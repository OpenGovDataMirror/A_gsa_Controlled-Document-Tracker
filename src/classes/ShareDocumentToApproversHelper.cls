
public class ShareDocumentToApproversHelper {
    public static Boolean isFirstTime = true;
    public static void manageControlledDocumentSharing(Map<Id, Approval_Step__c> oldSteps, List<Approval_Step__c> newSteps){
        Set<Id> controlledDocumentsToUpdateAccess = new Set<Id>();
        Id previousApproverId;

        for(Approval_Step__c newStep : newSteps){
            previousApproverId = Trigger.isInsert ? null : oldSteps.get(newStep.Id).Assigned_Approver__c;
            if(newStep.Assigned_Approver__c != previousApproverId){
                controlledDocumentsToUpdateAccess.add(newStep.Correspondence_Document__c);
            }
            // case# 21548 - BEGIN
            if(newStep.Marked_for_Deletion__c == true && newStep.Assigned_Approver__c != null && 
                newStep.Marked_for_Deletion__c != oldSteps.get(newStep.Id).Marked_for_Deletion__c) {
                controlledDocumentsToUpdateAccess.add(newStep.Correspondence_Document__c);
            }
            // case# 21548 - END
        }

        manageControlledDocumentSharing(controlledDocumentsToUpdateAccess);
    }

    public static void manageControlledDocumentSharing(List<Supplementary_Access_User__c> oldSharingUsers, List<Supplementary_Access_User__c> newSharingUsers){
        List<Supplementary_Access_User__c> combinedSharingUsers = new List<Supplementary_Access_User__c>();
        combinedSharingUsers.addAll(oldSharingUsers);
        combinedSharingUsers.addAll(newSharingUsers);
        manageControlledDocumentSharing(combinedSharingUsers);
    }

    public static void manageControlledDocumentSharing(List<Supplementary_Access_User__c> sharingUsers){
        Set<Id> controlledDocumentsToUpdateAccess = new Set<Id>();

        for(Supplementary_Access_User__c sharingUser : sharingUsers){
            controlledDocumentsToUpdateAccess.add(sharingUser.Controlled_Document__c);
        }

        manageControlledDocumentSharing(controlledDocumentsToUpdateAccess);
    }

    public static void manageControlledDocumentSharing(Set<Id> controlledDocumentIds){
        List<Supplementary_Access_User__c> relevantSupplementaryAccessUsers = getRelevantSupplementaryAccessUsers(controlledDocumentIds);
        Map<Id, Set<Id>> controlledDocumentIdToUsersWithAccess = createControlledDocumentUserAccessMap(controlledDocumentIds, relevantSupplementaryAccessUsers);
        Map<Id, List<Controlled_Document__Share>> existingControlledDocumentSharingEntityMap = createExistingControlledDocumentSharingEntityMap(controlledDocumentIds);
        
        List<Controlled_Document__Share> newShares = new List<Controlled_Document__Share>();
        List<controlled_Document__Share> sharesToDelete = new List<Controlled_Document__Share>();
        //case# 21548-BEGIN
        Set<Id> controlledDocIds = new Set<Id>();
        Map<Id, Set<Id>> controlledDocUserMap = new Map<Id, Set<Id>>();
        //case#21548-END
        for(Id controlledDocumentId : controlledDocumentIds){
            //case#21548-BEGIN
            controlledDocUserMap.put(controlledDocumentId, new Set<Id>());
            //case#21548-END
            for(Controlled_Document__Share sharingEntity : existingControlledDocumentSharingEntityMap.get(controlledDocumentId)){
                
                if(!controlledDocumentIdToUsersWithAccess.get(controlledDocumentId).remove(sharingEntity.UserOrGroupId)){ //remove() returns true if the set was modified
                    sharesToDelete.add(sharingEntity); //If the user was not in the set, then their access should be revoked
                    //case#21548-BEGIN
                    controlledDocIds.add(controlledDocumentId);
                    controlledDocUserMap.get(controlledDocumentId).add(sharingEntity.UserOrGroupId);
                    //case#21548-END
                }
            }
        }
        //case#21548 -BEGIN
        if(!sharesToDelete.isEmpty()) {
            Set<Id> contentDocumentIds = new Set<Id>();
            Map<Id, Id> contentDocToControlledDocMap = new Map<Id, Id>();
            List<ContentDocumentLink> cdlsNotRequired = new List<ContentDocumentLink>();
            for(ContentDocumentLink cdl : [SELECT Id, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId IN :controlledDocIds]) {
                contentDocumentIds.add(cdl.ContentDocumentId);
                contentDocToControlledDocMap.put(cdl.ContentDocumentId, cdl.LinkedEntityId);
            }
            Map<Id, ContentDocument> contentDocumentMap = getContentDocumentMap(contentDocumentIds);
            for(Id contentDoc : contentDocumentIds) {
                ContentDocument cDocument = (contentDocumentMap.containsKey(contentDoc)) ? contentDocumentMap.get(contentDoc) : new ContentDocument();                
                List<ContentDocumentLink> contentDocumentLinkList = (cDocument != null) ? cDocument.ContentDocumentLinks : new List<ContentDocumentLink>();
                Id controlledDocId = contentDocToControlledDocMap.get(contentDoc);                                
                for(ContentDocumentLink cdl : contentDocumentLinkList) {
                    for(Id linkedUser : controlledDocUserMap.get(controlledDocId)) {
                        if(cdl.LinkedEntityId == linkedUser && cdl.ContentDocumentId == contentDoc)
                            cdlsNotRequired.add(cdl);                   
                    }
                }
            }
            delete cdlsNotRequired; 
        }
        //case#21548 -END
        
        for(Id controlledDocumentId : controlledDocumentIds){
            for(Id userId : controlledDocumentIdToUsersWithAccess.get(controlledDocumentId)){
                newShares.add(createCorrespondenceShare(controlledDocumentId, userId)); //Any users that remain in the set do not already have sharing entities created
            }
        }

        delete sharesToDelete;
        insert newShares;
    }

    private static Map<Id, List<Controlled_Document__Share>> createExistingControlledDocumentSharingEntityMap(Set<Id> controlledDocumentIds){
        Map<Id, List<Controlled_Document__Share>> controlledDocumentIdToExistingSharingEntities = new Map<Id, List<Controlled_Document__Share>>();

        for(Id controlledDocId : controlledDocumentIds){
            controlledDocumentIdToExistingSharingEntities.put(controlledDocId, new List<Controlled_Document__Share>());
        }

        for(Controlled_Document__Share sharingRecord : getControlledDocumentShares(controlledDocumentIds)){
            controlledDocumentIdToExistingSharingEntities.get(sharingRecord.ParentId).add(sharingRecord);
        }

        return controlledDocumentIdToExistingSharingEntities;
    }

    private static Map<Id, Set<Id>> createControlledDocumentUserAccessMap(Set<Id> controlledDocumentIds, List<Supplementary_Access_User__c> relevantSupplementaryAccessUsers){
        Map<Id, Set<Id>> controlledDocumentIdToUsersWithAccess = new Map<Id, Set<Id>>();

        for(Id controlledDocId : controlledDocumentIds){
            controlledDocumentIdToUsersWithAccess.put(controlledDocId, new Set<Id>());
        }

        for(Approval_Step__c approvalStep : getRelevantApprovalSteps(controlledDocumentIds)){
            if(!approvalStep.Assigned_Approver__r.isActive) continue;
            controlledDocumentIdToUsersWithAccess.get(approvalStep.Correspondence_Document__c).add(approvalStep.Assigned_Approver__c);
        }

        for(Supplementary_Access_User__c sharingUser : relevantSupplementaryAccessUsers){
            controlledDocumentIdToUsersWithAccess.get(sharingUser.Controlled_Document__c).add(sharingUser.User__c);
        }

        return controlledDocumentIdToUsersWithAccess;
    }

    private static Controlled_Document__Share createCorrespondenceShare(Id controlledDocumentId, Id userId){
        return new Controlled_Document__Share(AccessLevel = 'Edit', RowCause= Schema.Controlled_Document__Share.RowCause.Apex_Managed_Sharing__c,
                                              ParentId = controlledDocumentId,
                                              UserOrGroupId = userId);
    }

    private static List<Approval_Step__c> getRelevantApprovalSteps(Set<Id> controlledDocumentIds){
        return [SELECT Id, Assigned_Approver__c, Assigned_Approver__r.isActive, Assigned_Approver__r.DelegatedApproverId, Correspondence_Document__c
                  FROM Approval_Step__c
                 WHERE Correspondence_Document__c IN :controlledDocumentIds AND
                       Assigned_Approver__c != null 
                       // case# 21548-added below condition
                       AND Marked_for_Deletion__c = false];
    }

    private static List<Supplementary_Access_User__c> getRelevantSupplementaryAccessUsers(Set<Id> controlledDocumentIds){
        return [SELECT User__c, Controlled_Document__c
                  FROM Supplementary_Access_User__c
                 WHERE Controlled_Document__c IN: controlledDocumentIds AND
                       Active__c = true AND
                       User__c != null
        		//Prevent inactive Users and try to share the record with active users only (SFEEO-2027)
                AND User__r.isActive=true];
    }

    private static List<Controlled_Document__Share> getControlledDocumentShares(Set<Id> controlledDocumentIds){
        return [SELECT Id, ParentId, UserOrGroupId
                  FROM Controlled_Document__Share
                 WHERE ParentId IN :controlledDocumentIds AND
                       RowCause = :Schema.Controlled_Document__Share.RowCause.Apex_Managed_Sharing__c];
    }
    
    //case# 21548 - BEGIN
    private static Map<Id, ContentDocument> getContentDocumentMap(Set<Id> contentDocumentIds){

        return new Map<Id, ContentDocument>([
                    SELECT Id, 
                      (
                        SELECT Id, LinkedEntityId, ContentDocumentId 
                        FROM ContentDocumentLinks 
                        WHERE ShareType = 'C'
                      ) 
                    FROM ContentDocument 
                    WHERE Id IN :contentDocumentIds
                  ]);
    }
    //case# 21548 - END
}