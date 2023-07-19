public class VendorRosterEmail {
    
    
    public List<Vendor_Roster__c> getVendorRosterList() {
        return [select id, vendor__c, reportid__c from vendor_roster__c];
    }
    
    public Map<Id,String> getVendorReportMap(List<Vendor_Roster__c> lstVR) {
        Map<Id,String> mapVR = new Map<id,String>();
        for(Vendor_Roster__c vr:lstVR) {
            mapVR.put(vr.Vendor__c,vr.ReportID__c);
        }
        return mapVR;
    }
    
    public List<Contact> getContactsFromVendorRosterList(List<Vendor_Roster__c> lstVR) {
        List<Contact> lstContacts;
        Set<Id> vendorIds = new set<id>();
        
        for(Vendor_Roster__c vr: lstVR) {
            vendorIds.add(vr.Vendor__c);
        }
        
        lstContacts = [select id,firstname,lastname,email,accountid, account.name
                       from contact
                       where accountid in: vendorids
                       and Report_Distribution__c = 'Roster'
                       and email != ''];
        
        return lstContacts;
    }   
    
     public HttpResponse getVendorMemberReport(string reportid) {
        
        Http http = new Http();
        HttpRequest request;
        HttpResponse  response; 
        
        request = new HttpRequest();  
        request.setEndpoint(System.URL.getSalesforceBaseURL().toExternalForm() + 
                            '/services/data/v52.0/analytics/reports/' + reportId);
        
        request.setMethod('GET');  
        request.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionID()); 
        request.setHeader('Accept', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'); 
        response= http.send(request);
        return response;
    }
   
}