@isTest
public without sharing class AutomatedLocationUpdateTest {
	
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
	public static void updateApprovalStepLocations_givenDivision_shouldGiveDivisionLocation(){
		List<Approval_Step__c> triggerNew = new List<Approval_Step__c>();
		Map<Id, Approval_Step__c> triggerOldMap = new Map<Id, Approval_Step__c>();

		ApprovalStepDAMock mockApprovalDA = new ApprovalStepDAMock();
		ControlledDocumentDAMock mockDocumentDA = new ControlledDocumentDAMock();
		UserDAMock mockUserDA = new UserDAMock();
		
		mockUserDA.genericUser.Division = 'ADF';
		AutomatedLocationUpdate.setMockUserDA(mockUserDA);

		Approval_Step__c step = new Approval_Step__c(Role_of_Approver__c = ControlledDocumentConstants.OFFICE_POC);
		step.Sequence__c = '1';
        step.Approval_Status__c = ControlledDocumentConstants.INITIATED_STATUS_STRING;
        step.Office__c = '';
        step.Assigned_Approver__c = mockUserDA.genericUser.Id;
        mockApprovalDA.mockList.add(step);
		AutomatedLocationUpdate.setMockDA(mockApprovalDA);
		
		mockDocumentDA.document.Stage__c = ControlledDocumentConstants.STAGE_INITIATED;
		mockDocumentDA.documentList.add(mockDocumentDA.document);
		AutomatedLocationUpdate.setMockDocDA(mockDocumentDA);
		
		triggerNew.add(step);
		triggerOldMap.put(step.Id, step);
		
		Test.startTest();
			AutomatedLocationUpdate.updateApprovalStepLocations(triggerNew, triggerOldMap);
			//System.assertEquals('Region1-TMF-ADF-Technology Modernization Fund - PMO', triggerNew[0].Approver_s_Location__c);
        Test.stopTest();
	}
	
	@isTest
	public static void updateApprovalStepLocations_givenOldLocation_shouldGiveOldLocation(){
		List<Approval_Step__c> triggerNew = new List<Approval_Step__c>();
		Map<Id, Approval_Step__c> triggerOldMap = new Map<Id, Approval_Step__c>();

		ApprovalStepDAMock mockApprovalDA = new ApprovalStepDAMock();
		ControlledDocumentDAMock mockDocumentDA = new ControlledDocumentDAMock();
		UserDAMock mockUserDA = new UserDAMock();
		
		mockUserDA.genericUser.Division = 'ADF';
		AutomatedLocationUpdate.setMockUserDA(mockUserDA);

		Approval_Step__c step = new Approval_Step__c(Role_of_Approver__c = ControlledDocumentConstants.OFFICE_POC);
		step.Sequence__c = '1';
        step.Approval_Status__c = ControlledDocumentConstants.INITIATED_STATUS_STRING;
        step.Office__c = 'Test Office';
        mockApprovalDA.mockList.add(step);
		AutomatedLocationUpdate.setMockDA(mockApprovalDA);
		
		mockDocumentDA.document.Stage__c = ControlledDocumentConstants.STAGE_INITIATED;
		AutomatedLocationUpdate.setMockDocDA(mockDocumentDA);
		
		triggerNew.add(step);
		triggerOldMap.put(step.Id, step);
		
		Test.startTest();
			AutomatedLocationUpdate.updateApprovalStepLocations(triggerNew, triggerOldMap);
			System.assertEquals('Test Office', triggerNew[0].Approver_s_Location__c);
        Test.stopTest();
	}

	@isTest
	public static void updateApprovalStepLocations_givenNoStepsInitiated_shouldGiveOwnerLocation(){
		List<Approval_Step__c> triggerNew = new List<Approval_Step__c>();
		Map<Id, Approval_Step__c> triggerOldMap = new Map<Id, Approval_Step__c>();

		ApprovalStepDAMock mockApprovalDA = new ApprovalStepDAMock();
		ControlledDocumentDAMock mockDocumentDA = new ControlledDocumentDAMock();
		UserDAMock mockUserDA = new UserDAMock();
		
		mockUserDA.genericUser.Division = 'ADF';
		AutomatedLocationUpdate.setMockUserDA(mockUserDA);

		Approval_Step__c step = new Approval_Step__c(Role_of_Approver__c = ControlledDocumentConstants.OFFICE_POC);
		step.Sequence__c = '1';
        step.Office__c = '';
        step.Approval_Status__c = 'Not Initiated';
		AutomatedLocationUpdate.setMockDA(mockApprovalDA);
		
		mockDocumentDA.document.Stage__c = ControlledDocumentConstants.STAGE_INITIATED;
		AutomatedLocationUpdate.setMockDocDA(mockDocumentDA);
		
		triggerNew.add(step);
		triggerOldMap.put(step.Id, step);
		
		Test.startTest();
			AutomatedLocationUpdate.updateApprovalStepLocations(triggerNew, triggerOldMap);
			System.assertEquals(mockDocumentDA.document.Current_Location_auto__c, triggerNew[0].Approver_s_Location__c);
        Test.stopTest();
	}
    
	@isTest
	public static void updateControlledDocumentLocationFromApprovalSteps_givenInitiatedSteps(){
		List<Approval_Step__c> triggerNew = new List<Approval_Step__c>();

		ApprovalStepDAMock mockApprovalDA = new ApprovalStepDAMock();
		ControlledDocumentDAMock mockDocumentDA = new ControlledDocumentDAMock();
		UserDAMock mockUserDA = new UserDAMock();
		
		mockUserDA.genericUser.Division = 'ADF';
		AutomatedLocationUpdate.setMockUserDA(mockUserDA);

		Approval_Step__c step = new Approval_Step__c(Role_of_Approver__c = ControlledDocumentConstants.OFFICE_POC);
		step.Sequence__c = '1';
        step.Office__c = '';
        step.Approval_Status__c = 'Initiated';
        step.Correspondence_Document__c = mockDocumentDA.document.Id;
        step.Approver_s_Location__c = 'Region1-TMF-ADF-Technology Modernization Fund - PMO';
        step.Approver_s_Organization_Acronym__c = 'Test';
		AutomatedLocationUpdate.setMockDA(mockApprovalDA);
		
		mockDocumentDA.document.Stage__c = ControlledDocumentConstants.STAGE_INITIATED;
		AutomatedLocationUpdate.setMockDocDA(mockDocumentDA);
		
		
		Test.startTest();
			AutomatedLocationUpdate.updateControlledDocumentLocationFromApprovalSteps(mockDocumentDA.document, triggerNew);
			//System.assertEquals('Region1-TMF-ADF-Technology Modernization Fund - PMO', mockDocumentDA.document.Current_Location_auto__c);

			triggerNew.add(step);
			AutomatedLocationUpdate.updateControlledDocumentLocationFromApprovalSteps(mockDocumentDA.document, triggerNew);
			System.assertEquals('Region1-TMF-ADF-Technology Modernization Fund - PMO', mockDocumentDA.document.Current_Location_auto__c);

			triggerNew.add(step);
			triggerNew.add(step);
			AutomatedLocationUpdate.updateControlledDocumentLocationFromApprovalSteps(mockDocumentDA.document, triggerNew);
			System.assertEquals('Simultaneous Agency Clearance Test', mockDocumentDA.document.Current_Location_auto__c);
 
			mockDocumentDA.document.Stage__c = ControlledDocumentConstants.STAGE_CLOSED;
 			AutomatedLocationUpdate.updateControlledDocumentLocationFromStage(mockDocumentDA.document);
			System.assertEquals('---', mockDocumentDA.document.Current_Location_auto__c);
        Test.stopTest();
	}
 

	@isTest
	public static void updateControlledDocumentLocationFromStage_givenStageClosed_shouldGiveBlankLocation(){
		Controlled_Document__c controlledDoc = new Controlled_Document__c();
		
		controlledDoc.Stage__c = ControlledDocumentConstants.STAGE_CLOSED;
		
		Test.startTest();
			AutomatedLocationUpdate.updateControlledDocumentLocationFromStage(controlledDoc);
		Test.stopTest();

		System.assertEquals('---', controlledDoc.Current_Location_auto__c);
	}	
	   
	@isTest
	public static void updateControlledDocumentLocationFromStage_givenStageHold_shouldGiveBlankLocation(){
		Controlled_Document__c controlledDoc = new Controlled_Document__c();
		
		controlledDoc.Stage__c = ControlledDocumentConstants.STAGE_HOLD;
		
		Test.startTest();
			AutomatedLocationUpdate.updateControlledDocumentLocationFromStage(controlledDoc);
		Test.stopTest();

		System.assertEquals('---', controlledDoc.Current_Location_auto__c);
	}	
	   
	@isTest
	public static void updateControlledDocumentLocationFromStage_givenStageExternalReviewAndOMB_shouldGiveOMBLocation(){
		Controlled_Document__c controlledDoc = new Controlled_Document__c();
		
		controlledDoc.Stage__c = ControlledDocumentConstants.STAGE_EXTERNAL_REVIEW;
		controlledDoc.OMB__c = ControlledDocumentConstants.PRE_OMB_STATUS_STRING;
		
		Test.startTest();
			AutomatedLocationUpdate.updateControlledDocumentLocationFromStage(controlledDoc);
		Test.stopTest();

		System.assertEquals('OMB', controlledDoc.Current_Location_auto__c);
	}	

	@isTest
	public static void updateControlledDocumentLocationFromStage_givenStageExternalReview_shouldGiveBlankLocation(){
		Controlled_Document__c controlledDoc = new Controlled_Document__c();
		
		controlledDoc.Stage__c = ControlledDocumentConstants.STAGE_EXTERNAL_REVIEW;
		controlledDoc.OMB__c = 'NotOMB';
		
		Test.startTest();
			AutomatedLocationUpdate.updateControlledDocumentLocationFromStage(controlledDoc);
		Test.stopTest();

		System.assertEquals('---', controlledDoc.Current_Location_auto__c);
	}	

	@isTest
	public static void updateControlledDocumentLocationFromStage_givenStageAwaitingSignature_shouldGiveSignatoryLocation(){
		Controlled_Document__c controlledDoc = new Controlled_Document__c();
		UserDAMock mockUserDA = new UserDAMock();
		
		mockUserDA.genericUser.Division = 'ADF';
		AutomatedLocationUpdate.setMockUserDA(mockUserDA);
		
		controlledDoc.Stage__c = ControlledDocumentConstants.STAGE_AWAITING_SIGNATURE;
		controlledDoc.Final_Signatory__c = mockUserDA.genericUser.Id;

		Test.startTest();		
			AutomatedLocationUpdate.updateControlledDocumentLocationFromStage(controlledDoc);
		Test.stopTest();

		System.assertEquals('ADF', controlledDoc.Current_Location_auto__c);
	}	

	@isTest
	public static void updateControlledDocumentLocationFromStage_givenStageAwaitingClosure_shouldGiveOwnerLocation(){
		Controlled_Document__c controlledDoc = new Controlled_Document__c();
		UserDAMock mockUserDA = new UserDAMock();
		
		mockUserDA.genericUser.Division = 'ADF';
		AutomatedLocationUpdate.setMockUserDA(mockUserDA);
		
		controlledDoc.Stage__c = ControlledDocumentConstants.STAGE_AWAITING_CLOSURE;
		controlledDoc.Final_Signatory__c = mockUserDA.genericUser.Id;

		Test.startTest();		
			AutomatedLocationUpdate.updateControlledDocumentLocationFromStage(controlledDoc);
		Test.stopTest();

		System.assertEquals('ADF', controlledDoc.Current_Location_auto__c);
	}	

	@isTest
	public static void testApprovalStepUndelete(){
		Controlled_Document__c controlledDoc = new Controlled_Document__c();
		Approval_Step__c step = new Approval_Step__c(Role_of_Approver__c = ControlledDocumentConstants.OFFICE_POC, Correspondence_Document__c = controlledDoc.Id);
		List<Approval_Step__c> steps;
				
		Test.startTest();		
			insert controlledDoc;
			step.Correspondence_Document__c = controlledDoc.Id;
			insert step;
			
			steps = [SELECT Id FROM Approval_Step__c WHERE id=:step.Id];
			System.assertEquals(true, (steps.size() > 0));
			
			delete step;
			
			steps = [SELECT Id FROM Approval_Step__c WHERE id=:step.Id];
			System.assertEquals(true, (steps.size() == 0));
			
			undelete step;

			steps = [SELECT Id FROM Approval_Step__c WHERE id=:step.Id];
			System.assertEquals(true, (steps.size() > 0));			
		Test.stopTest();		
	}

}