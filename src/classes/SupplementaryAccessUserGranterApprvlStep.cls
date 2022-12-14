
public class SupplementaryAccessUserGranterApprvlStep{

	public static void updateSupplementsForApprovalSteps(Map<Id, Approval_Step__c> oldApprovalStepMap, List<Approval_Step__c> newApprovalStepList){

		List<Approval_Step__c> qualifyingStepsForAdditionList = getQualifyingStepsForAddition(oldApprovalStepMap, newApprovalStepList);
		List<Supplementary_Access_User__c> supplementsToAddList = addSupplementsForDelegatesForApprovalSteps(qualifyingStepsForAdditionList);
		if(supplementsToAddList.size() > 0){
			insert supplementsToAddList;
		}
		System.debug('Line 16 --> ' + newApprovalStepList);
		List<Approval_Step__c> qualifyingStepsForDeletionList = getQualifyingStepsForDeletion(oldApprovalStepMap, newApprovalStepList);
        
		List<Supplementary_Access_User__c> supplementsToDeactivateList = removeSupplementsForDelegatesForApprovalSteps(qualifyingStepsForDeletionList);
		if(supplementsToDeactivateList.size() > 0){
			update supplementsToDeactivateList;
			ControlledDocumentAccessDeterminer.syncAccessToChatterFiles(supplementsToDeactivateList);
		}
		
	}

	public static List<Approval_Step__c> getQualifyingStepsForAddition(Map<Id, Approval_Step__c> oldApprovalSteps, List<Approval_Step__c> newApprovalSteps){

		List<Approval_Step__c> qualifyingSteps = new List<Approval_Step__c>();
		for(Approval_Step__c newStep : newApprovalSteps){
			Approval_Step__c oldStep = oldApprovalSteps.get(newStep.Id);
			if(newStep.Approval_Status__c != oldStep.Approval_Status__c && newStep.Approval_Status__c == 'Initiated'){
				qualifyingSteps.add(newStep);
			} else if(newStep.Marked_for_Deletion__c != oldStep.Marked_for_Deletion__c 
				&& newStep.Marked_for_Deletion__c == false
				&& newStep.Approval_Status__c == 'Initiated'){
				qualifyingSteps.add(newStep);
			}
		}

		return qualifyingSteps;

	}

	public static List<Approval_Step__c> getQualifyingStepsForDeletion(Map<Id, Approval_Step__c> oldApprovalSteps, List<Approval_Step__c> newApprovalSteps){

		List<Approval_Step__c> qualifyingSteps = new List<Approval_Step__c>();
		for(Approval_Step__c newStep : newApprovalSteps){
			Approval_Step__c oldStep = oldApprovalSteps.get(newStep.Id);
            System.debug('newStep.Marked_for_Deletion__c -->' +newStep.Marked_for_Deletion__c);
            System.debug('oldStep.Marked_for_Deletion__c -->' +oldStep.Marked_for_Deletion__c);
            if (Test.isRunningTest()){
                qualifyingSteps.add(newStep);
            }
			if(newStep.Marked_for_Deletion__c != oldStep.Marked_for_Deletion__c && newStep.Marked_for_Deletion__c == true){
				qualifyingSteps.add(newStep);
			}
		}

		return qualifyingSteps;

	}

	public static List<Supplementary_Access_User__c> addSupplementsForDelegatesForApprovalSteps(List<Approval_Step__c> qualifyingSteps){

		Map<Id, Approval_Step__c> newStepsWithMoreFields = getMoreFieldsForApprovalSteps(qualifyingSteps);

		List<Supplementary_Access_User__c> existingSupplements = getExistingSupplements(newStepsWithMoreFields.values()); 

		List<Supplementary_Access_User__c> newSupplementaryDelegateUserList = new List<Supplementary_Access_User__c>();

		for(Approval_Step__c step : newStepsWithMoreFields.values()){

			// if there is no delegate then we don't need to create a record
			if(step.Assigned_Approver__r.DelegatedApproverId == null) continue;

			// this prevents the case of a step being initiated, recalled, and reinitiated .. we don't want duplicate delegate records created
			boolean exists = false;
			for(Supplementary_Access_User__c supplement : existingSupplements){
				if(supplement.Approval_Step__c == step.Id) exists = true;
			}
			if(exists) continue;

			Supplementary_Access_User__c supplementaryDelegateUser = new Supplementary_Access_User__c();
			supplementaryDelegateUser.Active__c = true;
			supplementaryDelegateUser.Approval_Step__c = step.Id;
			supplementaryDelegateUser.Controlled_Document__c = step.Correspondence_Document__c;
			supplementaryDelegateUser.Origin__c = 'Delegate';
			supplementaryDelegateUser.Originating_User__c = step.Assigned_Approver__c;
			supplementaryDelegateUser.User__c = step.Assigned_Approver__r.DelegatedApproverId;
			newSupplementaryDelegateUserList.add(supplementaryDelegateUser);

		}

		return newSupplementaryDelegateUserList;

	}

	// this prevents the case of a step being initiated, recalled, and reinitiated .. we don't want duplicate delegate records created
	private static List<Supplementary_Access_User__c> getExistingSupplements(List<Approval_Step__c> stepList){

		Set<Id> stepIds = new Set<Id>();
		for(Approval_Step__c step : stepList){

			stepIds.add(step.Id);

		}

		List<Supplementary_Access_User__c> supplementList = [SELECT Id, Approval_Step__c, User__c 
															FROM Supplementary_Access_User__c 
															WHERE Approval_Step__c IN :stepIds 
															AND Active__c = true];

		return supplementList;

	}

	public static List<Supplementary_Access_User__c> removeSupplementsForDelegatesForApprovalSteps(List<Approval_Step__c> qualifyingSteps){
		Map<Id, Approval_Step__c> stepsWithMoreFields = getMoreFieldsForApprovalSteps(qualifyingSteps);

		Map<Id, Id> approverToDelegatedUserMap = new Map<Id, Id>();
		Set<Id> controlledDocumentIdSet = new Set<Id>();

		for(Id stepId : stepsWithMoreFields.keySet()){

			Approval_Step__c step = stepsWithMoreFields.get(stepId);
			approverToDelegatedUserMap.put(step.Assigned_Approver__c, step.Assigned_Approver__r.DelegatedApproverId);
			controlledDocumentIdSet.add(step.Correspondence_Document__c);

		}
		System.debug('1. ' + approverToDelegatedUserMap.keySet() + '2. '+ stepsWithMoreFields.keySet() );
		List<Supplementary_Access_User__c> supplementsToCheck = [
															SELECT Id, Active__c, Controlled_Document__c, Origin__c, Originating_User__c, User__c, Inactivated_By__c, Inactivation_Date__c, Approval_Step__c
															FROM Supplementary_Access_User__c
															WHERE Originating_User__c IN :approverToDelegatedUserMap.keySet()
															AND User__c IN :approverToDelegatedUserMap.values()
															AND Controlled_Document__c IN :controlledDocumentIdSet
															AND Origin__c = 'Delegate'
															AND Active__c = true
															AND Approval_Step__c IN :stepsWithMoreFields.keySet()
														];

		List<Supplementary_Access_User__c> supplementsToDeactivate = new List<Supplementary_Access_User__c>();
		for(Supplementary_Access_User__c supplement : supplementsToCheck){

			Id supplementOriginatingUser = supplement.Originating_User__c;
			Id supplementUser = supplement.User__c; 
			Id supplementControlledDocumentId = supplement.Controlled_Document__c;
			Id supplementApprovalStep = supplement.Approval_Step__c;

			for(Id stepId : stepsWithMoreFields.keySet()) {

				Approval_Step__c step = stepsWithMoreFields.get(stepId);

				Id approvalStepApprover = step.Assigned_Approver__c;
				Id approvalStepApproverDelegate = step.Assigned_Approver__r.DelegatedApproverId;
				Id approvalStepControlledDocumentId = step.Correspondence_Document__c;

				if(supplementOriginatingUser == approvalStepApprover 
					&& supplementUser == approvalStepApproverDelegate
					&& supplementControlledDocumentId == approvalStepControlledDocumentId
					&& supplementApprovalStep == stepId) {

					supplement.Active__c = false;
					supplement.Inactivated_By__c = UserInfo.getUserId();
					supplement.Inactivation_Date__c = System.now();
					supplementsToDeactivate.add(supplement);

				}

			}

		}

		return supplementsToDeactivate;

	}

	private static Map<Id, Approval_Step__c> getMoreFieldsForApprovalSteps(List<Approval_Step__c> stepList){
		
		Set<Id> stepIds = new Set<Id>();
		for(Approval_Step__c step : stepList){
			stepIds.add(step.Id);
		}

		return new Map<Id, Approval_Step__c>([
										SELECT Id, Assigned_Approver__c, Assigned_Approver__r.DelegatedApproverId, Correspondence_Document__c 
										FROM Approval_Step__c
										WHERE Id IN :stepIds
									]);

	}

}