/**
 * Provides functionality for sharing Contract Implementations object 
 * records and related objects to certain community members.
 */ 
public with sharing class ContractImplementationTriggerHandler {
    private static Map<Id, Account> usersWithAccount;

    /**
     * When Contract Implementation with Status__c field value equals 
     * “Implemented” or “ Partially Implemented” is created, creates 
     * sharing objects (Contract_Implementations__Share) to share this 
     * Contract Implementations object record with community members with 
     * same account as in Contract_Implementations__c.Account__c field.
     * Share objects are inserted in @future method.
     * @param  contracts the list of new Contract Implementations object
     */ 
    public static void shareOnCreate(
        List<Contract_Implementations__c> contracts
    ) {
        usersWithAccount = UserService.getUsersWithAccount();
        share(contracts);
    }

    /**
     * Share Contract Implementations to proper User
     * @param  contracts the lis of Contract Implementations to share
     */ 
    private static void share(List<Contract_Implementations__c> contracts) {
        List<Contract_Implementations__Share> sharings = new List<Contract_Implementations__Share>();

        for (Contract_Implementations__c contract : contracts) {
            if (
                contract.Status__c == 'Implemented' ||
                contract.Status__c == 'Partially Implemented'
            ) {
                for (Id userId : usersWithAccount.keySet()) {
                    Account userAccount = usersWithAccount.get(userId);

                    if (
                        userAccount != null &&
                        contract.Account__c == userAccount.Id
                    ) {
                        sharings.add(createNewSharing(contract.Id, userId));
                    }
                }
            }
        }

        insertSharings(JSON.serialize(sharings));
    }

    /**
     * Create Apex Share object for Contract Implementations
     * @param  contractId Contract Implementations Id
     * @param  userId     User Id
     * @return            Apex Share object record
     */ 
    private static Contract_Implementations__Share createNewSharing(
        Id contractId,
        Id userId
    ) {
        return new Contract_Implementations__Share(
            ParentId = contractId,
            UserOrGroupId = userId,
            AccessLevel = 'Read'
        );
    }

    /**
     * Future method to insert Apex Share objects to Database
     * @param  sharingsJSON Apex Share objects in JSON format
     */ 
    @future
    private static void insertSharings(String sharingsJSON) {
        List<Contract_Implementations__Share> sharings = (List<Contract_Implementations__Share>) JSON.deserialize(
            sharingsJSON,
            List<Contract_Implementations__Share>.class
        );
        insert sharings;
    }

    /**
     * When Contract Implementation is updated, deletes old sharings 
     * (Contract_Implementations__Share) for the record and creates new 
     * sharings according to new field values.
     * Share objects are inserted in @future method.
     * @param  contracts the map of updated Contract Implementations
     */ 
    public static void shareOnUpdate(
        Map<Id, Contract_Implementations__c> contracts
    ) {
        usersWithAccount = UserService.getUsersWithAccount();
        deleteOldSharings(contracts.keySet());
        share(contracts.values());
    }

    /**
     * Delete old Apex Share objects
     * @param  contractIds set of Contract Implementations Ids to delete sharings
     */ 
    private static void deleteOldSharings(Set<Id> contractIds) {
        if (!contractIds.isEmpty()) {

            DMLWithoutSharingUtility.deleteContractImplementationSharings(
                [
                    SELECT Id
                    FROM Contract_Implementations__Share
                    WHERE ParentId IN :contractIds
                ]
            );
        }
    }

    /**
     * When new User with profile “Member” is created, creates sharing 
     * objects (Contract_Implementations__Share) to share Contract 
     * Implementations with Status__c field value equals “Implemented” or 
     * “ Partially Implemented” and Account__c equals to User’s Account.
     * Share objects are inserted in @future method.
     * @param  users list of inserted Users
     */ 
    public static void shareOnMemberCreate(List<User> users) {
        usersWithAccount = UserService.getUsersWithAccount(users);

        List<Contract_Implementations__c> contracts = [
            SELECT Account__c, Status__c
            FROM Contract_Implementations__c
            WHERE Status__c IN ('Implemented', 'Partially Implemented')
        ];

        share(contracts);
    }

    /**
     * When Contract Implementation Status__c or Contract_Agreement__c 
     * field is updated, deletes old sharings for Item_Pricing__c objects 
     * (Item_Pricing__Share) for community members with the same Account 
     * like Contract_Implementations__c.Account__c and creates new sharings 
     * according to updated field values.
     * Share objects are inserted in Batchable class.
     * @param  oldContracts the map of Contract Implementations before update
     * @param  newContracts the map of Contract Implementations after update
     */ 
    public static void sharePricingItems(
        Map<Id, Contract_Implementations__c> oldContracts,
        Map<Id, Contract_Implementations__c> newContracts
    ) {
        List<Contract_Implementations__c> contractsToUpdate = getContractsToUpdate(
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
     * Check Contract Implementations Status__c or Contract_Agreement__c fields are changed
     * @param  oldContracts oldContracts the map of Contract Implementations before update
     * @param  newContracts the map of Contract Implementations after update
     * @return              list of changed Contract Implementations
     */ 
    private static List<Contract_Implementations__c> getContractsToUpdate(
        Map<Id, Contract_Implementations__c> oldContracts,
        Map<Id, Contract_Implementations__c> newContracts
    ) {
        List<Contract_Implementations__c> updatedContracts = new List<Contract_Implementations__c>();
        for (Id contrId : newContracts.keySet()) {
            Contract_Implementations__c oldContr = oldContracts.get(contrId);
            Contract_Implementations__c newContr = newContracts.get(contrId);
            if (
                oldContr.Status__c != newContr.Status__c ||
                oldContr.Contract_Agreement__c != newContr.Contract_Agreement__c
            ) {
                updatedContracts.add(newContr);
            }
        }
        return updatedContracts;
    }

    /**
     * Get Members, related to updated Contract Implementation
     * @param  contractsToUpdate list of updated Contract Implementations
     * @return                   map of Users by their Id
     */ 
    private static Map<Id, User> getUsersToUpdate(
        List<Contract_Implementations__c> contractsToUpdate
    ) {
        Set<Id> accIds = new Set<Id>();
        for (Contract_Implementations__c impl : contractsToUpdate) {
            accIds.add(impl.Account__c);
        }
        return new Map<Id, User>(
            [
                SELECT Id, AccountId, ProfileId
                FROM User
                WHERE
                    ProfileId IN (SELECT Id FROM Profile WHERE Name = 'Member')
                    AND AccountId IN :accIds
            ]
        );
    }

    /**
     * When new Contract Implementation with Status__c field value equals 
     * “Implemented” or “ Partially Implemented” is created, creates 
     * sharings for Item_Pricing__c objects (Item_Pricing__Share), where 
     * Item_Pricing__c.Contract_Agreement__c equals with 
     * Contract_Implementations__c.Contract_Agreement__c, for community 
     * members with User.AccountId equals with 
     * Contract_Implementations__c.Account__c
     * Share objects are inserted in Batchable class.
     * @param  contracts the list of new Contract Implementations
     */ 
    public static void sharePricingItemsOnCreate(
        List<Contract_Implementations__c> contracts
    ) {
        Map<Id, User> usersToUpdate = getUsersToUpdate(contracts);

        if (!usersToUpdate.isEmpty()) {
            ItemPricingSharingBatch share = new ItemPricingSharingBatch(
                usersToUpdate,
                contracts
            );
            Id jobId = Database.executeBatch(share);
        }
    }
}