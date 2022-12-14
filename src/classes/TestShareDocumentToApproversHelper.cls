
@isTest
private class TestShareDocumentToApproversHelper {
    
    private static Id testControlDocId;
   

    private static void loadTestData() {
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
        
        //Get Owner ID from existing users
        
        List<User> u = [Select u.UserType, u.Name, u.UserRoleId, u.ProfileID 
                    From User u 
                    where u.UserType = 'Standard' and isActive = true
                    and u.profileID in (select id from profile where name = 'System Administrator')
                    limit 1 ];
        
        //Get User ID from existing users for Apex Managed Sharing access
        
        List<User> u1 = [Select u.UserType, u.Name, u.UserRoleId, u.ProfileID 
                    From User u 
                    where u.UserType = 'Standard' and isActive = true
                    limit 1 ];
        
        // Insert Controlled Document
        Controlled_Document__c testControlledDoc = new Controlled_Document__c();
        testControlledDoc.Assignee__c = u1[0].id;
        testControlledDoc.Internal_External__c ='Internal';
        testControlledDoc.GSA_Action_Required__c='Other';
        testControlledDoc.ExecSec_Start_Date__c = system.Today();
        testControlledDoc.ExecSec_Due_Date__c = system.Today() + 5;
       // testControlledDoc.Date_Closed__c = system.Today() + 5;
        //testControlledDoc.Requested_Due_Date_External_Delivery_1__c=system.Today() + 5;
        testControlledDoc.ExecSec_End_Date__c = system.Today() + 5;
        testControlledDoc.Due_Date_for_Signature__c = system.Today() +5;
        testControlledDoc.Title__c = 'Test Controlled Doc' + system.Today();
        testControlledDoc.Correspondence_Type__c = 'Annual Report';
        testControlledDoc.Originating_Office__c = 'A - Office of the Administrator';
        testControlledDoc.OwnerId = u[0].id;
        testControlledDoc.Stage__c = 'Initiated';

        try
        {
            insert testControlledDoc;
            testControlDocId = testControlledDoc.id;
        }
        catch (DMLException dmle)
        {
            System.debug('\n\n>> TestShareDocumentToApproversHelper() - Unable to insert test Controlled Document.\nDMLException encountered - ' + dmle);
            System.assert(false);
        }
        
        // Insert 2nd Controlled Document
        Controlled_Document__c testControlledDoc1 = new Controlled_Document__c();
        testControlledDoc1.Assignee__c = u1[0].id;
        testControlledDoc1.ExecSec_Start_Date__c = system.Today() - 7;
        testControlledDoc1.ExecSec_Due_Date__c = system.Today() - 5;
        testControlledDoc1.ExecSec_End_Date__c = null;
        testControlledDoc1.Date_Closed__c = null;
        testControlledDoc1.Due_Date_for_Signature__c = system.Today() +5;
        testControlledDoc1.Title__c = 'Test Controlled Doc 1' + system.Today();
        testControlledDoc1.Correspondence_Type__c = 'Annual Report';
        testControlledDoc1.Originating_Office__c = 'A - Office of the Administrator';
        testControlledDoc1.OwnerId = u[0].id;
        testControlledDoc1.Stage__c = 'Initiated';
        testControlledDoc1.Due_Date__c = system.Today() - 5;

        try
        {
            insert testControlledDoc1;
        }
        catch (DMLException dmle)
        {
            System.debug('\n\n>> TestShareDocumentToApproversHelper() - Unable to insert test Controlled Document.\nDMLException encountered - ' + dmle);
            System.assert(false);
        }
        
        // Insert 3rd Controlled Document
        Controlled_Document__c testControlledDoc2 = new Controlled_Document__c();
        testControlledDoc2.Assignee__c = u1[0].id;
        testControlledDoc2.ExecSec_Start_Date__c = system.Today() - 7;
        testControlledDoc2.ExecSec_Due_Date__c = system.Today() - 5;
        testControlledDoc2.ExecSec_End_Date__c = system.Today();
        testControlledDoc2.Date_Closed__c = system.Today();
        testControlledDoc2.Due_Date_for_Signature__c = system.Today() +5;
        testControlledDoc2.Title__c = 'Test Controlled Doc 1' + system.Today();
        testControlledDoc2.Correspondence_Type__c = 'Annual Report';
        testControlledDoc2.Originating_Office__c = 'A - Office of the Administrator';
        testControlledDoc2.OwnerId = u[0].id;
        testControlledDoc2.Stage__c = 'Closed';
        testControlledDoc2.Due_Date__c = system.Today() - 5;

        try
        {
            insert testControlledDoc2;
        }
        catch (DMLException dmle)
        {
            System.debug('\n\n>> TestShareDocumentToApproversHelper() - Unable to insert test Controlled Document.\nDMLException encountered - ' + dmle);
            System.assert(false);
        }
        
      
        
        // Insert Approval Step
        
        List<Approval_Step__c> listApprovalStep = new List<Approval_Step__c>();
        
        Approval_Step__c testAppStep = new Approval_Step__c();
        testAppStep.Sequence__c = '1';
        testAppStep.Start_Date__c = system.Today();
        testAppStep.Due_Date__c = system.Today() + 5;
        testAppStep.Approval_Status__c = 'Not Initiated';
        testAppStep.Approval_Step_Type__c = 'Individual Approver';
        testAppStep.Assigned_Approver__c = u1[0].id;
        testAppStep.Correspondence_Document__c = testControlDocId;
        listApprovalStep.add(testAppStep);
        
        Approval_Step__c testAppStep1 = new Approval_Step__c();
        testAppStep1.Sequence__c = '2';
        testAppStep1.Start_Date__c = system.Today()+5;
        testAppStep1.Due_Date__c = system.Today() + 10;
        testAppStep1.Completed_Date__c = system.Today() + 10;
        testAppStep1.Approval_Status__c = 'Initiated';
        testAppStep1.Approval_Step_Type__c = 'Individual Approver';
        testAppStep1.Assigned_Approver__c = u1[0].id;
        testAppStep1.Correspondence_Document__c = testControlDocId;
        listApprovalStep.add(testAppStep1);
        System.debug('List of App Steps>>>>>>>>' + listApprovalStep);

        try
        {
           if (listApprovalStep.size() >0) {
            insert listApprovalStep;
           }
        }
        catch (DMLException dmle)
        {
            System.debug('\n\n>> TestShareDocumentToApproversHelper() - Unable to insert test Approval Step.\nDMLException encountered - ' + dmle);
            //System.assert(false);
        }

       
    }

    static testMethod void testInsertAppStep(){
        
   
        Test.startTest();

        loadTestData();

        Test.stopTest();
        
        List<Approval_Step__c> lstApps = [select a.id from Approval_Step__c a where Correspondence_Document__c = :testControlDocId];
        
        system.assertEquals(true, lstApps.size() >0);
    }
    
    static testMethod void testDeleteAppStep(){

        loadTestData();
        
        List<Approval_Step__c> listAppStepToDelete = [select a.id from Approval_Step__c a where Correspondence_Document__c = :testControlDocId];

        Test.startTest();
        
        delete listAppStepToDelete;

        Test.stopTest();
        
         List<Approval_Step__c> lstApps = [select a.id from Approval_Step__c a where Correspondence_Document__c = :testControlDocId];
        
        system.assertEquals(true, lstApps.size() == 0);
    }
    
    static testMethod void testUpdateAppStep(){
 
        loadTestData();
        
        List<User> u2 = [Select u.UserType, u.Name, u.UserRoleId, u.ProfileID 
                        From User u 
                        where u.UserType = 'Standard' and isActive = true
                        limit 2 ];
        
        Approval_Step__c testAppStep0 = new Approval_Step__c();
        testAppStep0.Sequence__c = '1';
        testAppStep0.Start_Date__c = system.Today();
        testAppStep0.Due_Date__c = system.Today() + 5;
        testAppStep0.Completed_Date__c = null;
        testAppStep0.Approval_Status__c = 'Initiated';
        testAppStep0.Approval_Step_Type__c = 'Individual Approver';
        testAppStep0.Assigned_Approver__c = u2[0].id;
        testAppStep0.Correspondence_Document__c = testControlDocId;
        insert testAppStep0;
        
        Test.startTest();
         
        testAppStep0.Assigned_Approver__c = u2[1].id;
        update testAppStep0;
          

        Test.stopTest();
        
        List<Approval_Step__c> lstApps = [select a.id from Approval_Step__c a where Correspondence_Document__c = :testControlDocId];
        
        system.assertEquals(true, lstApps.size() >0);
    }
    
    static testMethod void testUpdateDeactivationAppStep(){
 
        loadTestData();
        
        List<User> u2 = [Select u.UserType, u.Name, u.UserRoleId, u.ProfileID 
                        From User u 
                        where u.UserType = 'Standard' and isActive = true
                        limit 2 ];
        
        Approval_Step__c testAppStep0 = new Approval_Step__c();
        testAppStep0.Sequence__c = '1';
        testAppStep0.Start_Date__c = system.Today();
        testAppStep0.Due_Date__c = system.Today() + 5;
        testAppStep0.Completed_Date__c = null;
        testAppStep0.Approval_Status__c = 'Initiated';
        testAppStep0.Approval_Step_Type__c = 'Individual Approver';
        testAppStep0.Assigned_Approver__c = u2[0].id;
        testAppStep0.Correspondence_Document__c = testControlDocId;
        insert testAppStep0;
        
        Test.startTest();
         
        testAppStep0.Marked_for_Deletion__c = true;
        update testAppStep0;
          

        Test.stopTest();
        
        List<Approval_Step__c> lstApps = [select a.id from Approval_Step__c a where Marked_for_Deletion__c = true];
        
        system.assertEquals(1, lstApps.size());
    }
}