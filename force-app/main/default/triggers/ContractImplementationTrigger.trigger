trigger ContractImplementationTrigger on Contract_Implementations__c(
    after insert,
    after update
) {
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            ContractImplementationTriggerHandler.shareOnCreate(Trigger.new);
            ContractImplementationTriggerHandler.sharePricingItemsOnCreate(Trigger.new);
        }
        if (Trigger.isUpdate) {
            ContractImplementationTriggerHandler.sharePricingItems(Trigger.oldMap, Trigger.newMap);
            ContractImplementationTriggerHandler.shareOnUpdate(Trigger.newMap);
        }
    }
}