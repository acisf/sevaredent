@isTest
public class TestScheduleVendorRosterEmail {
    
    static testmethod void test() {
        Test.startTest();
        // Schedule the test job
        String jobId = System.schedule('TestScheduleVendorRosterEmail','0 0 03 1/1 * ? *',new ScheduleVendorRosterEmail());
        // Get the information from the CronTrigger API object
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, 
                          NextFireTime
                          FROM CronTrigger WHERE id = :jobId];
        
        // Verify the expressions are the same
        System.assertEquals( '0 0 03 1/1 * ? *', ct.CronExpression);
        
        // Verify the job has not run
        System.assertEquals(0, ct.TimesTriggered);
        
        // Verify the next time the job will run
        DateTime dt;
        dt = DateTime.newInstance(Date.today()+1,Time.newInstance(03,0,0,0));

        System.assertEquals( dt, ct.NextFireTime);
        Test.stopTest();
    }
}