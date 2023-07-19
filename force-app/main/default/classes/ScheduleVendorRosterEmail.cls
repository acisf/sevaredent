global class ScheduleVendorRosterEmail Implements Schedulable
{
    global void execute(SchedulableContext sc)
    {   
        VendorRosterEmail vre = new VendorRosterEmail();
        List<Vendor_Roster__c> lstVR;
        List<Contact> lstC; 
        lstVR = vre.getVendorRosterList();
        lstC = vre.getContactsFromVendorRosterList(lstVR);
        VendorRosterEmailBatch vreb = new VendorRosterEmailBatch(lstC);
        Database.executeBatch(vreb,1);  
        
    }
}