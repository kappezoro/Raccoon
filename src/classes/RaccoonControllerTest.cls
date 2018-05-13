@isTest
private class RaccoonControllerTest {
    
    private static String testJsonIntent = '{\"probabilities\":[{\"label\":\"Career\",\"probability\":0.72495943},{\"label\":\"Place\",\"probability\":0.55555}],\"object\":\"predictresponse\"}';
    
    /**
     * create test data
     * @return Job Applicant Id 
     */
    private static Id getTestApplicantId(){
        JobApplicant__c target = new JobApplicant__c();
        target.Name = 'testUser';
        target.Prefecture__c = 'Chiba';
        insert target;
        Id id = [SELECT Id FROM JobApplicant__c WHERE Name = 'testUser' LIMIT 1].Id;
        return id;
    }

    /**
     * test for putIntent method
     */
    @isTest
    private static void TestputIntent(){
        Id id = getTestApplicantId();
        JobApplicant__c target = new JobApplicant__c();
        target.Id = id;        
            
        JobApplicant__c jobApplicant = RaccoonController.parseIntentJson(testJsonIntent, target);
        
        // put each value to correct field by testJsonData
        System.assertEquals(0.72495943, jobApplicant.IntentCareer__c);
        
        //irregular case. normally always come all label probability.
        System.assertEquals(null, jobApplicant.IntentRelationship__c);
    }

    
    
}