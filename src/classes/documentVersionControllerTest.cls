@isTest
public class documentVersionControllerTest {

     static testMethod void testDocController() {
        // create a file
            ContentVersion contentVersion = new ContentVersion(
            Title = 'test1',
            PathOnClient = 'test1.jpg',
            VersionData = Blob.valueOf('Test Content'),
            IsMajorVersion = true
        );
        insert contentVersion;
        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
        Id docId = documents[0].Id;
        string docTitle = documents[0].Title;
        documentVersionController docContoller = new documentVersionController();
		List<documentVersionController.versionWrapper> verList = documentVersionController.getDocVersions(docId);
        System.assertEquals(verList[0].Title, docTitle);
    }
}