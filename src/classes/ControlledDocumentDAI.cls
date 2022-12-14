public interface ControlledDocumentDAI {
	List<Controlled_Document__c> getControlledDocumentsByIds(List<Id> documentIds);
	Controlled_Document__c getControlledDocumentById(Id docId);
	Controlled_Document__c updateControlledDocument(Controlled_Document__c document);
}