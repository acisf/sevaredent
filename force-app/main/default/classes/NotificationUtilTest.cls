@isTest
public class NotificationUtilTest {
    
     @isTest
    private static void runTest(){
        
        //test data        
        Account account = new Account();
        Id GpoRT = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Member').getRecordTypeId();
        account.Name = 'Test Member';
        account.Member_Id__c = '123';
        account.RecordTypeId = GpoRT;
        insert account;
        
		Account vendor = new Account();
        Id VendorRT = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Vendor').getRecordTypeId();
        vendor.Name = 'Test Vendor'; 
        vendor.RecordTypeId = VendorRT;
        insert vendor;

        Contact contact = new Contact();
        contact.FirstName = 'John';
        contact.LastName = 'Doe';
        contact.Email = 'john.doe@example.com';
        contact.AccountId = account.Id;
        insert contact;
    
        AccountContactRelation acr = [SELECT AccountId, ContactId, Primary_Contact__c,Inactive__c
                                      FROM AccountContactRelation];
        acr.Primary_Contact__c = true;
        acr.IsActive = true;
        acr.Inactive__c = false;
        update acr;
        
        APXT_Redlining__Contract_Agreement__c contract = new APXT_Redlining__Contract_Agreement__c();
        Id agrId = Schema.SObjectType.APXT_Redlining__Contract_Agreement__c.getRecordTypeInfosByName().get('MSA').getRecordTypeId();
        contract.RecordTypeId = agrId;
        contract.APXT_Redlining__Effective_Date__c = System.today();
        contract.APXT_Redlining__Account__c = vendor.Id;
        contract.Sevaredent_Contract_Number__c = 'SIMP1002';
        contract.Initial_Term_Years__c = 1;
        insert contract;

        Revenue_Tracking__c revenueTracking = new Revenue_Tracking__c();
        revenueTracking.GPO_Member_Account__c = account.Id;
        revenueTracking.Amount__c = 10;
        revenueTracking.Location_Id__c = '123';
        revenueTracking.CA_Vendor_Contract__c = contract.Id;
        revenueTracking.Year__c = 2020;
        insert revenueTracking;
        
        Test.startTest(); 
        
        
        /*test update revenue tracking contacts */
        NotificationUtil.updateRevenueTrackingContacts('2020',1000);
       
        
        /*test create attachments & insert notification tracking */              
        NotificationUtil.createAttachments('2020',1000);		
        
        //test send notification
        NotificationUtil.sendNotifications('2020',100);  
        
        Test.stopTest();
        
        List<Revenue_Tracking__c> lstRT = [SELECT Id,Name,Contract_Name__c,Location_Id__c, Amount__c, Start_Date__c, 
                End_Date__c, GPO_Member_Account__c, CA_Vendor_Contract__c, Primary_Contact__c, Month__c, 
                CA_Vendor_Contract_Name__c, CA_Vendor_Name__c,Quarter__c,Units__c, Volume__c,
                Sevaredent_ID__c, Rebate__c, Top_Parent_Account__c 
                FROM Revenue_Tracking__c
                WHERE Year__c =: 2020];       
        System.assert(lstRT[0].primary_contact__c != null); 
        
        List<annualnotificationtracking__c> lstAT = [ select id, gpo_member_account__c, attachment_Id__c,date_sent__c,primary_contact__c,
                primary_contact__r.Email, gpo_member_account__r.Name
                from annualnotificationtracking__c 
                where date_sent__c =: null and 
                Fiscal_Year__c =: '2020'];
        system.assertEquals(0,lstAT.size());
        
       
    }
}