global with sharing class BatchVendorMemberInsertChildren implements Database.Batchable<Sobject>,Database.Stateful{
    
    global list<sObject> lstScope;  
    global List<Vendor_Member__c> lstParents;
    global Integer count = 0;
    set<string> vendormembers = new set<string>();
    
    global BatchVendorMemberInsertChildren(list<sObject>al, List<Vendor_Member__c> lstVendorMembers){
        lstScope=al;
        lstParents = lstVendorMembers;
    }
    
    global Iterable<sObject> start(Database.BatchableContext BC){    
        return lstScope;
    }
    
    global void execute(Database.BatchableContext BC, List<sObject> scope){ 
        
        List<Vendor_Member__c> lstChildren = new List<Vendor_Member__c>();
        
        System.debug('Batch size (num children): ' + scope.size());
        System.debug('Num parents: ' + lstParents.size());
        
        for(sObject obj:scope) {  //loop child accounts  
            account a = (account) obj;         
            for(Vendor_Member__c vm:lstParents) {   //loop vendor members (parents)
                if(a.Top_Parent_Id__c == vm.Member_Id__c) {   //child account's top parent is a vendor member
                    
                    string vendormember = '';
                    vendormember = String.valueOf(vm.Vendor__c).left(15) + String.valueOf(a.id).left(15);        
                    
                    if(vendormembers.add(vendormember)) {                        
                        Vendor_Member__c vmNew = new Vendor_Member__c();                    
                        vmNew.Vendor__c = vm.Vendor__c;
                        vmNew.Member__c = a.id;
                        vmNew.VendorIdMemberId__c = vendormember;
                        vmNew.Is_Parent__c = false;
                        System.debug('Adding vendor member ' );
                        System.debug(vmNew);
                        lstChildren.add(vmNew);   
                        count +=1;
                    }
                    
                }
            }
        }
        
        Schema.SObjectField f = Vendor_Member__c.Fields.VendorIdMemberId__c;
        Database.UpsertResult [] cr = Database.upsert(lstChildren, f, false);
        
    }
    
    global void finish(Database.BatchableContext BC){
        system.debug('BatchVendorMemberInsertChildren completed: ' + count + ' child accounts');
    }
    
}