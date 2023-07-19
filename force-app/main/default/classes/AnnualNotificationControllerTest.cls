/**
 * Created by Chintan Shah on 8/20/2020.
 */
@isTest
private class AnnualNotificationControllerTest {
    
    @testSetup
    private static void testSetup(){
        Account account = new Account();
        Id GPOMemberRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Member').getRecordTypeId();
        account.Name = 'Test Member';
        account.Member_Id__c = '123';
        account.RecordTypeId = GPOMemberRecordTypeId;
        insert account;

        Contact contact = new Contact();
        contact.FirstName = 'Test';
        contact.LastName = 'Test';
        contact.AccountId = account.Id;
        contact.Primary_Contact__c = true;
        insert contact;

        APXT_Redlining__Contract_Agreement__c contract = new APXT_Redlining__Contract_Agreement__c();
        Id agrId = Schema.SObjectType.APXT_Redlining__Contract_Agreement__c.getRecordTypeInfosByName().get('MSA').getRecordTypeId();
        contract.RecordTypeId = agrId;
        contract.APXT_Redlining__Effective_Date__c = System.today();
        contract.APXT_Redlining__Account__c = account.Id;
        contract.Sevaredent_Contract_Number__c = 'SIMP1002';
        contract.Initial_Term_Years__c = 1;
        insert contract;

        Revenue_Tracking__c revenueTracking = new Revenue_Tracking__c();
        revenueTracking.GPO_Member_Account__c = account.Id;
        revenueTracking.Primary_Contact__c = contact.Id;
        revenueTracking.Amount__c = 10;
        revenueTracking.Location_Id__c = '123';
        revenueTracking.CA_Vendor_Contract__c = contract.Id;
        insert revenueTracking;

    }

    @isTest
    private static void testAnnualNotificationController(){
        Account account = [select id from Account limit 1];
        Test.startTest();
        
        Test.setCurrentPageReference(new PageReference('Page.myPage'));
        System.currentPageReference().getParameters().put('memberId', account.Id);
        
        AnnualNotificationController anc = new AnnualNotificationController();
          system.assert('123' != anc.getShippingAddressPart2());
        Test.stopTest();
    }

}