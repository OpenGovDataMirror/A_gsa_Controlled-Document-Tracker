
 public without sharing class ApprovalStepSelectManager {
    public List<ApprovalStepSelect> approvalStepSelects {get; private set;}
    public Boolean noRowsSelected {get; private set;}
    public static boolean isRecallTest = false;
    private List<ApprovalStepSelect> backupApprovalStepSelects;
    private Id documentId;
    private Controlled_Document__c cdoc;

    public ApprovalStepSelectManager(Id documentId) {
        this.documentId = documentId;
        initializeSteps();
        addNewStep();
        determineNoRowsSelected();
        cdoc = [SELECT Id, OwnerId, Stage__c, Assignee__c FROM Controlled_Document__c WHERE Id = :documentId];
    }

    public Boolean save(){
		System.debug('=== ApprovalStepSelectManager: save');

        if(!addValidationErrors(extractUnlockedApprovalSteps())){
            try{
                System.debug('=== ApprovalStepsToUpdate: ' + extractUnlockedApprovalSteps());
                update extractUnlockedApprovalSteps();
                initializeSteps();
                determineNoRowsSelected();
            } catch(Exception e){
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, ExceptionUtility.parseErrorMessage(e.getMessage())));
                return false;
            }
        }
        else{
            return false;
        }
        return true;
    }

    public void initiateSelected(){
        System.debug('============= ApprovalStepSelectManager: initiateSelected');

        Map<Id,Id> approvalProcessMap = new Map<Id,Id>();
        Set<Id> approvalStepIds = new Set<Id>();
        // case# 22035 - BEGIN- added try and catch blocks to show the trigger errors, all other code is existing.
        try {
            // case# 22035 - END
            for (ApprovalStepSelect step : approvalStepSelects) {
                approvalStepIds.add(step.approvalStep.id);
            }
            System.debug('============= initiateSelected: approvalStepIds' + approvalStepIds);

            for (ProcessInstanceWorkItem approvalProcessItem : getProcessWorkItems(approvalStepIds)) {
                approvalProcessMap.put(approvalProcessItem.ProcessInstance.TargetObjectId, approvalProcessItem.Id);
            }
            System.debug('============= initiateSelected: approvalProcessMap' + approvalProcessMap);

            // case# 25836 - BEGIN
            List<Approval.ProcessSubmitRequest> requests = new List<Approval.ProcessSubmitRequest>();
            System.debug('============= initiateSelected: requests' + requests);

            // case# 25836 - END
            for (ApprovalStepSelect step : approvalStepSelects) {
                System.debug('============= ApprovalStepSelectManager: step: ' + step);

                if (step.selected && !step.approvalStep.Marked_For_Deletion__c && approvalProcessMap.get(step.approvalStep.id) == null) {
                    Approval.ProcessSubmitRequest submitRequest = new Approval.ProcessSubmitRequest();
                    submitRequest.setObjectId(step.approvalStep.id);
                    submitRequest.setSubmitterId(UserInfo.getUserId());
                    // case# 25836 - BEGIN
                    requests.add(submitRequest);
                    // case# 25836 - END
                    //Approval.process(submitRequest); - COMMENTED for CASE# 25836
                }
            }
            System.debug('============= initiateSelected: requests' + requests);

            // case# 25836 - BEGIN
            Approval.ProcessResult[] processResults = Approval.process(requests);
            // case# 25836 - END

            for (Approval.ProcessResult pr : processResults) {
                System.debug('---Process Result: ' + pr);
            }

        }
        // case# 22035 - BEGIN
        catch(Exception e) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, exceptionUtility.parseErrorMessage(e.getMessage())));
        }
        // case# 22035 - END
        
        initializeSteps();
        addNewStep();
        determineNoRowsSelected();
    }

    public void recallSelected(){
        Map<Id, Id> approvalProcessMap = new Map<Id, Id>();
        Set<Id> approvalStepIds = new Set<Id>();
        for (ApprovalStepSelect step : approvalStepSelects) {
            approvalStepIds.add(step.approvalStep.id);
        }

        for (ProcessInstanceWorkItem approvalProcessItem : getProcessWorkItems(approvalStepIds)) {
            approvalProcessMap.put(approvalProcessItem.ProcessInstance.TargetObjectId, approvalProcessItem.Id);
        }

        // list of approval steps that need to be processed
        List<Approval_Step_Recall_Request__c> approvalStepsToProcess = new List<Approval_Step_Recall_Request__c>();

        // check the current user to see if he/she is an ExecSec Admin
        boolean isExecSecAdmin = false;
        Id userId = UserInfo.getUserId();
        List<PermissionSet> pset = [SELECT Id, Name FROM PermissionSet WHERE Name = 'Controlled_Document_Tracker_OAS_Admin_User_CRED'];
        if (pset != null && !pset.isEmpty()) {
            List<PermissionSetAssignment> psetAssignment = [SELECT Id FROM PermissionSetAssignment WHERE AssigneeId = :userId AND PermissionSetId = :pset[0].Id];
            if (psetAssignment != null && !psetAssignment.isEmpty()) {
                isExecSecAdmin = true;
            }
        }

        // checks for existing recall requests to ensure an approval step isn't recalled in the batch in this scenario:
        // 1. someone initiates a recall request to be picked up by batch
        // 2. an admin recalls the approval step before the batch picks it up
        // 3. the admin changes something and initiates it again
        // 4. the batch runs and recalls the approval step out of order
        List<Id> idsToQueryForExistingRequests = new List<Id>();

        for (ApprovalStepSelect step : approvalStepSelects) {
            if (step.selected && !step.approvalStep.Marked_For_Deletion__c && approvalProcessMap.get(step.approvalStep.Id) != null) {
                // BATCH SOLUTION //////////////////////////////////////////////////////////////////////////////////////////////
                try {
                    System.debug('TRYING TO DO NORMALLY');
                    Approval.ProcessWorkItemRequest recallRequest = new Approval.ProcessWorkItemRequest();
                    recallRequest.setWorkItemId(approvalProcessMap.get(step.approvalStep.Id));
                    recallRequest.setAction('Removed');
                    Approval.process(recallRequest);
                    ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Your recall request has been processed.');
                    ApexPages.addMessage(myMsg);
                    // creating a record for historical purposes - batch won't pick this up
                    Approval_Step_Recall_Request__c approvalStepToRecall = new Approval_Step_Recall_Request__c();
                    approvalStepToRecall.Approval_Step__c = step.approvalStep.Id;
                    approvalStepToRecall.Work_Item_Id__c = approvalProcessMap.get(step.approvalStep.Id);
                    approvalStepToRecall.Status__c = 'Recalled';
                    approvalStepToRecall.Recalled_By__c = userId;
                    Datetime d = Datetime.now();
                    approvalStepToRecall.Recalled_Date__c = d;
                    approvalStepsToProcess.add(approvalStepToRecall);
                    // search for existing unprocessed recall requests to make sure it isn't reprocessed
                    idsToQueryForExistingRequests.add(step.approvalStep.Id);
                } catch (Exception e) {
                    System.debug('INSIDE RECALL CATCH');
                    if (userId == cdoc.OwnerId
                            || userId == cdoc.Assignee__c
                            || userId == step.approvalStep.Assigned_Approver__c
                            || userId == step.approvalStep.CreatedById
                            || isExecSecAdmin) {
                        System.debug('NOW HAFTA DO IT VIA BATCH');
                        Approval_Step_Recall_Request__c approvalStepToRecall = new Approval_Step_Recall_Request__c(Approval_Step__c = step.approvalStep.Id, Work_Item_Id__c = approvalProcessMap.get(step.approvalStep.Id),Status__c = 'Pending', Recalled_By__c = userId);
                        approvalStepsToProcess.add(approvalStepToRecall);
                        ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.INFO, 'Your recall request has been submitted. Please allow some time for the system to process it.');
                        ApexPages.addMessage(myMsg);
                    } else {
                        System.debug('UNAUTHORIZED RECALL');
                        ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Please ask the Controlled Document owner, Approval Step creator, Assigned Approver, Exec Sec Assignee, or an administrator to recall the step manually.');
                        ApexPages.addMessage(myMsg);
                    }
                }
                ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
            }
        }

        // deleting existing approval step recall requests if an admin beat them to the punch
        if (idsToQueryForExistingRequests != null && !idsToQueryForExistingRequests.isEmpty()) {
            List<Approval_Step_Recall_Request__c> approvalStepRecallRequestList = [SELECT Id FROM Approval_Step_Recall_Request__c WHERE Work_Item_Id__c IN :idsToQueryForExistingRequests AND Status__c = 'Pending'];
            if (approvalStepRecallRequestList != null && !approvalStepRecallRequestList.isEmpty()) {
                System.debug('Special case - VERY RARE');
                delete approvalStepRecallRequestList;
            }
        }

        // insert approval step recall requests
        if (!approvalStepsToProcess.isEmpty()) {
            System.debug('=== Approval Steps To Process: ' + approvalStepsToProcess);
            insert approvalStepsToProcess;
        }

        initializeSteps();
        addNewStep();
        determineNoRowsSelected();

    }

    public void clearNewRow(){
        removeNewStep();
        addNewStep();
    }

    private List<Approval_Step__c> extractUnlockedApprovalSteps(){
        List<Approval_Step__c> steps = new List<Approval_Step__c>();
        for(ApprovalStepSelect step : approvalStepSelects){
            if(step.ApprovalStep.id != null && !step.getisLocked()){
                steps.add(step.ApprovalStep);
            }
        }
        return steps;
    }

    public void backup(){
        backupApprovalStepSelects = cloneApprovalStepSelectList(approvalStepSelects);
    }

    public void restore(){
        approvalStepSelects = cloneApprovalStepSelectList(backupApprovalStepSelects);
    }

    private static List<ApprovalStepSelect> cloneApprovalStepSelectList(List<ApprovalStepSelect> steps){
        List<ApprovalStepSelect> stepClones = new List<ApprovalStepSelect>();
        for(ApprovalStepSelect step : steps){
            stepClones.add(new ApprovalStepSelect(step));
        }
        return stepClones;
    }

    public void populateExternalReviewParty(){
        for(ApprovalStepSelect step : approvalStepSelects){
            if(step.approvalStep.Role_Of_Approver__c == ControlledDocumentConstants.EXTERNAL_REVIEW_ROLE_NAME){
                if(step.approvalStep.External_Review_Party__c == null){
                    step.approvalStep.External_Review_Party__c = ControlledDocumentConstants.EXTERNAL_REVIEW_AUTOFILL_VALUE;
                }
            }
            else{
                step.approvalStep.External_Review_Party__c = null;
            }
        }
    }

    private void initializeSteps(){
        approvalStepSelects = new List<ApprovalStepSelect>();
        for(Approval_Step__c step : getRelatedApprovalSteps()){
            approvalStepSelects.add(new ApprovalStepSelect(step));
        }
        System.debug('=== Initialized Steps: ' + approvalStepSelects);
    }

    public void addNewStep(){
        approvalStepSelects.add(new ApprovalStepSelect(new Approval_Step__c(Correspondence_Document__c = documentId)));
    }

    public void removeNewStep(){
        approvalStepSelects.remove(approvalStepSelects.size()-1);
    }

    public void insertNewStep(){
        if(!addValidationErrors(new List<Approval_Step__c>{getNewApprovalStep()})){
            try {
                System.debug('=== New Approval Step: ' + getNewApprovalStep());
                insert getNewApprovalStep();
                initializeSteps();
                addNewStep();
                determineNoRowsSelected();
            } catch (Exception e) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, exceptionUtility.parseErrorMessage(e.getMessage())));
            }
        }
    }

    private Boolean addValidationErrors(List<Approval_Step__c> steps){
        Set<String> errorMessageKeys = new Set<String>();
        for(Approval_Step__c step : steps){
            for(String s : ControlledDocumentConstants.REQUIRED_FIELD_API_TO_LABEL_MAP.keySet()){
                if(step.get(s) == null){
                    errorMessageKeys.add(s);
                }
            }
        }

        for(String s : errorMessageKeys){
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Missing Required Field: ' + ControlledDocumentConstants.REQUIRED_FIELD_API_TO_LABEL_MAP.get(s)));
        }

        if(errorMessageKeys.isEmpty()){
            return false;
        }
        return true;

    }

    private Approval_Step__c getNewApprovalStep(){
        return approvalStepSelects.get(approvalStepSelects.size()-1).approvalStep;
    }

    public void determineNoRowsSelected(){
        noRowsSelected = true;
        for(ApprovalStepSelect stepSelect : approvalStepSelects){
            if(stepSelect.selected){
                noRowsSelected = false;
                break;
            }
        }
    }

    private List<Approval_Step__c> getRelatedApprovalSteps(){
        return [SELECT Name, Approver_s_Location__c, Approval_Status__c, Assigned_Approver__c, CreatedById, Completed_Date__c, Marked_for_Deletion__c, Office__c, Delegate__c,
                       Days_Open__c, Role_Of_Approver__c, Sequence__c, Start_Date__c, Due_Date__c, External_Review_Party__c, Assigned_Approver__r.Name
                FROM Approval_Step__c
                WHERE Correspondence_Document__c =: documentId
                ORDER BY Sequence__c ASC NULLS LAST];
    }

    private static List<ProcessInstanceWorkItem> getProcessWorkItems(Set<Id> approvalStepIds){
        return [SELECT Id, ProcessInstance.TargetObjectId
                FROM ProcessInstanceWorkItem 
                WHERE ProcessInstance.Status = 'Pending' AND 
                      ProcessInstance.TargetObjectId IN: approvalStepIds];
    }
}