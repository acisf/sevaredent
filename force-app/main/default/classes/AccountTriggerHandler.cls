/**
 * Created by cshah on 03-09-2020.
 */

public without sharing class AccountTriggerHandler {

    public static void beforeUpdate(Map<Id, Account> oldMap, Map<Id, Account> newMap) {
        System.debug(' AccountTriggerHandler.beforeUpdate oldMap : ' + JSON.serialize(oldMap));
        System.debug(' AccountTriggerHandler.beforeUpdate newMap : ' + JSON.serialize(newMap));
        try {
            AccountTriggerHandlerUtility.checkIfRosterFieldsChangedAfterPublished(oldMap, newMap);
            AccountTriggerHandlerUtility.checkIfActiveChildPresent(oldMap, newMap);
        } catch (Exception e) {
            System.debug(' AccountTriggerHandler.beforeInsert Exception : ' + JSON.serialize(e));
        }
    }
}