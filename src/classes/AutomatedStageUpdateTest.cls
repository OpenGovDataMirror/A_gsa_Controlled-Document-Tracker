@isTest
public with sharing class AutomatedStageUpdateTest {

	private static Integer fakePostfix = 1;

	@isTest
	public static void updateControlledDocumentStage_givenOfficePOC_shouldGiveStageDrafting(){
		ApprovalStepDAMock mockDA = new ApprovalStepDAMock();

		Approval_Step__c step = new Approval_Step__c(Role_of_Approver__c = ControlledDocumentConstants.OFFICE_POC);
		mockDA.mockList.add(step);
		AutomatedStageUpdate.setMockDA(mockDA);

		Controlled_Document__c document = new Controlled_Document__c(Stage__c = ControlledDocumentConstants.STAGE_INITIATED);

		Test.startTest();
		AutomatedStageUpdate.updateControlledDocumentStage(document, step);
		Test.stopTest();

		System.assertNotEquals(ControlledDocumentConstants.STAGE_INITIATED, document.Stage__c);
		System.assertEquals(ControlledDocumentConstants.STAGE_DRAFTING, document.Stage__c);

	}

	@isTest
	public static void updateControlledDocumentStage_givenDrafterAndNonDraftingStep_shouldGiveStageRevise(){
		ApprovalStepDAMock mockDA = new ApprovalStepDAMock();

		Approval_Step__c step1 = new Approval_Step__c(Role_of_Approver__c = ControlledDocumentConstants.EXECSEC_REVIEWER);
		mockDA.mockList.add(step1);
		Approval_Step__c step2 = new Approval_Step__c(Role_of_Approver__c = ControlledDocumentConstants.DRAFTER);
		mockDA.mockList.add(step2);

		AutomatedStageUpdate.setMockDA(mockDA);

		Controlled_Document__c document = new Controlled_Document__c(Stage__c = ControlledDocumentConstants.STAGE_INITIATED);

		Test.startTest();
		AutomatedStageUpdate.updateControlledDocumentStage(document, step2);
		Test.stopTest();

		System.assertNotEquals(ControlledDocumentConstants.STAGE_INITIATED, document.Stage__c);
		System.assertEquals(ControlledDocumentConstants.STAGE_REVISE, document.Stage__c);

	}

	@isTest
	public static void updateControlledDocumentStage_givenEditorAndInsLetter_shouldGiveStageConcurrence(){
		ApprovalStepDAMock mockDA = new ApprovalStepDAMock();

		Approval_Step__c step1 = new Approval_Step__c();
		step1.Role_of_Approver__c = ControlledDocumentConstants.EDITOR;

		Controlled_Document__c document = new Controlled_Document__c();
		document.Stage__c = ControlledDocumentConstants.STAGE_INITIATED;
		document.Correspondence_Type__c = ControlledDocumentConstants.TYPE_INSTRUCTIONAL_LETTER;

		mockDA.mockList.add(step1);
		AutomatedStageUpdate.setMockDA(mockDA);

		Test.startTest();
		AutomatedStageUpdate.updateControlledDocumentStage(document, step1);
		Test.stopTest();

		System.assertNotEquals(ControlledDocumentConstants.STAGE_INITIATED, document.Stage__c);
		System.assertEquals(ControlledDocumentConstants.STAGE_CONCURRENCE, document.Stage__c);

	}

	@isTest
	public static void updateControlledDocumentStage_givenApproverAndOrder_shouldGiveStageProgReview(){
		ApprovalStepDAMock mockDA = new ApprovalStepDAMock();

		Approval_Step__c step1 = new Approval_Step__c();
		step1.Role_of_Approver__c = ControlledDocumentConstants.APPROVER;

		Controlled_Document__c document = new Controlled_Document__c();
		document.Stage__c = ControlledDocumentConstants.STAGE_INITIATED;
		document.Correspondence_Type__c = ControlledDocumentConstants.TYPE_ORDER;

		mockDA.mockList.add(step1);
		AutomatedStageUpdate.setMockDA(mockDA);

		Test.startTest();
		AutomatedStageUpdate.updateControlledDocumentStage(document, step1);
		Test.stopTest();

		System.assertNotEquals(ControlledDocumentConstants.STAGE_INITIATED, document.Stage__c);
		System.assertEquals(ControlledDocumentConstants.STAGE_PROGRAM_REVIEW, document.Stage__c);

	}

	@isTest
	public static void updateControlledDocumentStage_givenApproverAndDirectiveAndRevise_shouldGiveStageDirClearance(){
		ApprovalStepDAMock mockDA = new ApprovalStepDAMock();

		Approval_Step__c step1 = new Approval_Step__c();
		step1.Role_of_Approver__c = ControlledDocumentConstants.APPROVER;

		Controlled_Document__c document = new Controlled_Document__c();
		document.Stage__c = ControlledDocumentConstants.STAGE_REVISE;
		document.Correspondence_Type__c = ControlledDocumentConstants.TYPE_DIRECTIVE;

		mockDA.mockList.add(step1);
		AutomatedStageUpdate.setMockDA(mockDA);

		Test.startTest();
		AutomatedStageUpdate.updateControlledDocumentStage(document, step1);
		Test.stopTest();

		System.assertNotEquals(ControlledDocumentConstants.STAGE_REVISE, document.Stage__c);
		System.assertEquals(ControlledDocumentConstants.STAGE_DIRECTIVES_CLEARANCE, document.Stage__c);

	}

	@isTest
	public static void updateControlledDocumentStage_givenExecSecReviewer_shouldGiveStageDirConcurrence(){
		ApprovalStepDAMock mockDA = new ApprovalStepDAMock();

		Approval_Step__c step1 = new Approval_Step__c();
		step1.Role_of_Approver__c = ControlledDocumentConstants.EXECSEC_REVIEWER;

		Controlled_Document__c document = new Controlled_Document__c();
		document.Stage__c = ControlledDocumentConstants.STAGE_INITIATED;

		mockDA.mockList.add(step1);
		AutomatedStageUpdate.setMockDA(mockDA);

		Test.startTest();
		AutomatedStageUpdate.updateControlledDocumentStage(document, step1);
		Test.stopTest();

		System.assertNotEquals(ControlledDocumentConstants.STAGE_INITIATED, document.Stage__c);
		System.assertEquals(ControlledDocumentConstants.STAGE_CONCURRENCE, document.Stage__c);

	}

	@isTest
	public static void updateControlledDocumentStage_givenFYI_shouldRemainSameStage(){
		ApprovalStepDAMock mockDA = new ApprovalStepDAMock();

		Approval_Step__c step1 = new Approval_Step__c();
		step1.Role_of_Approver__c = ControlledDocumentConstants.FYI;

		Controlled_Document__c document = new Controlled_Document__c();
		document.Stage__c = ControlledDocumentConstants.STAGE_INITIATED;

		mockDA.mockList.add(step1);
		AutomatedStageUpdate.setMockDA(mockDA);

		Test.startTest();
		AutomatedStageUpdate.updateControlledDocumentStage(document, step1);
		Test.stopTest();

		System.assertEquals(ControlledDocumentConstants.STAGE_INITIATED, document.Stage__c);

	}
    //for ticket# RITM0636351 - BEGIN
    @isTest
	public static void updateControlledDocumentStage_givenApproverAndDirectiveAndRevise_shouldRetainStageDirClearance(){
		ApprovalStepDAMock mockDA = new ApprovalStepDAMock();

		Approval_Step__c step1 = new Approval_Step__c();
		step1.Role_of_Approver__c = ControlledDocumentConstants.APPROVER;

		Controlled_Document__c document = new Controlled_Document__c();
		document.Stage__c = ControlledDocumentConstants.STAGE_DIRECTIVES_CLEARANCE;
		document.Correspondence_Type__c = ControlledDocumentConstants.TYPE_DIRECTIVE;

		mockDA.mockList.add(step1);
		AutomatedStageUpdate.setMockDA(mockDA);

		Test.startTest();
		AutomatedStageUpdate.updateControlledDocumentStage(document, step1);
		Test.stopTest();

		System.assertNotEquals(ControlledDocumentConstants.STAGE_REVISE, document.Stage__c);
		System.assertEquals(ControlledDocumentConstants.STAGE_DIRECTIVES_CLEARANCE, document.Stage__c);

	}
	//for ticket# RITM0636351 - END
}