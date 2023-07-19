trigger ItemPricingTrigger on Item_Pricing__c(after insert, after update) {
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            ItemPricingTriggerHandler.shareItems(Trigger.new);
        }
        if (Trigger.isUpdate) {
            ItemPricingTriggerHandler.shareItems(
                Trigger.oldMap,
                Trigger.newMap
            );
        }
    }
}