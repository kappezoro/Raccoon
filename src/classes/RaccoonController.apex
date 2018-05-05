/**
 * Raccoon's Controller class
 */
public class RaccoonController {

    private static String OAUTH_URL     = 'https://api.einstein.ai/v2/oauth2/token';
    private static String OAUTH_EMAIL   = 'colorful.circle.42@gmail.com';    
    private static String SENTIMENT_URL = 'https://api.einstein.ai/v2/language/sentiment';
    private static String INTENT_URL    = 'https://api.einstein.ai/v2/language/intent';
    private static String TRAIN_URL     = '';
    private static String INTENT_MODEL_ID = 'NZBPJNYCSMSYSBIBQHPYLJ7UGU';
    private static String SENTIMENT_MODEL_ID = 'CommunitySentiment';

    @RemoteAction
    public static JobApplicant__c updateInterview(String applicantId, String interviewTextArea){
        try{
            JobApplicant__c jobApplicant = new JobApplicant__c();
            jobApplicant.Id = applicantId;
            jobApplicant.interview__c = interviewTextArea;
            jobApplicant.sentiment__c = callEinsteinLanguage(interviewTextArea, SENTIMENT_MODEL_ID, SENTIMENT_URL);
            String intentJson = callEinsteinLanguage(interviewTextArea, INTENT_MODEL_ID, INTENT_URL);
            parseIntentJson(intentJson, jobApplicant);
            System.debug('update');
            update jobApplicant;
            return jobApplicant;
        }catch(Exception e){
            System.debug(e);
            return null;
        }
    }

    /**
     * text-intent call to put data to ESP
     */    
    @TestVisible
    private static JobApplicant__c parseIntentJson(String intentJson, JobApplicant__c jobApplicant){
        JSONParser parser = JSON.createParser(intentJson);
        while (parser.nextToken() != null) {
            if(parser.getText() == 'Career'){
                parser.nextToken();
                parser.nextToken();
                jobApplicant.IntentCareer__c = parser.getDoubleValue();
            }else if(parser.getText() == 'Place'){
                parser.nextToken();
                parser.nextToken();
                jobApplicant.IntentPlace__c = parser.getDoubleValue();                
            }else if(parser.getText() == 'Relationship'){
                parser.nextToken();
                parser.nextToken();
                jobApplicant.IntentRelationship__c = parser.getDoubleValue();
            }else if(parser.getText() == 'Worktime'){
                parser.nextToken();
                parser.nextToken();
                jobApplicant.IntentWorkTime__c = parser.getDoubleValue();
            }else if(parser.getText() == 'Salary'){
                parser.nextToken();
                parser.nextToken();
                jobApplicant.IntentSalary__c = parser.getDoubleValue();                
            }
        }
        System.debug(jobApplicant);
        return jobApplicant;
    }
    
    /**
     * text-sentiment call to get result data from ESP  
     */
    public static String callEinsteinLanguage(String interviewTextArea, String modelId, String url){
        if(String.isBlank(interviewTextArea)){
            return '';
        }
        String target = interviewTextArea.replaceAll( '[\\r\\n]+', ' ' );
        String body = '{\"modelId\":\"' + modelId + '\",\"document\":\"' + target + '\"}';
        System.debug(body);
        HttpResponse res = call(url, 'POST', body);
        System.debug(res.getBody());
        return res.getBody();
        
    }

    /**
     *  call Einstein API 
     */
    public static HttpResponse call(String url, String method, String body){
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint(url);
        //common
        req.setHeader('Authorization', 'Bearer '+ getAccessToken());
        req.setHeader('Cache-Control', 'no-cache');
        //by url
        req.setHeader('Content-Type', 'application/json');
        req.setMethod(method);
        req.setBody(body);
        System.debug('sendRequest');
        System.debug(req);
        return h.send(req);
    }
          
    private static String getAccessToken() {
        // Ignore the File upload part and "jwt.pkcs" if you used a Salesforce certificate to sign up 
        // for an Einstein Platform account
        ContentVersion base64Content = [SELECT Title, VersionData FROM ContentVersion where Title='einstein_platform' OR  Title='predictive_services' ORDER BY Title LIMIT 1];
        String keyContents = base64Content.VersionData.tostring();
        keyContents = keyContents.replace('-----BEGIN RSA PRIVATE KEY-----', '');
        keyContents = keyContents.replace('-----END RSA PRIVATE KEY-----', '');
        keyContents = keyContents.replace('\n', '');

        // Get a new token
        JWT jwt = new JWT('RS256');
        jwt.pkcs8 = keyContents; // Comment this if you are using jwt.cert
        jwt.iss = 'developer.force.com';
        jwt.sub = OAUTH_EMAIL;
        jwt.aud = OAUTH_URL;
        jwt.exp = '1700';
        return JWTBearerFlow.getAccessToken(OAUTH_URL, jwt);    
    }
}