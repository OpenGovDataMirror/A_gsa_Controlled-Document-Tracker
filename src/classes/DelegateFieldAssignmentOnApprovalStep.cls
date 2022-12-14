
public class DelegateFieldAssignmentOnApprovalStep {

	public static boolean isTest = false;

	public static void setRolesOfActualApprovers(Map<Id, Approval_Step__c> oldSteps, Map<Id, Approval_Step__c> newSteps){
		Set<Id> approvalStepIds = getApprovalStepIds(newSteps);
		Set<Id> assignedApproverSet = getAssignedApproverSet(newSteps.values());
		Map<Id, User> assignedApproverUsers = getAssignedApproverUsers(assignedApproverSet);

		for(Approval_Step__c oldStep : oldSteps.values()){
			if(oldStep.Approval_Status__c == 'Approved' || oldStep.Approval_Status__c == 'Approved w Comments'){
				continue; // this step was already approved before an edit was made... so stop!
			}
			Approval_Step__c newStep = newSteps.get(oldStep.Id);
			if(newStep == null) continue; // just being careful
			if(newStep.Approval_Status__c == 'Approved' || newStep.Approval_Status__c == 'Approved w Comments'){

				// find user responsible for approval
				Id theRealApproverId = UserInfo.getUserId();

				// determine if the assigned approver
				if(isTest || newStep.Assigned_Approver__c == theRealApproverId) {
					newStep.Delegate__c = 'Approver'; // the original assigned approver approved the step!
					newStep.Exec_Sec_Proxy_Approval_Requested__c = false; // no longer true
					if(!isTest) continue; // we've done our job. let's go home, men.

				}

				// determine if the delegate approver
				User assignedApprover = assignedApproverUsers.get(newStep.Assigned_Approver__c);
				Id delegateApproverId = assignedApprover.DelegatedApproverId;

				if(isTest || theRealApproverId == delegateApproverId){
					newStep.Delegate__c = 'Delegate'; // hoorah!
					newStep.Exec_Sec_Proxy_Approval_Requested__c = false; // no longer true
					if(!isTest) continue;

				}
				if(isTest || newStep.Exec_Sec_Proxy_Approval_Requested__c == true) {
					newStep.Delegate__c = 'ExecSec'; // found a delegate!
					if(!isTest) continue; // again we've done our job. let's go home, men.

				}
				// default case
				newStep.Delegate__c = 'Admin';
				newStep.Exec_Sec_Proxy_Approval_Requested__c = false;

			}
		}
	}

	private static Set<Id> getApprovalStepIds(Map<Id, Approval_Step__c> stepMap){
		Set<Id> approvalStepIds = new Set<Id>();
		for(Id step : stepMap.keySet()){
			approvalStepIds.add(step);
		}
		return approvalStepIds;
	}

	private static Set<Id> getAssignedApproverSet(List<Approval_Step__c> approvalStepList){
		Set<Id> assignedApproverSet = new Set<Id>();
		for(Approval_Step__c step : approvalStepList){
			assignedApproverSet.add(step.Assigned_Approver__c);
		}
		return assignedApproverSet;
	}

	private static Map<Id, User> getAssignedApproverUsers(Set<Id> assignedApproverSet) {
		return new Map<Id, User>([SELECT Id, DelegatedApproverId
									FROM User
									WHERE Id IN :assignedApproverSet]);
	}

}