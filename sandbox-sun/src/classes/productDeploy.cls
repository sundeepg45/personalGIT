public class productDeploy {

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

    Opportunity  oppNew = new Opportunity(name= 'Product',closedate=System.today(),stageName='Unqualified'  );
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