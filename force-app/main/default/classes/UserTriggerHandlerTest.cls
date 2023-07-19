@isTest
public with sharing class UserTriggerHandlerTest {
    @TestSetup
    static void makeData() {
        Test.startTest();

        User owner = TestDataFactory.createOwner();
        System.runAs(owner) {
            Account customerAcc = TestDataFactory.createAccount();
            Account accountAll = TestDataFactory.createAccount('All', null);
            Account accountSpecific = TestDataFactory.createAccount(
                'Specific',
                null
            );
            Account accountEdication = TestDataFactory.createAccount(
                'Test',
                'Education'
            );

            TestDataFactory.createContractAgreements(
                customerAcc,
                accountSpecific.Id
            );

            User userAll = TestDataFactory.createCommunityUser(
                accountAll.Id,
                'JustUser'
            );
        }

        Test.stopTest();
    }

    @isTest
    private static void shareContractAgreements() {
        Test.startTest();

        Account customerAcc = [
            SELECT Id
            FROM Account
            WHERE Name = 'Test Account'
            LIMIT 1
        ];

        List<APXT_Redlining__Contract_Agreement__c> newContracts = [
            SELECT
                Id,
                APXT_Redlining__Status__c,
                Contract_Eligibility__c,
                Specific_Member__c
            FROM APXT_Redlining__Contract_Agreement__c
            WHERE APXT_Redlining__Account__c = :customerAcc.Id
        ];

        System.assertEquals(
            false,
            newContracts.isEmpty(),
            'contract agreements were not created in test setup'
        );
        System.assertEquals(
            3,
            newContracts.size(),
            'number of retrieved contract agreements are not correct'
        );

        User userAll = [
            SELECT Id
            FROM User
            WHERE LastNAme = 'JustUser'
            LIMIT 1
        ];

        Test.stopTest();

        System.runAs(userAll) {
            List<APXT_Redlining__Contract_Agreement__c> contracts = [
                SELECT Id
                FROM APXT_Redlining__Contract_Agreement__c
                WHERE APXT_Redlining__Account__c = :customerAcc.Id
            ];
            System.assertEquals(
                1,
                contracts.size(),
                'sharing for "GPO All" is not correct'
            );
        }
    }

    @isTest
    private static void shareContractImplementations() {
        Test.startTest();

        Account acc = [SELECT Id FROM Account WHERE Name = 'All' LIMIT 1];
        Account customerAcc = [
            SELECT Id
            FROM Account
            WHERE Name = 'Test Account'
            LIMIT 1
        ];

        APXT_Redlining__Contract_Agreement__c conAgree = [
            SELECT
                Id,
                APXT_Redlining__Status__c,
                Contract_Eligibility__c,
                Specific_Member__c
            FROM APXT_Redlining__Contract_Agreement__c
            WHERE APXT_Redlining__Account__c = :customerAcc.Id
            LIMIT 1
        ];

        TestDataFactory.createContractImplementation(acc.Id, conAgree.Id);

        User newUser = TestDataFactory.createCommunityUser(acc.Id, 'NewUser');

        Test.stopTest();

        System.runAs(newUser) {
            Integer contracts = [
                SELECT COUNT()
                FROM Contract_Implementations__c
                WHERE Contract_Agreement__c = :conAgree.Id
            ];
            System.assertEquals(
                1,
                contracts,
                'contract was not shared to correct user'
            );
        }
    }
}