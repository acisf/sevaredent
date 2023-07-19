@isTest
public class VendorRosterEmailTest {
    
    @isTest
    public static void runTest() {
        
        String vRT = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Vendor').getRecordTypeId();
        String VCRT = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Vendor').getRecordTypeId();
        Account v;
        
        v = new Account();
        v.Name = 'TestVendor';
        v.RecordTypeId = vRT;  
        insert v;
        
        Contact c = new Contact();
        c.FirstName = 'John';
        c.LastName = 'Doe';
        c.Email = 'jdoe@exmple.com';
        c.AccountId = v.id;
        c.RecordTypeId = vCRT;
        c.Report_Distribution__c = 'Roster';
        insert c;
        
        Vendor_Roster__c vr = new Vendor_Roster__c();
        vr.Vendor__c = v.id;
        vr.ReportID__c = '00O03000000JreiEAC';
        insert vr;
        
        Test.startTest();
        
        //test VendorRosterEmail constructor
        VendorRosterEmail vre = new VendorRosterEmail();
        System.assert(vre != null);  
        
        //test vendor roster list
        List<Vendor_Roster__c> lstVR = vre.getVendorRosterList();
        System.assert(lstVR.size() == 1);
        
        //test vendor report map
        Map<id,string> mapVR = new Map<id,string>();
        mapVR = vre.getVendorReportMap(lstVR);
        System.assert(mapVR.get(v.id) == '00O03000000JreiEAC' );
        
        //test vendor roster contact list
        List<Contact> lstC = vre.getContactsFromVendorRosterList(lstVR);
        System.assert(lstC.size() ==1);  
               
        //test batch 
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());
     	VendorRosterEmailBatch vreb = new VendorRosterEmailBatch(lstC);
        Database.executeBatch(vreb,1);   
      
        Test.stopTest();
        
        
    }
}