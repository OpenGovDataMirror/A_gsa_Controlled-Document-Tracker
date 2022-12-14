@isTest
public with sharing class ApprovalStepDAMock implements ApprovalStepDAI{
	public List<Approval_Step__c> mockList = new List<Approval_Step__c>();
	public List<AggregateResult> resultList = new List<AggregateResult>();

	public List<Approval_Step__c> getAllInitiatedApprovalStepsWithControlledDocumentId(Id docId){
		return mockList;
	}
	public List<Approval_Step__c> getAllInitiatedApprovalStepsWithControlledDocumentIds(List<Id> docIds){
		return mockList;
	}
	public List<AggregateResult> getMaxInitiatedTimeForDocumentIds(List<Id> docIds){
		return resultList;
	}
}