Trigger CDT_AttachmentError on Attachment (before insert) {

    CDT_AttachmentErrorHelper.AttachmentError(trigger.new);
}