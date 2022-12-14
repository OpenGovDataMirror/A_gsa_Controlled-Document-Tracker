/*-------------------------------------------------------------------------------------------------*
Trigger on Content Document Object to prevent users from deleting attachments from Controlled_Document__c
object. 
*--------------------------------------------------------------------------------------------------*
Author           | Date        | Version | Description
*--------------------------------------------------------------------------------------------------*
Ramesh Dugar       03/27/2017    1.0       Trigger Created
*--------------------------------------------------------------------------------------------------*/
trigger CDTPreventAttachmentDeleteTrigger on ContentDocument (before Delete) {
    if(trigger.isDelete && trigger.isBefore){
        //For case#29763
        CDTPreventAttachmentDeleteHelper.preventDeletemethod(trigger.old);
    }
}