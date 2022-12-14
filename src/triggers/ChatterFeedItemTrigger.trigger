/*-------------------------------------------------------------------------------
  ChatterFeedItemTrigger
  Chatter FeedItem Trigger on ConnectApi.FeedItem object
  -------------------------------------------------------------------------------
  Author                 |Date       | Version | Description
  -------------------------------------------------------------------------------
  Rajakumar               03/25/2014   1.0       Creation
  Rajakumar               04/30/2014   1.1       Task #00012362 -chatter email notification
  Stefan Maurer           12/01/2014   1.2       Added call to chatter file colaborator
  Raja Kumar P            08/22/2016   1.3       case# 26931- EBC chatter feed file types prevention added for before insert
  Raja Kumar P            02/02/2018   1.4       RITM0475411 & RITM0466275-Fixed the issue of delete operations code overwritten on 8/3/2017 10:17AM.
  Kumar                   04/12/2019   1.5       CDT Ticket# RITM0589850 - chatter group @mention record sharing for CDT-L & CDT-S groups.
  Kishore				  05/09/2020   1.6		 SFEEO 1966. Removed all the record sharing functionality using @mention.
  -------------------------------------------------------------------------------
  ------------------------------------------------------------------------------- */
trigger ChatterFeedItemTrigger on FeedItem (after insert, before insert, before delete, after delete) {
    if(Trigger.isAfter && Trigger.isInsert) {
        /*EBC_ExecutiveBusinessCaseTriggerHelper.preventFewAttachmentTypes(Trigger.new);
        if(!CriticalItemChatterFeedRecursionCheck.hasAlreadyInserted()){
            ChatterFeedItemHelper.recordSharing(Trigger.new);
        }*/
        }
    // case# 26931 v1.3 - BEGIN
    if(Trigger.isBefore && Trigger.isInsert) {
        //SDChatterFeedItemHelper.dontAllowChatterFeedUploadsOnSDRelatedObjects(trigger.new);
    }
    // case# 26931 v1.3 - END
    // Case# 29763 - BEGIN
    // Author - Ramesh Dugar, Related to CDT Application
    if(Trigger.isBefore && Trigger.isDelete){
        ChatterFeedItemHelper.preventfeedItemDelete(Trigger.old);
    }
    //Case# 29763 - END
    // for case# 31205
    if(Trigger.isAfter && Trigger.isDelete) {
        ChatterFeedItemHelper.deleteContentDocumentLinks(Trigger.old, Trigger.oldMap);
    }
}