global class ScheduleVendorRosterBatch Implements Schedulable
{
    global void execute(SchedulableContext sc)
    {   
        
        //delete old reports
        VendorRoster vrc = new VendorRoster();
        List<Vendor_Roster__c> lstVR = vrc.getVendorRosterList();
        VendorRosterDeleteBatch vdb = new VendorRosterDeleteBatch(lstVR);
        Database.executeBatch(vdb,1);         
        
        //create the reports
        List<Contract_Implementations__c> lstCI;
        VendorRoster vr = new VendorRoster();
        lstCI = new List<Contract_Implementations__c>();
        lstCI = vr.getContractImplementations();
        Map<string,Set<Id>> mapVA = vr.getVendorToAccountMap(lstCI);
        List<Account> lstVendors = vr.getUniqueVendorList(mapVA.keyset());
        VendorRosterBatch vb = new VendorRosterBatch(lstVendors,mapVA);
        System.scheduleBatch(vb, 'Vendor Roster', 10, 1); 
    }
}