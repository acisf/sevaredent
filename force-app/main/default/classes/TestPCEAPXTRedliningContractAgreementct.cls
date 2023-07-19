@isTest 
 private class TestPCEAPXTRedliningContractAgreementct { private static testMethod void Test_TestPCEAPXTRedliningContractAgreementct () { 
 FSTR.COTestFactory.FillAllFields=true; 
 APXT_Redlining__Contract_Agreement__c fw = (APXT_Redlining__Contract_Agreement__c)FSTR.COTestFactory.createSObject('APXT_Redlining__Contract_Agreement__c', false); 
 insert fw; 
 System.assertNotEquals(null, fw.id); 
 update fw; 
 delete fw;} 
}