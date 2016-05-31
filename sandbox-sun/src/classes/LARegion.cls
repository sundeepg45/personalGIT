/**
* Class Name: LARegion
* Author: Accenture
* Description: Used for getting the ISO Code and Region of a Lead.
* Modificaton History:
* Modified By :Nitesh Dokania
* Modified date : 5/2/2011
* Reason for Modification: Separated test class from business class.
*/

Global class LARegion
{
    public Map<String,LeadCountryMap__c> countryMap = new Map<String,LeadCountryMap__c>();
    public Map<String,String> isoCodeMap = new Map<String,String>();
    public static List<String> deploycountryList= new List<String>();
    LeadCountryMap__c[] countries ;
    
    public String getISOCode(String strCountry)
    {
        LeadCountryMap__c leadCountry = null;
        String isoCode = '';
        strCountry = strCountry.toUpperCase();
        system.debug('strCountry is:'+strCountry);
        if(! countryMap.containsKey(strCountry)) {
            countryMap.put(strCountry,NULL);
            for(LeadCountryMap__c country : [Select Country__c, ISO_Code__c, Region__c from LeadCountryMap__c where Country__c = :strCountry ])
            {
                countryMap.put(strCountry,country);
                isoCodeMap.put(country.ISO_Code__c,country.Region__c);
            }
        }
        //now get the ISO Code
        leadCountry = countryMap.get(strCountry);
        
        if(leadCountry != null) isoCode = leadCountry.ISO_Code__c;
        
        return isoCode;
    }

/*    
    public Map<String,LeadCountryMap__c> countryMap = null;
    public Map<String,String> isoCodeMap = null;
    public static boolean dbbyPass = false;
    public void populateCountryMap()
    {

        if(countryMap == null)
        {

            if(LeadMap.dbbyPass)
            {
                deploycountryList.add('India');
                deploycountryList.add('Australia');
                deploycountryList.add('Japan');
                deploycountryList.add('UK');
                deploycountryList.add('US');
                deploycountryList.add('China');
                deploycountryList.add('Brazil');
                deploycountryList.add('CA');
                countries=[Select Country__c, ISO_Code__c, Region__c from LeadCountryMap__c
                    where Country__c IN:deployCountryList ];
            }
            else
            {
                countries=[Select Country__c, ISO_Code__c, Region__c from LeadCountryMap__c];
            }
            System.debug('countries'+countries.Size());
            isoCodeMap = new Map<String,String>();
            countryMap = new Map<String,LeadCountryMap__c>();
            for(LeadCountryMap__c country:countries)
            {
                countryMap.put(country.Country__c.toUpperCase(),country);
                if(isoCodeMap.get(country.ISO_Code__c) == null)
                {
                    isoCodeMap.put(country.ISO_Code__c,country.Region__c);
                }
            }
        }
    }
*/
    public String getRegion(String isoCode)
    {
        if(! isoCodeMap.containsKey(isoCode)) {
            isoCodeMap.put(isoCode,NULL);
            for(LeadCountryMap__c country : [Select Country__c, ISO_Code__c, Region__c from LeadCountryMap__c where ISO_Code__c = :isoCode ])
            {
                System.debug('countryMap.put('+country.Country__c.toUpperCase()+',...);isoCodeMap.put('+country.ISO_Code__c+'...);');
                countryMap.put(country.Country__c.toUpperCase(),country);
                isoCodeMap.put(country.ISO_Code__c,country.Region__c);
            }
        }
        //now get the ISO Code
        String region = isoCodeMap.get(isoCode);

        if(region == null) region = '';
        return region;
    }
   
}