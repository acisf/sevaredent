/**
 * Provides functionality to work with Contract_Implementations__c 
 * object from other classes.
 */ 
public with sharing class ContractImplementations {

    /**
     * When Contract Agreement APXT_Redlining__Status__c field value 
     * changed to “Amended”, then Contract_Implementations__c object 
     * records with lookup on amended contract agreement will update their 
     * lookup into new (amendment) Contract Agreement.
     * @param  oldContracts the map of Contract Agreement object records before update
     * @param  newContracts the map of Contract Agreement object records after update
     */ 
    public static void updateAmendedContracts(
        Map<Id, APXT_Redlining__Contract_Agreement__c> oldContracts,
        Map<Id, APXT_Redlining__Contract_Agreement__c> newContracts
    ) {
        Set<Id> amendedContractsIds = new Set<Id>();
        for (Id contractId : newContracts.keySet()) {
            
            if (
                oldContracts.get(contractId).APXT_Redlining__Status__c !=
                newContracts.get(contractId).APXT_Redlining__Status__c &&
                newContracts.get(contractId).APXT_Redlining__Status__c ==
                'Amended'
            ) {
                amendedContractsIds.add(contractId);
            }
        }

        if (!amendedContractsIds.isEmpty()) {
            Map<Id, Id> activeByParentContractIds = mapActiveByParentContractIds(amendedContractsIds);
            updateImplementations(amendedContractsIds, activeByParentContractIds);
        }
    }

    /**
     * Maps new Contract Agreement Id by old Contract Agreement
     * @param  amendedContractsIds list of amemded Contrac Agreement Ids
     * @return                     map of new Contract Agreement Id by old Contract Agreement Id
     */
    private static Map<Id,Id> mapActiveByParentContractIds(Set<Id> amendedContractsIds) {
        Map<Id, Id> activeByParentContractIds = new Map<Id, Id>();
        for (APXT_Redlining__Contract_Agreement__c activeContract : [
            SELECT Record_Id__c, APXT_Redlining__Contract_Agreement_Family_Parent__c
            FROM APXT_Redlining__Contract_Agreement__c
            WHERE
                APXT_Redlining__Contract_Agreement_Family_Parent__c IN :amendedContractsIds
                AND (APXT_Redlining__Status__c = 'Activated' OR APXT_Redlining__Status__c = 'Being Amended')
        ]) {
            activeByParentContractIds.put(
                activeContract.APXT_Redlining__Contract_Agreement_Family_Parent__c,
                activeContract.Record_Id__c
            );
        }

        return activeByParentContractIds;
    }

    /**
     * Update Contract_Implementations__c.Contract_Agreement__c field with a new value
     * @param  amendedContractsIds       list of amemded Contrac Agreement Ids
     * @param  activeByParentContractIds map of new Contract Agreement Id by old Contract Agreement Id
     */ 
    private static void updateImplementations(
        Set<Id> amendedContractsIds, Map<Id, Id> activeByParentContractIds
    ) {
        
        List<Contract_Implementations__c> implementationsToUpdate = [
            SELECT Contract_Agreement__c
            FROM Contract_Implementations__c
            WHERE Contract_Agreement__c IN :amendedContractsIds
        ];
        for (Contract_Implementations__c impl : implementationsToUpdate) {
            impl.Contract_Agreement__c = activeByParentContractIds.get(
                impl.Contract_Agreement__c
            );
        }

        update implementationsToUpdate;
    }
}