public without sharing class ControlledDocumentEmailNotification {

	private static final String GRANT_UPDATE_ACCESS_EMAIL_SUBJECT = 'You have been granted access to a Controlled Document Record';
	private static final String CURRENT_ORG_URL = URL.getSalesforceBaseUrl().toExternalForm();
	//public static OrgWideEmailAddressDAI orgWideEmailDA = new OrgWideEmailAddressDA();
	public static UserDAI userEmailDA = new UserDA();

	public static List<Boolean> sendEmailNotificationToUsers(Controlled_Document__c controlledDoc, Set<Id> newCollaboratorIds){

		String message = 'You have been granted access to the Controlled Document Record, \''
				+ controlledDoc.Name + '\'. Click here to access the Controlled Document Record: '
				+ CURRENT_ORG_URL + '/' + controlledDoc.Id;

		List<String> recipients = getUserEmails(newCollaboratorIds);

		return sendEmailMessages(GRANT_UPDATE_ACCESS_EMAIL_SUBJECT, recipients, message);
	}

	public static List<String> getUserEmails(Set<Id> userIds){
		List<User> users = userEmailDA.getUserWithEmailByIds(userIds);

		List<String> emailAddresses = new List<String>();
		System.debug(users);
		for(User u : users){
			emailAddresses.add(u.Email);
		}

		return emailAddresses;
	}

	public static List<Boolean> sendEmailMessages(String subject, List<String> recipients, String message){
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

		mail.setSubject(subject);
		mail.setToAddresses(recipients);
		mail.setPlainTextBody(message);
		mail.setPlainTextBody(message);
		
		List<CDT_Org_Address__mdt> orgId = [select OrgID__c from CDT_Org_Address__mdt where DeveloperName='OrgEmail'];
		if (orgId[0].OrgID__c <> null){
			mail.setOrgWideEmailAddressId(orgId[0].OrgID__c);
		}
		//Set sender to OrgWide Email Address
		//OrgWideEmailAddress orgWideEmail = orgWideEmailDA.getOrgWideEmailByAddress('donotreply@gsa.gov');
		//System.debug(orgWideEmail);
		//mail.setOrgWideEmailAddressId(orgWideEmail.Id);
		System.debug(mail);

		List<Boolean> results = new List<Boolean>();
		if(!Test.isRunningTest()){
			List<Messaging.SendEmailResult> sendEmailResults = Messaging.sendEmail(new Messaging.Email[] { mail });
			for(Messaging.SendEmailResult res : sendEmailResults){
				results.add(res.isSuccess());
			}
		}else{
			for(String recipient : recipients){
				results.add(true);
			}
		}


		return results;
	}
}