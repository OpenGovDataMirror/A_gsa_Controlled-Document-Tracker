@isTest
private class CDTPreventAttachmentDeleteHelperTest {   
   
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
		
		PermissionSet nonexecSecPerm = [SELECT Id FROM PermissionSet WHERE PermissionSet.Name = 'Controlled_Document_Tracker_OAS_User_CRE'];
		insert new PermissionSetAssignment(AssigneeId = testUser1Standard.id, PermissionSetId = nonexecSecPerm.Id);
		insert new PermissionSetAssignment(AssigneeId = testUser2Standard.id, PermissionSetId = nonexecSecPerm.Id);
	}
   
    static testmethod void deleteattachment(){
       	Set<Id> userIds = new Set<Id>();
        for(PermissionSetAssignment pa : [SELECT Id, AssigneeId FROM PermissionSetAssignment WHERE 
                                          PermissionSet.Name = 'Controlled_Document_Tracker_OAS_Admin_User_CRED' LIMIT 200]) {
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
        controlDoc.Reason_File_Deletion__c = 'Deletiong for Testing';
		insert controlDoc;
       	
		insert ControlledDocumentTestUtility.createApprovalStep(controlDoc.id, '1', testUser2.Id);
        ControlledDocumentTestUtility.insertCollaborationTriggerControl(true);
					
       	ContentVersion testContentInsert =new ContentVersion(); 
        testContentInsert.ContentURL='http://www.google.com/';  
        testContentInsert.Title ='Google.com'; 
        insert testContentInsert; 
        
        ContentVersion testContent = [SELECT ContentDocumentId FROM ContentVersion where Id = :testContentInsert.Id];
        
        ContentDocument contentDoc = [select id from contentDocument where id=:testContent.ContentDocumentId];
        ContentDocumentLink contentlink=new ContentDocumentLink();
            contentlink.LinkedEntityId=controlDoc.id;
            contentlink.contentdocumentid=contentDoc.Id;
            contentlink.ShareType = 'V';
        insert contentlink;
        
        Test.startTest(); 
            try{
                delete contentDoc;
             	Controlled_Document__c Cd = [Select ID,Reason_File_Deletion__c from Controlled_Document__c where id = :controlDoc.id]; 
                System.assertEquals(null, cd.Reason_File_Deletion__c);
               }
            catch(DMLException e){ 
                Boolean expectedExceptionThrown =  e.getMessage().contains('reason') ? true : false;
				System.assertEquals(true, expectedExceptionThrown); 
                System.assertEquals('FIELD_CUSTOM_VALIDATION_EXCEPTION', e.getDmlStatusCode(0));                
            }	
        Test.stopTest(); 
        }
    }
    
    static testmethod void deleteattachmentError(){
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
					
       	ContentVersion testContentInsert =new ContentVersion(); 
        testContentInsert.ContentURL='http://www.google.com/';  
        testContentInsert.Title ='Google.com'; 
        insert testContentInsert; 
        
        ContentVersion testContent = [SELECT ContentDocumentId FROM ContentVersion where Id = :testContentInsert.Id];
        
        ContentDocument contentDoc = [select id from contentDocument where id=:testContent.ContentDocumentId];
        ContentDocumentLink contentlink=new ContentDocumentLink();
            contentlink.LinkedEntityId=controlDoc.id;
            contentlink.contentdocumentid=contentDoc.Id;
            contentlink.ShareType = 'V';
        insert contentlink;
        
        Test.startTest(); 
            try{
                delete contentDoc;
             	//Controlled_Document__c Cd = [Select ID,Reason_File_Deletion__c from Controlled_Document__c where id = :controlDoc.id]; 
                //System.assertEquals(null, cd.Reason_File_Deletion__c);
               }
            catch(DMLException e){ 
                Boolean expectedExceptionThrown =  e.getMessage().contains('delet') ? true : false;
				System.assertEquals(true, expectedExceptionThrown); 
                System.assertEquals('FIELD_CUSTOM_VALIDATION_EXCEPTION', e.getDmlStatusCode(0));                
            }	
        Test.stopTest(); 
        }
    }
    
    static testmethod void deleteContentDocAsExecSecUser(){
       	Set<Id> userIds = new Set<Id>();
        for(PermissionSetAssignment pa : [SELECT Id, AssigneeId FROM PermissionSetAssignment WHERE 
                                          PermissionSet.Name Like 'Controlled_Document_Tracker_OAS_User_CRE' LIMIT 200]) {
                                              userIds.add(pa.AssigneeId);
                                          }
        Map<Id, User> usersMap = new Map<Id, User>([SELECT Id FROM User WHERE Id IN :userIds 
                                                    AND IsActive=true AND UserType='Standard' LIMIT 5]);  
        List<User> users = usersMap.values();        
		FeedItem post;
		//List<User> exsitingStandardUsers = ControlledDocumentTestUtility.getStandardUsers(2);
		User testUser1 = users.get(0);
		User testUser2 = users.get(1);
        /*
        List<Group> grpList = [SELECT Id FROM Group WHERE Group.DeveloperName IN ('CDT_OAS_Admin_User')];
        List<GroupMember> gmList = new List<GroupMember>();
        for(User u : users) {
            GroupMember gm = new GroupMember(GroupId=grpList[0].Id, UserOrGroupId=u.Id);
            gmList.add(gm);
        }
        insert gmList;
		*/
		system.runAs(testUser1){
		Controlled_Document__c controlDoc = ControlledDocumentTestUtility.createTestControlDoc();
        controlDoc.Reason_File_Deletion__c = 'Deletiong for Testing';
		insert controlDoc;
       	
		insert ControlledDocumentTestUtility.createApprovalStep(controlDoc.id, '1', testUser2.Id);
        ControlledDocumentTestUtility.insertCollaborationTriggerControl(true);
					
       	ContentVersion testContentInsert =new ContentVersion(); 
        testContentInsert.ContentURL='http://www.google.com/';  
        testContentInsert.Title ='Google.com'; 
        insert testContentInsert; 
        Test.setCreatedDate(testContentInsert.Id, DateTime.now()-1);
        
        ContentVersion testContent = [SELECT Id, CreatedDate, ContentDocumentId FROM ContentVersion where Id = :testContentInsert.Id];
        ContentDocument contentDoc = [select id from contentDocument where id=:testContent.ContentDocumentId];
        ContentDocumentLink contentlink=new ContentDocumentLink();
            contentlink.LinkedEntityId=controlDoc.id;
            contentlink.contentdocumentid=contentDoc.Id;
            contentlink.ShareType = 'V';
        insert contentlink;
        
        Test.startTest(); 
            try{
                delete contentDoc;
             	//Controlled_Document__c Cd = [Select ID,Reason_File_Deletion__c from Controlled_Document__c where id = :controlDoc.id]; 
                //System.assertEquals(null, cd.Reason_File_Deletion__c);
               }
            catch(DMLException e){ 
                Boolean expectedExceptionThrown =  e.getMessage().contains('reason') ? true : false;
				System.assertEquals(true, expectedExceptionThrown); 
                System.assertEquals('FIELD_CUSTOM_VALIDATION_EXCEPTION', e.getDmlStatusCode(0));                
            }	
        Test.stopTest(); 
        }
    }
    
    static testmethod void deleteContentDocAsExecSecAdmin(){
       	Set<Id> userIds = new Set<Id>();
        for(PermissionSetAssignment pa : [SELECT Id, AssigneeId FROM PermissionSetAssignment WHERE 
                                          PermissionSet.Name Like 'Controlled_Document_Tracker_OAS_Admin_User_CRED' LIMIT 200]) {
                                              userIds.add(pa.AssigneeId);
                                          }
        Map<Id, User> usersMap = new Map<Id, User>([SELECT Id FROM User WHERE Id IN :userIds 
                                                    AND IsActive=true AND UserType='Standard' LIMIT 5]);  
        List<User> users = usersMap.values();        
		FeedItem post;
		//List<User> exsitingStandardUsers = ControlledDocumentTestUtility.getStandardUsers(2);
		User testUser1 = users.get(0);
		User testUser2 = users.get(1);
		system.debug('testUser1########################################'+testUser1);
        
        List<Group> grpList = [SELECT Id FROM Group WHERE Group.DeveloperName IN ('CDT_OAS_Admin_User')];
        List<GroupMember> gmList = new List<GroupMember>();
        for(User u : users) {
            GroupMember gm = new GroupMember(GroupId=grpList[0].Id, UserOrGroupId=u.Id);
            gmList.add(gm);
        }
        insert gmList;
		
		system.runAs(testUser1){
		Controlled_Document__c controlDoc = ControlledDocumentTestUtility.createTestControlDoc();
        controlDoc.Reason_File_Deletion__c = 'Deletiong for Testing';
		insert controlDoc;
       	
		insert ControlledDocumentTestUtility.createApprovalStep(controlDoc.id, '1', testUser2.Id);
        ControlledDocumentTestUtility.insertCollaborationTriggerControl(true);
					
       	ContentVersion testContentInsert =new ContentVersion(); 
        testContentInsert.ContentURL='http://www.google.com/';  
        testContentInsert.Title ='Google.com'; 
        insert testContentInsert; 
        Test.setCreatedDate(testContentInsert.Id, DateTime.now()-1);
        
        ContentVersion testContent = [SELECT Id, CreatedDate, ContentDocumentId FROM ContentVersion where Id = :testContentInsert.Id];
        ContentDocument contentDoc = [select id from contentDocument where id=:testContent.ContentDocumentId];
        ContentDocumentLink contentlink=new ContentDocumentLink();
            contentlink.LinkedEntityId=controlDoc.id;
            contentlink.contentdocumentid=contentDoc.Id;
            contentlink.ShareType = 'V';
        insert contentlink;
        
        Test.startTest(); 
            try{
                delete contentDoc;
             	//Controlled_Document__c Cd = [Select ID,Reason_File_Deletion__c from Controlled_Document__c where id = :controlDoc.id]; 
                //System.assertEquals(null, cd.Reason_File_Deletion__c);
               }
            catch(DMLException e){ 
                Boolean expectedExceptionThrown =  e.getMessage().contains('reason') ? true : false;
				System.assertEquals(true, expectedExceptionThrown); 
                System.assertEquals('FIELD_CUSTOM_VALIDATION_EXCEPTION', e.getDmlStatusCode(0));
            }	
        Test.stopTest(); 
        }
    }
    
    static testmethod void deleteFeedAsExecSecUser(){
        Set<Id> userIds = new Set<Id>();
        for(PermissionSetAssignment pa : [SELECT Id, AssigneeId FROM PermissionSetAssignment WHERE 
                                          PermissionSet.Name Like 'Controlled_Document%' LIMIT 200]) {
                                              userIds.add(pa.AssigneeId);
                                          }
        Map<Id, User> usersMap = new Map<Id, User>([SELECT Id FROM User WHERE Id IN :userIds 
                                                    AND IsActive=true AND UserType='Standard' LIMIT 5]);  
        List<User> users = usersMap.values();        
		//FeedItem post;
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
            //post = ControlledDocumentTestUtility.createFeedItem(controlDoc.id);
            //insert post;
            FeedItem post = new FeedItem();
            ContentVersion testContentInsert =new ContentVersion(); 
            testContentInsert.ContentURL='http://www.google.com/';  
            testContentInsert.Title ='Google.com'; 
            insert testContentInsert; 
            Test.setCreatedDate(testContentInsert.Id, DateTime.now()-1);
            
            post.Type = 'ContentPost';
            post.ParentId = controlDoc.id; // Opportunity
            post.RelatedRecordId = testContentInsert.id;
            //contentFI.title = 'Content Post';
            post.Body = 'Body of content post';
            insert post;
            
            List<FeedItem> feedItemExt = [SELECT Id, RelatedRecordId FROM FeedItem WHERE Id = :post.Id];
        	List<ContentVersion> cvrExt = [SELECT Id, CreatedDate, ContentDocumentId FROM ContentVersion 
                                           WHERE Id = :feedItemExt.get(0).RelatedRecordId];
        	Test.setCreatedDate(cvrExt[0].Id, DateTime.now()-1);
            Test.startTest();
            try{
                delete post;
            }
            catch(DMLException e){
                Boolean expectedExceptionThrown =  e.getMessage().contains('reason') ? true : false;
                //System.AssertEquals(true, expectedExceptionThrown);  
                System.assertEquals('FIELD_CUSTOM_VALIDATION_EXCEPTION', e.getDmlStatusCode(0));
            }
            Test.stopTest();
        }
    }
    
    static testmethod void deleteFeedAsExecSecUserWithReason(){
        Set<Id> userIds = new Set<Id>();
        for(PermissionSetAssignment pa : [SELECT Id, AssigneeId FROM PermissionSetAssignment WHERE 
                                          PermissionSet.Name Like 'Controlled_Document%' LIMIT 200]) {
                                              userIds.add(pa.AssigneeId);
                                          }
        Map<Id, User> usersMap = new Map<Id, User>([SELECT Id FROM User WHERE Id IN :userIds 
                                                    AND IsActive=true AND UserType='Standard' LIMIT 5]);  
        List<User> users = usersMap.values();        
		//FeedItem post;
		//List<User> exsitingStandardUsers = ControlledDocumentTestUtility.getStandardUsers(2);
		User testUser1 = users.get(0);
		User testUser2 = users.get(1);
		system.runAs(testUser1){
            Controlled_Document__c controlDoc = ControlledDocumentTestUtility.createTestControlDoc();
            controlDoc.Reason_File_Deletion__c = 'Deletiong for Testing';
            insert controlDoc;            
            insert ControlledDocumentTestUtility.createApprovalStep(controlDoc.id, '1', testUser2.Id);
            ControlledDocumentTestUtility.insertCollaborationTriggerControl(true);
            //Create a contentpost
            //post = ControlledDocumentTestUtility.createFeedItem(controlDoc.id);
            //insert post;
            FeedItem post = new FeedItem();
            ContentVersion testContentInsert =new ContentVersion(); 
            testContentInsert.ContentURL='http://www.google.com/';  
            testContentInsert.Title ='Google.com'; 
            insert testContentInsert; 
            Test.setCreatedDate(testContentInsert.Id, DateTime.now()-1);
            
            post.Type = 'ContentPost';
            post.ParentId = controlDoc.id; // Opportunity
            post.RelatedRecordId = testContentInsert.id;
            //contentFI.title = 'Content Post';
            post.Body = 'Body of content post';
            insert post;
            
            List<FeedItem> feedItemExt = [SELECT Id, RelatedRecordId FROM FeedItem WHERE Id = :post.Id];
        	List<ContentVersion> cvrExt = [SELECT Id, CreatedDate, ContentDocumentId FROM ContentVersion 
                                           WHERE Id = :feedItemExt.get(0).RelatedRecordId];
        	Test.setCreatedDate(cvrExt[0].Id, DateTime.now()-1);
            Test.startTest();
            try{
                delete post;
            }
            catch(DMLException e){
                Boolean expectedExceptionThrown =  e.getMessage().contains('reason') ? true : false;
                System.AssertEquals(true, expectedExceptionThrown);  
                System.assertEquals('FIELD_CUSTOM_VALIDATION_EXCEPTION', e.getDmlStatusCode(0));
            }
            Test.stopTest();
        }
    }

    static testmethod void deleteFeedAsExecSecAdmin(){
        Set<Id> userIds = new Set<Id>();
        for(PermissionSetAssignment pa : [SELECT Id, AssigneeId FROM PermissionSetAssignment WHERE 
                                          PermissionSet.Name Like 'Controlled_Document_Tracker_OAS_Admin_User_CRED' LIMIT 200]) {
                                              userIds.add(pa.AssigneeId);
                                          }
        Map<Id, User> usersMap = new Map<Id, User>([SELECT Id FROM User WHERE Id IN :userIds 
                                                    AND IsActive=true AND UserType='Standard' LIMIT 5]);  
        List<User> users = usersMap.values();        
		//FeedItem post;
		//List<User> exsitingStandardUsers = ControlledDocumentTestUtility.getStandardUsers(2);
		User testUser1 = users.get(0);
		User testUser2 = users.get(1);
        List<Group> grpList = [SELECT Id FROM Group WHERE Group.DeveloperName IN ('CDT_OAS_Admin_User')];
        List<GroupMember> gmList = new List<GroupMember>();
        for(User u : users) {
            GroupMember gm = new GroupMember(GroupId=grpList[0].Id, UserOrGroupId=u.Id);
            gmList.add(gm);
        }
        insert gmList;
		system.runAs(testUser1){
            Controlled_Document__c controlDoc = ControlledDocumentTestUtility.createTestControlDoc();
            controlDoc.Reason_File_Deletion__c = 'Deletiong for Testing';
            insert controlDoc;            
            insert ControlledDocumentTestUtility.createApprovalStep(controlDoc.id, '1', testUser2.Id);
            ControlledDocumentTestUtility.insertCollaborationTriggerControl(true);
            //Create a contentpost
            //post = ControlledDocumentTestUtility.createFeedItem(controlDoc.id);
            //insert post;
            FeedItem post = new FeedItem();
            ContentVersion testContentInsert =new ContentVersion(); 
            testContentInsert.ContentURL='http://www.google.com/';  
            testContentInsert.Title ='Google.com'; 
            insert testContentInsert; 
            Test.setCreatedDate(testContentInsert.Id, DateTime.now()-1);
            
            post.Type = 'ContentPost';
            post.ParentId = controlDoc.id; // Opportunity
            post.RelatedRecordId = testContentInsert.id;
            //contentFI.title = 'Content Post';
            post.Body = 'Body of content post';
            insert post;
            
            List<FeedItem> feedItemExt = [SELECT Id, RelatedRecordId FROM FeedItem WHERE Id = :post.Id];
        	List<ContentVersion> cvrExt = [SELECT Id, CreatedDate, ContentDocumentId FROM ContentVersion 
                                           WHERE Id = :feedItemExt.get(0).RelatedRecordId];
        	Test.setCreatedDate(cvrExt[0].Id, DateTime.now()-1);
            Test.startTest();
            try{
                delete post;
            }
            catch(DMLException e){
                Boolean expectedExceptionThrown =  e.getMessage().contains('reason') ? true : false;
                System.AssertEquals(true, expectedExceptionThrown);  
                System.assertEquals('FIELD_CUSTOM_VALIDATION_EXCEPTION', e.getDmlStatusCode(0));
            }
            Test.stopTest();
        }
    }
}