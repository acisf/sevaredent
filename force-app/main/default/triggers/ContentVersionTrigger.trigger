/**
 * Created by cshah on Nov 12, 2020.
 */

trigger ContentVersionTrigger on ContentVersion (before update, after insert, after update) {
    if (Trigger.isBefore) {
        if (Trigger.isUpdate) {
            ContentVersionTriggerHandler.linkDocumentsToAccountsOnUpdate(Trigger.oldMap, Trigger.newMap);
        }
    }    

    if(Trigger.isAfter) {
        if (Trigger.isInsert) {
            ContentVersionTriggerHandler.linkDocumentsToAccountsOnInsert(Trigger.new);
        }
/**       if(Trigger.isUpdate) {
            ContentVersionTriggerHandler.afterUpdate(Trigger.oldMap, Trigger.newMap);
        }*/
    }
}