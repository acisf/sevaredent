/**
 * Created by cshah on Nov 10, 2020.
 */

public without sharing class ContentDocumentLinkTriggerHandler {

    public static void afterInsert(Map<Id, ContentDocumentLink> newMap) {
        System.debug(' ContentDocumentLinkTriggerHandler.afterInsert newMap : ' + JSON.serialize(newMap));
        try {
            ContentDocumentLinkTriggerHandlerUtility.insertFileNames(newMap, true);
        } catch (Exception e) {
            System.debug(' ContentDocumentLinkTriggerHandler.afterInsert Exception : ' + e.getMessage());
            System.debug(e.getStackTraceString());
        }
    }
}