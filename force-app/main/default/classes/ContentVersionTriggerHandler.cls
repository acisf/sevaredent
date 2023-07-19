/**
 * Handler for ContentVersion trigger. Provides functionality for 
 * linking files to specific accounts.
 * Functions of this handler does not contain logic itself, but calls 
 * methods from other classes.
 */ 
public without sharing class ContentVersionTriggerHandler {
    
    /*public static void afterUpdate(
        Map<Id, ContentVersion> oldMap,
        Map<Id, ContentVersion> newMap
    ) {
        updateAmendmentsForContentVersionUpdation(oldMap, newMap);
    }

    @TestVisible
    private static void updateAmendmentsForContentVersionUpdation(
        Map<Id, ContentVersion> oldMap,
        Map<Id, ContentVersion> newMap
    ) {
        Set<Id> contentDocumentIds = new Set<Id>();

        for (ContentVersion contentVersion : newMap.values()) {
            ContentVersion oldContentVersion = oldMap.get(contentVersion.Id);
            if (
                !contentVersion.Title.toLowerCase()
                    .equals(oldContentVersion.Title.toLowerCase())
            ) {
                contentDocumentIds.add(contentVersion.ContentDocumentId);
            }
        }
        if (!contentDocumentIds.isEmpty()) {
            ContentDocumentTriggerHandlerUtility.updateFileNamesInAmendment(
                contentDocumentIds
            );
        }
    }
	*/
    /**
     * Called from trigger when document is created. Delegates 
     * work to the ContractAgreementFiles class.
     * 
     * @param  newList the list of new ContentVersion records
     */ 
    public static void linkDocumentsToAccountsOnInsert(
        List<ContentVersion> newList
    ) {
        ContractAgreementFiles.linkFilesOnInsert(newList);
    }

    /**
     * Called from trigger when document is updated. Delegates 
     * work to the ContractAgreementFiles class.
     * 
     * @param  newList the list of new ContentVersion records
     */ 
    public static void linkDocumentsToAccountsOnUpdate(
        Map<Id, ContentVersion> oldMap,
        Map<Id, ContentVersion> newMap
    ) {
        ContractAgreementFiles.linkFilesOnUpdate(oldMap, newMap);
    }
}