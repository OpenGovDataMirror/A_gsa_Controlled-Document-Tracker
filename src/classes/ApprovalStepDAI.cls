public interface ApprovalStepDAI {
	List<Approval_Step__c> getAllInitiatedApprovalStepsWithControlledDocumentId(Id docId);
	List<Approval_Step__c> getAllInitiatedApprovalStepsWithControlledDocumentIds(List<Id> docIds);
	List<AggregateResult> getMaxInitiatedTimeForDocumentIds(List<Id> docIds);
}