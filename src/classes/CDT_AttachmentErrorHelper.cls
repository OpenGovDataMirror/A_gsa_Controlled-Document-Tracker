Public with sharing class CDT_AttachmentErrorHelper{
    Public Static void AttachmentError(List<Attachment> attachment){        
        for(Attachment att:attachment){
            if(att.ParentId.getSobjectType() == Controlled_Document__c.SobjectType){  
                att.addError('To upload new files:  Attach in Chatter feed.<br/> To update existing files:  Click on document title in Notes & Attachments.',FALSE);
            }
        }   
    }
}