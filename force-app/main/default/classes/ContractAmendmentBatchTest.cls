/**
 * Created by cshah on Oct 29, 2020.
 */

@IsTest
public class ContractAmendmentBatchTest {
    @TestSetup
    public static void testSetupData() {
        Account account = new Account(Name='Test Account');
        insert account;

        List<Contract> contracts = new List<Contract>();
        for(Integer i = 0; i<=30; i++) {
            Contract contract = new Contract();
            contract.Name = 'Test Contract ' + i;
            contract.Status = 'Draft';
            contract.Sevaredent_Contract_Number__c = 'SMP1001' + i;
            contract.AccountId = account.Id;
            contract.StartDate = Date.today();
            contract.ContractTerm = 1;
            contract.Termination_Notice__c = 30;
            contract.Price_Escalator_Description__c = 'Test Price Description';

            contracts.add(contract);
        }
        insert contracts;

        List<Amendment__c> amendments = new List<Amendment__c>();
        for(Integer i = 0; i<=30; i++) {
            Amendment__c amendment = new Amendment__c();
            amendment.Contract__c = contracts[i].Id;
            amendment.Amendment_Description__c = 'Test Description ' + i;
            amendment.Amendment_Effective_Date__c = Date.today();
            amendment.Amendment_Type__c = 'Price Increase';
            amendment.Amendment_Contract_Fields__c = '{"Minimum_Order_Description__c":"minimum description"}';
            if(Math.mod(i,2) == 0) {
                amendment.Amendment_Status__c = 'Draft';
            } else {
                amendment.Amendment_Status__c = 'Approved';
            }
            amendments.add(amendment);
        }
        insert amendments;
    }
    @IsTest
    public static void testAmendmentContract() {
        Test.startTest();
        Database.executeBatch(new ContractAmendmentBatch());
        Test.stopTest();
    }
    @IsTest
    public static void testAmendmentScheduler() {
        Test.startTest();
        String sch = '0 5 0 1/1 * ? *';
        System.schedule('Test Apply Amendments to Contracts', sch, new ContractAmendmentScheduler());
        Test.stopTest();
    }
}