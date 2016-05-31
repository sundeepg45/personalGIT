/**
* Class Name:ContractNewPageRedirectTest
* Author:Accenture
* Date:4/26/2011
* Description:Test Class created for ContractNewPageRedirect business Class.
* Modificaton History:
* Modified By :Nitesh Dokania
* Modified date :4/26/2011
* Reason for Modification: Separated test class from business class and created a new test class
*/

@isTest
private class ContractNewPageRedirectTest
{
    public static final String OPPORTUNITY_ID_PARAM = 'CF00N60000001Nw8I_lkid';
    public static final String OPPORTUNITY_NAME_PARAM = 'CF00N60000001Nw8I';
    public static final String ACCOUNT_ID_PARAM = 'accid';
    public static final String RETURN_URL_PARAM = 'retURL';
    public static final String CANCEL_URL_PARAM = 'cancelURL';
    public static final String NOOVERRIDE_PARAM = 'nooverride';
    public static final String RECORD_TYPE_PARAM = 'RecordType';
    public static final String EDIT_PATH='/800/e';
    public static final String [] PARAM_NAMES = new String[] {
          OPPORTUNITY_ID_PARAM,
          OPPORTUNITY_NAME_PARAM,
          ACCOUNT_ID_PARAM,
          RETURN_URL_PARAM,
          CANCEL_URL_PARAM,
          NOOVERRIDE_PARAM,
          RECORD_TYPE_PARAM };
    
    public static testMethod void testContractNewPageRedirect()
    {
        Opportunity opp = [select Id, Name, AccountId from Opportunity where AccountId != null and Name != null limit 1];
        Pagereference currentPage = new Pagereference('/test/');
        ApexPages.StandardController sc = new ApexPages.StandardController(opp);
        ContractNewPageRedirect controller = new ContractNewPageRedirect(sc);
        controller.currentPage = currentPage;        
        Map<String,String> retval=controller.pageredirect().getParameters();
        System.assertEquals(retval.get(NOOVERRIDE_PARAM),'1');
        Map<String,String> parameters = currentPage.getParameters();
        parameters.put(ACCOUNT_ID_PARAM,''+opp.AccountId);
        retval=controller.pageredirect().getParameters();
        System.assertEquals(retval.get(ACCOUNT_ID_PARAM),''+opp.AccountId);
        ContractNewPageRedirect.putParam(parameters,RETURN_URL_PARAM,'/'+opp.AccountId);
        retval=controller.pageredirect().getParameters();
        System.debug('retval url'+retval.get(CANCEL_URL_PARAM));
        System.debug('ret url'+parameters.get(RETURN_URL_PARAM));
        //System.assertEquals(retval.get(CANCEL_URL_PARAM),parameters.get(RETURN_URL_PARAM));
//        if(!controller.pageredirect().getUrl().contains(EncodingUtil.urlEncode('/'+opp.AccountId,'UTF-8')))
//        {
//          System.assertEquals(EncodingUtil.urlEncode('/'+opp.AccountId,'UTF-8'),controller.pageredirect().getUrl());
//        }
        parameters.put(OPPORTUNITY_ID_PARAM,''+opp.Id);
        ContractNewPageRedirect.putParam(parameters,RETURN_URL_PARAM,'/'+opp.Id);
        retval=controller.pageredirect().getParameters();
        System.assertEquals(retval.get(OPPORTUNITY_ID_PARAM),''+opp.Id);
        System.assertEquals(retval.get(OPPORTUNITY_NAME_PARAM),EncodingUtil.urlEncode(opp.Name,'UTF-8'));
        ContractNewPageRedirect.putParam(parameters,OPPORTUNITY_NAME_PARAM,opp.Name);
        retval=controller.pageredirect().getParameters();
        System.assertEquals(retval.get(OPPORTUNITY_NAME_PARAM),EncodingUtil.urlEncode(opp.Name,'UTF-8'));
        parameters.remove(ACCOUNT_ID_PARAM);
        retval=controller.pageredirect().getParameters();
        System.assertEquals(retval.get(OPPORTUNITY_NAME_PARAM),EncodingUtil.urlEncode(opp.Name,'UTF-8'));
        System.assertEquals(retval.get(ACCOUNT_ID_PARAM),''+opp.AccountId);
        parameters.remove(OPPORTUNITY_NAME_PARAM);
        retval=controller.pageredirect().getParameters();
        System.assertEquals(retval.get(OPPORTUNITY_NAME_PARAM),EncodingUtil.urlEncode(opp.Name,'UTF-8'));
        System.assertEquals(retval.get(ACCOUNT_ID_PARAM),''+opp.AccountId);
    }
}