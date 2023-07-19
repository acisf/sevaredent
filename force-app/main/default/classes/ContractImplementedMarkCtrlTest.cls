@isTest
public with sharing class ContractImplementedMarkCtrlTest {
    @isTest
    private static void getUserImplementationDate() {
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

        System.runAs(comUser) {
            List<Contract_Implementations__c> impls = ContractImplementedMarkCtrl.getImplementations(
                conAgree.Id
            );
            System.assertEquals(
                false,
                impls.isEmpty(),
                'objects were not retrieved'
            );
        }
    }

    @isTest
    private static void getImplementationsException() {
        Test.startTest();

        Boolean exceptionThrown = false;

        try {
            List<Contract_Implementations__c> impls = ContractImplementedMarkCtrl.getImplementations('incorrect Id');
        } catch (Exception e) {
            exceptionThrown = true;
        }

        System.assertEquals(true, exceptionThrown, 'exception was not thrown');

        Test.stopTest();
    }
}