/**
* Class Name: LATAMLeadRouting
* Author: Accenture
* Date: 03-May-2008
* Requirement # R1
* Description: This class is used to route leads to the respective owner when captured from web depending on 
*              different conditions.
* Modificaton History:
* Modified By : Ratan Sharma
* Modified date :4/26/2011
* Reason for Modification:Separated test class from business class.
*/

public class LATAMLeadRouting 
{    
    //public static String GLOBAL_LEAD_ROUTING_ERROR = 'GLR Error Queue';
    //Aug Release 
    //LATAM GLR enhancement change, new Queue created
    
    public static String GLOBAL_LEAD_ROUTING_ERROR = 'LATAM Lead Management Queue';
    public String PARTNER_ACCOUNT ='Partner Account';
    public String NAMED_ACCOUNT = 'Named Account';
    public String EVAL_RENEW_QUEUE ='Eval/Renew';
    public String NON_EVAL_RENEW_QUEUE ='Non Eval/Renew';
    public String EMAIL_DOMAIN = 'Email Domain';
    public String NEW_COMMERCIAL='NA Commercial';
    public String COUNTRY = 'Country';
    Boolean isEmailDomain=false;
    public Map<String,LeadRules__c>  emailRulesMap= new Map<String,LeadRules__c>();

    // This method is responsible for assigning Owner to a lead through Global Lead Routing.
    
    public void assignQueue(List<Lead> leads, Map<String,String> companyMap, Map<String,String> countryMap,LeadMap leadMap,Map<String,String>latamatEmailMap,Map<String,String>latamDotEmailMap)
    {
        System.debug('atemailid'+latamatEmailMap);
        System.debug('LeadsSize'+leads.size());
        boolean zipFlag = false;
        Map<String,LeadAccountRules__c> partnerMap = new Map<String,LeadAccountRules__c>();
        LeadAccountRules__c[] partners=[Select Assign_To__c
                                                ,Value__c
                                                ,User__c,Assign_To_Partner__c,PartnerQueue__c,PartnerUser__c,Assign_To_Account_Team_Role__c,
                                                Account__r.OwnerId
                                                from LeadAccountRules__c
                                                where Value__c IN :companyMap.values()
                                                and SuperRegion__c='LATAM' and Type__c=:PARTNER_ACCOUNT];
    
        String assignTo = '';
        List<String> paccList= new List<String>();
        for(LeadAccountRules__c partner:partners)
        {
            partnerMap.put(partner.Value__c.toUpperCase(),partner);
            if (partner.Assign_To_Account_Team_Role__c != null)
            {
               paccList.add(partner.Account__r.Id);
            }
        }
        String leadId ='';
        Lead objLead = null;
        String emailId ='';
        String emailIdRule ='';
        String ownerIdString = '';

        for(Integer i=0;i<leads.size();i++)
        {
                objLead = leads.get(i);
                System.debug('LeadsSize1'+leads.size());
                System.debug('Partner Map value is:'+partnerMap);
                if(partnerMap.containsKey(objLead.Company.toUpperCase()))
                {
                    LeadAccountRules__c accRule = partnerMap.get(objLead.Company.toUpperCase());
                    system.debug('lead 1 is:'+objLead);
                    objLead.OwnerId = getOwnerId(objLead,accRule.Assign_To__c,accRule.User__c, accRule.PartnerQueue__c,accRule.PartnerUser__c,accRule.Assign_To_Partner__c,leadMap );
                    //Dummy update for change owner invoke
                    if(objLead.OwnerId == null)
                    {
                        teamMemberMap=getTeamMemberMap(paccList);
                        objLead.OwnerId = getOwnerId(objLead, 
                        accRule.Assign_To__c,
                        accRule.User__c,
                        accRule.PartnerQueue__c,
                        accRule.PartnerUser__c,
                        accRule.Assign_To_Account_Team_Role__c,
                        accRule.Account__r.OwnerId,
                        accRule.Account__r.Id, 
                        accRule.Assign_To_Partner__c,
                        leadMap,
                        teamMemberMap);

                    }

                    objLead.Dummy_Field__c = '2';
                    leads.remove(i);
                    i--;
                }
                /*
                * Allow routing LATAM Leads with Partner accounts to Account team roles.
                */          
        }
        
        /** 
        * Named Account Rule added for LATAM GLR enhancement  
        * Named Account Lead Assignment
        **/
        
        Map<String,LeadAccountRules__c> namedAccountMap = new Map<String,LeadAccountRules__c>();
        List<String> accList= new List<String>();
        LeadAccountRules__c[] accounts = [SELECT Id
                , Account__r.Name
                , Account__r.Id
                , Account__r.OwnerId
                , State__c
                , Country__c
                , Assign_To__c
                , User__c
                , Assign_To_Account_Team_Role__c
                , Value__c
                , Type__c
                , Assign_To_Partner__c
                , PartnerQueue__c
                , PartnerUser__c
                FROM LeadAccountRules__c 
                WHERE Type__c =: NAMED_ACCOUNT 
                AND SuperRegion__c='LATAM'
                AND Value__c IN :companyMap.values()];
    
         String accountAlias = '';
         for (LeadAccountRules__c accountRule:accounts)
         {
         /**
         *Determine if the lead should be assigned to an account team role
         **/
             if (accountRule.Assign_To_Account_Team_Role__c != null)
             {
                accList.add(accountRule.Account__r.Id);
             }
            
             if (accountRule.State__c != null)
             {
                 accountAlias = accountRule.Value__c+ '#$:' +accountRule.State__c ;
             }
             else 
             {
                 accountAlias = accountRule.Value__c;
             }
    
             if (accountRule.Type__c == NAMED_ACCOUNT)
             {
                //for named account Country is used
             if (accountRule.Country__c != null)
             {
                 accountAlias = accountAlias + accountRule.Country__c;
                 system.debug('CompanyCountry:'+accountAlias );
             }
                
                namedAccountMap.put(accountAlias.toUpperCase(),accountRule);
             }    
         }
        teamMemberMap=getTeamMemberMap(accList);
  
        String state = '';
        String companyState='';
        String company='';
        String country = '';
        String companyStateCountry = '';
        String companyCountry = '';

        for (Integer i=0;i<leads.size();i++)    
        {
            System.debug('LeadsSize2'+leads.size());
            objLead = leads.get(i);
            state = objLead.State;
            
            if (state != null) 
                state = state.toUpperCase();
            
            company = objLead.Company.toUpperCase();
            country = objLead.ISO_Country_Code__c;
            companyCountry = company.toUpperCase()+country.toUpperCase();
           
            // now check for master set up for country
            //
            system.debug('Named Account value is :'+namedAccountMap);
            system.debug('The lead is:'+objLead );
            system.debug('companyCountry:'+namedAccountMap.containsKey(companyCountry));
            if (namedAccountMap.containsKey(companyCountry))
            {
                LeadAccountRules__c accRule = namedAccountMap.get(companyCountry);
                system.debug('lead 2 is:'+objLead);
                objLead.OwnerId = getOwnerId(objLead, 
                    accRule.Assign_To__c,
                    accRule.User__c,
                    accRule.PartnerQueue__c,
                    accRule.PartnerUser__c,
                    accRule.Assign_To_Account_Team_Role__c,
                    accRule.Account__r.OwnerId,
                    accRule.Account__r.Id, 
                    accRule.Assign_To_Partner__c,
                    leadMap,
                    teamMemberMap);
                objLead.Dummy_Field__c = '2';
                leads.remove(i);
                i--;
                continue;
            }
                
            /**
            *check for master set up for region
            **/
                    system.debug('Named Account value 1 is :'+namedAccountMap);
                    system.debug('The lead is:'+objLead );
                    system.debug('namedAccountMap.containsKey(company):'+namedAccountMap.containsKey(company));
                    if (namedAccountMap.containsKey(company))
                    {
                    LeadAccountRules__c accRule = namedAccountMap.get(company);
                    system.debug('lead 3 is:'+objLead);
                    objLead.OwnerId = getOwnerId(objLead, 
                            accRule.Assign_To__c,
                            accRule.User__c,
                            accRule.PartnerQueue__c,
                            accRule.PartnerUser__c,
                            accRule.Assign_To_Account_Team_Role__c,
                            accRule.Account__r.OwnerId,
                            accRule.Account__r.Id, 
                            accRule.Assign_To_Partner__c,
                            leadMap,
                            teamMemberMap);
    
                     ownerIdString=objLead.OwnerId;              
                     objLead.Dummy_Field__c = '2';
                     leads.remove(i);
                     i--;
                     continue;
                    }
                }
      
        if(leads.size() ==0) return;            
        
        // LATAM Named Account rule ends 
        
        /**
        * Email Domain lead assignment 
        **/
        LeadRules__c[] emailrules=[Select Assign_To__c, Type__c, Value__c,User__c,PartnerUser__c,
        PartnerQueue__c,Assign_To_Partner__c  from LeadRules__c where 
        (Value__c IN :latamatEmailMap.values() OR Value__c IN :latamDotEmailMap.values() ) and
        SuperRegion__c='LATAM' and Type__c=:EMAIL_DOMAIN];
    
        for(LeadRules__c emailRulesobj:emailrules)
        {
            emailRulesMap.put(emailRulesobj.Value__c.toUpperCase(),emailRulesobj);
        }   
        System.debug('emailRulesMap'+emailRulesMap);
        for(Integer i=0;i<leads.size();i++)
        {         
           System.debug('LeadsSize3'+leads.size());
           objLead=leads.get(i);
           System.debug('email lead'+objLead);
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
            LeadRules__c rule =emailRulesMap.get('.'+dotSplit);
            system.debug('lead 4 is:'+objLead);
            objLead.OwnerId = getOwnerId(objLead,rule.Assign_To__c,
            rule.User__c, rule.PartnerQueue__c,rule.PartnerUser__c,
                rule.Assign_To_Partner__c,leadMap );

            objLead.Assignment_Error__c ='';
            objLead.Dummy_Field__c = '2';
            leads.remove(i);
            i--;
            continue;

        }
        System.debug('emailId'+emailId);
        if(emailRulesMap.containsKey(emailId))
        {
              LeadRules__c rule =emailRulesMap.get(emailId);
              system.debug('lead 5 is:'+objLead);
              objLead.OwnerId = getOwnerId(objLead,rule.Assign_To__c,
              rule.User__c, rule.PartnerQueue__c,rule.PartnerUser__c,
              rule.Assign_To_Partner__c,leadMap );
              objLead.Assignment_Error__c ='';
              objLead.Dummy_Field__c = '2';
              leads.remove(i);
              i--;
              continue;
         }

    }
    System.debug('cntryLeads'+leads.size());
    if(leads.size() ==0) return;      
    
    // Start -- Zip Code rule added as part of LATAM GLR enhancement - Oct. Release '10 
    
    LeadRules__c[] latamCountries=[Select Assign_To__c
                                    , Type__c
                                    , Value__c
                                    , User__c,Assign_To_Partner__c,PartnerQueue__c,PartnerUser__c, Zip_Code__c
                                    , Starting_Range__c
                                    , Ending_Range__c
                                    from LeadRules__c
                                    where
                                    SuperRegion__c='LATAM' AND
                                    Type__c= 'Country' AND
                                    (Value__c IN :countryMap.values() OR Value__c ='ALL')
                                     ];

    Map<String,LeadRules__c> ruleMap = new Map<String,LeadRules__c>();
    Map<String,List<LeadRules__c>> ruleZIPMap = new Map<String,List<LeadRules__c>>();
    List<LeadRules__c> ruleList = new List<LeadRules__c>();
            
    for(LeadRules__c latamCountry:latamCountries)
    {
        ruleMap.put(latamCountry.Value__c.toUpperCase(),latamCountry);
        ruleList = ruleZIPMap.get(latamCountry.Value__c.toUpperCase());
        if(ruleList== null)
        {
            ruleList = new List<LeadRules__c>();
        }
        ruleList.add(latamCountry);
        ruleZIPMap.put(latamCountry.Value__c.toUpperCase(), ruleList);
    }

    for(Integer i=0;i<leads.size();i++)
    {
        
        boolean ownerfound = false;
        zipFlag = false;
        objLead = leads.get(i);
        system.debug('Rule Zip Map value is:'+ruleZIPMap );
        system.debug('Zip Map Lead is:'+objLead );
        system.debug('Zip Map postal code is:'+objLead.PostalCode);
        if(ruleZIPMap.get(objLead.ISO_Country_Code__c) != null && objLead.PostalCode!=null && objLead.PostalCode.replaceAll(' ','').length()<5)
        {
            system.debug('lead 6 is:'+objLead);
            objLead.OwnerId = leadMap.getQueueId(GLOBAL_LEAD_ROUTING_ERROR);
            objLead.Assignment_Error__c = 'LATAM Zip Code rule is not set up' ;
            objLead.Dummy_Field__c = '2';
        }
        
        else
        {
            try
            {
                // objLead = leads.get(i);
                boolean incrementRuleFlag = false;
                if(ruleMap.containsKey(objLead.Iso_Country_Code__c))
                {
                    for(LeadRules__c rule: ruleZIPMap.get(objLead.Iso_Country_Code__c))
                    {
                        if(!zipFlag )
                        {
                       
                        if(objLead.PostalCode != null)
                        {
                            Integer leadZipCode = Integer.valueOf(objLead.PostalCode.replaceAll(' ','').substring(0,5));
                        }
                        system.debug('Postal Code lead is:'+objLead);
                        if(objLead.PostalCode != null &&(rule.Zip_Code__c!= null && rule.Zip_Code__c.indexOf(objLead.PostalCode.replaceAll(' ','').substring(0,5)) > -1))
                        {
                            system.debug('lead 7 is:'+objLead);
                            objLead.OwnerId = getOwnerId(objLead,rule.Assign_To__c,rule.User__c, rule.PartnerQueue__c
                                                                ,rule.PartnerUser__c, rule.Assign_To_Partner__c,leadMap);
        
                            objLead.Assignment_Error__c ='';
                            objLead.Dummy_Field__c = '2';
                            leads.remove(i);
                            i--;                           
                            zipFlag = true;
                            incrementRuleFlag= true;
                            ownerfound = true;
                            continue;
                        }      
                    }
                }  
                for(LeadRules__c rule: ruleZIPMap.get(objLead.Iso_Country_Code__c) )
                {
                    System.debug('here lead'+objLead);
                    if(!incrementRuleFlag)
                    {
                    /*
                    * Checking if the Lead's Zip code lies in a Zip code range rule.
                    */
                    system.debug('rule flag:'+incrementRuleFlag);
                    system.debug('ruleflag lead is:'+objLead);
                    if (objLead.PostalCode != null &&(rule.Starting_Range__c!= null 
                        && ((Integer.valueOf(objLead.PostalCode.replaceAll(' ','').substring(0,5))>Integer.valueOf(rule.Starting_Range__c)
                                && Integer.valueOf(objLead.PostalCode.replaceAll(' ','').substring(0,5))<Integer.valueOf(rule.Ending_Range__c)) 
                            || objLead.PostalCode.replaceAll(' ','').substring(0,5).equals(rule.Ending_Range__c)
                            || objLead.PostalCode.replaceAll(' ','').substring(0,5).equals(rule.Starting_Range__c))))
                        {
                            system.debug('lead 8 is:'+objLead);
                            objLead.OwnerId = getOwnerId(objLead,rule.Assign_To__c,rule.User__c, rule.PartnerQueue__c
                                                            ,rule.PartnerUser__c, rule.Assign_To_Partner__c,leadMap);
    
                            objLead.Assignment_Error__c ='';
                            objLead.Dummy_Field__c = '2';
                            leads.remove(i);
                            i--;                       
                            zipFlag = true;
                            ownerfound = true;
                            continue;
                        }
                    }    
                }
                
             if(leads.size() ==0) return;
                //boolean ownerfound = false;
             system.debug('ruleZIPMap.get(objLead.Iso_Country_Code__c is:'+ruleZIPMap.get(objLead.Iso_Country_Code__c));   
             for(LeadRules__c ruleAll : ruleZIPMap.get(objLead.Iso_Country_Code__c))
             {
                system.debug('zip flag:'+zipFlag);
                system.debug('ruleAll.Zip_Code__c is:'+ruleAll.Zip_Code__c);
                if(!zipFlag)
                {
                    if(ruleAll.Zip_Code__c=='ALL')
                    {
                        system.debug('lead 9 is:'+objLead);
                        objLead.OwnerId = getOwnerId(objLead,ruleAll.Assign_To__c,ruleAll.User__c, ruleAll.PartnerQueue__c
                                                                ,ruleAll.PartnerUser__c, ruleAll.Assign_To_Partner__c,leadMap);

                        objLead.Assignment_Error__c ='';
                        objLead.Dummy_Field__c = '2';
                        ownerfound =true;
                        leads.remove(i);
                        i--;
                        continue;
                    }
                }                    
             }  
                
             if(!ownerfound )
             {
                 objLead.OwnerId = objLead.OwnerId = leadMap.getQueueId(GLOBAL_LEAD_ROUTING_ERROR);
                 objLead.Assignment_Error__c ='LATAM Zip Code Rule is not set up';
                 objLead.Dummy_Field__c = '2';
                 leads.remove(i);
                 i--;
                 continue;

             }
         }
           // End -- Zip Code rule added as part of LATAM GLR enhancement - Oct. Release '10 
           
           if(leads.size() ==0) return;
            if(!ownerfound  && !zipFlag && !incrementRuleFlag)
            {
               system.debug('rule map is:'+ruleMap);
               if(ruleMap.containsKey('ALL'))
               {
                       LeadRules__c rule = ruleMap.get('ALL');
                       system.debug('lead 10 is:'+objLead);
                       objLead.OwnerId = getOwnerId(objLead,rule.Assign_To__c,rule.User__c, rule.PartnerQueue__c
                                                            ,rule.PartnerUser__c, rule.Assign_To_Partner__c,leadMap);

                       objLead.Assignment_Error__c ='';
                       objLead.Dummy_Field__c = '2';
                       leads.remove(i);
                       i--;
                       continue;
               }
            
            //populate global lead routing error
            if(leads.size() ==0) return;
            system.debug('lead 11 is:'+objLead);
            objLead.OwnerId = leadMap.getQueueId(GLOBAL_LEAD_ROUTING_ERROR);
            objLead.Assignment_Error__c = 'LATAM Country rule is not set up' ;
            objLead.Dummy_Field__c = '2';
            }
            }
            catch(System.TypeException e)
            {
                objLead.OwnerId = leadMap.getQueueId(GLOBAL_LEAD_ROUTING_ERROR);
                objLead.Assignment_Error__c = 'Zip Code has special characters.' ;
                objLead.Dummy_Field__c = '2';
            }
            catch(System.ListException e)
            {
                  objLead.OwnerId = leadMap.getQueueId(GLOBAL_LEAD_ROUTING_ERROR);
                  objLead.Dummy_Field__c = '2';
                  objLead.Assignment_Error__c = 'Multiple zip code rules exist to route this Lead.' ;
            }
        }
    }
        
}
    Map<String, List<AccountTeamMember>> teamMemberMap= new Map<String, List<AccountTeamMember>>();
    
    // This method is responsible to provide a map of Team Member in associated Account of the rule.
    
    public Map<String, List<AccountTeamMember>> getTeamMemberMap (List<String> accountList)
    {   
            
            AccountTeamMember[] teams= [Select Id, TeamMemberRole, UserId, AccountId from AccountTeamMember where AccountId IN :accountList];
                    
                    if(teams.size()>0)
                    {   
                        for(AccountTeamMember team:teams)
                        {                   
                            List<AccountTeamMember> tempList= new List<AccountTeamMember>();
                            //String tempAccountID=null;
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
      
    // This method actually assigns Owner to the lead which satisfy condition in a particular rule.
    
    public String getOwnerId(Lead objLead, String queueId,String userId,String partnerQueueId,String partnerUserId, String accountTeamRole, String accountOwner, String accountId, boolean assignToPartner,leadMap leadMap, Map<String,List<AccountTeamMember>> teamMap)
    {
            String ownerId = '';
            String ownerIdFromteamRole=null;
            String tempAccountID=null;
            String userName=null;
            Integer j=0; 
            List<AccountTeamMember> teamMemberIdList=new List<AccountTeamMember>();
            system.debug('team memberis:'+objLead);
            system.debug('team memberis1:'+objLead.Partner_Opt_in__c);
            system.debug('team memberis2:'+assignToPartner );
            if(assignToPartner && objLead.Partner_Opt_in__c)
            {
                if(partnerUserId != null && partnerUserId.length()>0)   ownerId = partnerUserId;
                if(partnerQueueId != null && partnerQueueId.length()>0) ownerId = partnerQueueId;
            }
            else
            {
              
                if(accountTeamRole != null)
                {
                    if(accountTeamRole=='Account Owner')
                    {
                        ownerId = accountOwner;
                    }
                    else            
                    {
                 
                        if(teamMap.containsKey(accountId))
                        {
                            teamMemberIdList=teamMap.get(accountId);
                                                        
                            for(Integer i=0; i<teamMemberIdList.size(); i++)
                            {
                                AccountTeamMember accTeam = new AccountTeamMember();
                                accTeam=teamMemberIdList.get(i);
                                if(accTeam.TeamMemberRole==accountTeamRole)
                                { 
                                   j++;                                                            
                                   userName=accTeam.UserId;        
                                }
                            }
                        if(j>0)
                            {
                                if(j==1)
                                {
                                    ownerId=userName;
                                    
                                }
                                else
                                {
                                    ownerId=GLOBAL_LEAD_ROUTING_ERROR;
                                    objLead.Assignment_Error__c ='There is more than one user listed as a specific Account Team role referenced on the routing rule. Lead Assignment Source : GLOBAL_LEAD_ROUTING_ERROR';
                                    objLead.Dummy_Field__c = '2';
                                }
                            }
                            else
                            {
                                    ownerId=GLOBAL_LEAD_ROUTING_ERROR;
                                    objLead.Assignment_Error__c ='There is no user listed as a specific Account Team role referenced on the routing rule. Lead Assignment Source : GLOBAL_LEAD_ROUTING_ERROR';
                                    objLead.Dummy_Field__c = '2';
                            }

                        }
                        
                        else
                        {
                                    ownerId=GLOBAL_LEAD_ROUTING_ERROR;
                                    objLead.Assignment_Error__c ='There is no user listed as a specific Account Team role referenced on the routing rule. Lead Assignment Source : GLOBAL_LEAD_ROUTING_ERROR';
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
    
    public String getOwnerId(Lead objLead,String queueId,String userId, String partnerQueueId,String partnerUserId, boolean assignToPartner,LeadMap leadMap)
    {
        String ownerId = '';

        if(assignToPartner && objLead.Partner_Opt_in__c)
        {
            if(partnerUserId != null && partnerUserId.length()>0)   ownerId = partnerUserId;
            if(partnerQueueId != null && partnerQueueId.length()>0) ownerId = partnerQueueId;
        }
        else
        {
            if(userId != null && userId.length()>0) ownerId = userId;
            if(queueId != null && queueId.length()>0)   ownerId = queueId;
        }

        if(!ownerId.startsWith('005')) ownerId =  leadMap.getQueueId(ownerId);

        return ownerId;
    }

}