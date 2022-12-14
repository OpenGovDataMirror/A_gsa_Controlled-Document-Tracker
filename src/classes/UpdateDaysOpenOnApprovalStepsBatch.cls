global with sharing class UpdateDaysOpenOnApprovalStepsBatch implements Database.Batchable<Sobject> {
	public static final String query = 'SELECT Id FROM Controlled_Document__c WHERE ExecSec_Start_Date__c != null OR Due_Date__c != null OR ExecSec_Due_Date__c != null OR Stage__c != \'Closed\' LIMIT 50000';
	public static boolean isBatchOn = false;
	
	global Database.QueryLocator start(Database.BatchableContext BC){
		return Database.getQueryLocator(query);
	}

	global void execute(Database.BatchableContext BC, List<Sobject> scope){
		isBatchOn = true;

		Database.update(scope, false);
		
		List<Approval_Step__c> childApprovalSteps = [SELECT Approval_Status__c 
		                                             FROM   Approval_Step__c 
		                                             WHERE  Correspondence_Document__c IN: scope AND 
		                                                    Approval_Status__c =: ControlledDocumentConstants.INITIATED_STATUS_STRING];
		Database.update(childApprovalSteps, false);

		List<Location_and_Stage_History__c> locationAndStageHistories = [SELECT Id, Active__c
																			FROM Location_and_Stage_History__c
																			WHERE Active__c = true];
		Database.update(locationAndStageHistories, false);
	}

	global void finish(Database.BatchableContext BC){
		AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email
							FROM AsyncApexJob 
							WHERE Id =: BC.getJobId()];
		/*
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		String[] toAddresses = new String[] {'someone@somewhere.gov'};
		mail.setToAddresses(toAddresses);
		mail.setSubject('UpdateDaysOpenOnApprovalStepsBatch ' + a.Status);
		mail.setPlainTextBody('The batch Apex job processed ' + a.TotalJobItems + ' batches with '+ a.NumberOfErrors + ' failures.');
		Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
		*/
	}
}