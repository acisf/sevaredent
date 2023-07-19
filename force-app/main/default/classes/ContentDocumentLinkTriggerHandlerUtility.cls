/**
 * Created by cshah on Nov 10, 2020.
 */

public without sharing class ContentDocumentLinkTriggerHandlerUtility {

    public static void insertFileNames(Map<Id, ContentDocumentLink> newMap, Boolean isAppendFileNames) {
        System.debug('ContentDocumentLinkTriggerHandlerUtility.insertFileNames newMap' + JSON.serialize(newMap));
        Map<Id, Set<Id>> amendmentContentDocumentMap = createAmendmentContentDocumentMap(newMap);
        Set<Id> contentDocumentRecordIds = createSetOfContentDocumentRecordIds(newMap);
        System.debug('ContentDocumentLinkTriggerHandlerUtility.insertFileNames amendmentContentDocumentMap' + JSON.serialize(amendmentContentDocumentMap));
        System.debug('ContentDocumentLinkTriggerHandlerUtility.insertFileNames contentDocumentRecordIds' + JSON.serialize(contentDocumentRecordIds));

        Map<Id, ContentDocument> contentDocumentMap = new Map<Id, ContentDocument>(getContentDocumentRecords(contentDocumentRecordIds));
        System.debug('ContentDocumentLinkTriggerHandlerUtility.insertFileNames contentDocumentMap' + JSON.serialize(contentDocumentMap));
        List<Amendment__c> amendmentsListToBeUpdate = getAmendmentRecords(amendmentContentDocumentMap.keySet());
        if(!isAppendFileNames) {
            amendmentsListToBeUpdate = updateFileNamesToBlank(amendmentsListToBeUpdate);
        }
        System.debug('ContentDocumentLinkTriggerHandlerUtility.insertFileNames amendmentsListToBeUpdate' + JSON.serialize(amendmentsListToBeUpdate));
        updateFileNamesInAmendments(amendmentsListToBeUpdate, amendmentContentDocumentMap, contentDocumentMap);
    }

    @TestVisible
    private static Map<Id, Set<Id>> createAmendmentContentDocumentMap(Map<Id, ContentDocumentLink> contentDocumentLinkMap) {
        System.debug('ContentDocumentLinkTriggerHandlerUtility.createAmendmentContentDocumentMap contentDocumentLinkMap' + JSON.serialize(contentDocumentLinkMap));
        Map<Id, Set<Id>> amendmentContentDocumentMap = new Map<Id, Set<Id>>();
        for(ContentDocumentLink contentDocumentLink: contentDocumentLinkMap.values()) {
            if (isContentDocumentLinkForAmendment(contentDocumentLink)) {
                if(amendmentContentDocumentMap.containsKey(contentDocumentLink.LinkedEntityId)) {
                    amendmentContentDocumentMap.get(contentDocumentLink.LinkedEntityId).add(contentDocumentLink.ContentDocumentId);
                } else {
                    amendmentContentDocumentMap.put(contentDocumentLink.LinkedEntityId, new Set<Id>{contentDocumentLink.ContentDocumentId});
                }
            }
        }
        System.debug('ContentDocumentLinkTriggerHandlerUtility.createAmendmentContentDocumentMap amendmentContentDocumentMap' + JSON.serialize(amendmentContentDocumentMap));
        return amendmentContentDocumentMap;
    }

    public static Map<Id, ContentDocumentLink> createContentDocumentLinkMapForAmendmentLinkedEntity(Map<Id, ContentDocumentLink> contentDocumentLinkMap) {
        System.debug('ContentDocumentLinkTriggerHandlerUtility.createAmendmentContentDocumentMap contentDocumentLinkMap' + JSON.serialize(contentDocumentLinkMap));
        Map<Id, ContentDocumentLink> contentDocumentLinkMapForAmendmentEntity = new Map<Id, ContentDocumentLink>();
        for(ContentDocumentLink contentDocumentLink: contentDocumentLinkMap.values()) {
            if (isContentDocumentLinkForAmendment(contentDocumentLink)) {
                contentDocumentLinkMapForAmendmentEntity.put(contentDocumentLink.Id, contentDocumentLink);
            }
        }
        System.debug('ContentDocumentLinkTriggerHandlerUtility.createAmendmentContentDocumentMap amendmentContentDocumentMap' + JSON.serialize(contentDocumentLinkMapForAmendmentEntity));
        return contentDocumentLinkMapForAmendmentEntity;
    }

    @TestVisible
    private static Set<Id> createSetOfContentDocumentRecordIds(Map<Id, ContentDocumentLink> contentDocumentLinkMap) {
        Set<Id> contentDocumentRecordIds = new Set<Id>();
        for(ContentDocumentLink contentDocumentLink: contentDocumentLinkMap.values()) {
            if (isContentDocumentLinkForAmendment(contentDocumentLink)) {
                contentDocumentRecordIds.add(contentDocumentLink.ContentDocumentId);
            }
        }
        System.debug('ContentDocumentLinkTriggerHandlerUtility.createSetOfContentDocumentRecordIds contentDocumentRecordIds' + JSON.serialize(contentDocumentRecordIds));
        return contentDocumentRecordIds;
    }

    @TestVisible
    private static void updateFileNamesInAmendments(List<Amendment__c> amendmentsListToBeUpdate, Map<Id, Set<Id>> amendmentContentDocumentMap, Map<Id, ContentDocument> contentDocumentMap) {
        System.debug('ContentDocumentLinkTriggerHandlerUtility.updateFileNamesInAmendments before update amendmentsListToBeUpdate' + JSON.serialize(amendmentsListToBeUpdate));
        System.debug('ContentDocumentLinkTriggerHandlerUtility.updateFileNamesInAmendments amendmentContentDocumentMap' + JSON.serialize(amendmentContentDocumentMap));
        System.debug('ContentDocumentLinkTriggerHandlerUtility.updateFileNamesInAmendments contentDocumentMap' + JSON.serialize(contentDocumentMap));
        if(!amendmentsListToBeUpdate.isEmpty()) {
            for(Amendment__c amendment: amendmentsListToBeUpdate) {
                Set<Id> contentDocumentIds = amendmentContentDocumentMap.get(amendment.Id);
                for(Id contentDocumentId: contentDocumentIds) {
                    ContentDocument contentDocument = contentDocumentMap.get(contentDocumentId);
                    if(String.isNotEmpty(amendment.Files__c)) {
                        amendment.Files__c = amendment.Files__c + '<br/><br>' + createLinkToContentDocument(contentDocument);
                    } else {
                        amendment.Files__c = createLinkToContentDocument(contentDocument);
                    }
                }
            }
            System.debug('ContentDocumentLinkTriggerHandlerUtility.updateFileNamesInAmendments after update amendmentsListToBeUpdate' + JSON.serialize(amendmentsListToBeUpdate));
            update amendmentsListToBeUpdate;
        }
    }

    @TestVisible
    private static Boolean isContentDocumentLinkForAmendment(ContentDocumentLink contentDocumentLink) {
        return contentDocumentLink.LinkedEntityId.getSobjectType().getDescribe().getName().equalsIgnoreCase('Amendment__c');
    }

    @TestVisible
    private static List<ContentDocument> getContentDocumentRecords(Set<Id> contentDocumentRecordIds) {
        return [SELECT Id, Title, FileExtension, FileType FROM ContentDocument WHERE Id IN :contentDocumentRecordIds];
    }

    @TestVisible
    private static List<Amendment__c> getAmendmentRecords(Set<Id> amendmentRecordIds) {
        return [SELECT Id, Files__c FROM Amendment__c WHERE Id IN :amendmentRecordIds];
    }

    public static Map<Id, ContentDocumentLink> createContentDocumentLinkMapForContentDocuments(Set<Id> contentDocumentIds) {
        Map<Id, ContentDocumentLink> contentDocumentLinkMap = new Map<Id, ContentDocumentLink>(contentDocumentLinkRecordsForContentDocuments(contentDocumentIds));
        return contentDocumentLinkMap;
    }

    @TestVisible
    private static List<ContentDocumentLink> contentDocumentLinkRecordsForContentDocuments(Set<Id> contentDocumentIds) {
        return [SELECT Id, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE ContentDocumentId IN :contentDocumentIds];
    }

    @TestVisible
    private static String createLinkToContentDocument(ContentDocument contentDocument) {
        return contentDocument.Title + '.' + contentDocument.FileExtension + '<br>' + System.Url.getSalesforceBaseUrl().toExternalForm() + '/lightning/r/ContentDocument/' + contentDocument.Id + '/view';
    }

    @TestVisible
    private static List<Amendment__c> updateFileNamesToBlank(List<Amendment__c> amendmentsListToBeUpdate) {
        System.debug('ContentDocumentLinkTriggerHandlerUtility.updateFileNamesToBlank amendmentsListToBeUpdate' + JSON.serialize(amendmentsListToBeUpdate));
        for(Amendment__c amendment: amendmentsListToBeUpdate) {
            amendment.Files__c = '';
        }
        System.debug('ContentDocumentLinkTriggerHandlerUtility.updateFileNamesToBlank amendmentsListToBeUpdate' + JSON.serialize(amendmentsListToBeUpdate));
        return amendmentsListToBeUpdate;
    }
}