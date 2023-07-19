global with sharing  class BatchVendorMemberSendEmail implements Database.Batchable<Sobject>,Database.Stateful,Database.AllowsCallouts{ 
    
    global list<sObject> lstScope; 
    global boolean debug;
    
    global BatchVendorMemberSendEmail(list<sObject> vendors, boolean debugMode){
        lstScope= vendors;
        debug = debugMode;
    }
    
    global Iterable<sObject> start(Database.BatchableContext BC){ 
        return lstScope;
    }
    
    global void execute(Database.BatchableContext BC, List<sObject> scope){    
        List<Messaging.SingleEmailMessage> allmsg = new list<Messaging.SingleEmailMessage>(); 
        List<contact> lstContacts;
        Set<id> vendorids = new set<id>(); 
        List<String> toAddr; 
        List<String> ccAddr; 
        
        OrgWideEmailAddress owea;        
        owea = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress WHERE DisplayName='Sevaredent Contract Coordinator'];  

        
        for(sobject s: scope) {
            account a = (account) s;
            vendorids.add(a.id); 
        }
        
        System.debug('Got vendors: ' + vendorids.size());
        
        lstContacts = [select id,firstname,lastname,email,accountid, account.name
                       from contact
                       where accountid in: vendorids
                       and Report_Distribution__c = 'Roster'
                       and email != ''];
        
        System.debug('Got contacts ' + lstContacts.size());
        
        for(Contact c: lstContacts) {
            
        	toAddr = new List<String>();  
        	ccAddr = new List<string>();
            httpresponse r = setVendorMemberReportFilter(c.AccountId);
            Messaging.SingleEmailMessage msg =  getMsg(c);
            
            if ( owea != null) {
                msg.setOrgWideEmailAddressId(owea.id);
            }
            
            if(debug) {
                msg.whatid   = c.AccountId;
                toAddr.add('erica.walsh@sevaredent.com');
                ccAddr.add('jai.jamerson@sevaredent.com'); 
                msg.toaddresses = toAddr;
                msg.ccaddresses = ccAddr;
            }
            else {
                msg.whatid   = c.AccountId;
                toAddr.add(c.Email);
                msg.toaddresses = toAddr;
                ccAddr.add('jai.jamerson@sevaredent.com');  
                msg.ccaddresses = ccAddr;
            }      
            
            if(toAddr.size() > 0)
                allmsg.add(msg);
            
            System.debug ('Num messages' + allmsg.size());
        }
        
        Messaging.sendEmail(allmsg,true);
    }
    
    global void finish(Database.BatchableContext BC){
        
        system.debug('BatchVendorMemberSendEmail completed');
    }
    
    public HttpResponse setVendorMemberReportFilter(string vendorid) {
        
        Http http = new Http();
        HttpRequest request;
        HttpResponse  response;
        
        string body = '{   "reportMetadata" : {    "reportFilters" : [ {      "column" : "Vendor_Member__c.Vendor__c.Id",';
        body += '"filterType" : "fieldValue", "isRunPageEditable" : true,  "operator" : "equals", "value" : "' + vendorid + '"   } ]}}';
        
        request = new HttpRequest();
        
        if(debug) {
        request.setEndpoint(System.URL.getSalesforceBaseURL().toExternalForm() + 
                            '/services/data/v52.0/analytics/reports/' + '00O3h0000046D02EAE');
        } else {
            request.setEndpoint(System.URL.getSalesforceBaseURL().toExternalForm() + 
                            '/services/data/v52.0/analytics/reports/' + '00O3h0000046D02EAE');
        }
        
        request.setMethod('PATCH');
        request.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionID());
        request.setHeader('Content-Type', 'application/json; charset=UTF-8');
        request.setHeader('Accept', 'application/json');  
        request.setBody(body);
        response= http.send(request);
        return response;
    }
    
    public HttpResponse getVendorMemberReport(string vendorid) {
        
        Http http = new Http();
        HttpRequest request;
        HttpResponse  response; 
        
        request = new HttpRequest();
        request.setTimeout(120000);  
        
        if(debug) {
        	request.setEndpoint(System.URL.getSalesforceBaseURL().toExternalForm() + 
                            '/services/data/v52.0/analytics/reports/' + '00O3h0000046D02EAE');
        } else {
            request.setEndpoint(System.URL.getSalesforceBaseURL().toExternalForm() + 
                            '/services/data/v52.0/analytics/reports/' + '00O3h0000046D02EAE');
        }
        
        request.setMethod('GET');  
        request.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionID()); 
        request.setHeader('Accept', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'); 
        response= http.send(request);
        return response;
    }
    
    
    public Messaging.SingleEmailMessage getMsg(contact c) {   
        Messaging.SingleEmailMessage mail;
        // try {
        Blob blobReport;
        Messaging.EmailFileAttachment efaReport;
        Date d = Date.today();
        String year = String.valueOf(d.year());
        String month = String.valueOf(d.month());
        String day = String.valueOf(d.day());
        
        System.debug('Debug mode is ' + debug);
        
        //create blob / email attachment from httpresponse 
        string accountid = c.accountId;
        blobReport = getVendorMemberReport(accountid).getBodyAsBlob();         
        efaReport = new Messaging.EmailFileAttachment();
        efaReport.setFileName('Member_Roster_' + year + month + day + '.xlsx');
        efaReport.setContentType('application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
        efaReport.setBody(blobReport); 
        
        System.debug('Blob report ');
        system.debug(blobReport);
        
        //instantiate email object
        mail = new Messaging.SingleEmailMessage(); 
        mail.setSubject('Member Report for ' + c.Account.Name + ' - ' + month + '/' + day + '/' + year); 
  
        mail.setUseSignature(false);
        mail.setBCCSender(false);
        
        mail.htmlbody = 'Hello,<br/><br/>';
        mail.htmlbody += 'Attached is this month’s Sevaredent member roster for ' + c.Account.Name + '. If you have any questions, then please let me know.';
        mail.htmlbody += '<br/><br/>';
        mail.htmlbody += 'Jai Jamerson<br/>';
        mail.htmlbody += 'Contract Coordinator<br/>';
        mail.htmlbody += 'Email: jai.jamerson@sevaredent.com<br/>';
        mail.htmlbody += '629 Davis Drive, Suite 300<br/>';
        mail.htmlbody += 'Morrisville, NC 27560<br/>';
           
        
        mail.setFileAttachments(new Messaging.EmailFileAttachment[]{efareport});
        mail.setSaveAsActivity(true); 
        
        System.debug('Mail');
        system.debug(mail);
        
        // }        
        // catch (Exception e) {
        //            system.debug('Error getting email');
        //          system.debug(e);
        //   }
        
        return mail;
        
    }
}