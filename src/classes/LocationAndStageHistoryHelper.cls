
public class LocationAndStageHistoryHelper{

    private static ApprovalStepDAI appStepDA = new ApprovalStepDA();
    private static UserDAI userDA = new UserDA();
    private static ControlledDocumentDAI controlledDocDA = new ControlledDocumentDA();
    
    public static void setMockDA(ApprovalStepDAMock dataAccessor){
        //use in test
        appStepDA = dataAccessor;
    }
    public static void setMockUserDA(UserDAMock dataAccessor){
        //use in test
        userDA = dataAccessor;
    }
    public static void setMockDocDA(ControlledDocumentDAMock dataAccessor){
        //use in test
        controlledDocDA = dataAccessor;
    }


    // prevents adding a second location and stage history when the stage is changed to closed
    public static Map<Id, boolean> controlledDocumentIdRecursionTracker = new Map<Id, boolean>();
    public static BusinessHours cdtBusinessHours = [SELECT Id 
                                                FROM BusinessHours 
                                                WHERE Name = 'CDT Business Hours'];

    private static Boolean updatedFromApprovalStep = false;

    // BEFORE INSERT ONLY
    // inserts start dates and also sets the Current Location
    public static void insertStartDatesAndSetCurrentLocation(List<Controlled_Document__c> newCDocs){
        Date currentLocalDate = System.now().date();
        AutomatedLocationUpdate.locationValues locationVals = new AutomatedLocationUpdate.locationValues();
                
        for(Controlled_Document__c newControlledDocument : newCDocs){
            newControlledDocument.Current_Stage_Start_Date_New__c = currentLocalDate;
            newControlledDocument.Days_On_Current_Stage_New__c = 0;
            newControlledDocument.Current_Location_Start_Date_New__c = currentLocalDate;
            newControlledDocument.Days_In_Current_Location_New__c = 0;
            
            if (newControlledDocument.Stage__c != 'Awaiting Closure' && newControlledDocument.Stage__c != 'Awaiting Signature' && newControlledDocument.Stage__c != 'Hold' &&
                newControlledDocument.Stage__c != 'Closed' && newControlledDocument.Stage__c != 'External Review') {

                if (!String.isBlank(newControlledDocument.Assignee__c)) {
                    locationVals.updateWithUserId(newControlledDocument.Assignee__c, newControlledDocument.Id, newControlledDocument.Name);
                } else {
                    locationVals.updateWithUserId(newControlledDocument.OwnerId, newControlledDocument.Id, newControlledDocument.Name);
                }
                        
                newControlledDocument.Current_Region_Auto__c = locationVals.region;
                newControlledDocument.Current_Organization_Acronym__c = locationVals.orgAcronym;
                newControlledDocument.Current_Division_Code__c = locationVals.divisionCode; 
                newControlledDocument.Current_Division_Name__c = locationVals.divisionName; 
                newControlledDocument.Current_Location_auto__c = locationVals.concatenatedLocation; 
            }else{
                AutomatedLocationUpdate.updateControlledDocumentLocationFromStage(newControlledDocument);
            }
            
            
        }
    }


    public static void checkForNewDivision(List<Controlled_Document__c> newCDocs) {
        User tmpUser;
        Mapping_Object__c[] tmpMap;
        String tmpDivision;
            
        for(Controlled_Document__c newControlledDocument : newCDocs){
            tmpUser = [SELECT Id, Division, Alternate_Division__c, User_Region__c, Alternate_Region__c From User where Id =: newControlledDocument.OwnerId];
            tmpDivision = (String.isBlank(tmpUser.Division) ? tmpUser.Alternate_Division__c : tmpUser.Division);
        
            if (tmpDivision != null){
                tmpDivision = tmpDivision.left(3);                
            }
            
            tmpMap = [SELECT Id, Service_Staff_Office__c, Office_Portfolio__c FROM Mapping_Object__c WHERE Name =: tmpDivision];
    
            if (tmpMap.isEmpty()) {
                    
                Messaging.reserveSingleEmailCapacity(2);
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                    
                List<PermissionSetAssignment> execSecGroup = [SELECT AssigneeId, Assignee.Name, Assignee.Email FROM PermissionSetAssignment WHERE PermissionSet.Name = 'Controlled_Document_Tracker_OAS_Admin_User_CRED'];
                String[] emailAddresses = new String[]{};
                for(PermissionSetAssignment assignment : execSecGroup) {
                    emailAddresses.add(assignment.Assignee.Email);
                }

                String[] ccAddresses = new String[] {};
                String recordLink = URL.getSalesforceBaseUrl().toExternalForm()+'/'+ newControlledDocument.Id;  
                
                mail.setToAddresses(emailAddresses);
                mail.setCcAddresses(ccAddresses);
                    
                //mail.setOrgWideEmailAddressId('0D230000000TPnh');//donotreply@gsa.gov
                mail.setSubject('New Division Location Added to CDT ' + newControlledDocument.Name);
                mail.setBccSender(false);
                mail.setUseSignature(false);
                
                mail.setPlainTextBody(
                    'A new division location was added to the following Controlled Document Tracker record: \n' +
                    'Record Number:' + newControlledDocument.Name + '\n' +
                    'Division: '+ tmpDivision + '\n\n' +
                    'Please update the following as needed:\n' +
                    '1) The record\'s Approval Steps section\n' +
                    '2) The record\'s Location and Stage Histories section (if the Approval Step has already been marked)\n' +
                    '3) The central list of user divisions'
                );
                    
                mail.setHtmlBody(
                    '<p>A new division location was added to the following Controlled Document Tracker record:</p>' +
                    '<p><strong>Record Number:</strong> <a href=\'' + recordLink + '\'>' + newControlledDocument.Name + '</a> <br/> <strong>Division:</strong> ' + tmpDivision + '</p>' +
                    '<p>Please update the following as needed:</p>' +
                    '<p>1) The record\'s Approval Steps section <br/>' +
                    '2) The record\'s Location and Stage Histories section (if the Approval Step has already been marked) <br/>' +
                    '3) The central list of user divisions</p>'
                );
                    
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
                            
            }
        }
    }
    

    // AFTER INSERT ONLY
    public static void insertLocationHistoryForNewCDocs(List<Controlled_Document__c> newCDocs){
        Datetime current = System.now();
        Date currDate = current.date();
        Time currTime = current.time();
        Datetime currentLocal = Datetime.newInstance(currDate, currTime);

        List<Location_and_Stage_History__c> historiesToAdd = new List<Location_and_Stage_History__c>();
        for(Controlled_Document__c controlledDocument : newCDocs){            
            // if a CD is inserted as closed then this happens
            if(controlledDocument.Stage__c == 'Closed') continue;
            
            Location_and_Stage_History__c newHistoryLocation = new Location_and_Stage_History__c();
            
            // Case# 30668 - BEGIN
            //String locationName = (controlledDocument.current_Region__c != null) ? mergeString(controlledDocument.current_Region__c, 
            //                                                                                 controlledDocument.Current_Location__c) : null;
            //newHistoryLocation.Name = (locationName != null) ? locationName : controlledDocument.Current_Location__c;
            // Case# 30668 - END
            
            newHistoryLocation.Stage__c = controlledDocument.Stage__c;
            newHistoryLocation.Active__c = TRUE;
            newHistoryLocation.Start_Date__c = currentLocal;
            newHistoryLocation.of_Days_New__c = 0.0;
            newHistoryLocation.Controlled_Document__c = controlledDocument.Id;

            if (controlledDocument.Stage__c == 'Closed'){
                newHistoryLocation.End_Date__c = currentLocal;              
            }

            newHistoryLocation.Name = String.isNotBlank(controlledDocument.Current_Location_auto__c) ? controlledDocument.Current_Location_auto__c : '';
            newHistoryLocation.Region__c = String.isNotBlank(controlledDocument.Current_Region_Auto__c) ? ControlledDocument.Current_Region_Auto__c : '';   
            newHistoryLocation.Organization_Acronym__c = String.isNotBlank(controlledDocument.Current_Organization_Acronym__c) ? ControlledDocument.Current_Organization_Acronym__c : '';    
            newHistoryLocation.Division_Code__c = String.isNotBlank(controlledDocument.Current_Division_Code__c) ? ControlledDocument.Current_Division_Code__c : '';  
            newHistoryLocation.Division_Name__c = String.isNotBlank(controlledDocument.Current_Division_Name__c) ? ControlledDocument.Current_Division_Name__c : '';                  

            historiesToAdd.add(newHistoryLocation);
        }
        insert historiesToAdd;
    }

    // BEFORE UPDATE ONLY
    public static void checkAndUpdateHistory(Map<Id, Controlled_Document__c> newCDocs, Map<Id, Controlled_Document__c> oldCDocs){
        Datetime current = System.now();
        Date currDate = current.date();
        Time currTime = current.time();
        Time midnightTime = Time.newInstance(0, 0, 0, 0);
        Datetime currentLocal = Datetime.newInstance(currDate, currTime);
        Datetime currentLocalMidnight = Datetime.newInstance(currDate, midnightTime);
        Date currentLocalDate = currDate;

        List<Controlled_Document__c> cDocsNeedingHistoryChanges = new List<Controlled_Document__c>();
        for(Controlled_Document__c newControlledDocument : newCDocs.values()){
            // prevents closed controlled documents from running twice
            if(controlledDocumentIdRecursionTracker.get(newControlledDocument.Id) == true) {
                // allows another attempt after an initial 'closed' status in case a document is ever updated to 'closed' then to a new status in the same transcation
                // this should never happen -_-
                controlledDocumentIdRecursionTracker.put(newControlledDocument.Id, false);
                continue;
            }

            if(newControlledDocument.Stage__c == 'Closed'){
                newControlledDocument.Current_Location_Start_Date_New__c = null;
                newControlledDocument.Current_Stage_Start_Date_New__c = null;
                newControlledDocument.Days_In_Current_Location_New__c = null;
                newControlledDocument.Days_On_Current_Stage_New__c = null;
                cDocsNeedingHistoryChanges.add(newControlledDocument);
                continue;   
            }

            // this will help preventing nulls on existing controlled documents
            if(newControlledDocument.Current_Location_Start_Date_New__c == null) newControlledDocument.Current_Location_Start_Date_New__c = currentLocalDate;
            if(newControlledDocument.Current_Stage_Start_Date_New__c == null) newControlledDocument.Current_Stage_Start_Date_New__c = currentLocalDate;

            // used to prevent adding the same object to our list
            boolean added = false;
            if(newControlledDocument.Current_Location_auto__c != oldCDocs.get(newControlledDocument.Id).Current_Location_auto__c ||
               newControlledDocument.Current_Region_auto__c != oldCDocs.get(newControlledDocument.Id).Current_Region_auto__c ||
               newControlledDocument.Current_Organization_Acronym__c != oldCDocs.get(newControlledDocument.Id).Current_Organization_Acronym__c ||
               newControlledDocument.Current_Division_Name__c != oldCDocs.get(newControlledDocument.Id).Current_Division_Name__c ||
               newControlledDocument.Current_Division_Code__c != oldCDocs.get(newControlledDocument.Id).Current_Division_Code__c ||
               newControlledDocument.Current_Region__c != oldCDocs.get(newControlledDocument.Id).Current_Region__c){

                cDocsNeedingHistoryChanges.add(newControlledDocument);
                newControlledDocument.Current_Location_Start_Date_New__c = currentLocalDate;
                newControlledDocument.Days_In_Current_Location_New__c = 0;
                added = true;
            }
            // adds a new record even if the location doesn't change
            if(newControlledDocument.Stage__c != oldCDocs.get(newControlledDocument.Id).Stage__c ||
               newControlledDocument.OMB__c != oldCDocs.get(newControlledDocument.Id).OMB__c){

                newControlledDocument.Current_Stage_Start_Date_New__c = currentLocalDate;
                newControlledDocument.Days_On_Current_Stage_New__c = 0;
                if(!added){
                    cDocsNeedingHistoryChanges.add(newControlledDocument);
                    added = true;
                    if(newControlledDocument.Stage__c == 'Closed'){
                        controlledDocumentIdRecursionTracker.put(newControlledDocument.Id, true);
                    }
                }
            }

            // if these dates change then either an admin is doing something or we are testing
            boolean stageStartDateChanged = false;
            if(newControlledDocument.Current_Stage_Start_Date_New__c != oldCDocs.get(newControlledDocument.Id).Current_Stage_Start_Date_New__c){
                stageStartDateChanged = true;
            }

            // if these dates change then either an admin is doing something or we are testing
            boolean locationStartDateChanged = false;
            if(newControlledDocument.Current_Location_Start_Date_New__c != oldCDocs.get(newControlledDocument.Id).Current_Stage_Start_Date_New__c){
                locationStartDateChanged = true;
            }

            // changes controlled documents whenever the batch is run and not any other time
            if(UpdateDaysOpenOnApprovalStepsBatch.isBatchOn || stageStartDateChanged || locationStartDateChanged){
                newControlledDocument.Days_On_Current_Stage_New__c = getBsnsHoursDifferenceLong(cdtBusinessHours, newControlledDocument.Current_Stage_Start_Date_New__c, currentLocalDate);
                newControlledDocument.Days_In_Current_Location_New__c = getBsnsHoursDifferenceLong(cdtBusinessHours, newControlledDocument.Current_Location_Start_Date_New__c, currentLocalDate);
            }
        }

        List<Id> controlledDocumentIds = new List<Id>();
        List<Location_and_Stage_History__c> historiesToAdd = new List<Location_and_Stage_History__c>();
        for(Controlled_Document__c controlledDocument : cDocsNeedingHistoryChanges){

            controlledDocumentIds.add(controlledDocument.Id);

            // if closed we are not adding a new Location and Stage History but updating the most recent one to inactive and setting the end date
            if(controlledDocument.Stage__c == 'Closed') continue;

            Location_and_Stage_History__c newHistoryLocation = new Location_and_Stage_History__c();
            newHistoryLocation.Name = controlledDocument.Current_Location_auto__c;           

            // Case# 30668 - BEGIN
            // String locationName = (controlledDocument.current_Region__c != null) ? mergeString(controlledDocument.current_Region__c, 
            //                                                                                 controlledDocument.Current_Location__c) : null;
            // newHistoryLocation.Name = (locationName != null) ? locationName : controlledDocument.Current_Location__c;
            // Case# 30668 - END

            newHistoryLocation.Stage__c = controlledDocument.Stage__c;
            newHistoryLocation.Active__c = TRUE;
            newHistoryLocation.Start_Date__c = currentLocal;

            newHistoryLocation.Controlled_Document__c = controlledDocument.Id;
            newHistoryLocation.Of_Days_New__c = 0.0;
            
            if (controlledDocument.Stage__c == 'Closed'){
                newHistoryLocation.End_Date__c = currentLocal;              
            }
            
            newHistoryLocation.Name = String.isNotBlank(controlledDocument.Current_Location_auto__c) ? controlledDocument.Current_Location_auto__c : '';
            newHistoryLocation.Region__c = String.isNotBlank(controlledDocument.Current_Region_Auto__c) ? ControlledDocument.Current_Region_Auto__c : '';   
            newHistoryLocation.Organization_Acronym__c = String.isNotBlank(controlledDocument.Current_Organization_Acronym__c) ? ControlledDocument.Current_Organization_Acronym__c : '';    
            newHistoryLocation.Division_Code__c = String.isNotBlank(controlledDocument.Current_Division_Code__c) ? ControlledDocument.Current_Division_Code__c : '';  
            newHistoryLocation.Division_Name__c = String.isNotBlank(controlledDocument.Current_Division_Name__c) ? ControlledDocument.Current_Division_Name__c : '';                  

            historiesToAdd.add(newHistoryLocation);
        }

        List<Location_and_Stage_History__c> oldHistoryList = [SELECT Id, Active__c, Start_Date__c, End_Date__c, of_Days_New__c
                                                    FROM Location_and_Stage_History__c
                                                    WHERE Active__c = true AND
                                                        Controlled_Document__c IN :controlledDocumentIds];                          

        for(Location_and_Stage_History__c oldHistory : oldHistoryList){
            oldHistory.Active__c = FALSE;
            oldHistory.End_Date__c = currentLocal;
            if(oldHistory.Start_Date__c != null) {
                Double d = getBsnsHoursDifferenceDouble(cdtBusinessHours, oldHistory.Start_Date__c, oldHistory.End_Date__c);
                oldHistory.of_Days_New__c = d;
            }
        }

        update oldHistoryList;
        insert historiesToAdd;
    }

    private static Long getBsnsHoursDifferenceLong(BusinessHours bsnsHours, Datetime startTime, Datetime endTime){
        Long l = BusinessHours.diff(bsnsHours.Id, startTime, endTime);
        return l/1000/3600/8;
    }

    private static Double getBsnsHoursDifferenceDouble(BusinessHours bsnsHours, Datetime startTime, Datetime endTime){
        Double d = BusinessHours.diff(bsnsHours.Id, startTime, endTime);
        return d/1000/3600/8;
    }
 /*   // Case# 30668 - BEGIN 
    private static String mergeString(String currentRegion, String currentLocation) {
        String merged = null;
        if(currentregion != null) {
            merged = currentRegion + ': ' + currentLocation;
            if(merged.length() > 80) {
                merged = merged.substring(0, 80);
            }
        }
        return merged;
    } // Case# 30668 - END
*/

}