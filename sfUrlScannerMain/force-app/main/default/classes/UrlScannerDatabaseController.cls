public class UrlScannerDatabaseController {
    // SOQL query to get the ContentDocumentId of ContentDocumentLink by the Case Id
    public static List<ContentDocumentLink> getContentDocumentLinkByCaseId(String caseId) {
        List<ContentDocumentLink> contentDocumentLinksByCaseId = new List<ContentDocumentLink>();
        // Check if the user has read rights of ContentDocumentLink
        if(Schema.sObjectType.ContentDocumentLink.isAccessible() && caseId != null && String.isNotEmpty(caseId)) {
            contentDocumentLinksByCaseId = [SELECT ContentDocumentId FROM ContentDocumentLink 
                                            WHERE LinkedEntityId =: caseId ORDER BY ContentDocument.CreatedDate DESC];
        }        
        return contentDocumentLinksByCaseId;
    }

    // SOQL query to get the VersionData of ContentVersion by the contentDocumentId or its ID
    public static List<ContentVersion> getContentVersionsByContentDocumentLink(String contentDocumentId, String contentVersionId) {
        List<ContentVersion> contentDocumentVersions = new List<ContentVersion>();
        // Check if the user has read rights of ContentVersion
        if(Schema.sObjectType.ContentVersion.isAccessible()) {
            if(contentDocumentId != null && String.isNotEmpty(contentDocumentId)) {
                contentDocumentVersions = [SELECT Id, ContentDocumentId, VersionData FROM ContentVersion WHERE ContentDocumentId =: contentDocumentId AND IsLatest = true];
            }
            else if(contentVersionId != null && String.isNotEmpty(contentVersionId)) {
                contentDocumentVersions = [SELECT Id, ContentDocumentId, VersionData 
                                           FROM ContentVersion 
                                           WHERE Id =: contentVersionId AND IsLatest = true 
                                          ];
            }
        }
        return contentDocumentVersions;
    }
}