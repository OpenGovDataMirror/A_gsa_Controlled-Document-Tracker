global class ScheduleUpdateDaysOpenOnApprovalSteps implements Schedulable {
	global void execute(SchedulableContext sc) {
		UpdateDaysOpenOnApprovalStepsBatch b = new UpdateDaysOpenOnApprovalStepsBatch();
		database.executebatch(b);
	}
}