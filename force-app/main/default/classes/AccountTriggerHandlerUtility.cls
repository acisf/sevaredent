/**
 * Created by cshah on 03-09-2020.
 */

public without sharing class AccountTriggerHandlerUtility {
    // Once member is published, all roster related fields should only be editable by individuals with roster permission set
    public static void checkIfRosterFieldsChangedAfterPublished(Map<Id, Account> oldMap, Map<Id, Account> newMap) {
        System.debug(' AccountTriggerHandlerUtility.checkIfRosterFieldsChangedAfterPublished : ');
        for(Account newAccount: newMap.values()) {
            if (newAccount.Published_Member__c == true && oldMap.get(newAccount.Id).Published_Member__c == true) {
                if((newAccount.Name != oldMap.get(newAccount.Id).Name)
                    || (newAccount.Type != oldMap.get(newAccount.Id).Type)
                    || (newAccount.Status__c != oldMap.get(newAccount.Id).Status__c)
                    || (newAccount.Member_Start_Date__c != oldMap.get(newAccount.Id).Member_Start_Date__c)
                    || (newAccount.ShippingAddress != oldMap.get(newAccount.Id).ShippingAddress)
                    || (newAccount.BillingAddress != oldMap.get(newAccount.Id).BillingAddress)
                    || (newAccount.Phone != oldMap.get(newAccount.Id).Phone)
                    || (newAccount.Practice_City_Name__c != oldMap.get(newAccount.Id).Practice_City_Name__c)
                    || (newAccount.Practice_State_Name__c != oldMap.get(newAccount.Id).Practice_State_Name__c)
                    ) {
                    Id userId = UserInfo.getUserId();
                    List<PermissionSetAssignment> permissionAssignee = [SELECT Id, PermissionSetId, PermissionSet.Name, PermissionSet.ProfileId, PermissionSet.Profile.Name, AssigneeId, Assignee.Name FROM PermissionSetAssignment WHERE AssigneeId = :userId AND PermissionSet.Name = 'Roster'];
                    if(permissionAssignee.isEmpty()) {
                        System.debug(' AccountTriggerHandlerUtility.checkIfRosterFieldsChangedAfterPublished : Need Roster permission set assigned to modify these fields .');
                        newAccount.addError('Need Roster permission set assigned to modify these fields after member is published: Name, Type, Status, Member Start Date, Shipping Address, Billing Address, Phone, Practice City Name, Practice State Name');
                    }
                }
            }
        }
    }
    // Before Update: Check Parent Account cannot become inactive, if there are active children
    public static void checkIfActiveChildPresent(Map<Id, Account> oldMap, Map<Id, Account> newMap) {
        System.debug(' AccountTriggerHandlerUtility.checkIfActiveChildPresent : ');
        Map<Id, Account> parentAccountsByIds = new Map<Id, Account>();
        // Separate all parents account for which Status changed from active to inactive
        for(Account newAccount: newMap.values()) {
            if (newAccount.ParentId == null && newAccount.Status__c != null && oldMap.get(newAccount.Id).Status__c != null && newAccount.Status__c.equalsIgnoreCase('Inactive') && oldMap.get(newAccount.Id).Status__c.equalsIgnoreCase('Active')) {
                parentAccountsByIds.put(newAccount.Id, newAccount);
            }
        }
        System.debug(' AccountTriggerHandlerUtility.checkIfActiveChildPresent parentAccountsByIds : ' + JSON.serialize(parentAccountsByIds));
        // if we found any parent account which status is about to change from active to inactive, then check for active child records and add error, not to update
        if (parentAccountsByIds.keySet().size() > 0) {
            String status = 'Active';
            List<Account> childAccounts = [SELECT Id, ParentId FROM Account WHERE ParentId IN :parentAccountsByIds.keySet() AND Status__c = :status ORDER BY ParentId];
            System.debug(' AccountTriggerHandlerUtility.checkIfActiveChildPresent childAccounts : ' + JSON.serialize(childAccounts));
            // Map to parent id and their active child count
            Set<Id> parentIdOfActiveChild = new Set<Id>();
            for(Account account: childAccounts) {
                if (!parentIdOfActiveChild.contains(account.ParentId)) {
                    parentIdOfActiveChild.add(account.ParentId);
                    Account newAccount = parentAccountsByIds.get(account.ParentId);
                    newAccount.Status__c.addError('Parent Account cannot become inactive, if there are active children.');
                }
            }
            System.debug(' AccountTriggerHandlerUtility.checkIfActiveChildPresent parentIdOfActiveChild : ' + JSON.serialize(parentIdOfActiveChild));
        }
    }

}