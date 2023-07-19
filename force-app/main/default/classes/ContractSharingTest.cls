@isTest
public with sharing class ContractSharingTest {
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

            User userAll = TestDataFactory.createCommunityUser(
                accountAll.Id,
                'JustUser'
            );
            User userSpecific = TestDataFactory.createCommunityUser(
                accountSpecific.Id,
                'SpecificUser'
            );
            User userEdication = TestDataFactory.createCommunityUser(
                accountEdication.Id,
                'EducationUser'
            );

            TestDataFactory.createContractAgreements(
                customerAcc,
                accountSpecific.Id
            );
        }

        Test.stopTest();
    }

    @isTest
    static void shareOnCreate() {
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

        User userSpecific = [
            SELECT Id
            FROM User
            WHERE LastNAme = 'SpecificUser'
            LIMIT 1
        ];
        System.runAs(userSpecific) {
            List<APXT_Redlining__Contract_Agreement__c> contracts = [
                SELECT Id
                FROM APXT_Redlining__Contract_Agreement__c
                WHERE APXT_Redlining__Account__c = :customerAcc.Id
            ];

            System.assertEquals(
                2,
                contracts.size(),
                'sharing for "Custom/Member Specific" is not correct'
            );
        }

        User userEdication = [
            SELECT Id
            FROM User
            WHERE LastNAme = 'EducationUser'
            LIMIT 1
        ];
        System.runAs(userEdication) {
            List<APXT_Redlining__Contract_Agreement__c> contracts = [
                SELECT Id
                FROM APXT_Redlining__Contract_Agreement__c
                WHERE APXT_Redlining__Account__c = :customerAcc.Id
            ];

            System.assertEquals(
                2,
                contracts.size(),
                'sharing for "Education (discipline)" is not correct'
            );
        }

        Test.stopTest();
    }

    @isTest
    static void shareOnUpdate() {
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

        User userSpecific = [
            SELECT Id
            FROM User
            WHERE LastNAme = 'SpecificUser'
            LIMIT 1
        ];
        System.runAs(userSpecific) {
            List<APXT_Redlining__Contract_Agreement__c> contracts = [
                SELECT Id
                FROM APXT_Redlining__Contract_Agreement__c
                WHERE APXT_Redlining__Account__c = :customerAcc.Id
            ];

            System.assertEquals(
                2,
                contracts.size(),
                'sharing for "Custom/Member Specific" is not correct'
            );
        }

        User userEdication = [
            SELECT Id
            FROM User
            WHERE LastNAme = 'EducationUser'
            LIMIT 1
        ];
        System.runAs(userEdication) {
            List<APXT_Redlining__Contract_Agreement__c> contracts = [
                SELECT Id
                FROM APXT_Redlining__Contract_Agreement__c
                WHERE APXT_Redlining__Account__c = :customerAcc.Id
            ];

            System.assertEquals(
                2,
                contracts.size(),
                'sharing for "Education (discipline)" is not correct'
            );
        }

        for (APXT_Redlining__Contract_Agreement__c c : newContracts) {
            c.APXT_Redlining__Status__c = 'Draft';
        }

        update newContracts;

        System.runAs(userAll) {
            List<APXT_Redlining__Contract_Agreement__c> contracts = [
                SELECT Id
                FROM APXT_Redlining__Contract_Agreement__c
                WHERE APXT_Redlining__Account__c = :customerAcc.Id
            ];

            System.assertEquals(
                0,
                contracts.size(),
                'sharing for "GPO All" user was not updated'
            );
        }

        System.runAs(userSpecific) {
            List<APXT_Redlining__Contract_Agreement__c> contracts = [
                SELECT Id
                FROM APXT_Redlining__Contract_Agreement__c
                WHERE APXT_Redlining__Account__c = :customerAcc.Id
            ];

            System.assertEquals(
                0,
                contracts.size(),
                'sharing for "Custom/Member Specific" user was not updated'
            );
        }

        System.runAs(userEdication) {
            List<APXT_Redlining__Contract_Agreement__c> contracts = [
                SELECT Id
                FROM APXT_Redlining__Contract_Agreement__c
                WHERE APXT_Redlining__Account__c = :customerAcc.Id
            ];

            System.assertEquals(
                0,
                contracts.size(),
                'sharing for "Education (discipline)" user was not updated'
            );
        }

        Test.stopTest();
    }
}