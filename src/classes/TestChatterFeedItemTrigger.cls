
@isTest 
private class TestChatterFeedItemTrigger {
	
	@testSetup
	static void testDataSetup(){
		Id userProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard Platform User'].Id;
		List<User> exsitingStandardUsers = new List<User>();
        for(Integer i = 1; i < 6; i++) {
            exsitingStandardUsers.add(TestUtil.buildUser(i, userProfileId, 'testCon' + i + '@fake.com'));
        }
		insert exsitingStandardUsers;
		
		system.debug('#############################################################################');
		List<User> existingStandardUsers = ControlledDocumentTestUtility.getStandardUsers(2);
		
		User testUser1Standard = existingStandardUsers.get(0);		
		User testUser2Standard = existingStandardUsers.get(1);
		List<User> existingStandardUsersWithDelegateInsert = new List<User>();
		for(Integer i = 1; i < 4; i++) {
            existingStandardUsersWithDelegateInsert.add(TestUtil.buildUserWithDelegate(i, userProfileId, 'testDelegate' + i + '@fake.com', testUser1Standard.id));
        }
		insert existingStandardUsersWithDelegateInsert;
		
		List<User> existingStandardUsersWithDelegate = ControlledDocumentTestUtility.getStandardUsersWithDelegatedApprovers(2);
		User testUser1 = existingStandardUsersWithDelegate.get(0);
		User testUser2 = existingStandardUsersWithDelegate.get(1);
		
		PermissionSet execSecPerm = [SELECT Id FROM PermissionSet WHERE PermissionSet.Name = 'Controlled_Document_Tracker_OAS_Admin_User_CRED'];
		insert new PermissionSetAssignment(AssigneeId = testUser1.id, PermissionSetId = execSecPerm.Id);
		insert new PermissionSetAssignment(AssigneeId = testUser2.id, PermissionSetId = execSecPerm.Id);
		
		PermissionSet nonexecSecPerm = [SELECT Id FROM PermissionSet WHERE PermissionSet.Name = 'Controlled_Document_Tracker_User_CRE'];
		insert new PermissionSetAssignment(AssigneeId = testUser1Standard.id, PermissionSetId = nonexecSecPerm.Id);
		insert new PermissionSetAssignment(AssigneeId = testUser2Standard.id, PermissionSetId = nonexecSecPerm.Id);
	}
    
    /*
    @IsTest
    static void testCIAtMentionSharing() {
        // Build a simple feed item
        Map<Id, Group> grpMap = new Map<Id, Group>([Select Id from Group Where DeveloperName Like 'Critical_Items%']);
        List<GroupMember> grpuserslist = new List<GroupMember>();
        List<Critical_Issues__c> citemsList = new List<Critical_Issues__c>();
        Map<Id, Id> grpuserMap = new Map<Id, Id>();
        grpuserslist = [SELECT UserorGroupId, GroupId FROM GroupMember WHERE GroupId IN :grpMap.keySet()];
        
        for(GroupMember g : grpuserslist) {
            grpuserMap.put(g.UserorGroupId, g.GroupId);
        }
        
        List<User> users = [SELECT Id FROM User WHERE IsActive = true AND Id != :UserInfo.getUserId()
                    AND ProfileId IN (SELECT Id FROM Profile WHERE Name = 'GSA Standard Platform User') AND Id NOT IN :grpuserMap.keySet() LIMIT 2]; 
        
        for (Integer i=0;i<2;i++) {
            citemsList.add(new Critical_Issues__c(Organization__c = 'OCIO', 
                                        Related_Organization__c='Region 1', 
                                        Critical_Item_Status__c='New', User__c=users[0].Id,
                                        Action_Required_by_Administrator__c='Info Only/No Action Needed',
                                        Date_Updated__c=Date.today(),
                                        Additional_Comments2__c='Test1',
                                        Action_Type_Detail__c='Budget',
                                        Deadline__c=Date.today()+1,
                                        Recommended_Action__c='need to discuss',
                                        IQ_Number__c='123',
                                        Status_Update__c='Test1', Name='Test'+i));
        }
        insert citemsList;
        
        ConnectApi.MessageBodyInput messageInput = new ConnectApi.MessageBodyInput();
        messageInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();
        
        ConnectApi.TextSegmentInput textSegment = new ConnectApi.TextSegmentInput();
        textSegment.text = 'Hey there ';
        messageInput.messageSegments.add(textSegment);
        
        ConnectApi.MentionSegmentInput mentionSegment = new ConnectApi.MentionSegmentInput();
        mentionSegment.Id = users[1].Id;
        messageInput.messageSegments.add(mentionSegment);
        
        ConnectApi.FeedItemInput input = new ConnectApi.FeedItemInput();
        input.body = messageInput;
        
        ConnectApi.FeedItem feedItemReply = ConnectApi.ChatterFeeds.postFeedItem(null, 
                                                ConnectApi.FeedType.Record, citemsList[0].Id, input, null);
        
        List<Critical_Issues__Share> pocupdshares = [SELECT Id FROM Critical_Issues__Share WHERE 
                                                        ParentId = :citemsList[0].Id AND UserOrGroupId = :users[1].Id 
                                                        AND RowCause = 'Chatter__c'];
        // test to ensure that one sharing entry is inserted.
        Test.startTest();
        System.assertEquals(1, pocupdshares.size());
        Test.stopTest();
    }
    // EBC case# 26931 - v1.2 - BEGIN
    @isTest static void validateEBCFilePrevention() {
        List<User> stdUsers = [SELECT Id FROM User WHERE IsActive = true and UserType='Standard' LIMIT 2];
        // prepare the EBC record for insert
        Executive_Business_Case__c ebc = new Executive_Business_Case__c();
        ebc.Name = 'PRJ TSTZSDGF 123456';
        ebc.Project_Start_Date__c = System.today();
        ebc.Portfolio__c = 'FAS';
        ebc.Request_Type__c = 'New Investment';
        ebc.Requested_Amount_1st_Fiscal_Year__c = 0.00;
        ebc.Requested_Amount_2nd_Fiscal_Year__c = 0.00;
        ebc.Requested_Amount_3rd_Fiscal_Year__c = 0.00;
        ebc.Requested_Amount_4th_Fiscal_Year__c = 0.00;
        ebc.Requested_Amount_5th_Fiscal_Year__c = 0.00;
        ebc.Service_or_Staff_Office_SSO__c = 'A - Office of the Administrator';
        ebc.Executive_Sponsor_Delegate__c = stdUsers[0].Id;
        ebc.Abstract__c = 'TestRecord...';
        ebc.Fiscal_Year__c = '2019';
        ebc.Project_End_Date__c = System.today();
        ebc.Program_Business_Line__c = 'A - Office of the Administrator';
        // insert new EBC record
        insert ebc;
        // prepare the chatter feed with .txt attachment
        // prepare the message body input
        ConnectApi.MessageBodyInput messageInput = new ConnectApi.MessageBodyInput();
        messageInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();
        // prepare the text segment input
        ConnectApi.TextSegmentInput textSegment = new ConnectApi.TextSegmentInput();
        textSegment.text = 'Hey there ';
        messageInput.messageSegments.add(textSegment);
        // prepare the mentionsegment input
        ConnectApi.MentionSegmentInput mentionSegment = new ConnectApi.MentionSegmentInput();
        mentionSegment.Id = stdUsers[1].Id;
        messageInput.messageSegments.add(mentionSegment);
        
        // prepare the message input
        ConnectApi.NewFileAttachmentInput newattachinput = new ConnectApi.NewFileAttachmentInput();
        newattachinput.title='My Title';
        newattachinput.description='sample file';
        ConnectApi.FeedItemInput input = new ConnectApi.FeedItemInput();
        input.body = messageInput;
        input.attachment = newattachinput;
        
        // prepare the attachment input
        String text = 'These are the contents of the new file.';
        Blob myBlob = Blob.valueOf(text);
        ConnectApi.BinaryInput binInput = new ConnectApi.BinaryInput(myBlob, 'text/plain', 'My Title');
        // insert the feed with attachment
        try {
            ConnectApi.FeedItem feedItemReply = ConnectApi.ChatterFeeds.postFeedItem(null, 
                                                ConnectApi.FeedType.Record, ebc.Id, input, binInput);
        }
        catch(ConnectApi.ConnectApiException e) {
            System.assertEquals('You must attach the files of following types word, excel and pdf', e.getMessage());
        }
    }
    */
    // EBC case# 26931 - v1.2 - END
    // CDT case#27693
    static testmethod void cdt_preventdelete(){
        Set<Id> userIds = new Set<Id>();
        for(PermissionSetAssignment pa : [SELECT Id, AssigneeId FROM PermissionSetAssignment WHERE 
                                          PermissionSet.Name Like 'Controlled_Document%' LIMIT 200]) {
                                              userIds.add(pa.AssigneeId);
                                          }
        Map<Id, User> usersMap = new Map<Id, User>([SELECT Id FROM User WHERE Id IN :userIds 
                                                    AND IsActive=true AND UserType='Standard' LIMIT 5]);  
        List<User> users = usersMap.values();        
		FeedItem post;
		//List<User> exsitingStandardUsers = ControlledDocumentTestUtility.getStandardUsers(2);
		User testUser1 = users.get(0);
		User testUser2 = users.get(1);
		system.runAs(testUser1){
            Controlled_Document__c controlDoc = ControlledDocumentTestUtility.createTestControlDoc();
            //controlDoc.Reason_File_Deletion__c = 'Deletiong for Testing';
            insert controlDoc;            
            insert ControlledDocumentTestUtility.createApprovalStep(controlDoc.id, '1', testUser2.Id);
            ControlledDocumentTestUtility.insertCollaborationTriggerControl(true);
            //Create a contentpost
            post = ControlledDocumentTestUtility.createFeedItem(controlDoc.id);
            insert post;
            Test.startTest();
            try{
                delete post;
            }
            catch(DMLException e){
                Boolean expectedExceptionThrown =  e.getMessage().contains('delet') ? true : false;
                System.AssertEquals(true, expectedExceptionThrown);  
                System.assertEquals('FIELD_CUSTOM_VALIDATION_EXCEPTION', e.getDmlStatusCode(0));
            }
            Test.stopTest();
        }
    }
    // CDT Case# 31205 - BEGIN
    @isTest static void testFeedDelete() {
        Set<Id> userIds = new Set<Id>();
        for(PermissionSetAssignment pa : [SELECT Id, AssigneeId FROM PermissionSetAssignment WHERE 
                                          PermissionSet.Name Like 'Controlled_Document%' LIMIT 200]) {
                                              userIds.add(pa.AssigneeId);
                                          }
        Map<Id, User> usersMap = new Map<Id, User>([SELECT Id FROM User WHERE Id IN :userIds 
                                                    AND IsActive=true AND UserType='Standard' LIMIT 5]);  
        List<User> users = usersMap.values();
        Controlled_Document__c controlDoc = ControlledDocumentTestUtility.createTestControlDoc();
        controlDoc.Reason_File_Deletion__c = 'testing';
        insert controlDoc;
        Approval_Step__c step = ControlledDocumentTestUtility.createApprovalStep(controlDoc.id, '1', users[0].Id);
        insert step;
        FeedItem post = ControlledDocumentTestUtility.createFeedItem(controlDoc.id);
        insert post; 
        List<FeedItem> feedItemExt = [SELECT Id, RelatedRecordId FROM FeedItem WHERE Id = :post.Id];
        List<ContentVersion> cvrExt = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :feedItemExt.get(0).RelatedRecordId];
        Set<Id> cdocIds = new Set<Id>();
        for(ContentVersion cvr: cvrExt) {
            cdocIds.add(cvr.ContentDocumentId);
        }
        List<ContentDocumentLink> cdlExt = [SELECT Id, LinkedEntityId, ShareType FROM ContentDocumentLink 
                                            WHERE ContentDocumentId IN :cdocIds];
		System.assertEquals(1, feedItemExt.size());
		System.assertEquals(1, cvrExt.size());
		System.assertEquals(true, cdlExt.size()>0);        
		//ContentVersion contentVer = ControlledDocumentTestUtility.getContentVersion(post.RelatedRecordId);
		//List<ContentDocumentLink> existingLinks = ControlledDocumentTestUtility.getLinkForUserDocument(UserInfo.getUserId(), contentVer.ContentDocumentId);
        Test.startTest();
        delete post;
        Test.stopTest();
        Integer count=0;
        for(ContentDocumentLink cdl: [SELECT Id, LinkedEntityId, ShareType FROM ContentDocumentLink 
                                      WHERE ContentDocumentId IN :cdocIds]) {
                                          if(cdl.ShareType == 'C') {
                                          	count = count + 1;    
                                          }    
                                      }                                  
        System.assertEquals(0, count);
    }
    // CDT Case# 31205 - END 
    //ticket# RITM0589850 - BEGIN
    // Removed as part of SFEEO 1961
    /*
    @isTest static void testFeedMentionPost() {
        Set<Id> userIds = new Set<Id>();
        for(PermissionSetAssignment pa : [SELECT Id, AssigneeId FROM PermissionSetAssignment WHERE 
                                          PermissionSet.Name ='Controlled_Document_Tracker_User_CRE' 
                                          AND Assignee.IsActive=true LIMIT 200]) {
                                              userIds.add(pa.AssigneeId);
                                          }
        Map<Id, User> usersMap = new Map<Id, User>([SELECT Id FROM User WHERE Id IN :userIds 
                                                    AND IsActive=true AND UserType='Standard' LIMIT 5]);  
        List<User> users = usersMap.values();
        Id grpId = [SELECT Id, DeveloperName FROM Group WHERE DeveloperName='Controlled_Document_Tracker_OGC_POCs'].Id;
        Set<Id> gmUserIds = new Set<Id>();
        List<GroupMember> gmList = new List<GroupMember>([SELECT Id, UserorGroupId, GroupId FROM GroupMember WHERE GroupId =:grpId]);
        if(!gmList.isEmpty()) { 
            for(GroupMember gm: gmList) {	
                gmUserIds.add(gm.UserOrGroupId);	
            }
        }
        List<CollaborationGroup> cgList = new List<CollaborationGroup>();
        cgList = [SELECT Id, Name FROM CollaborationGroup WHERE Name IN ('CDT-L')];        
        if(cgList.isEmpty()) {
            cgList.add(new CollaborationGroup(Name = 'CDT-L', CollaborationType='Public', OwnerId = UserInfo.getUserId()));
        	insert cgList;
        }
        CollaborationGroup newcg = [SELECT Id FROM CollaborationGroup WHERE Name='CDT-L' LIMIT 1];
        List<CollaborationGroupMember> cgmList = new List<CollaborationGroupMember>();
        List<CollaborationGroupMember> newMembers = new List<CollaborationGroupMember>();
        Set<Id> memberIdSet = new Set<Id>();
        cgmList = [SELECT Id, MemberId FROM CollaborationGroupMember WHERE CollaborationGroupId = :newcg.Id AND Member.IsActive = true
                  AND MemberId != :UserInfo.getUserId()];
        if(!cgmList.isEmpty()) {
            for(CollaborationGroupMember cgm : cgmList) {
                memberIdSet.add(cgm.MemberId);
            }
        } else {
            for(Id usrId : gmuserIds) {
                newMembers.add(new CollaborationGroupMember(MemberId=usrId, CollaborationGroupId=newcg.Id));    
            }            
            insert newMembers;
        }
        // to resolve the mixed DML in test class execution for group members
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        // create the controlled document record
        Controlled_Document__c controlDoc = ControlledDocumentTestUtility.createTestControlDoc();
        //controlDoc.OwnerId = users[0].Id;
        insert controlDoc;
        Approval_Step__c step = ControlledDocumentTestUtility.createApprovalStep(controlDoc.id, '1', users[0].Id);
        insert step;
        FeedItem post = ControlledDocumentTestUtility.createFeedItem(controlDoc.id);
        insert post; 
        
        // prepare the message body input
        ConnectApi.MessageBodyInput messageInput = new ConnectApi.MessageBodyInput();
        messageInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();
        // prepare the text segment input
        ConnectApi.TextSegmentInput textSegment = new ConnectApi.TextSegmentInput();
        textSegment.text = 'Hey there ';
        messageInput.messageSegments.add(textSegment);
        // prepare the mentionsegment input
        ConnectApi.MentionSegmentInput mentionSegment = new ConnectApi.MentionSegmentInput();
        mentionSegment.Id = cgList[0].Id;
        messageInput.messageSegments.add(mentionSegment);
        ConnectApi.FeedItemInput input = new ConnectApi.FeedItemInput();
        input.body = messageInput;        
        Test.startTest();
        ConnectApi.FeedItem feedItemReply = ConnectApi.ChatterFeeds.postFeedItem(null, 
                                                ConnectApi.FeedType.Record, controlDoc.id, input, null);
        Test.stopTest();
        
        System.debug('controlDocId == ' + controlDoc.Id);
        //List<FeedItem> feedItemExt = [SELECT Id, RelatedRecordId FROM FeedItem WHERE Id = :post.Id];
        List<Controlled_Document__Share> cdShares = [SELECT Id FROM Controlled_Document__Share WHERE 
                                                        ParentId = :controlDoc.Id AND UserOrGroupId IN :gmUserIds 
                                                        AND RowCause = 'Apex_Managed_Sharing__c'];    
    	System.assertEquals(gmUserIds.size(), cdShares.size());            
    }
    
    @isTest static void testFeedMentionPostWithoutChatterGrp() {
        Set<Id> userIds = new Set<Id>();
        for(PermissionSetAssignment pa : [SELECT Id, AssigneeId FROM PermissionSetAssignment WHERE 
                                          PermissionSet.Name ='Controlled_Document_Tracker_User_CRE' 
                                          AND Assignee.IsActive=true LIMIT 200]) {
                                              userIds.add(pa.AssigneeId);
                                          }
        Map<Id, User> usersMap = new Map<Id, User>([SELECT Id FROM User WHERE Id IN :userIds 
                                                    AND IsActive=true AND UserType='Standard' LIMIT 5]);  
        List<User> users = usersMap.values();
         
        // to resolve the mixed DML in test class execution for group members
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        // create the controlled document record
        Controlled_Document__c controlDoc = ControlledDocumentTestUtility.createTestControlDoc();
        //controlDoc.OwnerId = users[0].Id;
        insert controlDoc;
        Approval_Step__c step = ControlledDocumentTestUtility.createApprovalStep(controlDoc.id, '1', users[0].Id);
        insert step;
        FeedItem post = ControlledDocumentTestUtility.createFeedItem(controlDoc.id);
        insert post; 
        
        // prepare the message body input
        ConnectApi.MessageBodyInput messageInput = new ConnectApi.MessageBodyInput();
        messageInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();
        // prepare the text segment input
        ConnectApi.TextSegmentInput textSegment = new ConnectApi.TextSegmentInput();
        textSegment.text = 'Hey there ';
        messageInput.messageSegments.add(textSegment);
        // prepare the mentionsegment input
        ConnectApi.MentionSegmentInput mentionSegment = new ConnectApi.MentionSegmentInput();
        mentionSegment.Id = users[0].Id;
        messageInput.messageSegments.add(mentionSegment);
        ConnectApi.FeedItemInput input = new ConnectApi.FeedItemInput();
        input.body = messageInput;        
        Test.startTest();
        ConnectApi.FeedItem feedItemReply = ConnectApi.ChatterFeeds.postFeedItem(null, 
                                                ConnectApi.FeedType.Record, controlDoc.id, input, null);
        Test.stopTest();
        //List<FeedItem> feedItemExt = [SELECT Id, RelatedRecordId FROM FeedItem WHERE Id = :post.Id];
        List<Controlled_Document__Share> cdShares = [SELECT Id FROM Controlled_Document__Share WHERE 
                                                        ParentId = :controlDoc.Id AND UserOrGroupId = :users[0].Id 
                                                        AND RowCause = 'Apex_Managed_Sharing__c'];    
    	System.assertEquals(1, cdShares.size());            
    }
	*/    
    //ticket# RITM0589850 - END   
}