public with sharing class BusinessHoursDA implements BusinessHoursDAI{
	public static BusinessHours getBusinessHoursByName(String name){
		return [
				SELECT Id
				FROM BusinessHours
				WHERE Name= :name
		];
	}
}