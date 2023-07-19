/**
 * Handler for Contract Agreement trigger. Provides functionality for sharing 
 * Contract Agreement object records and related objects to 
 * certain community members. Includes methods for some functionality 
 * on the amendment process.
 * Functions of this handler does not contain logic itself, but calls 
 * methods from other classes.
 */
public with sharing class AC_ContractAgreementTriggerHandler {

    /**
     * Called from trigger when Contract Agreement is created. Delegates 
     * work to the ContractSharing class.
     * @param  contracts the list of new Contract Agreements
     */ 
    public static void shareContracts(
        List<APXT_Redlining__Contract_Agreement__c> contracts
    ) {
        ContractSharing.shareOnCreate(contracts);
    }

    /**
     * Called from trigger when Contract Agreement is updated. Delegates 
     * work to the ContractSharing class.
     * @param  oldContracts the map of new Contract Agreements before update
     * @param  newContracts the map of new Contract Agreements after update
     */
    public static void shareContracts(
        Map<Id, APXT_Redlining__Contract_Agreement__c> oldContracts,
        Map<Id, APXT_Redlining__Contract_Agreement__c> newContracts
    ) {
        ContractSharing.shareOnUpdate(oldContracts, newContracts);
    }

    /**
     * Called from trigger when Contract Agreement is updated. Delegates 
     * work to the ContractImplementations class.
     * @param  oldContracts the map of new Contract Agreements before update
     * @param  newContracts the map of new Contract Agreements after update
     */ 
    public static void updateAmendedContractsOnImplementations(
        Map<Id, APXT_Redlining__Contract_Agreement__c> oldContracts,
        Map<Id, APXT_Redlining__Contract_Agreement__c> newContracts
    ) {
        ContractImplementations.updateAmendedContracts(
            oldContracts,
            newContracts
        );
    }

    /**
     * Called from trigger when Contract Agreement is updated. Delegates 
     * work to the ContractAgreementFiles class.
     * @param  oldContracts the map of new Contract Agreements before update
     * @param  newContracts the map of new Contract Agreements after update
     */ 
    public static void reparentFilesOnAmendment(
        Map<Id, APXT_Redlining__Contract_Agreement__c> oldContracts,
        Map<Id, APXT_Redlining__Contract_Agreement__c> newContracts
    ) {
        ContractAgreementFiles.reparentFilesOnAmendment(
            oldContracts,
            newContracts
        );
    }

    /**
     * Called from trigger when Contract Agreement is updated. Delegates 
     * work to the ItemPricingSharing class.
     * @param  oldContracts the map of new Contract Agreements before update
     * @param  newContracts the map of new Contract Agreements after update
     */
    public static void sharePricingsOnUpdate(
        Map<Id, APXT_Redlining__Contract_Agreement__c> oldContracts,
        Map<Id, APXT_Redlining__Contract_Agreement__c> newContracts
    ) {
        ItemPricingSharing.shareOnAgreementUpdate(oldContracts, newContracts);
    }
}