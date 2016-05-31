/**
 * Class Name:OpportunityDeployTest
 * Modificaton History: 6/29/2011 - Updated Stage value from 'Unqualified' to 'Prepare' for Value Selling project - July 20th, 2011 release
 * Modified By : Ratan Sharma
 * Modified date : 6/29/2011
 * Reason for Modification: Updated Stage value from 'Unqualified' to 'Prepare' for Value Selling project - July 20th, 2011 release
 * Modified By : Nitesh Dokania
 * Modified date : 9/19/2011
 * Reason for Modification: Enhanced code coverage for AutoCompleteTask trigger on Opportunity.
 */

@isTest
private class OpportunityDeployTest {
	public static Account account;
	public static Opportunity  oppNew;
	public static testmethod void oppDeploy() {
	
		//create test method for each trigger
		/* Trigger deployment section starts */
		
		//create an account so as to use it from all opportunities
		RecordType recordType = [select Id,name from RecordType where name = 'Strategic' limit 1];
		
		account = new Account(name='account');
		account.RecordTypeId = recordType.Id;
		account.AccountClassification__c = 'Strategic';
		insert account;
		
		System.debug('');
	    oppNew = new Opportunity(name= 'back out order',closedate=System.today()+45,stageName='Closed Booked' );
	    oppNew.AccountId=account.Id;
	    oppNew.Country_of_Order__c ='India';
	    insert oppNew;
		
		test.startTest();
		
		backOutSubmittedOrder();
		OpportunityUpdatedforQuat();
		
		test.stopTest();
	
	}
	
	public static testmethod void oppDeployTest() {
	
		//create test method for each trigger
		/* Trigger deployment section starts */
		
		//create an account so as to use it from all opportunities
		RecordType recordType = [select Id,name from RecordType where name = 'Strategic' limit 1];
		
		account = new Account(name='account');
		account.RecordTypeId = recordType.Id;
		account.AccountClassification__c = 'Strategic';
		insert account;
		
		System.debug('');
	    oppNew = new Opportunity(name= 'back out order',closedate=System.today()+45,stageName='Closed Booked' );
	    oppNew.AccountId=account.Id;
	    oppNew.Country_of_Order__c ='India';
	    insert oppNew;
		
		test.startTest();
		
		fieldUpdates();
		autoCompleteTask();
		
		test.stopTest();
	}

	public static void backOutSubmittedOrder()
	{
	    //set the opportunity values to invoke the trigger.
	    //changed the opportunity stagename value to prepare as part of Value Selling enhancement.July 20th release
	    oppNew.DateOrderBooked__c = null;
	    oppNew.DateOrderSubmitted__c = System.now();
	    oppNew.stageName='Prepare';
	    oppNew.CloseDate = System.today();
	    update oppNew;
	
	}


	public static void OpportunityUpdatedforQuat()
	{
	    //changed the opportunity stagename value to prepare as part of Value Selling enhancement.July 20th release
	    Opportunity  opptyNew = new Opportunity(name= 'Kalidass to NA',closedate=System.today(),stageName='Prepare', Renewable__c='No',Pay_Now__c='No',OpportunityType__c='Standard',PaymentType__c='NA Purchase Order',FulfillmentChannel__c='Direct - End Customer'  );
	    opptyNew.AccountId=account.Id;
	    opptyNew.Country_of_Order__c ='Canada';
	    insert opptyNew;
	
	    //set the opportunity values to invoke the trigger.
	    oppNew.DateOrderBooked__c = null;
	   // oppNew.DateOrderSubmitted__c = System.now();
	   //changed the opportunity stagename value to prepare as part of Value Selling enhancement.July 20th release
	    oppNew.stageName='Prepare';
	    
	    oppNew.closedate = Date.newInstance(2009,12,12);
	    oppNew.Close_Date_Moved_Reason__c = 'Testing IDC';
	    update oppNew;
	}
	
    public static void fieldUpdates() {
        //changed the opportunity stagename value to prepare as part of Value Selling enhancement.July 20th release
        OpportinityFieldUpdates fieldUpdates = new OpportinityFieldUpdates(); 
        Opportunity oppOld = new Opportunity(name= 'Old Field Update Test',closedate=System.today(),stageName='Prepare',AccountId=account.Id,DateOrderBooked__c=System.now());
        
        Opportunity oppty1New = new Opportunity(name= 'New Field Update Test',closedate=System.today(),stageName='Prepare',AccountId=account.Id,DateOrderSubmitted__c=System.now());
        fieldUpdates.opportuinityClosedWon(oppty1New);
        
        oppty1New.OracleOrderNumber__c = '1';
        oppty1New.stageName='Prepare';
        fieldUpdates.OpportunityIsBooked(oppty1New);

        oppty1New.FulfillmentChannel__c = 'Direct';
        fieldUpdates.updateOpportunityCloseDate(oppty1New,oppOld);
            
        oppty1New.DateOrderBooked__c = System.now();
        fieldUpdates.opportuinityClosedBooked(oppty1New);
        
        oppty1New.OracleOrderNumber__c = null;
        fieldUpdates.backoutBookedOrder(oppty1New);
        
        fieldUpdates.backoutSubmitOrder(oppty1New);
      
    }
    
    public static void autoCompleteTask()
	{		
	    Task tk = new Task();
	    tk.WhatId = oppNew.Id;
	    tk.Status = 'In Progress';
	    tk.RecordTypeId = Util.omCorrectionRequestRecordTypeId;
	    insert tk;
	    
	    //set the opportunity values to invoke the trigger.
		oppNew.OracleOrderNumber__c = '123456';
		update oppNew;
	
	}
}