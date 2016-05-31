/**
* Class Name:Lead_SendtoSalesController 
* Author : Prajakta Samant
* Date:08/10/2011
* Description: Controller class for Send to Sales VF page

* Modificaton History:
* Bill Riemers 08/25/2011
* Improve test coverage.
*
* Bryan Bosely 09/06/2011
* test coverage for the functionality added to update lead owner
*/

@isTest
private class Lead_SendToSalesControllerTest
{	
	static testMethod void testProcessLead()
	{
		Lead ld =  new Lead(
			OwnerId = Util.globalLeadRoutingQueue,
			LastName ='TestLead',
			Email='lead@email.com',
			Title='None',
			LeadSourceDetail__c='Test Source',
			Route_Around__c = true,
			Status='New',
			Stage__c='Test Stage',
			Company='Company',
			Country='US1',
			State='NC1',
			Iso_Country_Code__c ='US1',
			Products_of_Interest__c='Test Product',
			Partner_Opt_In__c=true);
			
		insert ld;
		ld = [
			select 
				Name,
				OwnerId,
				LastName,
				Email,
				Title,
				LeadSourceDetail__c,
				Route_Around__c,
				Status,
				Stage__c,
				Company,
				Country,
				State,
				Iso_Country_Code__c,
				Products_of_Interest__c,
				Partner_Opt_In__c
			from Lead where Id = :ld.Id ];
//		ld.OwnerId = UserInfo.getUserId();
		ld.OwnerId = Util.globalLeadRoutingQueue;
		ApexPages.StandardController sc = new ApexPages.StandardController(ld);
		Lead_SendtoSalesController controller = new Lead_SendtoSalesController(sc);

		controller.isRouteLead = false;
		controller.sendNotification = true;
		//System.assertNotEquals(null,controller.processLead());

		controller.isRouteLead = true;
		//System.assertNotEquals(null,controller.processLead());
	}
}