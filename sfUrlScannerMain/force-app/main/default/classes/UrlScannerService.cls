public with sharing class UrlScannerService {

    private static final String HTTPS = 'https://';
    private static final String HTTP = 'http://';
    // max size and/or number of characters allowed in one uploaded file
    private static final Integer CHARACTERS_THRESHOLD = 100000;
    // max size of allowed number of urls in one uploaded file
    private static final Integer URL_MAX_SIZE = 90;

    // to be compared in fileContent, if it equals this static final String it means we hit the exception Regex too complicated
    @TestVisible
    private static final String FILE_CONTAINS_MORE_THAN_THRESHOLD_CHARACTERS = 'File contains a string that is longer than ' + CHARACTERS_THRESHOLD + ' characters';
    
    // Input : Case ID
    // Result : a map of 4 keys
    // * list : a list of maps that has 2 keys, url and status, that return the url fetched and the safety health status of it (respectively)
    // * connectedToIPQ : true if the connection to IP Quality service is established, false if not
    // * status : true if the file contains a maliciousUrl, false if not
    // * moreThanThresholdChars : true if the file exceeds the CHARACTERS_THRESHOLD, false if not
    public Map<String, Object> scanUrlsInFile(String caseId) {
        Boolean maliciousFile = false; 
        Boolean connectedToIPQ = false;
        Boolean moreThanThresholdChars = false;
        Map<String, Object> mapOfDataAndFileStatus = new Map<String, Object>();
        List<Map<String, String>> listOfMapsOfUrls = new List<Map<String, String>>();
        List<IPQualityScore__c> ipQualityScores = UrlScannerDatabaseController.getIPQualityScore();
        
        // Get IP Quality API Key to be used in EP
        String ipQualityScoreApiKey = ipQualityScores != null && ipQualityScores.size() > 0 && ipQualityScores[0].API_Key__c != null ? ipQualityScores[0].API_Key__c : '';
      	
        // Fetch the urls from the input file inserted by the user in the Case
        String bodyText = getFileContentAsString(caseId);
        // If the body text is FILE_CONTAINS_MORE_THAN_THRESHOLD_CHARACTERS, it means we would've hit the regex too complicated exception and the code won't proceed with that method
        if(bodyText != null && String.isNotEmpty(bodyText) && bodyText.equalsIgnoreCase(FILE_CONTAINS_MORE_THAN_THRESHOLD_CHARACTERS)) {
            moreThanThresholdChars = true;
        }
        // If the body was parsed okay
        else if(bodyText != null && String.isNotEmpty(bodyText) && !bodyText.equalsIgnoreCase(FILE_CONTAINS_MORE_THAN_THRESHOLD_CHARACTERS)) {
            // Get list of urls in one body Text
            List<String> urls = getUrlsInString(bodyText);
        
            // Get url size to keep it under URL_MAX_SIZE to avoid 101 too many callouts exception
            Integer urlSize = urls.size();
            // Loop throught the urls and put them in a map where the key is 'url', this will be needed to populate data in the lightning aura datatable
            for(String oneUrl : urls) {
                // a map where the keys are the state and status and the results are whether the api call was made succesfully and the safety of the url (respectively)
                Map<String, Object> mapOfScannedUrlsWithStatus = urlSize <= URL_MAX_SIZE ? UrlScannerApiHandler.scanUrlWithIpQuality(oneUrl, ipQualityScoreApiKey) : new Map<String, Object>();
                // successApiCall is 200 if the call is succesful and there's a response to the API call 
                Integer successApiCall = mapOfScannedUrlsWithStatus != null && mapOfScannedUrlsWithStatus.get('response_status') != null ? (Integer) mapOfScannedUrlsWithStatus.get('response_status') : 400;
                // to track the safety health of one URL
                Boolean isMalicious = false;
                String urlSafety = '';
                
                // Init list of maps for datatable
                Map<String, String> mapOfUrls = new Map<String, String>();
                // Get if the url is malicious only when the api call is successful
                if(successApiCall == 200) {
                    isMalicious = mapOfScannedUrlsWithStatus != null && mapOfScannedUrlsWithStatus.get('state') != null ? (Boolean) mapOfScannedUrlsWithStatus.get('state') : false;
                    urlSafety = isMalicious ? 'Malicious URL' : 'Safe URL';
                    // set connectedToIPQ meaning that the connection was succesful
                    connectedToIPQ = true;
                }
            
                // Populate the list with map with two keys, once is the url and the other is the status of the url (safe or not)
                mapOfUrls.put('url', oneUrl);
                mapOfUrls.put('status', urlSafety);
                listOfMapsOfUrls.add(mapOfUrls);
                
                // Only update maliciousFile boolean to be true if it was false in previoius iteration, if it becomes true, then keep it as it since that means that a malicious url has been detected
                if(!maliciousFile) {
                    maliciousFile = isMalicious;
                }
            }
        
            // If a malicious url has been detected, delete the file and fire an email to the user who uploaded it
            if(maliciousFile) {
                takeActionsWhenMaliciousFileFound(caseId);
            }
        }
      	
        // Populate final map with 3 keys, list contains the urls, connectedToIPQ to check if the API call was made, status to check if there's at least one malicious URL
        mapOfDataAndFileStatus.put('list', listOfMapsOfUrls);
        mapOfDataAndFileStatus.put('connectedToIPQ', connectedToIPQ);
        mapOfDataAndFileStatus.put('status', maliciousFile);
        mapOfDataAndFileStatus.put('moreThanThresholdChars', moreThanThresholdChars);
        
        return mapOfDataAndFileStatus;
    }
    
    // send email notifications to the emailDestination
    private void fireEmailNotification(String emailDestination, String subject, String body) {
        List<Messaging.SingleEmailMessage> mailList = new List<Messaging.SingleEmailMessage>();
        
        Messaging.SingleEmailMessage mail =  new Messaging.SingleEmailMessage();
   
        List<String> sendTo = new List<String>();
        sendTo.add(emailDestination);
        mail.setToAddresses(sendTo);
        mail.setSubject(subject);
        mail.setHtmlBody(body);
   
        mailList.add(mail);
        
        Messaging.sendEmail(mailList);
    }
    
    private void takeActionsWhenMaliciousFileFound(String caseId) {
        // Fire email to notify the user about the deleted file
        List<Case> cases = UrlScannerDatabaseController.getCaseNumberById(caseId);
        List<ContentDocumentLink> contentDocLinks = UrlScannerDatabaseController.getContentDocumentLinkByCaseId(caseId);

        // check that there's a case and a doc, then send the email
        if(cases != null && cases.size() > 0 && contentDocLinks != null && contentDocLinks.size() > 0) {
            String instanceUrl = URL.getSalesforceBaseUrl().toExternalForm();
            String subject = 'File attached to the case ' + cases[0].CaseNumber + ' will be deleted';
            String emailDestination = contentDocLinks[0].ContentDocument.CreatedBy.email;
            String body = 'Dear ' + contentDocLinks[0].ContentDocument.CreatedBy.LastName + ',<br/><br/>';
            body += 'The file titled ' + contentDocLinks[0].ContentDocument.Title + ' that you have attempted to attach to the case '; 
            body += '<a href="'+ instanceUrl +  '/' + caseId + '">' + cases[0].CaseNumber + '</a> has been deleted because it contains malicious URLs.<br/>';
            body += 'Please review the file and reupload it without the malicious urls, and do not click on any of them.<br/><br/>';
            body += 'Best regards';
            fireEmailNotification(emailDestination, subject, body);
        }
        	
        // Delete the record in a future callout (separate thread)
        UrlScannerDatabaseController.deleteMaliciousFile(caseId);
    }

    // Get all URLS in one file body text
    private static List<String> getUrlsInString(String fileContent) {
        // Regex to detect urls
        String regexUrl =  '(?:(?:(?:[a-z0-9]{3,9}:(?://)?)(?:[-;:&=+$,w]+@)?[a-z0-9.-]+|(?:www.|[-;:&=+$??,w]+@)[a-z0-9.-]+)((?:/[+~%/.w-]*)?\\??(?:[-+=&;%@.w]*)#?w*)?)';

        // Create pattern and matcher to fetch urls from the input string
        Pattern myPattern = Pattern.compile(regexUrl);
        Matcher myMatcher = MyPattern.matcher(fileContent);
        List<String> urls = new List<String>();

        // try catch to avoid LOB or regex too complicated exceptions
        try {
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
        }
        catch(Exception e) {
            System.debug('EXCEPTION IN :' + e.getStackTraceString() + ' -- reason :' + e.getMessage());
        }
        
        return urls;
    }
    
    // Fetch both ContentDocumentLink and ContentVersion to get encoded then decoded versionData of the latest upload file version
    private static String getFileContentAsString(String caseId) {
        // SF doesn't allow semi-join query for ContentVersion and ContentDocumentLink, that's why we need two SOQL queries to get the end result which is VersionData
        String fileContent = '';
        // Fetch the ContentDocumentLink First to get the ContentDocumentId
        List<ContentDocumentLink> contentDocumentLinksOfCase = UrlScannerDatabaseController.getContentDocumentLinkByCaseId(caseId);
        List<ContentVersion> contentDocumentVersionsOfCase = new List<ContentVersion>();
        if(contentDocumentLinksOfCase != null && contentDocumentLinksOfCase.size() > 0) {
            // Get the ContentVersion second with the ContentDocumentId of the list contentDocumentLinksOfCase
            contentDocumentVersionsOfCase = UrlScannerDatabaseController.getContentVersionsByContentDocumentLink(contentDocumentLinksOfCase[0].ContentDocumentId, '');
            for(ContentVersion oneCV : contentDocumentVersionsOfCase) {
                Blob versionData = oneCV.VersionData;
                if(versionData != null && versionData.size() < CHARACTERS_THRESHOLD) {
                    // Encode first to base64, then decode to base64 to get the content of the txt file
                    fileContent = EncodingUtil.base64Decode(EncodingUtil.base64Encode(versionData)).toString();
                    
                }
                // if the size exceeds the threshold, then return FILE_CONTAINS_MORE_THAN_THRESHOLD_CHARACTERS to be used in a later logic
                else {
                    fileContent = FILE_CONTAINS_MORE_THAN_THRESHOLD_CHARACTERS;
                }
            }
        }
        
        return fileContent;
    }
}