global class ContractAmendmentCancelledBatchApex implements Database.Batchable<sObject>, Database.Stateful{
    //Exception[] errors = new Exception[0];
    String[] errorMsgs = new String[0];
    public integer count = 0;
    List<APXT_Redlining__Contract_Agreement__c> listContractAgreement = new List<APXT_Redlining__Contract_Agreement__c>();
    Set<Id> AmendmentIds = new Set<Id>();
   
    global ContractAmendmentCancelledBatchApex(Set<Id> setAmendmentId, List<APXT_Redlining__Contract_Agreement__c> ListExpiredAmendment) {
        AmendmentIds = setAmendmentId;
        listContractAgreement = ListExpiredAmendment;
    }

    global Database.QueryLocator start(Database.BatchableContext BC){
        
        return Database.getQueryLocator([Select Id, Contract_Agreement__c from Item_Pricing__c where Contract_Agreement__c IN: AmendmentIds]);
    }

    global void execute(Database.BatchableContext BC, List<Item_Pricing__c> scope) {

        Map<Id, List<Item_Pricing__c>> mapamendmentIdItemPricingRecords = new Map<Id, List<Item_Pricing__c>>();
        List<Item_Pricing__c> ListItemPricingUpdate = new List<Item_Pricing__c>();

        if(scope.size()>0 && !scope.isEmpty()){

            for(Item_Pricing__c itemPrice : scope){
                if(mapamendmentIdItemPricingRecords.containsKey(itemPrice.Contract_Agreement__c)){
                    mapamendmentIdItemPricingRecords.get(itemPrice.Contract_Agreement__c).add(itemPrice);
                }else{
                    mapamendmentIdItemPricingRecords.put(itemPrice.Contract_Agreement__c, new List<Item_Pricing__c>{itemPrice});
                }
            }
            system.debug('mapamendmentIdItemPricingRecords: '+mapamendmentIdItemPricingRecords);
            for(APXT_Redlining__Contract_Agreement__c conAgree : listContractAgreement){
                if(mapamendmentIdItemPricingRecords.get(conAgree.Id) != null){
                for(Item_Pricing__c itemPrice : mapamendmentIdItemPricingRecords.get(conAgree.Id)){
                    itemPrice.Contract_Agreement__c = conAgree.APXT_Redlining__Contract_Agreement_Family_Parent__c;
                    ListItemPricingUpdate.add(itemPrice);
                }
            }
            }
            system.debug('ListItemPricingUpdate:'+ListItemPricingUpdate);
            if(!ListItemPricingUpdate.isEmpty()){
                //try{
                    database.saveresult[] ds =  Database.update(ListItemPricingUpdate,false);
                    //update ListItemPricingUpdate;
                    for(database.SaveResult d : ds){
                        if(d.issuccess()){
                            count++;
                        }else{
                            errorMsgs.add('Item Price record'+ListItemPricingUpdate[count].Id+', Error Message: '+ d.getErrors()[0].getMessage());
                            count++;
                        }
                        
                   }
                    
               /* }catch(DmlException e){
                    system.debug('Error : '+e.getMessage());
                    errors.add(e);
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
        mail.setSenderDisplayName('Contract Amendment Cancelled Batch');
        mail.setSubject('Item Pricing Records moved by Batch');
        String bodyText='Total Job Items ' + apexJob.TotalJobItems + ', Number of records processed ' + count + ' with '+ apexJob.NumberOfErrors + ' failures.\n';
        bodyText += 'Number of Error Messages ' + errorMsgs.size() + '\n';
        bodyText += 'Error Message' + String.join(errorMsgs, '\n');
        mail.setPlainTextBody(bodyText);
       // mail.setPlainTextBody('The batch Apex job processed ' + apexJob.TotalJobItems + ' batches with '+ apexJob.NumberOfErrors + ' failures.');
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
}