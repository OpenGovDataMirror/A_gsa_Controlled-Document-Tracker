@isTest
public with sharing class ControlledDocumentDAMock implements ControlledDocumentDAI{

	public List<Controlled_Document__c> documentList = new List<Controlled_Document__c>();
	public Controlled_Document__c document = new Controlled_Document__c();

	public List<Controlled_Document__c> getControlledDocumentsByIds(List<Id> documentIds){
		return documentList;
	}

	public Controlled_Document__c getControlledDocumentById(Id docId){
		return document;
	}

	public Controlled_Document__c updateControlledDocument(Controlled_Document__c document){
		return document;
	}
}