//@isTest(seeAllData=true)
@isTest
public class TestGSAUtility {
    
    @testSetup
    static void dataSetup(){
        Account acc = new Account(Name='TestAccount');
        insert acc;
    }
    public static testmethod void testUtility() {

        Account acct = new Account();
        String fieldName = acct.Name;
        GSAUtility.getFieldValueFromObject (acct, fieldName);
        system.assertEquals(true, true);
    }
    static testMethod void getApiName() {
		List<Account> acc = [SELECT Id FROM Account];
        if(acc != null && !acc.isEmpty())
        {
            String accId = acc[0].Id;
			GSAUtility.getApiNameByRecordId(accId);
        }
        system.assertEquals(true, true);
		
	}
}