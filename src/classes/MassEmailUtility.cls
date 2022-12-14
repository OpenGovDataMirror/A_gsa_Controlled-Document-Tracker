
public with sharing class MassEmailUtility extends EmailUtility
{
	public MassEmailUtility()
	{
		mail = new Messaging.MassEmailMessage();
		//mail.setSaveAsActivity(false);
	}
	
	public void setDescription(String description)
	{
		((Messaging.MassEmailMessage)mail).setDescription(description);
	}
	
	public override void setTemplateId(Id tempId)
	{
		((Messaging.MassEmailMessage)mail).setTemplateId(tempId);
	}
	
	//Sets the target Ids for templates to contain the correct data.
	//They can be of type: Contact, Lead, or User.
	public void setTargetObjectIds(List<Id> targetIds)
	{
		((Messaging.MassEmailMessage)mail).setTargetObjectids(targetIds);
	}
	
	//Can only be used in conjunction with TargetObjectIds.
	//Sets the whatIds for templates to contain the correct data.
	//They can be of type: Contract, Case, Opportunity, Product.
	public void setWhatIds(List<Id> whatIds)
	{
		((Messaging.MassEmailMessage)mail).setWhatIds(whatIds);
	}
}