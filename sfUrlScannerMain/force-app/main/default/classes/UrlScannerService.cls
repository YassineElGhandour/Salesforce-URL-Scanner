public class UrlScannerService {
    private static final String HTTPS = 'https://';
    private static final String HTTP = 'http://';
    
    public static List<String> getUrlsInString(String fileContent) {
        // Regex to detect urls
        String regexUrl =  '(?:(?:(?:[a-z0-9]{3,9}:(?://)?)(?:[-;:&=+$,w]+@)?[a-z0-9.-]+|(?:www.|[-;:&=+$??,w]+@)[a-z0-9.-]+)((?:/[+~%/.w-]*)?\\??(?:[-+=&;%@.w]*)#?w*)?)';

        // Create pattern and matcher to fetch urls from the input string
        Pattern myPattern = Pattern.compile(regexUrl);
        Matcher myMatcher = MyPattern.matcher(fileContent);
        List<String> urls = new List<String>();

        while (myMatcher.find()) { 
            String initialUrl = myMatcher.group();
            if(initialUrl != null && String.isNotEmpty(initialUrl)) {
            	// check that the url contains the prefix http or https
            	// if yes, add it to the list
                if(initialUrl.startsWith(HTTPS) || initialUrl.startsWith(HTTP)) {
                    urls.add(initialUrl);
                }
                // if not, add HTTP as a prefix
                else {
                    urls.add(HTTP + initialUrl);
                }
            }
        }
        return urls;
    }
    
    public static String getFileContentAsString(String caseId) {
        // SF doesn't allow semi-join query for ContentVersion and ContentDocumentLink, that's why we need two SOQL queries to get the end result which is VersionData
        String fileContent = '';
        // Fetch the ContentDocumentLink First to get the ContentDocumentId
        List<ContentDocumentLink> contentDocumentLinksOfCase = UrlScannerDatabaseController.getContentDocumentLinkByCaseId(caseId);
        List<ContentVersion> contentDocumentVersionsOfCase = new List<ContentVersion>();
        if(contentDocumentLinksOfCase != null && contentDocumentLinksOfCase.size() > 0) {
            // Get the ContentVersion second witht the ContentDocumentId of the list contentDocumentLinksOfCase
            contentDocumentVersionsOfCase = UrlScannerDatabaseController.getContentVersionsByContentDocumentLink(contentDocumentLinksOfCase[0].ContentDocumentId, '');
            for(ContentVersion oneCV : contentDocumentVersionsOfCase) {
                Blob versionData = oneCV.VersionData;
                if(versionData != null) {
                    // Encode first to base64, then decode to base64 to get the content of the txt file
                    fileContent = EncodingUtil.base64Decode(EncodingUtil.base64Encode(versionData)).toString();
                }
            }
        }
        
        return fileContent;
    }

}