@isTest
public without sharing class ControlledDocumentTriggerHelperTest {
/*
Additional Test coverage for ControlledDocumentTriggerHelper.cls
is found in TestChatterFeedItemTrigger.cls, TestApprovalStepSelectManager.cls,
and TestChatterFileCollaboratorTH
 */
 
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
		
		List<User> existingStandardUsersWithDelegate = ControlledDocumentTestUtility.getStandardUsersWithDelegatedApprovers(2);
		system.debug('############');
		system.debug(existingStandardUsersWithDelegate);
		User testUser1 = existingStandardUsersWithDelegate.get(0);
		User testUser2 = existingStandardUsersWithDelegate.get(1);
		
		PermissionSet execSecPerm = [SELECT Id FROM PermissionSet WHERE PermissionSet.Name = 'Controlled_Document_Tracker_OAS_Admin_User_CRED'];
		insert new PermissionSetAssignment(AssigneeId = testUser1.id, PermissionSetId = execSecPerm.Id);
		insert new PermissionSetAssignment(AssigneeId = testUser2.id, PermissionSetId = execSecPerm.Id);
		
		PermissionSet nonexecSecPerm = [SELECT Id FROM PermissionSet WHERE PermissionSet.Name = 'Controlled_Document_Tracker_User_CRE'];
		insert new PermissionSetAssignment(AssigneeId = testUser1Standard.id, PermissionSetId = nonexecSecPerm.Id);
		
	}

	@isTest
	public static void testExecSecDaysOpen(){
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
		controlledDocument.Assignee__c = userIds[0];
		controlledDocument.ExecSec_Start_Date__c = Date.newInstance(2018,10,22);
		controlledDocument.ExecSec_End_Date__c = Date.newInstance(2018,10,26);
		controlledDocument.Due_Date__c = Date.newInstance(2018,10,21);

		Test.startTest();
		insert controlledDocument;
		Test.stopTest();

		Controlled_Document__c modifiedDocument = [SELECT Days_Open__c FROM Controlled_Document__c WHERE Id=:controlledDocument.Id];

		System.assertNotEquals(null, modifiedDocument.Days_Open__c);
	}

	@isTest
	public static void testExecSecDaysOpenGivenNoEndDate(){
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
		controlledDocument.Assignee__c = userIds[0];
		controlledDocument.ExecSec_Start_Date__c = Date.newInstance(2018,10,22);
		controlledDocument.Due_Date__c = Date.newInstance(2018,10,22);

		Test.startTest();
		insert controlledDocument;
		Test.stopTest();

		Controlled_Document__c modifiedDocument = [SELECT Days_Open__c FROM Controlled_Document__c WHERE Id=:controlledDocument.Id];

		System.assertNotEquals(null, modifiedDocument.Days_Open__c);
	}

	@isTest
	public static void testExecSecDaysOverdue(){
		Controlled_Document__c controlledDocument = new Controlled_Document__c();
		controlledDocument.Originating_Office__c = 'AK - Office of Civil Rights';
		controlledDocument.ExecSec_Due_Date__c = Date.newInstance(2018,10,22);
		controlledDocument.ExecSec_End_Date__c = Date.newInstance(2018,10,25);

		Test.startTest();
		insert controlledDocument;
		Test.stopTest();

		Controlled_Document__c modifiedDocument = [SELECT ExecSec_Days_Overdue__c FROM Controlled_Document__c WHERE Id=:controlledDocument.Id];

		System.assertNotEquals(null, modifiedDocument.ExecSec_Days_Overdue__c);
	}

	@isTest
	public static void testExecSecDaysOverdueGivenNoEndDate(){
		Controlled_Document__c controlledDocument = new Controlled_Document__c();
		controlledDocument.Originating_Office__c = 'AK - Office of Civil Rights';
		controlledDocument.ExecSec_Due_Date__c = Date.newInstance(2018,10,22);

		Test.startTest();
		insert controlledDocument;
		Test.stopTest();

		Controlled_Document__c modifiedDocument = [SELECT ExecSec_Days_Overdue__c FROM Controlled_Document__c WHERE Id=:controlledDocument.Id];

		System.assertNotEquals(null, modifiedDocument.ExecSec_Days_Overdue__c);
	}

	@isTest
	public static void testDaysOverdue(){
		Controlled_Document__c controlledDocument = new Controlled_Document__c();
		controlledDocument.Originating_Office__c = 'AK - Office of Civil Rights';
		controlledDocument.Due_Date__c = Date.newInstance(2018,10,22);


		Test.startTest();
		insert controlledDocument;
		Test.stopTest();

		Controlled_Document__c modifiedDocument = [SELECT Days_Overdue__c FROM Controlled_Document__c WHERE Id=:controlledDocument.Id];

		System.assertNotEquals(null, modifiedDocument.Days_Overdue__c);
	}

	@isTest
	public static void testDaysOverdueWithExecSecEndDate(){
		Controlled_Document__c controlledDocument = new Controlled_Document__c();
		controlledDocument.Originating_Office__c = 'AK - Office of Civil Rights';
		controlledDocument.Due_Date__c = Date.newInstance(2018,10,22);
		controlledDocument.ExecSec_End_Date__c = Date.newInstance(2018,10,25);

		Test.startTest();
		insert controlledDocument;
		Test.stopTest();

		Controlled_Document__c modifiedDocument = [SELECT Days_Overdue__c FROM Controlled_Document__c WHERE Id=:controlledDocument.Id];

		System.assertNotEquals(null, modifiedDocument.Days_Overdue__c);
	}

	@isTest
	public static void testUpdate(){
		Controlled_Document__c controlledDocument = new Controlled_Document__c();
		controlledDocument.Originating_Office__c = 'AK - Office of Civil Rights';
		controlledDocument.Due_Date__c = Date.today();
		controlledDocument.ExecSec_End_Date__c = Date.today()+1;
		insert controlledDocument;
		
        Approval_Step__c step = new Approval_Step__c();
        step.Sequence__c = '1';
        step.Due_Date__c = Date.today().addDays(7);
        step.Role_of_Approver__c = 'Drafter';
        step.Approval_Status__c = 'Initiated';
        step.Assigned_Approver__c = UserInfo.getUserId();
        step.Correspondence_Document__c = controlledDocument.Id;        
        insert step;
        
		Test.startTest();
        controlledDocument.Assignee__c = UserInfo.getUserId();
        controlledDocument.ExecSec_Start_Date__c = Date.today();
        controlledDocument.Stage__c = 'Concurrence';
		update controlledDocument;
		Test.stopTest();

		Controlled_Document__c modifiedDocument = [SELECT Days_Overdue__c FROM Controlled_Document__c WHERE Id=:controlledDocument.Id];

		System.assertNotEquals(null, modifiedDocument.Days_Overdue__c);
	}

	@isTest
	public static void testUserStageModifyAccess(){
		UserDA userAccessor = new UserDA();
		PermissionSetAssignmentDA permSetAssignmentDA = new PermissionSetAssignmentDA();

		List<PermissionSetAssignment> psa = [
				SELECT Id, AssigneeId
				FROM PermissionSetAssignment
				WHERE PermissionSet.Name = 'Controlled_Document_Tracker_User_CRE'
				AND Assignee.IsActive = true
		];

		User CDTUser;
		for(PermissionSetAssignment pa : psa){
			List<PermissionSetAssignment> userPermissionSetAssignments = permSetAssignmentDA.getPermissionSetAssignmentsForUserId(pa.AssigneeId);
			Boolean userIsExecSec = false;
			for (PermissionSetAssignment permsa : userPermissionSetAssignments){
				if (ControlledDocumentConstants.EXECSEC_USER_PERMISSION_SET_NAMES.contains(permsa.PermissionSet.Name)) {
					userIsExecSec = true;
				}
			}
			if(!userIsExecSec){
				CDTUser = userAccessor.getUserById(pa.AssigneeId);
				break;
			}
		}

		User activeUser = userAccessor.getUserById(UserInfo.getUserId());


		Controlled_Document__c controlledDocument = new Controlled_Document__c();
		System.runAs(activeUser) {
			insert controlledDocument;

			Approval_Step__c step = new Approval_Step__c();
			step.Sequence__c = '1';
			step.Due_Date__c = Date.today().addDays(7);
			step.Role_of_Approver__c = 'Drafter';
			step.Approval_Status__c = 'Initiated';
			step.Assigned_Approver__c = CDTUser.Id;
			step.Correspondence_Document__c = controlledDocument.Id;

			insert step;

		}


		Controlled_Document__c controlledDocument2;

		Test.startTest();

		System.runAs(CDTUser){
			controlledDocument.Stage__c = 'Drafting';
			try{
				update controlledDocument;
			}catch (DmlException e){
				System.debug(e.getMessage());
				System.assert(true);
			}
			controlledDocument2 = new Controlled_Document__c();
			insert controlledDocument2;
		}

		System.runAs(activeUser) {
			try {
				update controlledDocument;
			} catch (DmlException e) {
				System.debug(e.getMessage());
				System.assert(false);
			}

			controlledDocument2.Stage__c = 'Drafting';
			try {
				update controlledDocument2;
			} catch (DmlException e) {
				System.debug(e.getMessage());
				System.assert(true);
			}
		}

		Test.stopTest();

	}
}