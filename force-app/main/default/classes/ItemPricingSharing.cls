/**
 * Provides functionality for sharing Item Pricing object records to 
 * certain community members.
 */ 
public with sharing class ItemPricingSharing {
    private static Map<Id, Account> usersWithAccount;

    /**
     * When a new Item Pricing object is created, it creates sharings 
     * (Item_Pricing__Share) to share it to community members, which has 
     * implemented Contract Agreements equals to 
     * Item_Pricing__c.Contract_Agreement__c field value.
     * Share objects are inserted in @future method.
     * @param  newPricings the list of Item Pricing objects
     */ 
    public static void shareOnCreate(List<Item_Pricing__c> newPricings) {
        usersWithAccount = UserService.getUsersWithAccount();
        share(newPricings);
    }

    /**
     * Share Item Pricings to proper User
     * @param  pricings list of Item Pricings to share
     */ 
    private static void share(List<Item_Pricing__c> pricings) {
        Set<Id> conAgreeIds = getAgreementIds(pricings);
        Map<Id, Set<Id>> accountsByAgreements = mapAccountsByAgreements(
            conAgreeIds
        );

        List<Item_Pricing__Share> sharings = new List<Item_Pricing__Share>();

        for (Item_Pricing__c item : pricings) {
            Set<Id> accIds = accountsByAgreements.get(
                item.Contract_Agreement__c
            );

            if (accIds != null && !accIds.isEmpty()) {
                shareToAccountUsers(item.Id, accIds, sharings);
            }
        }

        insertByChunks(sharings);
    }

    /**
     * Get Id of Contract Agreement for this Item Pricing
     * @param  pricings list of Item Pricings
     * @return          set of Contract Agreement Ids
     */ 
    private static Set<Id> getAgreementIds(List<Item_Pricing__c> pricings) {
        Set<Id> conAgreeIds = new Set<Id>();
        for (Item_Pricing__c item : pricings) {
            conAgreeIds.add(item.Contract_Agreement__c);
        }

        return conAgreeIds;
    }

    /**
     * Maps Accounts by Contract Agreements
     * @param  conAgreeIds set of Contract Agreement Ids
     * @return             map of Accounts by Contract Agreement Id
     */ 
    private static Map<Id, Set<Id>> mapAccountsByAgreements(
        Set<Id> conAgreeIds
    ) {
        List<Contract_Implementations__c> implementations = [
            SELECT Account__c, Contract_Agreement__c, Status__c
            FROM Contract_Implementations__c
            WHERE
                Contract_Agreement__c IN :conAgreeIds
                AND Status__c IN ('Implemented', 'Partially Implemented')
        ];

        Map<Id, Set<Id>> accountsByAgreements = new Map<Id, Set<Id>>();
        Set<Id> accIds;
        for (Contract_Implementations__c impl : implementations) {
            accIds = accountsByAgreements.containsKey(
                    impl.Contract_Agreement__c
                )
                ? accountsByAgreements.get(impl.Contract_Agreement__c)
                : new Set<Id>();
            accIds.add(impl.Account__c);
            accountsByAgreements.put(impl.Contract_Agreement__c, accIds);
        }

        return accountsByAgreements;
    }

    /**
     * Share Item Pricings for Users of specific Accounts
     * @param  itemId   Id of Item Pricing
     * @param  accIds   set of Account Ids
     * @param  sharings list of Item Pricing Share objects
     */ 
    private static void shareToAccountUsers(
        Id itemId,
        Set<Id> accIds,
        List<Item_Pricing__Share> sharings
    ) {
        for (Id userId : usersWithAccount.keySet()) {
            if (
                usersWithAccount.get(userId) != null &&
                accIds.contains(usersWithAccount.get(userId).Id)
            ) {
                sharings.add(createNewSharing(itemId, userId));
            }
        }
    }

    /**
     * Create Apex Share object for Item Pricing
     * @param  itemId Id of Item Pricing
     * @param  userId Id of User
     * @return        Apex Share object for Item Pricing
     */ 
    private static Item_Pricing__Share createNewSharing(Id itemId, Id userId) {
        Item_Pricing__Share itemShr = new Item_Pricing__Share();
        itemShr.ParentId = itemId;
        itemShr.UserOrGroupId = userId;
        itemShr.AccessLevel = 'Read';

        return itemShr;
    }

    /**
     * Provides inserting by chanks to prevent DML exception
     * @param  sharings list of Apex Share objects for Item Pricing
     */ 
    private static void insertByChunks(List<Item_Pricing__Share> sharings) {
        if (sharings.size() == 0) {
            return;
        }
        List<Item_Pricing__Share> sharingsChunk = new List<Item_Pricing__Share>();
        for (Integer i = 0; i < 150; i++) {
            if (sharings.size() > 0) {
                sharingsChunk.add(sharings[0]);
                sharings.remove(0);

                if (sharingsChunk.size() == 150) {
                    insertByChunks(sharings);
                }
            }
        }
        insertSharings(JSON.serialize(sharingsChunk));
    }

    /**
     * Future method to insert Apex Share objects to Database
     * @param  sharingsJSON Apex Share objects in JSON format
     */ 
    @future
    private static void insertSharings(String sharingsJSON) {
        List<Item_Pricing__Share> sharings = (List<Item_Pricing__Share>) JSON.deserialize(
            sharingsJSON,
            List<Item_Pricing__Share>.class
        );

        insert sharings;
    }

    /**
     * When the Item Pricing Contract_Agreement__c field is changed, it 
     * removes old sharings (Item_Pricing__Share) and creates new sharings 
     * to share it to community members according to the new field value.
     * Share objects are inserted in @future method.
     * @param  oldPricings the map of Item Pricing objects records before update
     * @param  newPricings the map of Item Pricing objects records after update
     */ 
    public static void shareOnUpdate(
        Map<Id, Item_Pricing__c> oldPricings,
        Map<Id, Item_Pricing__c> newPricings
    ) {
        usersWithAccount = UserService.getUsersWithAccount();
        Map<Id, Item_Pricing__c> pricingsToUpdate = getPricingsToUpdate(
            oldPricings,
            newPricings
        );

        deleteOldSharings(pricingsToUpdate.keySet());
        share(pricingsToUpdate.values());
    }

    /**
     * Check if Item Pricing Contract_Agreement__c field was changed
     * @param  oldPricings the map of Item Pricing objects records before update
     * @param  newPricings the map of Item Pricing objects records after update
     * @return             list of changed Item Pricings
     */ 
    private static Map<Id, Item_Pricing__c> getPricingsToUpdate(
        Map<Id, Item_Pricing__c> oldPricings,
        Map<Id, Item_Pricing__c> newPricings
    ) {
        Map<Id, Item_Pricing__c> updatedPricings = new Map<Id, Item_Pricing__c>();
        for (Id itemId : newPricings.keySet()) {
            Item_Pricing__c oldItem = oldPricings.get(itemId);
            Item_Pricing__c newItem = newPricings.get(itemId);

            if (
                oldItem.Contract_Agreement__c != newItem.Contract_Agreement__c
            ) {
                updatedPricings.put(itemId, newItem);
            }
        }

        return updatedPricings;
    }

    /**
     * Delete old Apex Share objects
     * @param  pricingIds set of Item Pricing Ids to delete sharings
     */ 
    private static void deleteOldSharings(Set<Id> pricingIds) {
        if (!pricingIds.isEmpty()) {
            List<Item_Pricing__Share> oldSharings = [
                SELECT Id
                FROM Item_Pricing__Share
                WHERE ParentId IN :pricingIds
                LIMIT 10000
            ];

            DMLWithoutSharingUtility.deleteItemPricingSharings(oldSharings);
        }
    }

    /**
     * When the Contract Agreement APXT_Redlining__Status__c field is 
     * changed, it removes old sharings (Item_Pricing__Share) and creates 
     * new sharings to share it to community members according to the new field value.
     * Share objects are inserted in Batch class.
     * @param  oldContracts the map of Item Pricing objects records before update
     * @param  newPricings the map of Item Pricing objects records after update
     */ 
    public static void shareOnAgreementUpdate(
        Map<Id, APXT_Redlining__Contract_Agreement__c> oldContracts,
        Map<Id, APXT_Redlining__Contract_Agreement__c> newContracts
    ) {
        Map<Id, APXT_Redlining__Contract_Agreement__c> contractsToUpdate = getContractsToUpdate(
            oldContracts,
            newContracts
        );

        if (contractsToUpdate.isEmpty()) {
            return;
        }
        
        Map<Id, User> usersToUpdate = getUsersToUpdate(contractsToUpdate);

        if (!usersToUpdate.isEmpty()) {
            ItemPricingUpdateSharingBatch share = new ItemPricingUpdateSharingBatch(
                usersToUpdate,
                contractsToUpdate
            );
            Id jobId = Database.executeBatch(share);
        }
    }

    /**
     * Get Users that have access to this Contract Agreements
     * @param  contractsToUpdate Contract Agreements to update 
     * @return                   the map of Users
     */ 
    private static Map<Id, User> getUsersToUpdate(
        Map<Id, APXT_Redlining__Contract_Agreement__c> contractsToUpdate
    ) {
        return new Map<Id, User>(
            [
                SELECT Id, AccountId, ProfileId
                FROM User
                WHERE
                    ProfileId IN (SELECT Id FROM Profile WHERE Name = 'Member')
                    AND AccountId IN (SELECT Account__c FROM Contract_Implementations__c 
                    WHERE Status__c IN ('Implemented', 'Partially Implemented') 
                        AND Contract_Agreement__c IN :contractsToUpdate.keySet())
            ]
        );
    }

    /**
     * Check if Contract Agreement APXT_Redlining__Status__c field was changed and 
     * record type is correct
     * @param  oldContracts the map of Contract Agreement object records before update
     * @param  newContracts the map of Contract Agreement object records after update
     * @return              the map of changed Contract Agreements
     */ 
    private static Map<Id, APXT_Redlining__Contract_Agreement__c> getContractsToUpdate(
        Map<Id, APXT_Redlining__Contract_Agreement__c> oldContracts,
        Map<Id, APXT_Redlining__Contract_Agreement__c> newContracts
    ) {
        Map<Id, APXT_Redlining__Contract_Agreement__c> updatedContracts = new Map<Id, APXT_Redlining__Contract_Agreement__c>();
        for (Id contrId : newContracts.keySet()) {
            APXT_Redlining__Contract_Agreement__c oldContr = oldContracts.get(
                contrId
            );
            APXT_Redlining__Contract_Agreement__c newContr = newContracts.get(
                contrId
            );
            if (oldContr.APXT_Redlining__Status__c != newContr.APXT_Redlining__Status__c
                && isValidRecordType(newContr)) {
                updatedContracts.put(contrId, newContr);
            }
        }
        return updatedContracts;
    }    
    
    /**
     * Check if the record type of Contract Agreement has allowed value
     * @param  contract Contract Agreement object record
     * @return          true - if record type is allowed, otherwise - false
     */ 
    private static Boolean isValidRecordType(
        APXT_Redlining__Contract_Agreement__c contract
    ) {
        String MSA_RECORD_TYPE = Schema.sObjectType.APXT_Redlining__Contract_Agreement__c.getRecordTypeInfosByName()
            .get('MSA')
            .getRecordTypeId();
        String AMENDNENT_RECORD_TYPE = Schema.sObjectType.APXT_Redlining__Contract_Agreement__c.getRecordTypeInfosByName()
            .get('Amendment')
            .getRecordTypeId();
        String PRODUCT_AGREEMENT_RECORD_TYPE = Schema.sObjectType.APXT_Redlining__Contract_Agreement__c.getRecordTypeInfosByName()
            .get('Product Agreement')
            .getRecordTypeId();
        return contract.RecordTypeId == MSA_RECORD_TYPE ||
            contract.RecordTypeId == AMENDNENT_RECORD_TYPE ||
            contract.RecordTypeId == PRODUCT_AGREEMENT_RECORD_TYPE;
    }
}