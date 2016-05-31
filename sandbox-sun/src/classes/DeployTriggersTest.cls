/**
* Class Name:DeployTriggers
* Date: 5/3/2008
* Description:Test Class written to cover DeployTriggers class.
* Modificaton History: 6/28/2011 - Updated Stage value from 'Unqualified' to 'Prepare' for Value Selling project - July 20th, 2011 release
* Modified By : Abhijeet Anand
* Modified date :6/28/2011
* Reason for Modification:Updated Stage value from 'Unqualified' to 'Prepare' for Value Selling project - July 20th, 2011 release
*/


@isTest
private class DeployTriggersTest{
	public static testmethod void deployTrackDueDate(){

		List<Task> tasks = new List<Task>();
		Task  tandem_task ;
		tandem_task = new Task(subject= 'Track Due date',ActivityDate=System.today(),recordtypeid=Util.tandemRecordTypeId);
		tasks.add(tandem_task);
		insert tasks;

//		tandem_task = [select id,ActivityDate from task where subject='Track Due date' limit 1];
		tandem_task.ActivityDate=System.today()+2;
		update tandem_task;

	}
	public static testmethod void  deployTandemOpportunityNotification(){

		Account acc = new Account(Name='test Account');
		insert acc;
		List<Opportunity> tandem_Opportunities = new List<Opportunity>();
		Opportunity  tandem_Opportunity  ;
		//changed the opportunity stagename value to prepare as part of Value Selling enhancement.July 20th release
		tandem_Opportunity = new Opportunity(name= 'Tandem Opportunity Notification',closedate=System.today(),stageName='Prepare',EMEA_SE_Required__c=true,accountid=acc.Id);
		tandem_Opportunities.add(tandem_Opportunity);
		insert tandem_Opportunities;

//		tandem_Opportunity = [select id,stageName from Opportunity where name='Tandem Opportunity Notification' limit 1];
		Util.Opp_data.put(tandem_Opportunity.id,tandem_Opportunity);
		tandem_Opportunity.stageName='Closed Won';
		update tandem_Opportunity;
	}
/*
	There is no need to run the same test twice!

	public static testmethod void deployTandemTaskNotification (){
		deployTrackDueDate();
	}
*/
	/*public static testmethod void deployGPSGLSProductNotification(){

		List<Opportunity> tandem_Opportunities = new List<Opportunity>();
		Opportunity  tandem_Opportunity ;
		//changed the opportunity stagename value to Prepare as part of Value Selling enhancement.July 20th release
		tandem_Opportunity = new Opportunity(name= 'Tandem Opportunity Notification',closedate=System.today(),stageName='Prepare',EMEA_SE_Required__c=true,accountid==Util.ldAccount);
		tandem_Opportunities.add(tandem_Opportunity);
		insert tandem_Opportunities;
		tandem_Opportunity = [select id,stageName from Opportunity where name='Tandem Opportunity Notification'];

		List<OpportunityLineItem> products = new List<OpportunityLineItem>();
		OpportunityLineItem product  ;
		product = new OpportunityLineItem(NewOrRenewal__c='New', OpportunityId='006T0000003Jiu4IAC',  PricebookEntryId='01u60000001BZZZAA4', ProductId='00j60000001bMRqAAM', Quantity='2',UnitPrice='123');
		products.add(product);
		insert products;

		product=[select id from OpportunityLineItem where OpportunityId='006T0000003Jiu4IAC' and ProductId='00j60000001bMRqAAM' ];
		delete product;
	}*/

	public static testmethod void deployGPSGLSNotification(){

		List<Opportunity> tandem_Opportunities = new List<Opportunity>();
		Opportunity  tandem_Opportunity ;
		Account acc = new Account(Name='Test Account');
		insert acc;
		//changed the opportunity stagename value to prepare as part of Value Selling enhancement.July 20th release
		tandem_Opportunity = new Opportunity(name= 'Tandem Opportunity Notification',closedate=System.today(),stageName='Prepare',EMEA_SE_Required__c=true,accountid=acc.Id);
		tandem_Opportunities.add(tandem_Opportunity);
		insert tandem_Opportunities;

//		tandem_Opportunity = [select id,stageName from Opportunity where name='Tandem Opportunity Notification' limit 1];
		Util.Opp_data.put(tandem_Opportunity.id,tandem_Opportunity);

		tandem_Opportunity.stageName='Closed Won';
		update tandem_Opportunity;
	}

	public static testmethod void deployEMEAUserCreationNotification(){
		TestingIds__c salesUserProfileTesting = TestingIds__c.getValues('Sales User Profile');
		System.assertNotEquals(null,salesUserProfileTesting,'"Sales User Profile" needs to be set in the TestingIds__c');
		User emea_user =[
			Select
				Alias,
				City,
				FirstName,
				ForecastEnabled,
				IsActive,
				LanguageLocaleKey,
				LastLoginDate,
				LastModifiedById,
				LastModifiedDate,
				LastName,
				LocaleSidKey,
				MobilePhone,
				Name,
				Notes__c,
				OfflinePdaTrialExpirationDate,
				OfflineTrialExpirationDate,
				Phone,
				PostalCode,
				ProfileId,
				ReceivesAdminInfoEmails,
				ReceivesInfoEmails,
				Region__c,
				State,
				Street,
				Title,
				Username,
				UserRoleId
			from User
			where ProfileId = :salesUserProfileTesting.Id__c 
				and Region__c = 'EMEA'
			limit 1 ];
		emea_user.City='Prasad';
		update emea_user;

	}

	public static testmethod void deployLeads(){
		List<Lead> leads = new List<Lead>();
		Lead lead = new Lead(Country='India',State='Goa',Company='Redhat',OwnerId=Util.globalLeadRoutingQueue,LastName ='TestR4DeployLead',Title='R4',LeadSourceDetail__c='APAC World Tour',Status='New',Products_of_Interest__c='JBoss',Partner_Opt_In__c=false, Email='Paresh@gmail.gov');
		leads.add(lead);
		insert leads;

//	  lead = [Select Id,Partner_Opt_In__c from Lead where LastName = 'TestR4DeployLead' and Partner_Opt_In__c = false limit 1];
		lead.Partner_Opt_In__c = true;
		update lead;
	}
	public static testmethod void deployDeletionOMCorrection(){
		try{
		Account acc = new Account(Name='Test Account');

		Opportunity Opp = new Opportunity();
		//changed the opportunity stagename value to prepare as part of Value Selling enhancement.July 20th release
		Opp.StageName = 'Prepare';
		Opp.PaymentType__c = 'LATAM Purchase Order';
		Opp.Pay_Now__c = 'Yes';
		Opp.OpportunityType__c = 'Standard';
		Opp.Name = 'Test Opp';
		Opp.Country_of_Order__c = 'Virgin Islands, U.S';
		Opp.CloseDate = System.today();
		Opp.AccountId = acc.Id;
		Opp.Region2__c ='4';
		Insert Opp;
			Task tk = new Task(WhatId=opp.Id,Subject='OM Correction Requested',OwnerId=UserInfo.getUserId(),ActivityDate=System.today());
			insert tk;
			//Task om_task = [select id,ActivityDate from task where subject='OM Correction Requested' limit 1];
			delete tk;
		}catch(DMLException e){
		}

	}
}