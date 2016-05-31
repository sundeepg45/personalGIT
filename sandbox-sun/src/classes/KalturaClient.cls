public class KalturaClient {
    private String user;
    private String partnerId;
    private String session;
    private String secret;
    private String endpoint = 'http://www.kaltura.com/api_v3/?';
    

    public KalturaClient(String theUser, String thePartnerId, String theSecret) {
        user = theUser;
        partnerId = thePartnerId;
        secret = theSecret;
        login();
    }
    
    private void login() {
        Map<String,String> params = new Map<String,String> {
            'service'      => 'session',
            'action'       => 'start',
            'secret'       => secret,
            'type'         => '2',      // 2=ADMIN, 0=USER
            'userId'       => user,
            'partnerId'    => partnerId
        };
        HttpResponse rsp = submitRequest(endpoint, params);
        Dom.Document doc = rsp.getBodyDocument();
        Dom.XmlNode result = doc.getRootElement().getChildElement('result', null);
        if (result != null) {
            session = result.getText();
        }
    }
    
    public KalturaMediaEntry[] listMedia(Map<String,String> userParams) {
    	KalturaMediaEntry[] media = new List<KalturaMediaEntry>();
        Map<String,String> stdParams = new Map<String,String> {
            'service'      => 'media',
            'action'       => 'list',
            'ks'           => session,
            'partnerId'    => partnerId
        };
        Map<String,String> allParams = stdParams.clone();
        allParams.putAll(userParams);
        HttpResponse rsp = submitRequest(endpoint, allParams);
        Dom.Document doc = rsp.getBodyDocument();
        Dom.XmlNode resultNode = doc.getRootElement().getChildElement('result', null);
        System.debug('[DEBUG]------- result=' + doc.toXmlString());
        if (resultNode != null) {
            Dom.XmlNode objectsNode = resultNode.getChildElement('objects', null);
            Dom.XmlNode[] items = objectsNode.getChildElements();
            for (Dom.XmlNode item : items) {
                media.add(new KalturaMediaEntry(item));
            }
        }
        return media;
    }
    
    public String[] listCategories() {
        Map<String,String> stdParams = new Map<String,String> {
            'service'      => 'category',
            'action'       => 'list',
            'ks'           => session,
            'filter:orderBy'    => 'name'
        };
        String[] categoryList = new List<String>();
        HttpResponse rsp = submitRequest(endpoint, stdParams);
        Dom.Document doc = rsp.getBodyDocument();
        Dom.XmlNode resultNode = doc.getRootElement().getChildElement('result', null);
        System.debug('[DEBUG]------- result=' + doc.toXmlString());
        if (resultNode != null) {
            Dom.XmlNode objectsNode = resultNode.getChildElement('objects', null);
            Dom.XmlNode[] items = objectsNode.getChildElements();
            for (Dom.XmlNode item : items) {
            	categoryList.add(item.getChildElement('name', null).getText());
            }
        }
        return categoryList;
    }

    private String map2uri(Map<String,String> params) {
        String buf = '';
        for (String key : params.keySet()) {
            String val = params.get(key);
            buf = buf + '&' + key + '=' + EncodingUtil.urlEncode(val, 'UTF-8');
        }
        return buf.substring(1);
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
    
}