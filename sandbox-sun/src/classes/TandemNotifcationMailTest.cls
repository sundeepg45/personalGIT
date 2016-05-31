/**
* Class Name:TandemNotifcationMailTest
* Description: Test Class created for TandemNotifcationMail business Class
* Modificaton History:
* Modified By : Abhijeet Anand
* Modified Date : 9/20/2011
* Reason for Modification: Enhanced code coverage and added assert statements.
*/

@isTest
private class TandemNotifcationMailTest
{
	static testmethod void deployTandemNotifcationMail() {
		TestingIds__c apiProfileTesting = TestingIds__c.getValues('API Profile');
		System.assertNotEquals(null,apiProfileTesting,'"API Profile" needs to be set in the TestingIds__c');
		User u = new User(
			alias = 'st5893',
			email='standarduser5893@testorg.com',
			emailencodingkey='UTF-8',
			lastname='Testing',
			languagelocalekey='en_US',
			localesidkey='en_US',
			profileid = apiProfileTesting.Id__c,
			timezonesidkey='America/Los_Angeles',
			username='standarduser5893@testorg.com');
		insert u;
		System.runAs(u)
		{
			test.startTest();
			String acc_id=Util.ldAccount;
			Opportunity  tandem_Opportunity ;
			Account acc = new Account(Name='Test Account');
			insert acc;
			AccountTeamMember AccountTeamMember1 = new AccountTeamMember ( UserId=UserInfo.getUserId(), AccountId=acc.Id, TeamMemberRole='Inside Rep');
			insert AccountTeamMember1;

			//changed the opportunity stagename value to prepare as part of Value Selling enhancement.July 20th release
			tandem_Opportunity = new Opportunity(name= 'Tandem Opportunity Notification',accountid=acc.Id,closedate=System.today(),stageName='Prepare',EMEA_SE_Required__c=true,Amount=0);
			insert tandem_Opportunity;
			System.debug('tandem_Opportunity'+tandem_Opportunity);
			TandemNotifcationMail tndmNotification = new TandemNotifcationMail();
			tndmNotification.mailSent=false;
			tndmNotification.createMail(tandem_Opportunity);
			System.assert(tndmNotification.mailSent,'Failed to send e-mail');
			tandem_Opportunity.StageName = 'Qualify';
			tndmNotification.mailSent=false;
			update tandem_Opportunity;
			tndmNotification.createMailOnTandemOppUpdate(tandem_Opportunity,tandem_Opportunity);
			System.assert(tndmNotification.mailSent,'Failed to send e-mail');

			System.assertEquals(tandem_Opportunity.StageName,'Qualify');

			Opportunity tnd_Opportunity = new Opportunity(name= 'Tandem Opportunity Notification',accountid=acc.Id,closedate=System.today(),stageName='Prepare',EMEA_SE_Required__c=true,Amount=null);
			TandemNotifcationMail tandmNotification = new TandemNotifcationMail();
			tandmNotification.createMail(tnd_Opportunity);
			System.assert(tandmNotification.mailSent,'Failed to send e-mail');
			tandmNotification.mailSent=false;
			tandmNotification.createMailOnTandemOppUpdate(tnd_Opportunity,tnd_Opportunity);
			System.assert(tandmNotification.mailSent,'Failed to send e-mail');
			test.stopTest();
		}
	}
}