public class NotificationUtil {
    
    /* example, run in this order     
	 NotificationUtil.updateRevenueTrackingContacts('2021',10000);
	 NotificationUtil.createAttachments('2021',10000);
	 NotificationUtil.sendNotifications('2021',100);	 
	*/

    
    //updates primary contacts in revenue tracking
    @future
    public static void updateRevenueTrackingContacts(String fiscalyear, integer intLimit) {
        Set<id> accountids = new Set<Id>();
        Map<id,id> mapcontacts = new Map<id,id>();
        
        //get revenue tracking
        List<Revenue_Tracking__c> lstRT  = getRevenueTrackingForUpdate(fiscalyear, intLimit);
        
        //set of member accounts
        for(Revenue_Tracking__c rt: lstRT) {
            accountids.add(rt.GPO_Member_Account__c);
        }
        
        //map of primary contacts
        List<AccountContactRelation> lstPC = getActivePrimaryContacts(accountids);
        for(AccountContactRelation r: lstPC) {
            if(mapcontacts.get(r.AccountId) == null) {
                mapcontacts.put(r.AccountId,r.ContactId);
            }
        }
        
        for(Revenue_Tracking__c rt:lstRT) {
            if(mapcontacts.get(rt.GPO_Member_Account__c) != null) {
                rt.Primary_Contact__c = mapcontacts.get(rt.GPO_Member_Account__c);
            }
        }
        
       update lstRT;
        
    }
    
    //primary contacts for given accounts
    private static List<AccountContactRelation> getActivePrimaryContacts(Set<id> accountids) {
        return [SELECT Id,AccountId, ContactId, Primary_Contact__c, Inactive__c, IsActive, StartDate, EndDate 
                FROM AccountContactRelation
                WHERE AccountId IN: accountids
                AND Primary_Contact__c =: true 
                AND Inactive__c =: false
                ORDER BY ContactId]; 
    }
    
    
    //revenue tracking objects for given year
    private static List<Revenue_Tracking__c> getRevenueTracking(String fiscalyear) {
        return [SELECT Id,Name,Contract_Name__c,Location_Id__c, Amount__c, Start_Date__c, 
                End_Date__c, GPO_Member_Account__c,GPO_Member_Account__r.Name, CA_Vendor_Contract__c, Primary_Contact__c, Month__c, 
                CA_Vendor_Contract_Name__c, CA_Vendor_Name__c,Quarter__c,Units__c, Volume__c,
                Sevaredent_ID__c, Rebate__c, Top_Parent_Account__c 
                FROM Revenue_Tracking__c
                WHERE Year__c =: (Decimal.valueOf(fiscalyear))
               ];       
    }

        //revenue tracking objects for given year
        private static List<Revenue_Tracking__c> getRevenueTrackingForAttachments(String fiscalyear, Integer intLimit) {
            return [SELECT Id,Name,Contract_Name__c,Location_Id__c, Amount__c, Start_Date__c, 
                    End_Date__c, GPO_Member_Account__c,GPO_Member_Account__r.Name, CA_Vendor_Contract__c, Primary_Contact__c, Month__c, 
                    CA_Vendor_Contract_Name__c, CA_Vendor_Name__c,Quarter__c,Units__c, Volume__c,
                    Sevaredent_ID__c, Rebate__c, Top_Parent_Account__c 
                    FROM Revenue_Tracking__c
                    WHERE Year__c =: (Decimal.valueOf(fiscalyear))
                    AND Attachment_Id__c = null
                    LIMIT :intLimit
                   ];       
        }
    
        //revenue tracking objects for given year
    private static List<Revenue_Tracking__c> getRevenueTrackingForUpdate(string fiscalyear, Integer intLimit) {
        return [SELECT Id,Name,Contract_Name__c,Location_Id__c, Amount__c, Start_Date__c, 
                End_Date__c, GPO_Member_Account__c, CA_Vendor_Contract__c, Primary_Contact__c, Month__c, 
                CA_Vendor_Contract_Name__c, CA_Vendor_Name__c,Quarter__c,Units__c, Volume__c,
                Sevaredent_ID__c, Rebate__c, Top_Parent_Account__c 
                FROM Revenue_Tracking__c
                WHERE Year__c =: Decimal.valueOf(fiscalyear) AND
                Primary_Contact__c = null 
                LIMIT :intLimit
               ];       
    }
    
    //annual notification tracking objects for given year
    private static List<annualnotificationtracking__c> getNotificationTracking(string fiscalyear) {
        return [ select id, gpo_member_account__c, attachment_Id__c,date_sent__c,primary_contact__c,
                primary_contact__r.Email, gpo_member_account__r.Name
                from annualnotificationtracking__c 
                where date_sent__c =: null and 
                Fiscal_Year__c =: fiscalyear
                ORDER BY primary_contact__r.Email];
    }
    
  
    //creates attachments and tracking
    @future(callout=true)
    public static void createAttachments(String fiscalyear, Integer intLimit) {
        
        List<annualnotificationtracking__c> lstTracking = new List<annualnotificationtracking__c>();
        List<Attachment> lstPDFs = new List<Attachment>();
        Map<Id,Id> mapAttachments = new Map<Id,Id>();
        Set<Id> accounts = new Set<Id>(); 
        List<Revenue_Tracking__c> revenueTrackingList = getRevenueTrackingForAttachments(fiscalyear, intLimit); 
        
        for(Revenue_Tracking__c rt: revenueTrackingList) { 
            if(accounts.add(rt.GPO_Member_Account__c)) {
                annualnotificationtracking__c ant = new annualnotificationtracking__c();
                ant.gpo_member_account__c = rt.GPO_Member_Account__c;
                ant.primary_contact__c = rt.Primary_Contact__c;
                ant.attachment_Id__c = null;
                ant.date_sent__c = null;
                ant.fiscal_year__c = String.valueOf(fiscalyear);
                lstTracking.add(ant);  
                
                //create pdf
                Attachment a = createPDF(rt.GPO_Member_Account__c, rt.GPO_Member_Account__r.Name, String.valueOf(fiscalyear));
                lstPDFs.add(a);                
            }
        }
        
        insert lstPDFs;
        
        for(Attachment a:lstPDFs) {
            mapAttachments.put(a.parentid,a.id);
        }
        
        for(annualnotificationtracking__c ant: lstTracking) {
            if(mapAttachments.get(ant.GPO_Member_Account__c) != null) {
                ant.attachment_Id__c = mapAttachments.get(ant.GPO_Member_Account__c); 
            }            
        }
        
        insert lstTracking;   

        for(Revenue_Tracking__c rt: revenueTrackingList) {
            if(mapAttachments.get(rt.GPO_Member_Account__c) != null) {
                rt.attachment_Id__c = mapAttachments.get(rt.GPO_Member_Account__c); 
            }            
        }

        update revenueTrackingList;        
        
    }
    
    //creates pdf
    
    private static Attachment createPDF(Id accountId, String accountName, String fy ) {
        Blob body;
        PageReference pdf = Page.annualNotification; 
        pdf.getParameters().put('memberId',accountId);
        Attachment attach = new Attachment();         
        
        try { 
            body = pdf.getContent();
        } catch (Exception e) {
            body = Blob.valueOf('error');
        }
        
        attach.Body = body; 
        attach.Name = 'AnnualReport' + fy + ' - ' + accountName + '.pdf';
        attach.IsPrivate = false; 
        attach.ParentId = accountid;
        return attach; 
    }
    
    @future
    public static void sendNotifications(String fiscalyear, Integer upperlimit) {
        
        List<Messaging.SingleEmailMessage> allmsg= new List<Messaging.SingleEmailMessage>();  
        List<EmailTemplate> lstTemplates;       
        OrgWideEmailAddress[] owea; 
        Set<id> attachmentids = new Set<id>();    
        Set<string> contacts = new Set<String>();
        Map<id,id[]> contactAccounts = new Map<id,id[]>();        
        Map<id,Attachment> accountattachment = new Map<id,attachment>();  
        Messaging.EmailFileAttachment efa;
        Messaging.SingleEmailMessage mail;
        List<Messaging.EmailFileAttachment> lstEFA;
        List<String> ccAddr = new List<String>();
        
        //templates
        lstTemplates = [Select id,name from EmailTemplate where name like 'Annual Notification%'];    
        owea = [select Id from OrgWideEmailAddress where Address = 'contract-coordinator@sevaredent.com'];
        ccAddr.add('contract-coordinator@sevaredent.com');
        
        //attachment set
        List<annualnotificationtracking__c> lstTracking = [select id, gpo_member_account__c, attachment_Id__c,date_sent__c,primary_contact__c,
                primary_contact__r.Email, gpo_member_account__r.Name
                from annualnotificationtracking__c 
                where date_sent__c =: null and 
                Fiscal_Year__c =: fiscalyear
                ORDER BY primary_contact__r.Email                                                          
                Limit: upperlimit];
        
        System.debug('lstTracking');
        System.debug(lstTracking);
        
        for(annualnotificationtracking__c ant:lstTracking) {
            //ant.debug__c = '';
            attachmentids.add(ant.attachment_Id__c);  
        }
        
        update lstTracking;
        
         System.debug('lstTracking');
        System.debug(lstTracking);
        
        //attachment map
        List<Attachment> lstAttachments = [select id, parentid,contenttype, name, body 
                                           from attachment where id in:attachmentids]; 
        for(Attachment a: lstAttachments) {
            accountattachment.put(a.ParentId, a);
        } 
        
        System.debug('accountattachment');
        System.debug(accountattachment);
        
        //notice tracking loop
        Integer x = 0;
        for(annualnotificationtracking__c ant: lstTracking) {  
            system.debug('tracking loop');
            if(contacts.add(ant.Primary_Contact__r.Email)) {  //once per contact
                mail = new Messaging.SingleEmailMessage();  //one email
                lstEFA = new  List< Messaging.EmailFileAttachment>();  //list of attachments               
                mail.setUseSignature(false); 
                mail.setCcAddresses(ccAddr);
                mail.setBCCSender(false);
                mail.setWhatId(ant.Id);                  
                mail.setTargetObjectId(ant.Primary_Contact__c);          
                mail.setTemplateId(lstTemplates.get(0).id);               
                mail.setOrgWideEmailAddressId(owea.get(0).Id);
                
                for(Integer y = lstTracking.size() - 1 ; y >= x ; y--) {  //scan the list for other attachments

                    if(ant.Primary_Contact__r.Email == lstTracking[y].Primary_Contact__r.Email) {
                    
                        system.debug('email match' + ant.Primary_Contact__r.Email);
                    
                        efa = new Messaging.EmailFileAttachment();

                        if(accountattachment.get(lstTracking[y].GPO_Member_Account__c)!=null) {
                           
                            Attachment a = accountattachment.get(lstTracking[y].GPO_Member_Account__c);    
                            
                            efa.setBody(a.Body);
                            efa.setFileName(a.Name);   
                            lstEFA.add(efa);                        
                            lstTracking[y].Date_Sent__c = DateTime.now();
                        } 
                    }
                }
                
                //attachments              
                mail.setFileAttachments(lstEFA); 

                if(ant.Primary_Contact__r.Email != '') {
                	allmsg.add(mail);   
                } else
                {
                    system.debug('No email for annual tracking id ' + ant.id);
                }
            }
            
            x++;
        }
        
        //send emails
        System.debug('Messages sent: ' + allmsg.size());
        Messaging.sendEmail(allmsg);
        update lstTracking;
    }
}