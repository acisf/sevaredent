public class VendorRoster {
    
    string templateid = '00O3h000003VkmNEAS';
    
    public class Response{
        public Attributes attributes;
    }
        
    public class Attributes {
        public string describeUrl;
        public string instancesUrl;
        public string reportId;
        public string reportName;
        public string type;
    }
    
    
    public List<Contract_Implementations__c> getContractImplementations() {
        return [ SELECT Id, Name, Account__c, Status__c, Contract_Agreement__c, Vendor_ID__c
                FROM Contract_Implementations__c              
                WHERE Account__r.Status__c = 'Active'
                AND Contract_Agreement__c != null
                AND (Status__c =: 'Implemented'
                     OR Status__c =: 'Partially Implemented')
               ORDER BY Vendor_ID__c];        
    }
    
    public List<Account> getUniqueVendorList(set<string> vendorids) {
        List<Account> lstVendors = new List<Account>();
        lstVendors = [select id, name from account
                      where id in: vendorids];
        return lstVendors;        
    }
    
    public Map<String,Set<Id>> getVendorToAccountMap(List<Contract_Implementations__c> lstCI) {
        Map<String,Set<Id>> mapVA = new Map<String,Set<Id>>();
        Set<Id> vendorids = new Set<Id>();
        Set<Id> memberids;
        
        for(Contract_Implementations__c ci: lstCI) {
            if(vendorids.add(ci.Vendor_ID__c)) {
                memberids = new set<id>();
                memberids.add(ci.Account__c);
            }
            else {
                memberids.add(ci.Account__c);
            }            
            mapVA.put(ci.Vendor_ID__c,memberids);
        }
        
        return mapVA;
    }
    
    public HttpResponse cloneTemplate(string strVendorName) {
        
        Http http = new Http();
        HttpRequest request;
        HttpResponse  response; 
        Date d = Date.today();
        String year = String.valueOf(d.year());
        String month = String.valueOf(d.month());
        String day = String.valueOf(d.day());
        String strReportName = strVendorName.left(32) + ' Roster';
        
        string body = '{ "reportMetadata" :   {"name":"' + strReportName + '"}}';
        
        request = new HttpRequest();
        
        request.setEndpoint(System.URL.getSalesforceBaseURL().toExternalForm() + 
                            '/services/data/v52.0/analytics/reports?cloneId=' + templateid); 
        
        request.setMethod('POST');
        request.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionID());
        request.setHeader('Content-Type', 'application/json; charset=UTF-8');
        request.setHeader('Accept', 'application/json');  
        request.setBody(body);
        response= http.send(request);
        System.debug(response);
        System.debug(response.getBody());
        return response;
    }
    
      public HttpResponse deleteReport(string reportId) {
        
        Http http = new Http();
        HttpRequest request;
        HttpResponse  response;         
        String body = '';
        request = new HttpRequest();
        
        
        request.setEndpoint(System.URL.getSalesforceBaseURL().toExternalForm() + 
                            '/services/data/v52.0/analytics/reports/' + reportId); 
        
        request.setMethod('DELETE');
        request.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionID());
        request.setHeader('Content-Type', 'application/json; charset=UTF-8');
        request.setHeader('Accept', 'application/json');  
        request.setBody(body);
        response= http.send(request);
        System.debug(response);
        System.debug(response.getBody());
        return response;
    }
    public string getClonedReportId (HttpResponse response) {
        string reportid = '';
        string jsonString = response.getBody(); 
        Response jResp = new Response();
        jResp = (Response)JSON.deserialize(jsonString, Response.class);
        system.debug(jResp); 
        
        if(jResp != null && jResp.attributes != null) 
        	reportid = jResp.attributes.reportId;
        
        return reportid;
    }
    
    public HttpResponse setVendorRosterFilter(string reportid,set<id> topParents) {
        
        Http http = new Http();
        HttpRequest request;
        HttpResponse  response;
        String strTopParents = '';
        
        for(string strId:topParents) {
            strTopParents += strId.left(15) + ',';
        }
        
        strTopParents = strTopParents.substring(0,strTopParents.lastIndexOf(','));
        
        string body = '{   "reportMetadata" : {    "reportFilters" : ' +
            '[ ' +
        	'{"column" : "Account.Top_Parent_Id__c","filterType" : "fieldValue", "isRunPageEditable" : true,  "operator" : "equals", "value" : "' + strTopParents + '"  },' +
            '{"column" : "Account.Status__c","filterType" : "fieldValue", "isRunPageEditable" : true,  "operator" : "equals", "value" : "Active"' + '}' +
        	']' +
            '}}';
        
        request = new HttpRequest();
        
        request.setEndpoint(System.URL.getSalesforceBaseURL().toExternalForm() + 
                            '/services/data/v52.0/analytics/reports/' + reportid);
        
        
        request.setMethod('PATCH');
        request.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionID());
        request.setHeader('Content-Type', 'application/json; charset=UTF-8');
        request.setHeader('Accept', 'application/json');  
        request.setBody(body);
        response= http.send(request);
        System.debug(response);
        return response;
    }
    
    public List<Vendor_Roster__c> getVendorRosterList() {
        return [select id, vendor__c, reportid__c from vendor_roster__c];
    }    
    
    public void upsertVendorRoster(Id vendorId, string reportId) {
        Vendor_Roster__c vr = new Vendor_Roster__c();
        vr.Vendor__c = vendorId;
        vr.Vendor_Id__c = vendorId;
        vr.ReportID__c = reportId;        
        
        Schema.SObjectField vendorIdField = Vendor_Roster__c.Fields.Vendor_Id__c;
        Database.UpsertResult ur = Database.upsert(vr, vendorIdField);
    }
    
}