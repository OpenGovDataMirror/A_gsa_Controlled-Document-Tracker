trigger SupplementaryAccessUserTrigger on Supplementary_Access_User__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {

	if (Trigger.isBefore) {

	}
	else if (Trigger.isAfter) {

		if(Trigger.isInsert || Trigger.isUndelete){
			
			if(ShareDocumentToApproversHelper.isFirstTime){
                ShareDocumentToApproversHelper.isFirstTime=false;
                ShareDocumentToApproversHelper.manageControlledDocumentSharing(Trigger.new);
            }

		}
		else if(Trigger.isUpdate && !GrantAccessToChatterFileBatch.isGrantAccessToChatterFileBatch){
			//Bypassing the trigger when an update is made from GrantAccessToChatterFileBatch in order to reduce number of 
			//rows retrieved to prevent 50001 error as part of SFEEO-1491. The update is a dummy update hence the post DML processing is not required.
			ShareDocumentToApproversHelper.manageControlledDocumentSharing(Trigger.old, Trigger.new);

		}
		else if(Trigger.isDelete){ 

			ShareDocumentToApproversHelper.manageControlledDocumentSharing(Trigger.old);
	
		}

	}

}