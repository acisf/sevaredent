@isTest
public with sharing class ContractImplementationsTest {
    @isTest
    private static void updateAmendedContracts() {
        Test.startTest();

        APXT_Redlining__Contract_Agreement__c conAgree;
        APXT_Redlining__Contract_Agreement__c conAgreeToAmend;

        User owner = TestDataFactory.createOwner();

        System.runAs(owner) {
            Account acc = TestDataFactory.createAccount('User', null);
            Account customerAcc = TestDataFactory.createAccount();

            conAgreeToAmend = TestDataFactory.createContractAgreement(
                customerAcc
            );
            TestDataFactory.createContractImplementation(
                acc.Id,
                conAgreeToAmend.Id
            );
            conAgree = TestDataFactory.createContractAgreementWithParent(
                customerAcc,
                conAgreeToAmend.Id
            );

        Integer contracts = [
            SELECT COUNT()
            FROM Contract_Implementations__c
            WHERE Contract_Agreement__c = :conAgreeToAmend.Id
        ];
        System.assertEquals(
            1,
            contracts,
            'contract agreement was not assigned to contract implementation'
        );

        conAgreeToAmend.APXT_Redlining__Status__c = 'Amended';
        conAgreeToAmend.APXT_Redlining__Contract_Agreement_Family_Root__c = conAgree.Id;
        update conAgreeToAmend;
        
        contracts = [
            SELECT COUNT()
            FROM Contract_Implementations__c
            WHERE Contract_Agreement__c = :conAgree.Id
        ];
        System.assertEquals(
            1,
            contracts,
            'contract agreement field was not updated'
        );
        }
        Test.stopTest();
    }
}