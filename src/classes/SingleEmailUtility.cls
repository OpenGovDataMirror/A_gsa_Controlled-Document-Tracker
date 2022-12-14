/*
	SingleEmailUtility
	Utility class meant specifically to help out with shared procedures
	for Single Emails.
	-------------------------------------------------------------------
	Author                 Date           Release           Description
	-------------------------------------------------------------------
	Damien Phillippi       9/29/2011      11/14/2011        Creation
*/
public with sharing class SingleEmailUtility extends EmailUtility
{
	public SingleEmailUtility()
	{
		mail = new Messaging.SingleEmailMessage();
	}
	
	public void setBccAddresses(List<String> bccAddresses)
	{
		((Messaging.SingleEmailMessage)mail).setBccAddresses(bccAddresses);
	}
	
	public void setCcAddresses(List<String> ccAddresses)
	{
		((Messaging.SingleEmailMessage)mail).setCcAddresses(ccAddresses);
	}
	
	public void setCharset(String charset)
	{
		((Messaging.SingleEmailMessage)mail).setCharset(charset);
	}
	
	//NOTE-Size of docs cannot exceed 10MB
	public void setDocumentAttachments(List<Id> docIds)
	{
		((Messaging.SingleEmailMessage)mail).setDocumentAttachments(docIds);
	}
	
	//NOTE-Size of files cannot exceed 10MB
	public void setFileAttachments(List<Messaging.EmailFileAttachment> fileAttachments)
	{
		((Messaging.SingleEmailMessage)mail).setFileAttachments(fileAttachments);
	}
	
	public void setHTMLBody(String htmlBody)
	{
		((Messaging.SingleEmailMessage)mail).setHTMLBody(htmlBody);
	}
	
	//@param inReplyTo-Ids of the parent email this email will be replying to.
	public void setInReplyTo(String inReplyTo)
	{
		((Messaging.SingleEmailMessage)mail).setInReplyTo(inReplyTo);
	}
	
	public void setPlainTextBody(String plainText)
	{
		((Messaging.SingleEmailMessage)mail).setPlainTextBody(plainText);
	}
	
	public void setOrgWideEmailAddressId(Id orgWideId)
	{
		((Messaging.SingleEmailMessage)mail).setOrgWideEmailAddressId(orgWideId);
	}
	
	//Set what the email refers to.  It could be a parent email or an email thread.
	public void setReferences(String references)
	{
		((Messaging.SingleEmailMessage)mail).setReferences(references);
	}
	
	//@param targetId-Id of the Contact, Lead, or User that the email will be sent to.
	//               -This will make sure merge fields are correct for the template that is set.
	//NOTE-Make sure you are using a template also.
	public void setTargetObjectId(Id targetId)
	{
		((Messaging.SingleEmailMessage)mail).setTargetObjectId(targetId);
	}
	
	public override void setTemplateId(Id tempId)
	{
		((Messaging.SingleEmailMessage)mail).setTemplateId(tempId);
	}
	
	public void setToAddresses(List<String> addresses)
	{
		((Messaging.SingleEmailMessage)mail).setToAddresses(addresses);
	}
	
	//This method should be used in conjunction of the targetObjectId.  It will help ensure that
	//merge fields will contain the correct data.
	//@param whatId-This should be the Id of:
	//             -Account, Asset, Campaign, Case, Contract, Opportunity, Order, Product, Solutions, or Custom
	public void setWhatId(Id whatId)
	{
		((Messaging.SingleEmailMessage)mail).setWhatId(whatId);
	}
}