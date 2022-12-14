public interface UserDAI {
	User getUserById(Id userId);
//	List<User> getUsersByIds(List<Id> userIds);
	List<User> getUserWithEmailByIds(Set<Id> userIds);
}