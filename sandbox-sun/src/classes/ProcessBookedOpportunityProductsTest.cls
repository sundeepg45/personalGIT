/** Class Name      : ProcessBookedOpportunityProductsTest
 *  Description     : Test class which contains unit tests for validating the ProcessBookedOpportunityProducts class methods.
 *  @author         : Niti Bansal <nibansal@redhat.com>
 *  @version        : 10-12-2014
 *
 *  Modification Log:  
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *   Developer                  Date            Modification ID             Description
 *   Niti Bansal               	10-12-2014                                  Initial Version 
 *  ---------------------------------------------------------------------------------------------------------------------------------------
 *                                                                                    
**/

@isTest
private class ProcessBookedOpportunityProductsTest {

    static testMethod void processRestrictDeletionTest1()
    {
        //Creating user with Channel Sales Profile
        Profile p = [SELECT Id FROM Profile WHERE Name='Channel Sales']; 
        User u = new User(Alias = 'newUs209', Email='newuser209@testorg.com', 
         EmailEncodingKey='UTF-8', LastName='Testing209', LanguageLocaleKey='en_US', 
         LocaleSidKey='en_US', ProfileId = p.Id, 
         TimeZoneSidKey='America/Los_Angeles', UserName='newuser209@testorg.com');
        insert u;
                
        System.runAs(u){
        	// custom setting for trigger.     	
        	BooleanSetting__c booleanSettingName2 = new BooleanSetting__c();
        	booleanSettingName2.Name='OpportunityLineItem_Trigger';
        	insert booleanSettingName2;
        	
	        CDH_Party__c  cdhParty = TestUtil.getCDHParty('AB12ab234','Organization');
			insert cdhParty;
		    Account account = TestUtil.getAccount('Test Account');
			account.CDH_Party_Name__c = cdhParty.Id;
			insert account;
		        
			EBS_Account__c eBSAcc= TestUtil.getEBSAcc('ABC1234',account.id,'ABC1234');
			eBSAcc.Name='1234566';
			Insert eBSAcc;
		        
			Address__c addRec= TestUtil.getAddress('ABC1234',account.id);
			addRec.CDH_Party_Site_Number__c='AB12ab234';
			Insert addRec;
		        
			Opportunity opportunity = TestUtil.getOpportunity('Opportunity Name' ,account);
			//opportunity.OracleOrderID__c = '123456';
			//opportunity.OracleOrderNumber__c = '123456';
			opportunity.StageName='Prepare';
			insert opportunity;
			
			Id pricebookId = Test.getStandardPricebookId();
			Product2 product = TestUtil.getProduct('Product Test Data');
			insert product;
			PricebookEntry PricebookEntry = TestUtil.getPricebookEntry(pricebookId ,product);
			insert PricebookEntry;
		        
			//Create Opportunity LineItem
			List<OpportunityLineItem> OpportunityLineItemList = new List<OpportunityLineItem>();
			OpportunityLineItemList.add(TestUtil.getOpportunityLineItem(opportunity,PricebookEntry.id));
			OpportunityLineItemList.add(TestUtil.getOpportunityLineItem(opportunity,PricebookEntry.id));
			OpportunityLineItemList[0].Entitle_To_Account__c=eBSAcc.id;
			OpportunityLineItemList[0].Entitle_To_Sales_Account__c=account.id;
			OpportunityLineItemList[0].Entitle_To_Address__c=addRec.id;
			insert OpportunityLineItemList;
			
			//opportunity.DateOrderBooked__c = System.today();
			//opportunity.DateOrderSubmitted__c = System.today()-5; 
			opportunity.StageName ='Closed Won';
			update opportunity;
		
			Test.startTest();
	        try{
	        	//Delete Opportunity LineItem
	        	delete OpportunityLineItemList;
	        	}catch(exception ex){
	                System.assert(ex.getmessage().contains(Label.OppProducts_Cannot_Be_Deleted));
	            }
	        Test.stopTest();
        }
    }
    
    static testMethod void processRestrictDeletionTest2()
    {
        //Creating user with Channel Sales Profile
        Profile p = [SELECT Id FROM Profile WHERE Name='Channel Sales']; 
        User u = new User(Alias = 'newUs774', Email='newuser774@testorg.com', 
         EmailEncodingKey='UTF-8', LastName='Testing774', LanguageLocaleKey='en_US', 
         LocaleSidKey='en_US', ProfileId = p.Id, 
         TimeZoneSidKey='America/Los_Angeles', UserName='newuser774@testorg.com');
        insert u;
                
        System.runAs(u){      	
			// custom setting for trigger.       	
        	BooleanSetting__c booleanSettingName2 = new BooleanSetting__c();
        	booleanSettingName2.Name='OpportunityLineItem_Trigger';
        	insert booleanSettingName2;
        	 
        	CDH_Party__c  cdhParty = TestUtil.getCDHParty('AB12ab2345','Organization');
			insert cdhParty;
			
	    	Account account = TestUtil.getAccount('Test Account 2');
			account.CDH_Party_Name__c = cdhParty.Id;
			insert account;
	        
			EBS_Account__c eBSAcc= TestUtil.getEBSAcc('ABC12345',account.id,'ABC12345');
			eBSAcc.Name='1234566';
			Insert eBSAcc;
	        
			Address__c addRec= TestUtil.getAddress('ABC12345',account.id);
			addRec.CDH_Party_Site_Number__c='AB12ab2345';
			Insert addRec;
			Opportunity opportunity = TestUtil.getOpportunity('Opportunity Name 1' ,account);
			opportunity.OracleOrderID__c = '123456';
			opportunity.OracleOrderNumber__c = '123456';
			opportunity.StageName='Prepare';
			insert opportunity;
			
	        Id pricebookId = Test.getStandardPricebookId();
	        Product2 product = TestUtil.getProduct('Product Test Data 1');
	        insert product;
	        PricebookEntry PricebookEntry = TestUtil.getPricebookEntry(pricebookId ,product);
	        insert PricebookEntry;
	        
	        //Create Opportunity LineItem
	        List<OpportunityLineItem> OpportunityLineItemList = new List<OpportunityLineItem>();
	        OpportunityLineItemList.add(TestUtil.getOpportunityLineItem(opportunity,PricebookEntry.id));
	        OpportunityLineItemList.add(TestUtil.getOpportunityLineItem(opportunity,PricebookEntry.id));
	        OpportunityLineItemList[0].Entitle_To_Account__c=eBSAcc.id;
	        OpportunityLineItemList[0].Entitle_To_Sales_Account__c=account.id;
	        OpportunityLineItemList[0].Entitle_To_Address__c=addRec.id;
	        insert OpportunityLineItemList;

	        opportunity.OracleOrderNumber__c = '123457';
	        opportunity.StageName ='Closed Booked';
	        update opportunity;
	        
	        Test.startTest();
			try{
                //Delete Opportunity LineItem
                delete OpportunityLineItemList;
            }catch(exception ex){
               System.assert(ex.getmessage().contains(Label.OppProducts_Cannot_Be_Deleted));
            }
            
            Test.stopTest();
        }
        
        
    }
}