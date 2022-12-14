
public abstract class EmailUtility
{
	//Creating static vars so that Developers can easily find the email Priorities
	public static String HIGHEST_EMAIL_PRIORITY = 'Highest';
	public static String HIGH_EMAIL_PRIORITY = 'High';
	public static String NORMAL_EMAIL_PRIORITY = 'Normal';
	public static String LOW_EMAIL_PRIORITY = 'Low';
	public static String LOWEST_EMAIL_PRIORITY = 'Lowest';
	
	//Standard Messaging
	protected Messaging.Email mail;
	
	public void setSubject(String subject)
	{
		mail.setSubject(subject);
	}
	
	public void setSenderDisplayName(String senderDisplayName)
	{
		mail.setSenderDisplayName(senderDIsplayName);
	}
	
	public void setEmailPriority(String priority)
	{
		mail.setEmailPriority(priority);
	}
	
	//If you are sending to a User, then save this value to false.
	public void setSaveAsActivity(boolean saveAs)
	{
		mail.setSaveAsActivity(saveAs);
	}
	
	public void setBccSender(boolean bccSender)
	{
		mail.setBccSender(bccSender);
	}
	
	public void setReplyTo(String reply)
	{
		mail.setReplyTo(reply);
	}
	
	public abstract void setTemplateID(Id tempId);
	
	public void setUseSignature(boolean useSig)
	{
		mail.setUseSignature(useSig);
	}
	
	//Sends the current email
	//@return List<Messaging.SendEmailResult>-Result of the send message
	public List<Messaging.SendEmailResult> sendMesssage()
	{
		return Messaging.sendEmail(new List<Messaging.Email>{ mail });
	}
	
	//Static method to send a List of EmailUtilities at once.
	//@param utils-List of UtilityEmails to be sent
	//@return List<Messaging.SendEmailResult>-List of Results the calling class can deal with as sees fit
	public static List<Messaging.SendEmailResult> sendBulkMessages(List<EmailUtility> utils)
	{
		List<Messaging.Email> emails = new List<Messaging.Email>();
		for (EmailUtility util: utils)
			emails.add(util.Mail);
		
		return Messaging.sendEmail(emails);
	}
	
	//Method to send an email with the bare minimum asked for.  Some values get defaulted
	//@param recipients-List of emails to send the email to.
	//@param subject-Subject of the email
	//@param body-The body of the email
	//@return List<Messaging.SendEmailResult>-Collection of results from emails being sent.
	//                                       -Should usually only matter if there are errors.
	public static List<Messaging.SendEmailResult> sendSingleMessage(List<String> recipients, String subject, String body)
	{
		return EmailUtility.sendSingleMessage(recipients, new String[]{}, 'noreply@salesforce.com', 'No Reply', subject, body);
	}
	
	/*
		Function to easily send emails without looking up the setup.
		This function expects all inputs to be valid.
		@param recipients-People to recieve the email
		@param ccRecipients-People to be copied in the email
		@param reply-The email that will be replied to if the user chooses to reply
		@param subject-The header of the email
		@param body-The body of the email
		@return List<Messaging.SendEmailResult>- List of results of the email.
		                                        -The requesting class can handle this as it sees fit.
	*/
	public static List<Messaging.SendEmailResult> sendSingleMessage(List<String> recipients, List<String> ccRecipients, String reply, String senderName, String subject, String body)
	{
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		
		mail.setReplyTo(reply);
		mail.setSenderDisplayName(senderName);
		mail.setSubject(subject);
		mail.setBccSender(false);
		mail.setUseSignature(false);
		mail.setPlainTextBody(body);
		mail.setHtmlBody(body);
		mail.setToAddresses(recipients);
		mail.setCcAddresses(ccRecipients);
		
		return Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
	}
	
	//Method that lets the user specify all the parts of a SingleEmailMessage and send it.
	//NOTE-You should only use if you are very familiar with all of the parts of the email.
	//@return List<Messaging.SendEmailResult>-Result of the email to be sent
	public static List<Messaging.SendEmailResult> sendSingleMessage(List<String> recipients, List<String> bccAddresses,
			boolean bccSender, List<String> ccAddresses, String charSet, String priority, 
			List<Messaging.EmailFileAttachment> attachments, String htmlBody, String inReplyTo, Id orgWideAddressId,
			String plainText, String references, String replyTo, String senderDisplayName, String subject, 
			Id targetId, Id templateId, Id whatId)
	{
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		mail.setToAddresses(recipients);
		mail.setBccAddresses(bccAddresses);
		mail.setBccSender(bccSender);
		mail.setCcAddresses(ccAddresses);
		mail.setCharset(charSet);
		mail.setEmailPriority(priority);
		mail.setFileAttachments(attachments);
		mail.setHtmlBody(htmlBody);
		mail.setInReplyTo(inReplyTo);
		mail.setOrgWideEmailAddressId(orgWideAddressId);
		mail.setPlainTextBody(plainText);
		mail.setReferences(references);
		mail.setReplyTo(replyTo);
		mail.setSenderDisplayName(senderDisplayName);
		mail.setSubject(subject);
		mail.setTargetObjectId(targetId);
		mail.setTemplateId(templateId);
		mail.setWhatId(whatId);
		
		//mail.setBccAddresses(pList)
		return Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
	}
}