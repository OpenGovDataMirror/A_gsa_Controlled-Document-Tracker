@isTest
public with sharing class BusinessHoursDAMock {
	public static BusinessHours businessHrs = new BusinessHours();

	public static BusinessHours getBusinessHoursByName(String name){
		return businessHrs;
	}
}