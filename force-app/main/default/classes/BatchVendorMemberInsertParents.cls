global with sharing class  BatchVendorMemberInsertParents implements Database.Batchable<Sobject>,Database.Stateful{
    
    global list<sObject> lstScope; 
    global set<string> vendormembers = new set<string>();
    
    global BatchVendorMemberInsertParents(list<sObject> ci){
        lstScope= ci;
    }
    
    global Iterable<sObject> start(Database.BatchableContext BC){ 
        return lstScope;
    }
    global void execute(Database.BatchableContext BC, List<sObject> scope){        
        
        List<Vendor_Member__c> lstVM = new List<Vendor_Member__c>();
        
        for(SObject obj:scope) {
            Contract_Implementations__c ci = (Contract_Implementations__c) obj; 
            
            string vendormember = '';
            vendormember = String.valueOf(ci.Vendor_ID__c).left(15) + String.valueOf(ci.Account__c).left(15);  
            
            if(vendormembers.add(vendormember)) {
                Vendor_Member__c vm = new Vendor_Member__c();
                vm.Vendor__c = ci.Vendor_ID__c;
                vm.Member__c = ci.Account__c;
                vm.VendorIdMemberId__c = vendormember;
                vm.is_Parent__c = true;
                lstVM.add(vm);
            }
        }   
        
        Schema.SObjectField f = Vendor_Member__c.Fields.VendorIdMemberId__c;
        Database.UpsertResult [] cr = Database.upsert(lstVM, f, false);
        
    }
    global void finish(Database.BatchableContext BC){
        system.debug('BatchVendorMemberInsertParents completed');
    }
    
}