global class ItemPricingDeleteBatch implements Database.Batchable<sObject>,Database.Stateful{

    Id contractId;
    String emailBody;
    Integer successNumber = 0;
    Integer failedNumber = 0;
    String errorMessage =' ';
   
    public ItemPricingDeleteBatch( Id contractAgreementId ) {
        contractId = contractAgreementId;
    }


    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator([Select Id, Contract_Agreement__c from Item_Pricing__c where Contract_Agreement__c =:contractId AND To_Be_Deleted__c = true]);
    }

    global void execute(Database.BatchableContext BC, List<Item_Pricing__c> scope) { 
        
        try{
            successNumber = successNumber+scope.size();
            delete scope;
        }catch(Exception e){
            failedNumber = failedNumber + +scope.size();
            errorMessage = errorMessage + ' ' +e.getMessage();
        }

    }

    global void finish(Database.BatchableContext BC)
    {
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        List<String> sendTo = new List<String>();
        mail.setToAddresses(new List<String>{UserInfo.getUserEmail()});
        //mail.setToAddresses(new List<String>{'darshan@appluent.net'});
        //mail.setReplyTo('dev@appluent.com');
        mail.setSenderDisplayName('Delete Item Pricing Batch');
        mail.setSubject('Delete Item Pricing Batch Result ');
        String body = '<p> Hi ' + UserInfo.getName() + ', </p>';
        body += '<p>Number of Records Deleted : '+successNumber+ '</p>';
        body += '<p>Failed to Delete Records : '+failedNumber+ '</p>';
        body += '<p>Error : '+errorMessage+ '</p>';
        mail.setHtmlBody(body);
        System.debug(body);
        mails.add(mail);

        try {
            if(!Test.isRunningTest()){
                Messaging.reserveSingleEmailCapacity(1);
                Messaging.sendEmail(mails);
            }
        
        } catch (Exception e){
            System.debug('Error Sending email - ' + e.getMessage());
        }

    }


}