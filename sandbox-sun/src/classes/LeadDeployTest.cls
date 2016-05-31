/**
* Class Name:LeadDeployTest 
* Author:Accenture
* Date:4/11/2011
* Description:Test Class created for LeadDeploy business Class.
* Modificaton History:
* Modified By : Ratan Sharma
* Modified date :4/27/2011
* Reason for Modification:Renamed the class put @isTest notationas per standard practice.
*/

@isTest
private class LeadDeployTest {
	public static Lead lead;
	public static testmethod void t1()
	{
	    lead = new Lead();
	    lead.LastName='Accenture';
	    lead.RecordTypeId = '012300000000Pmx';
	    lead.Company='Accenture';
	    lead.Status='New';
	    lead.Products_of_Interest__c='JBoss';
	    lead.LeadSourceDetail__c='SD_RONA';
	    lead.Partner_Opt_In__c=true;
	    
	    insert lead;   
	}
}