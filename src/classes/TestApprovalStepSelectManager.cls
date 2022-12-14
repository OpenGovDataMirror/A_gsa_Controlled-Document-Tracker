
@isTest
private class TestApprovalStepSelectManager {

	@testSetup
	static void testDataSetup(){
		Id userProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard Platform User'].Id;
		List<User> exsitingStandardUsers = new List<User>();
        for(Integer i = 1; i < 6; i++) {
            exsitingStandardUsers.add(TestUtil.buildUser(i, userProfileId, 'testCon' + i + '@fake.com'));
        }
		insert exsitingStandardUsers;
		
		system.debug('#############################################################################');
		List<User> existingStandardUsers = ControlledDocumentTestUtility.getStandardUsers(2);
		
		User testUser1Standard = existingStandardUsers.get(0);		
		User testUser2Standard = existingStandardUsers.get(1);
		List<User> existingStandardUsersWithDelegateInsert = new List<User>();
		for(Integer i = 1; i < 4; i++) {
            existingStandardUsersWithDelegateInsert.add(TestUtil.buildUserWithDelegate(i, userProfileId, 'testDelegate' + i + '@fake.com', testUser1Standard.id));
        }
		insert existingStandardUsersWithDelegateInsert;
		
		List<User> existingStandardUsersWithDelegate = ControlledDocumentTestUtility.getStandardUsersWithDelegatedApprovers(2);
		User testUser1 = existingStandardUsersWithDelegate.get(0);
		User testUser2 = existingStandardUsersWithDelegate.get(1);
		
		PermissionSet execSecPerm = [SELECT Id FROM PermissionSet WHERE PermissionSet.Name = 'Controlled_Document_Tracker_OAS_Admin_User_CRED'];
		insert new PermissionSetAssignment(AssigneeId = testUser1.id, PermissionSetId = execSecPerm.Id);
		insert new PermissionSetAssignment(AssigneeId = testUser2.id, PermissionSetId = execSecPerm.Id);
	}
    
    @isTest static void testContructorWithoutApprovalSteps() {
        Controlled_Document__c controlDoc = ControlledDocumentTestUtility.createTestControlDoc();
        insert controlDoc;
        
        Test.startTest();
        ApprovalStepSelectManager manager = new ApprovalStepSelectManager(controlDoc.Id);
        Test.stopTest();

        System.assertEquals(1, manager.approvalStepSelects.size(), 'Should only contian new step');
    }
    
    @isTest static void testApprovalStepValidation() {
        Controlled_Document__c controlDoc = ControlledDocumentTestUtility.createTestControlDoc();
        insert controlDoc;
        Approval_Step__c approvalStep = new Approval_Step__c();
        approvalStep.Correspondence_Document__c = controlDoc.Id;
        approvalStep.Sequence__c = '1';
        approvalStep.Start_Date__c = System.today();
        approvalStep.Due_Date__c = System.today()+1;
        approvalStep.Role_of_Approver__c = 'Approver';
        approvalStep.Assigned_Approver__c = UserInfo.getUserId();
        approvalStep.Approval_Status__c = 'Not Initiated';
        insert approvalStep;
        approvalStep.Due_Date__c = System.today()-1;
        approvalStep.Approval_Status__c = 'Initiated';
        try {
            update approvalStep;
        }
        catch(DMLException e) {
            System.assertEquals('FIELD_CUSTOM_VALIDATION_EXCEPTION', e.getDmlStatusCode(0));   
        }
    }
    
    @isTest static void testApprovalStepBulkInitiation() {
        Controlled_Document__c controlDoc = ControlledDocumentTestUtility.createTestControlDoc();
        insert controlDoc;
        List<Approval_Step__c> stepList = new List<Approval_Step__c>();
        // case# 25836 - added condition to exclude the users with inactive delegatedapprovers
        List<User> users = [SELECT Id FROM User WHERE UserType='Standard' AND IsActive=true AND DelegatedApproverId = null LIMIT 200];
        //List<PermissionSet> psets = new List<PermissionSet>([SELECT Id, Name FROM PermissionSet WHERE Name Like 'Controlled_Document%']);
        //TestApprovalStepSelectManager.assignPsets(psets[0].Id, users);
        for(Integer i =0; i<5; i++) {
            Approval_Step__c approvalStep = new Approval_Step__c();
            approvalStep.Correspondence_Document__c = controlDoc.Id;
            approvalStep.Sequence__c = '1';
            approvalStep.Start_Date__c = System.today();
            approvalStep.Due_Date__c = System.today()+1;
            approvalStep.Role_of_Approver__c = 'Approver';
            approvalStep.Assigned_Approver__c = users[i].Id;
            approvalStep.Approval_Status__c = 'Not Initiated';
            stepList.add(approvalStep);
        }
        insert stepList;
        for(Integer i =0; i<5; i++) {
            stepList[i].Approval_Status__c = 'Initiated';
        }
        Test.startTest();
        update stepList;
        Test.stopTest();        
        System.assertEquals(5, [SELECT Id FROM Approval_Step__c WHERE Approval_Status__c='Initiated'].size());   
        
    }
    
    @isTest static void testContructorWithApprovalSteps() {
        Controlled_Document__c controlDoc = ControlledDocumentTestUtility.createTestControlDoc();
        insert controlDoc;
        insert ControlledDocumentTestUtility.createApprovalStep(controlDoc.id, '1', UserInfo.getUserId());
        
        Test.startTest();
        ApprovalStepSelectManager manager = new ApprovalStepSelectManager(controlDoc.Id);
        Test.stopTest();

        System.assertEquals(2, manager.approvalStepSelects.size(), 'Should contian new step and existing approval step.');
    }

    @isTest static void testFailedSave() {
        Controlled_Document__c controlDoc = ControlledDocumentTestUtility.createTestControlDoc();
        insert controlDoc;
        Approval_Step__c step = ControlledDocumentTestUtility.createApprovalStep(controlDoc.id, '1', UserInfo.getUserId());
        insert step;
        ApprovalStepSelectManager manager = new ApprovalStepSelectManager(controlDoc.Id);
        //Set a required Approval Step to null
        manager.approvalStepSelects.get(0).ApprovalStep.Role_of_Approver__c = null;

        Boolean testResult;
        Test.startTest();
        testResult = manager.save();
        Test.stopTest();

        Approval_Step__c resultStep = ControlledDocumentTestUtility.getApprovalStep(step.id);
        System.assertEquals(false, testResult, 'Saving process should have failed.');
        System.assertEquals(step.Office__c, resultStep.Office__c, 'Office should have remained unchanged since the save failed.');
    }

    @isTest static void testSuccessfulSave() {
        Controlled_Document__c controlDoc = ControlledDocumentTestUtility.createTestControlDoc();
        insert controlDoc;
        Approval_Step__c step = ControlledDocumentTestUtility.createApprovalStep(controlDoc.id, '1', UserInfo.getUserId());
        insert step;
        ApprovalStepSelectManager manager = new ApprovalStepSelectManager(controlDoc.Id);
        manager.approvalStepSelects.get(0).ApprovalStep.Office__c = 'testOffice';

        Boolean testResult;
        Test.startTest();
        testResult = manager.save();
        Test.stopTest();

        Approval_Step__c resultStep = ControlledDocumentTestUtility.getApprovalStep(step.id);
        System.assertEquals(true, testResult, 'Saving process should have failed.');
        System.assertEquals('testOffice', resultStep.Office__c, 'Office should have been set and saved successfully.');
    }

    @isTest static void testInitiation(){
        Controlled_Document__c controlDoc = ControlledDocumentTestUtility.createTestControlDoc();
        insert controlDoc;
        Approval_Step__c step1 = ControlledDocumentTestUtility.createApprovalStep(controlDoc.id, '1', UserInfo.getUserId());
        Approval_Step__c step2 = ControlledDocumentTestUtility.createApprovalStep(controlDoc.id, '2', UserInfo.getUserId());
        insert new List<Approval_Step__c>{step1, step2};
        ApprovalStepSelectManager manager = new ApprovalStepSelectManager(controlDoc.Id);
        manager.approvalStepSelects.get(0).selected = true;
        manager.approvalStepSelects.get(1).selected = true;
        ControlledDocumentTestUtility.initiateApprovalStep(step2.id);

        Test.startTest();
        manager.initiateSelected();
        Test.stopTest();

        System.assertEquals(1, ControlledDocumentTestUtility.getProcessWorkItem(step1.Id).size(), 'A in progress approval should exist for this approval step.');
        System.assertEquals(1, ControlledDocumentTestUtility.getProcessWorkItem(step2.Id).size(), 'Initiation should not have created a duplicate approval process.');
        System.assertEquals(false, manager.approvalStepSelects.get(0).selected, 'Selected value should have been reset to false.');
        System.assertEquals(false, manager.approvalStepSelects.get(1).selected, 'Selected value should have been reset to false.');
    }

    // this recall test is done 'naturally' in that it doesn't require custom code
    // a single user creates an approval step, initiates it, and then recalls it
    // this is standard Salesforce functionality via their approval API
    @isTest static void testNaturalRecall(){
        Controlled_Document__c controlDoc = ControlledDocumentTestUtility.createTestControlDoc();
        insert controlDoc;
        Approval_Step__c step = ControlledDocumentTestUtility.createApprovalStep(controlDoc.id, '1', UserInfo.getUserId());
        insert step;
        ApprovalStepSelectManager manager = new ApprovalStepSelectManager(controlDoc.Id);
        manager.approvalStepSelects.get(0).selected = true;
        ControlledDocumentTestUtility.initiateApprovalStep(step.id);

        Test.startTest();
        manager.recallSelected();
        Test.stopTest();

        System.assertEquals(0, ControlledDocumentTestUtility.getProcessWorkItem(step.Id).size(), 'The approval process should no longer exist.');
        System.assertEquals(false, manager.approvalStepSelects.get(0).selected, 'Selected value should have been reset to false.');
    }

    // using SeeAllDate because of an issue where creating users failed at line 19 in UserToChatterMessage.cls which is not our code
    @isTest static void testAssignedApproverRecall(){
        // this flag avoids the callout in the ApprovalStepSelectManager; we test the callout in a separate method
        ApprovalStepSelectManager.isRecallTest = true;

        Controlled_Document__c controlledDocument;
        Approval_Step__c approvalStep;
        ApprovalStepSelectManager manager;

        Profile stdUserProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User'];
        Profile adminUserProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];

        // create non admin user
        User stdUser1 = new User();
        stdUser1.FirstName = 'John';
        stdUser1.LastName = 'DoeTEST';
        stdUser1.ProfileId = stdUserProfile.Id;
        stdUser1.Affiliation__c = 'Contractor';
        stdUser1.Email = stdUser1.FirstName + '@test.com';
        stdUser1.Username = stdUser1.FirstName + '@gsa.gov.thisisatest';
        stdUser1.CommunityNickname = stdUser1.FirstName + stdUser1.LastName + 'gsagovtest';
        stdUser1.TimeZoneSidKey = 'America/New_York';
        stdUser1.LocaleSidKey = 'en_US';
        stdUser1.EmailEncodingKey = 'ISO-8859-1';
        stdUser1.LanguageLocaleKey='en_US';
        stdUser1.Alias = 'jdoetest';
        insert stdUser1;

        // create admin user
        User adminUser = new User();
        adminUser.FirstName = 'Admin';
        adminUser.LastName = 'AdminTEST';
        adminUser.ProfileId = adminUserProfile.Id;
        adminUser.Affiliation__c = 'Contractor';
        adminUser.Email = adminUser.FirstName + '@test.com';
        adminUser.Username = adminUser.FirstName + '@gsa.gov.thisisatest';
        adminUser.CommunityNickname = adminUser.FirstName + adminUser.LastName + 'gsagovtest';
        adminUser.TimeZoneSidKey = 'America/New_York';
        adminUser.LocaleSidKey = 'en_US';
        adminUser.EmailEncodingKey = 'ISO-8859-1';
        adminUser.LanguageLocaleKey='en_US';
        adminUser.Alias = 'admintes';
        insert adminUser;
        List<PermissionSet> psetList = new List<PermissionSet>([SELECT Id FROM PermissionSet WHERE Name Like 'Controlled_Document%']);
        PermissionSetAssignment passign = new PermissionSetAssignment();
        passign.AssigneeId = stdUser1.Id;
        passign.PermissionSetId = psetList[0].Id;
        insert passign;
        // create controlled document with non admin user
        System.runAs(stdUser1){
            controlledDocument = new Controlled_Document__c();
            controlledDocument.Originating_Office__c = 'AK - Office of Civil Rights';
            insert controlledDocument;
        }

        // create approval step as admin user and assign it to non admin user
        System.runAs(adminUser){
            approvalStep = new Approval_Step__c();
            approvalStep.Correspondence_Document__c = controlledDocument.Id;
            approvalStep.Sequence__c = '1';
            approvalStep.Due_Date__c = System.today();
            approvalStep.Role_of_Approver__c = 'Approver';
            approvalStep.Assigned_Approver__c = stdUser1.Id;
            approvalStep.Approval_Status__c = 'Not Initiated';
            insert approvalStep;

            // initiate it as admin user
            manager = new ApprovalStepSelectManager(controlledDocument.Id);
            manager.approvalStepSelects.get(0).selected = true;
            Approval.ProcessSubmitRequest submitRequest = new Approval.ProcessSubmitRequest();
            submitRequest.setObjectId(approvalStep.Id);
            submitRequest.setSubmitterId(adminUser.Id);
            Approval.process(submitRequest);
        }

        Test.startTest();
        System.runAs(stdUser1){
            
            manager.recallSelected();
        }
        Test.stopTest();

        System.assertEquals(1, ControlledDocumentTestUtility.getProcessWorkItem(approvalStep.Id).size());
    }


    @isTest static void testImproperUserRecall(){ 
        // this flag avoids the callout in the ApprovalStepSelectManager; we test the callout in a separate method
        ApprovalStepSelectManager.isRecallTest = true;

        Controlled_Document__c controlledDocument;
        Approval_Step__c approvalStep;
        ApprovalStepSelectManager manager;

        Profile stdUserProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User'];
        Profile adminUserProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];

        // create non admin user
        User stdUser1 = new User();
        stdUser1.FirstName = 'John';
        stdUser1.LastName = 'DoeTEST';
        stdUser1.ProfileId = stdUserProfile.Id;
        stdUser1.Affiliation__c = 'Contractor';
        stdUser1.Email = stdUser1.FirstName + '@test.com';
        stdUser1.Username = stdUser1.FirstName + '@gsa.gov.thisisatest';
        stdUser1.CommunityNickname = stdUser1.FirstName + stdUser1.LastName + 'gsagovtest';
        stdUser1.TimeZoneSidKey = 'America/New_York';
        stdUser1.LocaleSidKey = 'en_US';
        stdUser1.EmailEncodingKey = 'ISO-8859-1';
        stdUser1.LanguageLocaleKey='en_US';
        stdUser1.Alias = 'jdoetest';
        insert stdUser1;

        // create admin user
        User adminUser = new User();
        adminUser.FirstName = 'Admin';
        adminUser.LastName = 'AdminTEST';
        adminUser.ProfileId = adminUserProfile.Id;
        adminUser.Affiliation__c = 'Contractor';
        adminUser.Email = adminUser.FirstName + '@test.com';
        adminUser.Username = adminUser.FirstName + '@gsa.gov.thisisatest';
        adminUser.CommunityNickname = adminUser.FirstName + adminUser.LastName + 'gsagovtest';
        adminUser.TimeZoneSidKey = 'America/New_York';
        adminUser.LocaleSidKey = 'en_US';
        adminUser.EmailEncodingKey = 'ISO-8859-1';
        adminUser.LanguageLocaleKey='en_US';
        adminUser.Alias = 'admintes';
        insert adminUser;
        List<PermissionSet> psetList = new List<PermissionSet>([SELECT Id FROM PermissionSet WHERE Name Like 'Controlled_Document%']);
        PermissionSetAssignment passign = new PermissionSetAssignment();
        passign.AssigneeId = adminUser.Id;
        passign.PermissionSetId = psetList[0].Id;
        insert passign;
        
        // create controlled document with admin user
        System.runAs(adminUser){
            controlledDocument = new Controlled_Document__c();
            controlledDocument.Originating_Office__c = 'AK - Office of Civil Rights';
            insert controlledDocument;

            // create approval step as admin user and assign it to himself
            approvalStep = new Approval_Step__c();
            approvalStep.Correspondence_Document__c = controlledDocument.Id;
            approvalStep.Sequence__c = '1';
            approvalStep.Due_Date__c = System.today();
            approvalStep.Role_of_Approver__c = 'Approver';
            approvalStep.Assigned_Approver__c = adminUser.Id;
            approvalStep.Approval_Status__c = 'Not Initiated';
            insert approvalStep;

            // initiate it as admin user
            manager = new ApprovalStepSelectManager(controlledDocument.Id);
            manager.approvalStepSelects.get(0).selected = true;
            Approval.ProcessSubmitRequest submitRequest = new Approval.ProcessSubmitRequest();
            submitRequest.setObjectId(approvalStep.Id);
            submitRequest.setSubmitterId(adminUser.Id);
            Approval.process(submitRequest);
        }

        Test.startTest();
        System.runAs(stdUser1){
            // the user is not approved to do such a thing so it will fail
            manager.recallSelected();
        }
        Test.stopTest();

        System.assertEquals(1, ControlledDocumentTestUtility.getProcessWorkItem(approvalStep.Id).size());
    }

    @isTest static void testClearNewRow(){
        Controlled_Document__c controlDoc = ControlledDocumentTestUtility.createTestControlDoc();
        insert controlDoc;
        ApprovalStepSelectManager manager = new ApprovalStepSelectManager(controlDoc.Id);
        manager.approvalStepSelects.get(0).ApprovalStep.Office__c = 'testOffice';

        Test.startTest();
        manager.clearNewRow();
        Test.stopTest();

        System.assertEquals(null, manager.approvalStepSelects.get(0).ApprovalStep.Office__c, 'Value should have reverted to null.');
    }

    @isTest static void testBackupRestore(){
        Controlled_Document__c controlDoc = ControlledDocumentTestUtility.createTestControlDoc();
        insert controlDoc;
        Approval_Step__c step = ControlledDocumentTestUtility.createApprovalStep(controlDoc.id, '1', UserInfo.getUserId());
        insert step;
        ApprovalStepSelectManager manager = new ApprovalStepSelectManager(controlDoc.Id);
        manager.approvalStepSelects.get(0).ApprovalStep.Office__c = 'testOffice1';

        Test.startTest();
        manager.backup();
        manager.approvalStepSelects.get(0).ApprovalStep.Office__c = 'testOffice2';
        manager.restore();
        Test.stopTest();

        System.assertEquals('testOffice1', manager.approvalStepSelects.get(0).ApprovalStep.Office__c, 'Office should have been reverted.');
    }

    @isTest static void testPopulateExternalReviewParty(){
        Controlled_Document__c controlDoc = ControlledDocumentTestUtility.createTestControlDoc();
        insert controlDoc;
        Approval_Step__c step1 = ControlledDocumentTestUtility.createApprovalStep(controlDoc.id, '1', UserInfo.getUserId());
        Approval_Step__c step2 = ControlledDocumentTestUtility.createApprovalStep(controlDoc.id, '2', UserInfo.getUserId());
        Approval_Step__c step3 = ControlledDocumentTestUtility.createApprovalStep(controlDoc.id, '3', UserInfo.getUserId());
        insert new List<Approval_Step__c>{step1, step2, step3};
        ApprovalStepSelectManager manager = new ApprovalStepSelectManager(controlDoc.Id);
        manager.approvalStepSelects.get(0).ApprovalStep.Role_Of_Approver__c = ControlledDocumentConstants.EXTERNAL_REVIEW_ROLE_NAME;
        manager.approvalStepSelects.get(1).ApprovalStep.Role_Of_Approver__c = ControlledDocumentConstants.EXTERNAL_REVIEW_ROLE_NAME;
        manager.approvalStepSelects.get(1).ApprovalStep.External_Review_Party__c = 'testExternalReviewParty';
        manager.approvalStepSelects.get(2).ApprovalStep.External_Review_Party__c = 'testExternalReviewParty';

        Test.startTest();
        manager.populateExternalReviewParty();
        Test.stopTest();

        System.assertEquals(ControlledDocumentConstants.EXTERNAL_REVIEW_AUTOFILL_VALUE, manager.approvalStepSelects.get(0).ApprovalStep.External_Review_Party__c, 'Review party should have been autofilled.');
        System.assertEquals('testExternalReviewParty', manager.approvalStepSelects.get(1).ApprovalStep.External_Review_Party__c, 'Review party should not have been autofilled.');
        System.assertEquals(null, manager.approvalStepSelects.get(2).ApprovalStep.External_Review_Party__c, 'Review party should have been cleared');
    }

    @isTest static void testAddRemoveNewStep(){
        Controlled_Document__c controlDoc = ControlledDocumentTestUtility.createTestControlDoc();
        insert controlDoc;
        ApprovalStepSelectManager manager = new ApprovalStepSelectManager(controlDoc.Id);

        Test.startTest();
        manager.removeNewStep();
        manager.addNewStep();
        Test.stopTest();

        System.assertEquals(1, manager.approvalStepSelects.size(), 'New step should have been removed and re-added, leaving 1 step in the list.');
    }

    @isTest static void testInsertNewStep(){
        Controlled_Document__c controlDoc = ControlledDocumentTestUtility.createTestControlDoc();
        insert controlDoc;
        ApprovalStepSelectManager manager = new ApprovalStepSelectManager(controlDoc.Id);
        ControlledDocumentTestUtility.setApprovalStepRequiredFields(manager.approvalStepSelects.get(0).ApprovalStep, '1', UserInfo.getUserId());
        manager.approvalStepSelects.get(0).ApprovalStep.Office__c = 'testOffice';

        Test.startTest();
        manager.insertNewStep();
        Test.stopTest();

        System.assertEquals(2, manager.approvalStepSelects.size(), 'List should include both a new row and the inserted row.');
        System.assertEquals('testOffice', manager.approvalStepSelects.get(0).ApprovalStep.Office__c, 'The first approval step should be the one that was inserted.');
    }
    /*
    static void assignPsets(Id psetId, List<User> users) {
        List<PermissionSetAssignment> passignList = new List<PermissionSetAssignment>();
        Map<Id, Id> passignMap = new Map<Id, Id>();
        Set<Id> userIds = new Set<Id>();
        for(User u : users) {
            userIds.add(u.Id);
        }
        for(PermissionSetAssignment pa : [SELECT Id, AssigneeId FROM PermissionSetAssignment WHERE AssigneeId IN :userIds AND 
                                          PermissionSet.Name Like 'Controlled_Document%']) {
                                              if(!passignMap.containsKey(pa.AssigneeId))
                                              passignMap.put(pa.assigneeId, pa.Id);
                                          }
        for(User u : users) {
            if(!passignMap.containskey(u.Id))
            passignList.add(new PermissionSetAssignment(AssigneeId=u.Id, PermissionSetId=psetId));
        }
        insert passignList;
    }
    */
    @isTest static void testApprovalStepUserValidation() {
        //Controlled_Document__c controlDoc = ControlledDocumentTestUtility.createTestControlDoc();
        //insert controlDoc;
        Set<Id> userIds = new Set<Id>();
        for(PermissionSetAssignment pa : [SELECT Id, AssigneeId FROM PermissionSetAssignment WHERE AssigneeId IN :userIds AND 
                                          PermissionSet.Name Like 'Controlled_Document%']) {
                                              userIds.add(pa.AssigneeId);
                                          }
        List<User> users = new List<User>([SELECT Id FROM User WHERE Id NOT IN :userIds AND IsActive=true AND UserType='Standard' LIMIT 5]);
        System.runAs(users[0]) {
            Controlled_Document__c controlledDocument = new Controlled_Document__c();
            controlledDocument.Originating_Office__c = 'AK - Office of Civil Rights';
            insert controlledDocument;
            Approval_Step__c approvalStep = new Approval_Step__c();
            approvalStep.Correspondence_Document__c = controlledDocument.Id;
            approvalStep.Sequence__c = '1';
            approvalStep.Start_Date__c = System.today();
            approvalStep.Due_Date__c = System.today()+1;
            approvalStep.Role_of_Approver__c = 'Approver';
            approvalStep.Assigned_Approver__c = users[0].Id;
            approvalStep.Approval_Status__c = 'Not Initiated';
            //insert approvalStep;
            //approvalStep.Due_Date__c = System.today()-1;
            //approvalStep.Approval_Status__c = 'Initiated';
            //approvalStep.Assigned_Approver__c = users[0].Id;        
            try {
                insert approvalStep;
            }
            catch(DMLException e) {
                System.assertEquals('FIELD_CUSTOM_VALIDATION_EXCEPTION', e.getDmlStatusCode(0));   
            }
        }    
    }

    @isTest static void testInsertStepOnClosedDocument() {
        List<Id> userIds = new List<Id>();
        for (PermissionSetAssignment pa : [
                SELECT Id, AssigneeId
                FROM PermissionSetAssignment
                WHERE PermissionSet.Name Like 'Controlled_Document%'
        ]) {
            userIds.add(pa.AssigneeId);
        }

        Controlled_Document__c controlledDocument = new Controlled_Document__c();
        controlledDocument.Originating_Office__c = 'AK - Office of Civil Rights';
        controlledDocument.Stage__c = ControlledDocumentConstants.STAGE_CLOSED;
        insert controlledDocument;
        Approval_Step__c approvalStep = new Approval_Step__c();
        approvalStep.Correspondence_Document__c = controlledDocument.Id;
        approvalStep.Sequence__c = '1';
        approvalStep.Start_Date__c = System.today();
        approvalStep.Due_Date__c = System.today() + 1;
        approvalStep.Role_of_Approver__c = 'Approver';
        approvalStep.Assigned_Approver__c = userIds[0];
        approvalStep.Approval_Status__c = 'Not Initiated';

        Test.startTest();
        try {
            insert approvalStep;
        } catch (DmlException e) {
            System.assertEquals('FIELD_CUSTOM_VALIDATION_EXCEPTION', e.getDmlStatusCode(0));
        }
        Test.stopTest();
    }

    @isTest static void testUpdateStepOnClosedDocument() {
        List<Id> userIds = new List<Id>();
        for (PermissionSetAssignment pa : [
                SELECT Id, AssigneeId
                FROM PermissionSetAssignment
                WHERE PermissionSet.Name Like 'Controlled_Document%'
        ]) {
            userIds.add(pa.AssigneeId);
        }

        Controlled_Document__c controlledDocument = new Controlled_Document__c();
        controlledDocument.Originating_Office__c = 'AK - Office of Civil Rights';
        insert controlledDocument;
        Approval_Step__c approvalStep = new Approval_Step__c();
        approvalStep.Correspondence_Document__c = controlledDocument.Id;
        approvalStep.Sequence__c = '1';
        approvalStep.Start_Date__c = System.today();
        approvalStep.Due_Date__c = System.today() + 1;
        approvalStep.Role_of_Approver__c = 'Approver';
        approvalStep.Assigned_Approver__c = userIds[0];
        approvalStep.Approval_Status__c = 'Not Initiated';
        insert approvalStep;

        Test.startTest();
        controlledDocument.Stage__c = ControlledDocumentConstants.STAGE_CLOSED;
        update controlledDocument;
        try {
            update approvalStep;
        } catch (DmlException e) {
            System.assertEquals('FIELD_CUSTOM_VALIDATION_EXCEPTION', e.getDmlStatusCode(0));
        }
        Test.stopTest();
    }
}