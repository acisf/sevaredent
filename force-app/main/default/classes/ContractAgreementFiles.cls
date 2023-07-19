/**
 * Provide functionality for files that are attached to Contract 
 * Agreement object. Contains static methods that could be called from 
 * Trigger or Trigger handler class.
 */
public with sharing class ContractAgreementFiles {
    private static final Id AFFORDABLE_CARE_ACCOUNT_ID = getAffordableCareAccountId();
    private static final String MEMBER_ACCOUNT_RECORD_TYPE = Schema.sObjectType.Account.getRecordTypeInfosByName()
        .get('Member')
        .getRecordTypeId();
    private static final String AMENDMENT_RECORD_TYPE = Schema.sObjectType.APXT_Redlining__Contract_Agreement__c.getRecordTypeInfosByName()
        .get('Amendment')
        .getRecordTypeId();
    private static List<Account> accountsAll;
    private static List<Account> accountsAffordable;
    private static List<Account> accountsCommercial;
    private static List<Account> accountsEducational;

    /**
     * When a file is inserted to org it will be linked to existing active 
     * accounts with ‘Member’ record type. Link created depending on 
     * ContentVersion.Visibility__c field value and account type or 
     * relation to “Affordable Care” account.
     * @param  newList      the list of inserted files
     */
    public static void linkFilesOnInsert(List<ContentVersion> newList) {
        accountsAll = [
            SELECT Id, Name, Top_Parent_Id__c, Type
            FROM Account
            WHERE
                RecordTypeId = :MEMBER_ACCOUNT_RECORD_TYPE
                AND Status__c = 'Active'
        ];
        linkFilesToAccounts(newList);
    }

    /**
     * Link file to proper Account
     * @param  newList the list of files to link
     */ 
    private static void linkFilesToAccounts(List<ContentVersion> newList) {
        sortAccountsByCategireis();

        Map<String, Set<Id>> vDocMap = new Map<String, Set<Id>>();
        Set<Id> dIds;

        for (ContentVersion cv : newList) {
            dIds = vDocMap.containsKey(cv.Visibility__c)
                ? vDocMap.get(cv.Visibility__c)
                : new Set<Id>();
            dIds.add(cv.ContentDocumentId);
            vDocMap.put(cv.Visibility__c, dIds);
        }

        createLinks(accountsAll, vDocMap.get('All'));
        createLinks(accountsAffordable, vDocMap.get('Affordable Care'));
        createLinks(accountsCommercial, vDocMap.get('Commercial'));
        createLinks(accountsEducational, vDocMap.get('Education'));
    }

    /**
     * Sort available accounts by categories according to their Type
     * and relation to "Affordable Care" Account
     */ 
    private static void sortAccountsByCategireis() {
        if (accountsAll != null && !accountsAll.isEmpty()) {
            accountsAffordable = new List<Account>();
            accountsCommercial = new List<Account>();
            accountsEducational = new List<Account>();

            for (Account acc : accountsAll) {
                if (acc.Type == 'Education') {
                    accountsEducational.add(acc);
                } else if (acc.Id == AFFORDABLE_CARE_ACCOUNT_ID) {
                    accountsAffordable.add(acc);
                } else if (acc.Id != AFFORDABLE_CARE_ACCOUNT_ID) {
                    accountsCommercial.add(acc);
                }
            }
        }
    }

    /**
     * Create ContentDocumentLink objects between files and Accounts
     * @param  accounts the list of accounts
     * @param  files    the list of files
     */ 
    private static void createLinks(List<Account> accounts, Set<Id> files) {
        if (
            accounts != null &&
            !accounts.isEmpty() &&
            files != null &&
            !files.isEmpty()
        ) {
            List<ContentDocumentLink> linksToInsert = new List<ContentDocumentLink>();

            for (Account acc : accounts) {
                if (acc.Top_Parent_Id__c == acc.Id) {
                    for (Id fileId : files) {
                        ContentDocumentLink link = new ContentDocumentLink(
                            ContentDocumentId = fileId,
                            LinkedEntityId = acc.Id,
                            ShareType = 'V',
                            Visibility = 'AllUsers'
                        );
                        linksToInsert.add(link);
                    }
                }
            }
            DMLWithoutSharingUtility.createContentDocumentLinks(linksToInsert);
        }
    }

    /**
     * Get Id of "Affordable Care" Account from Custom Metadata Types
     * @return   Id of "Affordable Care" Account
     */ 
    private static Id getAffordableCareAccountId() {
        if (Test.isRunningTest()) {
            return [
                SELECT Id
                FROM Account
                WHERE Name = 'Test Affordable'
                LIMIT 1
            ]
            ?.Id;
        } else {
            return CommunitySettings__mdt.getInstance('Sevaredent_Portal')
                .Affordable_Care_Account_ID__c;
        }
    }

    /**
     * When ContentVersion.Visibility__c field value of a file is changed 
     * file will be linked to existing active accounts with ‘Member’ record 
     * type according to new visibility. Link created depending on 
     * ContentVersion.Visibility__c field value and account type or 
     * relation to “Affordable Care” account. Old links are deleted.
     * @param  oldMap the map of files before update
     * @param  newMap the map of files after update
     */ 
    public static void linkFilesOnUpdate(
        Map<Id, ContentVersion> oldMap,
        Map<Id, ContentVersion> newMap
    ) {
        accountsAll = [
            SELECT Id, Name, Top_Parent_Id__c, Type
            FROM Account
            WHERE
                RecordTypeId = :MEMBER_ACCOUNT_RECORD_TYPE
                AND Status__c = 'Active'
        ];

        List<ContentVersion> listToUpdate = documentsWithCangedVisibility(
            oldMap,
            newMap
        );

        if (!listToUpdate.isEmpty()) {
            removeExistingLinks(listToUpdate);
            linkFilesToAccounts(listToUpdate);
        }
    }

    /**
     * Check the ContentVersion.Visibility__c field is changed
     * @param  oldMap the map of files before update
     * @param  newMap the map of files after update
     * @return        list of files with changed visibilty
     */
    private static List<ContentVersion> documentsWithCangedVisibility(
        Map<Id, ContentVersion> oldMap,
        Map<Id, ContentVersion> newMap
    ) {
        List<ContentVersion> listToUpdate = new List<ContentVersion>();
        for (Id cvId : oldMap.keySet()) {
            ContentVersion oldCV = oldMap.get(cvId);
            ContentVersion newCV = newMap.get(cvId);

            if (oldCV.Visibility__c != newCV.Visibility__c) {
                listToUpdate.add(newCV);
            }
        }

        return listToUpdate;
    }

    /**
     * Remove links for files with changed visibilty
     * @param  listToUpdate list of files with changed visibilty
     */ 
    private static void removeExistingLinks(List<ContentVersion> listToUpdate) {
        Set<Id> accountIds = new Map<Id, Account>(accountsAll).keySet();
        Set<Id> docIds = getContentDocumentIds(listToUpdate);

        List<ContentDocumentLink> links = [
            SELECT Id
            FROM ContentDocumentLink
            WHERE ContentDocumentId IN :docIds AND LinkedEntityId IN :accountIds
            LIMIT 1000
        ];

        if (!links.isEmpty()) {
            DMLWithoutSharingUtility.deleteContentDocumentLinks(links);
        }
    }

    /**
     * Get ContentDocumentId of file from ContentVersion object
     * @param  listToUpdate list of files with changed visibilty
     * @return              list of ContentDocumentId
     */ 
    private static Set<Id> getContentDocumentIds(
        List<ContentVersion> listToUpdate
    ) {
        Set<Id> docIds = new Set<Id>();

        for (ContentVersion cv : listToUpdate) {
            docIds.add(cv.ContentDocumentId);
        }

        return docIds;
    }

    /**
     * When new account created on the org, all files that must be 
     * available for this account according to ContentVersion.Visibility__c 
     * field value and account type, record type or relation to “Affordable 
     * Care” account would be linked to this account.
     * @param  newAccounts the list of inserted accounts
     */
    public static void linkFilesOnAccountCreate(List<Account> newAccounts) {
        accountsAll = getAccountsToUpdate(newAccounts);

        if (accountsAll.isEmpty()) {
            return;
        }

        List<ContentVersion> fileList = [
            SELECT Visibility__c, ContentDocumentId
            FROM ContentVersion
            WHERE
                Visibility__c IN (
                    'All',
                    'Affordable Care',
                    'Commercial',
                    'Education'
                )
            LIMIT 50000
        ];

        linkFilesToAccounts(fileList);
    }

    /**
     * Check that Account has proper record type and status
     * @param  newAccounts list of inserted accounts
     * @return             list of accounts with proper parameters
     */ 
    private static List<Account> getAccountsToUpdate(
        List<Account> newAccounts
    ) {
        List<Account> accountsToUpdate = new List<Account>();
        for (Account acc : newAccounts) {
            if (
                acc.RecordTypeId == MEMBER_ACCOUNT_RECORD_TYPE &&
                acc.Status__c == 'Active'
            ) {
                accountsToUpdate.add(acc);
            }
        }

        return accountsToUpdate;
    }

    /**
     * When account RecordTypeId or Status__c field changed on the org, 
     * links for old files are deleted, and new links are created according 
     * to ContentVersion.Visibility__c field value and new account field 
     * values.
     * @param  oldAccounts the map of accounts before update
     * @param  newAccounts the map of accounts after update
     */
    public static void linkFilesOnAccountUpdate(
        Map<Id, Account> oldAccounts,
        Map<Id, Account> newAccounts
    ) {
        accountsAll = getAccountsToUpdate(oldAccounts, newAccounts);
        if (!accountsAll.isEmpty()) {
            List<ContentVersion> fileList = [
                SELECT Visibility__c, ContentDocumentId
                FROM ContentVersion
                WHERE
                    Visibility__c IN (
                        'All',
                        'Affordable Care',
                        'Commercial',
                        'Education'
                    )
                LIMIT 50000
            ];

            removeExistingLinks(fileList);

            accountsAll = getAccountsToUpdate(accountsAll);
            linkFilesToAccounts(fileList);
        }
    }

    /**
     * Check Account RecordTypeId and Status__c field values changed
     * @param  oldAccounts the map of accounts before update
     * @param  newAccounts the map of accounts after update
     * @return             list of accounts with changed fields
     */ 
    private static List<Account> getAccountsToUpdate(
        Map<Id, Account> oldAccounts,
        Map<Id, Account> newAccounts
    ) {
        List<Account> updatedAccounts = new List<Account>();
        for (Id accId : newAccounts.keySet()) {
            Account oldAcc = oldAccounts.get(accId);
            Account newAcc = newAccounts.get(accId);
            if (
                oldAcc.RecordTypeId != newAcc.RecordTypeId ||
                oldAcc.Status__c != newAcc.Status__c
            ) {
                updatedAccounts.add(newAcc);
            }
        }
        return updatedAccounts;
    }

    /**
     * Returns a list of files that are linked to the account of a current 
     * user and certain Contract Agreement object record.
     * @param  contractId Id of Contract Agreement object record
     * @return            list of files
     */ 
    public static List<ContentVersion> getRelatedFiles(Id contractId) {
        Id accountId = getUserAccountId();
        Set<Id> cdIds = getUserAvailableFileIds(contractId, accountId);

        return !cdIds.isEmpty()
            ? [
                  SELECT
                      ContentDocumentId,
                      Title,
                      ContentSize,
                      ContentModifiedDate,
                      FileExtension
                  FROM ContentVersion
                  WHERE ContentDocumentId IN :cdIds
              ]
            : new List<ContentVersion>();
    }

    /**
     * Get AccountId of current User
     * @return   current User AccountId
     */
    private static Id getUserAccountId() {
        Id contactId = [
            SELECT ContactId
            FROM User
            WHERE Id = :UserInfo.getUserId()
        ]
        ?.ContactId;
        return [SELECT AccountId FROM Contact WHERE Id = :contactId]?.AccountId;
    }

    /**
     * Get ContentDocumentId of files that is linked to Account and to 
     * Contract Agreement in the same time
     * @param  contractId Id of Contract Agreement
     * @param  accountId  Id of Account
     * @return            list of ContentDocumentId
     */ 
    private static Set<Id> getUserAvailableFileIds(
        Id contractId,
        Id accountId
    ) {
        if (accountId == null) {
            return new Set<Id>();
        } else {
            Set<Id> cdIds = new Set<Id>();
            List<ContentDocumentLink> filesOnContract = [
                SELECT ContentDocumentId
                FROM ContentDocumentLink
                WHERE LinkedEntityId = :contractId
            ];
            List<ContentDocumentLink> filesOnAccount = [
                SELECT ContentDocumentId
                FROM ContentDocumentLink
                WHERE LinkedEntityId = :accountId
            ];

            for (ContentDocumentLink contractFile : filesOnContract) {
                for (ContentDocumentLink accountFile : filesOnAccount) {
                    if (
                        contractFile.ContentDocumentId ==
                        accountFile.ContentDocumentId
                    ) {
                        cdIds.add(accountFile.ContentDocumentId);
                    }
                }
            }
            return cdIds;
        }
    }

    /**
     * When the Contract Agreement APXT_Redlining__Status__c field changes 
     * to “Activated” and record type is “Amendment”, links for related 
     * files of old Contract Agreement are deleted. Links for these files 
     * to the new (amendment) Contract Agreement are created.
     * @param  oldContracts the map of Contract Agreement object records before update
     * @param  newContracts the map of Contract Agreement object records after update
     */ 
    public static void reparentFilesOnAmendment(
        Map<Id, APXT_Redlining__Contract_Agreement__c> oldContracts,
        Map<Id, APXT_Redlining__Contract_Agreement__c> newContracts
    ) {
        Map<Id, Id> activeByParentContractIds = mapActiveByParentContractIds(
            oldContracts,
            newContracts
        );

        if (!activeByParentContractIds.isEmpty()) {
            reparent(activeByParentContractIds);
        }
    }

    /**
     * Removes link between old Contract Agreement and the file and create new link
     * between new Contract Agreement and the file
     * @param  activeByParentContractIds map of active Contract Agreement Id by 
     *                                   old Contract Agreement Id
     */ 
    private static void reparent(Map<Id, Id> activeByParentContractIds) {

        List<ContentDocumentLink> filesOnContracts = [
                SELECT ContentDocumentId, LinkedEntityId, ShareType, Visibility
                FROM ContentDocumentLink
                WHERE
                    LinkedEntityId IN :activeByParentContractIds.keySet()
            ];

        Map<Id, List<ContentDocumentLink>> filesByNewContracts = mapFilesByNewContracts(
            activeByParentContractIds,
            filesOnContracts
        );

        createNewLinks(filesByNewContracts);
        
        DMLWithoutSharingUtility.deleteContentDocumentLinks(filesOnContracts);
    }

    /**
     * Maps files from old Contract Agreement by new Contract Agreement Id
     * @param  activeByParentContractIds map of new Contract Agreement Id by old Contract Agreement
     * @param  filesOnContracts          list of files from Contrac Agreements
     * @return                           map of files by Contract Agreement Id
     */ 
    private static Map<Id, List<ContentDocumentLink>> mapFilesByNewContracts(
        Map<Id, Id> activeByParentContractIds,
        List<ContentDocumentLink> filesOnContracts
    ) {
        Map<Id, List<ContentDocumentLink>> filesByContracts = new Map<Id, List<ContentDocumentLink>>();
        List<ContentDocumentLink> files;
        for (ContentDocumentLink link : filesOnContracts) {
            files = filesByContracts.containsKey(link.LinkedEntityId)
                ? filesByContracts.get(link.LinkedEntityId)
                : new List<ContentDocumentLink>();
            files.add(link);
            filesByContracts.put(link.LinkedEntityId, files);
        }

        Map<Id, List<ContentDocumentLink>> filesByNewContracts = new Map<Id, List<ContentDocumentLink>>();
        for (Id contractId : filesByContracts.keySet()) {
            filesByNewContracts.put(
                activeByParentContractIds.get(contractId),
                filesByContracts.get(contractId)
            );
        }

        return filesByNewContracts;
    }

    /**
     * Maps new Contract Agreement Id by old Contract Agreement
     * @param  oldContracts the map of Contract Agreement object records before update
     * @param  newContracts the map of Contract Agreement object records after update
     * @return              map of new Contract Agreement Id by old Contract Agreement
     */ 
    private static Map<Id, Id> mapActiveByParentContractIds(
        Map<Id, APXT_Redlining__Contract_Agreement__c> oldContracts,
        Map<Id, APXT_Redlining__Contract_Agreement__c> newContracts
    ) {
        Map<Id, Id> activeByParentContractIds = new Map<Id, Id>();
        for (Id conId : newContracts.keySet()) {
            APXT_Redlining__Contract_Agreement__c oldContract = oldContracts.get(
                conId
            );
            APXT_Redlining__Contract_Agreement__c newContract = newContracts.get(
                conId
            );

            if (
                oldContract.APXT_Redlining__Status__c !=
                newContract.APXT_Redlining__Status__c &&
                newContract.RecordTypeId == AMENDMENT_RECORD_TYPE &&
                newContract.APXT_Redlining__Status__c == 'Activated'
            ) {
                activeByParentContractIds.put(
                    newContract.APXT_Redlining__Contract_Agreement_Family_Parent__c,
                    newContract.Record_Id__c
                );
            }
        }

        return activeByParentContractIds;
    }

    /**
     * Create ContentDocumentLink objects to link files to new Contract Agreements
     * @param  filesByContracts map of files by Contract Agreement Id
     */
    private static void createNewLinks(
        Map<Id, List<ContentDocumentLink>> filesByContracts
    ) {
        List<ContentDocumentLink> links = new List<ContentDocumentLink>();
        for (Id contractId : filesByContracts.keySet()) {
            for (ContentDocumentLink file : filesByContracts.get(contractId)) {
                ContentDocumentLink link = new ContentDocumentLink(
                    ContentDocumentId = file.ContentDocumentId,
                    LinkedEntityId = contractId,
                    ShareType = file.ShareType,
                    Visibility = file.Visibility
                );
                links.add(link);
            }
        }

        DMLWithoutSharingUtility.createContentDocumentLinks(links);
    }
}