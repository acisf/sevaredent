@isTest
public with sharing class SendEmailControllerTest {
    @isTest
    private static void sendSingleEmail() {
        Test.startTest();

        User testUser;
        User owner = TestDataFactory.createOwner();

        System.runAs(owner) {
            Account acc = TestDataFactory.createAccount('Test', null);
            testUser = TestDataFactory.createCommunityUser(acc.Id, 'TestUser');
        }

        System.runAs(testUser) {
            Boolean isSent = SendEmailController.sendEmail(
                'Test',
                'Test message'
            );

            System.assertEquals(true, isSent, 'email was not sent');
        }

        Test.stopTest();
    }

    @isTest
    private static void sendSingleEmailForException() {
        Test.startTest();

        Boolean exceptionThrown = false;
        
        try {
            Boolean isSent = SendEmailController.sendEmail(
                null,
                null
            );
        } catch (Exception ex) {
            exceptionThrown = true;
        }

        Test.stopTest();

        System.assertEquals(true, exceptionThrown, 'exception was not thrown');
    }
}