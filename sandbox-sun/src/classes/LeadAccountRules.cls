/**
* Class Name:LeadAccountRulesTest
* Author:Accenture
* Description:Used for avoiding creation of duplicate rule for LATAM region.
* Modificaton History:
* Modified By : Ratan Sharma
* Modified date :4/27/2011
* Reason for Modification:Separated test class from business class.
*/

public class LeadAccountRules {

	public void setUniqueIdentifier(LeadAccountRules__c[] rules)
	{
	    // start --- Updated for LATAM GLR Enhancement nov'10 release
	    for(LeadAccountRules__c rule:rules)
	    {
	       if(rule.SuperRegion__c == 'LATAM')
	       {
	           rule.Unique_Identifier__c=rule.SuperRegion__c+rule.Value__c+rule.Country__c + rule.State__c+ rule.Type__c;
	       }
	       else
	       {
	           rule.Unique_Identifier__c=rule.SuperRegion__c+rule.Value__c+rule.Country__c + rule.State__c;
	       }
	    }
	    // end --- Updated for LATAM GLR Enhancement nov'10 release
	}

}