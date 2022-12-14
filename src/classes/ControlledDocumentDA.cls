public with sharing class ControlledDocumentDA implements ControlledDocumentDAI{
	public List<Controlled_Document__c> getControlledDocumentsByIds(List<Id> documentIds){
		return [
				SELECT Id,
					Name,
					Correspondence_Type__c,
					Current_Location__c,
					Current_Location_auto__c,
					Current_Division_Code__c,
					Current_Organization_Acronym__c,
					Current_Location_Start_Date_New__c,
					Current_Region_Auto__c,
					Current_Division_Name__c,
					Stage__c,
					OMB__c,
					ExecSec_Start_Date__c,
					Assignee__c,
					Final_Signatory__c,
					OwnerId
				FROM Controlled_Document__c
				WHERE Id IN :documentIds
		];
	}

	public Controlled_Document__c getControlledDocumentById(Id docId){
		return [
			SELECT Id,
				Name,
				Current_Location__c,
				Current_Location_auto__c,
				Current_Division_Code__c,
				Current_Organization_Acronym__c,
				Current_Location_Start_Date_New__c,
				Current_Region_Auto__c,
				Current_Division_Name__c,
				Stage__c,
				OMB__c,
				ExecSec_Start_Date__c,
				Assignee__c,
				Final_Signatory__c,
				OwnerId
			FROM Controlled_Document__c
			WHERE Id = :docId
		];
	}

	public Controlled_Document__c updateControlledDocument(Controlled_Document__c document){
		update document;
		return document;
	}
}