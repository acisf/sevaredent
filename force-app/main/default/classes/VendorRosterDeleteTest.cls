@isTest
public class VendorRosterDeleteTest {
    
    @isTest
    public static void runTest() {
        
        String vRT = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Vendor').getRecordTypeId();
        String VCRT = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Vendor').getRecordTypeId();
        Account v;
        
        v = new Account();
        v.Name = 'TestVendor';
        v.RecordTypeId = vRT;  
        insert v;
        
        Vendor_Roster__c vr = new Vendor_Roster__c();
        vr.Vendor__c = v.id;
        vr.ReportID__c = '00O03000000JreiEAC';
        insert vr;
        
        Test.startTest();
        
        //test vendor roster list
        VendorRoster vrc = new VendorRoster();
        List<Vendor_Roster__c> lstVR = vrc.getVendorRosterList();
        System.assert(lstVR.size() == 1);
                       
        //test batch 
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());
     	VendorRosterDeleteBatch vdb = new VendorRosterDeleteBatch(lstVR);
        Database.executeBatch(vdb,1);  
        
        lstVR = vrc.getVendorRosterList();
        system.assertEquals(1,lstVR.size());
        Test.stopTest();        
        
    }
}