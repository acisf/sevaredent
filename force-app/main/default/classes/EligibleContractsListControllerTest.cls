@isTest
public with sharing class EligibleContractsListControllerTest {
    @TestSetup
    static void makeData(){
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
    }

    @isTest
    private static void getContracts() {
        Test.startTest();

        List<APXT_Redlining__Contract_Agreement__c> contracts = EligibleContractsListController.getContracts();

        System.assertEquals(
            false,
            contracts.isEmpty(),
            'contracts were not retrieved'
        );

        Test.stopTest();
    }

    @isTest
    private static void searchContracts() {
        Test.startTest();

        List<APXT_Redlining__Contract_Agreement__c> contracts = EligibleContractsListController.searchContracts('Test', null);

        System.assertEquals(
            false,
            contracts.isEmpty(),
            'contracts were not retrieved'
        );

        Test.stopTest();
    }
        
    @isTest
    private static void searchContractsException() {
        Test.startTest();

        Boolean exceptionThrown = false;

        try {
            List<APXT_Redlining__Contract_Agreement__c> contracts = EligibleContractsListController.searchContracts(null, null);
        } catch (Exception e) {
            exceptionThrown = true;
        }

        System.assertEquals(true, exceptionThrown, 'exception was not thrown');

        Test.stopTest();
    }
}