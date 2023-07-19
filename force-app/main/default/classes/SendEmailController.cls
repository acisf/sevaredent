/**
 * Apex controller for sendEmail LWC component.
 */ 
public with sharing class SendEmailController {

    /**
     * Called when the “Send” email button is clicked. Delegates 
     * work to the EmailSender class.
     * @param  subject subject for Case and Email
     * @param  message description for Case, message for Email
     * @return         true - if email is sent, otherwise - false
     */ 
    @AuraEnabled
    public static Boolean sendEmail(String subject, String message) {
        try {
            return EmailSender.emailCase(subject, message);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}