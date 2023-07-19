@isTest(SeeAllData=true)
private class CSVPriceUploadComponentControllerTest {
    
static testMethod void deleteMethodBatchTest(){
    Account acc = TestDataFactory.CreateAccount();
    APXT_Redlining__Contract_Agreement__c conAgree = TestDataFactory.createContractAgreement(acc);
    Item_Pricing__c itemPricing = TestDataFactory.createItemPricing(conAgree);
    itemPricing.To_Be_Deleted__c = true;
    update itemPricing;
    Test.startTest();
        String returnString = CSVPriceUploadComponentController.deleteExistingRecords(conAgree.Id);
        System.assertEquals(null, returnString);
    Test.stopTest();

}


static testMethod void getExistingRecordsTest(){

    Account acc = TestDataFactory.CreateAccount();
    APXT_Redlining__Contract_Agreement__c conAgree = TestDataFactory.createContractAgreement(acc);
    Item_Pricing__c itemPricing = TestDataFactory.createItemPricing(conAgree);
    

    Test.startTest();
    CSVPriceUploadComponentController.existingRecordsResults wrapper = new CSVPriceUploadComponentController.existingRecordsResults();
    wrapper = CSVPriceUploadComponentController.getExistingRecords(conAgree.Id);
    System.assertEquals(1, wrapper.totalRows);
    Test.stopTest();
    
}
  
static testMethod void getsObjectRecordsTest(){

    Account acc = TestDataFactory.CreateAccount();
    APXT_Redlining__Contract_Agreement__c conAgree = TestDataFactory.createContractAgreement(acc);
    Item_Pricing__c itemPricing = TestDataFactory.createItemPricing(conAgree);
    List<Item_Pricing__c> listItemPricing = new List<Item_Pricing__c>();
    test.startTest();

    listItemPricing = CSVPriceUploadComponentController.getsObjectRecords('0', conAgree.Id);
    system.debug(listItemPricing);
    system.assertEquals(1, listItemPricing.size());
    test.stopTest();

}

static testMethod void saveCSVFileTest(){

    Account acc = TestDataFactory.CreateAccount();
    APXT_Redlining__Contract_Agreement__c conAgree = TestDataFactory.createContractAgreement(acc);
    Item_Pricing__c itemPricing = TestDataFactory.createItemPricing(conAgree);
    Item_Pricing__c itemPricing1 = TestDataFactory.nonInsertItemPricing(conAgree);
    Item_Pricing__c itemPricing2 = TestDataFactory.nonInsertItemPricingCorrectData(conAgree);
    Item_Pricing__c itemPricing3 = TestDataFactory.nonInsertItemPricingCorrectData1(conAgree);
    List<Item_Pricing__c> listItemPricing = new List<Item_Pricing__c>();
    listItemPricing.add(itemPricing1);
    listItemPricing.add(itemPricing);
    listItemPricing.add(itemPricing2);
    listItemPricing.add(ItemPricing3);

    test.startTest();
    CSVPriceUploadComponentController.upsertRecordsResults upsertWrapper = new CSVPriceUploadComponentController.upsertRecordsResults();
    upsertWrapper = CSVPriceUploadComponentController.saveCSVFile(listItemPricing, conAgree.Id, '648783');
    system.assertEquals(null, upsertWrapper.insertedRecords);
    test.stopTest();

}

static testMethod void deleteItemPricingRecordsTest(){

    Account acc = TestDataFactory.CreateAccount();
    APXT_Redlining__Contract_Agreement__c conAgree = TestDataFactory.createContractAgreement(acc);
    Item_Pricing__c itemPricing = TestDataFactory.createItemPricing(conAgree);
    List<Item_Pricing__c> listItemPricing = new List<Item_Pricing__c>();
    listItemPricing.add(itemPricing);

    Integer i = 0;

    test.startTest();

    i = CSVPriceUploadComponentController.deleteItemPricingRecords(listItemPricing);
    system.assertEquals(1, i);
    test.stopTest();

}

static testMethod void getReportIdTest(){

    Account acc = TestDataFactory.CreateAccount();
    APXT_Redlining__Contract_Agreement__c conAgree = TestDataFactory.createContractAgreement(acc);

    String conName = [Select Name from APXT_Redlining__Contract_Agreement__c WHERE Id=:conAgree.Id].Name;

    CSVPriceUploadComponentController.reportRequirement reportWrapper = new CSVPriceUploadComponentController.reportRequirement();
    reportWrapper = CSVPriceUploadComponentController.getReportId(conAgree.Id);
    system.assertEquals(conName, reportWrapper.contractAgreementName);
    test.startTest();
}

static testMethod void saveCSVFileTest2(){

    Account acc = TestDataFactory.CreateAccount();
    APXT_Redlining__Contract_Agreement__c conAgree = TestDataFactory.createContractAgreement(acc);
    Item_Pricing__c itemPricing4 = TestDataFactory.nonInsertItemPricingCorrectData2(conAgree);
    List<Item_Pricing__c> listItemPricing = new List<Item_Pricing__c>();
    listItemPricing.add(itemPricing4);

    test.startTest();

    CSVPriceUploadComponentController.upsertRecordsResults upsertWrapper = new CSVPriceUploadComponentController.upsertRecordsResults();
    upsertWrapper = CSVPriceUploadComponentController.saveCSVFile(listItemPricing, conAgree.Id, '648783');
    System.assertEquals(1, upsertWrapper.insertedRecords.size());
    test.stopTest();
}

}