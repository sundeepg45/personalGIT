Global class LeadAssignment
{

public static String GLOBAL_LEAD_ROUTING = 'GLOBAL LEAD ROUTING';
public static String GLOBAL_LEAD_ROUTING_ERROR = 'GLR Error Queue';
public static String NEW_BUSINESS_QUEUE = 'NA New Business Queue';
public static String SLED_SALES_QUEUE = 'NA Sled Sales Queue';
public static String NA_EDU_QUEUE = 'NA EDU Queue';
public static String NA_SALES_DEV_QUEUE = 'NA Sales Dev';

public static LARegion regionMap = new LARegion();
public static LeadMap objleadMap = new LeadMap();
public List<Lead> NAList= new List<Lead>();
public List<Lead> LATAMList= new List<Lead>();
public List<Lead> APACList= new List<Lead>();
public List<Lead> EMEAList= new List<Lead>();

public List<Lead> updateNAList= new List<Lead>();
public List<Lead> updateLATAMList= new List<Lead>();
public List<Lead> updateAPACList= new List<Lead>();
public List<Lead> updateEMEAList= new List<Lead>();
public List<Lead> errorList= new List<Lead>();

public Map<String,String> apacatEmailMap = new Map<String,String>();
public Map<String,String> apacdotEmailMap = new Map<String,String>();

public Map<String,String> emeaatEmailMap = new Map<String,String>();
public Map<String,String> emeadotEmailMap = new Map<String,String>();

public Map<String,String> latamatEmailMap = new Map<String,String>();
public Map<String,String> latamdotEmailMap = new Map<String,String>();

public Map<String,String> naatEmailMap = new Map<String,String>();
public Map<String,String> nadotEmailMap = new Map<String,String>();

public Map<String,LeadRules__c> emailRulesMap= new Map<String,LeadRules__c>();

public Map<String,String> latamCompany = new Map<String,String>();
public Map<String,String> latamCountry = new Map<String,String>();

public Map<String,String> emeaCompany = new Map<String,String>();
public Map<String,String> emeaCountry = new Map<String,String>();

public Map<String,Lead> APACLeads = new Map<String,Lead>();
public Map<String,String> APACCompany = new Map<String,String>();
public Map<String,String> APACCOuntry = new Map<String,String>();
public Map<String,String> APACState = new Map<String,String>();
public List<String> APACId = new List<String>();

public Map<String,String> naCompany = new Map<String,String>();
public Map<String,String> naEmailMap = new Map<String,String>();
public Map<String,String> naStateMap = new Map<String,String>();

public List<Lead> NANBList= new List<Lead>();
public Map<String,String> nbStateMap = new Map<String,String>();

public List<Lead> NASList= new List<Lead>();
public Map<String,String> sStateMap = new Map<String,String>();

public List<Lead> NAEDUList= new List<Lead>();
public Map<String,String> eduStateMap = new Map<String,String>();

public static Map<String,String> ownerIDMap = new Map<String,String>();
public boolean flag=false;
public List<Lead> errorLeads = new List<Lead>();

partnerUserValidation objpartnerUserValidation= new partnerUserValidation();


public void assignLead(Lead[] leads,Boolean isupdate) {

    String isoCode = '';
    Map<String,String> isoCode1 = new Map<String,String>();
    String region = '';
    Map<String,String> region1 = new Map<String,String>();
    String ownerId = '';
    String oldOwner = '';
    
    boolean apac = false;
    boolean emea = false;
    boolean latam = false;
    boolean na= false;
    String emailId = '';
    
    LeadAssignment.objleadMap.setMap();
    Integer count = 1;
    
    
    //
    // interate through the leads so that we can filter our SOQL queries
    //
    
    Set<String> country = new Set<String>();
    for (Lead lead : leads)
    {
    	if (lead.Country != null)
        	country.add(lead.Country.toUpperCase());
    }

    // start---Added for LATAM GLR enhancement nov'10 release
    List<LeadCountryMap__c> regionIsoCode = [SELECT Country__c, ISO_Code__c, Region__c FROM LeadCountryMap__c WHERE Country__c IN :country]; 
    for(LeadCountryMap__c lcm : regionIsoCode)
    {
        isoCode1.put(lcm.Country__c.toUpperCase(),lcm.ISO_Code__c.toUpperCase());
        region1.put(lcm.ISO_Code__c.toUpperCase(),lcm.Region__c);
    }
    // end --- Added for LATAM GLR enhancement nov'10 release
    for(Lead objLead : leads)
    {
        //
        // set the owner id of the lead if we've seen it before
        //
        
        if(ownerIDMap.get(objLead.Id)!=null)
        {
            objLead.ownerID=ownerIDMap.get(objLead.Id);
            objLead.Dummy_Field__c = '2';
            continue;
        }

        boolean triggerLA = false;
        oldOwner = objLead.OwnerId ;
        region = '';
        isoCode = '';
        
        System.debug('Lead Owner: ' + oldOwner);
        
        //
        // determine if the lead is owned by a queue
        //
        
        if(oldOwner == LeadAssignment.objleadMap.getQueueId(LeadAssignment.GLOBAL_LEAD_ROUTING)
        || oldOwner == LeadAssignment.objleadMap.getQueueId(LeadAssignment.NEW_BUSINESS_QUEUE)
        || oldOwner == LeadAssignment.objleadMap.getQueueId(LeadAssignment.SLED_SALES_QUEUE)
        || oldOwner == LeadAssignment.objleadMap.getQueueId(LeadAssignment.NA_EDU_QUEUE))
        {
            System.debug('Lead owned by a queue');
            triggerLA = true;
        }

        //
        // use lead assignment
        //
        if(triggerLA)
        {
            
            //
            // verify we have the required lead data
            //
            
            if(objLead.LastName==null ||objLead.Company==null||objLead.Country==null||objLead.LeadSourceDetail__c==null||objLead.Email==null)
            {
                System.debug('Lead does not have the required data, add it to the errors collection');
                errorLeads.add(objLead);
                
                //objLead.addError('Please make sure Company, Last Name, E-mail, and Country is populated before assigning the lead to the Global Lead Routing Queue.');
                //objLead.Dummy_Field__c = '2';

                continue;
            }

            //isoCode = LeadAssignment.regionMap.getISOCode(objLead.Country.toUpperCase());
            //region = LeadAssignment.regionMap.getRegion(isoCode);
            
            // start---Added for LATAM GLR enhancement nov'10 release
            isoCode = isoCode1.get(objLead.Country.toUpperCase());
            region = region1.get(isoCode);
            // end---Added for LATAM GLR enhancement nov'10 release
            
            objLead.Iso_Country_Code__c = isoCode;
            
            //
            // ensure the region is not null
            // add the lead to the Global Lead Routing Error Queue, if it is.
            //
            
            if(region == null || region == '' )
            {
                objLead.OwnerId = LeadAssignment.objleadMap.getQueueId(LeadAssignment.GLOBAL_LEAD_ROUTING_ERROR);
                objLead.Assignment_Error__c = ' Country : '+ objLead.Country + ' is not mapped to any region' ;
                objLead.Dummy_Field__c = '2';
            }
            
            System.Debug('Lead Region: ' + region);
        }

        //
        // add the lead to region specific collections
        //

        if(region == 'LATAM')
        {
            LATAMList.add(objLead);
            updateLATAMList.add(objLead);
            latamCompany.put(String.valueOf(count),objLead.Company);
            latamCountry.put(String.valueOf(count),objLead.Iso_Country_Code__c);
            latam= true;

            String atemailId;
            String dotemailId;
            String[] dotEmail=null;
            String objemailId=objLead.Email;
            
            String[] atEmail=objemailId.split('@',2);
            
            System.debug('atEmail'+atEmail);
            if(atEmail.size() >1)
            {

                atemailId = atEmail[1].toUpperCase();
                latamatEmailMap.put(atemailId,atemailId);
                dotEmail = atemailId.split('\\.',-1);
                if(dotEmail.size()>1)
                {
                    dotemailId=dotEmail[dotEmail.size()-1].toUpperCase();
                    latamdotEmailMap.put('.'+dotemailId,'.'+dotemailId);
                }

            }
        }

        if(region == 'APAC')
        {
            APACList.add(objLead);
            updateAPACList.add(objLead);
            APACCompany.put(String.valueOf(count),objLead.Company);
            APACCountry.put(String.valueOf(count),objLead.Iso_Country_Code__c);
            APACState.put(String.valueOf(count),objLead.State);
            
            String atemailId;
            String dotemailId;
            String[] dotEmail=null;
            String objemailId=objLead.Email;
            System.debug('objemailId'+objemailId);
            String[] atEmail=objemailId.split('@',2);
            System.debug('atEmail'+atEmail);
            if(atEmail.size() >1)
            {
                atemailId = atEmail[1].toUpperCase();
                System.debug('atemailId'+atemailId);
                apacatEmailMap.put(atemailId,atemailId);
                dotEmail = atemailId.split('\\.',-1);
                if(dotEmail.size()>1)
                {
                    dotemailId=dotEmail[dotEmail.size()-1].toUpperCase();
                    apacdotEmailMap.put('.'+dotemailId,'.'+dotemailId);
                }

            }
            apac = true;
        }
        if(region == 'EMEA')
        {
            EMEAList.add(objLead);
            updateEMEAList.add(objLead);
            emeaCompany.put(String.valueOf(count),objLead.Company);
            emeaCountry.put(String.valueOf(count),objLead.Iso_Country_Code__c);
            String atemailId;
            String dotemailId;
            String[] dotEmail=null;
            String objemailId=objLead.Email;
            String[] atEmail=objemailId.split('@',2);
            if(atEmail.size() >1)
            {

                atemailId = atEmail[1].toUpperCase();
                emeaatEmailMap.put(atemailId,atemailId);
                dotEmail = atemailId.split('\\.',-1);
                if(dotEmail.size()>1)
                {
                    dotemailId=dotEmail[dotEmail.size()-1].toUpperCase();
                    emeadotEmailMap.put('.'+dotemailId,'.'+dotemailId);

                }
            }
            emea= true;
        }
        if(region =='NA')
        {
            String atemailId;
            String dotemailId;
            String[] dotEmail=null;
            String objemailId=objLead.Email;
            String[] atEmail=objemailId.split('@',2);        
            
            if(atEmail.size() >1)
            {
                atemailId = atEmail[1].toUpperCase();
                naatEmailMap.put(atemailId,atemailId);
                dotEmail = atemailId.split('\\.',-1);
                if(dotEmail.size()>1)
                {
                    dotemailId=dotEmail[dotEmail.size()-1].toUpperCase();
                    nadotEmailMap.put('.'+dotemailId,'.'+dotemailId);
            }
        }
        if(objLead.OwnerId == LeadAssignment.objleadMap.getQueueId(LeadAssignment.NEW_BUSINESS_QUEUE))
        {
            System.Debug('Process a lead owned by the New Business Queue');
            NANBList.add(objLead);
            updateNAList.add(objLead);
            if(objLead.State != null)
            {
                nbStateMap.put(objLead.State,objLead.State);
            }
        }
        else if(objLead.OwnerId == LeadAssignment.objleadMap.getQueueId(LeadAssignment.SLED_SALES_QUEUE))
        {
            System.Debug('Process a lead owned by the SLED Sales Queue');
            NASList.add(objLead);
            updateNAList.add(objLead);
            if(objLead.State != null)
            {
                sStateMap.put(objLead.State,objLead.State);
            }
        }
        else if(objLead.OwnerId == LeadAssignment.objleadMap.getQueueId(LeadAssignment.NA_EDU_QUEUE))
        {
            System.Debug('Process a lead owned by the NA EDU Queue');
            NAEDUList.add(objLead);
            updateNAList.add(objLead);
            if(objLead.State != null)
            {
                eduStateMap.put(objLead.State,objLead.State);
            }
        }
        else
        {
            NAList.add(objLead);
            updateNAList.add(objLead);
            naCompany.put(objLead.Company,objLead.Company);
            emailId = objLead.Email;
            if(emailId== null) emailId = '';
            String[] emailSplit = emailId.split('@',2);
            if(emailSplit.size() >1)
            {
                emailId = emailSplit[1];
                naEmailMap.put(emailId,emailId);
            }
            if(objLead.State != null)
            {
                naStateMap.put(objLead.State,objLead.State);
            }
        }
        na= true;
    }
    count++;
    }

    //
    // Route lead to the appropriate region
    //
    
    if(latam)
    {
        System.Debug('Route lead to LATAM');
        LATAMLeadRouting routing = new LATAMLeadRouting();
        routing.assignQueue(LATAMList,latamCompany,latamCountry,LeadAssignment.objleadMap,latamatEmailMap,latamdotEmailMap);
        if(isupdate)
        {
            for(Lead lead: updateLATAMList)
            {
                ownerIDMap.put(lead.Id,lead.ownerId);
            }
        }
    }

    if(apac)
    {
        System.Debug('Route lead to APAC');
        APACLeadRouting routing = new APACLeadRouting();
        routing.assignQueue(APACList,APACCompany,APACCountry,APACState,LeadAssignment.objleadMap,apacatEmailMap,apacdotEmailMap);
        if(isupdate)
        {
            for(Lead lead: updateAPACList)
            {
                ownerIDMap.put(lead.Id,lead.ownerId);
            }
        }
    }

    if(emea)
    {
        System.Debug('Route lead to EMEA');
        EMEALeadRouting routing = new EMEALeadRouting();
        routing.assignQueue(EMEAList,emeaCompany,emeaCountry,LeadAssignment.objleadMap,emeaatEmailMap,emeadotEmailMap);
        if(isupdate)
        {
            for(Lead lead: updateEMEAList)
            {
                ownerIDMap.put(lead.Id,lead.ownerId);
            }
        }
    }

    if(na)
    {
        System.Debug('Route lead to North America');
        NALeadRouting routing = new NALeadRouting();
                  
        routing.assignQueue(NAList,naCompany,naStateMap,naEmailMap,LeadAssignment.objleadMap,naatEmailMap,nadotEmailMap);
        if(NANBList.size()>0)
        {
            System.Debug('Route lead to North America New Business');
            routing.newBusiness(NANBList,nbStateMap,LeadAssignment.objleadMap);
        }
        if(NASList.size()>0)
        {
            System.Debug('Route lead to North America SLED');
            routing.sledTerritory(NASList,sStateMap,LeadAssignment.objleadMap);
        }
        if(NAEDUList.size()>0)
        {
            System.Debug('Route lead to North America EDU');
            routing.eduTerritory(NAEDUList,eduStateMap,LeadAssignment.objleadMap);
        }
        if(isupdate)
        {
            for(Lead lead: updateNAList)
            {
                ownerIDMap.put(lead.Id,lead.ownerId);
            }
        }
    }

    //
    // determine which leads contain errors
    //
    
    String ids = '';
    for (Lead errlead:errorLeads)
    {
        ids += errlead.Id + ',';
    }
    System.Debug('Leads that contain errors:' + ids);

    
    Integer size = errorLeads.size();
    if(size >0)
    {
        String errMsg = '<b>Error Encountered:</b> You are attempting to transfer leads into the lead routing engine'+
        '   that does not meet the minimum requirement for data on the lead(s). '+
        '<br>Ensure that your leads have Company, Last Name, eMail, Country, Lead Source Detail populated before assigning them '+
        'to the Global Lead Routing Queue. Your entire transfer request has been rolled back. '
        + '<br>Please correct the failed records or remove them from the transfer list and try again.<br>';
        Lead lead1 = errorLeads.get(0);
        If(size >1)
        {
            errMsg += '<b>Failed Record (Lead IDs)<b>:'+ids;
        }
        lead1.addError(errMsg);
    }

    boolean isportalUser = false;
    if(Util.currentUser() != null)
    {
        isportalUser=true;
    }


    if(!isportalUser)
    {
        errorLeads=objpartnerUserValidation.partvalidation(leads);
        size = errorLeads.Size();
        if(size >0)
        {
            String errMsg='<b>Please ensure that Partner Opt In is set to true before assigning lead to partner <br>';
            for(Lead errlead:errorLeads)
            {
                ids += errlead.Id + ',';
            }
            
            Lead lead1 = errorLeads.get(0);
            
            If(size >1)
            {
                errMsg += '<b>Failed Record (Lead IDs)<b>:'+ids;
            }
            lead1.addError(errMsg);
        }
    
     }
  
  }

}