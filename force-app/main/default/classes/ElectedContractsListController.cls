/**
 * Apex controller for electedContractsList LWC component.
 */ 
public with sharing class ElectedContractsListController {

    /**
     * Returns a list of Contract Agreements that are implemented by the 
     * Account of the current user. Used to get a default list of objects.
     * Delegates work to the ElectedContractsList class.
     * @return   list of Contract Agreements
     */ 
    @AuraEnabled(cacheable=true)
    public static List<APXT_Redlining__Contract_Agreement__c> getContracts() {
        try {
            return ElectedContractsList.getAvailableContracts();
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * Returns filtered and sorted list of Contract Agreements that are 
     * implemented by the Account of the current user. Used to get a list 
     * of objects from a search field.
     * Delegates work to the ElectedContractsList class.
     * @param  searchTerm parameter to filter objects
     * @param  sortBy     parameter to sort objects
     * @return            list of Contract Agreements
     */ 
    @AuraEnabled(cacheable=true)
    public static List<APXT_Redlining__Contract_Agreement__c> searchContracts(
        String searchTerm,
        String sortBy
    ) {
        try {
            return ElectedContractsList.getAvailableContracts(
                searchTerm,
                sortBy
            );
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}