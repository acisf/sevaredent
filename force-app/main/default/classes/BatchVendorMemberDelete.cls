global with sharing class BatchVendorMemberDelete implements Database.Batchable<Sobject>,Database.Stateful{
    
    global list<sObject> accList;
    global BatchVendorMemberDelete(list<sObject>al){
        accList=al;
    }
    
    global Iterable<sObject> start(Database.BatchableContext BC){
        return accList;
    }
    global void execute(Database.BatchableContext BC, List<sObject> scope){                
        delete scope;
    }
    global void finish(Database.BatchableContext BC){
        system.debug('BatchVendorMemberDelete completed');
    }
    
}