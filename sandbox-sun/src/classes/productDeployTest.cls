/**
* Class Name:productDeployTest 
* Description: Contains test methods for Opportunity Product related triggers.
* Modificaton History: 6/28/2011 - Updated Stage value from 'Unqualified' to 'Prepare' for Value Selling project - July 20th, 2011 release
* Modified By : Ratan Sharma
* Modified date :6/28/2011
* Reason for Modification: Updated Stage value from 'Unqualified' to 'Prepare' for Value Selling project - July 20th, 2011 release
*/

@isTest

private class productDeployTest {

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

    product();
}

public static void product()
{

    //changed the opportunity stagename value to prepare as part of Value Selling enhancement.July 20th release
    Opportunity  oppNew = new Opportunity(name= 'Product',closedate=System.today(),stageName='Prepare'  );
    oppNew.AccountId=account.Id;
    oppNew.CurrencyIsoCode='INR';
    insert oppNew;

    OpportunityLineItem product = new OpportunityLineItem ();
    product.OpportunityId = oppNew.Id;
    product.Quantity=100;
    product.PricebookEntryId=[Select id, CurrencyIsoCode from PricebookEntry  where IsActive=true  and CurrencyIsoCode ='INR' limit 1].Id;
    product.UnitPrice=20;
    insert product;

}


}