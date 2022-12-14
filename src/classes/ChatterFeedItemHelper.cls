

public class ChatterFeedItemHelper {
    
    public static void preventfeedItemDelete(List<FeedItem> cdtfeed){
        Set<ID> controlDocumentID = new Set<ID>();
        Map<Id,String> cdIdMap = new Map<Id, String>();
       	Set<Id> cvIdSet = new Set<Id>();
        Set<Id> cdocIdSet = new Set<Id>();
        Map<Id, Id> cvTocdMap = new Map<Id, Id>();
        for(FeedItem f :cdtfeed) {
            System.debug(' feed type : '+f.type);
            System.debug(' relatedrecord id : '+f.RelatedRecordId);
            system.debug(' parent id : '+f.parentid);
           if(f.Type == 'ContentPost' && f.parentId.getSObjectType().getDescribe().getName() == 'Controlled_Document__c') {
               // f.addError('you cannot delete this attachment. Please contact your administrator for assistance.',FALSE);
               ControlDocumentID.add(f.parentId);
               //System.debug('related record id : '+f.relatedrecordid);
               if(f.RelatedRecordId != null)
                   cvIdSet.add(f.RelatedRecordId);
            } 
        }
        // Identify the ContentDocument Ids by using ContentVersion Ids
        for(ContentVersion cv : [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id IN :cvIdSet]) {
            cdocIdSet.add(cv.ContentDocumentId);
            cvTocdMap.put(cv.Id, cv.ContentDocumentId);
        }
        Map<Id, ContentDocument> contentVersionMap = getContentVersionMap(cdocIdSet);
        //System.debug('CVMap size '+contentVersionMap.size());
        List<GroupMember> gmList = new List<GroupMember>();
        List<User> AdminList = new List<User>();
        Id userId = UserInfo.getUserId();
        gmList = [SELECT Id FROM GroupMember WHERE UserorGroupId = :userId AND Group.DeveloperName IN ('CDT_OAS_Admin_User')];
        AdminList = [SELECT Id FROM User WHERE IsActive=true AND Profile.Name ='System Administrator' AND Id =:userId];
        
        List<Controlled_Document__c> conDoc = [SELECT Id,Reason_File_Deletion__c FROM Controlled_Document__c where ID IN:ControlDocumentID];
        for(Controlled_Document__c cd : conDoc) {
             cdIdMap.put(cd.Id,cd.Reason_File_Deletion__c);
         }
        
        Id controlDocID;
        string reasonForDeletion;
        Set<Id> controlledDocuemntID = new Set<ID>(); 
        List<CDT_Deletion_Log__c> logList = new List<CDT_Deletion_Log__c>();
        for(FeedItem item : cdtfeed) {
            if(item.Type == 'ContentPost' && item.parentId.getSObjectType().getDescribe().getName() == 'Controlled_Document__c'){
                //controlDocId = item.parentId;
                reasonForDeletion = cdIdMap.get(item.parentId);
                controlledDocuemntID.add(item.parentId);
                if(item.RelatedRecordId != null) {
                    Id cdId = cvTocdMap.get(item.RelatedRecordId);
                    ContentDocument cdoc = (contentVersionMap.containsKey(cdId)) ? contentVersionMap.get(cdId) : new ContentDocument();                
            	    List<ContentVersion> versions = (cdoc != null) ? cdoc.ContentVersions : new List<ContentVersion>();
        			ContentVersion cversion = new ContentVersion();
                    if(!versions.isEmpty())
                        cversion = versions.get(0);
                    /*
                    if(String.isBlank(reasonForDeletion))
                       item.addError('You cannot delete this attachment. Please Enter the reason for deletion.',FALSE);
                    else 
                    */
                    if(isUploadedRecently(cversion,15) == false && isAdminUser(gmList, AdminList) == false) {
                        item.addError(System.Label.CDT_File_Deletion_Request,FALSE);
                    }
                    else if(isContentOnlyWithOneVersion(cversion) == false && isAdminUser(gmList, AdminList) == false) {
                        item.addError(System.Label.CDT_File_Deletion_Request,FALSE);
                    }
                    else if(String.isBlank(reasonForDeletion)) {
                       item.addError('Before deleting this file, you must fill in the Reason For File Deletion field in the Controlled Document Detail section of the record.',FALSE);
                    }                    
                    else {
                        CDT_Deletion_Log__c log = new CDT_Deletion_Log__c();
                        log.Contolled_Document__c = item.parentId;
                        log.File_Name__c= item.Title;
                        log.DeletionDate__c = Date.Today();
                        log.Reason__c = reasonForDeletion;
                        log.User_Name__c = UserInfo.getName();
                        logList.add(log);
                    }
                }               
            }   
        }
        if(!logList.isEmpty()) {    
            insert(logList);
            List<Controlled_Document__c> Cdlist = [Select ID,Reason_File_Deletion__c from Controlled_Document__c where id in :controlledDocuemntID];
            for(Controlled_Document__c record : cdlist){
                record.Reason_File_Deletion__c ='';
            }
            update(Cdlist);
        }   
     }
    //End of CDT Case#29763
    // 
    // for case# 31205 - BEGIN
    public static void deleteContentDocumentLinks(List<FeedItem> triggerOld, Map<Id, FeedItem> triggerOldMap) {
        System.debug('In deleteContentDocumentLinks ==>');
        Set<Id> cdocIds = new Set<Id>();
        List<ContentDocumentLink> cdlList = new List<ContentDocumentLink>();  
        Set<Id> relatedRecordIds = new Set<Id>();
        for(FeedItem fitem: triggerOld) {    
            // Identify the controlled document contentpost records        
            if(fitem.type == 'ContentPost' && fitem.parentId.getSObjectType().getDescribe().getName() == 'Controlled_Document__c') {
                //System.debug('ContentVersion' +fitem.relatedrecordId);
                if(fitem.RelatedRecordId != null)
                    relatedRecordIds.add(fitem.RelatedRecordId);
            }
        }
        if(!relatedRecordIds.isEmpty()) {
            // Identify the ContentDocument Ids by using ContentVersion Ids
            for(ContentVersion cv : [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id IN :relatedrecordIds]) {
                cdocIds.add(cv.ContentDocumentId);
            }    
            //System.debug('ContentVersion list size : '+cdocIds.size());
            // Identify the content document link records to remove the collaborators access for the deleted feeds/posts.
            for(ContentDocument cd : [SELECT Id, (SELECT Id FROM ContentDocumentLinks WHERE ShareType = 'C') FROM ContentDocument WHERE Id IN :cdocIds]) {
                for(ContentDocumentLink cdl : cd.ContentDocumentLinks) {
                    cdlList.add(cdl);
                }
            }            
            System.debug('CDL size :' +cdlList.size());
            try {
                if(!cdlList.isEmpty())
                    delete cdlList;
            }
            catch(DMLException e) {
                System.debug(LoggingLevel.INFO,'ChatterFeedItemTrigger - After Delete error '+e.getMessage());    
            }   
        }    
    }
    // for case# 31205 - END
    // case# RITM0475411 - BEGIN
    public static Map<Id, ContentDocument> getContentVersionMap(Set<Id> contentDocumentIds){
        return new Map<Id, ContentDocument>([
            SELECT Id, 
            (
                SELECT Id, VersionNumber, CreatedDate, ContentDocumentId 
                FROM ContentVersions 
                WHERE IsLatest = true
            ) 
            FROM ContentDocument 
            WHERE Id IN :contentDocumentIds
        ]);
    }
    public static Boolean isContentOnlyWithOneVersion(ContentVersion cv) {
        System.debug('Version Number : '+cv.versionnumber);
        System.debug('cv : '+cv);
        return ((cv.versionNumber == '1') ? true : false);
    }
    
    public static Boolean isUploadedRecently(ContentVersion cv, Integer minutesgap) {
    	Boolean result = false;
        //System.debug(cv.createddate);
        DateTime dt = cv.CreatedDate;
        DateTime changed = dt.addMinutes(minutesgap);
        DateTime dtime = DateTime.now();
        if(changed >= dtime) 
            result = true;                
        return result;
    }
    
    public static Boolean isAdminUser(List<GroupMember> gmList, List<User> AdminList) {
        return ((!AdminList.isEmpty() || !gmList.isEmpty()) ? true : false); 
    }
}