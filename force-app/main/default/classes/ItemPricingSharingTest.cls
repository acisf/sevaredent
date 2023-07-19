@isTest
public with sharing class ItemPricingSharingTest {
    @TestSetup
    private static void makeData() {
        Test.startTest();

        User owner = TestDataFactory.createOwner();
        System.runAs(owner) {
            Account customerAcc = TestDataFactory.createAccount();

            Account accountEducation = TestDataFactory.createAccount(
                'Test Acc',
                'Education'
            );

            User userEdication = TestDataFactory.createCommunityUser(
                accountEducation.Id,
                'EducationUser'
            );

            APXT_Redlining__Contract_Agreement__c conAgree = TestDataFactory.createContractAgreement(
                customerAcc
            );

            TestDataFactory.createContractImplementation(
                accountEducation.Id,
                conAgree.Id
            );
        }

        Test.stopTest();
    }

    @isTest
    private static void shareOnCreate() {
        Test.startTest();

        Account customerAcc = [
            SELECT Id
            FROM Account
            WHERE Name = 'Test Account'
            LIMIT 1
        ];

        APXT_Redlining__Contract_Agreement__c conAgree = [
            SELECT Id
            FROM APXT_Redlining__Contract_Agreement__c
            WHERE APXT_Redlining__Account__c = :customerAcc.Id
        ];

        TestDataFactory.createItemPricing(conAgree);
        List<Item_Pricing__c> pricings;

        User edUser = [
            SELECT Id
            FROM User
            WHERE Name = 'EducationUser'
            LIMIT 1
        ];

        Test.stopTest();

        System.runAs(edUser) {
            pricings = [
                SELECT Id
                FROM Item_Pricing__c
                WHERE Contract_Agreement__c = :conAgree.Id
            ];
        }
        System.assertEquals(
            false,
            pricings.isEmpty(),
            'item pricing was not shared'
        );
    }

    @isTest
    private static void shareOnUpdate() {
        Test.startTest();
        Account customerAcc = [
            SELECT Id
            FROM Account
            WHERE Name = 'Test Account'
            LIMIT 1
        ];

        APXT_Redlining__Contract_Agreement__c conAgree = [
            SELECT Id
            FROM APXT_Redlining__Contract_Agreement__c
            WHERE APXT_Redlining__Account__c = :customerAcc.Id
        ];

        TestDataFactory.createItemPricing(conAgree);
        Item_Pricing__c pricing = [
            SELECT Id, Sevaredent_Contract_Number__c, Contract_Agreement__c
            FROM Item_Pricing__c
            WHERE Contract_Agreement__c = :conAgree.Id
            LIMIT 1
        ];
        APXT_Redlining__Contract_Agreement__c newConAgree = TestDataFactory.createContractAgreementWithParent(
            customerAcc,
            null
        );

        pricing.Contract_Agreement__c = newConAgree.Id;
        pricing.Sevaredent_Contract_Number__c = newConAgree.Sevaredent_Contract_Number__c;

        Test.stopTest();

        update pricing;

        User edUser = [
            SELECT Id
            FROM User
            WHERE Name = 'EducationUser'
            LIMIT 1
        ];

        List<Item_Pricing__c> pricings;
        System.runAs(edUser) {
            pricings = [SELECT Id FROM Item_Pricing__c WHERE Id = :pricing.Id];
        }
        System.assertEquals(
            true,
            pricings.isEmpty(),
            'item pricing sharing was not updated'
        );
    }

    @isTest
    private static void shareOnMemberCreate() {
        Test.startTest();

        Account customerAcc = [
            SELECT Id
            FROM Account
            WHERE Name = 'Test Account'
            LIMIT 1
        ];

        APXT_Redlining__Contract_Agreement__c conAgree = [
            SELECT Id
            FROM APXT_Redlining__Contract_Agreement__c
            WHERE APXT_Redlining__Account__c = :customerAcc.Id
        ];

        TestDataFactory.createItemPricing(conAgree);
        List<Item_Pricing__c> pricings;

        Account userAcc = [
            SELECT Id
            FROM Account
            WHERE Name = 'Test Acc' AND Type = 'Education'
            LIMIT 1
        ];
        User newUser = TestDataFactory.createCommunityUser(
            userAcc.Id,
            'NewEducationUser'
        );

        Test.stopTest();

        System.runAs(newUser) {
            pricings = [
                SELECT Id
                FROM Item_Pricing__c
                WHERE Contract_Agreement__c = :conAgree.Id
            ];
        }
        System.assertEquals(
            false,
            pricings.isEmpty(),
            'item pricing was not shared'
        );
    }

    @isTest
    private static void shareOnMemberCreateBatch() {
        Test.startTest();

        Account customerAcc = [
            SELECT Id
            FROM Account
            WHERE Name = 'Test Account'
            LIMIT 1
        ];

        APXT_Redlining__Contract_Agreement__c conAgree = [
            SELECT Id
            FROM APXT_Redlining__Contract_Agreement__c
            WHERE APXT_Redlining__Account__c = :customerAcc.Id
        ];

        List<Item_Pricing__c> pricings = TestDataFactory.bulkItemPricingRecords3(
            conAgree
        );

        Account userAcc = [
            SELECT Id
            FROM Account
            WHERE Name = 'Test Acc' AND Type = 'Education'
            LIMIT 1
        ];
        User newUser = TestDataFactory.createCommunityUser(
            userAcc.Id,
            'NewEducationUser'
        );

        Test.stopTest();

        System.runAs(newUser) {
            Integer count = [
                SELECT COUNT()
                FROM Item_Pricing__c
                WHERE Contract_Agreement__c = :conAgree.Id
            ];
            System.assertEquals(
                200,
                count,
                'item pricing was not shared in batch'
            );
        }
    }

    @isTest
    private static void shareOnContractImplementationCreate() {
        Test.startTest();

        Account customerAcc = [
            SELECT Id
            FROM Account
            WHERE Name = 'Test Account'
            LIMIT 1
        ];

        APXT_Redlining__Contract_Agreement__c conAgree = [
            SELECT Id
            FROM APXT_Redlining__Contract_Agreement__c
            WHERE APXT_Redlining__Account__c = :customerAcc.Id
        ];

        TestDataFactory.createItemPricing(conAgree);

        Account userAcc = [
            SELECT Id
            FROM Account
            WHERE Name = 'Test Acc' AND Type = 'Education'
            LIMIT 1
        ];

        Contract_Implementations__c impl = [
            SELECT Status__c
            FROM Contract_Implementations__c
            WHERE
                Account__c = :userAcc.Id
                AND Contract_Agreement__c = :conAgree.Id
        ];

        User edUser = [
            SELECT Id
            FROM User
            WHERE Name = 'EducationUser'
            LIMIT 1
        ];

        Test.stopTest();

        System.runAs(edUser) {
            List<Item_Pricing__c> pricings = [
                SELECT Id
                FROM Item_Pricing__c
                WHERE Contract_Agreement__c = :conAgree.Id
            ];

            System.assertEquals(
                false,
                pricings.isEmpty(),
                'item pricing was not shared on implementation create'
            );
        }
    }

    @isTest
    private static void shareOnContractImplementationUpdate() {
        Test.startTest();

        Account customerAcc = [
            SELECT Id
            FROM Account
            WHERE Name = 'Test Account'
            LIMIT 1
        ];

        APXT_Redlining__Contract_Agreement__c conAgree = [
            SELECT Id
            FROM APXT_Redlining__Contract_Agreement__c
            WHERE APXT_Redlining__Account__c = :customerAcc.Id
        ];

        TestDataFactory.createItemPricing(conAgree);

        Account userAcc = [
            SELECT Id
            FROM Account
            WHERE Name = 'Test Acc' AND Type = 'Education'
            LIMIT 1
        ];

        Contract_Implementations__c impl = [
            SELECT Status__c
            FROM Contract_Implementations__c
            WHERE
                Account__c = :userAcc.Id
                AND Contract_Agreement__c = :conAgree.Id
        ];

        impl.Status__c = 'On Hold';
        update impl;

        User edUser = [
            SELECT Id
            FROM User
            WHERE Name = 'EducationUser'
            LIMIT 1
        ];

        Test.stopTest();

        System.runAs(edUser) {
            List<Item_Pricing__c> pricings = [
                SELECT Id
                FROM Item_Pricing__c
                WHERE Contract_Agreement__c = :conAgree.Id
            ];

            System.assertEquals(
                true,
                pricings.isEmpty(),
                'item pricing sharing was not changed'
            );
        }
    }

    @isTest
    private static void shareOnContractAgreementUpdate() {
        Test.startTest();

        Account customerAcc = [
            SELECT Id
            FROM Account
            WHERE Name = 'Test Account'
            LIMIT 1
        ];

        APXT_Redlining__Contract_Agreement__c conAgree = [
            SELECT Id
            FROM APXT_Redlining__Contract_Agreement__c
            WHERE APXT_Redlining__Account__c = :customerAcc.Id
        ];

        TestDataFactory.createItemPricing(conAgree);

        Account userAcc = [
            SELECT Id
            FROM Account
            WHERE Name = 'Test Acc' AND Type = 'Education'
            LIMIT 1
        ];

        Contract_Implementations__c impl = [
            SELECT Status__c
            FROM Contract_Implementations__c
            WHERE
                Account__c = :userAcc.Id
                AND Contract_Agreement__c = :conAgree.Id
        ];

        conAgree.APXT_Redlining__Status__c = 'Signed';
        update conAgree;

        User edUser = [
            SELECT Id
            FROM User
            WHERE Name = 'EducationUser'
            LIMIT 1
        ];

        Test.stopTest();

        System.runAs(edUser) {
            List<Item_Pricing__c> pricings = [
                SELECT Id
                FROM Item_Pricing__c
                WHERE Contract_Agreement__c = :conAgree.Id
            ];

            System.assertEquals(
                true,
                pricings.isEmpty(),
                'item pricing sharing was not changed'
            );
        }
    }
}