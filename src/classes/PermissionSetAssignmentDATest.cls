@isTest
private class PermissionSetAssignmentDATest {
	
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
	}
	
	@isTest
	public static void getPermissionSetAssigmentForCdtOasAdminUsers_shouldReturnCdtOasAdmins() {
		PermissionSetAssignmentDA permSetAssignmentDA = new PermissionSetAssignmentDA();
		Test.startTest();
			List<PermissionSetAssignment> permissionSetAssignments = permSetAssignmentDA.getPermissionSetAssigmentForCdtOasAdminUsers();
		Test.stopTest();

		String permSetName = 'Controlled_Document_Tracker_OAS_Admin_User_CRED';
		for (PermissionSetAssignment psa : permissionSetAssignments){
			System.assertEquals(permSetName, psa.PermissionSet.Name);
		}

	}

	@isTest
	public static void getPermissionSetAssignmentsForUserId_givenOASAdmin_shouldHaveOASAdminPermSet(){
		PermissionSetAssignmentDA permSetAssignmentDA = new PermissionSetAssignmentDA();
		List<PermissionSetAssignment> oasAdmins = permSetAssignmentDA.getPermissionSetAssigmentForCdtOasAdminUsers();
		Id oasAdminId = oasAdmins[0].AssigneeId;

		Test.startTest();
		List<PermissionSetAssignment> permissionSetAssignments = permSetAssignmentDA.getPermissionSetAssignmentsForUserId(oasAdminId);
		Test.stopTest();

		String permSetName = 'Controlled_Document_Tracker_OAS_Admin_User_CRED';
		List<String> permSetForUserNames = new List<String>();
		for (PermissionSetAssignment psa : permissionSetAssignments){
			permSetForUserNames.add(psa.PermissionSet.Name);
		}

		System.assert(permSetForUserNames.contains(permSetName));
	}
}