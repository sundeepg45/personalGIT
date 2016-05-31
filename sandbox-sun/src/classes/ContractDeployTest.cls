/**
* Class Name:ContractDeployTest
* Date:4/26/2011
* Description: Contains test methods for Contract related triggers.
* Modificaton History: 6/28/2011 - Updated Stage value from 'Unqualified' to 'Prepare' for Value Selling project - July 20th, 2011 release
* Modified By : Abhijeet Anand
* Modified date :6/28/2011
* Reason for Modification: Updated Stage value from 'Unqualified' to 'Prepare' for Value Selling project - July 20th, 2011 release
*/

@isTest
private class ContractDeployTest {

public static Account account;
public static testmethod void t1()
{

    //create test method for each trigger
    /* Trigger deployment section starts */

    //create an account so as to use it from all opportunities
    RecordType recordType = [select Id,name from RecordType where name = 'Strategic' limit 1];

    account = new Account(name='account');
    account.RecordTypeId = recordType.Id;
    account.AccountClassification__c = 'Strategic';

    insert account;

    populateAccount();
}

public static void populateAccount()
{

    //changed the opportunity stagename value to prepare as part of Value Selling enhancement.July 20th release
    Opportunity  opportunity = new Opportunity(name= 'Contract',closedate=System.today(),stageName='Prepare' );
    opportunity.AccountId = account.Id;
    opportunity.Country_of_Order__c ='Pakistan';
    opportunity.CurrencyIsoCode = 'USD';
    opportunity.OpportunityType__c ='Standard';
    opportunity.FulfillmentChannel__c = 'Direct - End Customer';
    opportunity.Amount = 1000;

    insert opportunity;

    RecordType recordType = [select Id,name from RecordType where name = 'Other' and SObjectType = 'Contract' limit 1];

    Contract contract = new Contract(name='Contract');
    contract.Opportunity__c = opportunity.Id;
    contract.AccountId = account.Id;
    contract.RecordTypeId = recordType.Id;

    insert contract;

}


}