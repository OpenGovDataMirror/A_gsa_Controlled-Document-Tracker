@isTest
public with sharing class OrgWideEmailAddressDAMock implements OrgWideEmailAddressDAI{
	public OrgWideEmailAddress emailAddress = new OrgWideEmailAddress(Address='noreply@gsa.gov');

	public OrgWideEmailAddress getOrgWideEmailByAddress(String address){
		return emailAddress;		
	}
}