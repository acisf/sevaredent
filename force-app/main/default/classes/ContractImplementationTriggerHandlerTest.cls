@isTest
public with sharing class ContractImplementationTriggerHandlerTest {
    @isTest
    static void shareOnCreate() {
        Test.startTest();

        APXT_Redlining__Contract_Agreement__c conAgree;
        User comUser;
        User otherUser;
        User owner = TestDataFactory.createOwner();

        System.runAs(owner) {
            Account acc = TestDataFactory.createAccount('User', null);
            Account otherAcc = TestDataFactory.createAccount('Other', null);
            Account customerAcc = TestDataFactory.createAccount();

            comUser = TestDataFactory.createCommunityUser(acc.Id, 'TestUser');
            otherUser = TestDataFactory.createCommunityUser(
                otherAcc.Id,
                'OtherUser'
            );

            conAgree = TestDataFactory.createContractAgreement(customerAcc);

            TestDataFactory.createContractImplementation(acc.Id, conAgree.Id);
        }

        Test.stopTest();

        System.runAs(comUser) {
            Integer contracts = [
                SELECT COUNT()
                FROM Contract_Implementations__c
                WHERE Contract_Agreement__c = :conAgree.Id
            ];
            System.assertEquals(
                contracts,
                1,
                'contract was not shared to correct user'
            );
        }

        System.runAs(otherUser) {
            Integer contracts = [
                SELECT COUNT()
                FROM Contract_Implementations__c
                WHERE Contract_Agreement__c = :conAgree.Id
            ];
            System.assertEquals(
                contracts,
                0,
                'contract was shared to unappropriate user'
            );
        }
    }

    @isTest
    static void shareOnUpdate() {
        Test.startTest();

        APXT_Redlining__Contract_Agreement__c conAgree;
        User comUser;
        User owner = TestDataFactory.createOwner();

        System.runAs(owner) {
            Account acc = TestDataFactory.createAccount('User', null);
            Account customerAcc = TestDataFactory.createAccount();

            comUser = TestDataFactory.createCommunityUser(acc.Id, 'TestUser');
            conAgree = TestDataFactory.createContractAgreement(customerAcc);

            TestDataFactory.createContractImplementation(acc.Id, conAgree.Id);
        }

        Test.stopTest();

        System.runAs(owner) {
            Contract_Implementations__c contract = [
                SELECT Status__c
                FROM Contract_Implementations__c
                WHERE Contract_Agreement__c = :conAgree.Id
                LIMIT 1
            ];

            contract.Status__c = 'Open';
            update contract;
        }

        System.runAs(comUser) {
            Integer contracts = [
                SELECT COUNT()
                FROM Contract_Implementations__c
                WHERE Contract_Agreement__c = :conAgree.Id
            ];
            System.assertEquals(
                0,
                contracts,
                'contract sharing was not changed'
            );
        }
    }
}