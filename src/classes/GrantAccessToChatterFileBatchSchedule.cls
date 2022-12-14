public class GrantAccessToChatterFileBatchSchedule implements Schedulable {
	public void execute(SchedulableContext sc) {
    	GrantAccessToChatterFileBatch b = new GrantAccessToChatterFileBatch();
		ID batchprocessid = Database.executeBatch(b, 1);
   }

}