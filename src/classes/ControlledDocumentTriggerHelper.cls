
public with sharing class ControlledDocumentTriggerHelper {
    // * BEGIN - COMMENTED FOR 4.0
    //public Double daysOpen;
    //public Double daysOverdue;
    //public Double daysExecSecOverdue;
    // * END - COMMENTED FOR 4.0
    public static PermissionSetAssignmentDAI permSetAssignmentDA = new PermissionSetAssignmentDA();
    
    public static void onBeforeInsert(List<Controlled_Document__c> triggerNew, Map<Id, Controlled_Document__c> triggerOldMap) {
        // v5.0 - BEGIN
        String agencyAdmin = fetchAgencyAdmin();
       
        if(agencyAdmin != null) {
            doValidate(triggerNew, null, agencyAdmin);
        }
        // v5.0 - END
        
        setDayFields(triggerNew);
        setReportFields(triggerNew);
        System.debug('=== ControlledDocumentTriggerHelper: onBeforeInsert');
        LocationAndStageHistoryHelper.insertStartDatesAndSetCurrentLocation(triggerNew);
    }    
    
    public static void onBeforeUpdate(List<Controlled_Document__c> triggerNew, Map<Id, Controlled_Document__c> triggerNewMap, Map<Id, Controlled_Document__c> triggerOldMap) {
        
        if(!ApprovalStepTriggerHelper.ControlDocumentUpdateFromApprovalStep){
            checkIfUserHasPermissionsForStageChange(triggerNew, triggerOldMap);
        }
        
        // v5.0 - BEGIN
        String agencyAdmin = fetchAgencyAdmin();
        
        if(agencyAdmin != null) {        
            doValidate(triggerNew, triggerOldMap, agencyAdmin);
        }
        // v5.0 - END
        
        setDayFields(triggerNew);
        setReportFields(triggerNew);
        // recursion happens after a workflow updates the Controlled_Document__c's End Date after being closed
        System.debug('=== ControlledDocumentTriggerHelper: onBeforeUpdate');
        checkForStageChangeAndUpdateLocation(triggerNew, triggerOldMap);
        LocationAndStageHistoryHelper.checkAndUpdateHistory(triggerNewMap, triggerOldMap);
    }    

    public static void onBeforeDelete(List<Approval_Step__c> triggerNew, Map<Id, Approval_Step__c> triggerOldMap) {
        //Cascade delete does not fire triggers for child objects. The following line fires
        //the approval step triggers in order to ensure that the Control Doc and ChatterFeed
        //sharing entities stay in sync.
        //delete [SELECT id FROM Approval_Step__c WHERE Correspondence_Document__c IN: trigger.old];
    }    


    public static void onAfterInsert(List<Controlled_Document__c> triggerNew, Map<Id, Controlled_Document__c> triggerOldMap) {

        LocationAndStageHistoryHelper.insertLocationHistoryForNewCDocs(triggerNew);
        LocationAndStageHistoryHelper.checkForNewDivision(triggerNew);
    }    

    public static void onAfterUpdate(List<Controlled_Document__c> triggerNew, Map<Id, Controlled_Document__c> triggerOldMap) {

        //ChatterFileCollaboratorTH.updateCollaborators(triggerOldMap, triggerNew);
    }    



    private static void setDayFields(List<Controlled_Document__c> controlledDocumentList){
        Datetime current = System.now();
        Date currDate = current.date();
        Time currTime = Time.newInstance(0, 0, 0, 0);
        Datetime currentLocal = Datetime.newInstance(currDate, currTime);
        BusinessHours cdtBusinessHours = [SELECT Id FROM BusinessHours WHERE Name = 'CDT Business Hours'];

        for (Controlled_Document__c controlledDocument : controlledDocumentList) {
            // BEGIN -version 4.0 Added the fields to each record level to reflect the correct calculations
            Double daysOpen = null;
            Double daysOverdue = null;
            Double daysExecSecOverdue = null;  
            // END -version 4.0 Added the fields to each record level to reflect the correct calculations
            if(controlledDocument.ExecSec_Start_Date__c == null) controlledDocument.Days_Open__c = null;
            if(controlledDocument.ExecSec_Due_Date__c == null) controlledDocument.ExecSec_Days_Overdue__c = null;
            //Days open calculation if applicable
            if ((controlledDocument.ExecSec_Start_Date__c != NULL)) {                   
                if ((controlledDocument.ExecSec_End_Date__c != null)) {  
                    daysOpen = getBsnsHoursDifference(cdtBusinessHours, controlledDocument.ExecSec_Start_Date__c, controlledDocument.ExecSec_End_Date__c);       
                } 
                else {
                   daysOpen = getBsnsHoursDifference(cdtBusinessHours, controlledDocument.ExecSec_Start_Date__c, currentLocal);
                }

                controlledDocument.Days_Open__c =  daysOpen;
            }
            //Days Overdue calculation if applicable
            if ((controlledDocument.Stage__c != 'Closed') && (controlledDocument.Due_Date__c != null)) {                    
                if ((currentLocal > controlledDocument.Due_Date__c)) {
                    daysOverdue = getBsnsHoursDifference(cdtBusinessHours, controlledDocument.Due_Date__c, currentLocal);             
                } 
                else {                     
                   //do Nothing
                }
                controlledDocument.Days_Overdue__c =  daysOverdue;
            } else if ((controlledDocument.Stage__c == 'Closed') && (controlledDocument.Due_Date__c != null) && (controlledDocument.ExecSec_End_Date__c != null)) {     
                if ((controlledDocument.Due_Date__c < controlledDocument.ExecSec_End_Date__c)) {
                    daysOverdue = getBsnsHoursDifference(cdtBusinessHours, controlledDocument.Due_Date__c, controlledDocument.ExecSec_End_Date__c);        
                } 
                else {                     
                   //do Nothing
                }
                //daysOverdue = getBsnsHoursDifference(cdtBusinessHours, controlledDocument.Date_Closed__c, controlledDocument.Due_Date__c);
                controlledDocument.Days_Overdue__c =  daysOverdue;
            }
            //ExecSec Days Overdue calculation if applicable
            //ExecSec_Days_Overdue__c ExecSec_Due_Date__c ExecSec_End_Date__c
            if ((controlledDocument.ExecSec_Due_Date__c != null) && (controlledDocument.ExecSec_End_Date__c != null)) {                                     
                if ((controlledDocument.ExecSec_End_Date__c > controlledDocument.ExecSec_Due_Date__c)) {        
                    daysExecSecOverdue = getBsnsHoursDifference(cdtBusinessHours, controlledDocument.ExecSec_Due_Date__c, controlledDocument.ExecSec_End_Date__c);          
                }                   
                controlledDocument.ExecSec_Days_Overdue__c =  daysExecSecOverdue;
            } else  if ((controlledDocument.ExecSec_Due_Date__c != null) && (controlledDocument.ExecSec_End_Date__c == null)) {                                     
                if ((currentLocal > controlledDocument.ExecSec_Due_Date__c)) {
                    daysExecSecOverdue = getBsnsHoursDifference(cdtBusinessHours, controlledDocument.ExecSec_Due_Date__c, currentLocal);             
                }                   
                controlledDocument.ExecSec_Days_Overdue__c =  daysExecSecOverdue;
            } 
        }
    }

    public static Long getBsnsHoursDifference(BusinessHours bsnsHours, Datetime startTime, Datetime endtime){
        Long l = BusinessHours.diff(bsnsHours.Id, startTime, endtime);
        return l/1000/3600/8;
    }
    
    // v5.0 - BEGIN
    // Validation error while choosing the control for administrtor's review by users who are not part of the ExecSec-Admin or ExecSec-User groups
    private static void doValidate(List<Controlled_Document__c> triggerNew, Map<Id, Controlled_Document__c> oldMap, String adminName) {
        List<GroupMember> gmList = new List<GroupMember>();
        //User gsaAdmin = new User();
        List<User> AdminList = new List<User>();
        gmList = [SELECT Id FROM GroupMember WHERE UserorGroupId = :UserInfo.getUserId() AND Group.DeveloperName IN ('CDT_OAS_User','CDT_OAS_Admin_User')]; 
        AdminList = [SELECT Id FROM User WHERE Name = :adminName AND IsActive = true LIMIT 1];
        //gsaAdmin = [SELECT Id FROM User WHERE Name = :adminName AND IsActive = true LIMIT 1];        
        if(!AdminList.isEmpty()) {            
            for(Controlled_Document__c cdt : triggerNew) {
                if(((cdt.GSA_Action_Required__c == 'Signature/Approval of the Administrator' && 
                    (oldMap == null || cdt.GSA_Action_Required__c != oldMap.get(cdt.Id).GSA_Action_Required__c)) || 
                    (cdt.Final_Signatory__c == AdminList[0].Id && 
                    (oldMap == null || cdt.Final_Signatory__c != oldMap.get(cdt.Id).Final_Signatory__c))) 
                    && gmList.isEmpty() ) {
                    cdt.addError(System.Label.CDT_Issue_Controls);
                }
            }
        }    
    }
    // v5.0 - END
    private static String fetchAgencyAdmin() {
        Map<String, CDT_GSA_Administrator__c> cmMap = CDT_GSA_Administrator__c.getAll();
        String agencyAdmin = null;
        if(!cmMap.isEmpty()) {
            CDT_GSA_Administrator__c cm = cmMap.get('Agency Administrator');
            agencyAdmin = (cm.FullName__c != null) ? cm.FullName__c : null;                
        }
        return agencyAdmin;
    }

    private static void setReportFields(List<Controlled_Document__c> controlledDocuments){
        BusinessHours hours = BusinessHoursDA.getBusinessHoursByName('CDT Business Hours');

        for(Controlled_Document__c controlledDocument : controlledDocuments){
            System.debug('Document: ' + controlledDocument.Name);
            Long daysDiff;

            System.debug('ExecSec End Date: ' + controlledDocument.ExecSec_End_Date__c);
            System.debug('Req Due Date: ' + controlledDocument.Due_Date__c);

            if (controlledDocument.ExecSec_End_Date__c == null ||
                    controlledDocument.Due_Date__c == null){
                controlledDocument.Asuite_Review_Days__c = null;
                controlledDocument.Full_5day_Review__c = false;
                controlledDocument.Full_25day_Process__c = false;

            }else{
                Datetime startTime = controlledDocument.ExecSec_End_Date__c;
                Datetime endTime = controlledDocument.Due_Date__c;
                daysDiff = getBsnsHoursDifference(hours, startTime, endTime) + 1;
                System.debug('Day Difference: ' + daysDiff);

                if(daysDiff < 0){
                    daysDiff = 0;
                }

                controlledDocument.Asuite_Review_Days__c = daysDiff;
                controlledDocument.Full_5day_Review__c = daysDiff > 4;
            }


            System.debug('ExecSec Start Date: ' + controlledDocument.ExecSec_Start_Date__c);
            System.debug('Req Due Date: ' + controlledDocument.Due_Date__c);

            if (controlledDocument.ExecSec_Start_Date__c == null ||
                    controlledDocument.Due_Date__c == null){
                controlledDocument.Total_Days_Process__c = null;
                controlledDocument.ExecStart_To_ReqDueDate__c = null;

            }else{
                Datetime startTime = controlledDocument.ExecSec_Start_Date__c;
                Datetime endTime = controlledDocument.Due_Date__c;
                daysDiff = getBsnsHoursDifference(hours, startTime, endTime) + 1;
                System.debug('Day Difference: ' + daysDiff);


                controlledDocument.ExecStart_To_ReqDueDate__c = daysDiff;
                if (daysDiff < 0) {
                    daysDiff = 0;
                }

                controlledDocument.Total_Days_Process__c = daysDiff;
                controlledDocument.Full_25day_Process__c = daysDiff > 24;
            }

            System.debug('Asuite Rev Days: ' + controlledDocument.Asuite_Review_Days__c);
            System.debug('Full 5Day Rev: ' + controlledDocument.Full_5day_Review__c);
            System.debug('ExecSec Start to Due Date: ' + controlledDocument.ExecStart_To_ReqDueDate__c);
            System.debug('Total Days Process: ' + controlledDocument.Total_Days_Process__c);
            System.debug('Full 25 Days Process: ' + controlledDocument.Full_25day_Process__c);
        }
    }

    private static void checkForStageChangeAndUpdateLocation(List<Controlled_Document__c> controlledDocuments,
                                                            Map<Id, Controlled_Document__c> oldControlledDocuments){
        // v2.00 - BEGIN
        Map<String, Integer> appStepsCountMap = new Map<String, Integer>();                                                        
        appStepsCountMap = fetchInitiatedApprovalStepsofCDocs(controlledDocuments);        
        // v2.00 - END
        for(Controlled_Document__c currentDocument : controlledDocuments){
            Controlled_Document__c oldDocument = oldControlledDocuments.get(currentDocument.Id);
            System.debug('=== currentDocument Stage:' + currentDocument.Stage__c);
            System.debug('=== oldDocument Stage:' + oldDocument.Stage__c);
            System.debug('=== ExecSec Assignee has changed:' + (currentDocument.Assignee__c != oldDocument.Assignee__c));
            System.debug('=== overwritten check:' + locationWasNotManuallyOverwritten(currentDocument, oldDocument));
            if (((currentDocument.Stage__c != oldDocument.Stage__c && AutomatedLocationUpdate.stagesThatChangeLocation.contains(currentDocument.Stage__c) ) || 
                    currentDocument.OMB__c != oldDocument.OMB__c ||
                 	//commented v2.00
                    //execSecAssigneeHasChanged(currentDocument, oldDocument)) && 
                	//v2.00 - BEGIN
                	(execSecAssigneeHasChanged(currentDocument, oldDocument) && 
                     (appStepsCountMap != null && !appStepsCountMap.containsKey(currentDocument.Id))) ) &&
                	//v2.00 - END
                locationWasNotManuallyOverwritten(currentDocument, oldDocument)){
                System.debug('checkForStageChangeAndUpdateLocation');
                AutomatedLocationUpdate.updateControlledDocumentLocationFromStage(currentDocument);
            }
        }
    }

    private static Boolean locationWasNotManuallyOverwritten(Controlled_Document__c doc, Controlled_Document__c docOld){
        return ((doc.Current_Region_Auto__c == docOld.Current_Region_Auto__c) &&
                (doc.Current_Organization_Acronym__c == docOld.Current_Organization_Acronym__c) &&
                (doc.Current_Division_Code__c == docOld.Current_Division_Code__c) &&
                (doc.Current_Division_Name__c == docOld.Current_Division_Name__c) &&
                (doc.Current_Location_auto__c == docOld.Current_Location_auto__c));
    }

    private static Boolean execSecAssigneeHasChanged(Controlled_Document__c doc, Controlled_Document__c docOld){
        return doc.Assignee__c != docOld.Assignee__c;
    }
	
    // v2.00 - BEGIN 
    private static Map<String, Integer> fetchInitiatedApprovalStepsofCDocs(List<Controlled_Document__c> cdocsList) {
        Map<String, Integer> extractMap = new Map<String, Integer>();
        Set<Id> cDocids = new Set<Id>();
        for(Controlled_Document__c cdoc : cdocsList) {
            cDocIds.add(cdoc.Id);
        }
        // fetching the initiated approval steps by cdoc id
        List<AggregateResult> groupResults = [SELECT Correspondence_Document__c cDoc, COUNT(Id) Total FROM Approval_Step__c
                                             WHERE Correspondence_Document__c IN :cDocIds AND Approval_Status__c = 'Initiated'
                                             GROUP BY Correspondence_Document__c];
        for(AggregateResult ar: groupResults) {
            extractMap.put(String.valueOf(ar.get('cDoc')), Integer.valueOf(ar.get('Total')));
        }        
        return extractMap;
    }
	// v2.00 - END
    private static void checkIfUserHasPermissionsForStageChange(List<Controlled_Document__c> triggerNew, Map<Id, Controlled_Document__c> triggerOldMap){

        Id userId = UserInfo.getUserId();
        System.debug(UserInfo.getName());
        List<PermissionSetAssignment> userPermissionSetAssignments = permSetAssignmentDA.getPermissionSetAssignmentsForUserId(userId);
        Boolean userIsExecSec = false;
        for (PermissionSetAssignment psa : userPermissionSetAssignments){
            if (ControlledDocumentConstants.EXECSEC_USER_PERMISSION_SET_NAMES.contains(psa.PermissionSet.Name)) {
                userIsExecSec = true;
            }
        }

        for(Controlled_Document__c newDocument : triggerNew){
            Controlled_Document__c oldDocument = triggerOldMap.get(newDocument.Id);
            Boolean userIsOwner = (newDocument.OwnerId == userId);
            if(newDocument.Stage__c != oldDocument.Stage__c){
                System.debug('Stage is changed');
                System.debug('Is owner? ' + (userIsOwner));
                System.debug('Is ExecSec? ' + (userIsExecSec));
                if (!userIsExecSec && !userIsOwner){
                    System.debug('User does not have permission to modify stage.');
                    newDocument.addError('Only Record Owner and Exec Sec users can modify Stage.');
                }
            }
        }
    }
    
    



/*
The field is calculated as the number of business days that have passed since the date in Due_Date__c as long as the Stage does not equal "Closed". 
If today's date is still before the Due Date, the field should either be blank or show a 0. Once the record is closed, i.e., Stage = Closed, 
the calculation should use the Date_Closed__c field instead of today's date to calculate the "Days Overdue" field.
*/

}