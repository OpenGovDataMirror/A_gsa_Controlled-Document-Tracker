@isTest
public with sharing class PermissionSetAssignmentDAMock implements PermissionSetAssignmentDAI{
	public List<PermissionSetAssignment> permSetAssignments = new List<PermissionSetAssignment>();
	public List<PermissionSetAssignment> getPermissionSetAssigmentForCdtOasAdminUsers(){
		return permSetAssignments;
	}
	public List<PermissionSetAssignment> getPermissionSetAssignmentsForUserId(Id userId){
		return permSetAssignments;
	}
}