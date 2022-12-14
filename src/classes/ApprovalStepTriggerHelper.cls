public without sharing class ApprovalStepTriggerHelper {
    private static boolean approvalUpdateFlag = false;
    private static ApprovalStepDAI appStepDA = new ApprovalStepDA();
    private static ControlledDocumentDA controlledDocDA = new ControlledDocumentDA();
	private static Set<Id> wfUpdatedIds = new Set<Id>(); //v2.0
    public static boolean ControlDocumentUpdateFromApprovalStep = false;
    
    public static void onBeforeInsert(List<Approval_Step__c> triggerNew, Map<Id, Approval_Step__c> triggerOldMap) {
        checkIfDocumentIsClosedAndErrorOnInsert(triggerNew);
        performBusinessDaysCalculations(triggerNew);
        doValidateCDTUsers(triggerNew, null);
    }    

    public static void onBeforeUpdate(List<Approval_Step__c> triggerNew, List<Approval_Step__c> triggerOld, Map<Id, Approval_Step__c> triggerNewMap, Map<Id, Approval_Step__c> triggerOldMap) {
        checkIfDocumentIsClosedAndErrorOnUpdate(triggerNew, triggerOldMap);
        updateTimeInitiated(triggerNew, triggerOldMap);

        // case# 22417 BEGIN - recursion prevention logic
        if(!ApprovalStepCheckRecursive.hasAlreadyUpdated()) {
        // case# 22417 END - recursion prevention logic
            wfUpdatedIds = findWFFieldUpdate(triggerNew); //v2.0
            NotificationItemCreationHandler.createApprovalStepNotifications(triggerNew);
            setActualApproverOnApprovalStep(triggerOld, triggerNew);
            performBusinessDaysCalculations(triggerNew);
            // case# 22035 BEGIN - enforce the due date validation during field updates
            doValidateDueDate(triggerNew, triggerOldMap);
            // case# 22035 END - enforce the due date validation during field updates
            doValidateCDTUsers(triggerNew, triggerOldMap);
            DelegateFieldAssignmentOnApprovalStep.setRolesOfActualApprovers(triggerOldMap, triggerNewMap);

        // case# 22417 BEGIN - recursion prevention logic
            approvalUpdateFlag = true;
            AutomatedLocationUpdate.updateApprovalStepLocations(triggerNew, triggerOldMap);
            System.debug('===# onBeforeUpdate: triggerNew' + triggerNew);
        }
        // case# 22417 END - recursion prevention logic
    }    

    public static void onAfterInsert(List<Approval_Step__c> triggerNew, List<Approval_Step__c> triggerOld, Map<Id, Approval_Step__c> triggerNewMap, Map<Id, Approval_Step__c> triggerOldMap) {
        ShareDocumentToApproversHelper.manageControlledDocumentSharing(triggerOldMap, triggerNew);
        //ChatterFileCollaboratorTH.createCollaborators(triggerNew);
    }    

    public static void onAfterUpdate(List<Approval_Step__c> triggerNew, List<Approval_Step__c> triggerOld, Map<Id, Approval_Step__c> triggerNewMap, Map<Id, Approval_Step__c> triggerOldMap) {
        // case# 22417 BEGIN - recursion prevention logic during field updates
        if(!ApprovalStepCheckRecursive.hasAlreadyUpdated()) {
        // case# 22417 END - recursion prevention logic
            ShareDocumentToApproversHelper.manageControlledDocumentSharing(triggerOldMap, triggerNew);
            //ChatterFileCollaboratorTH.updateCollaborators(triggerOldMap, triggerNewMap);
            SupplementaryAccessUserGranterApprvlStep.updateSupplementsForApprovalSteps(triggerOldMap, triggerNew);
            approvalUpdateFlag = false;
            ApprovalStepCheckRecursive.setAlreadyUpdated();
        // case# 22417 BEGIN - recursion prevention logic during field updates
        }
        // case# 22417 END - recursion prevention logic
        //v2.0 - if condition to exclude the CDT stage/location changes during nightly batch process and time-based workflow rule update.
        if(!System.isBatch() && (wfUpdatedIds.isEmpty())) //v2.0
        	updateControlledDocumentFields(triggerNew, triggerOldMap);
    }    

    public static void onAfterUndelete(List<Approval_Step__c> triggerNew, Map<Id, Approval_Step__c> triggerOldMap) {
        //ChatterFileCollaboratorTH.createCollaborators(triggerNew); 
    }  
     
     
    public static Boolean isApprovalUpdating(){
        return approvalUpdateFlag;
    }       
    
    
    private static Long getBsnsHoursDifference(BusinessHours bsnsHours, Datetime startTime, Datetime endTime){        
        Long l = BusinessHours.diff(bsnsHours.Id, startTime, endTime);

        return l/1000/3600/8;
    }
    
    // case# 22035 BEGIN - enforce the due date validation during field updates
    //        for validating the due date during approval process field updates
    private static void doValidateDueDate(List<Approval_Step__c> newSteps, Map<Id,Approval_Step__c> oldStepsMap) {

        for(Approval_Step__c step: newSteps) {            
            if(step.Due_Date__c != null && step.Due_Date__c < Date.today() && step.Approval_Status__c == 'Initiated' && 
                // added below criteria for case# 27165
                step.Approval_Status__c != oldStepsMap.get(step.Id).Approval_Status__c) {
                step.addError('The Due Date must be equal or later than today');
            }            
        }
    }
    // case# 22035 END - enforce the due date validation during field updates
    
    // case# 31205 BEGIN
    private static void doValidateCDTUsers(List<Approval_Step__c> newSteps, Map<Id, Approval_Step__c> oldStepsMap) {
        // this is to validate the approver before create and update
        Set<Id> userIds = new Set<Id>();
    
        for(Approval_Step__c step: newSteps) {
            if(step.Assigned_Approver__c != null && (oldStepsMap == null || 
                                                     step.Assigned_Approver__c != oldStepsMap.get(step.Id).Assigned_Approver__c)) {
                userIds.add(step.Assigned_Approver__c);
            }
        }
        Map<Id,Id> userToPsetMap = new Map<Id,Id>();
        for(PermissionSetAssignment passign : [SELECT Id, AssigneeId, PermissionSetId FROM PermissionSetAssignment WHERE AssigneeId IN :userIds AND
                                               PermissionSet.Name Like 'Controlled_Document%']) {
                                                   if(!userToPsetMap.containskey(passign.AssigneeId))
                                                       userToPsetMap.put(passign.AssigneeId, passign.PermissionSetId);
                                               }
        Map<Id, Id> adminsMap = new Map<Id, Id>();
        for(User u: [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() AND IsActive=true 
                     AND Profile.Name IN ('System User','System Administrator')]) {
            adminsMap.put(u.Id, u.Id);
        }
		system.debug('UserName---------'+UserInfo.getUserName());
		system.debug('AdminsMap---------'+adminsMap);
        for(Approval_Step__c step: newSteps) {
            if(step.Assigned_Approver__c != null && (oldStepsMap == null || 
                                                     step.Assigned_Approver__c != oldStepsMap.get(step.Id).Assigned_Approver__c)) {
                if(adminsMap.isEmpty() && !userToPsetMap.containsKey(step.Assigned_Approver__c))
                  step.addError(System.Label.CDT_Error);
            }
        }
    }
    // case# 31205 END
    
    // not really sure what this is or where to put it but I wanted to make the trigger up above more readable at a glance
    private static void performBusinessDaysCalculations(List<Approval_Step__c> newSteps){
        Double daysOpen;
        BusinessHours cdtBusinessHours = [SELECT Id FROM BusinessHours WHERE Name = 'CDT Business Hours'];
        Datetime current = System.now();
        Date currDate = current.date();
        Time currTime = Time.newInstance(0, 0, 0, 0);
        Datetime currentLocal = Datetime.newInstance(currDate, currTime);

        for (Approval_Step__c step : newSteps) {

            if ((step.Start_date__c != NULL) && (step.Approval_Status__c != 'Not Initiated')) {

                if ((step.Completed_Date__c != null)) {
                    daysOpen = getBsnsHoursDifference(cdtBusinessHours, step.Start_date__c, step.Completed_Date__c);
                } else {
                    daysOpen = getBsnsHoursDifference(cdtBusinessHours, step.Start_date__c, currentLocal);
                }
                step.days_open__c =  daysOpen;
            }              
        }
    }

    private static void setActualApproverOnApprovalStep(List<Approval_Step__c> oldSteps, List<Approval_Step__c> newSteps){

        List<User> userList = [SELECT Id, Name FROM User WHERE Id = :UserInfo.getUserId()];

        if(userList.isEmpty()) return; // in what world would this happen? O__O

        for(Approval_Step__c oldStep : oldSteps){

            for(Approval_Step__c newStep : newSteps){

                if(oldStep.Approval_Status__c != newStep.Approval_Status__c 
                    && (newStep.Approval_Status__c == 'Approved' || newStep.Approval_Status__c == 'Approved w Comments')){

                    newStep.Actual_Approver__c = userList[0].Name;
                }
            }
        }
    }

    private static void updateTimeInitiated(List<Approval_Step__c> triggerNew, Map<Id, Approval_Step__c> triggerOldMap){
        Datetime now = Datetime.now();
        for (Approval_Step__c step : triggerNew){
            Approval_Step__c oldStep = triggerOldMap.get(step.Id);
            if (isStepBeingInitiated(oldStep.Approval_Status__c, step.Approval_Status__c)){
                step.Time_Initiated__c = now;
            }else if (isStepBeingRecalled(oldStep.Approval_Status__c, step.Approval_Status__c)){
                System.debug('Approval step being recalled.');
                step.Time_Initiated__c = null;
            }
        }
    }

    private static Boolean isStepBeingInitiated(String oldStatus, String newStatus){
        return oldStatus == 'Not Initiated' &&
                newStatus == 'Initiated';
    }

    private static Boolean isStepBeingRecalled(String oldStatus, String newStatus) {
        return oldStatus != 'Not Initiated' &&
                newStatus == 'Not Initiated';
    }

    private static void updateControlledDocumentFields(List<Approval_Step__c> triggerNew, Map<Id, Approval_Step__c> triggerOldMap){
        List<Id> docIds = new List<Id>();
        for (Approval_Step__c step : triggerNew){
            Approval_Step__c oldStep = triggerOldMap.get(step.Id);
            if(!isDocumentReopeningAndUpdatingSteps(step, oldStep)){
                docIds.add(step.Correspondence_Document__c);
            }
        }

        Map<Id, Controlled_Document__c> controlledDocuments = new Map<Id, Controlled_Document__c>(
                controlledDocDA.getControlledDocumentsByIds(docIds));


        List<Approval_Step__c> allApprovalSteps = appStepDA.getAllInitiatedApprovalStepsWithControlledDocumentIds(docIds);
        List<AggregateResult> docIdsAndMaxInitTimes = appStepDA.getMaxInitiatedTimeForDocumentIds(docIds);
        Map<Id, List<Approval_Step__c>> latestStepsByDocId = buildLatestStepMap(allApprovalSteps, docIdsAndMaxInitTimes);


        for (Controlled_Document__c document : controlledDocuments.values()){
            if(document.Stage__c != 'Closed' ){
                List<Approval_Step__c> latestSteps = latestStepsByDocId.get(document.Id);
                if (latestSteps.size() > 0 && document.Assignee__c != null ) {
                    // first element of latestSteps will be latestInitiatedStepWithHighestSequence
                    AutomatedStageUpdate.updateControlledDocumentStage(document, latestSteps[0]);
                }
                if(document.Stage__c != ControlledDocumentConstants.STAGE_HOLD || (document.Stage__c == ControlledDocumentConstants.STAGE_HOLD && latestSteps.size() > 0  && latestSteps[0].Approval_Status__c != 'Initiated/Closed')){
                    AutomatedLocationUpdate.updateControlledDocumentLocationFromApprovalSteps(document, latestSteps);
                }
            }
        }
        
        ControlDocumentUpdateFromApprovalStep = true;
        update controlledDocuments.values();
        ControlDocumentUpdateFromApprovalStep = false;
    }

    private static void checkIfDocumentIsClosedAndErrorOnInsert(List<Approval_Step__c> triggerNew){
        for(Approval_Step__c step : triggerNew){
            if (step.Document_Stage__c == 'Closed') {
                step.addError('This control is closed. Approval Step cannot be created and/or updated.');
            }
        }
    }

    private static void checkIfDocumentIsClosedAndErrorOnUpdate(List<Approval_Step__c> triggerNew, Map<Id, Approval_Step__c> triggerOldMap){
        for (Approval_Step__c step : triggerNew){
            if (step.Document_Stage__c == 'Closed'){
                Approval_Step__c oldStep = triggerOldMap.get(step.Id);
                if(!isDocumentClosingAndUpdatingSteps(step, oldStep) ){
                    step.addError('This control is closed. Approval Step cannot be created and/or updated.');
                }
            }
        }
    }

    private static Boolean isDocumentClosingAndUpdatingSteps(Approval_Step__c newStep, Approval_Step__c oldStep){
        return (oldStep.Approval_Status__c != 'Initiated/Closed' &&
                (newStep.Approval_Status__c == 'Initiated/Closed' ||
                        newStep.Approval_Status__c == 'Not Initiated'));
    }

    private static Boolean isDocumentReopeningAndUpdatingSteps(Approval_Step__c newStep, Approval_Step__c oldStep){
        return (oldStep.Approval_Status__c != 'Initiated/Reopened' &&
                newStep.Approval_Status__c == 'Initiated/Reopened');
    }

    private static Map<Id, List<Approval_Step__c>> buildLatestStepMap(List<Approval_Step__c> approvalSteps,
                                                            List<AggregateResult> docIdsAndMaxInitTimes){
        Map<Id, List<Approval_Step__c>> latestStepsByDocIds = new Map<Id, List<Approval_Step__c>>();
        for(AggregateResult result : docIdsAndMaxInitTimes){
            Id docId = Id.valueOf(String.valueOf(result.get('Correspondence_Document__c')));
            Datetime maxInitTime = Datetime.valueOf(result.get('maxInitTime'));


            List<Approval_Step__c> relevantSteps = getRelevantSteps(approvalSteps, docId);

            List<Approval_Step__c> maxInitiatedSteps = getMaxInitiatedSteps(relevantSteps, maxInitTime);

            Approval_Step__c latestStepWithHighestSequence = getStepWithHighestSequence(maxInitiatedSteps);

            List<Approval_Step__c> stepsWithSameSequence = groupStepsWithSameSequence(relevantSteps, latestStepWithHighestSequence);

            List<Approval_Step__c> finalStepList = ifAllStepsApprovedOrRejectedEmptyList(stepsWithSameSequence);

            latestStepsByDocIds.put(docId, finalStepList);
            System.debug('Final Step List Size: ' + finalStepList.size());
            System.debug(finalStepList);

        }
        return latestStepsByDocIds;
    }

    private static List<Approval_Step__c> getRelevantSteps(List<Approval_Step__c> approvalSteps, String docId){
        System.debug('getRelevantSteps');
        List<Approval_Step__c> relevantSteps = new List<Approval_Step__c>();
        for (Approval_Step__c step : approvalSteps) {
            if (step.Correspondence_Document__c == docId) {
                relevantSteps.add(step);
            }
        }
        return relevantSteps;
    }

    private static List<Approval_Step__c> getMaxInitiatedSteps(List<Approval_Step__c> approvalSteps, Datetime maxInitTime){
        System.debug('getMaxInitiatedSteps');
        List<Approval_Step__c> maxInitTimeSteps = new List<Approval_Step__c>();
        for (Approval_Step__c step : approvalSteps) {
            if (step.Time_Initiated__c == maxInitTime) {
                maxInitTimeSteps.add(step);
            }
        }
        return maxInitTimeSteps;
    }

    private static Approval_Step__c getStepWithHighestSequence(List<Approval_Step__c> approvalSteps){
        System.debug('getStepWithHighestSequence');
        Approval_Step__c stepWithHighestSequence;
        for (Approval_Step__c step : approvalSteps){
            if (stepWithHighestSequence == null){
                stepWithHighestSequence = step;
            }else{
                if(Integer.valueOf(step.Sequence__c) > Integer.valueOf(stepWithHighestSequence.Sequence__c)){
                    stepWithHighestSequence = step;
                }
            }
        }
        return stepWithHighestSequence;
    }

    private static List<Approval_Step__c> groupStepsWithSameSequence(List<Approval_Step__c> approvalSteps, Approval_Step__c controllingStep){
        System.debug('groupStepsWithSameSequence');
        List<Approval_Step__c> stepsWithSameSequence = new List<Approval_Step__c>();
        if(controllingStep != null) {
            stepsWithSameSequence.add(controllingStep);
            for (Approval_Step__c step : approvalSteps) {
                system.debug('*****Step'+step);
                system.debug('******sequence'+Integer.valueOf(step.Sequence__c));
                system.debug('*****controllseq'+Integer.valueOf(controllingStep.Sequence__c));
                system.debug('****stepId'+step.Id);
                system.debug('****controllingid'+controllingStep.Id);
                if (Integer.valueOf(step.Sequence__c) == Integer.valueOf(controllingStep.Sequence__c) &&
                        step.Id != controllingStep.Id) {

                    stepsWithSameSequence.add(step);
                }
            }
        }
        return stepsWithSameSequence;
    }

    private static List<Approval_Step__c> ifAllStepsApprovedOrRejectedEmptyList(List<Approval_Step__c> approvalSteps){
        System.debug('ifAllStepsApprovedOrRejectedEmptyList');
        Boolean shouldEmptyList = true;
        for(Approval_Step__c step : approvalSteps){
            shouldEmptyList = isStepApprovedOrRejected(step.Approval_Status__c);
            if(!shouldEmptyList){
                break;
            }
        }
        if(shouldEmptyList){
            return new List<Approval_Step__c>();
        }else{
            return approvalSteps;
        }
    }

    private static Boolean isStepApprovedOrRejected(String approvalStatus){
        return (approvalStatus == ControlledDocumentConstants.APPROVED_STATUS_STRING ||
                approvalStatus == ControlledDocumentConstants.APPROVED_WITH_COMMENTS_STATUS_STRING ||
                approvalStatus == ControlledDocumentConstants.REJECTED_STATUS_STRING);
    }
    //v2.0 - BEGIN
    private static Set<Id> findWFFieldUpdate(List<Approval_Step__c> triggerNew) {
        Set<Id> appSteps = new Set<Id>();
        for(Approval_Step__c step: triggerNew) {
            if(step.Notification_History_Trigger__c == 'Step Reminder Notification' || 
               step.Notification_History_Trigger__c == 'Step Overdue Notifications') {
                   appSteps.add(step.Id);
               }
        }
        return appSteps;
    }
    //v2.0 - END
}