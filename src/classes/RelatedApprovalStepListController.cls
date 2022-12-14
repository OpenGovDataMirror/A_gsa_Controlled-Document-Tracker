
 public with sharing class RelatedApprovalStepListController {
	private Controlled_Document__c document;
	public ApprovalStepSelectManager manager {get; private set;}
	public Boolean editMode {get; private set;}
	public String helpText {get; set;}

	public RelatedApprovalStepListController(ApexPages.StandardController stdController) {
		editMode = false;
		document = (Controlled_Document__c) stdController.getRecord();
		manager = new ApprovalStepSelectManager(document.id);

		String inlineTemp = Approval_Step__c.Assigned_Approver__c.getDescribe().getInlineHelpText();
		helpText = formatHelpText(inlineTemp);
	}

	public void saveTable(){
		System.debug('=== RelatedApprovalStepListController: saveTable');
		if(manager.save()){
			manager.addNewStep();
			editMode = false;
		}
	}

	public void editMode(){
		manager.removeNewStep();
		manager.backup();
		editMode = true;
	}

	public void readMode(){ //aka Cancel
		manager.restore();
		manager.addNewStep();
		editMode = false;
	}

	public String getEXTERNAL_REVIEW_ROLE_NAME(){
		return ControlledDocumentConstants.EXTERNAL_REVIEW_ROLE_NAME;
	}

	public String formatHelpText(String helpText){
		if(helpText == null) return '';
		Integer length = helpText.length();
		return helpText;
	}

}