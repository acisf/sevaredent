/**
 * Handler for User trigger. Provides functionality for 
 * sharing Contract Agreements, Contract Implementations and Item 
 * Pricing object records to certain community members.
 */ 
public with sharing class UserTriggerHandler {
    private static Id MEMBER_PROFILE_ID = CommunitySettings__mdt.getInstance('Sevaredent_Portal').Member_Profile_ID__c;

    /**
     * When a new User with profile “Member” is created, delegates creation 
     * of sharings for Contract Agreement object records for this User to 
     * ContractSharing class.
     * @param  users the list of Users to create sharings
     */ 
    public static void shareContractAgreements(List<User> users) {
        Map<Id, User> usersToShare = getUsersToShare(users);
        if (usersToShare.isEmpty()) {
            return;
        }
        ContractSharing.shareOnMemberCreate(usersToShare.values());
    }

    /**
     * Check if the Uesr is 'Member'
     * @param  users the list of new Users
     * @return       the list of Users with "Member" profile
     */ 
    private static Map<Id, User> getUsersToShare(List<User> users) {
        Map<Id, User> usersToShare = new Map<Id, User>();

        if (Test.isRunningTest()) {
            MEMBER_PROFILE_ID = [
                SELECT Id
                FROM Profile
                WHERE Name = 'Member'
                LIMIT 1
            ]
            ?.Id;
        }
        
        for (User u : users) {
            if (u.ProfileId == MEMBER_PROFILE_ID) {
                usersToShare.put(u.Id, u);
            }
        }

        return usersToShare;
    }

    /**
     * When a new User with profile “Member” is created, delegates creation 
     * of sharings for Contract Implementations object records for this 
     * User to ContractImplementationTriggerHandler class.
     * @param  users the list of Users to create sharings
     */ 
    public static void shareContractImplementations(List<User> users) {
        Map<Id, User> usersToShare = getUsersToShare(users);
        if (usersToShare.isEmpty()) {
            return;
        }
        ContractImplementationTriggerHandler.shareOnMemberCreate(
            usersToShare.values()
        );
    }

    /**
     * When a new User with profile “Member” is created, delegates creation 
     * of sharings for Item Pricing object records for this User to 
     * ItemPricingSharingBatch class.
     * @param  usersMap the map of Users to create sharings
     */ 
    public static void shareItemPricings(Map<Id, User> usersMap) {
        Map<Id, User> usersToShare = getUsersToShare(usersMap.values());
        
        if (!usersToShare.isEmpty()) {
            ItemPricingSharingBatch share = new ItemPricingSharingBatch(
                usersToShare
            );
            Id jobId = Database.executeBatch(share);
        }
    }
}