
public with sharing class TestUtil {

	/*
	public static Account buildAccount(String name, Id rtId) {
		return new Account(
			Name = name,
			RecordTypeId = rtId);
	}*/

	public static User buildUser(Integer i, Id profileId, String email) {
		String fName = 'fN' + i;
		String lName = 'lN' + i;
		return new User(
			FirstName = fName,
			LastName = lName,
			Email = email,
			ProfileId = profileId,
			UserName = email.subStringBefore('@') + '@gsa.testUser',
			Alias = fName + 'al',
			CommunityNickname = email.subStringBefore('@'),
			FederationIdentifier = 'testFedID' + i,
			//Affiliation__c = String.valueOf(i),
			EmailEncodingKey = 'UTF-8',
			LanguageLocaleKey = 'en_US',
			LocaleSidKey = 'en_US',
			TimeZoneSidKey = 'America/New_York',
			/*
			CHRIS_ID__c = '1' + i,
			Contact_ID__c = i,
			GOVTPOC_COTAR__c = String.valueOf(i),
			MAJOR_ORG__c = String.valueOf(i),
			MAJOR_ORG_DESCRIPTION__c = String.valueOf(i),
			Middle_Name__c = String.valueOf(i),
			Nickname__c = String.valueOf(i),
			User_Organization_Name__c = String.valueOf(i),
			User_Region__c = String.valueOf(i),
			UPN__c = String.valueOf(i),
			WORK_BUILDING_PRIMARY__c = String.valueOf(i),
			Supervisory_Status__c = i,
			Supervisory_Status_Description__c = String.valueOf(i),
			*/
			isActive = true
		);
	}
		
	public static User buildUserWithDelegate(Integer i, Id profileId, String email, Id testUser1) {
		String fName = 'fNDel' + i;
		String lName = 'lNDel' + i;
		return new User(
			FirstName = fName,
			LastName = lName,
			Email = email,
			ProfileId = profileId,
			UserName = email.subStringBefore('@') + '@gsa.testUser',
			Alias = fName + 'al',
			CommunityNickname = email.subStringBefore('@'),
			FederationIdentifier = 'testFedIDDel' + i,
			//Affiliation__c = String.valueOf(i),
			EmailEncodingKey = 'UTF-8',
			LanguageLocaleKey = 'en_US',
			LocaleSidKey = 'en_US',
			TimeZoneSidKey = 'America/New_York',
			/*
			CHRIS_ID__c = '1' + i,
			Contact_ID__c = i,
			GOVTPOC_COTAR__c = String.valueOf(i),
			MAJOR_ORG__c = String.valueOf(i),
			MAJOR_ORG_DESCRIPTION__c = String.valueOf(i),
			Middle_Name__c = String.valueOf(i),
			Nickname__c = String.valueOf(i),
			User_Organization_Name__c = String.valueOf(i),
			User_Region__c = String.valueOf(i),
			UPN__c = String.valueOf(i),
			WORK_BUILDING_PRIMARY__c = String.valueOf(i),
			Supervisory_Status__c = i,
			Supervisory_Status_Description__c = String.valueOf(i),
			*/			
			DelegatedApproverId=testUser1,
			isActive=true
		);
	}
	/*
	public static Contact buildContactByUser(User u, Id rtId, Id accId) {
		return new Contact(
			FirstName = u.FirstName,
			LastName = u.LastName,
			Email = u.Email,
			Contact_Federated_ID__c = u.FederationIdentifier,
			RecordTypeId = rtId,
			AccountId = accId);
	}

	public static Survey2__c buildSurveyMaster(String name) {
		return new Survey2__c(
			Name = name);
	}

	public static SurveyFeedback__c buildSurveyFeedback(Id contactId, Id surveyId) {
		return new SurveyFeedback__c(
			Contact__c = contactId,
			Survey2__c = surveyId);
	}

	public static SurveyIndividualAnswer__c buildSurveyAnswer(Id feedbackId, String questionName) {
		return new SurveyIndividualAnswer__c(
			Survey_Feedback__c = feedbackId,
			Question_Number__c = questionName);
	}

	public static SurveyIndividualQuestion__c buildSurveyQuestion(String name, Id surveyId) {
		return new SurveyIndividualQuestion__c(
			Name = name,
			Survey2__c = surveyId);
	}
	*/
}