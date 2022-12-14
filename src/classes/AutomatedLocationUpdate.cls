
public without sharing class AutomatedLocationUpdate {

    //public static OrgWideEmailAddressDAI orgWideEmailDA = new OrgWideEmailAddressDA();

    private static ApprovalStepDAI appStepDA = new ApprovalStepDA();
    private static UserDAI userDA = new UserDA();
    private static ControlledDocumentDAI controlledDocDA = new ControlledDocumentDA();
    public static List<String> stagesThatChangeLocation = new List<String>{
            ControlledDocumentConstants.STAGE_AWAITING_CLOSURE,
            ControlledDocumentConstants.STAGE_AWAITING_SIGNATURE,
            ControlledDocumentConstants.STAGE_HOLD,
            ControlledDocumentConstants.STAGE_EXTERNAL_REVIEW,
            ControlledDocumentConstants.STAGE_CLOSED
    };
    private static Boolean updatedLocationFromApprovalSteps = false;
    
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
    
    public static void updateApprovalStepLocations(List<Approval_Step__c> triggerNew, Map<Id, Approval_Step__c> triggerOldMap) {
        Controlled_Document__c controlledDocument;
        locationValues locationVals = new locationValues();
        Set<Id> controlledDocumentIdSet = new Set<Id>();
        List<Id> controlledDocumentIdList = new List<Id>();
        List<Controlled_Document__c> controlledDocumentList;
        Map<Id, Controlled_Document__c> controlledDocumentMap = new Map<Id, Controlled_Document__c>();

        for(Approval_Step__c approvalStep : triggerNew) {
            controlledDocumentIdSet.add(approvalStep.Correspondence_Document__c);
        }
        // possibly replace with ControlledDocumentDA method
        controlledDocumentIdList.addAll(controlledDocumentIdSet);
        controlledDocumentList = controlledDocDA.getControlledDocumentsByIds(controlledDocumentIdList);
        for(Controlled_Document__c doc : controlledDocumentList) {
            controlledDocumentMap.put(doc.Id, doc);
        }
        
        for(Approval_Step__c approvalStep : triggerNew) {
            if (noManualOveridesForApprovalStepLocation(approvalStep, triggerOldMap.get(approvalStep.Id))) {
            
                controlledDocument = controlledDocumentMap.get(approvalStep.Correspondence_Document__c);
    
                if (approvalStepIsInitiated(approvalStep)) {
                    // Approval Step Location
                    if (!String.isBlank(approvalStep.Office__c)) {
                        // Populate new concatenated field with old value. Leave all other location values blank.
                        locationVals.reset();
                        locationVals.concatenatedLocation = approvalStep.Office__c;
                        approvalStep.Approver_s_Location__c = approvalStep.Office__c;
                    } else {
                        // Populate new concatenated field (CD Current Location) with the selected Approver's Division Code, Region 
                        // and Organization Acronym & Division Name from mapping object
                        locationVals.reset();
                        locationVals.updateWithUserId(approvalStep.Assigned_Approver__c, controlledDocument.Id, controlledDocument.Name);
    
                        approvalStep.Approver_s_Region_Location__c = locationVals.region;
                        approvalStep.Approver_s_Organization_Acronym__c = locationVals.orgAcronym;
                        approvalStep.Approver_s_Division_Code__c = locationVals.divisionCode;
                        approvalStep.Approver_s_Division_Name__c = locationVals.divisionName;
                        approvalStep.Approver_s_Location__c = locationVals.concatenatedLocation;
                    }
                }
            }
        }       
    }
    

    public static void updateControlledDocumentLocationFromApprovalSteps(Controlled_Document__c controlledDocument,
                                                                        List<Approval_Step__c> approvalSteps) {
        System.debug('DocName: ' + controlledDocument.Name);
        System.debug('Approval Steps Size: ' + approvalSteps.size());



        String inboundConcatLocation = controlledDocument.Current_Location_auto__c;
        locationValues locationVals = new locationValues();
        Set<String> acronymUnique = new Set<String>();

        if (approvalSteps.size() == 0) {
            System.debug('Size 0');
            if (stagesThatChangeLocation.contains(controlledDocument.Stage__c)){
                updateControlledDocumentLocationFromStage(controlledDocument);
            }
            else {
                if (!String.isBlank(controlledDocument.Assignee__c)) {
                    locationVals.updateWithUserId(controlledDocument.Assignee__c, controlledDocument.Id, controlledDocument.Name);
                } else {
                    locationVals.updateWithUserId(controlledDocument.OwnerId, controlledDocument.Id, controlledDocument.Name);
                }

                controlledDocument.Current_Region_Auto__c = locationVals.region;
                controlledDocument.Current_Organization_Acronym__c = locationVals.orgAcronym;
                controlledDocument.Current_Division_Code__c = locationVals.divisionCode;
                controlledDocument.Current_Division_Name__c = locationVals.divisionName;
                controlledDocument.Current_Location_auto__c = locationVals.concatenatedLocation;
            }
        } else if (approvalSteps.size() == 1) {
            System.debug('Size 1');
            if (approvalStepIsInitiated(approvalSteps[0])) {
                controlledDocument.Current_Region_Auto__c = approvalSteps[0].Approver_s_Region_Location__c;
                controlledDocument.Current_Organization_Acronym__c = approvalSteps[0].Approver_s_Organization_Acronym__c;
                controlledDocument.Current_Division_Code__c = approvalSteps[0].Approver_s_Division_Code__c;
                controlledDocument.Current_Division_Name__c = approvalSteps[0].Approver_s_Division_Name__c;
                controlledDocument.Current_Location_auto__c = approvalSteps[0].Approver_s_Location__c;
            }

        } else {//multiple steps
            System.debug('Multiple');
            for (Approval_Step__c initiatedApprovalStep : approvalSteps) {
                acronymUnique.add(initiatedApprovalStep.Approver_s_Organization_Acronym__c);
            }

            locationVals.reset();

            locationVals.concatenatedLocation = ControlledDocumentConstants.LOCATION_SIMULTANEOUS_AGENCY_CLEARANCE;
            if (acronymUnique.size() == 1) {
                String acronym;
                for (String name : acronymUnique) {
                    acronym = name;
                }   // to get value from set
                if(String.isNotBlank(acronym)){
                    locationVals.concatenatedLocation = locationVals.concatenatedLocation + ' ' + acronym;
                }
            }

            controlledDocument.Current_Region_Auto__c = locationVals.region;
            controlledDocument.Current_Organization_Acronym__c = locationVals.orgAcronym;
            controlledDocument.Current_Division_Code__c = locationVals.divisionCode;
            controlledDocument.Current_Division_Name__c = locationVals.divisionName;
            controlledDocument.Current_Location_auto__c = locationVals.concatenatedLocation;

        }
        System.debug('Location Output: ' + controlledDocument.Current_Location_auto__c);
        if (inboundConcatLocation != controlledDocument.Current_Location_auto__c) {
            System.debug('Registering Location Change');
            updatedLocationFromApprovalSteps = true;
            controlledDocument.Current_Location_Start_Date_New__c = System.now().date();
            controlledDocument.Days_In_Current_Location_New__c = 0;
        }
    }

    

    public static void updateControlledDocumentLocationFromStage(Controlled_Document__c controlledDocument) {
        System.debug('updateControlledDocumentLocationFromStage');
        System.debug('Inbound Stage: ' + controlledDocument.Stage__c);
        String inboundConcatLocation = controlledDocument.Current_Location_auto__c;
        System.debug('Inbound Location: ' + controlledDocument.Current_Location_auto__c);
        locationValues locationVals = new locationValues();

        System.debug('Stage That Changes Loc: ' + stagesThatChangeLocation.contains(controlledDocument.Stage__c));
        System.debug('Updated From Approval Steps: ' + updatedLocationFromApprovalSteps);

        if(!stagesThatChangeLocation.contains(controlledDocument.Stage__c) &&
                !updatedLocationFromApprovalSteps){
            if (!String.isBlank(controlledDocument.Assignee__c)) {
                locationVals.updateWithUserId(controlledDocument.Assignee__c, controlledDocument.Id, controlledDocument.Name);
            } else {
                locationVals.updateWithUserId(controlledDocument.OwnerId, controlledDocument.Id, controlledDocument.Name);
            }

        } else {
            // Stage = Awaiting Signature
            if (controlledDocument.Stage__c == ControlledDocumentConstants.STAGE_AWAITING_SIGNATURE) {
                // Populate new concatenated location field with the "Final Signatory" user's location info
                // Pull & match Organization Acronym, Division Name from mapping along with Region from the Salesforce User Profile.
                System.debug('Awaiting Signature');
                System.debug('User For Location: ' + controlledDocument.Final_Signatory__c);
                System.debug(locationVals);
                locationVals.updateWithUserId(controlledDocument.Final_Signatory__c, controlledDocument.Id, controlledDocument.Name);
                System.debug(locationVals);
            }

            // Stage = Closed
            if (controlledDocument.Stage__c == ControlledDocumentConstants.STAGE_CLOSED) {
                // Overwrite Location Details concatenated field with "---" in the Controlled Document record ONLY
                // All other location fields will be made blank (no additional updates to Approval Steps.
                // The "End Date" for the previous location in the Stage Histories should be entered when the record is Closed.
                locationVals.reset();
            }

            // Stage = Hold
            if (controlledDocument.Stage__c == ControlledDocumentConstants.STAGE_HOLD) {
                // Overwrite Location Details concatenated field with "---"
                // All other location fields will be made blank, there will be no additional updates to the Approval Steps,
                // but the Stage Histories will capture the Location as "---" as listed in the CDT record.
                locationVals.reset();
            }

            // Stage = External Review & the Pre-OMB Flag is marked
            if ((controlledDocument.Stage__c == ControlledDocumentConstants.STAGE_EXTERNAL_REVIEW) && (controlledDocument.OMB__c == ControlledDocumentConstants.PRE_OMB_STATUS_STRING)) {
                // Overwrite Location Details Org Acronym field with "OMB", the new concatenated field field will update accordingly
                // All other location fields will be blank, there will be no additional changes to Approval Steps,
                // but the Stage Histories will capture the location as "OMB" as listed in the Location Details.
                locationVals.reset();

                locationVals.orgAcronym = 'OMB';
                locationVals.concatenatedLocation =  'OMB';
            }

            // Stage = External Review & the Pre-OMB Flag is NOT marked
            if ((controlledDocument.Stage__c == ControlledDocumentConstants.STAGE_EXTERNAL_REVIEW) && (controlledDocument.OMB__c != ControlledDocumentConstants.PRE_OMB_STATUS_STRING)) {
                // Overwrite Location Details concatenated field  with "---"
                // All other location fields will be blank, there will be no additional updates to Approval Steps,
                // but the Stage Histories will capture the the Location as "---" as listed in the Location Details.
                locationVals.reset();
            }

            // Stage = Awaiting Closure
            if (controlledDocument.Stage__c == ControlledDocumentConstants.STAGE_AWAITING_CLOSURE) {
                // Overwrite the Location Details concatenated field with the "Record Owner" user's location info
                // Pull & match Organization Acronym, Division Name from mapping along with Region,
                // there will be no additional updates to Approval Steps, but Stage Histories will update with the information as listed in the Location Details.
                locationVals.updateWithUserId(controlledDocument.OwnerId, controlledDocument.Id, controlledDocument.Name);
            }

        }

        controlledDocument.Current_Region_Auto__c = locationVals.region;
        controlledDocument.Current_Organization_Acronym__c = locationVals.orgAcronym;
        controlledDocument.Current_Division_Code__c = locationVals.divisionCode;
        controlledDocument.Current_Division_Name__c = locationVals.divisionName;
        controlledDocument.Current_Location_auto__c = locationVals.concatenatedLocation;

        System.debug('Location Output: ' + controlledDocument.Current_Location_auto__c);
        if(inboundConcatLocation != controlledDocument.Current_Location_auto__c){
            System.debug('Registering Location Change');
            controlledDocument.Current_Location_Start_Date_New__c = System.now().date();
            controlledDocument.Days_In_Current_Location_New__c = 0;
        }

        // reset flag for next document/set of approval steps
        if(updatedLocationFromApprovalSteps){
            updatedLocationFromApprovalSteps = false;
        }
    }


    public class locationValues{
        public String concatenatedLocation {get;set;}
        public String divisionCode {get;set;}
        public String divisionName {get;set;}
        public String orgAcronym {get;set;}
        public String region {get;set;}
        
        public locationValues() {
            this.concatenatedLocation = '---';
            this.divisionCode = '';
            this.divisionName = '';
            this.orgAcronym = '';
            this.region = '';
        }
        
        public void reset() {
            this.concatenatedLocation = '---';
            this.divisionCode = '';
            this.divisionName = '';
            this.orgAcronym = '';
            this.region = '';
        }

        public void updateWithUserId(Id userID, Id recordId, String recordName) {
            User tmpUser;
            Mapping_Object__c[] tmpMap;
            String tmpDivision = '';
            
            tmpUser = userDA.getUserById(userID);
            // [SELECT Id, Division, Alternate_Division__c, User_Region__c, Alternate_Region__c From User where Id =: userID];
            if (!String.isBlank(tmpUser.Alternate_Division__c)) {
                tmpDivision = tmpUser.Alternate_Division__c;
            } else {
                if (!String.isBlank(tmpUser.Division)) {
                    tmpDivision = tmpUser.Division;
                }           
            }
            
            if (String.isBlank(tmpDivision)) {
                this.concatenatedLocation = '---';
                this.divisionCode = '';
                this.divisionName = '';
                this.orgAcronym = '';
                this.region = '';           
            } else {
                tmpDivision = tmpDivision.left(3);
                
                tmpMap = [SELECT Id, Service_Staff_Office__c, Office_Portfolio__c FROM Mapping_Object__c WHERE Name =: tmpDivision];
                
                if (tmpMap.isEmpty()) {
                    this.concatenatedLocation = tmpDivision;
                    this.divisionCode = tmpDivision;
                    this.divisionName = '';
                    this.orgAcronym = '';
                    this.region = '';   

                    Messaging.reserveSingleEmailCapacity(2);
                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                    
                    List<PermissionSetAssignment> execSecGroup = [SELECT AssigneeId, Assignee.Name, Assignee.Email FROM PermissionSetAssignment WHERE PermissionSet.Name = 'Controlled_Document_Tracker_OAS_Admin_User_CRED'];
                    String[] emailAddresses = new String[]{};
                    for(PermissionSetAssignment assignment : execSecGroup) {
                        emailAddresses.add(assignment.Assignee.Email);
                    }
					
					String recordLink = URL.getSalesforceBaseUrl().toExternalForm()+'/'+ recordId;  
                    mail.setToAddresses(emailAddresses);
					
					List<CDT_Org_Address__mdt> orgId = [select OrgID__c from CDT_Org_Address__mdt where DeveloperName='OrgEmail'];
					if (orgId[0].OrgID__c <> null){
						mail.setOrgWideEmailAddressId(orgId[0].OrgID__c);
					}
                    //OrgWideEmailAddress orgWideEmail = orgWideEmailDA.getOrgWideEmailByAddress('donotreply@gsa.gov');
                    //mail.setOrgWideEmailAddressId(orgWideEmail.Id);
                    mail.setSubject('New Division Location Added to CDT ' + recordName);
                    mail.setBccSender(false);
                    mail.setUseSignature(false);
                    
                    mail.setPlainTextBody(
                        'A new division location was added to the following Controlled Document Tracker record: \n' +
                        'Record Number: <<Number hyperlinked to record>>\n' +
                        'Division: '+ tmpDivision + '\n\n' +
                        'Please update the following as needed:\n' +
                        '1) The record\'s Approval Steps section\n' +
                        '2) The record\'s Location and Stage Histories section (if the Approval Step has already been marked)\n' +
                        '3) The central list of user divisions'
                    );
                    
                    mail.setHtmlBody(
                        '<p>A new division location was added to the following Controlled Document Tracker record:</p>' +
                        '<p><strong>Record Number:</strong> <a href=\'' + recordLink + '\'>' + recordName + '</a> <br/> <strong>Division:</strong> ' + tmpDivision + '</p>' +
                        '<p>Please update the following as needed:</p>' +
                        '<p>1) The record\'s Approval Steps section <br/>' +
                        '2) The record\'s Location and Stage Histories section (if the Approval Step has already been marked) <br/>' +
                        '3) The central list of user divisions</p>'
                    );

                    if(!Test.isRunningTest()){
                     //   Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
                    }

                                
                } else {
                    this.divisionCode = tmpDivision;
                    this.divisionName = tmpMap[0].Office_Portfolio__c;
                    this.orgAcronym = tmpMap[0].Service_Staff_Office__c;
                    this.region = (String.isBlank(tmpUser.Alternate_Division__c) ? tmpUser.User_Region__c : tmpUser.Alternate_Region__c);
                    this.concatenatedLocation = region + '-' + orgAcronym + '-' + divisionCode + '-' + divisionName;                
                }               
            }
        }
    }   
    
    private static Boolean noManualOveridesForApprovalStepLocation(Approval_Step__c approvalStep, Approval_Step__c approvalStepOld){
        return ((approvalStep.Approver_s_Region_Location__c == approvalStepOld.Approver_s_Region_Location__c) &&
                (approvalStep.Approver_s_Organization_Acronym__c == approvalStepOld.Approver_s_Organization_Acronym__c) &&
                (approvalStep.Approver_s_Division_Code__c == approvalStepOld.Approver_s_Division_Code__c) &&
                (approvalStep.Approver_s_Division_Name__c == approvalStepOld.Approver_s_Division_Name__c) &&
                (approvalStep.Approver_s_Location__c == approvalStepOld.Approver_s_Location__c));
    }
    
    private static Boolean approvalStepIsInitiated(Approval_Step__c approvalStep){
        return (approvalStep.Approval_Status__c == ControlledDocumentConstants.INITIATED_STATUS_STRING || 
                approvalStep.Approval_Status__c == ControlledDocumentConstants.INITIATED_REOPENED_STATUS_STRING);
    }
     
}