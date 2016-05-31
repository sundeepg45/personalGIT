public without sharing class STConnector {
    private final String AUTHTOKEN = 'ab77ce2301227e2df5c76c49a5014887';
    // these must be in sync with the action__c picklist values
    public static String ACTION_UPDATE_USER = 'Update User';
    public static String ACTION_CREATE_USER = 'Create User';
    public static String ACTION_ACTIVATE_USER = 'Activate User';
    public static String ACTION_DEACTIVATE_USER = 'Deactivate User';
    public static String ACTION_REFRESH_CERTS = 'Refresh Certs';

    private String osurl = '';

    public class STDuplicateUserException extends Exception {
        public String   userid;
    }

    public class STException extends Exception {}

    public class JSONResponse {
        public String status {get; set;}    // success, fail
        public String reason {get; set;}
        public String userid {get; set;}    // populated on createuser
    }

    public class STUser {
        public String status {get; set; }
        public String reason {get; set; }
        public String sfid {get; set; }
        public String sumtotalid {get; set; }
        public String firstname {get; set; }
        public String lastname {get; set; }
        public String username {get; set; }
        public String country {get; set; }
        public String managerid {get; set; }
        public String language {get; set; }
        public String email {get; set; }
        public String organization {get; set; }
        public String domain {get; set; }
        public String domainid {get; set; }
        public String accountid {get; set; }
        public String securityrole {get; set; }
        public String subregion {get; set; }
        public String accountname {get; set; }
        public String regiontypetier {get; set; }
        public String jobfunctions {get; set; }
        public String elapsed {get; set; }  // transaction elapsed time (seconds)
    }

    public STConnector() {
        Configuration__c cfg = [select Value__c from Configuration__c where Name = 'STConnect.osurl'];
        osurl = cfg.Value__c;
    }

    public STUser getUserInfo(ID userId) {
        User u = getUser(userId);
        if (u == null || u.SumTotal_ID__c == null) {
            return null;
        }
        HttpResponse rsp = submitRequest(osurl + '/service/getuser?userid=' + u.SumTotal_ID__c, null);
        System.debug('****[debug]**** response body=' + rsp.getBody());
        String body = rsp.getBody();
        if (body == null || body.length() < 10 || body.startsWith('<')) {
            // need to log this somewhere
            throw new STException('unrecognized response from server');
        }
        if (rsp.getStatusCode() != 200) {
            // need to log this somewhere
            throw new STException(body);
        }

        STUser usr = (STUser) JSON.deserialize(body, STUser.class);
        return usr;
    }

    public JSONResponse createUser(ID userId) {
        JSONResponse rsp = null;
        try {
            rsp = sendUserRequest('createuser', userId);
        }
        catch (Exception ex1) {
            LogSwarm log = new LogSwarm('sumtotal', 'signup');
            log.exception(ex1);
            return null;
        }
        if (rsp != null && rsp.status == 'fail' && rsp.userid != null) {
            STDuplicateUserException ex = new STDuplicateUserException();
            ex.userid = rsp.userid;
            throw ex;
        }
        return rsp;
    }

    public JSONResponse updateUser(ID userId) {
        return sendUserRequest('updateuser', userId);
    }

    public JSONResponse processQueue() {
        SumTotal_Request__c[] reqlist = [select Id from SumTotal_Request__c where Status__c = 'Pending'];
        if (reqlist.isEmpty()) {
            return null;
        }
        HttpResponse rsp = submitRequest(osurl + '/service/processqueue', null);
        System.debug('****[debug]**** response body=' + rsp.getBody());
        String body = rsp.getBody();
        if (body == null || body.length() < 10 || body.startsWith('<')) {
            throw new STException(body);
        }
        if (rsp.getStatusCode() != 200) {
            // need to log this somewhere
            throw new STException(rsp.getBody());
        }

        JSONResponse jrsp = (JSONResponse) JSON.deserialize(body, JSONResponse.class);
        return jrsp;
    }

    public static void enqueue(ID userId, String action) {
        SumTotal_Request__c req = new SumTotal_Request__c();
        req.Action__c = action;
        req.User__c = userId;
        insert req;
    }

    public static void enqueue(ID[] userIdList, String action) {
        SumTotal_Request__c[] reqlist = new List<SumTotal_Request__c>();
        for (ID userId : userIdList) {
            reqlist.add(new SumTotal_Request__c(Action__c=action, User__c=userId));
        }
        if (!reqlist.isEmpty()) {
            insert reqlist;
        }
    }

    //
    // internal (private) methods
    //
    private Map<String,String> userToMap(User usr, Contact_Track__c[] tracks) {
        Map<String,String> params = new Map<String,String>();
        params.put('sfid', usr.Id);
        params.put('fname', usr.FirstName);
        params.put('lname', usr.LastName);
        params.put('email', usr.Email);
        params.put('username', usr.Username);
        if (tracks != null && tracks.size() > 0) {
            String[] names = new List<String>();
            for (Contact_Track__c track : tracks) {
                String trackname = track.Partner_Track__r.Partner_Function__c + ' / ' + track.Partner_Track__r.Product_of_Interest__c;
                if (track.Primary__c) trackname = '*' + trackname;
                names.add(trackname);
            }
            if (usr.Channel_Role__c != null) {
                names.add(usr.Channel_Role__c);
            }
            params.put('jobfunctions', PartnerUtil.joinArray(names, ','));
        }
        else {
            if (usr.Channel_Role__c != null) {
                params.put('jobfunctions', usr.Channel_Role__c);
            }
        }
        if (usr.SumTotal_ID__c != null) {
            params.put('sumtotalid', usr.SumTotal_ID__c);
        }
        params.put('language', usr.LanguageLocaleKey);
        params.put('tzname', usr.TimeZoneSidKey);

        if (usr.Contact != null && usr.Contact.Account != null) {
            if (usr.Contact.Account.ShippingCountry == null)
                params.put('country', usr.Contact.Account.BillingCountry);
            else
                params.put('country', usr.Contact.Account.ShippingCountry);
            params.put('accountid', usr.Contact.AccountId);
            params.put('accountname', usr.Contact.Account.Name);
            params.put('partnertype', usr.Contact.Account.Finder_Partner_Type_Name__c);
            params.put('partnertier', usr.Contact.Account.Finder_Partner_Tier_Name__c);
            if (usr.Contact.Owner.SumTotal_ID__c != null) {
                params.put('managerid', usr.Contact.Owner.SumTotal_ID__c);
            }
            if (usr.Contact.Account.Subregion__c == 'Fed Sled') {
                params.put('region', usr.Contact.Account.Subregion__c);
            }
            else {
                params.put('region', usr.Contact.Account.Global_Region__c);
            }
            params.put('subregion', usr.Contact.Account.Subregion__c);
        }
        else {
            if (usr.Region__c == 'NA' && usr.Title != null && usr.Title.endsWith('Public Sector')) {
                params.put('region', 'Fed Sled');
            }
            else {
                if (usr.Region__c != null) params.put('region', usr.Region__c);
            }
        }
        return params;
    }

    public User getUser(ID userId) {
        try {
            return [
                select  Id, FirstName, LastName, Username, SumTotal_ID__c, Email, LanguageLocaleKey, Title,
                        Contact.Account.Finder_Partner_Tier_Name__c, Contact.Account.Finder_Partner_Type_Name__c,
                        AccountId, Contact.Account.Name, Contact.Owner.SumTotal_ID__c, Contact.Account.ShippingCountry,
                        Contact.Account.BillingCountry, TimeZoneSidKey, Contact.Account.Global_Region__c, Region__c,
                        Contact.Account.Subregion__c, Channel_Role__c
                from    User
                where   Id = :userId
            ];
        }
        catch (QueryException ex) {
            return null;
        }
    }

    public Contact_Track__c[] getTracks(ID contactId) {
        if (contactId == null) {
            return new List<Contact_Track__c>();
        }
        try {
            return [
                select Id, Contact__c, Partner_Track__r.Partner_Function__c, Partner_Track__r.Product_of_Interest__c, Primary__c
                from   Contact_Track__c
                where  Contact__c = :contactId
            ];
        }
        catch (QueryException ex) {
            return null;
        }
    }

    private JSONResponse sendUserRequest(String action, ID userId) {
        User usr = getUser(userId);
        if (usr == null) {
            System.debug('user not found');
            return null;
        }
        Contact_Track__c[] tracks = getTracks(usr.ContactId);
        Map<String,String> params = userToMap(usr, tracks);
        HttpResponse rsp = submitRequest(osurl + '/service/' + action + '?', params);
        System.debug('****[debug]**** response body=' + rsp.getBody());
        String body = rsp.getBody();
        if (body == null || body.length() < 10 || body.startsWith('<!DOCTYPE')) {
            throw new STException('unrecognized response from server');
        }
        if (rsp.getStatusCode() != 200) {
            throw new STException(rsp.getBody());
        }
        JSONResponse jrsp = (JSONResponse) JSON.deserialize(body, JSONResponse.class);
        return jrsp;
    }

    private HttpResponse submitRequest(String endpoint, Map<String,String> params) {
        Http client = new Http();
        HttpRequest request = new HttpRequest();
        request.setTimeout(60000);
        request.setMethod('GET');
        request.setHeader('RHAuth', AUTHTOKEN);
        if (params == null)
            request.setEndpoint(endpoint);
        else
            request.setEndpoint(endpoint + map2uri(params));
        System.debug('request endpoint is ' + request.getEndpoint());
        return client.send(request);
    }

    private String map2uri(Map<String,String> params) {
        String buf = '';
        for (String key : params.keySet()) {
            String val = params.get(key);
            if (val != null) {
                buf = buf + '&' + key + '=' + EncodingUtil.urlEncode(val, 'UTF-8');
            }
        }
        return buf.substring(1);
    }

}