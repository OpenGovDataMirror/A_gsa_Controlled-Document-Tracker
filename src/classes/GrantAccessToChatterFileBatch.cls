
public class GrantAccessToChatterFileBatch implements Database.Batchable<sObject>{

	public static final String OVERRIDE_EMAIL_SUBJECT = 'ExecSec Proxy request APPROVED for ';
	public static boolean isGrantAccessToChatterFileBatch = False;
	
	public GrantAccessToChatterFileBatch(){
		// do nothing
	}

	public List<sObject> start(Database.BatchableContext BC){
		List<sObject> scope = new List<sObject>();
		// if no GUA Requests are to be processed check if there are Approval Steps to Recall
		if(scope.isEmpty()){
			scope = getRecallRequests();
		}
		// if no GUA Requests are to be processed and no Approval Steps to Recall then see if there are ExecSec Overrides to process
		if(scope.isEmpty()){
			scope = getOverrides();
		}
		return scope;
	}
	
	public void execute(Database.BatchableContext BC, List<sObject> scope){
		isGrantAccessToChatterFileBatch = True;

		// APPROVAL STEP RECALL REQUESTS ////////////////////////////////////////////////////////////////////////////////////////////////
		if(scope[0] instanceOf Approval_Step_Recall_Request__c){
			Approval_Step_Recall_Request__c request = (Approval_Step_Recall_Request__c) scope[0];
			List<Approval_Step_Recall_Request__c> requestsToRecall = new List<Approval_Step_Recall_Request__c>();
			requestsToRecall.add(request);

			dealWithRecalls(requestsToRecall);
			dealWithOverrides(getOverrides());
		}

		// EXECSEC APPROVAL STEP OVERRIDE REQUEST ///////////////////////////////////////////////////////////////////////////////////////
		if(scope[0] instanceOf ExecSec_Approval_Step_Override_Request__c){
			ExecSec_Approval_Step_Override_Request__c request = (ExecSec_Approval_Step_Override_Request__c) scope[0];
			List<ExecSec_Approval_Step_Override_Request__c> overrideRequests = new List<ExecSec_Approval_Step_Override_Request__c>();
			overrideRequests.add(request);
			
			dealWithOverrides(overrideRequests);
        }
	}
	
	public void finish(Database.BatchableContext BC){		

		AsyncApexJob a = [Select Id, Status, NumberOfErrors, JobItemsProcessed,
						 TotalJobItems, ExtendedStatus, CreatedBy.Email
						 from AsyncApexJob where Id =:BC.getJobId()];
		
		DateTime scheduledTime = DateTime.now().addMinutes( 1 );
		String timeString = scheduledTime.format( 'yyyy-MM-dd HH:mm:ss' );
		String cronString = scheduledTime.format( 's m H d M ? yyyy' );
		if(!test.isRunningTest()){
			System.schedule( 'GrantAccessToChatterFileBatch - ' + timeString + ' (' + Math.random() + ')', cronString, new GrantAccessToChatterFileBatchSchedule() );
		}

	}

	// APPROVAL STEP RECALL REQUESTS ////////////////////////////////////////////////////////////////////////////////////////////////
	private List<Approval_Step_Recall_Request__c> getRecallRequests(){

		return [SELECT Id, Work_Item_Id__c, Status__c, Exception__c
					FROM Approval_Step_Recall_Request__c
					WHERE Status__c = 'Pending'];

	}

	private void dealWithRecalls(List<Approval_Step_Recall_Request__c> requestsToRecall){

		if(requestsToRecall.isEmpty()) return;

		for(Approval_Step_Recall_Request__c step : requestsToRecall){
			try{
				step.Status__c = 'Recalled';
				Datetime d = Datetime.now();
				step.Recalled_Date__c = d;
				Approval.ProcessWorkItemRequest recallRequest = new Approval.ProcessWorkItemRequest();
				recallRequest.setWorkItemId(step.Work_Item_Id__c);
				recallRequest.setAction('Removed');
				Approval.process(recallRequest);
			} catch (Exception e){
				step.Status__c = 'Failed';
				step.Recalled_Date__c = null;
				step.Exception__c = e.getMessage() + ' (' + e.getLineNumber() + ')';
			}
		}
		Database.update(requestsToRecall, false);

	}
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	// EXECSEC APPROVAL STEP OVERRIDE REQUEST ///////////////////////////////////////////////////////////////////////////////////////
	private List<ExecSec_Approval_Step_Override_Request__c> getOverrides(){

		return [SELECT Id, Work_Item_Id__c, Status__c, Override_Date__c, Overridden_By__c, Overridden_By__r.Name, Overridden_By__r.Email, Exception__c, Approval_Step__c, Approval_Step__r.Assigned_Approver__c, Approval_Step__r.Name, Approval_Step__r.Assigned_Approver__r.Name, Approval_Step__r.Correspondence_Document__c, Approval_Step__r.Correspondence_Document__r.Name, Approval_Step__r.Comments__c, Approval_Step__r.Exec_Sec_Proxy_Approval_Requested__c
							FROM ExecSec_Approval_Step_Override_Request__c 
							WHERE Status__c = 'Pending'];

	}

	private void dealWithOverrides(List<ExecSec_Approval_Step_Override_Request__c> overrideRequests){

		if(overrideRequests.isEmpty()) return;

		Set<Id> workItemIds = new Set<Id>();
		Set<Id> approvalStepIds = new Set<Id>();
		for(ExecSec_Approval_Step_Override_Request__c request : overrideRequests){
			workItemIds.add(request.Work_Item_Id__c);
			approvalStepIds.add(request.Approval_Step__c);
		}
		Map<Id, ProcessInstanceWorkItem> workItemMap = new Map<Id, ProcessInstanceWorkItem>([SELECT Id, ActorId, ProcessInstance.TargetObjectId 
																								FROM ProcessInstanceWorkItem 
																								WHERE Id IN :workItemIds AND ProcessInstance.Status = 'Pending']);
		Map<Id, Approval_Step__c> approvalStepMap = new Map<Id, Approval_Step__c>([SELECT Id, Comments__c, Exec_Sec_Proxy_Approval_Requested__c, Actual_Approver__c
																					FROM Approval_Step__c
																					WHERE Id IN :approvalStepIds]); 
		List<Approval_Step__c> approvalStepsToUpdate = new List<Approval_Step__c>();
		Set<Id> workItemSet = new Set<Id>(workItemMap.keySet());
		for(ExecSec_Approval_Step_Override_Request__c request : overrideRequests){
			try {
				// reassign the approval step
				ProcessInstanceWorkItem processInstanceWorkItem = workItemMap.get(request.Work_Item_Id__c);
				processInstanceWorkItem.ActorId = request.Overridden_By__c;
				update processInstanceWorkItem;

				Approval_Step__c approvalStep = approvalStepMap.get(request.Approval_Step__c);
				approvalStep.Comments__c = 'Exec Sec Proxy Approval Requested';
				approvalStep.Exec_Sec_Proxy_Approval_Requested__c = true;
				approvalStep.Actual_Approver__c = request.Overridden_By__r.Name;

				boolean present = false;
				for(Approval_Step__c step : approvalStepsToUpdate){
					if(step.Id == approvalStep.Id) present = true;
				}
				if(!present) approvalStepsToUpdate.add(approvalStep); // updating just the ones that are changed

				request.Override_Date__c = System.now();

				// update the custom object to show completion success
				request.Status__c = 'Reassigned';

				// send email to notify users
				sendEmailsForExecSecOverrideRequests(createRecipientsList(request), request);
			} catch (Exception e){
				request.Status__c = 'Failed';
				request.Exception__c = '(' + e.getLineNumber() + ')' + e.getMessage();
			}
		}
		Database.update(overrideRequests, false);
		Database.update(approvalStepsToUpdate, false);

		// only create notification records for the ones that didn't fail and thus an email was never sent out anyways
		List<ExecSec_Approval_Step_Override_Request__c> requestList = new List<ExecSec_Approval_Step_Override_Request__c>();
		for(ExecSec_Approval_Step_Override_Request__c request : overrideRequests){
			if(request.Status__c == 'Failed') continue; // skip the fails
			requestList.add(request);
		}
		NotificationItemCreationHandler.createExecSecOverrideNotification(requestList);

	}

	private static List<ProcessInstanceWorkItem> getProcessWorkItems(Set<Id> approvalStepIds){

		return [SELECT Id, ProcessInstance.TargetObjectId
				FROM ProcessInstanceWorkItem 
				WHERE ProcessInstance.Status = 'Pending' AND 
					  ProcessInstance.TargetObjectId IN: approvalStepIds];

	}

	public static List<String> createRecipientsList(ExecSec_Approval_Step_Override_Request__c request){

		List<String> recipients = new List<String>();
		//recipients.add('ccoleman@acumensolutions.com'); // debug only
		//recipients.add('ktuttle@acumensolutions.com'); // debug only
		recipients.add(request.Overridden_By__r.Email);
		return recipients;

	}

	public static List<String> createRecipientsListForNotificationList(ExecSec_Approval_Step_Override_Request__c request){

		List<String> recipients = new List<String>();
		//recipients.add('Christian Coleman'); // debug only
		//recipients.add('Kimberley Tuttle'); // debug only
		recipients.add(request.Overridden_By__r.Name);
		recipients.add(request.Approval_Step__r.Assigned_Approver__r.Name);
		return recipients;

	}

	private static void sendEmailsForExecSecOverrideRequests(List<String> recipients, ExecSec_Approval_Step_Override_Request__c request){

		String baseUrl = URL.getSalesforceBaseUrl().toExternalForm();
		String approvalStepURL = baseUrl + '/' + request.Approval_Step__c;
		EmailUtility.sendSingleMessage(
						recipients,
						ControlledDocumentConstants.OVERRIDE_EMAIL_SUBJECT + request.Approval_Step__r.Name,
						'Per your request, you have been granted the ExecSec Proxy approver role for ' + request.Approval_Step__r.Correspondence_Document__r.Name
						+ '<p/>'
						+ '<a href="'
						+ approvalStepURL
						+ '">'
						+ request.Approval_Step__r.Name
						+'</a>'
					);

	}
}