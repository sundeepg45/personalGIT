/**
* Class Name: ContractNewPageRedirect
* Author: Accenture
* Modificaton History:
* Modified By : Nitesh Dokania
* Modified date : 4/26/2011
* Reason for Modification: Separated test class from business class.
*/

public with sharing class ContractNewPageRedirect {
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

    public Pagereference currentPage;
    
    public ContractNewPageRedirect(ApexPages.StandardController controller)
    {
        currentPage = ApexPages.currentPage();
    }
    
    public static void putParam(Map<String,String> parameters,String name,String value)
    {
        parameters.put(name,(value != null)?EncodingUtil.urlEncode(value,'UTF-8'):'');
//        parameters.put(name,(value!=null)?value:'');
    }
    
    public Pagereference getPageRedirect()
    {
        Pagereference retval1 = new Pagereference(EDIT_PATH);
        System.debug('retval 1'+retval1);
        Map<String,String> p = retval1.getParameters();
        System.debug('retval2222'+p);
        String opp_id = currentPage.getParameters().get(OPPORTUNITY_ID_PARAM);
        System.debug('oppid***'+opp_id);
        for(String paramName : PARAM_NAMES)
        {
            if(paramName == RETURN_URL_PARAM)
            {
                String retUrl = 'apex/OpportunityView?id='+opp_id;
                p.put(paramName,retUrl);
            }
            else
            {
                String s=currentPage.getParameters().get(paramName);
                if(s != null)
                {
                    p.put(paramName,s);
                }
            }
        }
        System.debug('retval 2'+p);
        String opp_id1 = p.get(OPPORTUNITY_ID_PARAM);
        System.debug('oppid111***'+opp_id1);
        String acc_id = p.get(ACCOUNT_ID_PARAM);
        String retUrl = p.get(RETURN_URL_PARAM);
        System.debug('retval???'+ retval1);
        putParam(p,NOOVERRIDE_PARAM,'1');
        System.debug('retval***'+ retval1);
        if (opp_id != null && opp_id.length() > 0 )
        {
            System.debug('inside first if');
            String opp_name = p.get(OPPORTUNITY_NAME_PARAM); 
            if(acc_id == null || acc_id.length() == 0 || opp_name == null || opp_name.length() == 0 )
            {
                List<Opportunity> opps = [
                  select Name, AccountId from Opportunity where id=:opp_id and AccountId != null limit 1 ];
                for(Opportunity opp : opps)
                {
                    putParam(p,OPPORTUNITY_NAME_PARAM,opp.name);
                    putParam(p,ACCOUNT_ID_PARAM,(acc_id=''+opp.AccountId));
                }
            }
        }
        System.debug('retval***'+ retval1);
        if(acc_id != null && acc_id.length() > 0 && retUrl != null && retUrl.length() > 0)
        {
            System.debug('inside second if');
            p.put(CANCEL_URL_PARAM,retUrl);         
        }
        System.debug('FIRST' + retval1);
        return retval1;
    }
    
    public Pagereference pageredirect()
    {
        Pagereference retval = getPageRedirect();
        retval.setRedirect(true);
        System.debug('SECOND' + retval);
        return retval;
    }
}