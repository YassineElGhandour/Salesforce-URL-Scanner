@IsTest(SeeAllData = false)
public class UrlScannerUnitTests {
    private static final String BODY_WITH_URLS = 'Visit photo hosting sites such as www.flickr.com,500px.com, www.freeimagehosting.net and https://postimage.io and image';
    private static final String BODY_WITHOUT_URLS = 'This is a unit test body that does not contain any URLs';
    
    // Prepare a setup of mock data of 
    // * IP Quality Score custom setting
    // * Case
    // * ContentDocumentLink
    // and return the case Id
    private static String testSetup(String bodyString) {
        IPQualityScore__c ipQualityScore = new IPQualityScore__c();
        ipQualityScore.API_Key__c = 'API_KEY';
        insert ipQualityScore;
        
        Case testCase = new Case();
        testCase.Status = 'New';
        testCase.Origin = 'Phone';
        insert testCase;
                
        ContentVersion content = new ContentVersion();
        content.Title = 'test'; 
        content.PathOnClient= '/' + content.Title + '.txt';
        Blob bodyBlob = Blob.valueOf(bodyString);
        content.VersionData=bodyBlob; 
        content.origin = 'H';
        insert content;
                
        ContentDocumentLink contentlink = new ContentDocumentLink();
        contentlink.LinkedEntityId= testCase.id;
        List<ContentVersion> contentDocumentVersionsByContentDocId = UrlScannerDatabaseController.getContentVersionsByContentDocumentLink('', content.Id);
        contentlink.contentdocumentid = contentDocumentVersionsByContentDocId[0].contentdocumentid;
        contentlink.ShareType = 'I';
        contentlink.Visibility = 'AllUsers';
        insert contentlink;
        
        return testCase.Id;
    }
    
    // Set up HTTP mock response with 3 parameters
    // * HTTP request
    // * Risk Score to manmipulate the results of the urls being malicious or not (risk < 10 = safe, risk score > 10 == malicious)
    // * Status code to cover case of 400
    private static HttpResponse setHttpResponseWithRisk(HttpRequest req, Integer riskScore, Integer statusCode) {
        Map<String, Object> jsonMap = new Map<String, Object>();
        jsonMap.put('risk_score', riskScore);
        String fullJsonReponse = JSON.serialize(jsonMap);
        
        HttpResponse res = new HttpResponse();
        req.setHeader('Content-type', 'application/json');
        req.setHeader('accept', 'application/json');
        res.setBody(fullJsonReponse);
        res.setStatus('OK');
        res.setStatusCode(statusCode);
            
        return res;
    }
    
    // Mock successful responses of IP Quality Score no risk
    public class IpQualityScoreMockZeroRisk implements HttpCalloutMock {
        // Status code is 200 because the call is faked to be successful
        public HttpResponse respond(HttpRequest req) {
            return setHttpResponseWithRisk(req, 0, 200);
        }
    }
    
    // Mock successful responses of IP Quality Score With risk
    public class IpQualityScoreMockWithRisk implements HttpCalloutMock {
        // Status code is 200 because the call is faked to be successful
        public HttpResponse respond(HttpRequest req) {
			return setHttpResponseWithRisk(req, 100, 200);
        }
    }
    
    // Mock failure responses of IP Quality Score With risk
    public class IpQualityScoreMockFailure implements HttpCalloutMock {
        // Status code is 400 because the call is faked to fail
        public HttpResponse respond(HttpRequest req) {
			return setHttpResponseWithRisk(req, 100, 400);
        }
    }
    
    @isTest
    public static void testScanMoreThan100KbFile() {
        // HTTP Mocks
        Test.setMock(HttpCalloutMock.class, new IpQualityScoreMockZeroRisk());
        
        // Setup mock data
        String caseId = testSetup(UrlScannerService.FILE_CONTAINS_MORE_THAN_THRESHOLD_CHARACTERS);
        
        Test.startTest();
        
        Map<String, Object> mapOfDataAndStatus = UrlScannerController.fetchUrlsAndTheirStatuses(caseId);
        List<Map<String, String>> listOfMapsOfUrls = (List<Map<String, String>>) mapOfDataAndStatus.get('list');
        System.assertEquals(true, listOfMapsOfUrls.size() == 0, 'Urls are found in the input txt');
        
        Test.stopTest();
    }
    
    @isTest
    public static void testScanNoUrlsInFile() {
        // HTTP Mocks
        Test.setMock(HttpCalloutMock.class, new IpQualityScoreMockZeroRisk());
        
        // Setup mock data
        String caseId = testSetup(BODY_WITHOUT_URLS);
        
        Test.startTest();
        
        Map<String, Object> mapOfDataAndStatus = UrlScannerController.fetchUrlsAndTheirStatuses(caseId);
        List<Map<String, String>> listOfMapsOfUrls = (List<Map<String, String>>) mapOfDataAndStatus.get('list');
        System.assertEquals(true, listOfMapsOfUrls.size() == 0, 'Urls are found in the input txt');
        
        Test.stopTest();
    }
    
    @isTest
    public static void testScanUrlInFileZeroRisk() {
        // HTTP Mocks
        Test.setMock(HttpCalloutMock.class, new IpQualityScoreMockZeroRisk());
        
        // Setup mock data
        String caseId = testSetup(BODY_WITH_URLS);
        
        Test.startTest();
        
        Map<String, Object> mapOfDataAndStatus = UrlScannerController.fetchUrlsAndTheirStatuses(caseId);
        List<Map<String, String>> listOfMapsOfUrls = (List<Map<String, String>>) mapOfDataAndStatus.get('list');
        System.assertEquals(true, listOfMapsOfUrls.size() > 0, 'No urls are found in the input txt');
        System.assertEquals(true, !(Boolean) mapOfDataAndStatus.get('status'), 'File contains malicious urls');
        System.assertEquals(true, mapOfDataAndStatus.get('connectedToIPQ'), 'Failure of connection');
        
        Test.stopTest();
    }
    
    @isTest
    public static void testScanUrlInFileWithRisk() {
        // HTTP Mocks
        Test.setMock(HttpCalloutMock.class, new IpQualityScoreMockWithRisk());
        
        // Setup mock data
        String caseId = testSetup(BODY_WITH_URLS);
        
        Test.startTest();
        
        Map<String, Object> mapOfDataAndStatus = UrlScannerController.fetchUrlsAndTheirStatuses(caseId);
        List<Map<String, String>> listOfMapsOfUrls = (List<Map<String, String>>) mapOfDataAndStatus.get('list');
        System.assertEquals(true, listOfMapsOfUrls.size() > 0, 'No urls are found in the input txt');
        System.assertEquals(true, mapOfDataAndStatus.get('status'), 'File does not contains malicious urls');
        System.assertEquals(true, mapOfDataAndStatus.get('connectedToIPQ'), 'Failure of connection');
        
        Test.stopTest();
    }
    
    @isTest
    public static void testScanUrlInFileFailure() {
        // HTTP Mocks
        Test.setMock(HttpCalloutMock.class, new IpQualityScoreMockFailure());
        
        // Setup mock data
        String caseId = testSetup(BODY_WITH_URLS);
        
        Test.startTest();
        
        Map<String, Object> mapOfDataAndStatus = UrlScannerController.fetchUrlsAndTheirStatuses(caseId);
        List<Map<String, String>> listOfMapsOfUrls = (List<Map<String, String>>) mapOfDataAndStatus.get('list');
        System.assertEquals(false, mapOfDataAndStatus.get('connectedToIPQ'), 'Successful connection');
        
        Test.stopTest();
    }

}