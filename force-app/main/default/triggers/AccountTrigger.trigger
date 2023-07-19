trigger AccountTrigger on Account(after insert, before update) {
    if (Trigger.isBefore) {
        if (Trigger.isUpdate) {
            ContractAgreementFiles.linkFilesOnAccountUpdate(Trigger.oldMap, Trigger.newMap);
            AccountTriggerHandler.beforeUpdate(Trigger.oldMap, Trigger.newMap);
        }
    }

    if (Trigger.isAfter && Trigger.isInsert) {
        ContractAgreementFiles.linkFilesOnAccountCreate(Trigger.new);
    }
}