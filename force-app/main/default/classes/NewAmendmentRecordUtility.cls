/**
 * Created by cshah on Nov 02, 2020.
 */

public without sharing class NewAmendmentRecordUtility {

    @AuraEnabled
    public static Map<String, Object> init(String recordId, String contractId) {
        Map<String, Object> response = new Map<String, Object>();

        Map<String, Object> amendmentData = new Map<String, Object>();
        amendmentData.put('amendmentStatus', '');
        amendmentData.put('contractId', contractId);
        amendmentData.put('amendmentContractFields', new Map<String, Object>());

        if (recordId != null) {
            for (Amendment__c amendment : [SELECT Contract__c, Executed__c, isCancelled__c, Amendment_Type__c, Amendment_Status__c, Amendment_Description__c, Amendment_Effective_Date__c, Amendment_Contract_Fields__c, Warning__c FROM Amendment__c WHERE Id = :recordId]) {
                /*AND Amendment_Status__c !=*/
                contractId = amendment.Contract__c;

                amendmentData.put('id', amendment.Id);
                amendmentData.put('executed', amendment.Executed__c);
                amendmentData.put('contractId', amendment.Contract__c);
                amendmentData.put('isCancelled', amendment.isCancelled__c);
                amendmentData.put('amendmentType', amendment.Amendment_Type__c);
                amendmentData.put('amendmentStatus', amendment.Amendment_Status__c);
                amendmentData.put('amendmentDescription', amendment.Amendment_Description__c);
                amendmentData.put('amendmentEffectiveDate', amendment.Amendment_Effective_Date__c);
                amendmentData.put('amendmentContractFields', ((amendment.Amendment_Contract_Fields__c == null) ? new Map<String, Object>() : (Map<String, Object>) JSON.deserializeUntyped(amendment.Amendment_Contract_Fields__c)));
            }
        }

        response.put('amendment', amendmentData);
        response.put('contractFieldAPIAndLabelDetails', getContractFieldAPIAndLabelDetails(contractId));
        return response;
    }

    private static List<Map<String, Object>> getContractFieldAPIAndLabelDetails(String contractId) {
        List<Schema.FieldSetMember> fieldSetMembers = null;
        for (Contract contract : [SELECT Id, RecordTypeId, RecordType.Name FROM Contract WHERE Id = :contractId]) {
            if (contract.RecordType.Name.equalsIgnoreCase('Master Service Agreement')) {
                fieldSetMembers = SObjectType.Contract.fieldSets.MSA_Amendment.getFields();
            } else if (contract.RecordType.Name.equalsIgnoreCase('Master Participation Agreement')) {
                fieldSetMembers = SObjectType.Contract.fieldSets.MPA_Amendment.getFields();
            } else if (contract.RecordType.Name.equalsIgnoreCase('Non-Disclosure Agreement')) {
                fieldSetMembers = SObjectType.Contract.fieldSets.NDA_Amendment.getFields();
            } else if (contract.RecordType.Name.equalsIgnoreCase('Proceed Contracts')) {
                fieldSetMembers = SObjectType.Contract.fieldSets.Proceed_Amendment.getFields();
            }
        }

        List<Map<String, Object>> fieldsLists = new List<Map<String, Object>>();
        if (fieldSetMembers != null) {
            for (FieldSetMember member : fieldSetMembers) {
                String dataType = String.valueOf(member.getSObjectField().getDescribe().getType());
                String label = member.getSObjectField().getDescribe().getLabel();
                String fieldName = member.getSObjectField().getDescribe().getName();

                Map<String, Object> fieldMap = new Map<String, Object>{
                        'apiName' => fieldName,
                        'label' => label,
                        'dataType' => dataType,
                        dataType => true
                };

                if (dataType.equalsIgnoreCase('PICKLIST') || dataType.equalsIgnoreCase('MULTIPICKLIST')) {
                    fieldMap.put('picklistValues', picklistEntries(member));
                }

                fieldsLists.add(fieldMap);
            }
        }

        return fieldsLists;
    }

    private static List<Map<String, String>> picklistEntries(FieldSetMember member) {
         return picklistValues(member.getSObjectField().getDescribe().getPicklistValues());
    }

    private static List<Map<String, String>> picklistValues(List<PicklistEntry> picklistValues) {
        List<Map<String, String>> picklistValuesList = new List<Map<String, String>>();
        for (PicklistEntry entry : picklistValues) {
            Map<String, String> pickListMap = new Map<String, String>();
            pickListMap.put('label', entry.getLabel());
            pickListMap.put('value', entry.getValue());
            picklistValuesList.add(pickListMap);
        }
        return picklistValuesList;
    }

    @AuraEnabled
    public static Boolean cancelAmendment(Id recordId) {
        if(String.isNotEmpty(recordId)) {
            List<Amendment__c> amendmentListToBeCancelled = new List<Amendment__c>();
            for(Amendment__c amendment: [SELECT Id, isCancelled__c FROM Amendment__c WHERE isCancelled__c = FALSE AND Executed__c = FALSE AND Id = :recordId]) {
                amendment.isCancelled__c = true;
                amendment.Amendment_Status__c = 'Cancelled';
                amendmentListToBeCancelled.add(amendment);
            }
            if (!amendmentListToBeCancelled.isEmpty()) {
                update amendmentListToBeCancelled;
                return true;
            }
        }
        return false;
    }

    @AuraEnabled
    public static String checkIfAmendmentWillApply(Id recordId, Map<String, Object> amendmentMap) {
        Savepoint sp = Database.setSavepoint();
        System.debug('NewAmendmentRecordUtility.checkIfAmendmentWillApply recordId: ' + recordId);
        System.debug('NewAmendmentRecordUtility.checkIfAmendmentWillApply amendmentMap: ' + JSON.serialize(amendmentMap));

        Amendment__c amendment = getAmendmentRecord(recordId);
        amendment = populateAmendmentRecord(amendment, amendmentMap);

        if(String.isEmpty(recordId)) {
            insert amendment;
        }
        System.debug('NewAmendmentRecordUtility.checkIfAmendmentWillApply amendment: ' + JSON.serialize(amendment));

        List<Amendment__c> amendments = new List<Amendment__c>{amendment};
        String exceptionMessage = '';
        try{
            ContractAmendmentBatchUtility.populateAndUpdateContractForAmendments(amendments);
        } catch(Exception e) {
            exceptionMessage = e.getMessage();
        }
        Database.rollback(sp);
        System.debug('NewAmendmentRecordUtility.checkIfAmendmentWillApply');
        System.debug('exceptionMessage' + exceptionMessage);

        exceptionMessage = exceptionMessage.substringAfter('VALIDATION_EXCEPTION,');
        if(String.isNotEmpty(recordId)) {
            Amendment__c amendmentToUpdate = new Amendment__c(Id = amendment.Id, Warning__c = exceptionMessage);
            update amendmentToUpdate;
        }

        return exceptionMessage;
    }

    public static Map<String, Schema.DescribeFieldResult> amendmentFields {
        get {
            if (amendmentFields == null) {
                amendmentFields = new Map<String, Schema.DescribeFieldResult>();
                Map<String, Schema.SObjectField> sObjectFields = Schema.getGlobalDescribe().get('Amendment__c').getDescribe().fields.getMap();
                for (String fieldName : sObjectFields.keySet()) {
                    Schema.SObjectField sObjectField = sObjectFields.get(fieldName);
                    amendmentFields.put(fieldName.toLowerCase(), sObjectField.getDescribe());
                }

            }
            return amendmentFields;
        }
        set;
    }

    private static Amendment__c getAmendmentRecord(Id recordId) {
        Amendment__c amendment;
        if(String.isNotEmpty(recordId)) {
            amendment = [SELECT Id, Name, Amendment_Number__c, Amendment_Effective_Date__c, Amendment_Description__c, Amendment_Status__c, Amendment_Type__c, Amendment_Contract_Fields__c, Contract__c, Executed__c, CreatedById FROM Amendment__c WHERE Executed__c = FALSE AND isCancelled__c = FALSE AND Id =: recordId].get(0);
        } else {
            amendment = new Amendment__c(Executed__c = false, isCancelled__c = false);
        }
        System.debug('NewAmendmentRecordUtility.getAmendmentRecord amendment: ' + JSON.serialize(amendment));
        return amendment;
    }

    private static Amendment__c populateAmendmentRecord(Amendment__c amendment, Map<String, Object> amendmentMap) {
        for(String fieldName: amendmentMap.keySet()) {
            //String keyString = String.valueOf(fieldName);
            if(amendmentMap.get(fieldName) != null && String.isNotEmpty(String.valueOf(amendmentMap.get(fieldName)).trim())) {
                Schema.DescribeFieldResult describeFieldResult = amendmentFields.get(fieldName.toLowerCase());
                switch on describeFieldResult.getType() {
                    when BOOLEAN {
                        amendment.put(fieldName, Boolean.valueOf(amendmentMap.get(fieldName)));
                    }
                    when CURRENCY {
                        amendment.put(fieldName, Decimal.valueOf(String.valueOf(amendmentMap.get(fieldName))));
                    }
                    when DATE {
                        amendment.put(fieldName, dateFromStringYYYYMMDD(String.valueOf(amendmentMap.get(fieldName))));
                    }
                    when DATETIME {
                        amendment.put(fieldName, datetimeFromStringYYYYMMDD(String.valueOf(amendmentMap.get(fieldName))));
                    }
                    when LONG {
                        amendment.put(fieldName, Long.valueOf(String.valueOf(amendmentMap.get(fieldName))));
                    }
                    when PERCENT {
                        amendment.put(fieldName, Decimal.valueOf(String.valueOf(amendmentMap.get(fieldName))));
                    }
                    when TIME {
                        amendment.put(fieldName, amendmentMap.get(fieldName));
                    }
                    when INTEGER {
                        amendment.put(fieldName, Integer.valueOf(amendmentMap.get(fieldName)));
                    }
                    when DOUBLE {
                        amendment.put(fieldName, Double.valueOf(amendmentMap.get(fieldName)));
                    }

                    when else {
                        if(fieldName.equalsIgnoreCase('Contract__c') && String.isNotEmpty(String.valueOf(amendment.get(fieldName)))) {}
                        else {
                            amendment.put(fieldName, amendmentMap.get(fieldName));
                        }
                    }
                }
            }
        }
        System.debug('NewAmendmentRecordUtility.populateAmendmentRecord amendment: ' + JSON.serialize(amendment));
        return amendment;
    }

    @TestVisible
    private static Date dateFromStringYYYYMMDD(String currentDate) {
        List<String> dateComponent = currentDate.split('-');
        Date formedDate = Date.newInstance(Integer.valueOf(dateComponent.get(0)), Integer.valueOf(dateComponent.get(1)), Integer.valueOf(dateComponent.get(2)));
        return formedDate;
    }
    @TestVisible
    private static Datetime datetimeFromStringYYYYMMDD(String currentDate) {
        List<String> dateComponent = currentDate.split('-');
        Datetime formedDatetime = Datetime.newInstance(Integer.valueOf(dateComponent.get(0)), Integer.valueOf(dateComponent.get(1)), Integer.valueOf(dateComponent.get(2)), 0, 0, 0);
        return formedDatetime;
    }
}