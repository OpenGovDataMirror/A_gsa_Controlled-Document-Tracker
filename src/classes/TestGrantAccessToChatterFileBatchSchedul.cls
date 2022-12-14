
@isTest
private class TestGrantAccessToChatterFileBatchSchedul {

    static testMethod void myUnitTest() {
        Test.startTest();    	
        String jobId = System.schedule('testBatchScheduler', '0 0 0 3 9 ? 2022', new GrantAccessToChatterFileBatchSchedule());
        Test.stopTest();

        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
                
        // Verify the expressions are the same
        System.assertEquals('0 0 0 3 9 ? 2022', ct.CronExpression);

        // Verify the job has not run
        System.assertEquals(0, ct.TimesTriggered);

        
    }
}