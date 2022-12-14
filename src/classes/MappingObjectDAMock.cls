@isTest
public with sharing class MappingObjectDAMock implements MappingObjectDAI{
	public Mapping_Object__c mappingObject = new Mapping_Object__c();
	public List<Mapping_Object__c> getMappingObjectsByName(String name){
		return new List<Mapping_Object__c>{mappingObject};
	}
}