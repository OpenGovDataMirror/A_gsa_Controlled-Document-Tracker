trigger ChatterFeedToUser on User (before update, after insert, after update) {


    if(Trigger.isBefore && Trigger.isUpdate){
            SupplementaryAccessUserGranterUser.updateSupplementsForDelegates(trigger.old, trigger.new);
        
    }
	
}