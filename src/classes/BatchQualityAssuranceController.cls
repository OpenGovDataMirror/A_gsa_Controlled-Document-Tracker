public with sharing class BatchQualityAssuranceController {

	private final Long LONGEST_TIME_BATCH_SHOULD_HAVE_LAST_RUN = 3600000;

	public List<BatchWrapper> batchWrapperList {get; set;}
	public List<BadControlledDocuments> badCdList {get; set;}
	public String issuesIdentified {get; set;}
	public boolean batchIsRunning {get; set;}
	public String batchStatusRunning {get; set;}
	public String batchStatusStopped {get; set;}

	public BatchQualityAssuranceController(){
		batchWrapperList = new List<BatchWrapper>();
		badCdList = new List<BadControlledDocuments>();
		
		List<AsyncApexJob> jobList = [SELECT Id, ApexClassID, ApexClass.Name, CompletedDate, ExtendedStatus, JobItemsProcessed, JobType, MethodName, NumberOfErrors, Status, TotalJobItems 
										FROM AsyncApexJob 
										WHERE ApexClass.Name IN ('GrantAccessToChatterFileBatch','GrantAccessToChatterFileBatchSchedule') 
										AND Status IN ('Queued','Processing','Preparing') ];
		
		if(jobList != null || jobList.size() < 10){

			Integer fillOutNumber = 10 - jobList.size();

			jobList.addAll([SELECT Id, ApexClassID, ApexClass.Name, CompletedDate, ExtendedStatus, JobItemsProcessed, JobType, MethodName, NumberOfErrors, Status, TotalJobItems 
										FROM AsyncApexJob 
										WHERE ApexClass.Name IN ('GrantAccessToChatterFileBatch','GrantAccessToChatterFileBatchSchedule') 
										AND Status IN ('Completed', 'Aborted') 
										AND CompletedDate <= TODAY
										ORDER BY CompletedDate DESC
										LIMIT :fillOutNumber]);
		}

		Integer i = 10;
		for(AsyncApexJob job : jobList){

			batchWrapperList.add(
								new BatchWrapper(job.ApexClass.Name, 
												job.JobItemsProcessed,
												job.CompletedDate));

			i--;
		}

		List<Controlled_Document_Feed__c> guaList = [SELECT Id, Created_Date__c, Status__c, User__c, User__r.Name, Notified__c, Controlled_Document__c, Controlled_Document__r.Name
													FROM Controlled_Document_Feed__c
													WHERE Status__c = 'Pending'];
		for(Controlled_Document_Feed__c gua : guaList){
			badCdList.add(
							new BadControlledDocuments(gua.Controlled_Document__c,
														gua.Controlled_Document__r.Name,
														gua.User__c,
														gua.User__r.Name,
														gua.Created_Date__c));
		}

		// determine if true or false
		batchIsRunning = false;
		for(BatchWrapper batch : batchWrapperList){
			if(batch.batchName == 'GrantAccessToChatterFileBatchSchedule'){
				batchIsRunning = true;
				break;
			} /*else {
				if(batch.completionDatetime == null) continue;
				Long timeDifference = System.now().getTime() - batch.completionDatetime.getTime();
				if(timeDifference < 10){
					batchIsRunning = true;
				}
			}*/
		}

		if(jobList.size() < 10) {
			batchIsRunning = false;
		}

		if(batchIsRunning){
			batchStatusStopped = 'display:none';
		}else {
			batchStatusRunning = 'display:none';
		}
	}

	public class BatchWrapper {
		public String batchName {get; set;}
		public Integer jobsProcessed {get; set;}
		public Datetime completionDatetime {get; set;}
		public String completionDate {get; set;}

		public BatchWrapper(String batchName, Integer jobsProcessed, Datetime completionDate){
			this.batchName = batchName;
			this.jobsProcessed = jobsProcessed;
			this.completionDatetime = completionDate;
			if(completionDate != null) this.completionDate = completionDate.format();
		}
	}

	public class BadControlledDocuments {
		public String controlledDocumentId {get; set;}
		public String controlledDocumentName {get; set;}
		public String requestorId {get; set;}
		public String requestorName {get; set;}
		public String requestedTime {get; set;}

		public BadControlledDocuments(String controlledDocumentId, String controlledDocumentName, String requestorId, String requestorName, Datetime requestedTime){
			this.controlledDocumentId = controlledDocumentId;
			this.controlledDocumentName = controlledDocumentName;
			this.requestorId = requestorId;
			this.requestorName = requestorName;
			if(requestedTime != null) this.requestedTime = requestedTime.format();
		}
	}

}