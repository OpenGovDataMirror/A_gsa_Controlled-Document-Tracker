@isTest
public with sharing class ApprovalStepDATest {
	
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
	public static void getAllInitiatedApprovalStepsWithControlledDocumentId_givenUninitiatedStep_shouldReturnEmptyList(){
		ApprovalStepDA testDA = new ApprovalStepDA();
		User testUser = insertTestUser();
		Controlled_Document__c document = insertControlledDocument(testUser);
		Approval_Step__c step = insertApprovalStep(testUser, document);

		Test.startTest();
		List<Approval_Step__c> steps = testDA.getAllInitiatedApprovalStepsWithControlledDocumentId(document.Id);
		Test.stopTest();

		System.assertEquals(0, steps.size());
	}

	@isTest
	public static void getAllInitiatedApprovalStepsWithControlledDocumentId_givenInitiatedStep_shouldReturnOneStep(){
		ApprovalStepDA testDA = new ApprovalStepDA();
		User testUser = insertTestUser();
		Controlled_Document__c document = insertControlledDocument(testUser);
		Approval_Step__c step = insertInitiatedApprovalStep(testUser, document);

		Test.startTest();
		List<Approval_Step__c> steps = testDA.getAllInitiatedApprovalStepsWithControlledDocumentId(document.Id);
		Test.stopTest();

		System.assertEquals(1, steps.size());
		System.assertEquals(step.Id, steps[0].Id);
	}

	@isTest
	public static void getAllInitiatedApprovalStepsWithControlledDocumentIds_givenInitiatedSteps_shouldReturnTwoSteps(){
		ApprovalStepDA testDA = new ApprovalStepDA();
		User testUser = insertTestUser();
		Controlled_Document__c document1 = insertControlledDocument(testUser);
		Approval_Step__c step1 = insertInitiatedApprovalStep(testUser, document1);
		Controlled_Document__c document2 = insertControlledDocument(testUser);
		Approval_Step__c step2 = insertInitiatedApprovalStep(testUser, document2);

		List<Id> docIds = new List<Id>{
				document1.Id,
				document2.Id
		};

		List<Id> stepIds = new List<Id>{
				step1.Id,
				step2.Id
		};

		Test.startTest();
		List<Approval_Step__c> steps = testDA.getAllInitiatedApprovalStepsWithControlledDocumentIds(docIds);
		Test.stopTest();

		System.assertEquals(2, steps.size());
		System.debug('=== steps: ' +  steps);
		System.debug('=== stepIds: ' +  stepIds);
		
		for (Approval_Step__c s : steps){
			System.debug(s);
			System.assert(stepIds.contains(s.Id));
		}

		List<AggregateResult> maxSteps = testDA.getMaxInitiatedTimeForDocumentIds(docIds);
		System.debug('=== maxSteps: ' +  maxSteps);
		System.assertEquals(2, maxSteps.size());


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

	private static Approval_Step__c insertApprovalStep(User u, Controlled_Document__c document){
		Approval_Step__c step = new Approval_Step__c();
		step.Sequence__c = '1';
		step.Due_Date__c = Date.today().addDays(7);
		step.Role_of_Approver__c = 'Drafter';
		step.Approval_Status__c = 'Not Initiated';
		step.Assigned_Approver__c = u.Id;
		step.Correspondence_Document__c = document.Id;

		insert step;
		return  step;
	}

	private static Approval_Step__c insertInitiatedApprovalStep(User u, Controlled_Document__c document){
		Approval_Step__c step = new Approval_Step__c();
		step.Sequence__c = '1';
		step.Due_Date__c = Date.today().addDays(7);
		step.Role_of_Approver__c = 'Drafter';
		step.Approval_Status__c = 'Initiated';
		step.Assigned_Approver__c = u.Id;
		step.Correspondence_Document__c = document.Id;

		insert step;
		return  step;
	}
}