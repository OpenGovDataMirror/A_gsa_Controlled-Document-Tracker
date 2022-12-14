public with sharing class PermissionSetAssignmentDA implements PermissionSetAssignmentDAI{
	public List<PermissionSetAssignment> getPermissionSetAssigmentForCdtOasAdminUsers(){
		return [SELECT AssigneeId,
				Assignee.Name,
				Assignee.Email,
				PermissionSet.Name,
				PermissionSetId
		FROM PermissionSetAssignment
		WHERE PermissionSet.Name = 'Controlled_Document_Tracker_OAS_Admin_User_CRED'];
	}

	public List<PermissionSetAssignment> getPermissionSetAssignmentsForUserId(Id userId){
		return [SELECT AssigneeId,
				Assignee.Name,
				Assignee.Email,
				PermissionSet.Name,
				PermissionSetId
		FROM PermissionSetAssignment
		WHERE AssigneeId = :userId];
	}
}