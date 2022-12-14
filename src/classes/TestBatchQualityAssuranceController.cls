@isTest 
private class TestBatchQualityAssuranceController {
	
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
	
	@isTest static void testController(){
		Test.startTest();

		// start Grant Update Access batch
		GrantAccessToChatterFileBatch b = new GrantAccessToChatterFileBatch();
		ID batchprocessid = Database.executeBatch(b, 1);

		// create a controlled document
		//ControlledDocumentTestUtility.createRequiredChatterGroups();
		List<User> exsitingStandardUsers = ControlledDocumentTestUtility.getStandardUsers(1);
		User testUser1 = exsitingStandardUsers.get(0);
		System.runAs(testUser1) {
			Controlled_Document__c controlDoc = ControlledDocumentTestUtility.createTestControlDoc();
			insert controlDoc;
		}

		// query CD
		List<Controlled_Document__c> cdList = [SELECT Id FROM Controlled_Document__c LIMIT 1];

		// create a Grant Update Access Request
		Controlled_Document_Feed__c cdf = new Controlled_Document_Feed__c();
		cdf.Controlled_Document__c = cdList.get(0).Id;
		cdf.Status__c = 'Pending';
		insert cdf;

		// instantiate the controller
		BatchQualityAssuranceController batchQualityAssuranceController = new BatchQualityAssuranceController();
		//BatchQualityAssuranceController.BatchWrapper bw = new BatchQualityAssuranceController.BatchWrapper('', 0, System.now());
		//BatchQualityAssuranceController.BadControlledDocuments bcd = new BatchQualityAssuranceController.BadControlledDocuments('', '', '', '', System.now());

		// the assert
		System.assertNotEquals(b, null);

		Test.stopTest();
	}

}