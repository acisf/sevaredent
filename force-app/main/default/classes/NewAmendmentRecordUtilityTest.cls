/**
 * Created by cshah on Nov 16, 2020.
 */

@IsTest
public class NewAmendmentRecordUtilityTest {

    @TestSetup
    public static void testSetupMethod() {
        Account account = new Account(Name = 'Test Account');
        insert account;

        Contract contract = new Contract(Name='Test Contract', StartDate = Date.today(), AccountId=account.Id, Sevaredent_Contract_Number__c = 'Test Sevaredent');
        insert contract;

        Amendment__c amendment = new Amendment__c(Name='Test Amendment', Contract__c = contract.Id, Amendment_Number1__c = 1, Amendment_Status__c = 'Draft', Amendment_Type__c = 'Extension', Amendment_Contract_Fields__c = '{"Minimum_Order_Description__c":"minimum description", "EndDate":"2020-10-19"}');
        insert amendment;

    }
    @IsTest
    public static void testNewAmendmentRecord() {
        Contract contract = [SELECT Id FROM Contract].get(0);
        Amendment__c amendment = [SELECT Id FROM Amendment__c].get(0);

        NewAmendmentRecordUtility.init(amendment.Id, contract.Id);
        Boolean isCancel = NewAmendmentRecordUtility.cancelAmendment(amendment.Id);
        System.assertEquals(true, isCancel);
        isCancel = NewAmendmentRecordUtility.cancelAmendment(null);
        System.assertEquals(false, isCancel);
    }
    @IsTest
    public static void testCheckIfAmendmentWillApply() {
        Amendment__c amendment = [SELECT Id FROM Amendment__c].get(0);
        Contract contract = [SELECT Id FROM Contract].get(0);

        Map<String, Object> amendmentMap = new Map<String, Object>{
                'Amendment_Number1__c' => 1,
                'Executed__c' => false,
                'Amendment_Effective_Date__c' => '2020-01-24',
                'Amendment_Status__c' => 'Draft',
                'Amendment_Type__c' => 'Extension',
                'Contract__c' => contract.Id
                };
        String warning = NewAmendmentRecordUtility.checkIfAmendmentWillApply(amendment.Id, amendmentMap);
        System.assertEquals('', warning);
        NewAmendmentRecordUtility.checkIfAmendmentWillApply(null, amendmentMap);
        NewAmendmentRecordUtility.datetimeFromStringYYYYMMDD('2020-01-01');
    }
}