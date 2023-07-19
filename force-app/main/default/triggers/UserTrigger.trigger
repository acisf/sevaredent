trigger UserTrigger on User (after insert) {
    if (Trigger.isAfter && Trigger.isInsert) {
        UserTriggerHandler.shareContractAgreements(Trigger.new);
        UserTriggerHandler.shareContractImplementations(Trigger.new);
        UserTriggerHandler.shareItemPricings(Trigger.newMap);
    }
}