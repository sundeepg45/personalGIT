/** Class Name      : Attachment_TriggerHandlerTest
 *  Description     : Test class which contains unit tests for validating the Attachment_TriggerHandler class methods.
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
private class Attachment_TriggerHandlerTest {

    //To create attachment
    private static Attachment createAttachment(Id oppId) 
    {
        return new Attachment(
          parentId = oppId,
          Name = 'Test attachment',
          Body = Blob.valueOf('Test Data')
          );
      }
      
    static testMethod void processRestrictDeletionTest1()
    {
    	//Creating user with Channel Sales Profile
    	Profile p = [SELECT Id FROM Profile WHERE Name='Channel Sales']; 
        User u = new User(Alias = 'newUse19', Email='newuser19@testorg.com', 
         EmailEncodingKey='UTF-8', LastName='Testing19', LanguageLocaleKey='en_US', 
         LocaleSidKey='en_US', ProfileId = p.Id, 
         TimeZoneSidKey='America/Los_Angeles', UserName='newuser19@testorg.com');
        insert u;
        
        System.runAs(u){
        	
        	// custom setting for trigger.
			BooleanSetting__c booleanSettingName = new BooleanSetting__c();
			booleanSettingName.Name='Att_Before.processRestrictDeletion';
			insert booleanSettingName;
             
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
	        opportunity.StageName='Prepare';
	        insert opportunity;
	        
	        //system.debug('Opportunity amount-->'+[select amount from opportunity where id =:opportunity.id]);
	        Id pricebookId = Test.getStandardPricebookId();
	        Product2 product = TestUtil.getProduct('Product Test Data');
	        insert product;
	        PricebookEntry PricebookEntry = TestUtil.getPricebookEntry(pricebookId ,product);
	        insert PricebookEntry;
	        
	        List<OpportunityLineItem> OpportunityLineItemList = new List<OpportunityLineItem>();
	        OpportunityLineItemList.add(TestUtil.getOpportunityLineItem(opportunity,PricebookEntry.id));
	        OpportunityLineItemList.add(TestUtil.getOpportunityLineItem(opportunity,PricebookEntry.id));
	        OpportunityLineItemList[0].Entitle_To_Account__c=eBSAcc.id;
	        OpportunityLineItemList[0].Entitle_To_Sales_Account__c=account.id;
	        OpportunityLineItemList[0].Entitle_To_Address__c=addRec.id;
	        insert OpportunityLineItemList;
	        
	        //opportunity.OracleOrderNumber__c = '123456';
	        opportunity.StageName ='Closed Won';
	        update opportunity;
        
	        //create Attachment
	        Attachment obj = createAttachment(opportunity.id);
	        insert obj;
	       
	        Test.startTest();
            try{
	        	//Delete Attachment Object
	        	delete obj;
	        	}catch(exception ex){
	                System.assert(ex.getmessage().contains(Label.Attachment_Cannot_Be_Deleted));
	           }
	           
	       Test.stopTest();
	        
        }
    }
    
    static testMethod void processRestrictDeletionTest2()
    {
        //Creating user with Channel Sales Profile
        Profile p = [SELECT Id FROM Profile WHERE Name='Channel Sales']; 
        User u = new User(Alias = 'newUs536', Email='newuser536@testorg.com', 
         EmailEncodingKey='UTF-8', LastName='Testing536', LanguageLocaleKey='en_US', 
         LocaleSidKey='en_US', ProfileId = p.Id, 
         TimeZoneSidKey='America/Los_Angeles', UserName='newuser536@testorg.com');
        insert u;
        
        System.runAs(u){
        	
        	 // custom setting for trigger.
			BooleanSetting__c booleanSettingName = new BooleanSetting__c();
			booleanSettingName.Name='Att_Before.processRestrictDeletion';
			insert booleanSettingName;
             
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
	        opportunity.OracleOrderID__c = '123456';
	        opportunity.OracleOrderNumber__c = '123456';
	        opportunity.StageName='Prepare';
	        insert opportunity;
	        
	        //system.debug('Opportunity amount-->'+[select amount from opportunity where id =:opportunity.id]);
	        Id pricebookId = Test.getStandardPricebookId();
	        Product2 product = TestUtil.getProduct('Product Test Data');
	        insert product;
	        PricebookEntry PricebookEntry = TestUtil.getPricebookEntry(pricebookId ,product);
	        insert PricebookEntry;
	        
	        List<OpportunityLineItem> OpportunityLineItemList = new List<OpportunityLineItem>();
	        OpportunityLineItemList.add(TestUtil.getOpportunityLineItem(opportunity,PricebookEntry.id));
	        OpportunityLineItemList.add(TestUtil.getOpportunityLineItem(opportunity,PricebookEntry.id));
	        OpportunityLineItemList[0].Entitle_To_Account__c=eBSAcc.id;
	        OpportunityLineItemList[0].Entitle_To_Sales_Account__c=account.id;
	        OpportunityLineItemList[0].Entitle_To_Address__c=addRec.id;
	        insert OpportunityLineItemList;
	        
	        opportunity.OracleOrderNumber__c = '123456';
	        opportunity.StageName ='Closed Booked';
	        update opportunity;
        
            
            //create Attachment
            Attachment obj = createAttachment(opportunity.id);
            insert obj;
                
            Test.startTest();
            try{
	        	//Delete Attachment Object
	        	delete obj;
	        	}catch(exception ex){
	                System.assert(ex.getmessage().contains(Label.Attachment_Cannot_Be_Deleted));
	           }
            
            Test.stopTest();
        }
        
        
    }
}