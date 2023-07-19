@isTest
public class VendorRosterTest {
    
    @isTest
    public static void runTest() {
        
        String vRT = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Vendor').getRecordTypeId();
         String VCRT = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Vendor').getRecordTypeId();
        String mRT = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Member').getRecordTypeId();
        String MSA = Schema.SObjectType.APXT_Redlining__Contract_Agreement__c.getRecordTypeInfosByName().get('MSA').getRecordTypeId();
        //String ciRT = Schema.SObjectType.Contract_Implementations__c.getRecordTypeInfosByName().get('Active').getRecordTypeId();
      
        Account v;
        Account m;
        Account m2;       
        Contract_Implementations__c ci;
        APXT_Redlining__Contract_Agreement__c ca;
        
        List<Account> lstAccount = new List<Account>(); 
        List<APXT_Redlining__Contract_Agreement__c> lstCA = new List<APXT_Redlining__Contract_Agreement__c>();
        List<Contract_Implementations__c> lstCI = new List<Contract_Implementations__c>(); 
        
        v = new Account();
        v.Name = 'TestVendor';
        v.RecordTypeId = vRT;  
        v.Status__c = 'Active';
        insert v;
                 
        Contact c = new Contact();
        c.FirstName = 'John';
        c.LastName = 'Doe';
        c.Email = 'jdoe@exmple.com';
        c.AccountId = v.id;
        c.RecordTypeId = vCRT;
        c.Report_Distribution__c = 'Roster';
        insert c;
        
        m = new Account();
        m.Name = 'Test Member';
        m.RecordTypeId = mRT;
        m.Status__c = 'Active';
        insert m;
        
        m2 = new Account();
        m2.Name  = 'Test Member 2';
        m2.RecordTypeId = mRT;        
        m2.Status__c = 'Active';
        insert m2;
        
        ca = new APXT_Redlining__Contract_Agreement__c();
        ca.RecordTypeId = msa;
        ca.APXT_Redlining__Account__c = v.id; 
        ca.APXT_Redlining__Status__c = 'Activated';
        lstCA.add(ca);    
        insert lstCA; 
        
        ci = new Contract_Implementations__c(); 
        //ci.RecordTypeId = ciRT;
        ci.Contract_Agreement__c = ca.id;
        ci.Account__c = m.id;
        ci.Status__c = 'Implemented'; 
        lstCI.add(ci); 
        
        ci = new Contract_Implementations__c();  
        //ci.RecordTypeId = ciRT;
        ci.Contract_Agreement__c = ca.id;
        ci.Account__c = m2.id;
        ci.Status__c = 'Implemented'; 
        lstCI.add(ci); 
        
        insert lstCI;
        
        lstCI = [SELECT Id, Name, Account__c, Status__c, Contract_Agreement__c, Vendor_ID__c
                 FROM Contract_Implementations__c];
                
        
        Test.startTest();
        
        //test constructors
        VendorRoster vr = new VendorRoster();
        System.assert(vr != null);   
        
             
        //test list of contract implementations
        lstCI = new List<Contract_Implementations__c>();
        lstCI = vr.getContractImplementations();
        System.assert(lstCI.size() > 0);        
        
        //test vendor to account map
        Map<string,Set<Id>> mapVA = vr.getVendorToAccountMap(lstCI);
        System.assert(mapVA.size() ==1);
        Set<string> vendorids = mapVA.keyset();
        for(string id:vendorids) {
            System.assert(id == v.id);
        }
        string vendorid = String.valueOf(v.id).left(15);
        set<id> accountids = mapVA.get(vendorid);
        System.assert(accountids.size() == 2); 
        
         //test unique vendor list
        List<Account> lstVendors = vr.getUniqueVendorList(mapVA.keyset());
        system.assert(lstVendors.size() == 1);
        
         //test delete report
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());
        HttpResponse res = vr.deleteReport('00O03000000JreiEAC');
        System.assert(res.getStatusCode() == 200);
            
        
        //test clone report
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());
        res = vr.cloneTemplate(v.Name);
        System.assert(res.getStatusCode() == 200);
        
        //test get report id
        String reportid = '';
        reportid = vr.getClonedReportId(res);
        System.assert(reportid == '00O03000000JreiEAC');
        
        //test set report filter
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());
        res = vr.setVendorRosterFilter(reportid,mapVA.get(vendorid));
        System.assert(res.getStatusCode() == 200);
        
        //test vendor_roster__c upsert
        vr.upsertVendorRoster(vendorid, reportId);
        Vendor_Roster__c vrObj = [select id from vendor_roster__c where vendor__c =: v.id];
        System.assert(vrObj != null);
        
        //test get vendor roster list
        list<Vendor_Roster__c> lstVR;
        lstVR = vr.getVendorRosterList();
        system.debug('Vendor Roster List: ' + lstVR.size());
        System.assertEquals(1,lstVR.size());
        
        //test vendor roster batch
        VendorRosterBatch vb = new VendorRosterBatch(lstVendors,mapVA);
        //Database.executeBatch(vb,1);  
        
    }
    
}