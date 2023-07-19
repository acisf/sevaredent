/**
 * Created by cshah on Nov 12, 2020.
 */

public without sharing class ContentDocumentTriggerHandler {

    public static void beforeDelete(Map<Id, ContentDocument> oldMap) {
        ContentDocumentTriggerHandlerUtility.deleteAndUpdateFileNamesInAmendment(oldMap);
    }
}