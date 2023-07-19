/**
 * Created by cshah on Oct 29, 2020.
 */

public without sharing class ContractAmendmentBatchUtility {

    public static Map<String, Schema.DescribeFieldResult> contractFields {
        get {
            if (contractFields == null) {
                contractFields = new Map<String, Schema.DescribeFieldResult>();
                Map<String, Schema.SObjectField> sObjectFields = Schema.getGlobalDescribe().get('Contract').getDescribe().fields.getMap();
                for (String fieldName : sObjectFields.keySet()) {
                    Schema.SObjectField sObjectField = sObjectFields.get(fieldName);
                    contractFields.put(fieldName.toLowerCase(), sObjectField.getDescribe());
                }

            }
            return contractFields;
        }
        set;
    }

    public static void populateAndUpdateContractForAmendments(List<Amendment__c> amendments) {
        Set<Id> contractIds = getContractIds(amendments);
        Map<Id, Contract> amendmentContractsMap = getContractsForAmendments(contractIds);
        upsertContractsAmendmentsAndChatter(amendments, amendmentContractsMap);
    }

    /*
        Group all the contract id(s) which is parent of all the amendment which comes to be upsert
    * */
    @TestVisible
    private static Set<Id> getContractIds(List<Amendment__c> amendments) {
        Set<Id> contractIds = new Set<Id>();
        for (Amendment__c amendment : amendments) {
            contractIds.add(amendment.Contract__c);
        }
        //System.debug(' ContractAmendmentBatchUtility contractIds: ' + JSON.serialize(contractIds));
        return contractIds;
    }

    /*
        Query previous amendment history so we can concatenate current changes
    * */
    @TestVisible
    private static Map<Id, Contract> getContractsForAmendments(Set<Id> contractIds) {
        Map<Id, Contract> amendmentContractsMap = new Map<Id, Contract>([SELECT Id, Amendment_History__c, OwnerId FROM Contract WHERE Id IN :contractIds]);
        //System.debug(' ContractAmendmentBatchUtility amendmentContractsMap: ' + JSON.serialize(amendmentContractsMap));
        return amendmentContractsMap;
    }

    /*
        Apply Amendments to contract records with amendment and contract fields
        Update Amendment records that these are processed now
        Insert Chatter Feed items related to amendments
        Insert Task related to amendments
    * */

    @TestVisible
    private static void upsertContractsAmendmentsAndChatter(List<Amendment__c> amendments, Map<Id, Contract> amendmentContractsMap) {
        Map<Id, Contract> contractToBeUpdated = new Map<Id, Contract>();
        List<Amendment__c> amendmentToBeUpdated = new List<Amendment__c>();
        List<FeedItem> feedItemsToBeInserted = new List<FeedItem>();
        List<Task> taskToBeInserted = new List<Task>();

        for (Amendment__c amendment : amendments) {
            String amendmentChanges = getAmendmentChanges(amendment);
            System.debug(' ContractAmendmentBatchUtility.upsertContractsAmendmentsAndChatter amendmentChanges: ' + JSON.serialize(amendmentChanges));

            Contract contract = (contractToBeUpdated.containsKey(amendment.Contract__c) ? contractToBeUpdated.get(amendment.Contract__c) : amendmentContractsMap.get(amendment.Contract__c));
            contract = updateContractRecord(amendment, contract, amendmentChanges);
            contractToBeUpdated.put(contract.Id, contract);

            // update executed to true and status to Activated
            amendmentToBeUpdated.add(createAmendmentRecordToBeUpdate(amendment));

            // insert chatter post for amendment update
            feedItemsToBeInserted.add(createChatterPostRecord(amendment, amendmentChanges));

            // insert task for amendment update
            if(String.isNotEmpty(amendment.CreatedById)) {
                taskToBeInserted.add(createActivityHistoryRecord(amendment, amendmentContractsMap.get(amendment.Contract__c), amendmentChanges));
            }
        }

        System.debug('ContractAmendmentBatchUtility contractToBeUpdated: ' + JSON.serialize(contractToBeUpdated));
        System.debug('ContractAmendmentBatchUtility amendmentToBeUpdated: ' + JSON.serialize(amendmentToBeUpdated));
        System.debug('ContractAmendmentBatchUtility feedItemsToBeInserted: ' + JSON.serialize(feedItemsToBeInserted));
        System.debug('ContractAmendmentBatchUtility taskToBeInserted: ' + JSON.serialize(taskToBeInserted));

        if (contractToBeUpdated.size() > 0) {
            System.debug('ContractAmendmentBatchUtility updating records');
            update contractToBeUpdated.values();
            update amendmentToBeUpdated;
            insert feedItemsToBeInserted;
            insert taskToBeInserted;
        } else {
            System.debug('ContractAmendmentBatchUtility no record found to update');
        }
    }

    /*
        Form a String for Amendment History To be update on contract record
    */
    @TestVisible
    private static String getAmendmentChanges(Amendment__c amendment) {
        String amendmentChanges = '';

        Integer d = amendment.Amendment_Effective_Date__c.day();
        Integer mo = amendment.Amendment_Effective_Date__c.month();
        Integer yr = amendment.Amendment_Effective_Date__c.year();

        Datetime amendmentEffectiveDate = Datetime.newInstance(amendment.Amendment_Effective_Date__c.year(), amendment.Amendment_Effective_Date__c.month(), amendment.Amendment_Effective_Date__c.day(), 0, 0, 0);
        String formattedAmendmentEffectiveDate = amendmentEffectiveDate.format('MM/dd/yyyy');

        amendmentChanges = formattedAmendmentEffectiveDate + ':';
        amendmentChanges += '\nAmendment Type' + ': ' + amendment.Amendment_Type__c;
        amendmentChanges += '\nAmendment Description' + ': ' + amendment.Amendment_Description__c;

        Map<String, Object> contractFieldValueMap = (Map<String, Object>) JSON.deserializeUntyped(amendment.Amendment_Contract_Fields__c);
        if(!contractFieldValueMap.isEmpty()) {
            amendmentChanges += '\nField Changed' + ':';
            // get old value from contract to add in history
            List<String> contractFieldList = new List<String>(contractFieldValueMap.keySet());
            String query = 'SELECT Id, ' + String.join(contractFieldList, ',') + ' FROM Contract WHERE Id = \'' + amendment.Contract__c + '\'';
            System.debug('ContractAmendmentBatchUtility.getAmendmentChanges query: ' + query);
            List<Contract> currentContracts = Database.query(query);
            Contract currentContract = currentContracts.get(0);

            for (String contractField : contractFieldValueMap.keySet()) {
                Schema.DescribeFieldResult describeFieldResult = contractFields.get(contractField.toLowerCase());
                amendmentChanges += '\nOld Value: ' + describeFieldResult.getLabel() + ' = ' + currentContract.get(contractField) + ', New Value: ' + describeFieldResult.getLabel() + ' = ' + String.valueOf(contractFieldValueMap.get(contractField));
            }
        }


        return amendmentChanges;
    }

    /*
        Apply the amendment to single contract
        Update the contract fields with amendment fields and contract fields
    * */
    @TestVisible
    private static Contract updateContractRecord(Amendment__c amendment, Contract oldContract, String amendmentChanges) {
        Contract contract = new Contract(Id = amendment.Contract__c);
        contract.Amendment_Description__c = amendment.Amendment_Description__c;
        contract.Amendment_Effective_Date__c = amendment.Amendment_Effective_Date__c;
        contract.Amendment_Type__c = amendment.Amendment_Type__c;
        contract.Amendment_History__c = amendmentChanges + '\n\n' + (String.isNotEmpty(oldContract.Amendment_History__c) ? oldContract.Amendment_History__c : '');
        contract.Amendment__c = amendment.Id;
        //contract.Status = 'Being Amended';

        Map<String, Object> contractFieldValueMap = (Map<String, Object>) JSON.deserializeUntyped(amendment.Amendment_Contract_Fields__c);
        //System.debug(' ContractAmendmentBatchUtility.updateContractRecord contractFieldValueMap: ' + JSON.serialize(contractFieldValueMap));
        for (String fieldName : contractFieldValueMap.keySet()) {
            Schema.DescribeFieldResult describeFieldResult = contractFields.get(fieldName.toLowerCase());
            switch on describeFieldResult.getType() {
                when BOOLEAN {
                    contract.put(fieldName, Boolean.valueOf(contractFieldValueMap.get(fieldName)));
                }
                when CURRENCY {
                    contract.put(fieldName, Decimal.valueOf(String.valueOf(contractFieldValueMap.get(fieldName))));
                }
                when DATE {
                    contract.put(fieldName, dateFromStringYYYYMMDD(String.valueOf(contractFieldValueMap.get(fieldName))));
                }
                when DATETIME {
                    contract.put(fieldName, datetimeFromStringYYYYMMDD(String.valueOf(contractFieldValueMap.get(fieldName))));
                }
                when DOUBLE {
                    contract.put(fieldName, Double.valueOf(contractFieldValueMap.get(fieldName)));
                }
                when INTEGER {
                    contract.put(fieldName, Integer.valueOf(contractFieldValueMap.get(fieldName)));
                }
                when LONG {
                    contract.put(fieldName, Long.valueOf(String.valueOf(contractFieldValueMap.get(fieldName))));
                }
                when PERCENT {
                    contract.put(fieldName, Decimal.valueOf(String.valueOf(contractFieldValueMap.get(fieldName))));
                }
                when TIME {
                    contract.put(fieldName, contractFieldValueMap.get(fieldName));
                }

                when else {
                    contract.put(fieldName, contractFieldValueMap.get(fieldName));
                }
            }
        }
        return contract;
    }

    @TestVisible
    private static Date dateFromStringYYYYMMDD(String currentDate) {
        List<String> dateComponent = currentDate.split('-');
        Date formedDate = Date.newInstance(Integer.valueOf(dateComponent.get(0)), Integer.valueOf(dateComponent.get(1)), Integer.valueOf(dateComponent.get(2)));
        return formedDate;
    }

    @TestVisible
    public static Datetime datetimeFromStringYYYYMMDD(String currentDate) {
        List<String> dateComponent = currentDate.split('-');
        Datetime formedDatetime = Datetime.newInstance(Integer.valueOf(dateComponent.get(0)), Integer.valueOf(dateComponent.get(1)), Integer.valueOf(dateComponent.get(2)), 0, 0, 0);
        return formedDatetime;
    }

    @TestVisible
    private static Amendment__c createAmendmentRecordToBeUpdate(Amendment__c amendment) {
        Amendment__c amendmentToUpdate = new Amendment__c(Id = amendment.Id, Executed__c = true, Amendment_Status__c = 'Activated');
        return amendmentToUpdate;
    }

    @TestVisible
    private static FeedItem createChatterPostRecord(Amendment__c amendment, String amendmentChanges) {
        FeedItem post = new FeedItem();
        post.ParentId = amendment.Contract__c;
        post.Body = amendmentChanges;
        return post;
    }

    @TestVisible
    private static Task createActivityHistoryRecord(Amendment__c amendment, Contract contract, String amendmentChanges) {
        Task task = new Task(Subject = 'Amendment: ' + amendment.Name, OwnerId = amendment.CreatedById, WhatId = contract.Id, ActivityDate = amendment.Amendment_Effective_Date__c, Status = 'Completed', Description = amendmentChanges);
        return task;
    }

    public static void sendExceptionEmailToAdmins(String errorException) {
        List<String> toAddresses = new List<String>();
        for(User user : [SELECT Id, Email FROM User WHERE Profile.Name = 'System Administrator']) {
            toAddresses.add(user.Email);
        }
        sendEmail(toAddresses, errorException);
    }

    @TestVisible
    private static void sendEmail(List<String> toAddresses, String errorBody) {
        List<Messaging.SingleEmailMessage> emailMessages = new List<Messaging.SingleEmailMessage>();
        Messaging.SingleEmailMessage emailMessage = new Messaging.SingleEmailMessage();
        emailMessage.toAddresses = toAddresses;
        Date currentDate = Date.today();
        emailMessage.subject = ('Contract Amendment Batch Exception: ' + String.valueOf(currentDate.month()) + '/' + String.valueOf(currentDate.day()) + '/' + String.valueOf(currentDate.year()));
        emailMessage.htmlBody = errorBody;
        emailMessage.optOutPolicy = 'FILTER';
        emailMessage.bccSender = false;
        emailMessage.useSignature = false;

        emailMessages.add(emailMessage);
        Messaging.sendEmail(emailMessages);
    }
}