
@isTest
private class TestRelatedApprovalStepListController {

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
	
	@isTest static void testNoApprovalSteps() {
		Controlled_Document__c controlDoc = ControlledDocumentTestUtility.createTestControlDoc();
		insert controlDoc;

		Test.startTest();
		ApexPages.StandardController sc = new ApexPages.StandardController(controlDoc);
		RelatedApprovalStepListController controller = new RelatedApprovalStepListController(sc);
		Test.setCurrentPage(Page.RelatedApprovalStepList);
		Test.stopTest();

		System.assertEquals(1, controller.manager.approvalStepSelects.size(), 'The approvalStepSelects list should only include the new row.');
		System.assertEquals(false, controller.editMode);
	}

	@isTest static void testWithExistingApprovalSteps() {
		List<Approval_Step__c> newApprovalSteps = new List<Approval_Step__c>();

		Controlled_Document__c controlDoc = ControlledDocumentTestUtility.createTestControlDoc();
		Controlled_Document__c otherControlDoc = ControlledDocumentTestUtility.createTestControlDoc();
		insert new List<Controlled_Document__c>{controlDoc, otherControlDoc};

		newApprovalSteps.add(ControlledDocumentTestUtility.createApprovalStep(controlDoc.id, '1', UserInfo.getUserId()));
		newApprovalSteps.add(ControlledDocumentTestUtility.createApprovalStep(controlDoc.id, '2', UserInfo.getUserId()));
		newApprovalSteps.add(ControlledDocumentTestUtility.createApprovalStep(otherControlDoc.id, '1', UserInfo.getUserId()));
		insert newApprovalSteps;

		Test.startTest();
		ApexPages.StandardController sc = new ApexPages.StandardController(controlDoc);
		RelatedApprovalStepListController controller = new RelatedApprovalStepListController(sc);
		Test.setCurrentPage(Page.RelatedApprovalStepList);
		Test.stopTest();

		System.assertEquals(3, controller.manager.approvalStepSelects.size(), 'The approvalStepSelects list should only include the 2 inserted approval steps and the new row.');
		System.assertEquals(false, controller.editMode);
	}

	@isTest static void testEditMode(){
		List<Approval_Step__c> newApprovalSteps = new List<Approval_Step__c>();

		Controlled_Document__c controlDoc = ControlledDocumentTestUtility.createTestControlDoc();
		insert controlDoc;
		insert ControlledDocumentTestUtility.createApprovalStep(controlDoc.id, '1', UserInfo.getUserId());
		ApexPages.StandardController sc = new ApexPages.StandardController(controlDoc);
		RelatedApprovalStepListController controller = new RelatedApprovalStepListController(sc);
		Test.setCurrentPage(Page.RelatedApprovalStepList);

		Test.startTest();
		controller.editMode();
		Test.stopTest();

		System.assertEquals(true, controller.editMode);
		System.assertEquals(1, controller.manager.ApprovalStepSelects.size(), 'Manager should have removed the last row, leaving only 1 approval step.');
	}

	@isTest static void testReadMode(){
		List<Approval_Step__c> newApprovalSteps = new List<Approval_Step__c>();

		Controlled_Document__c controlDoc = ControlledDocumentTestUtility.createTestControlDoc();
		insert controlDoc;
		insert ControlledDocumentTestUtility.createApprovalStep(controlDoc.id, '1', UserInfo.getUserId());
		ApexPages.StandardController sc = new ApexPages.StandardController(controlDoc);
		RelatedApprovalStepListController controller = new RelatedApprovalStepListController(sc);
		Test.setCurrentPage(Page.RelatedApprovalStepList);
		controller.editMode();

		Test.startTest();
		controller.readMode();
		Test.stopTest();

		System.assertEquals(false, controller.editMode);
		System.assertEquals(2, controller.manager.ApprovalStepSelects.size(), 'Manager should have readded the last row, leaving 2 approval steps.');
	}

	@isTest static void testSaveTable(){
		List<Approval_Step__c> newApprovalSteps = new List<Approval_Step__c>();

		Controlled_Document__c controlDoc = ControlledDocumentTestUtility.createTestControlDoc();
		insert controlDoc;
		insert ControlledDocumentTestUtility.createApprovalStep(controlDoc.id, '1', UserInfo.getUserId());
		ApexPages.StandardController sc = new ApexPages.StandardController(controlDoc);
		RelatedApprovalStepListController controller = new RelatedApprovalStepListController(sc);
		Test.setCurrentPage(Page.RelatedApprovalStepList);
		controller.editMode();

		Test.startTest();
		controller.saveTable();
		Test.stopTest();

		System.assertEquals(false, controller.editMode);
		System.assertEquals(2, controller.manager.ApprovalStepSelects.size(), 'Manager should have readded the last row, leaving 2 approval steps.');
	}

	@isTest static void testFailedSaveTable(){
		List<Approval_Step__c> newApprovalSteps = new List<Approval_Step__c>();

		Controlled_Document__c controlDoc = ControlledDocumentTestUtility.createTestControlDoc();
		insert controlDoc;
		Approval_Step__c step = ControlledDocumentTestUtility.createApprovalStep(controlDoc.id, '1', UserInfo.getUserId());
		step.Office__c = null;
		insert step;
		ApexPages.StandardController sc = new ApexPages.StandardController(controlDoc);
		RelatedApprovalStepListController controller = new RelatedApprovalStepListController(sc);
		Test.setCurrentPage(Page.RelatedApprovalStepList);
		controller.editMode();

        System.debug('=== controller.editMode: ' + controller.editMode);
		System.debug('=== controller.manager.save(): ' + controller.manager.save());
        
		Test.startTest();
		controller.saveTable();
		Test.stopTest();

        System.debug('=== controller.editMode: ' + controller.editMode);
		System.debug('=== controller.manager.save(): ' + controller.manager.save());

        System.assertEquals(false, controller.editMode);
		System.assertEquals(1, controller.manager.ApprovalStepSelects.size(), 'Manager should have remained in edit mode, leaving only 1 row.');
	}

	@isTest static void testGetExternalReviewRoleName(){
		List<Approval_Step__c> newApprovalSteps = new List<Approval_Step__c>();

		Controlled_Document__c controlDoc = ControlledDocumentTestUtility.createTestControlDoc();
		insert controlDoc;
		insert ControlledDocumentTestUtility.createApprovalStep(controlDoc.id, '1', UserInfo.getUserId());
		ApexPages.StandardController sc = new ApexPages.StandardController(controlDoc);
		RelatedApprovalStepListController controller = new RelatedApprovalStepListController(sc);
		Test.setCurrentPage(Page.RelatedApprovalStepList);

		Test.startTest();
		controller.getEXTERNAL_REVIEW_ROLE_NAME();
		Test.stopTest();

		System.assertEquals(ControlledDocumentConstants.EXTERNAL_REVIEW_ROLE_NAME, controller.getEXTERNAL_REVIEW_ROLE_NAME());
	}
}