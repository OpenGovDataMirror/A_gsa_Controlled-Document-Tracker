global without sharing class CDTBatchUtil {

	private static final Integer NOT_EXECSEC_ADMIN = -1;
	private static final Integer NOT_INITIATED = 0;
	private static final Integer ALLOWED = 1;
	private static final Integer ALREADY_EXISTS = 2;
	private static final Integer UNEXPECTED_ERROR = 99;
	private static final String PERMISSION_SET_NAME = 'Controlled_Document_Tracker_OAS_Admin_User_CRED';
	private static final String APPROVAL_STEP_INITIATED = 'Initiated';
	private static final String DEFAULT_PENDING_STATUS_FOR_REQUEST = 'Pending';

	webservice static Integer reassignExecSecUsers(Id astep){
		System.debug('astep = ' + astep);

		Id userId = UserInfo.getUserId();

		List<PermissionSet> psetList = [SELECT Id 
									FROM PermissionSet 
									WHERE Name = :PERMISSION_SET_NAME];

		List<PermissionSetAssignment> psetAssignmentList = [SELECT Id
															FROM PermissionSetAssignment
															WHERE PermissionSetId IN :psetList
															AND AssigneeId = :userId];

		if(psetAssignmentList.isEmpty()) return NOT_EXECSEC_ADMIN;

		// if not initiated return NOT_INITIATED
		List<Approval_Step__c> astepList = [SELECT Id, Approval_Status__c 
												FROM Approval_Step__c
												WHERE Id = :astep];
		if(!astepList.isEmpty()){
			if(astepList.get(0).Approval_Status__c != APPROVAL_STEP_INITIATED){
				return NOT_INITIATED;
			}
		}

		// if allowed return allowed and create record for batch processing
		System.debug('We made it!');

		List<ExecSec_Approval_Step_Override_Request__c> potentialDuplicateList = [SELECT Id, Status__c, Overridden_By__c, Approval_Step__c
																					FROM ExecSec_Approval_Step_Override_Request__c
																					WHERE Status__c = 'Pending' 
																					AND Overridden_By__c = :userId
																					AND Approval_Step__c = :astep];
		if(!potentialDuplicateList.isEmpty()) return ALREADY_EXISTS;

		List<ProcessInstanceWorkItem> approvalProcesses = getProcessWorkItems(astep);

		try {
			ExecSec_Approval_Step_Override_Request__c request = new ExecSec_Approval_Step_Override_Request__c();
			request.Approval_Step__c = astep;
			request.Overridden_By__c = userId;
			request.Status__c = DEFAULT_PENDING_STATUS_FOR_REQUEST;
			request.Work_Item_Id__c = approvalProcesses.get(0).Id;
			insert request;
			return ALLOWED;
		} catch (Exception e) {
			System.debug('An unexpected error occurred ' + e);
			return UNEXPECTED_ERROR;
		}		
	}	

	private static List<ProcessInstanceWorkItem> getProcessWorkItems(Id approvalStepId){
		return [SELECT Id, ProcessInstance.TargetObjectId, ProcessInstanceId
				FROM ProcessInstanceWorkItem 
				WHERE ProcessInstance.Status = 'Pending' AND 
					  ProcessInstance.TargetObjectId =: approvalStepId];
	}

}