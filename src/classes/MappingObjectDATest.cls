@isTest
public with sharing class MappingObjectDATest {
	@isTest
	public static void getMappingObjectsByName_givenNewMappingObject_shouldReturnSameObject(){
		Mapping_Object__c mappingObject = new Mapping_Object__c();
		mappingObject.Name = '10A';
		mappingObject.Service_Staff_Office__c = 'GSA';
		mappingObject.Office_Portfolio__c = 'General Services Administration';

		insert mappingObject;

		MappingObjectDA mapObjectDA = new MappingObjectDA();

		Test.startTest();
			List<Mapping_Object__c> mappingObjects = mapObjectDA.getMappingObjectsByName('10A');
		Test.stopTest();

		for(Mapping_Object__c mo : mappingObjects){
			System.assertEquals(mappingObject.Service_Staff_Office__c, mo.Service_Staff_Office__c);
			System.assertEquals(mappingObject.Office_Portfolio__c, mo.Office_Portfolio__c);
		}
	}
}