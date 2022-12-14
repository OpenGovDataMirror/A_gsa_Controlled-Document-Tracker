public with sharing class MappingObjectDA implements MappingObjectDAI{
	public List<Mapping_Object__c> getMappingObjectsByName(String name){
		return [SELECT Id,
				Service_Staff_Office__c,
				Office_Portfolio__c
		FROM Mapping_Object__c
		WHERE Name = :name];
	}
}