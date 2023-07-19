/**
 * Service class for EligibleContractsListController.
 */ 
public with sharing class EligibleContractsList {

    /**
     * Returns a list of Contract Agreements that the current user has access to.
     * @return   list of Contract Agreements
     */ 
    public static List<APXT_Redlining__Contract_Agreement__c> getAvailableContracts() {
        return [
            SELECT
                Name,
                Sevaredent_Contract_Number__c,
                APXT_Redlining__Account__r.Name,
                APXT_Redlining__Effective_Date__c,
                APXT_Redlining__Expiration_Date__c,
                Category__c,
                Sub_Category__c
            FROM APXT_Redlining__Contract_Agreement__c
        ];
    }

    /**
     * Returns a list of Contract Agreements that the current user has 
     * access to. Contract Agreements filtered on fields Name, 
     * Sevaredent_Contract_Number__c, APXT_Redlining__Account__r.Name, 
     * Category__c, Sub_Category__c and sorted according to input parameters.
     * @param  searchTerm parameter to filter objects
     * @param  sortBy     parameter to sort objects
     * @return            list of Contract Agreements
     */ 
    public static List<APXT_Redlining__Contract_Agreement__c> getAvailableContracts(
        String searchTerm,
        String sortBy
    ) {
        String searchValue =
            '\'%' +
            String.escapeSingleQuotes(searchTerm) +
            '%\'';

        String selectFrom =
            'SELECT Name, Sevaredent_Contract_Number__c, APXT_Redlining__Account__r.Name, ' +
            'APXT_Redlining__Effective_Date__c, APXT_Redlining__Expiration_Date__c, Category__c, ' +
            'Sub_Category__c FROM APXT_Redlining__Contract_Agreement__c ';
        String conditionSearch = 
            'WHERE (Name LIKE ' +
            searchValue +
            ' OR Sevaredent_Contract_Number__c LIKE ' +
            searchValue +
            ' OR APXT_Redlining__Account__r.Name LIKE ' +
            searchValue +
            ' OR Category__c LIKE ' +
            searchValue +
            ' OR Sub_Category__c LIKE ' +
            searchValue +
            ') ';
        String order = sortBy != null
            ? 'ORDER BY ' + String.escapeSingleQuotes(sortBy)
            : '';

        return Database.query(
            selectFrom +
            conditionSearch +
            order
        );
    }
}