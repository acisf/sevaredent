/**
 * Service class for SendEmailController.
 */ 
public with sharing class EmailSender {

    /**
     * Creates a case and then sends email according to input parameters. 
     * Message is sent on behalf of the current User. Recipient of the 
     * Email is described in CommunitySettings__mdt Custom Metadata Types 
     * Sevaredent_Portal.Contact_Us_Email_Reciever__c
     * @param  subject subject for Case and Email
     * @param  message description for Case, message for Email
     * @return         true - if email is sent, otherwise - false
     */ 
    public static Boolean emailCase(String subject, String message) {
        createCase(subject, message);
        return sendSingleEmail(subject, message);
    }

    /**
     * Creates a case according to input parameters.
     * @param  subject subject for Case
     * @param  message description for Case
     */ 
    private static void createCase(String subject, String message) {
        insert new Case(
            Origin = 'Email',
            Subject = subject,
            Description = message
        );
    }

    /**
     * Sends email according to input parameters on behalf of the current User.
     * @param  subject subject for Email
     * @param  message message for Email
     * @return         true - if email is sent, otherwise - false
     */ 
    private static Boolean sendSingleEmail(String subject, String message) {
        String addressees = getAddressees();

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(addressees.split(','));
        mail.setSubject(subject);
        mail.setPlainTextBody(message);
        mail.setReplyTo(UserInfo.getUserEmail());
        mail.setSenderDisplayName(UserInfo.getName());

        Messaging.SendEmailResult[] results = Messaging.sendEmail(
            new List<Messaging.SingleEmailMessage>{ mail }
        );

        if (!results[0].success) {
            throw new AuraHandledException(
                'The email failed to send: ' + results[0].errors[0].message
            );
        }

        return results[0].success;
    }

    /**
     * Retrieve email address to send Email from Custom Metadata Types object
     * @return   email address
     */ 
    private static String getAddressees() {
        return Test.isRunningTest()
            ? 'test@email.com'
            : CommunitySettings__mdt.getInstance('Sevaredent_Portal')
                  .Contact_Us_Email_Reciever__c;
    }
}