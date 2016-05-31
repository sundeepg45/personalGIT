/*
 *  SuperRegion
 *
 /*
    File Name: SuperRegion
    Date Implemented: 9/30/09
    Modified On: 04/12/10
    Project: App Maintainance
    Description: This trigger will populate SuperRegion for lead. The Country-SuperRegion Mapping needs to be created in"Lead SuperRegion Mapping".
*/

trigger SuperRegion on Lead (before insert,before update)
{
  
        Lead_SuperRegion_Mapping__c  ldRegion= null;
        Map<String, Lead_SuperRegion_Mapping__c> superRegionMap = null;
        Set<String> countries = new Set<String>();

        for(Lead ld :Trigger.new)
        {
            if(ld.Country != null)
            {
                countries.add(ld.Country.trim().toUpperCase());  
            }
        }
        if(!countries.isEmpty())
        {
            try
            {
                Lead_SuperRegion_Mapping__c[]  leadRegion   =[Select CountryFormula__c, Country_Iso_Code__c, SuperRegion__c from Lead_SuperRegion_Mapping__c where CountryFormula__c IN :countries OR Country_Iso_Code__c IN :countries]; 
                
                if(leadRegion.size() == 0) return;
                
                superRegionMap = new Map<String, Lead_SuperRegion_Mapping__c>();
                for(Lead_SuperRegion_Mapping__c region :leadRegion)
                {
                    //strCountry = region.Country__c;
                    if(region.CountryFormula__c != null || region.CountryFormula__c != '')
                    {
                        superRegionMap.put(region.CountryFormula__c, region);
                        superRegionMap.put(region.Country_Iso_Code__c, region);
                    }
                }
            }
            
            catch (Exception ignored) {}    
        
        }   
        for(Lead ld :Trigger.new)
        {
            if(ld.Country != null)
            {
                if(superRegionMap.size()>0)
                {
                    ldRegion=superRegionMap.get((ld.Country).toUpperCase());
                    if(ldRegion != null)
                    {
                        //If match found then get Super Region value from Super Region map and assign this value to Super Region field on Lead
                        ld.Super_Region__c=ldRegion.SuperRegion__c;
                    }
                    else
                    {       
                        //Set Super Region field to blank
                        ld.Super_Region__c='';
                    }
                }
            }
            else
            {
                //Set Super Region field to blank if Country on Lead is blank
                ld.Super_Region__c='';
            }
        }
}