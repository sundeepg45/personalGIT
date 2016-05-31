/**
* Class Name:RHNLoginTest
* Description: Test Class created for RHNLogin business Class
* Modificaton History: 6/28/2011 - Updated Stage value from 'Unqualified' to 'Prepare' for Value Selling project - July 20th, 2011 release
* Modified By : Ratan Sharma
* Modified date : 6/28/2011
* Reason for Modification: Updated Stage value from 'Unqualified' to 'Prepare' for Value Selling project - July 20th, 2011 release
*/




@isTest
private class RHNLoginTest
{

 public static testmethod void deployRHNLogin()
  {
  
   //create a test Account
   Account Acc = new Account(Name = 'testName');
   insert Acc ;
   
   //create a test Contact
   Contact con = new Contact(AccountId = Acc .Id, LastName = 'testerLAST', OwnerId = UserInfo.getUserId());
   insert con ;
    
  //create a test opp
  //changed the opportunity stagename value to prepare as part of Value Selling enhancement.July 20th release
   Opportunity opp = new Opportunity(Name = 'My Opportunity', StageName = 'Prepare', CloseDate = Date.today());
   insert opp; 
    
   OpportunityContactRole Cntrole = new OpportunityContactRole(Role = 'NA Marketing',ContactId =con.Id,OpportunityId=opp.Id);
   insert Cntrole;
    
   RHNLogin.copy('Cntrole.Role',+Cntrole.OpportunityId, +Cntrole.ContactId);
  }
}