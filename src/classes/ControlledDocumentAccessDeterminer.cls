
public without sharing class ControlledDocumentAccessDeterminer {

     private static List<User> AllExecSecUsers = new List<User>();
    // this works for a single controlled document
    public static boolean checkCollaboratorStatus(Id controlledDocument){

        boolean notCollaborator = false;
        
        Map<Id,ContentVersion> contentVersionMap = new Map<Id,ContentVersion>();
        List<FeedItem> feedItems = getFeedItems(new Set<Id>{controlledDocument});
        for(FeedItem item : feedItems){
            contentVersionMap.put(item.RelatedRecordId, null);
        }

        contentVersionMap = getContentVersionMap(contentVersionMap.keySet());

        boolean notAuthorized = false;
        for(FeedItem item : feedItems){
            if(contentversionMap.get(item.RelatedRecordId) == null){
                // we need to simulate the user clicking the button
                notAuthorized = true;
            }
        }

        // user hasn't clicked the button before
        if(notAuthorized) { 
            notCollaborator = true;
        }

        return notCollaborator;

    }

    public static void syncAccessToChatterFiles(List<Supplementary_Access_User__c> supplementList){

        Set<Id> controlledDocumentIdSet = new Set<Id>();
        for(Supplementary_Access_User__c supplement : supplementList){
            controlledDocumentIdSet.add(supplement.Controlled_Document__c);
        }

        syncAccessToChatterFiles(controlledDocumentIdSet);

    }

    public static void syncAccessToChatterFiles(Set<Id> controlledDocumentIdSet){

        Map<Id, Controlled_Document__c> controlledDocumentMap = new Map<Id, Controlled_Document__c>([
                                                                                                SELECT Id, OwnerId 
                                                                                                FROM Controlled_Document__c 
                                                                                                WHERE Id IN :controlledDocumentIdSet
                                                                                            ]);

        List<Approval_Step__c> relevantApprovalSteps = getApprovalSteps(controlledDocumentIdSet);
        List<Supplementary_Access_User__c> relevantSupplementaryAccessUsers = getSupplements(controlledDocumentIdSet);
        
        Map<Id, List<Id>> controlledDocumentToUserMap = new Map<Id, List<Id>>();
        Id admin = getAdminUserThatShouldAlwaysHaveAccess();
        getUsersThatShouldHaveAccess(relevantApprovalSteps, controlledDocumentToUserMap);
        getUsersThatShouldHaveAccess(relevantSupplementaryAccessUsers, controlledDocumentToUserMap);
        
        // SFEEO-1498: Grant collaborator access to Exec Sec users
        Set<Id> ExecSecUserIdSet = new Set<Id>();
        for(User ExecSecUserRec : getAllExecSecUsers())
        {
            ExecSecUserIdSet.add(ExecSecUserRec.Id);
        }

        List<FeedItem> relevantFeedItems = getFeedItems(controlledDocumentIdSet);
        Set<Id> contentVersionIdSet = new Set<Id>();
        for(FeedItem item : relevantFeedItems){
            contentVersionIdSet.add(item.RelatedRecordId);
        }

        Map<Id, ContentVersion> contentVersionMap = getContentVersionMap(contentVersionIdSet);
        Set<Id> contentDocumentIdList = new Set<Id>();
        for(ContentVersion contentVersion : contentVersionMap.values()){
            contentDocumentIdList.add(contentVersion.ContentDocumentId);
        }

        Map<Id, ContentDocument> contentDocumentMap = getContentDocumentMap(contentDocumentIdList);

        // identify which of these CDLs are okay to delete

        Map<Id, List<Id>> controlledDocumentToContentDocumentMap = makecontrolledDocumentToContentDocumentMap(relevantFeedItems, contentVersionMap);
        Map<Id, ContentDocumentLink> contentDocumentLinksToDelete = new Map<Id, ContentDocumentLink>();
        List<ContentDocumentLink> contentDocumentLinksToAdd = new List<ContentDocumentLink>();
        for(Id controlDoc : controlledDocumentToContentDocumentMap.keySet()){

            ///////////////////////////////////////////////////////////////////////////////////
            List<Id> usersThatShouldRetainAccess = controlledDocumentToUserMap.get(controlDoc);
            Id ownerId = controlledDocumentMap.get(controlDoc).OwnerId;
            ///////////////////////////////////////////////////////////////////////////////////

            // deletes bad cdls
            for(Id contentDocument : controlledDocumentToContentDocumentMap.get(controlDoc)){
                if(contentDocumentMap.containsKey(contentDocument)) {
                    List<ContentDocumentLink> contentDocumentLinkList = contentDocumentMap.get(contentDocument).ContentDocumentLinks;
                    for(ContentDocumentLink contentDocLink : contentDocumentLinkList){
                        if(admin == contentDocLink.LinkedEntityId) continue; // ALWAYS skip the admin
                        if(ownerId == contentDocLink.LinkedEntityId) continue; // ALWAYS skip the record owner
                        if(ExecSecUserIdSet.contains(contentDocLink.LinkedEntityId)) continue; // ALWAYS skip the Exec Sec Users

                        boolean userFound = false;
                        if(usersThatShouldRetainAccess != null) { 
                            for(Id user : usersThatShouldRetainAccess){

                                if(user == contentDocLink.LinkedEntityId) {
                                    userFound = true;
                                    continue;
                                }

                            }
                        }
                        if(!userFound && !contentDocumentLinksToDelete.containsKey(contentDocLink.Id)) {
                            contentDocumentLinksToDelete.put(contentDocLink.Id, contentDocLink);
                        } 

                    }
                }
            }
        }

        delete contentDocumentLinksToDelete.values();
      }
    
    @TestVisible
    public static List<User> getAllExecSecUsers(){
       
       if(AllExecSecUsers.isEmpty())
       {
           Set<Id> ExecSecUserGroupIds = new Set<Id>();
           Set<Id> ExecSecUserIds = new Set<Id>();
       
           for(Group ExecSecGroup : [Select Id FROM Group WHERE developerName IN ('CDT_OAS_Admin_User', 'CDT_OAS_User')])
           {
               ExecSecUserGroupIds.add(ExecSecGroup.Id);
           }
           
           for(GroupMember ExecSecGroupMember : [Select UserOrGroupId FROM GroupMember WHERE GroupId IN :ExecSecUserGroupIds]){
               ExecSecUserIds.add(ExecSecGroupMember.UserOrGroupId);
           }
           
           for(User ExecSecUser : [Select Id, Name, isActive, username, Email, UserPreferencesDisableMessageEmail FROM User WHERE Id IN :ExecSecUserIds AND isActive = True]){
               AllExecSecUsers.add(ExecSecUser);
           }
       }
       
       return AllExecSecUsers;
    }
    
    private static Id getAdminUserThatShouldAlwaysHaveAccess(){

        List<Controlled_Document_Admin__c> adminUser = [SELECT Id, UserName__c FROM Controlled_Document_Admin__c LIMIT 1];
        if(adminUser.isEmpty()) return null;
        List<User> userList = [SELECT Id FROM User WHERE UserName = :adminUser[0].UserName__c];
        if(userList.isEmpty()) return null;
        return userList[0].Id;

    }

    private static void getUsersThatShouldHaveAccess(List<Approval_Step__c> approvalSteps, Map<Id, List<Id>> controlledDocumentToUserMap){

        for(Approval_Step__c step : approvalSteps){
            Id controlledDocument = step.Correspondence_Document__c;
            Id user = step.Assigned_Approver__c;
            if(!controlledDocumentToUserMap.containsKey(controlledDocument)){
                List<Id> tempList = new List<Id>();
                tempList.add(user);
                controlledDocumentToUserMap.put(controlledDocument, tempList);
            } else {
                controlledDocumentToUserMap.get(controlledDocument).add(user);
            }
        }

    }

    private static void getUsersThatShouldHaveAccess(List<Supplementary_Access_User__c> supplements, Map<Id, List<Id>> controlledDocumentToUserMap){

        for(Supplementary_Access_User__c supplement : supplements){
            Id controlledDocument = supplement.Controlled_Document__c;
            Id user = supplement.User__c;
            if(!controlledDocumentToUserMap.containsKey(controlledDocument)){
                List<Id> tempList = new List<Id>();
                tempList.add(user);
                controlledDocumentToUserMap.put(controlledDocument, tempList);
            } else {
                controlledDocumentToUserMap.get(controlledDocument).add(user);
            }
        }

    }

    private static List<Approval_Step__c> getApprovalSteps(Set<Id> controlledDocumentIdSet){

        return [
            SELECT Id, Assigned_Approver__c, Correspondence_Document__c
            FROM Approval_Step__c 
            WHERE Correspondence_Document__c IN :controlledDocumentIdSet
        ];

    }

    private static List<Supplementary_Access_User__c> getSupplements(Set<Id> controlledDocumentIdSet){
         return [
                SELECT Id, Active__c, User__c, Controlled_Document__c
                FROM Supplementary_Access_User__c
                WHERE Active__c = true
                AND Controlled_Document__c IN :controlledDocumentIdSet
            ];
    }

    private static List<FeedItem> getFeedItems(Set<Id> controlledDocumentIdSet){

        return [
            SELECT Id, Type, Title, RelatedRecordId, ParentId, LinkUrl, 
            // commented for case# 23872
            //Body, ContentData, 
            CreatedById, ContentType, ContentSize, ContentFileName,
            // commented for case# 23872
            //ContentDescription, 
            CommentCount
            FROM FeedItem
            WHERE ParentId IN :controlledDocumentIdSet
            AND Type = 'ContentPost'
        ];

    }

    private static Map<Id, ContentVersion> getContentVersionMap(Set<Id> contentVersionIdSet){

        return new Map<Id, ContentVersion>([
                                        SELECT Id, ContentDocumentId, ContentDocument.OwnerId, ContentDocument.Title 
                                        FROM ContentVersion 
                                        WHERE Id IN :contentVersionIdSet
                                    ]);

    }

    private static Map<Id, ContentDocument> getContentDocumentMap(Set<Id> contentDocumentIdList){

        return new Map<Id, ContentDocument>([
                                        SELECT Id, 
                                            (
                                                SELECT LinkedEntityId, ShareType, IsDeleted 
                                                FROM ContentDocumentLinks 
                                                WHERE ShareType = 'C'
                                            ) 
                                        FROM ContentDocument 
                                        WHERE Id IN :contentDocumentIdList
                                    ]);

    }

    private static Map<Id, List<Id>> makecontrolledDocumentToContentDocumentMap(List<FeedItem> feedItems, Map<Id, ContentVersion> contentVersionMap){

        Map<Id, List<Id>> tempMap = new Map<Id, List<Id>>();
        for(FeedItem feedItem : feedItems){

            Id controlledDocumentId = feedItem.ParentId;
            Id contentVersionId = feedItem.RelatedRecordId;

            if(contentVersionMap.get(contentVersionId) == null) continue; // prevents null pointers that Kimberley was getting

            if(!tempMap.containsKey(controlledDocumentId)){
                tempMap.put(controlledDocumentId, new List<Id>());
                tempMap.get(controlledDocumentId).add(contentVersionMap.get(contentVersionId).ContentDocumentId);
            } else {
                tempMap.get(controlledDocumentId).add(contentVersionMap.get(contentVersionId).ContentDocumentId);
            }

        }

        return tempMap;

    }

}