/**
 * Batchable class that is called from other classes when it is 
 * necessary to create sharings for Item Pricing object records 
 * (Item_Pricing__Share) in batches.
 */ 
global class ItemPricingSharingBatch implements Database.Batchable<sObject>, Database.Stateful {
    Set<Id> userIds;
    List<User> users;
    List<Contract_Implementations__c> updatedImpls;
    Map<Id, APXT_Redlining__Contract_Agreement__c> updatedContracts;
    Map<Id, Set<Id>> accountsByAgreements = new Map<Id, Set<Id>>();
    Integer successNumber = 0;
    Integer failedNumber = 0;
    String errorMessage = ' ';

    public ItemPricingSharingBatch(Map<Id, User> usersMap) {
        this.userIds = usersMap.keySet();
        this.users = usersMap.values();
    }

    public ItemPricingSharingBatch(
        Map<Id, User> usersMap,
        List<Contract_Implementations__c> updatedImpls
    ) {
        this.userIds = usersMap.keySet();
        this.users = usersMap.values();
        this.updatedImpls = updatedImpls;
    }

    public ItemPricingSharingBatch(
        Map<Id, User> usersMap,
        Map<Id, APXT_Redlining__Contract_Agreement__c> updatedContracts
    ) {
        this.userIds = usersMap.keySet();
        this.users = usersMap.values();
        this.updatedContracts = updatedContracts;
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        Set<Id> activeContractsIds = new Map<Id, APXT_Redlining__Contract_Agreement__c>(
            [
                SELECT Id
                FROM APXT_Redlining__Contract_Agreement__c
                WHERE
                    APXT_Redlining__Status__c = 'Activated'
                    OR APXT_Redlining__Status__c = 'Being Amended'
            ]
        ).keySet();
        List<Contract_Implementations__c> implementations = this.updatedImpls !=
            null
            ? this.updatedImpls
            : [
                  SELECT Contract_Agreement__c, Account__c
                  FROM Contract_Implementations__c
                  WHERE
                      Account__c IN (
                          SELECT AccountId
                          FROM User
                          WHERE Id IN :this.userIds
                      )
                      AND Status__c IN ('Implemented', 'Partially Implemented')
                      AND Contract_Agreement__c IN :activeContractsIds
              ];

        Set<Id> contractIds = new Set<Id>();
        Set<Id> accIds;
        for (Contract_Implementations__c impl : implementations) {
            contractIds.add(impl.Contract_Agreement__c);
            accIds = this.accountsByAgreements.containsKey(
                    impl.Contract_Agreement__c
                )
                ? this.accountsByAgreements.get(impl.Contract_Agreement__c)
                : new Set<Id>();
            accIds.add(impl.Account__c);
            this.accountsByAgreements.put(impl.Contract_Agreement__c, accIds);
        }

        if (this.updatedContracts != null) {
            contractIds = this.updatedContracts.keySet();
        }

        return Database.getQueryLocator(
            [
                SELECT Id, Contract_Agreement__c
                FROM Item_Pricing__c
                WHERE Contract_Agreement__c IN :contractIds
            ]
        );
    }

    global void execute(
        Database.BatchableContext BC,
        List<Item_Pricing__c> scope
    ) {
        List<Item_Pricing__Share> sharings = new List<Item_Pricing__Share>();
        for (Item_Pricing__c item : scope) {
            if (sharingAllowed(item)) {
                Set<Id> accIds = this.accountsByAgreements.get(
                    item.Contract_Agreement__c
                );
                for (User u : this.users) {
                    if (u.AccountId != null && accIds.contains(u.AccountId)) {
                        Item_Pricing__Share itemShr = new Item_Pricing__Share();
                        itemShr.ParentId = item.Id;
                        itemShr.UserOrGroupId = u.Id;
                        itemShr.AccessLevel = 'Read';
                        sharings.add(itemShr);
                    }
                }
            }
        }

        try {
            successNumber = successNumber + scope.size();
            insert sharings;
        } catch (Exception e) {
            failedNumber = failedNumber + scope.size();
            errorMessage = errorMessage + ' ' + e.getMessage();
        }
    }

    global void finish(Database.BatchableContext BC) {
        System.debug('number of success batches: ' + successNumber);
        System.debug('number of failed batches: ' + failedNumber);
        System.debug('error message: ' + errorMessage);
    }

    private Boolean sharingAllowed(Item_Pricing__c item) {
        if (this.updatedImpls == null && this.updatedContracts == null) {
            return true;
        } else if (this.updatedImpls != null) {
            for (Contract_Implementations__c impl : this.updatedImpls) {
                if (
                    item.Contract_Agreement__c == impl.Contract_Agreement__c &&
                    (impl.Status__c == 'Implemented' ||
                    impl.Status__c == 'Partially Implemented')
                ) {
                    return true;
                }
            }
        } else if (this.updatedContracts != null) {
            for (
                APXT_Redlining__Contract_Agreement__c contract : this.updatedContracts.values()
            ) {
                if (
                    item.Contract_Agreement__c == contract.Id &&
                    (contract.APXT_Redlining__Status__c == 'Activated' ||
                    contract.APXT_Redlining__Status__c == 'Being Amended')
                ) {
                    return true;
                }
            }
        }

        return false;
    }
}