@isTest
public with sharing class UserDAMock implements UserDAI{
	private static Profile p = [SELECT Id FROM Profile WHERE Name='Standard Platform User'];
	public User genericUser = new User(Alias = 'atreides', Email='leto@testorg.com', User_Region__c = 'Region1',
            EmailEncodingKey='UTF-8', LastName='Atreides', UserName='leto@testorg.com', Division='ADF',
            LanguageLocaleKey='en_US', LocaleSidKey='en_US', TimeZoneSidKey='America/Los_Angeles', ProfileId = p.Id);
	
	public User getUserById(Id userId){
		return genericUser;
	}

//	public List<User> getUsersByIds(List<Id> userIds){
//		return new List<User>{genericUser};
//	}

	public List<User> getUserWithEmailByIds(Set<Id> userIds){
		return new List<User>{genericUser};
	}
}