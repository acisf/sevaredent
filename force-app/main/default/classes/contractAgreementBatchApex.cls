global class contractAgreementBatchApex implements Database.Batchable<sObject>, Database.Stateful{
    String[] errorMsgs = new String[0];
    public integer count = 0;
    List<APXT_Redlining__Contract_Agreement__c> listContractAgreement = new List<APXT_Redlining__Contract_Agreement__c>();
    Set<Id> AmendmentParentId = new Set<Id>();
   
    public contractAgreementBatchApex(Set<Id> setParentId, List<APXT_Redlining__Contract_Agreement__c> ListNonExpiredAmendment) {
        AmendmentParentId = setParentId;
        listContractAgreement = ListNonExpiredAmendment;
    }

    global Database.QueryLocator start(Database.BatchableContext BC){
        
        return Database.getQueryLocator([Select Id, Contract_Agreement__c from Item_Pricing__c where Contract_Agreement__c IN: AmendmentParentId]);
    }

    global void execute(Database.BatchableContext BC, List<Item_Pricing__c> scope) { 

       
List<Item_Pricing__c> ListItemPricingUpdate = new List<Item_Pricing__c>();
    if(scope.size()>0 && !scope.isEmpty()){
    
    
    Map<Id, List<Item_Pricing__c>> mapParentIdItemPricingRecords = new Map<Id, List<Item_Pricing__c>>(); 
    
            for(Item_Pricing__c itemPrice : scope){
                if(mapParentIdItemPricingRecords.containsKey(itemPrice.Contract_Agreement__c)){
                mapParentIdItemPricingRecords.get(itemPrice.Contract_Agreement__c).add(itemPrice);
                }else{
                    mapParentIdItemPricingRecords.put(itemPrice.Contract_Agreement__c, new List<Item_Pricing__c>{itemPrice});
                }
            }
            system.debug('mapParentIdItemPricingRecords: '+mapParentIdItemPricingRecords);
            for(APXT_Redlining__Contract_Agreement__c conAgree : listContractAgreement){
                if(mapParentIdItemPricingRecords.get(conAgree.APXT_Redlining__Contract_Agreement_Family_Parent__c) != null){
                for(Item_Pricing__c itemPrice : mapParentIdItemPricingRecords.get(conAgree.APXT_Redlining__Contract_Agreement_Family_Parent__c)){
                    itemPrice.Contract_Agreement__c = conAgree.Id;
                    ListItemPricingUpdate.add(itemPrice);
                }
            }
            }
            if(!ListItemPricingUpdate.isEmpty()){
                //try{
                    database.saveresult[] ds =  Database.update(ListItemPricingUpdate,false);
                    for(database.SaveResult d : ds){
                        if(d.issuccess()){
                            count++;
                        }else{
                            errorMsgs.add('Item Price record'+ListItemPricingUpdate[count].Id+', Error Message: '+ d.getErrors()[0].getMessage());
                            count++;
                        }
                        
                   }
                    //update ListItemPricingUpdate;
                /*}catch(DmlException e){
                    system.debug('Error : '+e.getMessage());
                }*/
}
}
    }

    global void finish(Database.BatchableContext BC)
    {
        AsyncApexJob apexJob = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email
                                FROM AsyncApexJob WHERE Id =: BC.getJobId()];

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddress = new String[] {apexJob.CreatedBy.Email};
        system.debug('apexJob.CreatedBy.Email : '+apexJob.CreatedBy.Email);
        mail.setToAddresses(toAddress);
        mail.setSenderDisplayName('Contract Agreement Batch Apex');
        mail.setSubject('Item Pricing Records moved by Batch');
        String bodyText='Total Job Items ' + apexJob.TotalJobItems + ', Number of records processed ' + count + ' with '+ apexJob.NumberOfErrors + ' failures.\n';
        bodyText += 'Number of Error Messages ' + errorMsgs.size() + '\n';
        bodyText += 'Error Message' + String.join(errorMsgs, '\n');
        mail.setPlainTextBody(bodyText);
        //mail.setPlainTextBody('The batch Apex job processed ' + apexJob.TotalJobItems + ' batches with '+ apexJob.NumberOfErrors + ' failures.');
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
}