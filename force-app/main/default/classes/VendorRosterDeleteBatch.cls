global class VendorRosterDeleteBatch implements Database.Batchable<sObject>,Database.AllowsCallouts, Database.Stateful {
    global list<sObject> lstScope;   
    
    global VendorRosterDeleteBatch(list<sObject> lstVR){
        lstScope=lstVR;  
    }
    
    global Iterable<sObject> start(Database.BatchableContext BC){    
        return lstScope;
    }
    
    global void execute(Database.BatchableContext BC, List<sObject> scope){  
                
        VendorRoster vr = new VendorRoster();
        
        for(Sobject obj: scope) {
            Vendor_Roster__c objVR = (Vendor_Roster__c) obj;
            vr.deleteReport(objVR.ReportID__c);
         } 
    } 
    global void finish(Database.BatchableContext BC) {
        delete lstScope;
        System.debug('Batch delete reports finished');
    }
}