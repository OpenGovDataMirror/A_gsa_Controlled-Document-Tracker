
@isTest
private class TestEmailUtility
{
	private void createTemplate()
	{
		EmailTemplate temp = new EmailTemplate();
		temp.Body = 'Test';
		temp.Description = 'Testing using emailTemplates';
		temp.DeveloperName = 'Test_Email_Template_##$@!';
		temp.Name = 'Test Email Template';
		temp.Subject = 'Test';
		insert temp;
		System.assert(temp.Subject == 'Test');
	}
	
	static testMethod void testSingleEmailUtility()
	{
		Account acc = new Account();
		acc.Name = 'Test Acc';
		insert acc;
		
		SingleEmailUtility single = new SingleEmailUtility();
		single.setBccAddresses(new List<String>{'test@test.com'});
		single.setBccSender(true);
		single.setSaveAsActivity(false);
		single.setCcAddresses(new List<String>{'test@test.com'});
		single.setCharset(null);
		single.setDocumentAttachments(null);
		single.setEmailPriority(EmailUtility.NORMAL_EMAIL_PRIORITY);
		single.setFileAttachments(null);
		single.setHTMLBody('<p>test</p>');
		single.setInReplyTo('test@test.com');
		single.setOrgWideEmailAddressId(null);
		single.setPlainTextBody('test');
		single.setReferences(null);
		single.setReplyTo('noreply@salesforce.com');
		single.setSenderDisplayName('No Reply');
		single.setSubject('subject');
		single.setTargetObjectId(null);
		single.setToAddresses(new List<String>{'test@test.com'});
		single.setUseSignature(false);
		single.setWhatId(null);
		single.setTemplateID(null);
		
		List<Messaging.SendEmailResult> results = single.sendMesssage();
		System.debug('result size = ' + results.size());
		for (Messaging.SendEmailResult result: results)
		{
			if (!result.isSuccess())
			{
				for (Messaging.SendEmailError error: result.getErrors())
				{
					System.debug(error.getMessage());
				}
			}
		}
		
		results = EmailUtility.sendBulkMessages(new List<EmailUtility>{single});
		
		List<Messaging.SendEmailResult> emailResults = EmailUtility.sendSingleMessage(new List<String>{'test@test.com'}, 'test subject', 'test body');
		
		for (Messaging.SendEmailResult res: emailResults)
		{
			System.assert(res.isSuccess(), 'Email Results with parameters List<String>, String Subject, String Body: is now failing');
		}
		
		emailResults = EmailUtility.sendSingleMessage(new List<String>{'test@test.com'}, new List<String>(), false, 
				new List<String>(), null, EmailUtility.NORMAL_EMAIL_PRIORITY, null, 'test', null, null,
				'test', null, null, 'NO REPLY', 'test sub', null, null, null);
		
		for (Messaging.SendEmailResult res: emailResults)
		{
			System.assert(res.isSuccess(), 'Email Results with parameters List<String>, String Subject, String Body: is now failing');
		}
	}
	
	static testMethod void testMassEmailUtility()
	{
		Folder testFolder = [SELECT Id FROM Folder LIMIT 1];//WHERE Name = 'EEO Mail Track Log Email Templates' 
		
		EmailTemplate temp = new EmailTemplate();
		temp.templateType = 'text';
		temp.Body = 'my test';
		temp.Description = 'tests';
		temp.DeveloperName = 'Some_Email_Test012351AAAABB';
		temp.Name = 'Some Email Name';
		temp.FolderId = UserInfo.getUserId();//testFolder.Id;
		temp.IsActive = true;
		
		insert temp;
		
		//Contact cont = [SELECT Id FROM Contact LIMIT 1];//new Contact();
		
		MassEmailUtility mass = new MassEmailUtility();
		mass.setDescription('test description');
		mass.setSaveAsActivity(false);
		mass.setTemplateId(temp.Id);
		mass.setTargetObjectIds(new List<Id>{UserInfo.getUserId()});//{cont.Id});//});
		mass.setWhatIds(null);
		
		List<Messaging.SendEmailResult> emailResults =mass.sendMesssage();
		for (Messaging.SendEmailResult res: emailResults)
		{
			System.assert(res.isSuccess(), 'Email Results with parameters List<String>, String Subject, String Body: is now failing');
		}
		//EmailUtility.sendBulkMessages(new List<EmailUtility>{mass});
		
	}
}