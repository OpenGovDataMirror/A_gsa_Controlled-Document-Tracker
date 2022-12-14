trigger LocationStageHistoryTrigger on Location_and_Stage_History__c (before update) {

	if(trigger.isBefore && trigger.isUpdate){

		BusinessHours cdtBusinessHours = [SELECT Id
											FROM BusinessHours 
											WHERE Name = 'CDT Business Hours'];

		Datetime current = System.now();
		Date currDate = current.date();
		Time currTime = current.time();
		Datetime currentLocal = Datetime.newInstance(currDate, currTime);

		Map<Id, Location_and_Stage_History__c> oldHistoryMap = trigger.oldMap;
	
		for(Location_and_Stage_History__c locationStageHistory : trigger.new){
			if(locationStageHistory.Start_Date__c != null && locationStageHistory.End_Date__c != null){
				locationStageHistory.of_Days_New__c = getBsnsHoursDifference(cdtBusinessHours, locationStageHistory.Start_Date__c, locationStageHistory.End_Date__c);
			} else if(locationStageHistory.Start_Date__c != null){
				// if this date changes then either an admin is doing something or we are testing
				boolean startDateChanged = false;
				if(oldHistoryMap.get(locationStageHistory.Id).Start_Date__c != locationStageHistory.Start_Date__c){
					startDateChanged = true;
				}

				if(UpdateDaysOpenOnApprovalStepsBatch.isBatchOn || startDateChanged){
					locationStageHistory.of_Days_New__c = getBsnsHoursDifference(cdtBusinessHours, locationStageHistory.Start_Date__c, currentLocal);
				}
			}
		}

	}

	private static Double getBsnsHoursDifference(BusinessHours bsnsHours, Datetime startTime, Datetime endtime){
		Double d = BusinessHours.diff(bsnsHours.Id, startTime, endtime);
		return d/1000/3600/8;
	}

}