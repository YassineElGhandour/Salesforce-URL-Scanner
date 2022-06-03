public class UrlScannerController {
    
    @AuraEnabled
    public static List<Map<String, String>> scanUrlsInFile(String caseId) {
        List<Map<String, String>> listOfMapsOfUrls = new List<Map<String, String>>();
        // Fetch the urls from the input file inserted by the user in the Case
        List<String> urls = UrlScannerService.getUrlsInString(UrlScannerService.getFileContentAsString(caseId));
        // loop throught the urls and put them in a map where the key is 'url', this will be needed to populate data in the lightning aura datatable
        for(String oneUrl : urls) {
            Boolean isMallicious = UrlScannerApiHandler.scanUrlWithIpQuality(oneUrl);
            Map<String, String> mapOfUrls = new Map<String, String>();
            mapOfUrls.put('url', oneUrl);
            mapOfUrls.put('status', isMallicious ? 'Mallicious URL' : 'Safe URL');
            listOfMapsOfUrls.add(mapOfUrls);
        }
        
        return listOfMapsOfUrls;
    }

}