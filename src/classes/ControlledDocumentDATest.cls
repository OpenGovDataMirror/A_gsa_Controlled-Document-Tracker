@isTest
public with sharing class ControlledDocumentDATest {
	
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

	@isTest
	public static void getControlledDocumentsById_givenOneControlledDoc_shouldReturnOneControlledDoc(){
		ControlledDocumentDA docDA = new ControlledDocumentDA();
		User testUser = insertTestUser();
		Controlled_Document__c document = insertControlledDocument(testUser);
		List<Id> docIds = new List<Id>{document.Id};

		Test.startTest();
		List<Controlled_Document__c> returnedDocs = docDA.getControlledDocumentsByIds(docIds);
		Test.stopTest();

		System.assertEquals(1, returnedDocs.size());
		for(Controlled_Document__c doc : returnedDocs){
			System.assert(docIds.contains(doc.Id));
		}
	}

	@isTest
	public static void getControlledDocumentById_givenOneControlledDoc_shouldReturnSameControlledDoc(){
		ControlledDocumentDA docDA = new ControlledDocumentDA();
		User testUser = insertTestUser();
		Controlled_Document__c document = insertControlledDocument(testUser);

		Test.startTest();
		Controlled_Document__c returnedDoc = docDA.getControlledDocumentById(document.Id);
		Test.stopTest();

		System.assertEquals(document.Id,returnedDoc.Id);
	}

	@isTest
	public static void updateControlledDocument_givenStageChange(){
		ControlledDocumentDA docDA = new ControlledDocumentDA();
		User testUser = insertTestUser();
		Controlled_Document__c document = insertControlledDocument(testUser);

		Test.startTest();
		document.Stage__c = 'Drafting';
		Controlled_Document__c returnedDoc = docDa.updateControlledDocument(document);
		Test.stopTest();

		System.assertEquals('Drafting',returnedDoc.Stage__c);
	}

	private static User insertTestUser(){
		Profile p = [SELECT Id FROM Profile WHERE Name='Standard Platform User'];
		User genericUser = new User(Alias = 'atreides',
				Email='leto@testorg.com',
				User_Region__c = 'Region1',
				EmailEncodingKey='UTF-8',
				LastName='Atreides',
				UserName='leto@testorg.com',
				Division='ADF',
				LanguageLocaleKey='en_US',
				LocaleSidKey='en_US',
				TimeZoneSidKey='America/Los_Angeles',
				ProfileId = p.Id);


		insert genericUser;
		return genericUser;
	}

	private static Controlled_Document__c insertControlledDocument(User u){
		Controlled_Document__c document = new Controlled_Document__c();
		document.Date_Received__c = Date.today();
		document.Internal_External__c = 'External';
		document.GSA_Action_Required__c = 'Other';
		document.Correspondence_Type__c = 'Other';
		document.Stage__c = 'Initiated';
		document.Due_Date__c = Date.today().addDays(30);
		document.Originating_Office__c = 'Other';
		document.Final_Signatory__c = u.Id;

		insert document;
		return document;
	}
}