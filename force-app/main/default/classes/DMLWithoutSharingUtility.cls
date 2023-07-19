/**
 * Utility class designed to allow DML operations on Share objects for 
 * users that are not owned Share objects records, but has permissions  
 * to create, update or delete objects for which Share objects are created.
 */ 
public without sharing class DMLWithoutSharingUtility {

    /**
     * Delete Share objects for Contract Agreements.
     * @param  sharings the list of Contract Agreement Share objects
     */ 
    public static void deleteContractAgreementSharings(
        List<APXT_Redlining__Contract_Agreement__Share> sharings
    ) {
        if (
            hasPermissions(
                Schema.sObjectType.APXT_Redlining__Contract_Agreement__c
            )
        ) {
            delete sharings;
        }
    }

    /**
     * Delete Share objects for Contract Implementations.
     * @param  sharings the list of Contract Implementations Share objects
     */ 
    public static void deleteContractImplementationSharings(
        List<Contract_Implementations__Share> sharings
    ) {
        if (hasPermissions(Schema.sObjectType.Contract_Implementations__c)) {
            delete sharings;
        }
    }

    /**
     * Delete Share objects for Item Pricing.
     * @param  sharings the list of Item Pricing Share objects
     */ 
    public static void deleteItemPricingSharings(
        List<Item_Pricing__Share> sharings
    ) {
        if (hasPermissions(Schema.sObjectType.Item_Pricing__c)) {
            delete sharings;
        }
    }

    /**
     * Delete ContentDocumentLink.
     * @param  links the list of ContentDocumentLink objects
     */ 
    public static void deleteContentDocumentLinks(
        List<ContentDocumentLink> links
    ) {
        if (
            hasPermissions(
                Schema.sObjectType.APXT_Redlining__Contract_Agreement__c
            )
        ) {
            delete links;
        }
    }

    /**
     * Create ContentDocumentLink.
     * @param  links the list of ContentDocumentLink objects
     */ 
    public static void createContentDocumentLinks(
        List<ContentDocumentLink> links
    ) {
        if (
            hasPermissions(
                Schema.sObjectType.APXT_Redlining__Contract_Agreement__c
            )
        ) {
            insert links;
        }
    }

    /**
     * Checks if the user has permissions to specific object
     * @param  obj object to check permissions
     * @return     true - if User has permissions, otherwise - false
     */ 
    private static Boolean hasPermissions(Schema.DescribeSObjectResult obj) {
        return obj.isCreateable() || obj.isUpdateable() || obj.isDeletable();
    }
}