/**
 * Provides functionality for sharing Contract Agreement object 
 * records to certain community members.
 */ 
public with sharing class ContractSharing {
    private static final String MSA_RECORD_TYPE = Schema.sObjectType.APXT_Redlining__Contract_Agreement__c.getRecordTypeInfosByName()
        .get('MSA')
        .getRecordTypeId();
    private static final String AMENDNENT_RECORD_TYPE = Schema.sObjectType.APXT_Redlining__Contract_Agreement__c.getRecordTypeInfosByName()
        .get('Amendment')
        .getRecordTypeId();
    private static final String PRODUCT_AGREEMENT_RECORD_TYPE = Schema.sObjectType.APXT_Redlining__Contract_Agreement__c.getRecordTypeInfosByName()
        .get('Product Agreement')
        .getRecordTypeId();
    private static Map<Id, Account> usersWithAccount;

    /**
     * When inserted new record of Contract Agreement with record type 
     * “MSA”, “Amendment” or “Product Agreement” and 
     * APXT_Redlining__Status__c field value equals “Activated” or “Being 
     * Amended”, creates sharing objects (APXT_Redlining__Contract_Agreement__Share) to share this Contract 
     * Agreement object record with community members according to member’s 
     * Account and APXT_Redlining__Contract_Agreement__c.Contract_Eligibility__c field value.
     * Share objects are inserted in @future method.
     * @param  contracts the list of new Contract Agreement objects
     */ 
    public static void shareOnCreate(
        List<APXT_Redlining__Contract_Agreement__c> contracts
    ) {
        usersWithAccount = UserService.getUsersWithAccount();
        share(contracts);
    }

    /**
     * Share Contract Agreements to proper User
     * @param  contracts list of Contract Agreements to share
     */ 
    private static void share(
        List<APXT_Redlining__Contract_Agreement__c> contracts
    ) {
        List<APXT_Redlining__Contract_Agreement__Share> sharings = new List<APXT_Redlining__Contract_Agreement__Share>();

        for (APXT_Redlining__Contract_Agreement__c c : contracts) {
            if (
                isValidRecordType(c) &&
                (c.APXT_Redlining__Status__c == 'Activated' ||
                c.APXT_Redlining__Status__c == 'Being Amended')
            ) {
                if (
                    c.Contract_Eligibility__c ==
                    'GPO All– Commercially Available for entire GPO'
                ) {
                    shareToAll(c.Id, sharings);
                } else if (
                    c.Contract_Eligibility__c ==
                    'Custom/Member Specific – Custom contract for member on Sevāredent paper'
                ) {
                    shareToSpecificAccount(c, sharings);
                } else if (
                    c.Contract_Eligibility__c == 'Education (discipline)'
                ) {
                    shareToEducational(c.Id, sharings);
                }
            }
        }

        If(sharings.size() > 0)		//MN
        	insertSharings(JSON.serialize(sharings));
    }

    /**
     * Check record type of Contract Agreement
     * @param  contract Contract Agreement object record
     * @return          true if record type is acceptable, otherwise - false
     */
    private static Boolean isValidRecordType(
        APXT_Redlining__Contract_Agreement__c contract
    ) {
        return contract.RecordTypeId == MSA_RECORD_TYPE ||
            contract.RecordTypeId == AMENDNENT_RECORD_TYPE ||
            contract.RecordTypeId == PRODUCT_AGREEMENT_RECORD_TYPE;
    }

    /**
     * Share Contract Agreement available for all community users
     * @param  contractId Id of Contract Agreement
     * @param  sharings   list of sharings
     */ 
    private static void shareToAll(
        Id contractId,
        List<APXT_Redlining__Contract_Agreement__Share> sharings
    ) {
        for (Id userId : usersWithAccount.keySet()) {
            sharings.add(createNewSharing(contractId, userId));
        }
    }

    /**
     * Share Contract Agreement available for community users with specific Account
     * @param  contractId Id of Contract Agreement
     * @param  sharings   list of sharings
     */
    private static void shareToSpecificAccount(
        APXT_Redlining__Contract_Agreement__c contract,
        List<APXT_Redlining__Contract_Agreement__Share> sharings
    ) {
        for (Id userId : usersWithAccount.keySet()) {
            Account userAccount = usersWithAccount.get(userId);

            if (
                userAccount != null &&
                contract.Specific_Member__c != null &&
                userAccount.Id == contract.Specific_Member__c
            ) {
                sharings.add(createNewSharing(contract.Id, userId));
            }
        }
    }

    /**
     * Share Contract Agreement available for community users with "Education" type of Account
     * @param  contractId Id of Contract Agreement
     * @param  sharings   list of sharings
     */ 
    private static void shareToEducational(
        Id contractId,
        List<APXT_Redlining__Contract_Agreement__Share> sharings
    ) {
        for (Id userId : usersWithAccount.keySet()) {
            Account userAccount = usersWithAccount.get(userId);

            if (userAccount != null && userAccount.Type == 'Education') {
                sharings.add(createNewSharing(contractId, userId));
            }
        }
    }

    /**
     * Create Apex Share object for Contract Agreement
     * @param  contractId contractId description
     * @param  userId     userId description
     * @return            return description
     */ 
    private static APXT_Redlining__Contract_Agreement__Share createNewSharing(
        Id contractId,
        Id userId
    ) {
        APXT_Redlining__Contract_Agreement__Share contractShr = new APXT_Redlining__Contract_Agreement__Share();
        contractShr.ParentId = contractId;
        contractShr.UserOrGroupId = userId;
        contractShr.AccessLevel = 'Read';

        return contractShr;
    }

    /**
     * Future method to insert Apex Share objects to Database
     * @param  sharingsJSON Apex Share objects in JSON format
     */ 
    @future
    private static void insertSharings(String sharingsJSON) {
        List<APXT_Redlining__Contract_Agreement__Share> sharings = (List<APXT_Redlining__Contract_Agreement__Share>) JSON.deserialize(
            sharingsJSON,
            List<APXT_Redlining__Contract_Agreement__Share>.class
        );
        insert sharings;
    }

    /**
     * When Contract Agreement record fields APXT_Redlining__Status__c, 
     * Contract_Eligibility__c, RecordTypeId or Specific_Member__c are 
     * changed, deletes old sharings 
     * (APXT_Redlining__Contract_Agreement__Share) and creates new sharings 
     * for community members according to new field values.
     * Share objects are inserted in @future method.
     * @param  oldContracts the map of Contract Agreement object records before update
     * @param  newContracts the map of Contract Agreement object records after update
     */ 
    public static void shareOnUpdate(
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

        usersWithAccount = UserService.getUsersWithAccount();
        deleteOldSharings(contractsToUpdate.keySet());
        share(contractsToUpdate.Values());
    }

    /**
     * Check that spicific fields of Contract Agreement were changed
     * @param  oldContracts the map of Contract Agreement object records before update
     * @param  newContracts the map of Contract Agreement object records after update
     * @return              map of Contract Agreement with changes
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
            if (
                oldContr.APXT_Redlining__Status__c !=
                newContr.APXT_Redlining__Status__c ||
                oldContr.Contract_Eligibility__c !=
                newContr.Contract_Eligibility__c ||
                oldContr.RecordTypeId != newContr.RecordTypeId ||
                oldContr.Specific_Member__c != newContr.Specific_Member__c
            ) {
                updatedContracts.put(contrId, newContr);
            }
        }
        return updatedContracts;
    }

    /**
     * Delete old Apex Share objects
     * @param  contractIds set of Contract Agreement Ids to delete sharings
     */ 
    private static void deleteOldSharings(Set<Id> contractIds) {
        if (!contractIds.isEmpty()) {
            List<APXT_Redlining__Contract_Agreement__Share> oldSharings = [
                SELECT Id
                FROM APXT_Redlining__Contract_Agreement__Share
                WHERE ParentId IN :contractIds
            ];

            DMLWithoutSharingUtility.deleteContractAgreementSharings(oldSharings);
        }
    }

    /**
     * When created new User with “Member” profile, creates new sharings 
     * (APXT_Redlining__Contract_Agreement__Share) to share Contract 
     * Agreement objects with record type “MSA”, “Amendment” or “Product 
     * Agreement” and APXT_Redlining__Status__c field value equals 
     * “Activated” or “Being Amended” according to member’s Account and 
     * APXT_Redlining__Contract_Agreement__c.Contract_Eligibility__c field value.
     * Share objects are inserted in @future method.
     * @param  users the list of new User objects
     */ 
    public static void shareOnMemberCreate(List<User> users) {
        usersWithAccount = UserService.getUsersWithAccount(users);
        List<APXT_Redlining__Contract_Agreement__c> contracts = [
            SELECT
                RecordTypeId,
                APXT_Redlining__Status__c,
                Contract_Eligibility__c,
                Specific_Member__c
            FROM APXT_Redlining__Contract_Agreement__c
            WHERE
                RecordTypeId IN (
                    :MSA_RECORD_TYPE,
                    :AMENDNENT_RECORD_TYPE,
                    :PRODUCT_AGREEMENT_RECORD_TYPE
                )
                AND APXT_Redlining__Status__c IN ('Activated', 'Being Amended')
        ];
        share(contracts);
    }
}