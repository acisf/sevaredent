global with sharing class VendorRosterBatch implements Database.Batchable<Sobject>,Database.Stateful,Database.AllowsCallouts{
    
    global list<sObject> lstScope; 
    global Map<String,Set<Id>> mapVendorMember; 
    
    global VendorRosterBatch(list<sObject>lstVendors,Map<String,Set<Id>> mapVM){
        lstScope=lstVendors;
        mapVendorMember = mapVM; 
    }
    
    global Iterable<sObject> start(Database.BatchableContext BC){    
        return lstScope;
    }
    
    global void execute(Database.BatchableContext BC, List<sObject> scope){ 
        Set<Id> vendors = new Set<Id>();
        
        for(SObject obj: scope) {
            
            Account vendor = (Account) obj;
            string vendorid = String.valueOf(vendor.id).left(15);
            set<Id> memberids = mapVendorMember.get(vendorid);
            
            VendorRoster vr = new VendorRoster();
            HttpResponse hr = vr.cloneTemplate(vendor.Name);
            string reportid = vr.getClonedReportId(hr); 
            vr.setVendorRosterFilter(reportid,memberids);
            if(vendors.add(vendor.id)) {
                vr.upsertVendorRoster(vendor.Id, reportId); 
            }
        }
        
    }
    
    global void finish(Database.BatchableContext BC){
        system.debug('Vendor Roster Batch completed');
    }
    
}