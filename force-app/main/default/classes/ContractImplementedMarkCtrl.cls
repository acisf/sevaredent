/**
 * Apex controller for contractImplementedMark LWC component.
 */ 
public with sharing class ContractImplementedMarkCtrl {

    /**
     * Returns Contract Implementations for current User and specified 
     * Contract Agreement, where Status__c field value is “Implemented” or 
     * “ Partially Implemented”.
     * @param  contractId Id of Contract Agreement object record
     * @return            list of Contract Implementations
     */ 
    @AuraEnabled(cacheable=true)
    public static List<Contract_Implementations__c> getImplementations(String contractId) {
        try {
            Id cId = contractId;
            return [
                SELECT Effective_Date__c
                FROM Contract_Implementations__c
                WHERE
                    Account__c IN (
                        SELECT AccountId
                        FROM User
                        WHERE AccountId != NULL AND Id = :UserInfo.getUserId()
                    )
                    AND Contract_Agreement__c = :cId
                    AND Status__c IN ('Implemented', 'Partially Implemented')
                    ORDER BY Effective_Date__c ASC
            ];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}