@isTest
public class TestBatchVMMail {
    
    @isTest static void testMail() {
        
        String vRT = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Vendor').getRecordTypeId();
        String VCRT = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Vendor').getRecordTypeId();
        Account v;
        Contact c;
        List<Account> lstAccount;
        
        v = new Account();
        v.Name = 'TestVendor';
        v.RecordTypeId = vRT;  
        insert v;
        
        c = new Contact();
        c.FirstName = 'John';
        c.LastName = 'Doe';
        c.Email = 'jdoe@exmple.com';
        c.AccountId = v.id;
        c.RecordTypeId = vCRT;
        c.Report_Distribution__c = 'Roster';
        insert c;
        
        lstAccount = [SELECT Id, Top_Parent_Id__c FROM Account WHERE Id =: v.id];
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());
        BatchVendorMemberSendEmail bd = new BatchVendorMemberSendEmail(lstAccount,true);        
        database.executeBatch(bd,200);      
        Test.stopTest();    
        
        Integer invocations = Limits.getEmailInvocations();        
        system.assertEquals(0, invocations, 'An email should be sent'); 
        
        
    }
}