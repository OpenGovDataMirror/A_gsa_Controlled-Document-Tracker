@isTest //(SeeAllData=true)
private class TestGrantAccessToChatterFiles {

    @testSetup
    static void testDataSetup(){
        
        
        Id userProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard Platform User'].Id;
		List<User> existingStandardUsers = new List<User>();
        for(Integer i = 1; i < 4; i++) {
            existingStandardUsers.add(TestUtil.buildUser(i, userProfileId, 'testCon' + i + '@fake.com'));
        }
		insert existingStandardUsers;
		
		//List<User> exsitingStandardUsers = ControlledDocumentTestUtility.getStandardUsers(2);
		User testUser1 = existingStandardUsers.get(0);
		User testUser2 = existingStandardUsers.get(1);
		
		PermissionSet execSecPerm = [SELECT Id FROM PermissionSet WHERE PermissionSet.Name = 'Controlled_Document_Tracker_OAS_Admin_User_CRED'];
		insert new PermissionSetAssignment(AssigneeId = testUser1.id, PermissionSetId = execSecPerm.Id);
		insert new PermissionSetAssignment(AssigneeId = testUser2.id, PermissionSetId = execSecPerm.Id);
    }
    
    @isTest static void testInsertFeedItem() {
        
        ControlledDocumentTestUtility.createRequiredChatterGroups();
		
		FeedItem post;
		List<ContentDocumentLink> existingLinks;
        
        List<User> exsitingStandardUsers = ControlledDocumentTestUtility.getStandardUsers(2);
		User testUser1 = exsitingStandardUsers.get(0);
		User testUser2 = exsitingStandardUsers.get(1);		
		
		Controlled_Document__c controlDoc;
		System.runAs(testUser1) {
			controlDoc = ControlledDocumentTestUtility.createTestControlDoc();
			insert controlDoc;
			post = ControlledDocumentTestUtility.createFeedItem(controlDoc.id);
			insert post;
			
		}
		
		System.runAs(testUser2) {
			Test.startTest();
			GrantAccessToChatterFiles.grantAccessToCDChatterFiles(controlDoc.Id);
			Test.stopTest();
		}
		System.assert(post.id != null);
	}	
	
}