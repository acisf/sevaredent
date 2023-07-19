trigger PCEAPXTRedliningContractAgreementct on APXT_Redlining__Contract_Agreement__c (after update, after insert){
 string operation = Trigger.isUpdate ? 'Update' : 'Insert';FSTR.ProcessComposerInitiatorUtils.EvaluateInitiators(Trigger.oldMap, Trigger.newMap, operation); 
}