trigger contractAgreementTrigger on APXT_Redlining__Contract_Agreement__c(
    after insert,
    after update,
    before delete
) {
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            AC_ContractAgreementTriggerHandler.shareContracts(Trigger.new);
        }
        if (Trigger.isUpdate) {
            AC_ContractAgreementTriggerHandler.shareContracts(Trigger.oldMap, Trigger.newMap);
            AC_ContractAgreementTriggerHandler.updateAmendedContractsOnImplementations(
                Trigger.oldMap,
                Trigger.newMap
            );
            AC_ContractAgreementTriggerHandler.reparentFilesOnAmendment(
                Trigger.oldMap,
                Trigger.newMap
            );
            AC_ContractAgreementTriggerHandler.sharePricingsOnUpdate(
                Trigger.oldMap,
                Trigger.newMap
            );
        }
    }
}