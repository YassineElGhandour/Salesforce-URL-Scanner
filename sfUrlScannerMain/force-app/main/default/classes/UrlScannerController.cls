public class UrlScannerController {
    
    @AuraEnabled
    public static Map<String, Object> fetchUrlsAndTheirStatuses(String caseId) {
        UrlScannerService urlScannerService = new UrlScannerService();
        return urlScannerService.scanUrlsInFile(caseId);
    }
}