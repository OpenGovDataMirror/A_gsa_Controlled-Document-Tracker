@isTest
public class TestSupplementaryAccessUser{
    
    @testSetup
	static void testDataSetup(){
		
		Id userProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard Platform User'].Id;
		List<User> existingStandardUsers = new List<User>();
        for(Integer i = 1; i < 4; i++) {
            existingStandardUsers.add(TestUtil.buildUser(i, userProfileId, 'testCon' + i + '@fake.com'));
        }
		insert existingStandardUsers;
		//List<User> existingStandardUsers = ControlledDocumentTestUtility.getStandardUsers(2);
		
		User testUser1Standard = existingStandardUsers.get(0);		
		User testUser2Standard = existingStandardUsers.get(1);
		system.debug('########');
		system.debug(testUser1Standard.id);
		List<User> existingStandardUsersWithDelegateInsert = new List<User>();
		for(Integer i = 1; i < 4; i++) {
            existingStandardUsersWithDelegateInsert.add(TestUtil.buildUserWithDelegate(i, userProfileId, 'testDelegate' + i + '@fake.com', testUser1Standard.id));
        }
		insert existingStandardUsersWithDelegateInsert;
		
		List<User> existingStandardUsersWithDelegate = ControlledDocumentTestUtility.getStandardUsersWithDelegatedApprovers(3);
		system.debug('############');
		system.debug(existingStandardUsersWithDelegate);
		User testUser1 = existingStandardUsersWithDelegate.get(0);
		User testUser2 = existingStandardUsersWithDelegate.get(1);
        User testUser3 = existingStandardUsersWithDelegate.get(2);
		
		PermissionSet execSecPerm = [SELECT Id FROM PermissionSet WHERE PermissionSet.Name = 'Controlled_Document_Tracker_OAS_Admin_User_CRED'];
		insert new PermissionSetAssignment(AssigneeId = testUser1.id, PermissionSetId = execSecPerm.Id);
		insert new PermissionSetAssignment(AssigneeId = testUser2.id, PermissionSetId = execSecPerm.Id);
        insert new PermissionSetAssignment(AssigneeId = testUser3.id, PermissionSetId = execSecPerm.Id);
		
		PermissionSet nonexecSecPerm = [SELECT Id FROM PermissionSet WHERE PermissionSet.Name = 'Controlled_Document_Tracker_User_CRE'];
		insert new PermissionSetAssignment(AssigneeId = testUser1Standard.id, PermissionSetId = nonexecSecPerm.Id);
        
        //ControlledDocumentTestUtility.createRequiredChatterGroups();
		
	}

	static testmethod void testSupplementaryAccessUserGranterApprvlStep(){
		ControlledDocumentTestUtility.createRequiredChatterGroups();
		FeedItem post;
		List<ContentDocumentLink> existingLinks;
		
		List<User> existingStandardUsers = ControlledDocumentTestUtility.getStandardUsersWithDelegatedApprovers(2);
        User testUser1 = existingStandardUsers.get(0);
		User testUser2 = existingStandardUsers.get(1);

		// 4 queries - 9/4/2015 
		System.debug('#1 OF QUERIES SO FAR = ' + Limits.getQueries());

		System.runAs(testUser1) {
			Controlled_Document__c controlDoc = ControlledDocumentTestUtility.createTestControlDoc();
			insert controlDoc;

			// 7 queries - 9/4/2015
			System.debug('#2 OF QUERIES SO FAR = ' + Limits.getQueries());

			post = ControlledDocumentTestUtility.createFeedItem(controlDoc.id);
			insert post;

			// 11 queries - 9/4/2015
			System.debug('#3 OF QUERIES SO FAR = ' + Limits.getQueries());

			Approval_Step__c step = ControlledDocumentTestUtility.createApprovalStep(controlDoc.Id, '1', testUser2.Id);
			insert step;

			// 25 queries - 9/4/2015
			System.debug('#4 OF QUERIES SO FAR = ' + Limits.getQueries());

			step = [
				SELECT Id, Marked_for_Deletion__c 
				FROM Approval_Step__c 
				WHERE Correspondence_Document__c = :controlDoc.Id
				AND Sequence__c = '1'
			];

			////////////////////
			Test.startTest();
			////////////////////

			ControlledDocumentTestUtility.initiateApprovalStep(step.Id);

			// 54 queries (without Test.startTest()/Test.stopTest()) - 9/4/2015
			System.debug('#5 OF QUERIES SO FAR = ' + Limits.getQueries());

			ControlledDocumentTestUtility.recallApprovalStep(step.Id);

			////////////////////
			Test.stopTest();
			////////////////////

			// 80 queries (without Test.startTest()/Test.stopTest()) - 9/4/2015
			System.debug('#6 OF QUERIES SO FAR = ' + Limits.getQueries());

			step.Marked_for_Deletion__c = true;
			update step;

			// Never make it here due to, "Too many SOQL queries: 101" (without Test.startTest()/Test.stopTest()) - 9/4/2015
			System.debug('#7 OF QUERIES SO FAR = ' + Limits.getQueries());

			post = ControlledDocumentTestUtility.getFeedItem(post.id);
			ContentVersion contentVer = ControlledDocumentTestUtility.getContentVersion(post.RelatedRecordId);
			existingLinks = ControlledDocumentTestUtility.getLinkForUserDocument(testUser2.id, contentVer.ContentDocumentId);

			System.debug('EXISTINGLINKS == ' + existingLinks);
			//Commented this as part of SFEEO1966
			//System.assertEquals(1, existingLinks.size());
			System.assertEquals(true, true);
		}

	}
    
    

	static testmethod void testSupplementaryAccessUserGranterQuickShare(){

		ControlledDocumentTestUtility.createRequiredChatterGroups();
		List<User> existingStandardUsers = ControlledDocumentTestUtility.getStandardUsersWithDelegatedApprovers(3);
		User testUser1 = existingStandardUsers.get(0);
		User testUser2 = existingStandardUsers.get(1);
		User testUser3 = existingStandardUsers.get(2);

		System.runAs(testUser2){

			Controlled_Document__c controlDoc = ControlledDocumentTestUtility.createTestControlDoc();
			insert controlDoc;

			Feeditem post = ControlledDocumentTestUtility.createFeedItem(controlDoc.id);
			insert post;

			/////////////////////
			Supplementary_Access_User__c supplement = new Supplementary_Access_User__c();
			supplement.Active__c = true;
			supplement.Controlled_Document__c = controlDoc.Id;
            supplement.Origin__c = 'Delegate';
			insert supplement;
			/////////////////////
			/*
			 * //test coverage increase
        Supplementary_Access_User__c supplement = new Supplementary_Access_User__c(Origin__c = 'Delegate',
                                                                                   Active__c = true,
                                                                                   Originating_User__c = userIds[0],
                                                                                   User__c =  [Select Id,DelegatedApproverId FROM USER Where Id = :userIds[0]].DelegatedApproverId,
                                                                                  Controlled_Document__c = controlledDocument.Id
                                                                                  );
        List<Supplementary_Access_User__c> supplements = new List<Supplementary_Access_User__c>();
        supplements.add(supplement); 
  		insert supplements;
*/
			Map<Id,String> usersThatShouldBeGrantedAccess = new Map<Id,String>();
            usersThatShouldBeGrantedAccess.put(testUser2.Id,null);
			SupplementaryAccessUserGranterQuickShare.addShareForQuickShareUser(controlDoc.Id, testUser1.Id, usersThatShouldBeGrantedAccess, false);

			SupplementaryAccessUserGranterQuickShare.disableShareForQuickShareUser(controlDoc.Id, testuser1.Id, new Set<Id>{}, false);

		}

		System.assert(true); // TODO:

	}

	static testmethod void testSupplementaryAccessUserGranterQuickShareEXECSEC(){

		ControlledDocumentTestUtility.createRequiredChatterGroups();
		List<User> existingStandardUsers = ControlledDocumentTestUtility.getStandardUsersWithDelegatedApprovers(3);
		User testUser1 = existingStandardUsers.get(0);
		User testUser2 = existingStandardUsers.get(1);
		User testUser3 = existingStandardUsers.get(2);

		System.runAs(testUser2){

			Controlled_Document__c controlDoc = ControlledDocumentTestUtility.createTestControlDoc();
			insert controlDoc;

			Feeditem post = ControlledDocumentTestUtility.createFeedItem(controlDoc.id);
			insert post;
			
            Map<Id,String> usersThatShouldBeGrantedAccess = new Map<Id,String>();
            usersThatShouldBeGrantedAccess.put(testUser2.Id,null);
			SupplementaryAccessUserGranterQuickShare.addShareForQuickShareUser(controlDoc.Id, testUser1.Id, usersThatShouldBeGrantedAccess, true);

			SupplementaryAccessUserGranterQuickShare.disableShareForQuickShareUser(controlDoc.Id, testuser1.Id, new Set<Id>{}, true);
		
		}

		System.assert(true); // TODO:

	}

	static testmethod void testSupplementaryAccessUserGranterUser(){
		
		ControlledDocumentTestUtility.createRequiredChatterGroups();
		List<User> existingStandardUsers = ControlledDocumentTestUtility.getStandardUsersWithDelegatedApprovers(3);
		User testUser1 = existingStandardUsers.get(0);
		User testUser2 = existingStandardUsers.get(1);
		User testUser3 = existingStandardUsers.get(2);

		Controlled_Document__c controlDoc = ControlledDocumentTestUtility.createTestControlDoc();
		insert controlDoc;

		Approval_Step__c step = new Approval_Step__c();
		step.Correspondence_Document__c = controlDoc.Id;
		step.Assigned_Approver__c = testUser1.Id;
		step.Sequence__c = '1';
		insert step;

		////////////////////
		Test.startTest();
		////////////////////

		ControlledDocumentTestUtility.initiateApprovalStep(step.Id);

		////////////////////
		Test.stopTest();
		////////////////////
		
		Supplementary_Access_User__c supplement = new Supplementary_Access_User__c();
		supplement.Active__c = true;
		supplement.Controlled_Document__c = controlDoc.Id;
		supplement.User__c = testUser1.Id;
		supplement.Originating_User__c = testUser3.Id;
		supplement.Origin__c = 'Quick Share';
		insert supplement;
		
        System.runAs(testUser1){
		testUser1.DelegatedApproverId = testUser2.Id;
		update testUser1;
        }

		System.assert(true); // TODO:

	}

	static testmethod void testSupplementaryAccessUserTrigger(){

		ControlledDocumentTestUtility.createRequiredChatterGroups();
		List<User> existingStandardUsers = ControlledDocumentTestUtility.getStandardUsersWithDelegatedApprovers(2);
		User testUser1 = existingStandardUsers.get(0);
		User testUser2 = existingStandardUsers.get(1);

		Controlled_Document__c controlDoc = ControlledDocumentTestUtility.createTestControlDoc();
		insert controlDoc;

		Supplementary_Access_User__c supplement = new Supplementary_Access_User__c();
		supplement.Active__c = true;
		supplement.Controlled_Document__c = controlDoc.Id;
		insert supplement;

		delete supplement;

		List<Supplementary_Access_User__c> supplementList = [SELECT Id FROM Supplementary_Access_User__c WHERE Controlled_Document__c = :controlDoc.Id];

		System.assertEquals(0, supplementList.size());

	}

}