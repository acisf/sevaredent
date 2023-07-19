/**
 * Service class designed to get information about User and compose it 
 * in desired format.
 */ 
public with sharing class UserService {
    private static final Id MEMBER_PROFILE_ID = [
        SELECT Id
        FROM Profile
        WHERE Name = 'Member'
        LIMIT 1
    ]
    ?.Id;

    /**
     * Maps all active users with “Member” profile on the org with their accounts.
     * @return   map of Accounts by User's Ids
     */ 
    public static Map<Id, Account> getUsersWithAccount() {
        Map<Id, Account> users = new Map<Id, Account>();
        Map<Id, Id> usersByContacts = mapUserByContactIds(null);
        Map<Id, Account> accountsByContacts = mapAccountByContactIds(
            usersByContacts.keySet()
        );

        for (Id contId : usersByContacts.keySet()) {
            users.put(
                usersByContacts.get(contId),
                accountsByContacts.get(contId)
            );
        }

        return users;
    }

    /**
     * Maps User Id by its Contact Id
     * @param  newUsers newUsers description
     * @return          map of User Id by Contact Id
     */
    private static Map<Id, Id> mapUserByContactIds(List<User> newUsers) {
        Map<Id, Id> usersByContacts = new Map<Id, Id>();

        List<User> users = newUsers != null ? newUsers : [
            SELECT Id, ContactId
            FROM User
            WHERE ProfileId = :MEMBER_PROFILE_ID AND isActive = true
        ];

        for (User u : users) {
            usersByContacts.put(u.ContactId, u.Id);
        }

        return usersByContacts;
    }

    /**
     * Maps Account Id by specific Contact Id
     * @param  contactIds set of Contact Ids
     * @return            map of Account Ids by Contact Ids
     */ 
    private static Map<Id, Account> mapAccountByContactIds(Set<Id> contactIds) {
        Map<Id, Account> accsByContacts = new Map<Id, Account>();

        for (Contact cnt : [
            SELECT Account.Name, Account.Type
            FROM Contact
            WHERE Id IN :contactIds
        ]) {
            accsByContacts.put(cnt.Id, cnt.Account);
        }

        return accsByContacts;
    }

    /**
     * Maps active users with “Member” profile on the org with their 
     * accounts from a certain list of Users.
     * @param  newUsers the list of Users to handle
     * @return          map of Accounts by User's Ids
     */ 
    public static Map<Id, Account> getUsersWithAccount(List<User> newUsers) {
        Map<Id, Account> users = new Map<Id, Account>();
        Map<Id, Id> usersByContacts = mapUserByContactIds(newUsers);
        Map<Id, Account> accountsByContacts = mapAccountByContactIds(
            usersByContacts.keySet()
        );

        for (Id contId : usersByContacts.keySet()) {
            users.put(
                usersByContacts.get(contId),
                accountsByContacts.get(contId)
            );
        }

        return users;
    }
}