
public class CDTPreventAttachmentDeleteHelper {
    /* commented for the task# RITM0466275
    public static void preventDeletemethod(List<ContentDocument> contentDocs){
        //test 
        List<Controlled_Document__c> conDoc = [SELECT Id,Reason_File_Deletion__c FROM Controlled_Document__c];
    	 Map<Id,String> cdIdMap = new Map<Id, String>();
         Set<Id> cdId = new Set<Id>();
           
        for(Controlled_Document__c cd : conDoc){
             cdIdMap.put(cd.Id,cd.Reason_File_Deletion__c);
             cdId.add(cd.Id);
         }
        List<ContentDocumentLink> clink = [Select Id,ContentDocumentId,LinkedEntityId from ContentDocumentLink Where LinkedEntityId IN:cdID];
        set<Id> AttId = new Set<Id>();
        Map<ID,ID> CDMap = new Map<ID,ID>();
        for(ContentDocumentLink cd : clink){
            AttId.add(cd.ContentDocumentId);
           // contentDocumentReasonMap.put(cd.contentDocumentID,cdIdMap.get(cd.LinkedEntityId));
           CDMap.put(cd.contentDocumentID,cd.LinkedEntityId);
        }
        system.debug('**'+AttId);
        List<CDT_Deletion_Log__c> logList = new List<CDT_Deletion_Log__c>();
        String reasonForDeletion;
        ID controlDocumentID;
        Set<ID> controlDocumentIDset = new Set<ID>();
        for(ContentDocument c : contentDocs){
            if(AttId.contains(c.Id)){
                controlDocumentID = CDMap.get(c.ID);
                reasonForDeletion = cdIdMap.get(controlDocumentID);
                controlDocumentIDset.add(controlDocumentID);
                if(String.isBlank(reasonForDeletion))
                   c.addError('You cannot delete this attachment. Please Enter the reason for deletion.',FALSE);
                else {
                       CDT_Deletion_Log__c log = new CDT_Deletion_Log__c();
                    	log.Contolled_Document__c = controlDocumentID;
                    	log.File_Name__c= c.Title;
                    	log.DeletionDate__c = Date.Today();
                    	log.Reason__c = reasonForDeletion;
                    	log.User_Name__c = UserInfo.getName();
                    	logList.add(log);
                    	
                }
            	
            }
            
    	}
        Insert(logList);
		List<Controlled_Document__c> Cdlist = [Select ID,Reason_File_Deletion__c from Controlled_Document__c where id in :controlDocumentIDset];
        for(Controlled_Document__c record : cdlist){
            record.Reason_File_Deletion__c ='';
        }
        Update(Cdlist);
    } */
    // added below code for task# RITM0466275 - BEGIN
    public static void preventDeletemethod(List<ContentDocument> contentDocs) {
        Map<Id, String> controldocIdMap = new Map<Id, String>();
        Map<Id, Id> controldocMap = new Map<Id, Id>();
        Map<Id,Id> cdMap = new Map<Id,Id>();        
        Set<Id> cdIdSet = new Set<Id>();
        List<CDT_Deletion_Log__c> logList = new List<CDT_Deletion_Log__c>();
        Set<Id> controlDocIdSet = new Set<Id>();        
        //Set<Id> AttId = new Set<Id>();
        String reasonForDeletion;
        Id controlDocumentId;        
        // capture the contentdocument ids
        for(ContentDocument cd : contentDocs) {
            cdIdSet.add(cd.Id);
        }   
        //List<ContentDocumentLink> clink = [Select Id,ContentDocumentId,LinkedEntityId from ContentDocumentLink Where ContentDocumentId IN:cdID];
        Map<Id, ContentDocument> contentDocumentMap = getContentDocumentMap(cdIdSet);
        Map<Id, ContentDocument> contentVersionMap = getContentVersionMap(cdIdSet);
        // identify the respective controlled document record ids by using respective content document ids
        for(ContentDocument contentDoc: contentDocs) {
            ContentDocument cDocument = (contentDocumentMap.containsKey(contentDoc.Id)) ? contentDocumentMap.get(contentDoc.Id) : new ContentDocument();                
            List<ContentDocumentLink> contentDocumentLinkList = (cDocument != null) ? cDocument.ContentDocumentLinks : new List<ContentDocumentLink>();
            //Id controlledDocId = contentDocToControlledDocMap.get(contentDoc);                                
            for(ContentDocumentLink cdl : contentDocumentLinkList) {
                controldocMap.put(cdl.Linkedentityid, cdl.contentdocumentid);
                cdMap.put(cdl.contentdocumentId, cdl.linkedentityid);
            }            
        }
        
        for(Controlled_Document__c cd : [SELECT Id, Reason_File_Deletion__c 
                                         FROM Controlled_Document__c 
                                         WHERE Id IN :controldocMap.keySet()]){
                                             controldocIdMap.put(cd.Id, cd.Reason_File_Deletion__c);
                                             //cdId.add(cd.Id);
                                         }
        
        List<GroupMember> gmList = new List<GroupMember>();
        List<User> AdminList = new List<User>();
        Id userId = UserInfo.getUserId();
        gmList = [SELECT Id FROM GroupMember WHERE UserorGroupId = :userId AND Group.DeveloperName IN ('CDT_OAS_Admin_User')];
        AdminList = [SELECT Id FROM User WHERE IsActive=true AND Profile.Name ='System Administrator' AND Id =:userId];
        
        //system.debug('**'+AttId);
        for(ContentDocument c : contentDocs) {
            if(cdMap.containsKey(c.Id)) {
                controlDocumentId = cdMap.get(c.Id);
                if(controldocIdMap.containsKey(controlDocumentId)) {
                    ContentDocument cdoc = (contentVersionMap.containsKey(c.Id)) ? contentVersionMap.get(c.Id) : new ContentDocument();                
            	    List<ContentVersion> versions = (cdoc != null) ? cdoc.ContentVersions : new List<ContentVersion>();
        			ContentVersion cversion = new ContentVersion();
                    if(!versions.isEmpty())
                        cversion = versions.get(0);
                    reasonForDeletion = controldocIdMap.get(controlDocumentId);
                    /*
                    if(String.isBlank(reasonForDeletion))
                        c.addError('You cannot delete this attachment. Please Enter the reason for deletion.');                    
                    else
                    */
                    if(isUploadedRecently(cversion,15) == false && isAdminUser(gmList, AdminList) == false) {
                      	c.addError(System.Label.CDT_File_Deletion_Request,FALSE);
                    }
                    else if(isContentOnlyWithOneVersion(cversion) == false && isAdminUser(gmList, AdminList) == false) {
                      	c.addError(System.Label.CDT_File_Deletion_Request,FALSE);
                    }
					else if(String.isBlank(reasonForDeletion)) {
                       c.addError('Before deleting this file, you must fill in the Reason For File Deletion field in the Controlled Document Detail section of the record.',FALSE);
                    }                    
                    else {
                        CDT_Deletion_Log__c log = new CDT_Deletion_Log__c();
                        log.Contolled_Document__c = controlDocumentId;
                        log.File_Name__c= c.Title;
                        log.DeletionDate__c = Date.Today();
                        log.Reason__c = reasonForDeletion;
                        log.User_Name__c = UserInfo.getName();
                        logList.add(log);
                        controlDocIdSet.add(controlDocumentId);                
                    }    
                }                            	
            }            
        }
        if(!logList.isEmpty()) {
            insert(logList);        
            List<Controlled_Document__c> cdList = [SELECT Id, Reason_File_Deletion__c 
                                                   FROM Controlled_Document__c 
                                                   WHERE Id IN :controlDocIdSet];
            for(Controlled_Document__c cd : cdList){
                cd.Reason_File_Deletion__c ='';
            }
            update(cdList);
        }    
    }
    
    public static Map<Id, ContentDocument> getContentDocumentMap(Set<Id> contentDocumentIds){
        return new Map<Id, ContentDocument>([
            SELECT Id, 
            (
                SELECT Id, LinkedEntityId, ContentDocumentId 
                FROM ContentDocumentLinks 
                WHERE ShareType = 'V'
            ) 
            FROM ContentDocument 
            WHERE Id IN :contentDocumentIds
        ]);
    }
    
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
        return ((cv.versionNumber == '1') ? true : false);
    }
    
    public static Boolean isUploadedRecently(ContentVersion cv, Integer minutesgap) {
    	Boolean result = false;
        System.debug(cv.createddate);
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
    // added below code for task# RITM0466275 - END
    
}