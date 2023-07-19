@isTest
public with sharing class RequestToElectControllerTest {
    
    @isTest
    private static void getAccountNameSuccess() {
        Test.startTest();

        Account acc = new Account(Name = 'Test');
        insert acc;

        String name = RequestToElectController.getAccountName(acc.Id);

        System.assertEquals(true, String.isNotBlank(name), 'name was not retrieved');
        System.assertEquals(acc.Name, name, 'retrieved name is not correct');

        Test.stopTest();
    }

    @isTest
    private static void getAccountNameException() {
        Test.startTest();

        Boolean exceptionThrown = false;

        try {
            String name = RequestToElectController.getAccountName('incorrect Id');
        } catch (Exception e) {
            exceptionThrown = true;
        }

        System.assertEquals(true, exceptionThrown, 'exception was not thrown');

        Test.stopTest();
    }

    @isTest
    private static void getReportIDSuccess() {
        Test.startTest();

        String id = RequestToElectController.getReportID();

        System.assertEquals(true, String.isNotBlank(id), 'field was not retrieved');

        Test.stopTest();
    }
}