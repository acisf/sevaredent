@isTest
public class TestDataFactory {
    public static Account CreateAccount() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        return acc;
    }

    public static Account createAccount(String name, String type) {
        Account acc = new Account(
            Name = name,
            Type = type,
            RecordTypeId = Schema.sObjectType.Account.getRecordTypeInfosByName()
                .get('Member')
                .getRecordTypeId(),
            Status__c = 'Active'
        );
        insert acc;

        return acc;
    }

    public static User createCommunityUser(String accId, String name) {
        Profile userProfile = [
            SELECT Id
            FROM Profile
            WHERE Name = 'Member'
            LIMIT 1
        ];

        Contact cont = new Contact(LastName = name, AccountId = accId);
        insert cont;

        User newUser = new User(
            ProfileId = userProfile.Id,
            ContactId = cont.Id,
            Alias = 'test',
            Email = name + '@useremail.address',
            Username = name + '@useremail.address',
            LastName = name,
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            TimeZoneSidKey = 'America/Los_Angeles',
            IsActive = true
        );
        insert newUser;

        return newUser;
    }

    public static User createOwner() {
        Profile stdUserProfile = [
            SELECT Id
            FROM Profile
            WHERE Name = 'System Administrator'
            LIMIT 1
        ];

        UserRole portalOwner = new UserRole(Name = 'Portal Owner');
        insert portalOwner;

        User accountOwner = new User(
            Alias = 'accOwner',
            Email = 'accOwner@testorg.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Owner',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = stdUserProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'accOwner@bond.com',
            UserRoleId = portalOwner.Id
        );

        insert accountOwner;
        return accountOwner;
    }

    public static User createUserManager1() {
        Profile pro = [SELECT Id FROM Profile WHERE Name = 'Contracting'];
        User testUserA = new User(
            Alias = 'standard',
            Email = 'standarduser@testorg.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Testing',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = pro.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'newTestUserA@testorganise.com'
        );

        insert testUserA;
        return testUserA;
    }

    public static User createUserManager2() {
        Profile pro = [SELECT Id FROM Profile WHERE Name = 'Contracting'];
        User testUserB = new User(
            Alias = 'standard',
            Email = 'standarduser@testorg.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Testing',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = pro.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'testUserB@testorganise.com'
        );

        insert testUserB;
        return testUserB;
    }

    public static APXT_Redlining__Contract_Agreement__c createContractAgreement(
        Account acc
    ) {
        String conAgreeRecordTypeId = Schema.sObjectType.APXT_Redlining__Contract_Agreement__c.getRecordTypeInfosByName()
            .get('MSA')
            .getRecordTypeId();

        User testUserA = TestDataFactory.createUserManager1();

        APXT_Redlining__Contract_Agreement__c conAgree = new APXT_Redlining__Contract_Agreement__c(
            APXT_Redlining__Account__c = acc.Id,
            APXT_Redlining__Status__c = 'Activated',
            APXT_Redlining__Type__c = 'Direct',
            APXT_Redlining__Effective_Date__c = System.today(),
            Sevaredent_Contract_Number__c = '648783',
            APXT_Redlining__Agreement_Type__c = 'Master Service Agreement',
            Sourcing_Manager__c = testUserA.Id,
            Contract_Eligibility__c = 'Education (discipline)',
            RecordTypeId = conAgreeRecordTypeId
        );

        insert conAgree;
        return conAgree;
    }

    public static APXT_Redlining__Contract_Agreement__c createContractAgreementWithParent(
        Account acc,
        String parentId
    ) {
        String conAgreeRecordTypeId = Schema.sObjectType.APXT_Redlining__Contract_Agreement__c.getRecordTypeInfosByName()
        .get('Amendment')
        .getRecordTypeId();

        User testUserA = TestDataFactory.createUserManager2();

        APXT_Redlining__Contract_Agreement__c conAgree = new APXT_Redlining__Contract_Agreement__c(
            APXT_Redlining__Account__c = acc.Id,
            APXT_Redlining__Status__c = 'Being Amended',
            APXT_Redlining__Contract_Agreement_Family_Parent__c = parentId,
            APXT_Redlining__Type__c = 'Direct',
            APXT_Redlining__Effective_Date__c = System.today(),
            Sevaredent_Contract_Number__c = '648784',
            APXT_Redlining__Agreement_Type__c = 'Master Service Agreement',
            Sourcing_Manager__c = testUserA.Id,
            Contract_Eligibility__c = 'Education (discipline)',
            RecordTypeId = conAgreeRecordTypeId
        );

        insert conAgree;
        return conAgree;
    }

    public static void createContractAgreements(Account acc, String specId) {
        String conAgreeRecordTypeId = Schema.sObjectType.APXT_Redlining__Contract_Agreement__c.getRecordTypeInfosByName()
            .get('MSA')
            .getRecordTypeId();

        User testUserA = TestDataFactory.createUserManager1();

        APXT_Redlining__Contract_Agreement__c conAgree1 = new APXT_Redlining__Contract_Agreement__c(
            APXT_Redlining__Account__c = acc.Id,
            APXT_Redlining__Status__c = 'Activated',
            APXT_Redlining__Type__c = 'Direct',
            APXT_Redlining__Effective_Date__c = System.today(),
            Sevaredent_Contract_Number__c = '648783',
            APXT_Redlining__Agreement_Type__c = 'Master Service Agreement',
            Sourcing_Manager__c = testUserA.Id,
            Contract_Eligibility__c = 'GPO All– Commercially Available for entire GPO',
            RecordTypeId = conAgreeRecordTypeId
        );

        APXT_Redlining__Contract_Agreement__c conAgree2 = new APXT_Redlining__Contract_Agreement__c(
            APXT_Redlining__Account__c = acc.Id,
            APXT_Redlining__Status__c = 'Activated',
            APXT_Redlining__Type__c = 'Direct',
            APXT_Redlining__Effective_Date__c = System.today(),
            Sevaredent_Contract_Number__c = '648783',
            APXT_Redlining__Agreement_Type__c = 'Master Service Agreement',
            Sourcing_Manager__c = testUserA.Id,
            Specific_Member__c = specId,
            Contract_Eligibility__c = 'Custom/Member Specific – Custom contract for member on Sevāredent paper',
            RecordTypeId = conAgreeRecordTypeId
        );

        APXT_Redlining__Contract_Agreement__c conAgree3 = new APXT_Redlining__Contract_Agreement__c(
            APXT_Redlining__Account__c = acc.Id,
            APXT_Redlining__Status__c = 'Activated',
            APXT_Redlining__Type__c = 'Direct',
            APXT_Redlining__Effective_Date__c = System.today(),
            Sevaredent_Contract_Number__c = '648783',
            APXT_Redlining__Agreement_Type__c = 'Master Service Agreement',
            Sourcing_Manager__c = testUserA.Id,
            Contract_Eligibility__c = 'Education (discipline)',
            RecordTypeId = conAgreeRecordTypeId
        );

        insert new List<APXT_Redlining__Contract_Agreement__c>{
            conAgree1,
            conAgree2,
            conAgree3
        };
    }

    public static void createContractImplementation(Id accId, Id conAgreeId) {
        insert new Contract_Implementations__c(
            Account__c = accId,
            Contract_Agreement__c = conAgreeId,
            Effective_Date__c = Date.today(),
            Status__c = 'Implemented'
        );
    }

    public static Item_Pricing__c createItemPricing(
        APXT_Redlining__Contract_Agreement__c conAgree
    ) {
        Item_Pricing__c ItemPricing = new Item_Pricing__c(
            Contract_Agreement__c = conAgree.Id,
            Manufacturer_Name__c = 'Test Manuf',
            Manufacturer_Part_Number__c = '23',
            Price_Start_Date__c = System.today(),
            Sevaredent_Contract_Number__c = '648783',
            Item_Description__c = 'Test description',
            Contract_Tier_1_Description__c = 'test',
            Contract_Tier_2_Description__c = null,
            Contract_Tier_3_Description__c = null,
            Contract_Tier_4_Description__c = null,
            Contract_Tier_1_Price_UOM__c = 23,
            Contract_Tier_2_Price_UOM__c = null,
            Contract_Tier_3_Price_UOM__c = null,
            Contract_Tier_4_Price_UOM__c = null,
            UOM__c = 'Test',
            Packaging_String__c = 'test',
            Qty_of_EA_p_UOM__c = 23,
            Price_End_Date__c = System.today() + 1
        );

        insert ItemPricing;

        return ItemPricing;
    }

    public static Item_Pricing__c nonInsertItemPricing(
        APXT_Redlining__Contract_Agreement__c conAgree
    ) {
        Item_Pricing__c ItemPricing1 = new Item_Pricing__c(
            Contract_Agreement__c = conAgree.Id,
            Manufacturer_Name__c = 'Test Manuf',
            Manufacturer_Part_Number__c = '23',
            Price_Start_Date__c = System.today(),
            Sevaredent_Contract_Number__c = '45678',
            Item_Description__c = null,
            Contract_Tier_1_Description__c = 'Test',
            Contract_Tier_2_Description__c = 'test',
            Contract_Tier_3_Description__c = null,
            Contract_Tier_4_Description__c = null,
            Contract_Tier_1_Price_UOM__c = 23,
            Contract_Tier_2_Price_UOM__c = null,
            Contract_Tier_3_Price_UOM__c = null,
            Contract_Tier_4_Price_UOM__c = null,
            UOM__c = 'Test',
            Packaging_String__c = 'test',
            Qty_of_EA_p_UOM__c = 23,
            Price_End_Date__c = System.today() + 1
        );

        return ItemPricing1;
    }

    public static Item_Pricing__c nonInsertItemPricingCorrectData(
        APXT_Redlining__Contract_Agreement__c conAgree
    ) {
        Item_Pricing__c ItemPricing2 = new Item_Pricing__c(
            Contract_Agreement__c = conAgree.Id,
            Manufacturer_Name__c = 'Test Manuf',
            Manufacturer_Part_Number__c = '23',
            Price_Start_Date__c = System.today(),
            Sevaredent_Contract_Number__c = '648783',
            Item_Description__c = 'Test description',
            Contract_Tier_1_Description__c = 'test',
            Contract_Tier_2_Description__c = null,
            Contract_Tier_3_Description__c = null,
            Contract_Tier_4_Description__c = null,
            Contract_Tier_1_Price_UOM__c = 23,
            Contract_Tier_2_Price_UOM__c = null,
            Contract_Tier_3_Price_UOM__c = null,
            Contract_Tier_4_Price_UOM__c = null,
            UOM__c = 'Test',
            Packaging_String__c = 'test',
            Qty_of_EA_p_UOM__c = 23,
            Price_End_Date__c = System.today() + 1
        );

        return ItemPricing2;
    }

    public static Item_Pricing__c nonInsertItemPricingCorrectData1(
        APXT_Redlining__Contract_Agreement__c conAgree
    ) {
        Item_Pricing__c ItemPricing3 = new Item_Pricing__c(
            Contract_Agreement__c = conAgree.Id,
            Manufacturer_Name__c = 'Test Manuf',
            Manufacturer_Part_Number__c = '23',
            Price_Start_Date__c = System.today(),
            Sevaredent_Contract_Number__c = '648783',
            Item_Description__c = 'Test description',
            Contract_Tier_1_Description__c = 'test',
            Contract_Tier_2_Description__c = 'test',
            Contract_Tier_3_Description__c = null,
            Contract_Tier_4_Description__c = null,
            Contract_Tier_1_Price_UOM__c = 23,
            Contract_Tier_2_Price_UOM__c = null,
            Contract_Tier_3_Price_UOM__c = null,
            Contract_Tier_4_Price_UOM__c = null,
            UOM__c = 'Test',
            Packaging_String__c = 'test',
            Qty_of_EA_p_UOM__c = 23,
            Price_End_Date__c = System.today() + 1,
            UNIQUE_KEY__c = conAgree.Id +
                '_' +
                '648783' +
                '_' +
                'Test Manuf' +
                '_' +
                '23' +
                '_' +
                'Test' +
                '_' +
                System.today()
        );

        return ItemPricing3;
    }

    public static Item_Pricing__c nonInsertItemPricingCorrectData2(
        APXT_Redlining__Contract_Agreement__c conAgree
    ) {
        Item_Pricing__c ItemPricing4 = new Item_Pricing__c(
            Contract_Agreement__c = conAgree.Id,
            Manufacturer_Name__c = 'Test',
            Manufacturer_Part_Number__c = '23',
            Price_Start_Date__c = System.today(),
            Sevaredent_Contract_Number__c = '648783',
            Item_Description__c = 'Test description',
            Contract_Tier_1_Description__c = 'test',
            Contract_Tier_2_Description__c = null,
            Contract_Tier_3_Description__c = null,
            Contract_Tier_4_Description__c = null,
            Contract_Tier_1_Price_UOM__c = 23,
            Contract_Tier_2_Price_UOM__c = null,
            Contract_Tier_3_Price_UOM__c = null,
            Contract_Tier_4_Price_UOM__c = null,
            UOM__c = 'Test',
            Packaging_String__c = 'test',
            Qty_of_EA_p_UOM__c = 23,
            Price_End_Date__c = System.today() + 1,
            UNIQUE_KEY__c = conAgree.Id +
                '_' +
                '648783' +
                '_' +
                'Test' +
                '_' +
                '23' +
                '_' +
                'Test' +
                '_' +
                System.today()
        );

        return ItemPricing4;
    }

    public static Item_Pricing__c nonInsertItemPricingCorrectData3(
        APXT_Redlining__Contract_Agreement__c conAgree
    ) {
        Item_Pricing__c ItemPricing5 = new Item_Pricing__c(
            Contract_Agreement__c = conAgree.Id,
            Manufacturer_Name__c = 'Test',
            Manufacturer_Part_Number__c = '23',
            Price_Start_Date__c = System.today(),
            Sevaredent_Contract_Number__c = '648783',
            Item_Description__c = 'Test description',
            Contract_Tier_1_Description__c = 'test',
            Contract_Tier_2_Description__c = null,
            Contract_Tier_3_Description__c = null,
            Contract_Tier_4_Description__c = null,
            Contract_Tier_1_Price_UOM__c = 23,
            Contract_Tier_2_Price_UOM__c = null,
            Contract_Tier_3_Price_UOM__c = null,
            Contract_Tier_4_Price_UOM__c = null,
            UOM__c = 'Test',
            Qty_of_EA_p_UOM__c = 23,
            Packaging_String__c = 'test',
            Price_End_Date__c = System.today() + 1,
            UNIQUE_KEY__c = conAgree.Id +
                '_' +
                '648783' +
                '_' +
                'Test' +
                '_' +
                '23' +
                '_' +
                'Test' +
                '_' +
                System.today()
        );

        return ItemPricing5;
    }

    public static APXT_Redlining__Contract_Agreement__c createContractAgreementAmendment(
        Account acc,
        APXT_Redlining__Contract_Agreement__c conAgree
    ) {
        String conAgreeRecordTypeId = Schema.sObjectType.APXT_Redlining__Contract_Agreement__c.getRecordTypeInfosByName()
            .get('Amendment')
            .getRecordTypeId();

        User testUserB = TestDataFactory.createUserManager2();

        APXT_Redlining__Contract_Agreement__c conAgreeAmend = new APXT_Redlining__Contract_Agreement__c(
            APXT_Redlining__Account__c = acc.Id,
            APXT_Redlining__Status__c = 'Draft',
            APXT_Redlining__Type__c = 'Direct',
            APXT_Redlining__Effective_Date__c = System.today(),
            Sevaredent_Contract_Number__c = '648783',
            APXT_Redlining__Agreement_Type__c = 'Master Service Agreement',
            Sourcing_Manager__c = testUserB.Id,
            Contract_Eligibility__c = 'Education (discipline)',
            RecordTypeId = conAgreeRecordTypeId,
            APXT_Redlining__Contract_Agreement_Family_Parent__c = conAgree.Id
        );

        return conAgreeAmend;
    }

    public static List<Item_Pricing__c> bulkItemPricingRecords1(
        APXT_Redlining__Contract_Agreement__c conAgree
    ) {
        List<Item_Pricing__c> itemPricingList1 = new List<Item_Pricing__c>();

        for (Integer i = 0; i < 2000; i++) {
            Item_Pricing__c ItemPricing1 = new Item_Pricing__c(
                Contract_Agreement__c = conAgree.Id,
                Manufacturer_Name__c = 'Test',
                Manufacturer_Part_Number__c = String.valueOf(i),
                Price_Start_Date__c = System.today(),
                Sevaredent_Contract_Number__c = '648783',
                Item_Description__c = 'Test description',
                Contract_Tier_1_Description__c = 'test',
                Contract_Tier_2_Description__c = null,
                Contract_Tier_3_Description__c = null,
                Contract_Tier_4_Description__c = null,
                Contract_Tier_1_Price_UOM__c = 23,
                Contract_Tier_2_Price_UOM__c = null,
                Contract_Tier_3_Price_UOM__c = null,
                Contract_Tier_4_Price_UOM__c = null,
                UOM__c = 'Test',
                Qty_of_EA_p_UOM__c = 23,
                Packaging_String__c = 'test',
                Price_End_Date__c = System.today() + 1,
                UNIQUE_KEY__c = conAgree.Id +
                    '_' +
                    '648783' +
                    '_' +
                    'Test' +
                    '_' +
                    String.valueOf(i) +
                    '_' +
                    'Test' +
                    '_' +
                    System.today()
            );

            itemPricingList1.add(ItemPricing1);
        }

        insert itemPricingList1;

        return itemPricingList1;
    }

    public static List<Item_Pricing__c> bulkItemPricingRecords2(
        APXT_Redlining__Contract_Agreement__c conAgree
    ) {
        List<Item_Pricing__c> itemPricingList2 = new List<Item_Pricing__c>();

        for (Integer i = 0; i < 2000; i++) {
            Item_Pricing__c ItemPricing2 = new Item_Pricing__c(
                Contract_Agreement__c = conAgree.Id,
                Manufacturer_Name__c = 'Test',
                Manufacturer_Part_Number__c = String.valueOf(i),
                Price_Start_Date__c = System.today(),
                Sevaredent_Contract_Number__c = '648783',
                Item_Description__c = 'Test description',
                Contract_Tier_1_Description__c = 'test',
                Contract_Tier_2_Description__c = null,
                Contract_Tier_3_Description__c = null,
                Contract_Tier_4_Description__c = null,
                Contract_Tier_1_Price_UOM__c = 23,
                Contract_Tier_2_Price_UOM__c = null,
                Contract_Tier_3_Price_UOM__c = null,
                Contract_Tier_4_Price_UOM__c = null,
                UOM__c = 'Test',
                Qty_of_EA_p_UOM__c = 23,
                Packaging_String__c = 'test',
                Price_End_Date__c = System.today() + 1,
                UNIQUE_KEY__c = conAgree.Id +
                    '_' +
                    '648783' +
                    '_' +
                    'Test' +
                    '_' +
                    String.valueOf(i) +
                    '_' +
                    'Test' +
                    '_' +
                    System.today()
            );

            itemPricingList2.add(ItemPricing2);
        }

        insert itemPricingList2;

        return itemPricingList2;
    }

    public static List<Item_Pricing__c> bulkItemPricingRecords3(
        APXT_Redlining__Contract_Agreement__c conAgree
    ) {
        List<Item_Pricing__c> itemPricingList1 = new List<Item_Pricing__c>();

        for (Integer i = 0; i < 200; i++) {
            Item_Pricing__c ItemPricing1 = new Item_Pricing__c(
                Contract_Agreement__c = conAgree.Id,
                Manufacturer_Name__c = 'Test',
                Manufacturer_Part_Number__c = String.valueOf(i),
                Price_Start_Date__c = System.today(),
                Sevaredent_Contract_Number__c = '648783',
                Item_Description__c = 'Test description',
                Contract_Tier_1_Description__c = 'test',
                Contract_Tier_2_Description__c = null,
                Contract_Tier_3_Description__c = null,
                Contract_Tier_4_Description__c = null,
                Contract_Tier_1_Price_UOM__c = 23,
                Contract_Tier_2_Price_UOM__c = null,
                Contract_Tier_3_Price_UOM__c = null,
                Contract_Tier_4_Price_UOM__c = null,
                UOM__c = 'Test',
                Qty_of_EA_p_UOM__c = 23,
                Packaging_String__c = 'test',
                Price_End_Date__c = System.today() + 1,
                UNIQUE_KEY__c = conAgree.Id +
                    '_' +
                    '648783' +
                    '_' +
                    'Test' +
                    '_' +
                    String.valueOf(i) +
                    '_' +
                    'Test' +
                    '_' +
                    System.today()
            );

            itemPricingList1.add(ItemPricing1);
        }

        insert itemPricingList1;

        return itemPricingList1;
    }

    public static List<Item_Pricing__c> bulkItemPricingRecords4(
        APXT_Redlining__Contract_Agreement__c conAgree
    ) {
        List<Item_Pricing__c> List1 = TestDataFactory.bulkItemPricingRecords1(
            conAgree
        );

        List<Item_Pricing__c> List4 = new List<Item_Pricing__c>();

        for (Item_Pricing__c it1 : List1) {
            List4.add(it1);
        }

        return List4;
    }

    public static List<Item_Pricing__c> bulkItemPricingRecords5(
        APXT_Redlining__Contract_Agreement__c conAgree
    ) {
        List<Item_Pricing__c> List2 = TestDataFactory.bulkItemPricingRecords2(
            conAgree
        );

        List<Item_Pricing__c> List5 = new List<Item_Pricing__c>();

        for (Item_Pricing__c it2 : List2) {
            List5.add(it2);
        }

        return List5;
    }

    public static void createFiles() {
        List<ContentVersion> documents = new List<ContentVersion>();

        ContentVersion all = new ContentVersion(
            Title = 'Test',
            PathOnClient = 'Test.jpg',
            VersionData = Blob.valueOf('Test Content'),
            Visibility__c = 'All',
            IsMajorVersion = true
        );
        documents.add(all);

        ContentVersion affordable = new ContentVersion(
            Title = 'Test',
            PathOnClient = 'Test.jpg',
            VersionData = Blob.valueOf('Test Content'),
            Visibility__c = 'Affordable Care',
            IsMajorVersion = true
        );
        documents.add(affordable);

        ContentVersion commercial = new ContentVersion(
            Title = 'Test',
            PathOnClient = 'Test.jpg',
            VersionData = Blob.valueOf('Test Content'),
            Visibility__c = 'Commercial',
            IsMajorVersion = true
        );
        documents.add(commercial);

        ContentVersion education = new ContentVersion(
            Title = 'Test',
            PathOnClient = 'Test.jpg',
            VersionData = Blob.valueOf('Test Content'),
            Visibility__c = 'Education',
            IsMajorVersion = true
        );
        documents.add(education);

        insert documents;
    }
}