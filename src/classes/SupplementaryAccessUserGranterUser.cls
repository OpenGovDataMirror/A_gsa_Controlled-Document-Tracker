public class SupplementaryAccessUserGranterUser{

	public static void updateSupplementsForDelegates(List<User> oldUserList, List<User> newUserList){

		Map<Id, Id> userIdToNewDelegateIdMap = new Map<Id, Id>();
		for(User oldUser : oldUserList){
			for(User newUser : newUserList) {
				if(oldUser.Id != newUser.Id) continue;
				if(oldUser.DelegatedApproverId != newUser.DelegatedApproverId && newUser.DelegatedApproverId != null){

					userIdToNewDelegateIdMap.put(newUser.Id, newUser.DelegatedApproverId);

				}
			}
		}

		addNewDelegatedSupplements(userIdToNewDelegateIdMap);

	}

	private static void addNewDelegatedSupplements(Map<Id, Id> userToNewDelegateMap){

		List<Approval_Step__c> relevantApprovalSteps = [
												SELECT Id, Assigned_Approver__c, Approval_Status__c, Correspondence_Document__c 
												FROM Approval_Step__c 
												WHERE Approval_Status__c = 'Initiated' 
												AND Assigned_Approver__c IN :userToNewDelegateMap.keySet()];

		List<Supplementary_Access_User__c> relevantQuickShares = [
														SELECT Id, Active__c, Controlled_Document__c, Inactivated_By__c, Inactivation_Date__c, Origin__c, Originating_User__c, User__c
														FROM Supplementary_Access_User__c
														WHERE Active__c = true
														AND User__c IN :userToNewDelegateMap.keySet()
														AND Origin__c = 'Quick Share'
													];

		List<Supplementary_Access_User__c> supplementsToCreate = new List<Supplementary_Access_User__c>();
		//List<Controlled_Document_Feed__c> batchItemsToAdd = new List<Controlled_Document_Feed__c>();

		for(Approval_Step__c step : relevantApprovalSteps){

			//if(userToNewDelegateMap.get(originatingUser) == null) continue; // we check for empty delegates in updateSupplementsForDelegates()

			Id originatingUser = step.Assigned_Approver__c;

			Supplementary_Access_User__c newSupplement = new Supplementary_Access_User__c();
			newSupplement.Active__c = true;
			newSupplement.Approval_Step__c = step.Id;
			newSupplement.Controlled_Document__c = step.Correspondence_Document__c;
			newSupplement.Origin__c = 'Delegate';
			newSupplement.Originating_User__c = originatingUser;
			newSupplement.User__c = userToNewDelegateMap.get(originatingUser);
			supplementsToCreate.add(newSupplement);

			// GRANTS ACCESS TO CHATTER FILES
			/*Controlled_Document_Feed__c batchItem = new Controlled_Document_Feed__c();
			batchItem.Controlled_Document__c = newSupplement.Controlled_Document__c;
			batchItem.Status__c = 'Pending';
			batchItem.User__c = newSupplement.User__c;
			batchItem.Approval_Step_Delegate_Origin__c = true;
			batchItemsToAdd.add(batchItem);*/

		}

		for(Supplementary_Access_User__c quickShare : relevantQuickShares){

			Id originatingUser = quickShare.User__c;

			Supplementary_Access_User__c newSupplement = new Supplementary_Access_User__c();
			newSupplement.Active__c = true;
			newSupplement.Controlled_Document__c = quickShare.Controlled_Document__c;
			newSupplement.Origin__c = 'Delegate';
			newSupplement.Originating_User__c = originatingUser;
			newSupplement.User__c = userToNewDelegateMap.get(originatingUser);
			supplementsToCreate.add(newSupplement);

			// GRANTS ACCESS TO CHATTER FILES
			/*Controlled_Document_Feed__c batchItem = new Controlled_Document_Feed__c();
			batchItem.Controlled_Document__c = newSupplement.Controlled_Document__c;
			batchItem.Status__c = 'Pending';
			batchItem.User__c = newSupplement.User__c;
			batchItem.Quick_Share_Origin__c = true;
			batchItemsToAdd.add(batchItem);*/
		}

		insert supplementsToCreate;
		//insert batchItemsToAdd;

	}

}