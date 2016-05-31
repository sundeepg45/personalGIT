public without sharing class ExtUserService {

    public String jsonResult {get; set; }


    public ExtUserService() {
    }

    public void doUserLookup() {

        String federationid = ApexPages.currentPage().getParameters().get('federationid');
        String partner = ApexPages.currentPage().getParameters().get('partner');
        String md5token = ApexPages.currentPage().getParameters().get('token');

        if (federationid == null) {
            jsonResult = '{ "status":"error", "description":"Missing required federationid parameter" }';
            return;
        }
        if (md5token == null) {
            jsonResult = '{ "status":"error", "description":"Missing validation token" }';
            return;
        }
        if (md5token == null) {
            jsonResult = '{ "status":"error", "description":"Missing partner identifier" }';
            return;
        }
        partner = partner.toLowerCase();
        External_User_Lookup__c extpartner = External_User_Lookup__c.getInstance(partner);
        if (extpartner.Enabled__c == false) {
            jsonResult = '{ "status":"error", "description":"Partner has been deactivated" }';
            return;
        }
        System.debug('federationid:' + federationid);
        System.debug('partner:' + partner);
        System.debug('auth:' + extpartner.Auth_Token__c);
        System.debug('string:' + federationid+partner+extpartner.Auth_Token__c);
        String mymd5 = EncodingUtil.convertToHex(Crypto.generateDigest('MD5', Blob.valueOf(federationid + partner + extpartner.Auth_Token__c)));
        System.debug('md5:' + mymd5);
        if (md5token != mymd5) {
            jsonResult = '{ "status":"error", "description" : "Invalid token" }';
            return;
        }

        // check for soql injection attack
        if (federationid.indexOf('%') != -1) {
            jsonResult = '{ "status":"error", "description":"invalid federationid parameter" }';
            return;
        }

        User[] users = [
            select  Id, FederationIdentifier, Contact.AccountId, Email, FirstName, LastName, Phone, Title
            from    User
            where   FederationIdentifier = :federationid and IsActive = true
        ];
        if (users.isEmpty()) {
            jsonResult = '{ "status":"notfound", "description":"federationid not found or disabled" }';
            return;
        }
        Account acct = [
            select  Id, Name, Website, Finder_Partner_Type__r.Name, BillingStreet, BillingCity, BillingState, BillingCountry
            from    Account
            where   Id = :users[0].Contact.AccountId
        ];

        Payload u = new Payload(users[0], acct);
        jsonResult =  JSON.serialize(u);
    }


public class AddressData {
    public String   street;
    public String   city;
    public String   state;
    public String   country;

}

public class PartnerData {
    public String   accountId;
    public String   name;
    public String   website;
    public AddressData  address;
    public String   partnerType;

    public PartnerData(Account acct) {
        address = new AddressData();
        accountId = ((String) acct.Id).substring(0,15);
        name = acct.Name;
        website = acct.Website;
        partnerType = acct.Finder_Partner_Type__r.Name;
        address.street = acct.BillingStreet;
        address.city = acct.BillingCity;
        address.state = acct.BillingState;
        address.country = acct.BillingCountry;
    }
}

public class UserData {
    public String   federationId;
    public String   title;
    public String   phone;
    public String   firstName;
    public String   lastName;
    public String   email;

    public UserData(User user) {
        federationId = user.FederationIdentifier;
        title = user.Title;
        phone = user.phone;
        firstName = user.FirstName;
        lastName = user.LastName;
        email = user.Email;
    }
}

public class Payload {
    public String       status;
    public PartnerData  partner;
    public UserData     user;

    public Payload(User u, Account acct) {
        status = 'ok';
        partner = new PartnerData(acct);
        user = new UserData(u);
    }
}

}