/**
 * Created by cshah on Nov 12, 2020.
 */

public without sharing class ContentDocumentTriggerHandlerUtility {

    public static void deleteAndUpdateFileNamesInAmendment(Map<Id, ContentDocument> oldMap) {
        createContentDocumentLinkRecords(oldMap.keySet());
    }

    public static void updateFileNamesInAmendment(Set<Id> contentDocumentIds) {
        Set<Id> amendmentIds = getAmendmentIdsForContentDocumentIds(contentDocumentIds);
        Map<Id, ContentDocumentLink> contentDocumentLinkMapForAmendmentEntity = new Map<Id, ContentDocumentLink>(contentDocumentLinksForAmendments(amendmentIds));
        System.debug('ContentDocumentTriggerHandlerUtility.updateFileNamesInAmendment contentDocumentLinkMapForAmendmentEntity');
        System.debug(JSON.serialize(contentDocumentLinkMapForAmendmentEntity));
        ContentDocumentLinkTriggerHandlerUtility.insertFileNames(contentDocumentLinkMapForAmendmentEntity, false);
    }

    @TestVisible
    private static void createContentDocumentLinkRecords(Set<Id> deletedContentDocumentIds) {
        Set<Id> amendmentIds = getAmendmentIdsForContentDocumentIds(deletedContentDocumentIds);

        if(!amendmentIds.isEmpty()) {
            Map<Id, ContentDocumentLink> contentDocumentLinkMap = contentDocumentLinkForAmendments(deletedContentDocumentIds, amendmentIds);
            ContentDocumentLinkTriggerHandlerUtility.insertFileNames(contentDocumentLinkMap, false);
        }
    }

    @TestVisible
    private static Set<Id> getAmendmentIdsForContentDocumentIds(Set<Id> contentDocumentIds) {
        Map<Id, ContentDocumentLink> contentDocumentLinkMapForAmendmentEntity = getContentDocumentLinksByContentDocumentIdsForAmendments(contentDocumentIds);
        Set<Id> amendmentIds = new Set<Id>();
        for(ContentDocumentLink contentDocumentLink :contentDocumentLinkMapForAmendmentEntity.values()) {
            amendmentIds.add(contentDocumentLink.LinkedEntityId);
        }
        System.debug('ContentDocumentTriggerHandlerUtility.getAmendmentIdsForContentDocumentIds amendmentIds' + JSON.serialize(amendmentIds));
        return amendmentIds;
    }

    @TestVisible
    private static Map<Id, ContentDocumentLink> getContentDocumentLinksByContentDocumentIdsForAmendments(Set<Id> contentDocumentIds) {
        Map<Id, ContentDocumentLink> contentDocumentLinkMapForAllEntity = ContentDocumentLinkTriggerHandlerUtility.createContentDocumentLinkMapForContentDocuments(contentDocumentIds);
        System.debug('ContentDocumentTriggerHandlerUtility.getContentDocumentLinksByContentDocumentIds contentDocumentLinkMapForAllEntity' + JSON.serialize(contentDocumentLinkMapForAllEntity));
        Map<Id, ContentDocumentLink> contentDocumentLinkMapForAmendmentEntity = ContentDocumentLinkTriggerHandlerUtility.createContentDocumentLinkMapForAmendmentLinkedEntity(contentDocumentLinkMapForAllEntity);
        System.debug('ContentDocumentTriggerHandlerUtility.getContentDocumentLinksByContentDocumentIds contentDocumentLinkMapForAmendmentEntity' + JSON.serialize(contentDocumentLinkMapForAmendmentEntity));
        return contentDocumentLinkMapForAmendmentEntity;
    }

    @TestVisible
    private static Map<Id, ContentDocumentLink> contentDocumentLinkForAmendments(Set<Id> contentDocumentIds, Set<Id> linkedEntityIds) {
        Map<Id, ContentDocumentLink> contentDocumentLinkMap = new Map<Id, ContentDocumentLink>([SELECT Id, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId IN :linkedEntityIds AND ContentDocumentId NOT IN :contentDocumentIds]);
        System.debug('ContentDocumentTriggerHandlerUtility.contentDocumentLinkForAmendments contentDocumentLinkMap' + JSON.serialize(contentDocumentLinkMap));
        return contentDocumentLinkMap;
    }

    @TestVisible
    private static List<ContentDocumentLink> contentDocumentLinksForAmendments(Set<Id> amendmentIds) {
        return [SELECT Id, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId IN :amendmentIds];
    }
}