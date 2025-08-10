public with sharing class UrlScannerController {
    
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> fetchUrlsAndTheirStatuses(String caseId) {
        UrlScannerService urlScannerService = new UrlScannerService();
        return urlScannerService.scanUrlsInFile(caseId);
    }
}