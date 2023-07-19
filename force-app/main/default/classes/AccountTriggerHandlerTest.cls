/**
 * Created by cshah on 05/09/20.
 */

@IsTest
public with sharing class AccountTriggerHandlerTest {
    static final Integer accountsToBeCreated = 5;
    @testSetup
    private static void testSetup() {
        List<Account> parentAccounts = createAccounts(null);
        insert parentAccounts;

        List<Account> childAccounts = new List<Account>();
        for(Account acc: parentAccounts) {
            childAccounts.addAll(createAccounts(acc.Id));
        }
        insert childAccounts;
    }
    // prepare accounts records for insert
    private static List<Account> createAccounts(Id parentId) {
        Id GPOMemberRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Member').getRecordTypeId();
        List<Account> listAccounts = new List<Account>();
        for(Integer i = 0; i< accountsToBeCreated; i++) {
            Account account = new Account();
            account.RecordTypeId = GPOMemberRecordTypeId;
            if(parentId == null) {
                account.Name = 'Test Account Member ' + i;
                account.Status__c = 'Active';
            } else {
                account.Name = 'Test Child Account Member ' + i;
                account.ParentId = parentId;
            }
            listAccounts.add(account);
        }
        return listAccounts;
    }
    private static List<Account> getAllAccounts() {
        return [SELECT Id, ParentId, Status__c FROM Account];
    }

    public static void addAccountInParentIdMap(Map<Id, List<Account>>accWithParentIds, Account acc) {
        if (accWithParentIds.containsKey(acc.ParentId)) {
            accWithParentIds.get(acc.ParentId).add(acc);
        } else {
            accWithParentIds.put(acc.ParentId, new List<Account>{acc});
        }
    }
    public static List<Account> getParentAccounts(List<Account> newAccountsList) {
        List<Account> accountWithoutParentId = new List<Account>();
        for (Account acc: newAccountsList) {
            if (acc.ParentId == null) {
                accountWithoutParentId.add(acc);
            }
        }
        return accountWithoutParentId;
    }
    public static Map<Id, List<Account>> getChildAccounts(List<Account> newAccountsList) {
        Map<Id, List<Account>> accountWithParentIds = new Map<Id, List<Account>>();
        for (Account acc: newAccountsList) {
            if (acc.ParentId != null) {
                addAccountInParentIdMap(accountWithParentIds, acc);
            }
        }
        return accountWithParentIds;
    }

    @IsTest
    private static void testParentAccountInactive() {
        List<Account> allAccounts = getAllAccounts();
        List<Account> parentAccounts = getParentAccounts(allAccounts);
        Map<Id, List<Account>> accountWithParentIds = getChildAccounts(allAccounts);

        List<Account> childAccountToUpdate = new List<Account>();
        childAccountToUpdate.addAll(setStatusActive(accountWithParentIds.get(parentAccounts[0].Id), 2));
        childAccountToUpdate.addAll(setStatusActive(accountWithParentIds.get(parentAccounts[1].Id), 3));
        update childAccountToUpdate;

        Account parentAccount = parentAccounts[0];
        parentAccount.Status__c = 'Inactive';
        try {
            update parentAccount;
        } catch (Exception e) {
            Boolean expectedExceptionThrown =  e.getMessage().contains('Parent Account cannot become inactive, if there are active children.') ? true : false;
            System.AssertEquals(expectedExceptionThrown, true);
        }
    }
    private static List<Account> setStatusActive(List<Account> childAccounts, Integer count) {
        List<Account> childAccountToUpdate = new List<Account>();
        for(Integer i = 0; i < count; i++) {
            Account acc = childAccounts[i];
            acc.Status__c = 'Active';
            childAccountToUpdate.add(acc);
        }
        return childAccountToUpdate;
    }
    @IsTest
    private static void testChangesInPublishedMember() {
        List<Account> allAccounts = getAllAccounts();

        Account newAccount = allAccounts[0];
        newAccount.Type = 'Test Type';
        newAccount.Status__c = 'Active';
        newAccount.Member_Start_Date__c = Date.newInstance(2020, 2, 17);
        newAccount.ShippingCity = 'DC';
        newAccount.BillingCity = 'DC';
        newAccount.Phone = '1234567890';
        newAccount.Practice_City_Name__c = 'W City';
        newAccount.Practice_State_Name__c = 'W State';
        newAccount.Published_Member__c = true;
        try {
            update newAccount;
        } catch (Exception e) {
            Boolean expectedExceptionThrown =  e.getMessage().contains('Need Roster permission set assigned to modify these fields after member is published: Name, Type, Status, Member Start Date, Shipping Address, Billing Address, Phone, Practice City Name, Practice State Name') ? true : false;
            System.AssertEquals(false, expectedExceptionThrown);
        }
        newAccount.Phone = '1234567891';
        try {
            update newAccount;
        } catch (Exception e) {
            Boolean expectedExceptionThrown =  e.getMessage().contains('Need Roster permission set assigned to modify these fields after member is published: Name, Type, Status, Member Start Date, Shipping Address, Billing Address, Phone, Practice City Name, Practice State Name') ? true : false;
            System.AssertEquals(true, expectedExceptionThrown);
        }
    }
    @IsTest
    private static void testChangesInPublishedMemberWithRosterPermission() {
        Id userId = UserInfo.getUserId();
        List<PermissionSet> permissionSet = [SELECT Id FROM PermissionSet WHERE Name = 'Roster' LIMIT 1];
        PermissionSetAssignment permissionSetAssignment = new PermissionSetAssignment(PermissionSetId = permissionSet[0].Id, AssigneeId = userId);
        insert permissionSetAssignment;

        List<Account> allAccounts = getAllAccounts();

        Account newAccount = allAccounts[0];
        newAccount.Type = 'Test Type';
        newAccount.Status__c = 'Active';
        newAccount.Member_Start_Date__c = Date.newInstance(2020, 2, 17);
        newAccount.ShippingCity = 'DC';
        newAccount.BillingCity = 'DC';
        newAccount.Phone = '1234567890';
        newAccount.Practice_City_Name__c = 'W City';
        newAccount.Practice_State_Name__c = 'W State';
        newAccount.Published_Member__c = true;
        try {
            update newAccount;
        } catch (Exception e) {
            Boolean expectedExceptionThrown =  e.getMessage().contains('Need Roster permission set assigned to modify these fields after member is published: Name, Type, Status, Member Start Date, Shipping Address, Billing Address, Phone, Practice City Name, Practice State Name') ? true : false;
            System.AssertEquals(false, expectedExceptionThrown);
        }
        newAccount.Practice_State_Name__c = 'Test state name changed';
        try {
            update newAccount;
        } catch (Exception e) {
            Boolean expectedExceptionThrown =  e.getMessage().contains('Need Roster permission set assigned to modify these fields after member is published: Name, Type, Status, Member Start Date, Shipping Address, Billing Address, Phone, Practice City Name, Practice State Name') ? true : false;
            System.assertEquals(false, expectedExceptionThrown);
        }
    }
}