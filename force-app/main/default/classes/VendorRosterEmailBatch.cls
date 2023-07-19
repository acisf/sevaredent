global class VendorRosterEmailBatch implements Database.Batchable<sObject>,Database.AllowsCallouts, Database.Stateful {
    global list<sObject> lstScope;  
    global VendorRosterEmail vre = new VendorRosterEmail();
    global map<id,string> mapRoster = new map<id,string>();    
    
    global VendorRosterEmailBatch(list<sObject>lstContacts){
        lstScope=lstContacts; 
        list<Vendor_roster__c> lstVR = vre.getVendorRosterList();
        mapRoster = vre.getVendorReportMap(lstVR);
    }
    
    global Iterable<sObject> start(Database.BatchableContext BC){    
        return lstScope;
    }
    
    global void execute(Database.BatchableContext BC, List<sObject> scope){  
        
        List<Messaging.SingleEmailMessage> allmsg = new List<Messaging.SingleEmailMessage>();
        List<String> toAddr; 
        List<String> ccAddr; 
        
        OrgWideEmailAddress owea;        
        owea = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress WHERE DisplayName='Sevaredent Contract Coordinator'];  
        Messaging.SingleEmailMessage mail;
        Blob blobReport;
        Messaging.EmailFileAttachment efaReport;
        Date    d = Date.today();
        String year = String.valueOf(d.year());
        String month = String.valueOf(d.month()).leftPad(2,'0');
        String day = String.valueOf(d.day()).leftPad(2,'0');
        
        for(Sobject obj: scope) {
            
            Contact c = (Contact) obj;
            toAddr = new List<String>();  
            ccAddr = new List<string>();
            
            mail = new messaging.SingleEmailMessage();
            mail.setOrgWideEmailAddressId(owea.id);
            
            //production: uncomment this
            toAddr.add(c.Email);           
            mail.toaddresses = toAddr;
            ccAddr.add('peter.galazka@sevaredent.com');  
            mail.ccaddresses = ccAddr;
          
           //toAddr.add('douglas.vann@affordablecare.com'); 
           //toAddr.add('erica.walsh@affordablecare.com'); 
            mail.toaddresses = toAddr;
            
            //create blob  
            string accountid = c.accountId;
            string reportid = '';
            
            if(mapRoster.get(c.AccountId) != null)
                reportid = mapRoster.get(c.accountid);
            
            blobReport = vre.getVendorMemberReport(reportid).getBodyAsBlob();  
            
            efaReport = new Messaging.EmailFileAttachment();
            efaReport.setFileName('Member_Roster_' + year + month + day + '.xlsx');
            efaReport.setContentType('application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
            efaReport.setBody(blobReport); 
            
            mail.setWhatId(accountid);
            mail.setSubject('Member Report for ' + c.Account.Name + ' - ' + month + '/' + day + '/' + year); 
            mail.setUseSignature(false);
            mail.setBCCSender(false);
            mail.htmlbody = 'Hello,<br/><br/>';
            mail.htmlbody += 'Attached is this month’s Sevaredent member roster for ' + c.Account.Name + '. If you have any questions, please let me know.';
            mail.htmlbody += '<br/><br/>';
            mail.htmlbody += 'Thank you,<br/>';
            mail.htmlbody += 'Sevaredent Contract Coordinator<br/>';
            mail.htmlbody += 'Email: Contract-Coordinator@sevaredent.com<br/>';
            mail.htmlbody += '629 Davis Drive, Suite 300<br/>';
            mail.htmlbody += 'Morrisville, NC 27560<br/>';
            
            mail.setFileAttachments(new Messaging.EmailFileAttachment[]{efareport});
            mail.setSaveAsActivity(true); 
            
            system.debug(mail);
            
            if(toAddr.size() > 0)
                allmsg.add(mail);
        } 
        
        
        Messaging.sendEmail(allmsg);
    } 
        
    global void finish(Database.BatchableContext BC) {
        
    }
}