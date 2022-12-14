
public without sharing class SupplementaryAccessUserGranterQuickShare {

	public static void addShareForQuickShareUser(Id controlledDocument, Id originatingUser, Map<Id,String> usersThatShouldBeGrantedAccess, boolean isExecSecOrOwner){

		List<Supplementary_Access_User__c> oldSupplements;

		if(isExecSecOrOwner == true) {

			oldSupplements = [
						SELECT Id, Active__c, Controlled_Document__c, Inactivated_By__c, Inactivation_Date__c, Origin__c, Originating_User__c, User__c
						FROM Supplementary_Access_User__c
						WHERE Active__c = true
						AND Controlled_Document__c = :controlledDocument
						AND Origin__c = 'Quick Share'
						AND User__c IN :usersThatShouldBeGrantedAccess.keyset()
					];

		} else {

			oldSupplements = [
						SELECT Id, Active__c, Controlled_Document__c, Inactivated_By__c, Inactivation_Date__c, Origin__c, Originating_User__c, User__c
						FROM Supplementary_Access_User__c
						WHERE Active__c = true
						AND Controlled_Document__c = :controlledDocument
						AND Origin__c = 'Quick Share'
						AND Originating_User__c = :originatingUser
						AND User__c IN :usersThatShouldBeGrantedAccess.keyset()
					];

		}

		List<Supplementary_Access_User__c> supplementsToAdd = new List<Supplementary_Access_User__c>();

		for(Id user : usersThatShouldBeGrantedAccess.keyset()) {

			boolean existed = false;

			for(Supplementary_Access_User__c supplement : oldSupplements){

				if(user == supplement.User__c) {
					
					existed = true;

				}

			}

			if(!existed){

				Supplementary_Access_User__c newSupplementaryAccessUser = new Supplementary_Access_User__c();
				newSupplementaryAccessUser.Active__c = true;
				newSupplementaryAccessUser.Controlled_Document__c = controlledDocument;
				newSupplementaryAccessUser.Origin__c = 'Quick Share';
				newSupplementaryAccessUser.Originating_User__c = originatingUser;
				newSupplementaryAccessUser.User__c = user;
                if(usersThatShouldBeGrantedAccess.get(user)!= null){
                   newSupplementaryAccessUser.Group__c = usersThatShouldBeGrantedAccess.get(user);
                }
				supplementsToAdd.add(newSupplementaryAccessUser);

			}

		}

		insert supplementsToAdd;
		addCommonSupplementaryUsers(originatingUser, supplementsToAdd);

		addShareForQuickShareDelegateUser(controlledDocument, supplementsToAdd); //, supplementsToEnable); // giveAccessToChatterFiles is also called in here for the delegates

	}

	private static void addShareForQuickShareDelegateUser(Id controlledDocument, List<Supplementary_Access_User__c> newSupplements){
		
		Set<Id> originatingUserIds = new Set<Id>();
		for(Supplementary_Access_User__c supplement : newSupplements){
			originatingUserIds.add(supplement.User__c);
		}
		Map<Id, User> originatingUsersToDelegate = new Map<Id, User>([
													SELECT Id, DelegatedApproverId
													FROM User
													WHERE Id = :originatingUserIds
												]);

		List<Id> delegateIds = new List<Id>();
		for(Id originatingUser : originatingUsersToDelegate.keySet()){
			delegateIds.add(originatingUsersToDelegate.get(originatingUser).DelegatedApproverId);
		}

		List<Supplementary_Access_User__c> oldSupplements = [
													SELECT Id, Active__c, Controlled_Document__c, Inactivated_By__c, Inactivation_Date__c, Origin__c, Originating_User__c, User__c
													FROM Supplementary_Access_User__c
													WHERE Controlled_Document__c = :controlledDocument
													AND Origin__c = 'Delegate'
													AND Originating_User__c = :originatingUserIds
													AND User__c IN :delegateIds
												];

		List<Supplementary_Access_User__c> supplementsToAdd = new List<Supplementary_Access_User__c>();

			for(Id originatingUserId : originatingUserIds){

				User originatingUser = originatingUsersToDelegate.get(originatingUserId);
				if(originatingUser == null) continue;
				Id delegateId = originatingUser.DelegatedApproverId;
				if(delegateId == null) continue;

				Supplementary_Access_User__c newSupplementaryAccessUser = new Supplementary_Access_User__c();
				newSupplementaryAccessUser.Active__c = true;
				newSupplementaryAccessUser.Controlled_Document__c = controlledDocument;
				newSupplementaryAccessUser.Origin__c = 'Delegate';
				newSupplementaryAccessUser.Originating_User__c = originatingUserId;
				newSupplementaryAccessUser.User__c = delegateId;
				supplementsToAdd.add(newSupplementaryAccessUser);

			}

		insert supplementsToAdd;
	}

	private static void addCommonSupplementaryUsers(Id originatingUser, List<Supplementary_Access_User__c> supplementsToAdd){
		
		List<Id> usersToAddAsCommonSupplementaryUsers = new List<Id>();

		if(!supplementsToAdd.isEmpty()) {
			for(Supplementary_Access_User__c supplement : supplementsToAdd){

				usersToAddAsCommonSupplementaryUsers.add(supplement.User__c);

			}

		}

		List<Common_Supplementary_User__c> existingCommonSupplements = [
																	SELECT Id, Group_Member__c, CreatedById, Frequency__c 
																	FROM Common_Supplementary_User__c
																	WHERE Group_Member__c IN :usersToAddAsCommonSupplementaryUsers
																	AND CreatedById = :originatingUser
																];

		List<Common_Supplementary_User__c> commonSupplementsToUpdate = new List<Common_Supplementary_User__c>();
		List<Common_Supplementary_User__c> commonSupplementsToAdd = new List<Common_Supplementary_User__c>();
		for(Id user : usersToAddAsCommonSupplementaryUsers){

			boolean existed = false;
			for(Common_Supplementary_User__c commonSupplement : existingCommonSupplements){

				if(user == commonSupplement.Group_Member__c) {

					existed = true;
					commonSupplement.Frequency__c++;
					commonSupplementsToUpdate.add(commonSupplement);

				}

			}
			if(existed) {


				continue; 

			}
			Common_Supplementary_User__c newCommonSupplement = new Common_Supplementary_User__c();
			newCommonSupplement.Group_Member__c = user;
			newCommonSupplement.Frequency__c = 1;
			commonSupplementsToAdd.add(newCommonSupplement);

		}

		update commonSupplementsToUpdate;
		insert commonSupplementsToAdd;

	}

	public static void disableShareForQuickShareUser(Id controlledDocument, Id originatingUser, Set<Id> usersThatShouldStillHaveAccess, boolean isExecSecOrOwner){

		List<Supplementary_Access_User__c> oldSupplements;

		if(isExecSecOrOwner) {

			oldSupplements = [
						SELECT Id, Active__c, Controlled_Document__c, Inactivated_By__c, Inactivation_Date__c, Origin__c, Originating_User__c, User__c, User__r.UserPreferencesDisableMessageEmail
						FROM Supplementary_Access_User__c
						WHERE Active__c = true
						AND Controlled_Document__c = :controlledDocument
						AND Origin__c = 'Quick Share'
						AND User__c NOT IN :usersThatShouldStillHaveAccess
					];

		} else {

			oldSupplements = [
						SELECT Id, Active__c, Controlled_Document__c, Inactivated_By__c, Inactivation_Date__c, Origin__c, Originating_User__c, User__c, User__r.UserPreferencesDisableMessageEmail
						FROM Supplementary_Access_User__c
						WHERE Active__c = true
						AND Controlled_Document__c = :controlledDocument
						AND Origin__c = 'Quick Share'
						AND Originating_User__c = :originatingUser
						AND User__c NOT IN :usersThatShouldStillHaveAccess
					];

		}

		List<Supplementary_Access_User__c> supplementsToDisable = new List<Supplementary_Access_User__c>();

		for(Supplementary_Access_User__c supplement : oldSupplements){

			supplement.Active__c = false;
			supplement.Inactivated_By__c = UserInfo.getUserId();
			supplement.Inactivation_Date__c = System.now();
			supplementsToDisable.add(supplement);
		
		}

		update supplementsToDisable;

		disableShareForQuickShareDelegateUser(controlledDocument, originatingUser, supplementsToDisable, isExecSecOrOwner); // only need originatingUser to show who disabled the delegate quick shares

		ControlledDocumentAccessDeterminer.syncAccessToChatterFiles(supplementsToDisable);

	}

	private static void disableShareForQuickShareDelegateUser(Id controlledDocument, Id originatingUser, List<Supplementary_Access_User__c> disabledSupplements, boolean isExecSecOrOwner){

		Set<Id> originatingUserIds = new Set<Id>();
		for(Supplementary_Access_User__c supplement : disabledSupplements){
			originatingUserIds.add(supplement.User__c);
		}

		Map<Id, User> originatingUsersToDelegate = new Map<Id, User>([
													SELECT Id, DelegatedApproverId
													FROM User
													WHERE Id = :originatingUserIds
												]);

		List<Id> delegateIds = new List<Id>();
		for(Id user : originatingUsersToDelegate.keySet()){
			delegateIds.add(originatingUsersToDelegate.get(user).DelegatedApproverId);
		}

		List<Supplementary_Access_User__c> oldSupplements;

		if(isExecSecOrOwner) {

			oldSupplements = [
						SELECT Id, Active__c, Approval_Step__c, Controlled_Document__c, Inactivated_By__c, Inactivation_Date__c, Origin__c, Originating_User__c, User__c, User__r.UserPreferencesDisableMessageEmail
						FROM Supplementary_Access_User__c
						WHERE Active__c = true
						AND Approval_Step__c = null
						AND Controlled_Document__c = :controlledDocument
						AND Origin__c = 'Delegate'
						AND User__c IN :delegateIds
					];
		} else {

			oldSupplements = [
						SELECT Id, Active__c, Approval_Step__c, Controlled_Document__c, Inactivated_By__c, Inactivation_Date__c, Origin__c, Originating_User__c, User__c, User__r.UserPreferencesDisableMessageEmail
						FROM Supplementary_Access_User__c
						WHERE Active__c = true
						AND Approval_Step__c = null
						AND Controlled_Document__c = :controlledDocument
						AND Origin__c = 'Delegate'
						AND Originating_User__c IN :originatingUserIds
						AND User__c IN :delegateIds
					];

		}

		List<Supplementary_Access_User__c> supplementsToDisable = new List<Supplementary_Access_User__c>();

		for(Supplementary_Access_User__c old : oldSupplements){

			Id originatingUserIdOld = old.Originating_User__c;
			Id userOld = old.User__c;
			
			for(Supplementary_Access_User__c disabled : disabledSupplements) {

				Id originatingUserIdDisabled = disabled.User__c; // the originating user of the delegate supplements is the user in the parent supplements
				Id userDisabled = originatingUsersToDelegate.get(originatingUserIdDisabled).DelegatedApproverId;

				if(userOld == userDisabled && originatingUserIdOld == originatingUserIdDisabled){

					old.Active__c = false;
					old.Inactivated_By__c = originatingUser;
					old.Inactivation_Date__c = System.now();
					supplementsToDisable.add(old);

				}

			}

		}
		update supplementsToDisable;
	}
}