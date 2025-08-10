public with sharing class UrlScannerDatabaseController {
    
    // SOQL get case number by Id
    public static List<Case> getCaseNumberById(String caseId) {
        List<Case> cases = new List<Case>();
        // Check if the user has read rights of Case
        if(Schema.sObjectType.Case.isAccessible() && caseId != null && String.isNotEmpty(caseId)) {
            cases = [SELECT CaseNumber FROM Case WHERE Id =: caseId WITH USER_MODE];
        }        
        return cases;
    }
    
    // SOQL query to get the ContentDocumentId of ContentDocumentLink by the Case Id
    public static List<ContentDocumentLink> getContentDocumentLinkByCaseId(String caseId) {
        List<ContentDocumentLink> contentDocumentLinksByCaseId = new List<ContentDocumentLink>();
        // Check if the user has read rights of ContentDocumentLink
        if(Schema.sObjectType.ContentDocumentLink.isAccessible() && caseId != null && String.isNotEmpty(caseId)) {
            // Only the latest created document to be fetched, hence order by and limit 1
            contentDocumentLinksByCaseId = [SELECT ContentDocumentId, ContentDocument.CreatedBy.Email, ContentDocument.Title, ContentDocument.CreatedBy.LastName 
                                            FROM ContentDocumentLink 
                                            WHERE LinkedEntityId =: caseId
                                            WITH USER_MODE
                                            ORDER BY ContentDocument.CreatedDate DESC 
                                            LIMIT 1];
        }        
        return contentDocumentLinksByCaseId;
    }

    // SOQL query to get the VersionData of ContentVersion by the contentDocumentId or its ID
    public static List<ContentVersion> getContentVersionsByContentDocumentLink(String contentDocumentId, String contentVersionId) {
        List<ContentVersion> contentDocumentVersions = new List<ContentVersion>();
        // Check if the user has read rights of ContentVersion
        if(Schema.sObjectType.ContentVersion.isAccessible()) {
            // fetch only the latest version of a ContentVersion
            if(contentDocumentId != null && String.isNotEmpty(contentDocumentId)) {
                contentDocumentVersions = [SELECT Id, ContentDocumentId, VersionData FROM ContentVersion WHERE ContentDocumentId =: contentDocumentId AND IsLatest = true WITH USER_MODE];
            }
            else if(contentVersionId != null && String.isNotEmpty(contentVersionId)) {
                contentDocumentVersions = [SELECT Id, ContentDocumentId, VersionData FROM ContentVersion WHERE Id =: contentVersionId AND IsLatest = true WITH USER_MODE];
            }
        }
        return contentDocumentVersions;
    }
    
    // SOQL query to get the api key from the custom setting IPQualityScore__c
    public static List<IPQualityScore__c> getIPQualityScore() {
        List<IPQualityScore__c> ipQualityScores = new List<IPQualityScore__c>();
        // Check if the user has read rights of IPQualityScore__c
        if(Schema.sObjectType.IPQualityScore__c.isAccessible()) {
            // Get only the first key
            ipQualityScores = [SELECT Id, API_Key__c FROM IPQualityScore__c WITH USER_MODE ORDER BY CreatedDate DESC LIMIT 1];
        }
        return ipQualityScores;
    }
    
    // future callout delete to run in a separate thread to leave time for datatable to display info before the file gets deleted
    @future(Callout=true)
    public static void deleteMaliciousFile(String caseId) {
        if(Schema.sObjectType.ContentDocumentLink.isDeletable()) {
            Boolean allOrNothing = false;
            Database.delete(getContentDocumentLinkByCaseId(caseId), allOrNothing, AccessLevel.USER_MODE);
        }
    }
}