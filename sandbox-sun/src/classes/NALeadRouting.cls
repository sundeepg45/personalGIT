/**
* Class Name:NALeadRouting
* Author:Accenture
* Description:Used for assigning Owner to a NA region Lead through GLR process.
* Modificaton History:
* Modified By : Nitesh Dokania
* Modified date :5/3/2011
* Reason for Modification:Separated test class from business class.
*/

public class NALeadRouting 
{
    public String PARTNER_ACCOUNT = 'Partner Account';
    public String NAMED_ACCOUNT = 'Named Account';
    public String FED_SALES='FED Sales';
    public String SLED_SALES='SLED Sales';
    public String TERRITORY='Territory List';
    public String EMAIL_DOMAIN='Email Domain';
    public String NEW_BUSINESS_NA_STATE='New Business State';
    public String NEW_BUSINESS_NCAL='New Business North Cal';
    public String NEW_BUSINESS_SCAL='New Business South Cal';
    public String NEW_BUSINESS_REVENUE='New Business Revenue';
    public String NEW_COMMERCIAL='NA Commercial'; 
    public String SLED_NA_STATE='SLED State';
    public String EDU_NA_STATE='EDU State';
    public String GLR ='GLOBAL LEAD ROUTING';
    public static String SALES_DEV_QUEUE='NA Sales Dev'; 
    public static String NEW_BUSINESS_QUEUE='NA New Business Queue';
    public static String FED_QUEUE='NA Fed Sales Queue';
    public static String SLED_QUEUE='NA Sled Sales Queue';
    public static String EDU_QUEUE='NA EDU Queue';
    public static Map<String,String> deployemailatMap = new Map<String,String>();
    public static Map<String,String> deployemaildotMap = new Map<String,String>();
    public Map<String,LeadRules__c> emailRulesMap= new Map<String,LeadRules__c>();
    public Map<String,LeadRules__c> newcommRulesMap= new Map<String,LeadRules__c>();

public void assignQueue(List<Lead> leads, Map<String,String> companyMap,Map<String,String> instateMap, Map<String,String>emailMap, LeadMap leadMap,Map<String,String>naatEmailMap,Map<String,String>naDotEmailMap)
{
		System.debug('atEmail'+naatEmailMap);
        Map<String,LeadAccountRules__c> partnerMap = new Map<String,LeadAccountRules__c>();
        List<Lead> fedsledList= new List<Lead>();
        List<Lead> eduList= new List<Lead>();
        Map<String,String> stateMap = new Map<String,String>();
        boolean blnsled = false;
        boolean blnedu = false;
        String ownerIdString='';
        String sledQueueId = leadMap.getQueueId(SLED_QUEUE);
        String eduQueueId = leadMap.getQueueId(EDU_QUEUE);
        List<String> accList= new List<String>();
        List<String> partnerAccList= new List<String>();
        Map<String,List<AccountTeamMember>> partnertempMap = new Map<String,List<AccountTeamMember>>();         
            
        //Partner account checkes 
        LeadAccountRules__c[] partners=[Select Assign_To__c
                                            ,Value__c
                                            ,User__c,Assign_To_Partner__c,PartnerQueue__c,PartnerUser__c,Assign_To_Account_Team_Role__c,Account__r.Id, Account__r.OwnerId
                                            from LeadAccountRules__c
                                            where Value__c IN :companyMap.values()
                                            and SuperRegion__c='NA' and Type__c=:PARTNER_ACCOUNT];

     
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
                    objLead.OwnerId = getOwnerId(objLead, accRule.Assign_To__c,accRule.User__c, accRule.PartnerQueue__c
                                                        ,accRule.PartnerUser__c,accRule.Assign_To_Account_Team_Role__c, accRule.Account__r.OwnerId, accRule.Account__r.Id, accRule.Assign_To_Partner__c,leadMap, partnertempMap);
                    
                    ownerIdString=objLead.OwnerId;
                    if(objLead.Assignment_Error__c == null || (ownerIdString.startsWith('005')))
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


            //Named Account Map
            Map<String,LeadAccountRules__c> namedAccountMap = new Map<String,LeadAccountRules__c>();
            Map<String,LeadAccountRules__c> fledMap = new Map<String,LeadAccountRules__c>();
            Map<String,LeadAccountRules__c> sledMap = new Map<String,LeadAccountRules__c>();
            Map<String,LeadAccountRules__c> territoryMap = new Map<String,LeadAccountRules__c>();
            Map<String,List<AccountTeamMember>> teamMemberMap = new Map<String,List<AccountTeamMember>>();

            LeadAccountRules__c[] accounts =[select Id, Account__r.Name, Account__r.Id, Account__r.OwnerId,State__c ,Country__c,Assign_To__c,User__c,Assign_To_Account_Team_Role__c,Value__c,Type__c ,Assign_To_Partner__c,PartnerQueue__c,PartnerUser__c
                            from LeadAccountRules__c where
                (Type__c=:NAMED_ACCOUNT OR Type__c=:FED_SALES OR Type__c=:SLED_SALES OR Type__c='Territory List' )
                and SuperRegion__c='NA'
                AND  Value__c IN :companyMap.values() ];

            String accountAlias = '';

            for(LeadAccountRules__c accountRule:accounts)
            {

                if(accountRule.Assign_To_Account_Team_Role__c != null)
                {
                    accList.add(accountRule.Account__r.Id);
                }
                if(accountRule.State__c != null)
                {
                    accountAlias = accountRule.Value__c+ '#$:' +accountRule.State__c ;
                }
                else
                {
                    accountAlias = accountRule.Value__c;
                }

                if(accountRule.Type__c == NAMED_ACCOUNT)
                {
                    //for named account Country is used
                    if(accountRule.Country__c != null)
                    {
                        accountAlias = accountAlias + accountRule.Country__c;
                    }
                    namedAccountMap.put(accountAlias.toUpperCase(),accountRule);
                }
                else if(accountRule.Type__c == FED_SALES)
                {
                    //for fled account Country is used
                    if(accountRule.Country__c != null)
                    {
                        accountAlias = accountAlias + accountRule.Country__c;
                    }

                    fledMap.put(accountAlias.toUpperCase(),accountRule);
                }
                else if(accountRule.Type__c == SLED_SALES)
                {
                    sledMap.put(accountAlias.toUpperCase(),accountRule);
                }

                else if(accountRule.Type__c == TERRITORY)
                {
                    territoryMap.put(accountAlias.toUpperCase(),accountRule);
                }
            }
            
           teamMemberMap=getTeamMemberMap(accList);

            objLead = null;
            String state = '';
            String companyState='';
            String company='';
            String country = '';
            String companyStateCountry = '';
            String companyCountry = '';

            for(Integer i=0;i<leads.size();i++)
            {

                objLead = leads.get(i);
                state = objLead.State;
                if(state != null) state = state.toUpperCase();
                company = objLead.Company.toUpperCase();
                companyState = company + '#$:' + state;
                country = objLead.Iso_Country_Code__c;
                companyStateCountry= companyState+country.toUpperCase();
                companyCountry = company.toUpperCase()+country.toUpperCase();
                if(namedAccountMap.containsKey(companyStateCountry))
                {

                    LeadAccountRules__c accRule = namedAccountMap.get(companyStateCountry);
                    objLead.OwnerId = getOwnerId(objLead, accRule.Assign_To__c,accRule.User__c,
                                                            accRule.PartnerQueue__c,accRule.PartnerUser__c,accRule.Assign_To_Account_Team_Role__c   
                                                            ,accRule.Account__r.OwnerId, accRule.Account__r.Id, accRule.Assign_To_Partner__c,leadMap, teamMemberMap);

                    ownerIdString=objLead.OwnerId;
                    if(objLead.Assignment_Error__c == null || (ownerIdString.startsWith('005')))
                    {
                        objLead.Assignment_Error__c ='';
                    }
                    objLead.Dummy_Field__c = '2';
                    leads.remove(i);
                    i--;
                    continue;
                }
                //now check for master set up for country
                if(namedAccountMap.containsKey(companyCountry))
                {
                    LeadAccountRules__c accRule = namedAccountMap.get(companyCountry);
                    objLead.OwnerId = getOwnerId(objLead, accRule.Assign_To__c,accRule.User__c,
                                                            accRule.PartnerQueue__c,accRule.PartnerUser__c,accRule.Assign_To_Account_Team_Role__c   
                                                            ,accRule.Account__r.OwnerId, accRule.Account__r.Id, accRule.Assign_To_Partner__c,leadMap, teamMemberMap);
    
                    ownerIdString=objLead.OwnerId;
                    if(objLead.Assignment_Error__c == null || (ownerIdString.startsWith('005')))
                    {
                        objLead.Assignment_Error__c ='';
                    }
                    objLead.Dummy_Field__c = '2';
                    leads.remove(i);
                    i--;
                    continue;
                }
                //check for master set up for region
                if(namedAccountMap.containsKey(company))
                {
                    LeadAccountRules__c accRule = namedAccountMap.get(company);

                    objLead.OwnerId = getOwnerId(objLead, accRule.Assign_To__c,accRule.User__c,
                                                            accRule.PartnerQueue__c,accRule.PartnerUser__c,accRule.Assign_To_Account_Team_Role__c,accRule.Account__r.OwnerId, accRule.Account__r.Id, accRule.Assign_To_Partner__c,leadMap, teamMemberMap);


                    ownerIdString=objLead.OwnerId;
                    if(objLead.Assignment_Error__c == null || (ownerIdString.startsWith('005')))
                    {
                        objLead.Assignment_Error__c ='';
                    }
                    objLead.Dummy_Field__c = '2';
                    leads.remove(i);
                    i--;
                    continue;
                }

                 

                if(fledMap.containsKey(companyCountry))
                {
                    LeadAccountRules__c accRule =  fledMap.get(companyCountry);
                    objLead.OwnerId = getOwnerId(objLead, accRule.Assign_To__c,accRule.User__c,
                                                            accRule.PartnerQueue__c,accRule.PartnerUser__c,accRule.Assign_To_Account_Team_Role__c   
                                                            ,accRule.Account__r.OwnerId,accRule.Account__r.Id, accRule.Assign_To_Partner__c,leadMap, teamMemberMap);

                    ownerIdString=objLead.OwnerId;
                    if(objLead.Assignment_Error__c == null || (ownerIdString.startsWith('005')))
                    {
                        objLead.Assignment_Error__c ='';
                    }
                    objLead.Dummy_Field__c = '2';
                    leads.remove(i);
                    i--;
                    continue;
                }
                
                  

                if(fledMap.containsKey(company))
                {
                    LeadAccountRules__c accRule =  fledMap.get(company);
                    objLead.OwnerId = getOwnerId(objLead,accRule.Assign_To__c,accRule.User__c,
                                                            accRule.PartnerQueue__c,accRule.PartnerUser__c,accRule.Assign_To_Account_Team_Role__c   
                                                            ,accRule.Account__r.OwnerId, accRule.Account__r.Id, accRule.Assign_To_Partner__c,leadMap, teamMemberMap);

                    ownerIdString=objLead.OwnerId;
                    if(objLead.Assignment_Error__c == null || (ownerIdString.startsWith('005')))
                    {
                        objLead.Assignment_Error__c ='';
                    }
                    objLead.Dummy_Field__c = '2';
                    leads.remove(i);
                    i--;
                    continue;
                }


                if(sledMap.containsKey(companyState))
                {
                    LeadAccountRules__c accRule =  sledMap.get(companyState);
                    objLead.OwnerId = getOwnerId(objLead,accRule.Assign_To__c,accRule.User__c,
                                                            accRule.PartnerQueue__c,accRule.PartnerUser__c,accRule.Assign_To_Account_Team_Role__c   
                                                            ,accRule.Account__r.OwnerId, accRule.Account__r.Id, accRule.Assign_To_Partner__c,leadMap, teamMemberMap);

                    
                    ownerIdString=objLead.OwnerId;
                    if(objLead.Assignment_Error__c == null || (ownerIdString.startsWith('005')))
                    {
                        objLead.Assignment_Error__c ='';
                    }
                    objLead.Dummy_Field__c = '2';
                    leads.remove(i);
                    i--;
                    if(objLead.OwnerId ==sledQueueId )
                    {
                        fedsledList.add(objLead);
                        stateMap.put(objLead.State,objLead.State);
                        blnsled = true;
                    }
                    
                    if(objLead.OwnerId ==eduQueueId )
                    {
                        eduList.add(objLead);
                        stateMap.put(objLead.State,objLead.State);
                        blnedu = true;
                    }
                    continue;
                }

                if(territoryMap.containsKey(companyState))
                {
                    LeadAccountRules__c accRule =  territoryMap.get(companyState);
                    objLead.OwnerId = getOwnerId(objLead,accRule.Assign_To__c,accRule.User__c,
                                                            accRule.PartnerQueue__c,accRule.PartnerUser__c,accRule.Assign_To_Account_Team_Role__c   
                                                            ,accRule.Account__r.OwnerId,accRule.Account__r.Id,accRule.Assign_To_Partner__c,leadMap, teamMemberMap);

                    ownerIdString=objLead.OwnerId;
                    if(objLead.Assignment_Error__c == null || (ownerIdString.startsWith('005')))
                    {
                        objLead.Assignment_Error__c ='';
                    }
                    objLead.Dummy_Field__c = '2';
                    leads.remove(i);
                    i--;
                    continue;
                }
            }

            //if no leads in the list then return.
            if(leads.size() ==0 && !blnsled ) return;



            //check the email domain rule
            LeadRules__c[] rules=[Select Assign_To__c
                                        , Type__c
                                        , Value__c
                                        ,User__c
                                        , Country__c,Assign_To_Partner__c,PartnerQueue__c,PartnerUser__c
                                        from LeadRules__c 
                                        where (Value__c IN:naatEmailMap.values() OR Value__c IN:nadotEmailMap.values()) and SuperRegion__c='NA'
                                        and Type__c=:EMAIL_DOMAIN ];



        for(LeadRules__c emailRulesobj:rules)
        {
                emailRulesMap.put(emailRulesobj.Value__c.toUpperCase(),emailRulesobj);
        }
        
        String emailIdRule = '';
        String emailId;
        boolean match = false;
        for(Integer i=0;i<leads.size();i++)
            {
                objLead=leads.get(i);
                System.debug('email lead'+objLead);
                System.debug('email rule'+rules);
                match = false;
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
                                
                                objLead.OwnerId = getOwnerId(objLead,rule.Assign_To__c,
                                    rule.User__c, rule.PartnerQueue__c,rule.PartnerUser__c,null,null,
                                        null, rule.Assign_To_Partner__c,leadMap, teamMemberMap);
                                objLead.Assignment_Error__c ='';
                                objLead.Dummy_Field__c = '2';
                                match = true;
                                leads.remove(i);
                                i--;
                        }
     
                if(emailRulesMap.containsKey(emailId) && !match)
                {
                                LeadRules__c rule =emailRulesMap.get(emailId);
                                objLead.OwnerId = getOwnerId(objLead, rule.Assign_To__c,
                                    rule.User__c, rule.PartnerQueue__c,rule.PartnerUser__c,null,null,
                                        null, rule.Assign_To_Partner__c,leadMap, teamMemberMap);
                               objLead.Assignment_Error__c ='';
                                objLead.Dummy_Field__c = '2';
                                match = true;
                                leads.remove(i);
                                i--;
                                 
                }

                
                if(objLead.OwnerId ==sledQueueId )
                {
                    fedsledList.add(objLead);
                    stateMap.put(objLead.State,objLead.State);
                    blnsled = true;
                }
                if(objLead.OwnerId ==eduQueueId )
                {
                    eduList.add(objLead);
                    stateMap.put(objLead.State,objLead.State);
                    blnedu = true;
                }

            } 
        //Check for lead owners. If Owner is SLED or EDU queue then execute EDU or SLED State rule
        if(blnsled)
        {
            sledTerritory(fedsledList,stateMap,leadMap);
        }
        if(blnedu)
        {
            eduTerritory(eduList,stateMap,leadMap);
        }


            
         //check the New Commercial rule
 
        state = '';
        Double revenue;
        String zipCode = '';
        String product = '';
        
        List<LeadRules__c> nwCommList = new List<LeadRules__c>();
        List<LeadRules__c> nwDefaultRuleList = new List<LeadRules__c>();

            LeadRules__c[] commrules=[Select Assign_To__c, Assign_To_Partner__c, Id,New_Business_Assign_To__c, New_Business_Partner_User__c, Product_Of_Interest__c, Revenue__c, Territory_Assign_to__c, Territory_Partner_User__c, Type__c, Value__c, Zip_Code__c
                                  from LeadRules__c 
                                  where (Value__c IN:instateMap.values()) and SuperRegion__c='NA'
                                  and Type__c=:NEW_COMMERCIAL];

        System.debug('NA CommercialRule'+commrules.size());
        for(LeadRules__c commruleobj:commrules)
        {                
              if(commruleobj.Zip_Code__c != null)
            {  
              newcommRulesMap.put(commruleobj.Value__c.toUpperCase(),commruleobj);
              nwCommList.add(commruleobj);
            }
             else
            {
               
                nwDefaultRuleList.add(commruleobj);
            }
        }
  		System.debug('default rule list'+nwDefaultRuleList);

          //now parse through the leads and assign
             boolean errorMsg = true;
        for(Integer i=0;i<leads.size();i++)
        {
            System.debug('lead sizeee'+leads.size());
            Boolean DefaultFlag=false;
            objLead = leads.get(i);
            state = objLead.State;
            zipCode = objLead.PostalCode;
            revenue = objLead.AnnualRevenue;
              
            //this is formula value based on Lead product value. 
            if(objLead.Primary_ProductFormula__c != null)
            {
                product= (objLead.Primary_ProductFormula__c).toUpperCase();
            }        
            errorMsg = false;
            
            if(zipCode == null) zipCode = '';
           
            if(state != null) state = state.toUpperCase();
            else
            {
                objLead.OwnerId = leadMap.getQueueId(SALES_DEV_QUEUE);
                objLead.Assignment_Error__c =' State is missing from the lead. Lead Assignment Source : NA Sales Dev Queue';
                objLead.Dummy_Field__c = '2';
                leads.remove(i);
                i--;
                continue;
            }
            if(revenue == null)
                {
                    //put it in sales dev queue with error.
                    System.debug('revenue found null');
                    objLead.OwnerId = leadMap.getQueueId(SALES_DEV_QUEUE);
                    objLead.Assignment_Error__c =' Revenue is missing from the lead. Lead Assignment Source : NA Sales Dev Queue';
                    objLead.Dummy_Field__c = '2';
                    leads.remove(i);
                    i--;
                    continue;
                 }                   
              
             
             for(LeadRules__c nwrule: nwCommList)
                    {
                        System.debug('lead exe'+objLead);
                        System.debug('rule exe'+nwrule);
                        System.debug('rule size'+nwCommList.size());
                        System.debug('pdtss'+objLead.Primary_ProductFormula__c);
                        System.debug('pdts of interest'+objLead.Products_of_Interest__c);
                        String ruleProduct='';
                        if((nwrule.Product_Of_Interest__c)!=null)
                        {
                              ruleProduct = (nwrule.Product_Of_Interest__c).toUpperCase();  
                        }
                                   
                        if(nwrule.Value__c == objLead.State)
                                {
                                     if(objLead.PostalCode == null && nwrule.Zip_Code__c != null)  
                                        {
                                                objLead.OwnerId = leadMap.getQueueId(SALES_DEV_QUEUE);
                                                objLead.Assignment_Error__c =' The Zip Code is missing from the Lead. Lead Assignment Source : New Commercial Rule';
                                                objLead.Dummy_Field__c = '2';
                                                leads.remove(i);
                                                i--;
                                                errorMsg = true;
                                                break;
                                        }                                 
                                   if(revenue >= nwrule.Revenue__c)
                                        {
                                           System.debug('revenue chk'+nwrule);
                                           if(nwrule.Assign_To_Partner__c)
                                            {                                              
                                              
                                               if((nwrule.Zip_Code__c.indexOf(objLead.PostalCode) > -1)&& (nwrule.Zip_Code__c.contains(zipCode)) && (objLead.PostalCode.length() > 4) && (ruleProduct== product))
                                                  {
                                                     
                                                    
                                                    objLead.OwnerId = getOwnerId(objLead,nwrule.Territory_Assign_to__c,nwrule.Territory_Partner_User__c,null,null,nwrule.Assign_To_Partner__c,leadMap);
                                                  
                                                    objLead.Assignment_Error__c ='';
                                                    objLead.Dummy_Field__c = '2';
                                                    errorMsg = true;
                                                    break;  
                                                 }
                                            }
                                            else
                                            {     
                                            	System.debug('>>>>'+nwrule.Zip_Code__c.contains(zipCode));
                                            	System.debug('lead name'+objlead);                                     
                                                  if((nwrule.Zip_Code__c.indexOf(objLead.PostalCode) > -1)&& (nwrule.Zip_Code__c.contains(zipCode)) && (objLead.PostalCode.length() > 4) && (ruleProduct== product))
                                                   {
                                                         objLead.OwnerId = getOwnerId(objLead,nwrule.Territory_Assign_to__c,null,null,null,nwrule.Assign_To_Partner__c,leadMap);
                                                         objLead.Assignment_Error__c ='';
                                                         objLead.Dummy_Field__c = '2';
                                                         errorMsg = true;
                                                         break;
                                                    }
                                            }    
                                    }                                               
                              else
                                {
                                        //modified logic for less than thresold with product match case....                                      
                                         System.debug('revenue chk'+nwrule);
                                         if(nwrule.Assign_To_Partner__c)
                                            { 
                                               if((nwrule.Zip_Code__c.indexOf(objLead.PostalCode) > -1) && (nwrule.Zip_Code__c.contains(zipCode)) && (objLead.PostalCode.length() > 4) && (ruleProduct== product))
                                                  {
                                                        
                                                        objLead.OwnerId = getOwnerId(objLead,null,null,nwrule.New_Business_Assign_To__c,nwrule.New_Business_Partner_User__c,nwrule.Assign_To_Partner__c,leadMap);
                                                        objLead.Assignment_Error__c ='';
                                                        objLead.Dummy_Field__c = '2';
                                                        errorMsg = true;
                                                        break; 
                                                 }
                                            }
                                            else
                                            {   
                                                    if((nwrule.Zip_Code__c.indexOf(objLead.PostalCode) > -1) && (nwrule.Zip_Code__c.contains(zipCode)) && (objLead.PostalCode.length() > 4) && (ruleProduct== product))
                                                   {
                                                         
                                                         objLead.OwnerId = getOwnerId(objLead,null,null,nwrule.New_Business_Assign_To__c,null,nwrule.Assign_To_Partner__c,leadMap);
                                                         objLead.Assignment_Error__c ='';
                                                         objLead.Dummy_Field__c = '2';
                                                         errorMsg = true;
                                                         break;
                                                    }
                                            } 
                                    
                     
                                }           
                                
                            }               
                    }  
    
            //this conditions checks whether lead is not matched in above conditions and will go for defalut rule check.
             if((objLead.OwnerId ==leadMap.getQueueId(SALES_DEV_QUEUE)) || (objLead.OwnerId ==leadMap.getQueueId(GLR)))
            {
                DefaultFlag=true;
                
            }
        System.debug('>>>>now default rule');
            //checking default rules 
             if(DefaultFlag)
            {
                for(LeadRules__c nwrule: nwDefaultRuleList)
                    {
                        String ruleProduct='';
                        if((nwrule.Product_Of_Interest__c)!=null)
                        {
                              ruleProduct = (nwrule.Product_Of_Interest__c).toUpperCase();  
                        }
						System.debug('default rule'+nwrule);
						System.debug('default lead'+objLead);
                        if(nwrule.Value__c == objLead.State)
                        {                                       

                           if(revenue >= nwrule.Revenue__c)
                            {
                                if(nwrule.Assign_To_Partner__c)
                                    { 
                                       
                                       if(ruleProduct == product)
                                          {
                                                objLead.OwnerId = getOwnerId(objLead,nwrule.Territory_Assign_to__c,nwrule.Territory_Partner_User__c,null,null,nwrule.Assign_To_Partner__c,leadMap);
                                                objLead.Assignment_Error__c ='';
                                                objLead.Dummy_Field__c = '2';
                                                errorMsg = true;
                                                break;  
                                         }
                                    }
                                else
                                    {   
                                      
                                            if(ruleProduct == product)
                                           {
                                                 objLead.OwnerId = getOwnerId(objLead,nwrule.Territory_Assign_to__c,null,null,null,nwrule.Assign_To_Partner__c,leadMap);
                                                 objLead.Assignment_Error__c ='';
                                                 objLead.Dummy_Field__c = '2';
                                                 errorMsg = true;
                                                 break;
                                            }
                                    }    
                             }                                               
                            else
                            {     
                                 //modified logic for default rule and revenue less than threshold...                                             
                                             
                                if(nwrule.Assign_To_Partner__c)
                                { 
                                    if(ruleProduct == product)
                                     {
                                            objLead.OwnerId = getOwnerId(objLead,null,null,nwrule.New_Business_Assign_To__c,nwrule.New_Business_Partner_User__c,nwrule.Assign_To_Partner__c,leadMap);
                                            objLead.Assignment_Error__c ='';
                                            objLead.Dummy_Field__c = '2';
                                            errorMsg = true;
                                            break;
                                     }
                                }
                                else
                                {   
                                    if(ruleProduct == product)
                                       {
                                            
                                             objLead.OwnerId = getOwnerId(objLead,null,null,nwrule.New_Business_Assign_To__c,null,nwrule.Assign_To_Partner__c,leadMap);
                                             objLead.Assignment_Error__c ='';
                                             objLead.Dummy_Field__c = '2';
                                             errorMsg = true;
                                             break;
                                        }
                                }                 

                             }  
                        }
                        
                    }       
                }
 //===================================================================           
       //   this bracket is for loop, which is removed and moved up at line 345


                if(errorMsg)
                {
                //put it in sales dev queue with error.
                      if((objLead.OwnerId == leadMap.getQueueId(SALES_DEV_QUEUE))&&(objLead.Assignment_Error__c == ''))
                      {
                        objLead.Assignment_Error__c ='There is no routing rule setup for the specified criteria in the lead. Lead Assignment Source: New Commercial Rule';
                        objLead.Dummy_Field__c = '2';
                      }
                
                
                    continue;
                }



               if(!match)
                {
                    objLead.OwnerId = leadMap.getQueueId(SALES_DEV_QUEUE);
                      if((objLead.Assignment_Error__c == '')||(objLead.Assignment_Error__c == null))
                        objLead.Assignment_Error__c ='There is no routing rule setup for the specified criteria in the lead. Lead Assignment Source: New Commercial Rule';
                    objLead.Dummy_Field__c = '2';
                     
                }
                


                if(objLead.OwnerId ==sledQueueId )
                {
                    fedsledList.add(objLead);
                    stateMap.put(objLead.State,objLead.State);
                    blnsled = true;
                }
                if(objLead.OwnerId ==eduQueueId )
                {
                    eduList.add(objLead);
                    stateMap.put(objLead.State,objLead.State);
                    blnedu = true;
                }
        
        }
            //If Lead owner is SLED QUEUE then execute 'SLED State' rule
            if(blnsled)
            {
                 sledTerritory(fedsledList,stateMap,leadMap);
            }
            //If Lead owner is EDU QUEUE then execute 'EDU State' rule
            if(blnedu)
            {
                eduTerritory(eduList,stateMap,leadMap);
            }
}


public void newBusiness(List<Lead> leads, Map<String,String> stateMap,LeadMap leadMap)
{
        boolean california = false;
        Map<String, List<AccountTeamMember>> tempMap= new Map<String, List<AccountTeamMember>>();
        LeadRules__c[] rules=[Select Assign_To__c
                                    , Type__c
                                    , Value__c
                                    ,User__c
                                    ,Zip_Code__c
                                    ,Revenue__c
                                    ,SMB_Assign_To__c
                                    ,ETR_Assign_To__c
                                    ,ETR_Partner_User__c
                                    ,SMB_Partner_User__c,PartnerQueue__c
                                    ,PartnerUser__c
                                    ,Assign_To_Partner__c
                                    from LeadRules__c
                                    where
                                    (Value__c IN :stateMap.values() OR Value__c = null)  and SuperRegion__c='NA'
                                    and (Type__c=:NEW_BUSINESS_NA_STATE OR Type__c =:NEW_BUSINESS_NCAL OR Type__c =:NEW_BUSINESS_SCAL  OR Type__c=:NEW_BUSINESS_REVENUE)];

        Map<String,LeadRules__c> nbStateMap = new Map<String,LeadRules__c>();
        Map<String,LeadRules__c> nbRevenueMap = new Map<String,LeadRules__c>();
        List<LeadRules__c> nbCaliforniaList = new List<LeadRules__c>();

  System.debug('>>>>now default rule CA*****');
        for(LeadRules__c rule:rules)
        {
                if(rule.Type__c == NEW_BUSINESS_NA_STATE )
                {
                    nbStateMap.put(rule.Value__c.toUpperCase(),rule);
                }
                if(rule.Type__c == NEW_BUSINESS_REVENUE )
                {
                    nbRevenueMap.put(rule.Value__c.toUpperCase(),rule);
                }

                if(rule.Type__c == NEW_BUSINESS_NCAL || rule.Type__c == NEW_BUSINESS_SCAL )
                {
                        nbCaliforniaList.add(rule);
                }
        }
		System.debug('Business rule'+rules);
        String state = '';
        Double revenue;
        LeadRules__c rule ;
        String zipCode = '';
        Lead objLead;
        boolean errorMsg = true;

        //now parse through the leads and assign
        for(Integer i=0;i<leads.size();i++)
        {
            System.debug('business lead'+objlead);
            objLead = leads.get(i);
            state = objLead.State;
            if(state != null) state = state.toUpperCase();
            zipCode = objLead.PostalCode;
            if(zipCode == null) zipCode ='';

            if(state == 'CA')
            {
                errorMsg = true;
                    for(LeadRules__c zip: nbCaliforniaList)
                    {

                        if(zip.Zip_Code__c != null && zip.Zip_Code__c.contains(zipCode))
                        {
                            //now check the revenue;
                            revenue = objLead.AnnualRevenue;

                            if(revenue == null || revenue ==0)
                            {
                                //put it in sales dev queue with error.
                                objLead.OwnerId = leadMap.getQueueId(SALES_DEV_QUEUE);
                                objLead.Assignment_Error__c =' Revenue is missing from the lead. Lead Assignment Source : New Business Queue';
                                objLead.Dummy_Field__c = '2';
                                leads.remove(i);
                                i--;
                                errorMsg = false;
                                break;

                            }

                            if(revenue >= zip.Revenue__c)
                            {
                                objLead.OwnerId = getOwnerId(objLead,null,zip.ETR_Assign_To__c, null
                                                                    ,zip.ETR_Partner_User__c,null,null,null, zip.Assign_To_Partner__c,leadMap, tempMap);

                                objLead.Dummy_Field__c = '2';
                                objLead.Assignment_Error__c ='';
                                errorMsg = false;
                                break;
                            }
                            else
                            {
                                objLead.OwnerId = getOwnerId(objLead,null,zip.SMB_Assign_To__c, null
                                                                    ,zip.SMB_Partner_User__c,null,null,null, zip.Assign_To_Partner__c,leadMap, tempMap);

                                objLead.Assignment_Error__c ='';
                                objLead.Dummy_Field__c = '2';
                                errorMsg = false;
                                break;
                            }

                        }

                    }

                    if(errorMsg)
                    {
                        //put it in sales dev queue with error.
                        objLead.OwnerId = leadMap.getQueueId(SALES_DEV_QUEUE);
                        objLead.Assignment_Error__c =' Zip code set up for california is missing. Lead Assignment Source : New Business Queue';
                        objLead.Dummy_Field__c = '2';

                    }
                    continue;
            }
            revenue = 0;
            if(nbRevenueMap.containsKey(state))
            {
                revenue = objLead.AnnualRevenue;
                if(revenue == null || revenue <0)
                {
                        objLead.OwnerId = leadMap.getQueueId(SALES_DEV_QUEUE);
                        objLead.Assignment_Error__c =' Revenue is missing from the lead. Lead Assignment Source : New Business Queue';
                        objLead.Dummy_Field__c = '2';
                        leads.remove(i);
                        i--;
                        continue;
                }

                rule = nbRevenueMap.get(state);

                if(revenue >= rule.Revenue__c)
                {
                    objLead.OwnerId = getOwnerId(objLead,null,rule.ETR_Assign_To__c, null
                                                        ,rule.ETR_Partner_User__c,null,null,null, rule.Assign_To_Partner__c,leadMap, tempMap);

                    objLead.Assignment_Error__c ='';
                    objLead.Dummy_Field__c = '2';
                    continue;
                }
                else
                {
                    objLead.OwnerId = getOwnerId(objLead,null,rule.SMB_Assign_To__c, null
                                                        ,rule.SMB_Partner_User__c,null,null,null, rule.Assign_To_Partner__c,leadMap, tempMap);
                    objLead.Assignment_Error__c ='';
                    objLead.Dummy_Field__c = '2';
                    continue;
                }
            }

            if(nbStateMap.containsKey(state))
            {
                    LeadRules__c rule1 = nbStateMap.get(state);
                    objLead.OwnerId = getOwnerId(objLead,rule1.Assign_To__c,rule1.User__c, rule1.PartnerQueue__c
                                                        ,rule1.PartnerUser__c,null,null,null, rule1.Assign_To_Partner__c,leadMap, tempMap);

                    objLead.Assignment_Error__c ='';
                    objLead.Dummy_Field__c = '2';
                    continue;
            }
            objLead.OwnerId = leadMap.getQueueId(SALES_DEV_QUEUE);
            objLead.Assignment_Error__c ='State: ' + state+' is not complete for the New Business Queue .';
            objLead.Dummy_Field__c = '2';
        }
}


//SLED territory check

public void sledTerritory(List<Lead> leads, Map<String,String> stateMap,LeadMap leadMap)
{
        System.debug('In SLEDTerr function');
        Map<String, List<AccountTeamMember>> tempMap= new Map<String, List<AccountTeamMember>>();

        LeadRules__c[] rules=[Select Assign_To__c
                                    , Type__c
                                    , Value__c
                                    ,User__c ,Assign_To_Partner__c,PartnerQueue__c,PartnerUser__c
                                    from LeadRules__c
                                    where
                                    Value__c IN :stateMap.values() and SuperRegion__c='NA'
                                    and Type__c=:SLED_NA_STATE];

        Map<String,LeadRules__c> nbStateMap = new Map<String,LeadRules__c>();

        for(LeadRules__c rule:rules)
        {
                    nbStateMap.put(rule.Value__c.toUpperCase(),rule);
        }

        String state = '';
        Lead objLead;
        for(Integer i=0;i<leads.size();i++)
        {
            objLead = leads.get(i);
            state = Util.getUpperCaseValue(objLead.State);
            if(nbStateMap.containsKey(state))
            {
                    LeadRules__c rule = nbStateMap.get(state);
                    objLead.OwnerId = getOwnerId(objLead,rule.Assign_To__c,rule.User__c, rule.PartnerQueue__c
                                                            ,rule.PartnerUser__c,null,null,null, rule.Assign_To_Partner__c,leadMap, tempMap);

                    objLead.Assignment_Error__c ='';
                    objLead.Dummy_Field__c = '2';
                    leads.remove(i);
                    i--;
                    continue;
            }
            objLead.OwnerId = leadMap.getQueueId(SALES_DEV_QUEUE);
            objLead.Assignment_Error__c ='State: '+state+'  setup is not complete for the SLED Sales Queue.  ';
            objLead.Dummy_Field__c = '2';
        }
}

//EDU territory check

public void eduTerritory(List<Lead> leads, Map<String,String> stateMap,LeadMap leadMap)
{
        System.debug('In edduuuuu function');
        Map<String, List<AccountTeamMember>> tempMap= new Map<String, List<AccountTeamMember>>();

        LeadRules__c[] rules=[Select Assign_To__c
                                    , Type__c
                                    , Value__c
                                    ,User__c ,Assign_To_Partner__c,PartnerQueue__c,PartnerUser__c
                                    from LeadRules__c
                                    where
                                    Value__c IN :stateMap.values() and SuperRegion__c='NA'
                                    and Type__c=:EDU_NA_STATE];

        Map<String,LeadRules__c> edStateMap = new Map<String,LeadRules__c>();

        for(LeadRules__c rule:rules)
        {
               edStateMap.put(rule.Value__c.toUpperCase(),rule);
        }

        String state = '';
        Lead objLead;
        for(Integer i=0;i<leads.size();i++)
        {
            objLead = leads.get(i);
            state = Util.getUpperCaseValue(objLead.State);
            if(edStateMap.containsKey(state))
            {
                    LeadRules__c rule = edStateMap.get(state);
                    objLead.OwnerId = getOwnerId(objLead,rule.Assign_To__c,rule.User__c, rule.PartnerQueue__c
                                                            ,rule.PartnerUser__c,null,null,null, rule.Assign_To_Partner__c,leadMap, tempMap);

                    objLead.Assignment_Error__c ='';
                    objLead.Dummy_Field__c = '2';
                    leads.remove(i);
                    i--;
                    continue;
            }
            objLead.OwnerId = leadMap.getQueueId(SALES_DEV_QUEUE);
            objLead.Assignment_Error__c ='State: '+state+'  setup is not complete for the Edu Sales Queue.  ';
            objLead.Dummy_Field__c = '2';
            System.debug('Errror assigned');
        }
}


    public Map<String, List<AccountTeamMember>> getTeamMemberMap (List<String> accountList)
    {   
            
            Map<String, List<AccountTeamMember>> teamMemberMap= new Map<String, List<AccountTeamMember>>();

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
    
    
    public String getOwnerId(Lead objLead, String queueId,String userId,String partnerQueueId,String partnerUserId, String accountTeamRole, String accountOwner, String accountId, boolean assignToPartner,leadMap leadMap, Map<String,List<AccountTeamMember>> teamMap)
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
                                AccountTeamMember a= new AccountTeamMember();
                                a=teamMemberIdList.get(i);
                                if(a.TeamMemberRole==accountTeamRole)
                                { 
                                   j++;                                                            
                                   userName=a.UserId;        
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
                                    ownerId=SALES_DEV_QUEUE;
                                    objLead.Assignment_Error__c ='There is more than one user listed as a specific Account Team role referenced on the routing rule. Lead Assignment Source : NA Sales Dev Queue';
                                    objLead.Dummy_Field__c = '2';
                                }
                            }
                            else
                            {
                                    ownerId=SALES_DEV_QUEUE;
                                    objLead.Assignment_Error__c ='There is no user listed as a specific Account Team role referenced on the routing rule. Lead Assignment Source : NA Sales Dev Queue';
                                    objLead.Dummy_Field__c = '2';
                            }

                        }
                        
                        else
                        {
                                    ownerId=SALES_DEV_QUEUE;
                                    objLead.Assignment_Error__c ='There is no user listed as a specific Account Team role referenced on the routing rule. Lead Assignment Source : NA Sales Dev Queue';
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

    //following function is used to assign owner for NA Commercail Type.
    public String getOwnerId(Lead objLead,String terrUserId,String terrPartnerUserId,String nbUserId,String nbPartnerUserId,boolean assignToPartner,LeadMap leadMap)
    {
        String ownerId = '';
     

        if((assignToPartner && objLead.Partner_Opt_in__c))
        {
            if(terrPartnerUserId != null && terrPartnerUserId.length()>0)   ownerId = terrPartnerUserId;
            if(nbPartnerUserId != null && nbPartnerUserId.length()>0)   ownerId = nbPartnerUserId;
        }
        else
        {       
               if(terrUserId != null && terrUserId.length()>0) ownerId = terrUserId;
               if(nbUserId != null && nbUserId.length()>0) ownerId = nbUserId;
           
        }
        if(ownerId.length() < 1 )
            ownerId = leadMap.getQueueId(SALES_DEV_QUEUE);

        return ownerId;
    }

}