public without sharing class rallyConnectorController {
    public JSONResponse jrsp {get; set; }
    public Case theCase {get; set; }

    public class JSONResponse {
        public String status {get; set;}
        public String error {get; set;}
        public String project {get; set;}
        public String owner {get; set; }
    }

    public rallyConnectorController(ApexPages.StandardController controller) {
        theCase = (Case) controller.getRecord();
        System.debug('*** [debug] *** caseid=' + theCase.Id);
    }

    public PageReference backToCasePage() {
        System.debug('*** [debug] *** redirecting to /' + theCase.Id);
        PageReference ref = new PageReference('/' + theCase.Id);
        return ref;
    }

    public PageReference createStory() {
        if (theCase == null) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Attempting to use this functionality incorrectly'));
            return null;
        }

        Rally_User__c[] ru = [select Id from Rally_User__c where OwnerId = :UserInfo.getUserId()];
        if (ru.isEmpty()) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'You are not authorized to submit cases to Rally'));
            return null;
        }

        theCase = [select Id, IT_User_Story__c from Case where Id = :theCase.Id];
        if (theCase.IT_User_Story__c != null && theCase.IT_User_Story__c.length() > 0) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Story already associated to this case'));
            return null;
        }

        Map<String,String> params = new Map<String,String>();
        params.put('caseid', theCase.id);
        params.put('userid', UserInfo.getUserId());
        params.put('context', 'prod');
        Configuration__c[] configs = [select Value__c from Configuration__c where Name = 'rallyconnectorUrl'];
        if (configs.size() == 0) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Rally connector configuration missing'));
            return null;
        }
        HttpResponse rsp = submitRequest(configs[0].Value__c + '/create?', params);
        System.debug('****[debug]**** response body=' + rsp.getBody());
        String body = rsp.getBody();
        if (body == null || body.length() < 10 || body.startsWith('<!DOCTYPE')) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Rally communication problem - try again and report problem'));
            return null;
        }
        jrsp = (JSONResponse) JSON.deserialize(body, JSONResponse.class);
        return null;
    }

    private HttpResponse submitRequest(String endpoint, Map<String,String> params) {
        Http client = new Http();
        HttpRequest request = new HttpRequest();
        request.setTimeout(20000);
        request.setMethod('GET');
        request.setEndpoint(endpoint + map2uri(params));
        System.debug('request endpoint is ' + request.getEndpoint());
        return client.send(request);
    }

    private String map2uri(Map<String,String> params) {
        String buf = '';
        for (String key : params.keySet()) {
            String val = params.get(key);
            buf = buf + '&' + key + '=' + EncodingUtil.urlEncode(val, 'UTF-8');
        }
        return buf.substring(1);
    }

}