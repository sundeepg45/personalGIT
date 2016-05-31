public without sharing class PartnerCertValidationScraper {
    private static final String affirmative = ' is a valid cert';
    private static final String negative = ' is not a valid cert';
    public String certId {get; set;}
    public String originalPage {get; set;}
    public String pageOutput {get; set; }


    public PartnerCertValidationScraper() {
        originalPage = '';
    }
    
    public void doExecute() {
        certId = ApexPages.currentPage().getParameters().get('certId');
        if (isValidCertificationId(certId)) {
            pageOutput = 'Valid';
        }
        else {
            pageOutput = 'Invalid';
        }
    }
    
    public Boolean isValidCertificationId(String certId) {
  PartnerTraining__c cert = null;      
        try {
          cert = [select Id, CertificateNumber__c, IsValid__c, RedHatValidated__c from PartnerTraining__c where Id = :certId];
          if (cert == null) {
              return False;
          }
          if (cert.RedHatValidated__c) {
              return cert.IsValid__c;
          }
        }
        catch (System.QueryException ex) {
            return False;
        }
        Http agent = new Http();
        HttpRequest request = new HttpRequest();
        request.setMethod('GET');
        String url = 'https://www.redhat.com/wapps/training/certification/verify.html';
        String params = '?certNumber=' + cert.CertificateNumber__c+'&verify=Verify&isSearch=False';
        request.setEndpoint(url + params);
        request.setHeader('Host', 'www.redhat.com');
        request.setHeader('Accept', 'text/html');
        request.setHeader('User-Agent', 'Mozilla/5.0 Firefox/3.6.13');
        request.setHeader('Accept-Charset', 'ISO-8859-1,utf-8');
        request.setHeader('Accept-Language', 'en-us,en;q=0.5');
        request.setHeader('Referer', url);
        request.setHeader('Cache-Control', 'no-cache, no-store');
        HttpResponse rsp = agent.send(request);
        String body = rsp.getBody();

        // uncomment for debugging
        //originalPage = body;

        //
        // check affirmative AND negative to make sure the page hasn't changed.
        //
        if (body != null) {
            if (body.indexOf(affirmative) != -1) {
                cert.RedHatValidated__c = true;
                cert.IsValid__c = true;
                update cert;
                return true;
            }
            if (body.indexOf(negative) != -1) {
                cert.RedHatValidated__c = true;
                cert.IsValid__c = false;
                update cert;
                return false;
            }
            // oops, page didn't load, was changed, or something went wrong
            System.debug('ERROR: certificate validation page did not return expected results: ' + rsp.getStatus());
            System.debug('ERROR: code=' + rsp.getStatusCode());
//          List<String> keys = rsp.getHeaderKeys();
//          for (String key : keys) {
//              if (key != null) System.debug('HEADER: ' + key + '=' + rsp.getHeader(key));
//          }
        }
        return false;       
    }
}