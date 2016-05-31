/**
* Class Name:TandemTaskNotifcationMailTest
* Date:4/11/2011
* Description: Test Class created for TandemNotifcationMail business Class
* Modificaton History:
* Modified By :Ratan Sharma
* Modified date :4/11/2011
* Reason for Modification:Separated test class from business class and created a new test class
*/

@isTest  
private class  TandemTaskNotifcationMailTest
{
	public static testmethod void deployTandemTaskNotifcationMail()
	{
		Opportunity opp = new Opportunity(
			//AccountId = account.Id,
			CloseDate = System.today().addDays(30),
			Country_Of_Order__c = 'US',
			CurrencyIsoCode = 'USD',
			Name = 'OpportunityNew',
			OpportunityType__c = 'Standard',
			PaymentType__c = 'NA Purchase Order',
			StageName = 'Test Stage');
		insert opp ;
		Task tandem_task = new Task(
			ownerId = UserInfo.getUserId(),
			subject= 'Track Due date',
			ActivityDate=System.today().addDays(1),
			recordtypeid=Util.tandemRecordTypeId,
			whatid=opp.Id);
//		insert tandem_task;
		TandemTaskNotifcationMail ttnm = new TandemTaskNotifcationMail();
		ttnm.addTask(tandem_task);
		ttnm.sendMail();
	}
}