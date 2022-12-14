@isTest
private class TestUpdateDaysOpenOnApprovalStepsBatch {

	@testSetup
	static void testDataSetup(){
		Id userProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard Platform User'].Id;
		List<User> existingStandardUsers = new List<User>();
        for(Integer i = 1; i < 6; i++) {
            existingStandardUsers.add(TestUtil.buildUser(i, userProfileId, 'testCon' + i + '@fake.com'));
        }
		insert existingStandardUsers;
		
		system.debug('#############################################################################');
		//List<User> existingStandardUsers = ControlledDocumentTestUtility.getStandardUsers(2);
		
		User testUser1Standard = existingStandardUsers.get(0);		
		User testUser2Standard = existingStandardUsers.get(1);
		List<User> existingStandardUsersWithDelegateInsert = new List<User>();
		for(Integer i = 1; i < 4; i++) {
            existingStandardUsersWithDelegateInsert.add(TestUtil.buildUserWithDelegate(i, userProfileId, 'testDelegate' + i + '@fake.com', testUser1Standard.id));
        }
		insert existingStandardUsersWithDelegateInsert;
		
		//List<User> existingStandardUsersWithDelegate = ControlledDocumentTestUtility.getStandardUsersWithDelegatedApprovers(2);
		User testUser1 = existingStandardUsersWithDelegateInsert.get(0);
		User testUser2 = existingStandardUsersWithDelegateInsert.get(1);
		
		PermissionSet execSecPerm = [SELECT Id FROM PermissionSet WHERE PermissionSet.Name = 'Controlled_Document_Tracker_OAS_Admin_User_CRED'];
		insert new PermissionSetAssignment(AssigneeId = testUser1Standard.id, PermissionSetId = execSecPerm.Id);
		insert new PermissionSetAssignment(AssigneeId = testUser2.id, PermissionSetId = execSecPerm.Id);
	}

	@isTest static void testBatchExecution() {
		Controlled_Document__c controlDoc;
		Approval_Step__c step;
		List<User> exsitingStandardUsers = ControlledDocumentTestUtility.getStandardUsers(1);
		User testUser1 = exsitingStandardUsers.get(0);
		
		System.runAs(testUser1) {
			controlDoc = ControlledDocumentTestUtility.createTestControlDoc();
			//controlDoc.ExecSec_Start_Date__c = System.today();
			insert controlDoc;
			step = ControlledDocumentTestUtility.createApprovalStep(controlDoc.id, '1', testUser1.Id);
			step.Approval_Status__c = ControlledDocumentConstants.INITIATED_STATUS_STRING;
			insert step;
		}

		Test.startTest();
		//System.schedule('ScheduleUpdateDaysOpenOnApprovalStepsBatch', '0 0 0 1 1 ? 2022', new ScheduleUpdateDaysOpenOnApprovalSteps());
		UpdateDaysOpenOnApprovalStepsBatch u = new UpdateDaysOpenOnApprovalStepsBatch();
		Database.executeBatch(u);
		Test.stopTest();

		controlDoc = ControlledDocumentTestUtility.getControlledDocument(controlDoc.id);
		System.assertEquals(UserInfo.getUserId(), controlDoc.LastModifiedById, 'If batch ran successfully, last modified user should be the same as the user that is running the test.');
	}

}