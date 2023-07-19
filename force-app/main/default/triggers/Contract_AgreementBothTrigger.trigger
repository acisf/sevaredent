trigger Contract_AgreementBothTrigger on APXT_Redlining__Contract_Agreement__c (after insert, before insert, before update, after update, before delete, after delete) { 
    FSTR.COTriggerHandler.handleBothTrigger();
}