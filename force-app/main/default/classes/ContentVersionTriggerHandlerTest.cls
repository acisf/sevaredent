/**
 * Created by cshah on Nov 16, 2020.
 */

@IsTest
public class ContentVersionTriggerHandlerTest {
    @IsTest
    public static void testUpdateFileNameToAmendments() {
        ContentVersion contentVersion = new ContentVersion(
                Title = 'Test File',
                PathOnClient = 'TestFile.jpg',
                VersionData = Blob.valueOf('Test Content'),
                IsMajorVersion = true
        );
        insert contentVersion;

        ContentVersion contentVersion_2 = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id LIMIT 1];
        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
        System.assertEquals(documents.size(), 1);
        System.assertEquals(documents[0].Id, contentVersion_2.ContentDocumentId);
        System.assertEquals(documents[0].LatestPublishedVersionId, contentVersion_2.Id);
        System.assertEquals(documents[0].Title, contentVersion_2.Title);

        Account account = new Account(Name = 'Test Account');
        insert account;

        Contract contract = new Contract(Name='Test Contract', StartDate = Date.today(), AccountId=account.Id, Sevaredent_Contract_Number__c = 'Test Sevaredent');
        insert contract;

        Amendment__c amendment = new Amendment__c(Name='Test Amendment', Contract__c = contract.Id, Amendment_Number1__c = 1, Amendment_Status__c = 'Draft', Amendment_Type__c = 'Extension');
        insert amendment;

        ContentDocumentLink contentDocumentLink = new ContentDocumentLink(LinkedEntityId=amendment.Id, ContentDocumentId=documents.get(0).Id);
        insert contentDocumentLink;

        // Update
        ContentVersion contentVersion3 = new ContentVersion(Id= contentVersion_2.Id, Title='Test New Title');
        update contentVersion3;

        // Delete
        delete documents.get(0);
    }
}