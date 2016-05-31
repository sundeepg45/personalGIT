/**
* Class Name:LeadRules
* Author:Accenture
* Description:Used for avoiding creation of duplicate LD Other Mapping rule for LATAM region.
* Modificaton History:
* Modified By : Ratan Sharma
* Modified date :5/2/2011
* Reason for Modification:Separated test class from business class.
*/

public class LeadRules{

public void setUniqueLeadRule(LeadRules__c[] rules)
{
    // start--Updated for LATAM GLR enhancement nov '10 release
    for(LeadRules__c rule:rules)
    {
        if(rule.SuperRegion__c == 'LATAM')
        {
            rule.Unique_Identifiers__c=rule.Type__c+rule.SuperRegion__c+rule.Value__c+rule.Country__c+rule.Revenue__c+rule.Product_Of_Interest__c+rule.Zip_Code__c+rule.Starting_Range__c+rule.Ending_Range__c;
        }
    }
    // end--Updated for LATAM GLR enhancement nov '10 release
}
}