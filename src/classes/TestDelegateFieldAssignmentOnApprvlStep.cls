@isTest
public class TestDelegateFieldAssignmentOnApprvlStep{

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

    static testMethod void testDelegateAssignment(){

    	DelegateFieldAssignmentOnApprovalStep.isTest = true;

    	List<User> existingStandardUsers = ControlledDocumentTestUtility.getStandardUsersWithDelegatedApprovers(2);
		User testUser1 = existingStandardUsers.get(0);
		User testUser2 = existingStandardUsers.get(1);
		User testUser3 = ControlledDocumentTestUtility.getDelegateOfUser(existingStandardUsers.get(1).Id);

		Approval_Step__c step;

		System.runAs(testUser1) {
			Controlled_Document__c controlDoc = ControlledDocumentTestUtility.createTestControlDoc();
			insert controlDoc;

			step = ControlledDocumentTestUtility.createApprovalStep(controlDoc.Id, '1', testUser2.Id);
			insert step;

			////////////////////
			Test.startTest();
			////////////////////

			ControlledDocumentTestUtility.initiateApprovalStep(step.Id);

			////////////////////
			Test.stopTest();
			////////////////////

		}

		System.runAs(testUser3){

			ControlledDocumentTestUtility.approveApprovalStep(step.Id);

		}

		System.assert(true);

    }
    @isTest static void testApprovalStepValidation() {
        DelegateFieldAssignmentOnApprovalStep.isTest = true;
        
        Controlled_Document__c controlDoc = ControlledDocumentTestUtility.createTestControlDoc();
        insert controlDoc;
        Approval_Step__c approvalStep = new Approval_Step__c();
        approvalStep.Correspondence_Document__c = controlDoc.Id;
        approvalStep.Sequence__c = '1';
        approvalStep.Start_Date__c = System.today();
        approvalStep.Due_Date__c = System.today()+1;
        approvalStep.Role_of_Approver__c = 'Approver';
        approvalStep.Assigned_Approver__c = UserInfo.getUserId();
        approvalStep.Approval_Status__c ='Initiated';
        insert approvalStep;
        approvalStep.Due_Date__c = System.today()-1;
        approvalStep.Approval_Status__c = 'Approved';
        try {
            update approvalStep;
        }
        catch(DMLException e) {
            System.assertEquals('FIELD_CUSTOM_VALIDATION_EXCEPTION', e.getDmlStatusCode(0));   
        }
    }

}