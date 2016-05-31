public without sharing class CDHTools {

    public ContactSearchResult searchContacts(String loginName) {
        ContactSearchResult results = new ContactSearchResult();
        if (loginName == null || loginName.length() < 2) {
            return results;
        }
        loginName = loginName.toUpperCase();
        SearchBeforeCreateURL__c sbcCustomsetting = SearchBeforeCreateURL__c.getValues('CDH Contact Search URL');
        String endpoint = sbcCustomsetting.Cdh_URL__c + 'login=' + EncodingUtil.urlEncode(loginName, 'UTF-8');
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('GET');
        req.setTimeOut(10000);
        Http http = new Http();
        HTTPResponse res = new HTTPResponse();
        boolean successResult = true;
        try {
            if (!Test.isRunningTest()) {
                res = http.send(req);
                System.debug('***** [debug] ***** response: ' + res);
            }
            else {
                res.setStatus('OK');
                String jsonBody = '{ \"Contacts\": {\"Contact\": {\"Status\": \"\",\"Phone\": \"\",\"Email\": \"\",\"LoginName\": \"\",\"IDs\": {\"ID\": [\"\",\"\"]},\"SalesAccountCDHPartyNumber\": \"\",\"Fax\": \"\",\"Salutation\": \"\", \"FirstName\": \"\",\"CDHPartyNumber\": 531412,\"SalesAccountId\": \"\",\"MobilePhone\": \"\",\"LastName\": \"\"}}}';
                res.setBody(jsonBody);
                res.setStatusCode(200);
            }
        } catch(System.CalloutException e) {
            throw e;
        }
        if (res.getStatus() == 'OK') {
            if (res.getBody() != null) {
                try {
                    JSONParser parser = JSON.createParser(res.getBody());
                } catch(Exception e) {
                    ApexPages.Message Message = new ApexPages.Message(ApexPages.Severity.ERROR,'Error suspected in CDH Data');  // set the exception message
                    ApexPages.addMessage(Message);
                    return null;
                }
                Map<String,Object> payload = (Map<String,Object>) JSON.deserializeUntyped(res.getBody());
                System.debug('***** [debug] ***** payload=');
                System.debug(payload);

                if (payload.get('Contacts') == null) {
                    if (payload.get('ORACLEMESSAGE') != null) {
                        Map<String,Object> oracleMessage = (Map<String,Object>) payload.get('ORACLEMESSAGE');
                        Map<String,Object> oracleMessagePayload = (Map<String,Object>) oracleMessage.get('PAYLOAD');
                        String err = (String) oracleMessagePayload.get('ERROR_MESSAGE');
                        ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, err);
                        System.debug('**** [debug] ***** Oracle error message: ' + err);
                        return null;
                    }
                }
                else {
                    Map<String,Object> contacts = (Map<String,Object>) payload.get('Contacts');
                    Map<String,Object> contact = (Map<String,Object>) contacts.get('Contact');
                    results.cdhPartyNumber = String.valueOf((Integer) contact.get('CDHPartyNumber'));
                    results.email = (String) contact.get('Email');
                    results.fax = (String) contact.get('Fax');
                    results.firstName = (String) contact.get('FirstName');
                    results.lastName = (String) contact.get('LastName');
                    results.loginName = (String) contact.get('LoginName');
                    results.mobilePhone = (String) contact.get('MobilePhone');
                    results.phone = (String) contact.get('Phone');
                    results.salesAcctPartyNumber = (String) contact.get('SalesAccountCDHPartyNumber');
                    results.salutation = (String) contact.get('Salutation');
                    Map<String,Object> ids = (Map<String,Object>) contact.get('IDs');
                    results.idList = new List<String>();
                    if (ids != null && ids.get('ID') != null) {
                        Object[] anyIds = (Object[]) ids.get('ID');
                        for (Object aId : anyIds) results.idList.add(String.valueOf(aId));
                    }
                    return results;
                }
            }
            else {
                ApexPages.Message Message = new ApexPages.Message(ApexPages.Severity.INFO,'No Data returned');
                ApexPages.addMessage(Message);
                return null;
            }

        } else if(res.getStatus() == 'Bad Request') {
            ApexPages.Message Message = new ApexPages.Message(ApexPages.Severity.ERROR,'Records could not be retrieved for the search criteria provided');  // set the exception message
            ApexPages.addMessage(Message);
        } else {
            ApexPages.Message Message = new ApexPages.Message(ApexPages.Severity.INFO,'CDH system is down, please try later.');  // set the exception message
            ApexPages.addMessage(Message);
            System.debug('Result status: ' + res.getStatus());
        }
        return null;
    }


     public SearchResult[] searchCDHParty(SearchParams params) {
        SearchResult[] searchResultList = new List<SearchResult>();

        String parmetersToBeSearched = '';
        if (params.country != null) {
            List<String> countryListSplit = params.country.split(',');
            params.country = countryListSplit[0];
        }
        if (!params.AliasFlag && params.AccName != null)
        {
           parmetersToBeSearched += params.AccName != '' ? '&partyName='+EncodingUtil.urlEncode(params.AccName.trim(), 'UTF-8') : '';

        }
        if (params.PartyNo != null)
        {
            parmetersToBeSearched += params.PartyNo != '' ? '&partyNumber='+EncodingUtil.urlEncode(params.PartyNo.trim(), 'UTF-8') : '';
        }
        if(params.DUNSNumber !=null)
        {
            parmetersToBeSearched += params.DUNSNumber != '' ? '&dunsNumber='+EncodingUtil.urlEncode(params.DUNSNumber.trim(), 'UTF-8') : '';
        }
        if (params.Street != null)
        {
            parmetersToBeSearched += params.Street != '' ? '&address1='+EncodingUtil.urlEncode(params.Street.trim(), 'UTF-8') : '';
        }
        if (params.city != null)
        {
            parmetersToBeSearched += params.city != '' ? '&city='+EncodingUtil.urlEncode(params.city.trim(), 'UTF-8') : '';
        }
        if (params.state != null )
        {
            parmetersToBeSearched += params.state != null ? '&state='+EncodingUtil.urlEncode(params.state.trim(), 'UTF-8') : '';
        }
        if (params.country != null)
        {
            parmetersToBeSearched += params.country != '--None--' ? '&country='+params.country.trim() : '';
        }
        if (params.postalcode != null)
        {
            parmetersToBeSearched += params.postalcode != '' ? '&postalCode='+EncodingUtil.urlEncode(params.postalcode.trim(), 'UTF-8') : '';
        }

        if (params.AliasFlag && params.AccName != null)
        {
            parmetersToBeSearched += params.AccName != '' ? '&knownAs='+EncodingUtil.urlEncode(params.AccName.trim(), 'UTF-8') : '';

        }

        parmetersToBeSearched = parmetersToBeSearched.substring(1, parmetersToBeSearched.length());
        System.debug('parmetersToBeSearched ----'+parmetersToBeSearched);
        SearchBeforeCreateURL__c sbcCustomsetting = SearchBeforeCreateURL__c.getValues('CDH URL');
        String sbcUrlString = sbcCustomsetting.Cdh_URL__c;

        String httpRequestString = sbcUrlString + parmetersToBeSearched;
        System.debug('--------URL------' + httpRequestString);

        HttpRequest req = new HttpRequest();
        req.setEndpoint(httpRequestString);
        req.setMethod('GET');

        //increase the time out to 120 seconds
        req.setTimeOut(120000);

        Http http = new Http();
        HTTPResponse res = new HTTPResponse();
        boolean successResult = true;

        try {
            if (!Test.isRunningTest()){
                res = http.send(req);
                System.Debug('==========> res ' + res);
            }
            else {
                res.setStatus('OK');
                String jsonBody='{\"ORACLEMESSAGE\":{\"PAYLOAD\":{\"HZ_PARTY\":{\"HZ_PARTY_ROW\":{\"ATTRIBUTE3\":\"\",\"ATTRIBUTE2\":\"\",\"PARTY_NAME\":\"Canopy Cloud Ltd\",\"ATTRIBUTE1\":\"\",\"PARTY_ID\":1230665,\"TAX_REFERENCE\":\"GB232327983\",\"PARTY_NUMBE\":1221437,\"STATUS\":\"Active\",\"ATTRIBUTE5\":\"\",\"DUNS_NUMBER\":\"\",\"ATTRIBUTE4\":\"\",\"CROSS_REFERENCE\":{\"CROSS_REFERENCE_ROW\":[{\"ORIG_SYSTEM\":\"EBS\",\"ORIG_SYSTEM_REFERENCE\":6261266},{\"ORIG_SYSTEM\":\"SFDC\",\"ORIG_SYSTEM_REFERENCE\":\"0016000000lBukAAAS_ICUST\"},{\"ORIG_SYSTEM\":\"WEB\",\"ORIG_SYSTEM_REFERENCE\":\"6868870_ICUST\"}]},\"HZ_PARTY_SITES\":{\"HZ_PARTY_SITES_ROW\":{\"PARTY_SITE_NUMBER\":324371,\"STATE\":\"\",\"COUNTRY\":\"GB\",\"STATUS\":\"Active\",\"ADDRESS4\":\"\",\"CROSS_REFERENCE\":\"\",\"ADDRESS2\":\"PO Box 14\",\"ADDRESS3\":\"\",\"COUNTY\":\"\",\"ADDRESS1\":\"Finance Management Services\",\"IDENTIFYING_ADDRESS_FLAG\":\"Y\",\"PROVINCE":\"\",\"CITY\":\"Crewe\",\"POSTAL_CODE\":\"CW2 6DR\"}},\"JGZZ_FISCAL_CODE\":\"\",\"HZ_CONTACT_POINT\":\"\",\"HZ_CLASSIFICATION\":\"\",\"MATCH_PERCENTAGE\":100,\"PARTY_TYPE\":\"ORGANIZATION\",\"KNOWN_AS\":\"\"}}},\"xmlns\":\"http://rhcdh.redhat.com/1\"}}';
                res.setBody(jsonBody);
                res.setStatusCode(200);
            }
        } catch(System.CalloutException e) {
            throw e;   // just rethrow for now
/*
            successResult = false;
            System.debug('exception ----->'+ e);
            ApexPages.Message Message = new ApexPages.Message(ApexPages.Severity.ERROR,'Large set of records retrieved. Please refine your search and search again');  // set the exception message
            ApexPages.addMessage(Message);
            return null;
*/
        }

        if (res.getStatus() == 'OK') {
            if (res.getBody() != null) {
                JSONParser errorParser;
                JSONParser parser;
                try {
                    errorParser = JSON.createParser(res.getBody());
                    String errorStr = res.getBody();
                    System.Debug('----------------1' + errorStr);
                } catch(Exception e) {
                    ApexPages.Message Message = new ApexPages.Message(ApexPages.Severity.ERROR,'Error suspected in CDH Data');  // set the exception message
                    ApexPages.addMessage(Message);
                    return null;
                }
                try {
                    parser = JSON.createParser(res.getBody());
                    String errorStr = res.getBody();
                    System.Debug('----------------2' + errorStr);
                } catch(Exception e) {
                    ApexPages.Message Message = new ApexPages.Message(ApexPages.Severity.ERROR,'Error suspected in CDH Data');  // set the exception message
                    ApexPages.addMessage(Message);
                    return null;
                }
                System.Debug('---------' + parser);

                List<JSONRecord> JSONRecordList = new List<JSONRecord>();
                Integer i = 0;
                JSONRecord j = new JSONRecord();
                j.ORIG_SYSTEM = new List<String> ();
                j.ORIG_SYSTEM_REFERENCE = new List<String> ();
                j.CLASS_CODE = new List<String> ();
                j.CLASS_CODE_DESCRIPTION = new List<String> ();
                j.CLASS_CATEGORY = new List<String> ();
                j.PRIMARY_FLAG = new List<String> ();
                j.START_DATE_ACTIVE = new List<String> ();
                j.END_DATE_ACTIVE = new List<String> ();
                j.STATUS = new List<String> ();

                String errorMessage = '';
                while (errorParser.nextToken() != null) {
                    if ((errorParser.getCurrentToken() == JSONToken.FIELD_NAME) &&(errorParser.getText() == 'ERROR_MESSAGE')) {
                        errorParser.nextToken();
                        System.Debug('==============Error' + errorParser.getText());
                        errorMessage = errorParser.getText();
                    }
                }

                if (errorMessage == '') {
                    System.debug('================================entered data parsing');
                    while (parser.nextToken() != null) {
                        if(i == 0) {
                            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) &&(parser.getText() == 'PARTY_TYPE')) {
                                parser.nextToken();
                                j.PARTY_TYPE = parser.getText();
                                System.debug('========================================PARTY_TYPE '+parser.getText());
                                i++;
                                JSONRecordList.add(j);
                                j = new JSONRecord();
                                j.ORIG_SYSTEM = new List<String> ();
                                j.ORIG_SYSTEM_REFERENCE = new List<String> ();
                                j.CLASS_CODE = new List<String> ();
                                j.CLASS_CODE_DESCRIPTION = new List<String> ();
                                j.CLASS_CATEGORY = new List<String> ();
                                j.PRIMARY_FLAG = new List<String> ();
                                j.START_DATE_ACTIVE = new List<String> ();
                                j.END_DATE_ACTIVE = new List<String> ();
                                j.STATUS = new List<String> ();
                                System.debug('@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@'+i);
                            }
                            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'PARTY_NAME')) {
                                parser.nextToken();
                                System.debug('========================================PARTY_NAME '+parser.getText());
                                j.PARTY_NAME = parser.getText();
                            }
                            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'PARTY_NUMBER')) {
                                parser.nextToken();
                                System.debug('========================================PARTY_NUMBER '+parser.getText());
                                j.PARTY_NUMBER = parser.getText();
                            }

                            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'DUNS_NUMBER')) {
                                parser.nextToken();
                                System.debug('========================================DUNS_NUMBER '+parser.getText());
                                j.DUNS_NUMBER = parser.getText();
                            }
                            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'PARTY_SITE_NUMBER')) {
                                parser.nextToken();
                                System.debug('========================================PARTY_SITE_NUMBER '+parser.getText());
                                j.PARTY_SITE_NUMBER = parser.getText();
                            }
                            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'ADDRESS1')) {
                                parser.nextToken();
                                System.debug('========================================ADDRESS1 '+parser.getText());
                                j.ADDRESS1 = parser.getText();
                            }
                            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'ADDRESS2')) {
                                parser.nextToken();
                                System.debug('========================================ADDRESS2 '+parser.getText());
                                j.ADDRESS2 = parser.getText();
                            }
                            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'CITY')) {
                                parser.nextToken();
                                System.debug('========================================CITY '+parser.getText());
                                j.CITY = parser.getText();
                            }
                            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'COUNTY')) {
                                parser.nextToken();
                                System.debug('========================================COUNTY'+parser.getText());
                                j.COUNTY = parser.getText();
                            }
                            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'STATE')) {
                                parser.nextToken();
                                System.debug('========================================STATE '+parser.getText());
                                j.STATE = parser.getText();
                            }
                            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'PROVINCE')) {
                                parser.nextToken();
                                System.debug('========================================PROVINCE '+parser.getText());
                                j.PROVINCE = parser.getText();
                            }
                            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'COUNTRY')) {
                                parser.nextToken();
                                System.debug('========================================COUNTRY '+parser.getText());
                                j.COUNTRY = parser.getText();
                            }
                            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'POSTAL_CODE')) {
                                parser.nextToken();
                                System.debug('========================================POSTAL_CODE '+parser.getText());
                                j.POSTAL_CODE = parser.getText();
                            }
                            if(j.PHONENO == null){
                                if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'RAW_PHONE_NUMBER')) {
                                    parser.nextToken();
                                    System.debug('========================================POSTAL_CODE '+parser.getText());
                                    j.PHONENO = parser.getText();
                                }
                            }
                            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'ORIG_SYSTEM')) {
                                parser.nextToken();
                                System.debug('========================================ORIG_SYSTEM '+parser.getText());
                                j.ORIG_SYSTEM.add(parser.getText());
                            }
                            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'ORIG_SYSTEM_REFERENCE')) {
                                parser.nextToken();
                                System.debug('========================================ORIG_SYSTEM_REFERENCE '+parser.getText());
                                j.ORIG_SYSTEM_REFERENCE.add(parser.getText());
                            }

                            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'TAX_REFERENCE')) {
                                parser.nextToken();
                                System.debug('========================================TAX_REFERENCE '+parser.getText());
                                j.TAX_REFERENCE = parser.getText();
                            }
                            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'CLASS_CODE')) {
                                parser.nextToken();
                                System.debug('========================================CLASS_CODE '+parser.getText());
                                j.CLASS_CODE.add(parser.getText());
                            }
                            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'CLASS_CODE_DESCRIPTION')) {
                                parser.nextToken();
                                System.debug('========================================CLASS_CODE_DESCRIPTION '+parser.getText());
                                j.CLASS_CODE_DESCRIPTION.add(parser.getText());
                            }
                            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'CLASS_CATEGORY')) {
                                parser.nextToken();
                                System.debug('========================================CLASS_CATEGORY '+parser.getText());
                                j.CLASS_CATEGORY.add(parser.getText());
                            }
                            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'PRIMARY_FLAG')) {
                                parser.nextToken();
                                System.debug('========================================PRIMARY_FLAG '+parser.getText());
                                j.PRIMARY_FLAG.add(parser.getText());
                            }
                            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'START_DATE_ACTIVE')) {
                                parser.nextToken();
                                System.debug('========================================START_DATE_ACTIVE '+parser.getText());
                                j.START_DATE_ACTIVE.add(parser.getText());
                            }
                            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'END_DATE_ACTIVE')) {
                                parser.nextToken();
                                System.debug('========================================END_DATE_ACTIVE '+parser.getText());
                                j.END_DATE_ACTIVE.add(parser.getText());
                            }
                            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'STATUS')) {
                                parser.nextToken();
                                System.debug('========================================STATUS '+parser.getText());
                                j.STATUS.add(parser.getText());
                            }
                            i = 0;
                        }
                    }

                    Integer rowNum = 0;

                    for (JSONRecord row : JSONRecordList) {
                        SearchResult SRW = new SearchResult();
                        SRW.rowNum = string.valueOf(rowNum);
                        SRW.partyName = row.PARTY_NAME;
                        SRW.partyNumber = row.PARTY_NUMBER;
                        SRW.partyType = row.PARTY_TYPE;
                        SRW.partyTier = '';
                        SRW.DUNSNumber = row.DUNS_NUMBER;
                        SRW.partySiteNumber = row.PARTY_SITE_NUMBER;
                        SRW.address1 = row.ADDRESS1;
                        SRW.address2 = row.ADDRESS2;
                        SRW.city = row.CITY;
                        SRW.county = row.COUNTY;
                        SRW.state = row.STATE;
                        SRW.province = row.PROVINCE;
                        SRW.country = row.COUNTRY;
                        SRW.postalCode = row.POSTAL_CODE;
                        SRW.identifyingAddress = row.ADDRESS1;
                        SRW.taxReference = row.TAX_REFERENCE;
                        SRW.identifyingAddress += row.ADDRESS2 != '' ? ' '+row.ADDRESS2 : '';
                        SRW.identifyingAddress += row.CITY != '' ? ', '+row.CITY : '';
                        SRW.identifyingAddress += row.STATE != '' ? ', '+row.STATE : '';
                        SRW.identifyingAddress += row.PROVINCE != '' ? ', '+row.PROVINCE : '';
                        SRW.identifyingAddress += row.COUNTRY != '' ? ', '+row.COUNTRY : '';
                        SRW.identifyingAddress += row.POSTAL_CODE != '' ? ', '+row.POSTAL_CODE : '';
                        SRW.phone = row.PHONENO;
                        String salesforceLinks = '';
                        for (Integer ii = 0; ii < row.ORIG_SYSTEM.size(); ii++) {
                            if (row.ORIG_SYSTEM[ii] == 'SFDC') {
                                List<String> salesforceIDs = new List<String>();
                                salesforceIDs = row.ORIG_SYSTEM_REFERENCE[ii].split('_');
                                System.Debug('Split Osr----->'+salesforceIDs[0]);
                                salesforceLinks += salesforceLinks == '' ? salesforceIDs[0] : ','+salesforceIDs[0];
                            }
                        }
                        SRW.relatedLinks = salesforceLinks;
                        String partnerCode = '';
                        List<String> partnerCodes= new List<String>();
                        for (Integer ii = 0; ii < row.CLASS_CATEGORY.size(); ii++) {
                            System.debug ('Partner ---->'+row.CLASS_CATEGORY[ii]);
                            System.debug ('new data ---->'+row.CLASS_CODE[ii]+' : '+ row.CLASS_CODE_DESCRIPTION[ii]);
                            if (row.CLASS_CATEGORY[ii] == 'Partner') {
                                if (row.CLASS_CODE[ii] != '') {
                                    System.Debug('new data ---->'+row.CLASS_CODE[ii]+' : '+ row.CLASS_CODE_DESCRIPTION[ii]);
                                    if (ii < row.CLASS_CATEGORY.size()-1 && row.CLASS_CATEGORY.size() > 1) {
                                        partnerCodes.add(row.CLASS_CODE_DESCRIPTION[ii] +';');
                                    }
                                    else {
                                        partnerCodes.add( row.CLASS_CODE_DESCRIPTION[ii]);
                                    }

                                 }
                            }
                        }

                        SRW.partnerCodes = partnerCodes;
                        System.debug('========================================partnerCodes  '+partnerCodes );
                        System.debug('========================================partnerCode  '+partnerCode );
                        SRW.classification = '';
                        for (Integer counter = 0; counter < partnerCodes.size(); counter++) {
                            SRW.classification += partnerCodes[counter];
                        }
                        searchResultList.add(SRW);
                        rowNum++;
                    }

                } else {
                    ApexPages.Message Message = new ApexPages.Message(ApexPages.Severity.ERROR,errorMessage);
                    ApexPages.addMessage(Message);
                    return null;
                }

            } else {
                ApexPages.Message Message = new ApexPages.Message(ApexPages.Severity.INFO,'No Data returned');
                ApexPages.addMessage(Message);
                return null;
            }

        } else if(res.getStatus() == 'Bad Request') {
            ApexPages.Message Message = new ApexPages.Message(ApexPages.Severity.ERROR,'Records could not be retrieved for the search criteria provided');  // set the exception message
            ApexPages.addMessage(Message);
        } else {
            ApexPages.Message Message = new ApexPages.Message(ApexPages.Severity.INFO,'CDH system is down, please try later.');  // set the exception message
            ApexPages.addMessage(Message);
            System.debug('Result status: ' + res.getStatus());
        }

        return searchResultList;
     }

     public class ContactSearchResult {
        public  String      status;
        public  String      phone;
        public  String      email;
        public  String      loginName;
        public  String[]    idList;
        public  String      salesAcctPartyNumber;
        public  String      fax;
        public  String      salutation;
        public  String      firstName;
        public  String      lastName;
        public  String      cdhPartyNumber;
        public  String      salesAccountId;
        public  String      mobilePhone;
     }

    public class SearchResult {
        public String rowNum            {get;set;}
        public String partyName         {get;set;}
        public String partyNumber       {get;set;}
        public String partyType         {get;set;}
        public String partyTier         {get;set;}
        public String DUNSNumber        {get;set;}
        public String partySiteNumber   {get;set;}
        public String identifyingAddress {get;set;}
        public String taxReference      {get;set;}
        public String phone             {get;set;}
        public String relatedLinks      {get;set;}
        public List<string> partnerCodes {get;set;}
        public String address1          {get;set;}
        public String address2          {get;set;}
        public String city              {get;set;}
        public String county            {get;set;}
        public String state             {get;set;}
        public String province          {get;set;}
        public String country           {get;set;}
        public String postalCode        {get;set;}
        public String classification    {get;set;}
    }

    public class SearchParams {
        public string accName {get;set;}
        public Boolean AliasFlag{get;set;}
        public string DUNSNumber {get;set;}
        public string PartyNo{get;set;}
        public string Street{get;set;}
        public string city{get;set;}
        public string postalcode{get;set;}
        public string country{get;set;}
        public string state{get;set;}

        public SearchParams() {
            accName = null;
            AliasFlag = false;
            PartyNo = null;
            Street = null;
            city = null;
            postalcode = null;
            country = null;
            state = null;
        }
    }

    public class JSONRecord {
      public String PARTY_NAME{get;set;}
      public string PARTY_NUMBER{get;set;}
      public String PARTY_TYPE{get;set;}
      public string DUNS_NUMBER{get;set;}
      public String PARTY_SITE_NUMBER{get;set;}
      public String TAX_REFERENCE{get;set;}
      public String ADDRESS1{get;set;}
      public string ADDRESS2 {get;set;}
      public String CITY{get;set;}
      public string COUNTY {get;set;}
      public String STATE{get;set;}
      public string PROVINCE{get;set;}
      public String COUNTRY{get;set;}
      public string POSTAL_CODE {get;set;}
      public string PHONENO{get;set;}
      public List<String> ORIG_SYSTEM {get;set;}
      public List<string> ORIG_SYSTEM_REFERENCE{get;set;}
      public List<string> CLASS_CODE{get;set;}
      public List<string> CLASS_CODE_DESCRIPTION{get;set;}
      public List<string> CLASS_CATEGORY{get;set;}
      public List<string> PRIMARY_FLAG{get;set;}
      public List<string> START_DATE_ACTIVE{get;set;}
      public List<string> END_DATE_ACTIVE{get;set;}
      public List<string> STATUS{get;set;}
    }




}