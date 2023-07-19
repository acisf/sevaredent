/**
 * Batchable class that is called from other classes when it is 
 * necessary to update sharings for Item Pricing object records 
 * (Item_Pricing__Share) in batches.
 */ 
global class ItemPricingUpdateSharingBatch implements Database.Batchable<sObject>, Database.Stateful {
    Set<Id> userIds;
    List<User> users;
    List<Contract_Implementations__c> updatedImpls;
    Map<Id,APXT_Redlining__Contract_Agreement__c> updatedContracts;
    Map<Id, Set<Id>> accountsByAgreements = new Map<Id, Set<Id>>();
    Integer successNumber = 0;
    Integer failedNumber = 0;
    String errorMessage = ' ';

    public ItemPricingUpdateSharingBatch(
        Map<Id, User> usersMap,
        List<Contract_Implementations__c> updatedImpls
    ) {
        this.userIds = usersMap.keySet();
        this.users = usersMap.values();
        this.updatedImpls = updatedImpls;
    }

    public ItemPricingUpdateSharingBatch(
        Map<Id, User> usersMap,
        Map<Id,APXT_Redlining__Contract_Agreement__c> updatedContracts
    ) {
        this.userIds = usersMap.keySet();
        this.users = usersMap.values();
        this.updatedContracts = updatedContracts;
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        Set<Id> contractIds = new Set<Id>();
        if (this.updatedImpls != null) {
            for (Contract_Implementations__c impl : this.updatedImpls) {
                contractIds.add(impl.Contract_Agreement__c);
            }
        } else if (this.updatedContracts != null) {
            contractIds = this.updatedContracts.keySet();
        }

        return Database.getQueryLocator(
            [
                SELECT Id
                FROM Item_Pricing__Share
                WHERE
                    ParentId IN (
                        SELECT Id
                        FROM Item_Pricing__c
                        WHERE Contract_Agreement__c IN :contractIds
                    )
                    AND UserOrGroupId IN :this.userIds
            ]
        );
    }

    global void execute(
        Database.BatchableContext BC,
        List<Item_Pricing__Share> scope
    ) {
        try {
            DMLWithoutSharingUtility.deleteItemPricingSharings(scope);
            successNumber = successNumber + scope.size();
        } catch (Exception e) {
            failedNumber = failedNumber + scope.size();
            errorMessage = errorMessage + ' ' + e.getMessage();
        }
    }

    global void finish(Database.BatchableContext BC) {
        System.debug(
            'number of successfully deleted batches: ' + successNumber
        );
        System.debug('number of failed to delete batches: ' + failedNumber);
        System.debug('error message: ' + errorMessage);

        ItemPricingSharingBatch share;

        if (this.updatedImpls != null) {
            share = new ItemPricingSharingBatch(
                new Map<Id,User>(this.users),
                this.updatedImpls
            );
        } else if (this.updatedContracts != null) {
            share = new ItemPricingSharingBatch(
                new Map<Id,User>(this.users),
                this.updatedContracts
            );
        }
        if (share != null) {
            Id jobId = Database.executeBatch(share);
        }
    }
}