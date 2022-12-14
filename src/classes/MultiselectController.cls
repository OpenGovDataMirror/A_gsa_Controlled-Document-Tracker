/*
* MultiselectController synchronizes the values of the hidden elements to the
* SelectOption lists.
*/
public with sharing class MultiselectController {
    // SelectOption lists for public consumption
    public List<SelectOption> leftPicklist { get; set; }
    public List<SelectOption> rightPicklist { get; set; }
    public String label {get; set;}
    public List<SelectOption> searchCriteria {get; private set;}
    public String searchObject {get; set;}
    public String searchString {get; set;}
    public Controlled_Document__c thisControlledDocument {get; set;}
    public Id originatingUser {get; set;}
    public String baseUrl {get; set;}
    public boolean notCollaborator {get; set;}
    public boolean sendEmailNotification {get; set;}
    public Set<Id> currentSharedUsers {get; private set;}
    Set<String> publicGroups = new Set<String>();
    
    public boolean isExecSecOrOwner = false;
    //Map to store custom metadata values
    Map<String, String> groupMap = new Map<String, String>();    
    CDT_Public_Groups__mdt[] chatterMappings = [SELECT Chatter_Mention__c ,Public_Group__c FROM CDT_Public_Groups__mdt where id <> null];
    
    // Backing for hidden text field containing the options from the
    // left list
    public String leftOptionsHidden { get; set {
        leftOptionsHidden = value;
        setOptions(leftPicklist, value);
    }
                                    }
    
    // Backing for hidden text field containing the options from the
    // right list
    public String rightOptionsHidden { get; set {
        rightOptionsHidden = value;
        setOptions(rightPicklist, value);
    }
                                     }
    
    private Set<Id> existingSelectedUsers {get; private set;}
    private Map<Id, SelectOption> originalSelectedUsers {get; private set;}
    
    public MultiselectController(){
        thisControlledDocument = [SELECT Id, Name, OwnerId FROM Controlled_Document__c WHERE Id = :ApexPages.currentPage().getParameters().get('id')];
        originatingUser = UserInfo.getUserId();
        checkForSpecialPrivs();
        baseUrl = URL.getSalesforceBaseUrl().toExternalForm();
        
        rightPicklist = new List<SelectOption>();
        searchCriteria = new List<SelectOption>();
        searchCriteria.add(new SelectOption('Users', 'Users'));
        searchCriteria.add(new SelectOption('Common Users', 'Common Users'));
        searchCriteria.add(new SelectOption('Public Groups', 'Public Groups'));
        
        for (CDT_Public_Groups__mdt chatterMapping : chatterMappings) {
            groupMap.put(chatterMapping.Chatter_Mention__c, chatterMapping.Public_Group__c);
        }
        
        findSelectedUsers();
        findUsers();
        
        // occassionally someone will add a collaborator that doesn't have collaborator access
        // this will break when these individuals try to remove quick shares
        // removing a quick share should remove collaborator access and only collaborators can do this
        notCollaborator = ControlledDocumentAccessDeterminer.checkCollaboratorStatus(thisControlledDocument.Id);
        
        sendEmailNotification = false;
    }
    
    public MultiselectController(ApexPages.StandardController controller) {
        thisControlledDocument = [SELECT Id, Name, OwnerId FROM Controlled_Document__c WHERE Id = :ApexPages.currentPage().getParameters().get('id')];
        originatingUser = UserInfo.getUserId();
        checkForSpecialPrivs();
        baseUrl = URL.getSalesforceBaseUrl().toExternalForm();
        
        rightPicklist = new List<SelectOption>();
        searchCriteria = new List<SelectOption>();
        searchCriteria.add(new SelectOption('Users', 'Users'));
        searchCriteria.add(new SelectOption('Common Users', 'Common Users'));
        searchCriteria.add(new SelectOption('Public Groups', 'Public Groups'));
        
        for (CDT_Public_Groups__mdt chatterMapping : chatterMappings) {
            groupMap.put(chatterMapping.Chatter_Mention__c, chatterMapping.Public_Group__c);
        }
        
        findSelectedUsers();
        findUsers(); 
        // occassionally someone will add a collaborator that doesn't have collaborator access
        // this will break when these individuals try to remove quick shares
        // removing a quick share should remove collaborator access and only collaborators can do this
        notCollaborator = ControlledDocumentAccessDeterminer.checkCollaboratorStatus(thisControlledDocument.Id);
        
        sendEmailNotification = false;
        currentSharedUsers = new Set<Id>();
        for (SelectOption o : rightPicklist){
            currentSharedUsers.add(o.getValue());
        }
    }
    
    public void checkForSpecialPrivs(){
        
        if(originatingUser == thisControlledDocument.OwnerId){
            isExecSecOrOwner = true;
        } else {
            List<PermissionSet> execSecPermissionSet = [
                SELECT Id 
                FROM PermissionSet
                WHERE Name = 'Controlled_Document_Tracker_OAS_Admin_User_CRED'
            ];
            
            List<PermissionSetAssignment> psetAssign = [
                SELECT Id
                FROM PermissionSetAssignment
                WHERE AssigneeId = :originatingUser
                AND PermissionSetId = :execSecPermissionSet[0].Id
            ];
            
            if(!psetAssign.isEmpty()) isExecSecOrOwner = true;
        }
        
    }
    
    public void refreshAvailableUserList(){
        if (searchObject == 'Users'){
            findUsers();
        } else if (searchObject == 'Common Users'){
            findCommonUsers();
        } else if (searchObject == 'Public Groups'){
            findPublicGroups();
        }
    }
    
    public PageReference saveChanges(){
        
        Map<Id, SelectOption> selectedUsersMap = new Map<Id, SelectOption>();
        //Set<Id> userIds = new Set<Id>();
        Map<Id,String> userIdToGroup = new Map<Id, String>();
        Set<Id> groupIds = new Set<Id>();
        
        //Check the select option  for user or group
        for (SelectOption selectedOption : rightPicklist){
            Id selectedId = (Id)selectedOption.getValue();
            if(selectedId.getSObjectType().getDescribe().getName() == 'User'){
                userIdToGroup.put(selectedId, null);
                //userIds.add(selectedId); 
            }else if(selectedId.getSObjectType().getDescribe().getName() == 'Group'){
                groupIds.add(selectedId);
            }
        }
        try{
            //System.debug('***GroupInfo ' + [Select Id, UserOrGroupId,GroupId,Group.type From GroupMember Where GroupId in :groupIds]);
            if(groupIds.size() > 0){
                for(GroupMember member : [Select Id, UserOrGroupId,GroupId,Group.type From GroupMember Where GroupId in :groupIds]){
                    Id memberRecordId = member.UserOrGroupId;
                    if(memberRecordId.getSobjectType().getDescribe().getName() == 'User'){
                        userIdToGroup.put(memberRecordId, member.GroupId); 
                    }   
                }
            }    
        }catch(Exception e){
            system.debug('***Exception Occured ' + e.getMessage());
        }
        
        
        
        if(!userIdToGroup.keySet().isEmpty()) {
            SupplementaryAccessUserGranterQuickShare.addShareForQuickShareUser(thisControlledDocument.Id, originatingUser, userIdToGroup, isExecSecOrOwner);			
        }
        
        // an empty set here is perfectly fine
        SupplementaryAccessUserGranterQuickShare.disableShareForQuickShareUser(thisControlledDocument.Id, originatingUser, userIdToGroup.keySet(), isExecSecOrOwner);
        
        Set<Id> idsToEmail = new Set<Id>(userIdToGroup.keySet());
        idsToEmail.removeAll(currentSharedUsers);
        
        if(sendEmailNotification && !idsToEmail.isEmpty()){
            ControlledDocumentEmailNotification.sendEmailNotificationToUsers(thisControlledDocument, idsToEmail);
        }
        
        PageReference redirectPage = new PageReference(baseUrl + '/' + thisControlledDocument.Id);
        redirectPage.setRedirect(true);
        return redirectPage;
    }
    // case# 31205 - BEGIN
    public Set<Id> validCDTUsers(Set<Id> findIds) {
        Set<Id> userIds = new Set<Id>();
        if(findIds != null && (!findIds.isEmpty())) {
            for(PermissionSetAssignment passign: [SELECT AssigneeId, PermissionSetId FROM PermissionSetAssignment WHERE
                                                  PermissionSet.Name LIKE 'Controlled_Document%' AND AssigneeId IN :findIds LIMIT 200]) {
                                                      if(!userIds.contains(passign.AssigneeId))
                                                          userIds.add(passign.AssigneeId);
                                                  }
        } 
        if(findIds == null) {
            for(PermissionSetAssignment passign: [SELECT AssigneeId, PermissionSetId FROM PermissionSetAssignment WHERE
                                                  PermissionSet.Name LIKE 'Controlled_Document%' LIMIT 200]) {
                                                      if(!userIds.contains(passign.AssigneeId))
                                                          userIds.add(passign.AssigneeId);
                                                  }
        }
        return ((!userIds.isEmpty()) ? userIds : null);
    }    
    // case# 31205 - END
    public void findUsers(){
        leftPicklist = new List<SelectOption>();
        // case# 31205 - BEGIN
        Set<Id> validuserIds = new Set<Id>();
        validuserIds = validCDTUsers(null);
        Map<Id, User> usersmatchMap = new Map<Id, User>();
        // case# 31205 - END
        List<User> allUsers;
        if (String.isBlank(searchString) && validuserIds != null){
            allUsers = [
                SELECT Id, FirstName, LastName, Name, Username
                FROM User
                WHERE UserType = 'Standard' 
                // case# 31205 - BEGIN
                AND Id IN :validuserIds
                // case# 31205 - END
                AND IsActive = true
                ORDER BY FirstName ASC NULLS LAST, LastName ASC NULLS LAST, Name ASC NULLS LAST
                LIMIT 100
            ];
        } else {
            String likeString = '%' + searchString + '%';
            // case# 31202 - BEGIN
            for(User u : [SELECT Id, FirstName, LastName, Name, Username FROM User
                          WHERE UserType = 'Standard' AND IsActive = true
                          AND (FirstName LIKE :likeString OR LastName LIKE :likeString OR Name LIKE :likeString)                        
                          ORDER BY FirstName ASC NULLS LAST, LastName ASC NULLS LAST, Name ASC NULLS LAST
                          LIMIT 100
                         ]) {
                             usersmatchMap.put(u.Id, u);   
                         }
            validUserIds = validCDTUsers(usersmatchMap.keySet());
            allUsers = new List<User>();
            if(validuserIds != null && !validUserIds.isEmpty()) {
                for(Id uId : validUserIds) {
                    if(usersmatchMap.containsKey(uId)) {
                        allUsers.add(usersmatchMap.get(uId));
                    }
                }
            }
            // case# 31205 - END            
            /* commented for case# 31205 -BEGIN
allUsers = [
SELECT Id, FirstName, LastName, Name, Username
FROM User
WHERE UserType = 'Standard'
AND IsActive = true
AND (FirstName LIKE :likeString 
OR LastName LIKE :likeString
OR Name LIKE :likeString)
ORDER BY FirstName ASC NULLS LAST, LastName ASC NULLS LAST, Name ASC NULLS LAST
LIMIT 100
];
commented for case# 31205 - END  */
            
        }
        
        getSelectedUserIds();
        
        // check for similar names list
        Map<String, Integer> nameToOccurrences = new Map<String, Integer>();
        for (User user : allUsers){
            if (!existingSelectedUsers.contains(user.Id)){
                
                String key = user.FirstName + ' ' + user.LastName;
                if(nameToOccurrences.containsKey(key)){
                    Integer tempInt = nameToOccurrences.get(key) + 1;
                    nameToOccurrences.put(key, tempInt);
                } else {
                    nameToOccurrences.put(key, 1);
                }
                
                System.debug('SUP DAWG (non common LEFT)' + nameToOccurrences);
                
            }
        }
        // actually populate list
        for (User user : allUsers){
            if (!existingSelectedUsers.contains(user.Id)){
                
                String key = user.FirstName + ' ' + user.LastName;
                if(nameToOccurrences.get(key) > 1){
                    leftPicklist.add(new SelectOption(user.Id, user.FirstName 
                                                      + ' ' + user.LastName
                                                      + ' (' + user.Username + ')'));
                } else {
                    leftPicklist.add(new SelectOption(user.Id, user.FirstName 
                                                      + ' ' + user.LastName));
                }
                
            }
        }
    }
    
    public void findCommonUsers(){
        List<Supplementary_Access_User__c> selectedUsers = [
            SELECT Id, User__c, User__r.FirstName, User__r.LastName, User__r.Name, User__r.Username
            FROM Supplementary_Access_User__c
            WHERE Active__c = true 
            AND Origin__c = 'Quick Share'
            AND Controlled_Document__c = :thisControlledDocument.Id
            AND Originating_User__c = :originatingUser
        ];
        
        Set<Id> existingSupplementUsers = new Set<Id>();
        for(Supplementary_Access_User__c supplement : selectedUsers){
            existingSupplementUsers.add(supplement.User__c);
        }
        
        leftPicklist = new List<SelectOption>();
        
        List<Common_Supplementary_User__c> commonUsers;
        if (String.isBlank(searchString)){
            commonUsers = [
                SELECT Id, Group_Member__c, Group_Member__r.FirstName, Group_Member__r.LastName, Group_Member__r.Name, Group_Member__r.Username, Frequency__c
                FROM Common_Supplementary_User__c
                WHERE CreatedById = :originatingUser
                AND Group_Member__c NOT IN :existingSupplementUsers
                ORDER BY Frequency__c DESC NULLS LAST, Group_Member__r.FirstName ASC NULLS LAST, Group_Member__r.LastName ASC NULLS LAST, Group_Member__r.Name ASC NULLS LAST
                LIMIT 100
            ];
        } else {
            String likeString = '%' + searchString + '%';
            commonUsers = [
                SELECT Id, Group_Member__c, Group_Member__r.FirstName, Group_Member__r.LastName, Group_Member__r.Name, Group_Member__r.Username, Frequency__c
                FROM Common_Supplementary_User__c
                WHERE CreatedById = :originatingUser
                AND Group_Member__c NOT IN :existingSupplementUsers
                AND (Group_Member__r.FirstName LIKE :likeString 
                     OR Group_Member__r.LastName LIKE :likeString
                     OR Group_Member__r.Name LIKE :likeString)               
                ORDER BY Frequency__c DESC NULLS LAST, Group_Member__r.FirstName ASC NULLS LAST, Group_Member__r.LastName ASC NULLS LAST, Group_Member__r.Name ASC NULLS LAST
                LIMIT 100
            ];
        }
        
        getSelectedUserIds();
        // check for similar names list
        Map<String, Integer> nameToOccurrences = new Map<String, Integer>();
        for (Common_Supplementary_User__c commonSupplement : commonUsers){
            if (!existingSelectedUsers.contains(commonSupplement.Group_Member__c)){
                
                String key = commonSupplement.Group_Member__r.FirstName + ' ' + commonSupplement.Group_Member__r.LastName;
                if(nameToOccurrences.containsKey(key)){
                    Integer tempInt = nameToOccurrences.get(key) + 1;
                    nameToOccurrences.put(key, tempInt);
                } else {
                    nameToOccurrences.put(key, 1);
                }
                
                System.debug('SUP DAWG' + nameToOccurrences);
                
            }
        }
        // actually populate list
        for (Common_Supplementary_User__c commonSupplement : commonUsers){
            if (!existingSelectedUsers.contains(commonSupplement.Group_Member__c)){
                
                String key = commonSupplement.Group_Member__r.FirstName + ' ' + commonSupplement.Group_Member__r.LastName;
                if(nameToOccurrences.get(key) > 1){
                    leftPicklist.add(new SelectOption(commonSupplement.Group_Member__c, commonSupplement.Group_Member__r.FirstName 
                                                      + ' ' + commonSupplement.Group_Member__r.LastName 
                                                      + ' (' + commonSupplement.Group_Member__r.Username + ')'));
                } else {
                    leftPicklist.add(new SelectOption(commonSupplement.Group_Member__c, commonSupplement.Group_Member__r.FirstName 
                                                      + ' ' + commonSupplement.Group_Member__r.LastName));
                }
                
            }
        }
    }
    
    public void findSelectedUsers(){
        List<Supplementary_Access_User__c> selectedUsers = new List<Supplementary_Access_User__c>();
        if(isExecSecOrOwner) {
            System.debug('AAAAAA');
            selectedUsers = [
                SELECT Id, User__c, Group__c, User__r.FirstName, User__r.LastName, User__r.Username
                FROM Supplementary_Access_User__c
                WHERE Active__c = true 
                AND Origin__c = 'Quick Share'
                AND Controlled_Document__c = :thisControlledDocument.Id
                ORDER BY User__r.FirstName ASC NULLS LAST, User__r.LastName ASC NULLS LAST, User__r.Name ASC NULLS LAST
            ];
        } else {
            System.debug('12312412414');
            selectedUsers = [
                SELECT Id, User__c,Group__c, User__r.FirstName, User__r.LastName, User__r.Username
                FROM Supplementary_Access_User__c
                WHERE Active__c = true 
                AND Origin__c = 'Quick Share'
                AND Controlled_Document__c = :thisControlledDocument.Id
                AND Originating_User__c = :originatingUser
                ORDER BY User__r.FirstName ASC NULLS LAST, User__r.LastName ASC NULLS LAST, User__r.Name ASC NULLS LAST
            ];
        }
        //get group names
        Map<Id,Group> groupNames = new Map<Id,Group>([SELECT Id, Name, developerName FROM Group WHERE developerName IN :groupMap.values()]);
        
        // check for similar names list
        Map<String, Integer> nameToOccurrences = new Map<String, Integer>();
        Map<Id,Boolean> nameToOccurrencesGroup = new Map<Id,Boolean>();
        //Set<Id> group
        for (Supplementary_Access_User__c supplement : selectedUsers){
            if(supplement.Group__c == null){
                String key = supplement.User__r.FirstName + ' ' + supplement.User__r.LastName;
                if(nameToOccurrences.containsKey(key)){
                    Integer tempInt = nameToOccurrences.get(key) + 1;
                    nameToOccurrences.put(key, tempInt);
                } else {
                    nameToOccurrences.put(key, 1);
                }
            }else{
                if(!nameToOccurrencesGroup.containsKey((Id)supplement.Group__c)){
                    nameToOccurrencesGroup.put((Id)supplement.Group__c, true);
                }
            }
            //String keyGroup = groupNames.get(supplement.Group__c).Name;
            
            
        }
        //Map<Id,Boolean> groupExistsMap = new Map<Id,Boolean>();
        // actually populate list
        for (Supplementary_Access_User__c supplement : selectedUsers){
            if(supplement.Group__c == null){
                
                String key = supplement.User__r.FirstName + ' ' + supplement.User__r.LastName;
                if(nameToOccurrences.get(key) > 1){
                    rightPicklist.add(new SelectOption(supplement.User__c, supplement.User__r.FirstName
                                                       + ' ' + supplement.User__r.LastName
                                                       + ' (' + supplement.User__r.Username + ')'));
                } else {
                    rightPicklist.add(new SelectOption(supplement.User__c, supplement.User__r.FirstName
                                                       + ' ' + supplement.User__r.LastName));
                }
           }
            
       }
        System.debug('nameToOccurrencesGroup --> '+ nameToOccurrencesGroup);
        if( nameToOccurrencesGroup.keySet().size() > 0){
            for(ID grpId : nameToOccurrencesGroup.keySet()){
               // System.debug('groupNames.get(grpId).Name -->' + groupNames.get(grpId).Name );
            rightPicklist.add(new SelectOption(grpId, groupNames.get(grpId).Name ));
        }
        }
            }
    
    public void getSelectedUserIds(){
        existingSelectedUsers = new Set<Id>();
        
        for (SelectOption o : rightPicklist){
            existingSelectedUsers.add(o.getValue());
        }
    }
    
    public void findPublicGroups(){
        leftPicklist = new List<SelectOption>();
        
        List<Group> allGroups = [
            SELECT RelatedId,Type, DeveloperName, Id, Name FROM Group
            WHERE DeveloperName IN :groupMap.Values()
        ];
        
        getSelectedUserIds();
        for(Group g : allgroups){
          	if (!existingSelectedUsers.contains(g.Id)){
            	leftPicklist.add(new SelectOption(g.Id, g.Name));
            	publicGroups.add(g.Id);
            }
        }
    }
    
    
    
    // Parse &-separated values and labels from value and 
    // put them in option
    public void setOptions(SelectOption[] options, String value) {
        options.clear();
        String[] parts = value.split('&');
        for (Integer i=0; i<parts.size()/2; i++) {
            options.add(new SelectOption(EncodingUtil.urlDecode(parts[i*2], 'UTF-8'), 
                                         EncodingUtil.urlDecode(parts[(i*2)+1], 'UTF-8')));
        }
    }
    Public PageReference Cancel(){
        
        PageReference pageRef = new PageReference( '/' + thisControlledDocument.Id);
        pageRef.setRedirect(true);
        return pageRef;
    }
    
    
    
}