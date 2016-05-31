public class APACLeadRouting {

public String NAMED_ACCOUNT = 'Named Account';
public String EMAIL_DOMAIN = 'Email Domain';
public String JAPAN_COMMERCIAL_ACCOUNT = 'Japan Commercial';
public String ANZ_COMMERCIAL_NAMED_ACCOUNT= 'ANZ Commercial Named Account';
public String CHINA_PROVINCE= 'China Province';
public String ANZ_PROVINCE='ANZ Province';
public String APAC_PARTNER_ACCOUNT='Partner Account';
public String APAC_COUNTRY='Country';
public static String GLOBAL_LEAD_ROUTING_ERROR = 'GLR Error Queue';

public String state=null;
public String country=null;
Boolean isEmailDomain=false;

// Assign owner for APAC region 
public void assignQueue(List<Lead> leads, Map<String,String> companyMap,Map<String,String> countryMap,Map<String,String> stateMap,LeadMap leadMap,Map<String,String>apacatEmailMap,Map<String,String>apacDotEmailMap)
{
    Map<String,LeadAccountRules__c> partnerMap = new Map<String,LeadAccountRules__c>();
    Map<String,LeadAccountRules__c> namedAccountMap = new Map<String,LeadAccountRules__c>();
    Map<String,LeadAccountRules__c> japanCommercialMap = new Map<String,LeadAccountRules__c>();
    Map<String,LeadRules__c> chinaProvinceMap = new Map<String,LeadRules__c>();
    Map<String,LeadRules__c> anzProvinceMap = new Map<String,LeadRules__c>();
    Map<String,LeadRules__c> indiaProvinceMap = new Map<String,LeadRules__c>();
    Map<String,LeadRules__c> japanProvinceMap = new Map<String,LeadRules__c>();
    Map<String,LeadAccountRules__c> anzCommecialMap = new Map<String,LeadAccountRules__c>();
    Map<String,LeadRules__c> apaccountryMap = new Map<String,LeadRules__c>();
    Map<String,LeadRules__c> apaccityMap = new Map<String,LeadRules__c>();
    Map<String,LeadRules__c> emailRulesMap= new Map<String,LeadRules__c>();
    List<String> apacAtEmail = new List<String>();
    List<String> apacDotEmail = new List<String>();
    


    LeadAccountRules__c[] partners=[Select Assign_To__c,Value__c,User__c,Assign_To_Partner__c,PartnerQueue__c,PartnerUser__c
                                    from LeadAccountRules__c where Value__c IN :companyMap.values()
                                    and SuperRegion__c='APAC' and Type__c=:APAC_PARTNER_ACCOUNT];

    for(LeadAccountRules__c partner:partners)
    {
        partnerMap.put(partner.Value__c.toUpperCase(),partner);
    }


        LeadAccountRules__c[] leadassignments =[select Account__r.Name,Account__r.OwnerId,Assign_To__c,User__c,Type__c,Assign_To_Account_Owner__c,Value__c,Assign_To_Partner__c,PartnerQueue__c,PartnerUser__c from LeadAccountRules__c where (Account__r.Name IN :companyMap.values() OR Value__c IN :companyMap.values()) and SuperRegion__c='APAC' and Account__c != null];


        for(LeadAccountRules__c objleadassignment:leadassignments)
        {

                if (objleadassignment.Type__c=='Named Account')
                {
                    namedAccountMap.put(objleadassignment.Value__c.toUpperCase(),objleadassignment);
                }
                if(objleadassignment.Type__c=='Japan Commercial')
                {
                    japanCommercialMap.put(objleadassignment.Value__c.toUpperCase(),objleadassignment);
                }
                if(objleadassignment.Type__c=='ANZ Commercial Named Account')
                {
                    anzCommecialMap.put(objleadassignment.Value__c.toUpperCase(),objleadassignment);
                }
        }

        LeadRules__c[] apacCountries=[Select Assign_To__c,Type__c, Value__c, City__c,User__c,Assign_To_Partner__c,
                                      PartnerQueue__c,PartnerUser__c from LeadRules__c 
                                      where (Value__c IN :countryMap.values() OR Value__c IN :stateMap.values()) and SuperRegion__c='APAC'];
        
        for(LeadRules__c apacRule:apacCountries)
        {              
                if(apacRule.Type__c=='Country')
                {                
                    apaccountryMap.put(apacRule.Value__c.toUpperCase(),apacRule);                   
                }
                else if(apacRule.Type__c=='China Province')
                {
                    chinaProvinceMap.put(apacRule.Value__c.toUpperCase(),apacRule);
                }
                else if(apacRule.Type__c=='ANZ Province')
                {
                    anzProvinceMap.put(apacRule.Value__c.toUpperCase(),apacRule);
                }
                else if(apacRule.Type__c=='India Province')
                {
                    indiaProvinceMap.put(apacRule.Value__c.toUpperCase(),apacRule);
                }   
                else if(apacRule.Type__c=='Japan Province')
                {
                    japanProvinceMap.put(apacRule.Value__c.toUpperCase(),apacRule);
                }   
        }

    
        LeadRules__c[] emailrules=[Select Assign_To__c, Type__c, Value__c,User__c,Country__c,Assign_To_Partner__c,
        PartnerQueue__c,PartnerUser__c from LeadRules__c where (Value__c IN:apacatEmailMap.values() OR Value__c IN:apacdotEmailMap.values()) and SuperRegion__c='APAC'and Type__c=:EMAIL_DOMAIN];

        for(LeadRules__c emailRulesobj:emailrules)
        {
            emailRulesMap.put(emailRulesobj.Value__c.toUpperCase(),emailRulesobj);
        }   

        String leadId ='';
        Lead objLead = null;
        String atemailId ='';
        String dotemailId='';
        String emailId='';
        String company = '';
        String state='';
        String cityOfLead= '';

        for(Integer i=0;i<leads.size();i++)
        {

            objLead = leads.get(i);
            company = objLead.Company.toUpperCase();
            state = objLead.State;
            if(state != null) state = state.toUpperCase();
            if(partnerMap.containsKey(company))
            {
                LeadAccountRules__c accRule= partnerMap.get(company);
                objLead.OwnerId = getOwnerId(objLead,accRule.Assign_To__c,accRule.User__c, accRule.PartnerQueue__c
                                                    ,accRule.PartnerUser__c,false,null, accRule.Assign_To_Partner__c,leadMap );
                leads.remove(i);
                i--;
                objLead.Assignment_Error__c ='';
                objLead.Dummy_Field__c = '2';
                objLead.Assignment_Error__c = '';
                continue;
            }
            

            if(NamedAccountMap.containsKey(company))
            {
                    LeadAccountRules__c accRule = namedAccountMap.get(company);
                    objLead.OwnerId = getOwnerId(objLead,accRule.Assign_To__c,accRule.User__c,
                                                        accRule.PartnerQueue__c,accRule.PartnerUser__c,accRule.Assign_To_Account_Owner__c
                                                        ,accRule.Account__r.OwnerId,accRule.Assign_To_Partner__c,leadMap );

                    objLead.Assignment_Error__c ='';
                    objLead.Dummy_Field__c = '2';
                    objLead.Assignment_Error__c = '';
                    leads.remove(i);
                    i--;
                    continue;

                }
           
                emailId=objLead.Email;
                String[] emailSplit = emailId.split('@',2);
                String[] emaildotsplit=null;
                String dotSplit='';

                if(emailSplit.size() >1)
                {
                    emailId = emailSplit[1].toUpperCase();
                    emaildotsplit=emailId.split('\\.',-1);
                    if(emaildotsplit.size()>1)dotSplit=emaildotsplit[emaildotsplit.size()-1].toUpperCase();
                     System.Debug('dotSplit'+dotSplit);
               }
                
                if(emailRulesMap.containsKey('.'+dotSplit))
                {
                                LeadRules__c rule =emailRulesMap.get('.'+dotSplit);
                                
                                objLead.OwnerId = getOwnerId(objLead,rule.Assign_To__c,rule.User__c, rule.PartnerQueue__c
                                    ,rule.PartnerUser__c,false,null, rule.Assign_To_Partner__c,leadMap );                       

                                objLead.Assignment_Error__c ='';
                                objLead.Dummy_Field__c = '2';
                                objLead.Assignment_Error__c = '';
                                leads.remove(i);
                                i--;
                                continue;

                }

                if(emailRulesMap.containsKey(emailId))
                {
                                LeadRules__c rule =emailRulesMap.get(emailId);
                                                        
                                objLead.OwnerId = getOwnerId(objLead,rule.Assign_To__c,rule.User__c, rule.PartnerQueue__c
                                    ,rule.PartnerUser__c,false,null, rule.Assign_To_Partner__c,leadMap );

                               objLead.Assignment_Error__c ='';
                                objLead.Dummy_Field__c = '2';
                                objLead.Assignment_Error__c = '';
                                leads.remove(i);
                                i--;
                                continue;

                } 
            
                if(objLead.Iso_Country_Code__c == 'JP' && japanCommercialMap.containsKey(objLead.Company.toUpperCase()))
                {
                                LeadAccountRules__c japanCommercial = japanCommercialMap.get(objLead.Company.toUpperCase());

                                objLead.OwnerId = getOwnerId(objLead,japanCommercial.Assign_To__c,japanCommercial.User__c
                                                                                    , japanCommercial.PartnerQueue__c,japanCommercial.PartnerUser__c
                                                                                    ,japanCommercial.Assign_To_Account_Owner__c,japanCommercial.Account__r.OwnerId,japanCommercial.Assign_To_Partner__c,leadMap );

                                objLead.Assignment_Error__c ='';
                                objLead.Dummy_Field__c = '2';
                                objLead.Assignment_Error__c = '';
                                leads.remove(i);
                                i--;
                                continue;
                }


                if(objLead.Iso_Country_Code__c == 'CN' && chinaProvinceMap.containsKey(state))
                {
                                LeadRules__c rule = chinaProvinceMap.get(state);
                                objLead.OwnerId = getOwnerId(objLead,rule.Assign_To__c,rule.User__c, rule.PartnerQueue__c
                                                                                    ,rule.PartnerUser__c,false,null, rule.Assign_To_Partner__c,leadMap );

                                objLead.Assignment_Error__c ='';
                                objLead.Dummy_Field__c = '2';
                                objLead.Assignment_Error__c = '';
                                leads.remove(i);
                                i--;
                                continue;

                }

                if((objLead.Iso_Country_Code__c=='AU'|| objLead.Iso_Country_Code__c=='NZ') && anzCommecialMap.containsKey(objLead.Company.toUpperCase()))
                {

                                LeadAccountRules__c objANZCommercial = anzCommecialMap.get(objLead.Company.toUpperCase());

                                objLead.OwnerId = getOwnerId(objLead,objANZCommercial.Assign_To__c,objANZCommercial.User__c
                                                                                    , objANZCommercial.PartnerQueue__c,objANZCommercial.PartnerUser__c
                                                                                    ,objANZCommercial.Assign_To_Account_Owner__c,objANZCommercial.Account__r.OwnerId,objANZCommercial.Assign_To_Partner__c,leadMap );
                                objLead.Assignment_Error__c ='';
                                objLead.Dummy_Field__c = '2';
                                objLead.Assignment_Error__c = '';
                                leads.remove(i);
                                i--;
                                continue;
                }


                if((objLead.Iso_Country_Code__c=='AU'|| objLead.Iso_Country_Code__c=='NZ') && anzProvinceMap.containsKey(state))
                {
                                
                                LeadRules__c rule = anzProvinceMap.get(state);

                                objLead.OwnerId = getOwnerId(objLead,rule.Assign_To__c,rule.User__c, rule.PartnerQueue__c
                                                                                    ,rule.PartnerUser__c,false,null, rule.Assign_To_Partner__c,leadMap );
                                objLead.Assignment_Error__c ='';
                                objLead.Dummy_Field__c = '2';
                                objLead.Assignment_Error__c = '';
                                leads.remove(i);
                                i--;
                                continue;

                }

                if(objLead.Iso_Country_Code__c == 'IN' && indiaProvinceMap.containsKey(state))
                {
                                LeadRules__c rule = indiaProvinceMap.get(state);

                                objLead.OwnerId = getOwnerId(objLead,rule.Assign_To__c,rule.User__c, rule.PartnerQueue__c
                                                                                    ,rule.PartnerUser__c,false,null, rule.Assign_To_Partner__c,leadMap );

                                objLead.Assignment_Error__c ='';
                                objLead.Dummy_Field__c = '2';
                                objLead.Assignment_Error__c = '';
                                leads.remove(i);
                                i--;
                                continue;

                }
                
                if(objLead.Iso_Country_Code__c == 'JP' && japanProvinceMap.containsKey(state))
                {
                                LeadRules__c rule = japanProvinceMap.get(state);
                                objLead.OwnerId = getOwnerId(objLead,rule.Assign_To__c,rule.User__c, rule.PartnerQueue__c
                                                                                    ,rule.PartnerUser__c,false,null, rule.Assign_To_Partner__c,leadMap );

                                objLead.Assignment_Error__c ='';
                                objLead.Dummy_Field__c = '2';
                                objLead.Assignment_Error__c = '';
                                leads.remove(i);
                                i--;
                                continue;

                }
                else
                    {
                       // Routing by country name

                        if(apaccountryMap.containsKey(objLead.Iso_Country_Code__c))
                        {
                                LeadRules__c rule = apaccountryMap.get(objLead.Iso_Country_Code__c);
                                objLead.OwnerId = getOwnerId(objLead,rule.Assign_To__c,rule.User__c, rule.PartnerQueue__c
                                                                                        ,rule.PartnerUser__c,false,null, rule.Assign_To_Partner__c,leadMap );
                                objLead.Dummy_Field__c = '2';
                                objLead.Assignment_Error__c = '';
                                leads.remove(i);
                                i--;
                                continue;
                        }
                    }
            
            objLead.OwnerId = leadMap.getQueueId(GLOBAL_LEAD_ROUTING_ERROR);
            objLead.Assignment_Error__c = 'Country ISO Code: '+ objLead.Iso_Country_Code__c +' is not in APAC Country List ';
            objLead.Dummy_Field__c = '2';
        }
}

public String getOwnerId(Lead objLead,String queueId,String userId,
                                            String partnerQueueId,String partnerUserId, boolean accountOwnerFlag, String accountOwner, boolean assignToPartner,LeadMap leadMap)
    {
        String ownerId = '';

        if(assignToPartner && objLead.Partner_Opt_in__c)
        {
            if(partnerUserId != null && partnerUserId.length()>0)   ownerId = partnerUserId;
            if(partnerQueueId != null && partnerQueueId.length()>0) ownerId = partnerQueueId;
        }
        else
        {
            if(accountOwnerFlag)
            {
                ownerId = accountOwner;
            }
            else
            {
                if(userId != null && userId.length()>0) ownerId = userId;
                if(queueId != null && queueId.length()>0)   ownerId = queueId;
            }
        }

        if(!ownerId.startsWith('005')) ownerId =  leadMap.getQueueId(ownerId);

        return ownerId;
    }

}