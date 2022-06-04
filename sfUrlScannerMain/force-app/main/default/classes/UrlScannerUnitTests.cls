@IsTest(SeeAllData=false)
public class UrlScannerUnitTests {
    @isTest
    public static void testMockIpQualityScoreApi() {
        
    }
    
    @isTest
    public static void testScanUrlInFile() {
        IPQualityScore__c ipQualityScore = new IPQualityScore__c();
        ipQualityScore.API_Key__c = 'API_KEY';
        insert ipQualityScore;
        
        Case testCase = new Case();
        testCase.Status = 'New';
        testCase.Origin = 'Phone';
        insert testCase;
                
        String bodyString = 'Visit photo hosting sites such as www.flickr.com,';
        bodyString += '\n 500px.com, www.freeimagehosting.net and https://postimage.io, and upload these two image';
        bodyString += '\n files, picture.dog.png and picture.cat.jpeg, there. After that share their links';
        bodyString += '\n at https://www.facebook.com/.';
        
        ContentVersion content = new ContentVersion();
        content.Title = 'test'; 
        content.PathOnClient= '/' + content.Title + '.txt';
        Blob bodyBlob = Blob.valueOf(bodyString);
        content.VersionData=bodyBlob; 
        content.origin = 'H';
        insert content;
                
        ContentDocumentLink contentlink=new ContentDocumentLink();
        contentlink.LinkedEntityId= testCase.id;
        List<ContentVersion> contentDocumentVersionsByContentDocId = UrlScannerDatabaseController.getContentVersionsByContentDocumentLink('', content.Id);
        contentlink.contentdocumentid = contentDocumentVersionsByContentDocId[0].contentdocumentid;
        contentlink.ShareType = 'I';
        contentlink.Visibility = 'AllUsers';
        insert contentlink;
        
        Test.startTest();
        
        Map<String, Object> mapOfDataAndStatus = UrlScannerController.fetchUrlsAndTheirStatuses(testCase.Id);
        List<Map<String, String>> listOfMapsOfUrls = (List<Map<String, String>>) mapOfDataAndStatus.get('list');
        System.assertEquals(true, listOfMapsOfUrls.size() > 0, 'No urls are found in the input txt');
        System.assertEquals(true, !(Boolean) mapOfDataAndStatus.get('status'), 'File contains malicious url');
        
        Test.stopTest();
    }

}