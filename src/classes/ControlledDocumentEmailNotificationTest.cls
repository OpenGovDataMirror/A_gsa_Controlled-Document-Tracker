@isTest
public with sharing class ControlledDocumentEmailNotificationTest {

	@isTest
	private static void getUserEmails_givenUserId_shouldReturnTestEmail(){
		UserDAMock mockUserDA = new UserDAMock();
		ControlledDocumentEmailNotification.userEmailDA = mockUserDA;
		Set<Id> IdSet = new Set<Id>{'000000000000000000'};
		Test.startTest();
			List<String> emailAddresses = ControlledDocumentEmailNotification.getUserEmails(IdSet);
		Test.stopTest();

		for(String addr : emailAddresses){
			System.assertEquals(mockUserDA.genericUser.Email, addr);
		}
	}

	@isTest
	private static void sendEmailMessages_givenMockedEmail_shouldSuccessfullySend(){
		//ControlledDocumentEmailNotification.orgWideEmailDA = new OrgWideEmailAddressDAMock();

		UserDAMock mockUserDA = new UserDAMock();
		ControlledDocumentEmailNotification.userEmailDA = mockUserDA;
		List<String> recipients = new List<String>{mockUserDA.genericUser.Email};
		List<Boolean> results;
		Test.startTest();
		results = ControlledDocumentEmailNotification.sendEmailMessages('Test', recipients,'Test');
		Test.stopTest();

		System.assertEquals(True, results[0]);
	}

	@isTest
	private static void sendEmailNotificationToUsers_givenMockedEmail_shouldSuccessfullySend(){
		//ControlledDocumentEmailNotification.orgWideEmailDA = new OrgWideEmailAddressDAMock();

		UserDAMock mockUserDA = new UserDAMock();
		ControlledDocumentEmailNotification.userEmailDA = mockUserDA;

		Set<Id> IdSet = new Set<Id>{'000000000000000000'};
		Controlled_Document__c document = new Controlled_Document__c();
		document.Id = getFakeId(document.getSObjectType());

		List<Boolean> results;
		Test.startTest();
		results = ControlledDocumentEmailNotification.sendEmailNotificationToUsers(document,IdSet);
		Test.stopTest();

		System.assertEquals(True, results[0]);
	}

	@isTest(SeeAllData=true)
	private static void sendEmailNotificationToUsers_givenRetrievedEmail_shouldSuccessfullySend(){
		//ControlledDocumentEmailNotification.orgWideEmailDA = new OrgWideEmailAddressDAMock();
		User testUser = insertTestUser();

		Set<Id> IdSet = new Set<Id>{testUser.Id};
		Controlled_Document__c document = new Controlled_Document__c();
		document.Id = getFakeId(document.getSObjectType());

		List<Boolean> results;
		Test.startTest();
		results = ControlledDocumentEmailNotification.sendEmailNotificationToUsers(document,IdSet);
		Test.stopTest();

		System.assertEquals(True, results[0]);
	}

	public static String getFakeId(Schema.SObjectType sot){
		String result = String.valueOf(1);
		return sot.getDescribe().getKeyPrefix() +
				'0'.repeat(12-result.length()) + result;
	}

	private static User insertTestUser(){
		Profile p = [SELECT Id FROM Profile WHERE Name='Standard Platform User'];
		User genericUser = new User(Alias = 'atreides',
				Email='leto@testorg.com',
				User_Region__c = 'Region1',
				EmailEncodingKey='UTF-8',
				LastName='Atreides',
				UserName='leto@testorg.com',
				Division='ADF',
				LanguageLocaleKey='en_US',
				LocaleSidKey='en_US',
				TimeZoneSidKey='America/Los_Angeles',
				ProfileId = p.Id);


		insert genericUser;
		return genericUser;
	}
}