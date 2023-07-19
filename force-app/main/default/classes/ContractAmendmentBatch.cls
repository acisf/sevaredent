/**
 * Created by cshah on Oct 28, 2020.
 */

public without sharing class ContractAmendmentBatch implements Database.Batchable<SObject>, Database.Stateful {

    String error = '';
    public Database.QueryLocator start(Database.BatchableContext batchableContext) {
        String query = 'SELECT Id, Name, Amendment_Number__c, Amendment_Effective_Date__c, Amendment_Description__c, Amendment_Status__c, Amendment_Type__c, Amendment_Contract_Fields__c, Contract__c, Executed__c, CreatedById FROM Amendment__c WHERE Executed__c = false AND isCancelled__c = false AND Amendment_Status__c = \'Approved\' AND Amendment_Effective_Date__c <= Today';

        System.debug(' ContractAmendmentBatch.start query: ' + JSON.serialize(query));
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext batchableContext, List<Amendment__c> amendments) {
        //System.debug(' ContractAmendmentBatch.execute amendments: ' + JSON.serialize(amendments));
        try {
            ContractAmendmentBatchUtility.populateAndUpdateContractForAmendments(amendments);
        } catch(Exception e) {
            error += (e.getMessage() + '<br>' + e.getStackTraceString() + '<br><br>');
            System.debug(' ContractAmendmentBatch.execute: ' + error);
        }
    }

    public void finish(Database.BatchableContext batchableContext) {
        System.debug(' ContractAmendmentBatch.finish ' + error);
        if(String.isNotEmpty(error)) {
            ContractAmendmentBatchUtility.sendExceptionEmailToAdmins(error);
        }
    }

}