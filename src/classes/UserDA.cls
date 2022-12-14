public with sharing class UserDA implements UserDAI{
	public User getUserById(Id userId){
		return [SELECT Id,
				Division,
				Alternate_Division__c,
				User_Region__c,
				Alternate_Region__c
		FROM User
		WHERE Id =: userID];
	}

//	public List<User> getUsersByIds(List<Id> userIds){
//		return [SELECT Id,
//				Division,
//				Alternate_Division__c,
//				User_Region__c,
//				Alternate_Region__c
//		FROM User
//		WHERE Id IN :userIds];
//	}

	public List<User> getUserWithEmailByIds(Set<Id> userIds){
		return [SELECT Id,
				Email
		FROM User
		WHERE Id in :userIds];
	}
}