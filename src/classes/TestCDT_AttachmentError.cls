@isTest
Public Class TestCDT_AttachmentError{
	
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
		
		CDT_GSA_Administrator__c cm = new CDT_GSA_Administrator__c();
	    cm.Name='Agency Administrator';
	    cm.FullName__c='Timothy Horne';
	    insert cm; 
		
		User u = new User(FirstName = 'Timothy',
                             LastName = 'Horne',
                             ProfileId = userProfileId,
                             Affiliation__c = 'Contractor');

        u.Email = u.FirstName + '@test.com';
        u.Username = u.FirstName + '@gsa.gov.thisisatest';
        u.CommunityNickname = u.FirstName + u.LastName + 'gsagovtest';
        u.TimeZoneSidKey = 'America/New_York';
        u.LocaleSidKey = 'en_US';
        u.EmailEncodingKey = 'ISO-8859-1';
        u.LanguageLocaleKey='en_US';
        u.Alias = u.FirstName;
		u.isActive=true;
		insert u;
	}
	
    Static testmethod void AttachmentError(){
    
    Controlled_Document__c cdt = new Controlled_Document__c();
    
    cdt.Stage__c='Drafting';
    cdt.Correspondence_Type__c='Forms';
    cdt.Originating_Office__c='AK - Office of Civil Rights';
    insert cdt;
    
    Attachment attach=new Attachment();         
    attach.Name='Unit Test Attachment';
    Blob bodyBlob=Blob.valueOf('Unit Test Attachment Body');
    attach.body=bodyBlob;
    attach.parentId=cdt.id;
    try{
    insert attach;
    }
    catch(exception e){
   
System.Assert(e.getMessage().contains('To upload new files:  Attach in Chatter feed.'));
    }
   }
   
   // Case# 27460 - BEGIN - for test coverage of ControlledDocumenttrigger
   static testmethod void testInsertValidation() {
       User agencyAdmin = [SELECT Id from User Where Name = 'Timothy Horne' AND isActive= true LIMIT 1];
       Controlled_Document__c cdt = new Controlled_Document__c();
       cdt.Stage__c='Drafting';
       cdt.GSA_Action_Required__c = 'Signature/Approval of the Administrator';
       cdt.Final_Signatory__c = agencyAdmin.Id;
       cdt.Correspondence_Type__c='Forms';
       cdt.Originating_Office__c='AK - Office of Civil Rights';
       try {
           insert cdt;
       }
       catch(DMLException e) {
           System.assertEquals('FIELD_CUSTOM_VALIDATION_EXCEPTION', e.getDmlStatusCode(0));
       }        
   }
   static testmethod void testUpdateValidation1() {
             
       User agencyAdmin = [SELECT Id from User Where Name = 'Timothy Horne' AND isActive= true LIMIT 1];
       Controlled_Document__c cdt = new Controlled_Document__c();
       cdt.Stage__c='Drafting';
       cdt.Correspondence_Type__c='Forms';
       cdt.Originating_Office__c='AK - Office of Civil Rights';
       cdt.GSA_Action_Required__c = 'Signature/Approval of the Deputy Administrator';
       insert cdt;       
       cdt.GSA_Action_Required__c = 'Signature/Approval of the Administrator';
       try {
           update cdt;
       }
       catch(DMLException e) {
           System.assertEquals('FIELD_CUSTOM_VALIDATION_EXCEPTION', e.getDmlStatusCode(0));
       }        
   }
   static testmethod void testUpdateValidation2() {
       User agencyAdmin = [SELECT Id from User Where Name = 'Timothy Horne' AND isActive= true LIMIT 1];
       Controlled_Document__c cdt = new Controlled_Document__c();
       cdt.Stage__c='Drafting';
       cdt.Correspondence_Type__c='Forms';
       cdt.Originating_Office__c='AK - Office of Civil Rights';
       cdt.Final_Signatory__c = UserInfo.getUserId();
       insert cdt;
       cdt.Final_Signatory__c = agencyAdmin.Id;       
       try {
           update cdt;
       }
       catch(DMLException e) {
           System.assertEquals('FIELD_CUSTOM_VALIDATION_EXCEPTION', e.getDmlStatusCode(0));
       }        
   }
   // Case# 27460 - END - for test coverage of ControlledDocumentTrigger
}