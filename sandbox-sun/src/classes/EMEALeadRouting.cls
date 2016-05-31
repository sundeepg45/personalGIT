/**
* Class Name: EMEALeadRouting
* Author: Accenture
* Description: Assigns EMEA Lead to Owner through GLR process.
* Modificaton History:
* Modified By : Nitesh Dokania
* Modified date : 4/29/2011
* Reason for Modification: Separated test class from business class.
*/

public class EMEALeadRouting {

public Map<String,String> assignedToMap = null;
public static String GLOBAL_LEAD_ROUTING_ERROR = 'GLR Error Queue';
public String NAMED_ACCOUNT = 'Named Account';
public String PARTNER_ACCOUNT = 'Partner Account';
Boolean isEmailDomain=false;
public String EMAIL_DOMAIN = 'Email Domain';
public String COUNTRY = 'Country';
public Map<String,Leadrules__c>  emailRulesMap= new Map<String,Leadrules__c>();


public void assignQueue(List<Lead> leads, Map<String,String> companyMap, Map<String,String> countryMap,LeadMap leadMap,Map<String,String>emeaatEmailMap,Map<String,String>emeaDotEmailMap)
{
        Map<String,LeadAccountRules__c> partnerMap = new Map<String,LeadAccountRules__c>();
        List<String> accList= new List<String>();
        List<String> partnerAccList= new List<String>();
        String ownerIdString='';
        Map<String,List<AccountTeamMember>> partnertempMap = new Map<String,List<AccountTeamMember>>();

        //partner account check
        LeadAccountRules__c[] partners=[Select Assign_To__c
	                                    ,Value__c
	                                    ,User__c,Assign_To_Partner__c,PartnerQueue__c,PartnerUser__c,Assign_To_Account_Team_Role__c,Account__r.Id,Account__r.OwnerId
	                                    from LeadAccountRules__c
	                                    where Value__c IN :companyMap.values()
	                                    and SuperRegion__c='EMEA' and Type__c=:PARTNER_ACCOUNT];

    	for(LeadAccountRules__c partner:partners)
        {
            partnerMap.put(partner.Value__c.toUpperCase(),partner);
            if(partner.Assign_To_Account_Team_Role__c != null)
            {
                partnerAccList.add(partner.Account__r.Id);
            } 
        }

        Lead objLead = null;
        partnertempMap=getTeamMemberMap(partnerAccList);
    
         for(Integer i=0;i<leads.size();i++)
        {
            objLead = leads.get(i);
            if(partnerMap.containsKey(objLead.Company.toUpperCase()))
            {
                LeadAccountRules__c accRule= partnerMap.get(objLead.Company.toUpperCase());
                System.debug('teamMem***'+objLead);
                objLead.OwnerId = getOwnerId(objLead,accRule.Assign_To__c,accRule.User__c, accRule.PartnerQueue__c
                                                ,accRule.PartnerUser__c,accRule.Assign_To_Account_Team_Role__c, accRule.Account__r.OwnerId,accRule.Account__r.Id, accRule.Assign_To_Partner__c,leadMap,partnertempMap);
                
                if(objLead.Assignment_Error__c == null ||(ownerIdString.startsWith('005')))
                {
                    objLead.Assignment_Error__c ='';
                }
                objLead.Dummy_Field__c = '2';
                leads.remove(i);
                i--;
            }
        }


        //if no leads in the list then return.
        if(leads.size() ==0) return;


        //Named Account check
        Map<String,LeadAccountRules__c> namedAccountMap = new Map<String,LeadAccountRules__c>();

        LeadAccountRules__c[] namedAccounts =[select Account__r.Name, Account__r.OwnerId,Assign_To__c,User__c,Assign_To_Account_Owner__c,Value__c ,Assign_To_Partner__c,PartnerQueue__c,PartnerUser__c,Country__c ,Assign_To_Account_Team_Role__c,Account__r.Id
        from LeadAccountRules__c where Type__c=:NAMED_ACCOUNT and 
        SuperRegion__c='EMEA' AND (Account__c != null AND (Account__r.Name IN :companyMap.values() OR Value__c IN :companyMap.values() )) ];

        String accountName = '';
        for(LeadAccountRules__c namedAccount:namedAccounts)
        {
        	accountName = namedAccount.Value__c.toUpperCase();
            //for named account Country is used
            if(namedAccount.Country__c != null)
            {
                accountName = accountName+'#$:'+namedAccount.Country__c;
            }
            namedAccountMap.put(accountName,namedAccount);
        }
                       
    	objLead = null;

        for(Integer i=0;i<leads.size();i++)
        {
            objLead = leads.get(i);
            if(namedAccountMap.containsKey(objLead.Company.toUpperCase()))
            {
            	LeadAccountRules__c accRule = namedAccountMap.get(objLead.Company.toUpperCase());

                objLead.OwnerId = getOwnerId(objLead,accRule.Assign_To__c,accRule.User__c,
                                                        accRule.PartnerQueue__c,accRule.PartnerUser__c,accRule.Assign_To_Account_Team_Role__c
                                                        , accRule.Account__r.OwnerId,accRule.Account__r.Id, accRule.Assign_To_Partner__c,leadMap,partnertempMap);
            	if(objLead.Assignment_Error__c == null || (ownerIdString.startsWith('005')))
                {
                    objLead.Assignment_Error__c ='';
                }
                objLead.Dummy_Field__c = '2';
                leads.remove(i);
                i--;
  
            }
            else if(namedAccountMap.containsKey(objLead.Company.toUpperCase()+'#$:'+objLead.Iso_Country_Code__c))
            {
                LeadAccountRules__c accRule = namedAccountMap.get(objLead.Company.toUpperCase()+'#$:'+objLead.Iso_Country_Code__c);

                objLead.OwnerId = getOwnerId(objLead,accRule.Assign_To__c,accRule.User__c,
                                                    accRule.PartnerQueue__c,accRule.PartnerUser__c,accRule.Assign_To_Account_Team_Role__c
                                                    ,accRule.Account__r.OwnerId,accRule.Account__r.Id, accRule.Assign_To_Partner__c,leadMap,partnertempMap );
                if(objLead.Assignment_Error__c == null || (ownerIdString.startsWith('005')))
                {
                    objLead.Assignment_Error__c ='';
                }
                objLead.Dummy_Field__c = '2';
                leads.remove(i);
                i--;
            }

        }

        LeadRules__c[] emailrules=[Select Assign_To__c, Type__c, Value__c,User__c,Country__c ,Assign_To_Partner__c,PartnerQueue__c,PartnerUser__c
                        from LeadRules__c 
                        where (Value__c IN:emeaatEmailMap.values() OR Value__c IN:emeadotEmailMap.values()) and SuperRegion__c='EMEA' 
                        and Type__c=:EMAIL_DOMAIN];

        System.debug('emailrule**'+emailrules);    
        for(LeadRules__c emailRulesobj:emailrules)
        {
            emailRulesMap.put(emailRulesobj.Value__c.toUpperCase(),emailRulesobj);
        }


        String emailId;
        for(Integer i=0;i<leads.size();i++)
        {               
            objLead=leads.get(i);             
            String atemailId ='';
            String dotemailId='';
            emailId=objLead.Email;
            String[] emailSplit = emailId.split('@',2);
            String[] emaildotsplit=null;
            String dotSplit='';
                
            if(emailSplit.size() >1)
            {
                emailId = emailSplit[1].toUpperCase();
                emaildotsplit=emailId.split('\\.',-1);
                if(emaildotsplit.size()>1)dotSplit=emaildotsplit[emaildotsplit.size()-1].toUpperCase();
            }
            if(emailRulesMap.containsKey('.'+dotSplit))
            {
                System.debug('emailleads**'+objLead);
                LeadRules__c rule =emailRulesMap.get('.'+dotSplit);
                objLead.OwnerId = getOwnerId(objLead,rule.Assign_To__c,
                rule.User__c, rule.PartnerQueue__c,rule.PartnerUser__c,null,null,null,
                    rule.Assign_To_Partner__c,leadMap,null );
                objLead.Assignment_Error__c ='';
                objLead.Dummy_Field__c = '2';
                leads.remove(i);
                i--;
                continue;

            }

            if(emailRulesMap.containsKey(emailId))
            {
                LeadRules__c rule =emailRulesMap.get(emailId);
                objLead.OwnerId = getOwnerId(objLead,rule.Assign_To__c,
                rule.User__c, rule.PartnerQueue__c,rule.PartnerUser__c,null,null,null,
                    rule.Assign_To_Partner__c,leadMap,null);
                objLead.Assignment_Error__c ='';
                objLead.Dummy_Field__c = '2';
                leads.remove(i);
                i--;
                continue;
            }

        }

        //if no leads in the list then return.
        if(leads.size() ==0) return;

        //now check for Partner queue and country list
        LeadRules__c[] emeaCountries=[Select Assign_To__c
                                    , Type__c
                                    , Value__c
                                    ,User__c,Assign_To_Partner__c,PartnerQueue__c,PartnerUser__c
                                    from LeadRules__c
                                    where
                                    (Value__c IN :countryMap.values() OR Value__c ='ALL')  and SuperRegion__c='EMEA'
                                    and Type__c=:COUNTRY ];


        Map<String,LeadRules__c> ruleMap = new Map<String,LeadRules__c>();

        for(LeadRules__c emeaCountry:emeaCountries)
        {
                ruleMap.put(emeaCountry.Value__c.toUpperCase(),emeaCountry);
        }

            for(Integer i=0;i<leads.size();i++)
            {
   
                    objLead = leads.get(i);
                    if(ruleMap.containsKey(objLead.Iso_Country_Code__c))
                    {
                        LeadRules__c rule = ruleMap.get(objLead.Iso_Country_Code__c);
                        objLead.OwnerId = getOwnerId(objLead,rule.Assign_To__c,rule.User__c, rule.PartnerQueue__c
                                                        ,rule.PartnerUser__c,null,null,null, rule.Assign_To_Partner__c,leadMap,null );

                        objLead.Assignment_Error__c ='';
                        objLead.Dummy_Field__c = '2';
                        leads.remove(i);
                        i--;
                        continue;
                    }

                    if(ruleMap.containsKey('ALL'))
                    {
                        LeadRules__c rule = ruleMap.get('ALL');
                        objLead.OwnerId = getOwnerId(objLead,rule.Assign_To__c,rule.User__c, rule.PartnerQueue__c
                                                        ,rule.PartnerUser__c,null,null,null, rule.Assign_To_Partner__c,leadMap,null );

                        objLead.Assignment_Error__c ='';
                        objLead.Dummy_Field__c = '2';
                        leads.remove(i);
                        i--;
                        continue;
                    }

                    //populate global lead routing error
                    objLead.OwnerId = leadMap.getQueueId(GLOBAL_LEAD_ROUTING_ERROR);
                    objLead.Assignment_Error__c = ' EMEA Sales Support Rule is not set up.' ;
                    objLead.Dummy_Field__c = '2';
            }
    }

//Get team members of Account.
	public Map<String, List<AccountTeamMember>> getTeamMemberMap (List<String> accountList)
    {   
            
    	Map<String, List<AccountTeamMember>> teamMemberMap= new Map<String, List<AccountTeamMember>>();
        AccountTeamMember[] teams= [Select Id, TeamMemberRole, UserId, AccountId from AccountTeamMember where AccountId IN :accountList];
                    
        if(teams.size()>0)
        {   
            for(AccountTeamMember team:teams)
            {                   
                List<AccountTeamMember> tempList= new List<AccountTeamMember>();
                String tempAccountID=team.AccountId;
                           
                if(teamMemberMap.containsKey(tempAccountID))
                {
                    tempList=teamMemberMap.get(team.AccountId);         
                    tempList.add(team);
                    teamMemberMap.put(tempAccountID, tempList);

            	}
                else
                {   
                    tempList.add(team);
                    teamMemberMap.remove(tempAccountID);
                    teamMemberMap.put(tempAccountID, tempList);
                         
                }
                            
            }
        }     
        return teamMemberMap;
    }
    
    public String getOwnerId(Lead objLead, String queueId,String userId,
    String partnerQueueId,String partnerUserId, String accountTeamRole, String accountOwner, String accountId, 
    boolean assignToPartner,leadMap leadMap, Map<String,List<AccountTeamMember>> teamMap)
    {
        String ownerId = '';
        String ownerIdFromteamRole=null;
        String tempAccountID=null;
        String userName=null;
        Integer j=0; 
        List<AccountTeamMember> teamMemberIdList=new List<AccountTeamMember>();
        
        if(assignToPartner && objLead.Partner_Opt_in__c)
        {
            if(partnerUserId != null && partnerUserId.length()>0)   ownerId = partnerUserId;
            if(partnerQueueId != null && partnerQueueId.length()>0) ownerId = partnerQueueId;
        }
        else
        {    
            if(accountTeamRole != null)
            {
                System.debug('AccTeamNotNull');
                if(accountTeamRole=='Account Owner')
                {
                    ownerId = accountOwner;
                    objLead.Assignment_Error__c = '';
                }
                else            
                {
             		System.debug('NotAccOwner');
                    if(teamMap.containsKey(accountId))
                    {
                        teamMemberIdList=teamMap.get(accountId);
                        System.debug('teamMemberIdList**'+teamMemberIdList);                            
                        for(Integer i=0; i<teamMemberIdList.size(); i++)
                        {
                            AccountTeamMember a= new AccountTeamMember();
                            a=teamMemberIdList.get(i);
                            if(a.TeamMemberRole==accountTeamRole)
                            { 
                               j++;                                                            
                               userName=a.UserId;        
                            }
                        }                                              
                        System.debug('value of j'+j);
                        if(j>0)
                        {
                            if(j==1)
                            {
                                ownerId=userName;   
                                objLead.Assignment_Error__c = '';                                
                            }
                            else
                            {
                                ownerId=GLOBAL_LEAD_ROUTING_ERROR;
                                objLead.Assignment_Error__c ='There is more than one user listed as a specific Account Team role referenced on the routing rule. Lead Assignment Source : GLR Error Queue';
                                objLead.Dummy_Field__c = '2';
                            }
                        }
                        else
                        {
                                ownerId=GLOBAL_LEAD_ROUTING_ERROR;
                                objLead.Assignment_Error__c ='There is no user listed as a specific Account Team role referenced on the routing rule. Lead Assignment Source : GLR Error Queue';
                                objLead.Dummy_Field__c = '2';
                        }
                    }                        
                  else
                    {
                                ownerId=GLOBAL_LEAD_ROUTING_ERROR;
                                objLead.Assignment_Error__c ='There is no user listed as a specific Account Team role referenced on the routing rule. Lead Assignment Source : GLR Error Queue';
                                objLead.Dummy_Field__c = '2';
                    }
                }
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