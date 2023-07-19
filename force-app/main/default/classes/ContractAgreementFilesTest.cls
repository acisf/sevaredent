@isTest
public with sharing class ContractAgreementFilesTest {
    @TestSetup
    static void makeData() {
        Test.startTest();

        User owner = TestDataFactory.createOwner();
        System.runAs(owner) {
            Account accountAffordable = TestDataFactory.createAccount(
                'Test Affordable',
                null
            );
            Account accountCommercial = TestDataFactory.createAccount(
                'Test Commercial',
                null
            );
            Account accountEducation = TestDataFactory.createAccount(
                'Test Education',
                'Education'
            );
            TestDataFactory.createFiles();
        }

        Test.stopTest();
    }

    @isTest
    private static void linkFilesOnCreate() {
        Test.startTest();

        Account affordable = [
            SELECT Id
            FROM Account
            WHERE Name = 'Test Affordable'
            LIMIT 1
        ];

        Account commercial = [
            SELECT Id
            FROM Account
            WHERE Name = 'Test Commercial'
            LIMIT 1
        ];
        Account education = [
            SELECT Id
            FROM Account
            WHERE Name = 'Test Education'
            LIMIT 1
        ];

        Integer countAffordable = [
            SELECT COUNT()
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :affordable.Id
        ];
        Integer countCommercial = [
            SELECT COUNT()
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :commercial.Id
        ];
        Integer countEducation = [
            SELECT COUNT()
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :education.Id
        ];

        System.assertEquals(
            2,
            countAffordable,
            'linking of files for affordable care is not correct'
        );
        System.assertEquals(
            2,
            countCommercial,
            'linking of files for commercial is not correct'
        );
        System.assertEquals(
            2,
            countEducation,
            'linking of files for educational is not correct'
        );

        Test.stopTest();
    }

    @isTest
    private static void linkFilesOnUpdate() {
        Test.startTest();

        Account affordable = [
            SELECT Id
            FROM Account
            WHERE Name = 'Test Affordable'
            LIMIT 1
        ];
        Account commercial = [
            SELECT Id
            FROM Account
            WHERE Name = 'Test Commercial'
            LIMIT 1
        ];
        Account education = [
            SELECT Id
            FROM Account
            WHERE Name = 'Test Education'
            LIMIT 1
        ];

        Set<Id> accIds = new Set<Id>{
            affordable.Id,
            commercial.Id,
            education.Id
        };
        List<ContentDocumentLink> affordableLinks = [
            SELECT ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId IN :accIds
        ];
        Set<Id> linkIds = new Set<Id>();
        for (ContentDocumentLink cdl : affordableLinks) {
            linkIds.add(cdl.ContentDocumentId);
        }

        List<ContentVersion> versions = [
            SELECT Visibility__c
            FROM ContentVersion
            WHERE ContentDocumentId IN :linkIds
        ];

        List<ContentVersion> listToUpdate = new List<ContentVersion>();

        for (ContentVersion cv : versions) {
            cv.Visibility__c = 'ALL';
            listToUpdate.add(cv);
        }

        update listToUpdate;

        Integer countAffordable = [
            SELECT COUNT()
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :affordable.Id
        ];
        Integer countCommercial = [
            SELECT COUNT()
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :commercial.Id
        ];
        Integer countEducation = [
            SELECT COUNT()
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :education.Id
        ];

        System.assertEquals(
            4,
            countAffordable,
            'linking of files for affordable care is not correct'
        );
        System.assertEquals(
            4,
            countCommercial,
            'linking of files for commercial is not correct'
        );
        System.assertEquals(
            4,
            countEducation,
            'linking of files for educational is not correct'
        );

        Test.stopTest();
    }

    @isTest
    private static void linkFilesOnAccountCreate() {
        Test.startTest();

        TestDataFactory.createFiles();

        Account newAccount = TestDataFactory.createAccount(
            'New Test All',
            null
        );

        Integer count = [
            SELECT COUNT()
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :newAccount.Id
        ];

        System.assertEquals(
            2,
            count,
            'file was not linked after account creation'
        );

        Test.stopTest();
    }

    @isTest
    private static void linkFilesOnAccountUpdate() {
        Test.startTest();

        TestDataFactory.createFiles();

        Account newAccount = TestDataFactory.createAccount(
            'New Test All',
            null
        );

        Integer countBefore = [
            SELECT COUNT()
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :newAccount.Id
        ];

        System.assertEquals(
            2,
            countBefore,
            'file was not linked after account creation'
        );

        newAccount.Status__c = 'Inactive';
        update newAccount;

        Integer countAfter = [
            SELECT COUNT()
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :newAccount.Id
        ];

        System.assertEquals(
            true,
            countBefore != countAfter,
            'file was not unlinked after account update'
        );

        Test.stopTest();
    }

    @isTest
    private static void reparentFilesOnAmendment() {
        Test.startTest();
        Account acc;
        APXT_Redlining__Contract_Agreement__c conAgree;
        APXT_Redlining__Contract_Agreement__c conAgreeToAmend;

        User owner = [SELECT Id FROM USER WHERE Alias = 'accOwner' LIMIT 1];

        System.runAs(owner) {
            acc = TestDataFactory.createAccount(
                'New Test Acc',
                null
            );

            conAgreeToAmend = TestDataFactory.createContractAgreement(
                acc
            );

            conAgree = TestDataFactory.createContractAgreementWithParent(
                acc,
                conAgreeToAmend.Id
            );
        }

        List<ContentDocumentLink> docs = [
            SELECT ContentDocumentId, LinkedEntityId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :acc.Id
        ];

        ContentDocumentLink link = new ContentDocumentLink(
            ContentDocumentId = docs[0].ContentDocumentId,
            LinkedEntityId = conAgreeToAmend.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert link;

        Integer files = [
            SELECT COUNT()
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :conAgreeToAmend.Id
        ];
        System.assertEquals(
            1,
            files,
            'file was not linked to contract agreement'
        );

        conAgree.APXT_Redlining__Status__c = 'Activated';
        update conAgree;

        Test.stopTest();

        files = [
            SELECT COUNT()
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :conAgreeToAmend.Id
        ];
        System.assertEquals(0, files, 'file was not deleted from old contract on amendment');

        files = [
            SELECT COUNT()
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :conAgree.Id
        ];
        System.assertEquals(1, files, 'file was not reparented on amendment');
    }
}