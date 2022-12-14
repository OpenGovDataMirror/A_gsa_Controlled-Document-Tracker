public interface PermissionSetAssignmentDAI {
	List<PermissionSetAssignment> getPermissionSetAssigmentForCdtOasAdminUsers();
	List<PermissionSetAssignment> getPermissionSetAssignmentsForUserId(Id userId);
}