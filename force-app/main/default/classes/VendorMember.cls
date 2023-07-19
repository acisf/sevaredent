public class VendorMember {
    
    public void insertParents() {
        
        List<Contract_Implementations__c> lstCI;
        lstCI = [SELECT Id, Name, Account__c, Status__c, Contract_Agreement__c, Vendor_ID__c
                FROM Contract_Implementations__c
                WHERE 
                 Account__r.Status__c = 'Active'
                 AND Contract_Agreement__c != null
                AND (Status__c =: 'Implemented'
                     OR Status__c =: 'Partially Implemented')];
        
         Id batchInstanceId = Database.executeBatch(new BatchVendorMemberInsertParents(lstCI));         
    }
    
    public void insertChildren() {
        
        List<Vendor_Member__c> lstVM;
        List<Account> lstAccount;
        Set<string> memberids = new set<string>();
        
        lstVM = [SELECT VendorIdMemberId__c, Vendor__c,Member__c, Member_Id__c FROM Vendor_Member__c];
        
        for(Vendor_Member__c vm:lstVM) {
            if(vm.Member__c != null) {
            	memberids.add(vm.Member_Id__c);
            }
        }
        
        lstAccount = [SELECT Id, Top_Parent_Id__c FROM Account WHERE Top_Parent_Id__c IN:memberids AND Status__c = 'Active'];
        
        system.debug('CALLING BATCH INSERT CHILDREN');
        system.debug('Got ' + lstVM.size() + ' vendor members');
        system.debug('Got ' + lstAccount.size() + ' child accounts');
        
        BatchVendorMemberInsertChildren bc = new BatchVendorMemberInsertChildren(lstAccount,lstVM);
         Id batchInstanceId = Database.executeBatch( bc);         
    }
    
    public void deleteRoster() {
		List<Vendor_Member__c> lstVM;
        lstVM = [select id, name, VendorIdMemberId__c,Vendor__c,Member__c 
                       from Vendor_Member__c];
        
        Id batchInstanceId = Database.executeBatch(new BatchVendorMemberDelete(lstVM)); 
    }
    
    public void sendEmail(Boolean isDebug) { 
        
        List<Vendor_Member__c> lstVM;
        List<Account> lstVendors;
        Set<Id> vendors = new Set<Id>();
        
        lstVM = [select id, name, VendorIdMemberId__c,Vendor__c,Member__c 
                       from Vendor_Member__c order by name  ];
        
        for(Vendor_Member__c vm: lstVM) {
            vendors.add(vm.Vendor__c);
        }
        
        if(isDebug){
        	lstVendors = [select id, name from Account where id in: vendors order by name]; 
        } else {
            lstVendors = [select id, name from Account where id in: vendors order by name]; 
        }
        
        Id batchInstanceId = Database.executeBatch(new BatchVendorMemberSendEmail(lstVendors, isDebug),10); 
    }
     
    
}