@isTest(SeeAllData=true)
private class ExtUserServiceTest {

	@isTest static void validTest() {
        ExtUserService svc = new ExtUserService();
        String fedid = [select FederationIdentifier from User where FederationIdentifier != null and IsActive=true limit 1].FederationIdentifier;
        ApexPages.currentPage().getParameters().put('federationid', fedid);
        ApexPages.currentPage().getParameters().put('partner', 'zift');
        External_User_Lookup__c extpartner = External_User_Lookup__c.getInstance('zift');
        String token = EncodingUtil.convertToHex(Crypto.generateDigest('MD5', Blob.valueOf(fedid + 'zift' + extpartner.Auth_Token__c)));
        ApexPages.currentPage().getParameters().put('token', token);

        svc.doUserLookup();
        String json = svc.jsonResult;
        System.assert(json.indexOf('error') == -1, 'Received error: ' + json);
	}

    @isTest static void invalidTokenTest() {
        ExtUserService svc = new ExtUserService();
        String fedid = [select FederationIdentifier from User where FederationIdentifier != null and IsActive=true limit 1].FederationIdentifier;
        ApexPages.currentPage().getParameters().put('federationid', fedid);
        ApexPages.currentPage().getParameters().put('partner', 'zift');
        External_User_Lookup__c extpartner = External_User_Lookup__c.getInstance('zift');
        String token = EncodingUtil.convertToHex(Crypto.generateDigest('MD5', Blob.valueOf(fedid + 'zzift' + extpartner.Auth_Token__c)));
        ApexPages.currentPage().getParameters().put('token', token);

        svc.doUserLookup();
        String json = svc.jsonResult;
        System.assert(json.indexOf('error') != -1, 'Expected token error: ' + json);
    }

}