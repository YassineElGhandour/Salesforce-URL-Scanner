public class UrlScannerApiHandler {
    
	// endpoint for URL reports
	private static final String IP_QUALITY_SCORE_EP = 'https://ipqualityscore.com/api/json/url';
    private static final Integer IPQ_THRESHOLD = 10;

	public static Map<String, Object> scanUrlWithIpQuality(String url, String ipQualityScoreApiKey) {
        Boolean state = false;
        Integer responseStatus = 400;
        Map<String, Object> mapOfStatusAndState = new Map<String, Object>();
		String urlEncoded = EncodingUtil.urlEncode(url, 'UTF-8');

        // create the get request
        String endPoint = IP_QUALITY_SCORE_EP + '?key=' + ipQualityScoreApiKey + '&url='  + urlEncoded;
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(endPoint);
        request.setMethod('GET');
        HttpResponse response;
        
        try {
            response = http.send(request);
            if(response.getStatusCode() == 200) {
                Map<String,Object> urlResult = new Map<String,Object>();
                urlResult = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());

                if(urlResult != null && urlResult.get('risk_score') != null) {
                    responseStatus = 200;
                    Integer riskScoreCounter = (Integer) urlResult.get('risk_score');
                    if(riskScoreCounter > IPQ_THRESHOLD) {
                        state = true;
                    }
                }
            }
            else {
                System.debug('Status not OK : ' + responseStatus);
            }
            
            // Populate map
            mapOfStatusAndState.put('state', state);
        }
        catch (Exception e) {
            System.debug('EXCEPTION IN UrlScannerApiHandler : ' + e.getStackTraceString() + ' -- ' + e.getMessage());
        }
        mapOfStatusAndState.put('response_status', responseStatus);
        return mapOfStatusAndState;
	}
}