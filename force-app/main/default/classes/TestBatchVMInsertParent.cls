@isTest
public class TestBatchVMInsertParent {
    
    
    @isTest static void test(){
        String vRT = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Vendor').getRecordTypeId();
        String mRT = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Member').getRecordTypeId();
        String MSA = Schema.SObjectType.APXT_Redlining__Contract_Agreement__c.getRecordTypeInfosByName().get('MSA').getRecordTypeId();
        Account v;
        Account m;
        Vendor_Member__c vm;
        Contract_Implementations__c ci;
        APXT_Redlining__Contract_Agreement__c ca;
        List<Vendor_Member__c> lstVM = new List<Vendor_Member__c>();
        List<Account> lstMembers= new List<Account>();
        List<Account> lstVendors= new List<Account>();
        List<APXT_Redlining__Contract_Agreement__c> lstCA = new List<APXT_Redlining__Contract_Agreement__c>();
        List<Contract_Implementations__c> lstCI = new List<Contract_Implementations__c>(); 
        
        v = new Account();
        v.Name = 'TestVendor';
        v.RecordTypeId = vRT;
        lstvendors.add(v);
        
        m = new Account();
        m.Name = 'TestMember';
        m.RecordTypeId = mRT;
        lstMembers.add(m);
        
        insert lstVendors;
        insert lstMembers;
        
        ca = new APXT_Redlining__Contract_Agreement__c();
        ca.RecordTypeId = msa;
        ca.APXT_Redlining__Account__c = v.id; 
        lstCA.add(ca);    
        insert lstCA;
        
      
        ci = new Contract_Implementations__c();
        ci.Account__c = m.id;
        ci.Status__c = 'Implemented'; 
        ci.Contract_Agreement__c = ca.id;
        lstCI.add(ci);
        
        insert lstCI;
        
          lstCI = [SELECT Id, Name, Account__c, Status__c, Contract_Agreement__c, Vendor_ID__c
                 FROM Contract_Implementations__c];
        
        Test.startTest();
        BatchVendorMemberInsertParents bd = new BatchVendorMemberInsertParents(lstCI);
        database.executeBatch(bd,200);
        Test.stopTest();                     
        
        lstVM = [select id, name, VendorIdMemberId__c,Vendor__c,Member__c 
                 from Vendor_Member__c];
        System.assertEquals(1,lstVM.size());
    }
}