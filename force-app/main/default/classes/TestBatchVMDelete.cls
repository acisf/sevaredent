@isTest
public class TestBatchVMDelete {


    @isTest static void test(){
        String vRT = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Vendor').getRecordTypeId();
        String mRT = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Member').getRecordTypeId();
        
        Account v;
        Account m;
        Vendor_Member__c vm;
        Contract_Implementations__c ci;
        List<Vendor_Member__c> lstVM = new List<Vendor_Member__c>();
        List<Account> lstMembers= new List<Account>();
        List<Account> lstVendors= new List<Account>();
        List<Contract_Implementations__c> lstCI = new List<Contract_Implementations__c>(); 
        
        for(integer i=0;i<10;i++){
            v = new Account();
            v.Name = 'TestVendor' + String.valueOf(i);
            v.RecordTypeId = vRT;
            lstvendors.add(v);
        }
        
        for(integer i=0;i<10;i++){
            m = new Account();
            m.Name = 'TestMember' + String.valueOf(i);
            m.RecordTypeId = mRT;
            lstMembers.add(m);
        }
        
        insert lstVendors;
        insert lstMembers;
        
        for( Account a:lstVendors) {
            for( Account b:lstMembers) {
                vm = new Vendor_Member__c();
                vm.Vendor__c = a.id;
                vm.Member__c = b.id;   
                vm.VendorIdMemberId__c = String.valueOf(a.id) + String.valueOf(b.id);
                lstVM.add(vm);
            }            
        }
        
        insert lstVM;
        
        Test.startTest();
        BatchVendorMemberDelete bd = new BatchVendorMemberDelete(lstVM);
        database.executeBatch(bd,200);
        Test.stopTest();                     
        
        lstVM = [select id, name, VendorIdMemberId__c,Vendor__c,Member__c 
                 from Vendor_Member__c];
        System.assertEquals(0,lstvm.size());
    }
}