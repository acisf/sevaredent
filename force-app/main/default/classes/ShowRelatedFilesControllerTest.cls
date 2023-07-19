@isTest
public with sharing class ShowRelatedFilesControllerTest {
    @isTest
    private static void getRelatedFilesSucces() {
        Test.startTest();

        Account accountEducation;
        APXT_Redlining__Contract_Agreement__c contract;
        User commUser;

        User owner = TestDataFactory.createOwner();
        System.runAs(owner) {
            accountEducation = TestDataFactory.createAccount(
                'Test Education',
                'Education'
            );
            commUser = TestDataFactory.createCommunityUser(
                accountEducation.Id,
                'TestUser'
            );
            Account acc = TestDataFactory.CreateAccount();
            contract = TestDataFactory.createContractAgreement(acc);

            TestDataFactory.createFiles();

            ContentVersion education = [
                SELECT ContentDocumentId
                FROM ContentVersion
                WHERE Title = 'Test' AND Visibility__c = 'Education'
                LIMIT 1
            ];

            ContentDocumentLink link = new ContentDocumentLink(
                ContentDocumentId = education.ContentDocumentId,
                LinkedEntityId = contract.Id,
                ShareType = 'V',
                Visibility = 'AllUsers'
            );
            insert link;
        }

        Test.stopTest();
        System.runAs(commUser) {
            List<ContentVersion> files = ShowRelatedFilesController.getRelatedFiles(
                contract.Id
            );

            System.assertEquals(
                false,
                files.isEmpty(),
                'files were no retrieved'
            );
        }
    }

    @isTest
    public static void getRelatedFilesException() {
        Test.startTest();

        Boolean exceptionThrown = false;

        try {
            List<ContentVersion> files = ShowRelatedFilesController.getRelatedFiles(
                'incorrectId'
            );
        } catch (Exception e) {
            exceptionThrown = true;
        }

        System.assertEquals(true, exceptionThrown, 'exception was not thrown');

        Test.stopTest();
    }
}