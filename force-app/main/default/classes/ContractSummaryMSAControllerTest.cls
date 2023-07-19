/**
 * Created by cshah on Oct 27, 2020.
 */

@isTest
public class ContractSummaryMSAControllerTest {
    @TestSetup
    public static void testSetupContract() {
        Account account = new Account(Name='Test Account');
        insert account;


        Id msaRecordTypeId = [SELECT Id FROM RecordType WHERE RecordType.Name = 'Master Service Agreement' LIMIT 1].get(0).Id;
        Contract contract = new Contract();
        contract.Name = 'Test Contract';
        contract.Status = 'Draft';
        contract.Sevaredent_Contract_Number__c = 'SMP1001';
        contract.AccountId = account.Id;
        contract.StartDate = Date.today();
        contract.ContractTerm = 1;
        contract.Termination_Notice__c = 30;
        contract.Price_Escalator_Description__c = 'Test Price Description';

        insert contract;
    }
    @IsTest
    public static void testContractSummaryMSAController() {
        Contract contract = [SELECT Id FROM Contract].get(0);
        Test.startTest();

        Test.setCurrentPageReference(new PageReference('Page.ContractSummaryMSA'));
        System.currentPageReference().getParameters().put('Id', contract.Id);
        ApexPages.StandardController stdController = new ApexPages.StandardController(contract);
        ContractSummaryMSAController summaryMSAController = new ContractSummaryMSAController(stdController);
        Test.stopTest();
    }
}