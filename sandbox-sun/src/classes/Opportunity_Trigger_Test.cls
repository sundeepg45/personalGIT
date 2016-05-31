/*****************************************************************************************
    Name    : Opportunity_Trigger_Test
    Desc    : This is test class for Opportunity_Trigger  and Opportunity_Trigger_Handler.
              
                            
    Modification Log : 
---------------------------------------------------------------------------
    Developer        Date               Description
---------------------------------------------------------------------------
    Vipul Jain      03 SEP 2014         Created
******************************************************************************************/
@isTest
public class Opportunity_Trigger_Test{
    
    // Method to insert the single opportunity.
    
    public testMethod static void singleOpportunityCreation() {
        // prepare boolean setting data
        BooleanSetting__c booleanSetting = getBooleanSetting('Opportunity_Trigger', true);
        insert booleanSetting;

        // prepare account data
        Account account = getAccount('Test Account record');
        insert account;
        
        //prepare contact data
        Contact contact = getContact('Test' , 'Contact' ,account.Id);
        insert contact;
        
        // prepare address data
        Address__c address = getAddress('AddesssLine1' , 'AddesssLine2' , account.Id);
        insert address;
        
        
        // prepare ebsAccount data
        EBS_Account__c ebsAccount = getEBSAccount('EBS Account' , account.Id);
        insert ebsAccount;
        
        // prepare opportunity data.
        Opportunity opportunity = new Opportunity();
        opportunity.Name = 'Testing Opportunity';
        opportunity.StageName = 'Prepare';
        opportunity.CloseDate = system.today()+2;
        opportunity.Bill_To_Sales_Account__c = account.Id;
        opportunity.Bill_To_Account__c = ebsAccount.Id;
        opportunity.Bill_To_Address__c = address.id;
        opportunity.Bill_To_Contact__c = contact.Id;
        opportunity.Entitle_To_Sales_Account__c = account.id;
        opportunity.Entitle_To_Account__c = ebsAccount.id;
        opportunity.Entitle_To_Address__c = address.id; 
        opportunity.Entitle_To_Contact__c = contact.Id;
        opportunity.Ship_To_Sales_Account__c = account.id;
        opportunity.Ship_To_Account__c = ebsAccount.id;
        opportunity.Ship_To_Address__c = address.id;
        opportunity.Ship_To_Contact__c = contact.Id;
        opportunity.Sold_To_Sales_Account__c = account.id;
        opportunity.Sold_To_Account__c = ebsAccount.id;
        opportunity.Sold_To_Address__c = address.id;
        opportunity.Sold_To_Contact__c = contact.Id;
        // start the test
        test.starttest();
        
        // insert parent opportunity record
        insert opportunity;
        
        // prepare clone opportunity record
        Opportunity clonedOpportunity = new Opportunity();  
        clonedOpportunity.Name = 'Testing Opportunity';
        clonedOpportunity.StageName = 'Prepare';
        clonedOpportunity.CloseDate = system.today()+2;
        clonedOpportunity.recordtypeid = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Proof of Concept').getRecordTypeId();
        clonedOpportunity.Cloned_From_Opportunity__c = opportunity.Id;
        
        // insert cloned opportunity
        insert clonedOpportunity;
        
        // query on cloned opportunity record.
        
        Opportunity opportunityrecord = [select Bill_To_Sales_Account__c,
                                        BillingAddress__c,                                       
                                        Entitle_To_Address__c,
                                        Sold_To_Contact__c,
                                        Sold_To_Account__c,
                                        ShippingAddress__c
                                        from opportunity where Id =:clonedOpportunity.Id ];
        System.assertequals(opportunityrecord.Bill_To_Sales_Account__c,account.Id);
        System.assertequals(opportunityrecord.Sold_To_Contact__c,contact.Id);
        
        test.stoptest();    
    }
    
    // Method to insert the opportunities in bulk
    public testMethod static void bulkOpportunityCreation(){
        // prepare boolean setting data
        BooleanSetting__c booleanSetting = getBooleanSetting('Opportunity_Trigger', true);
        insert booleanSetting;

        List<Account> accountList = new List<Account>();
        for(integer i=0;i<20;i++){
            accountList.add(getAccount('Test Account record'+string.valueof(i)));
        }
        insert accountList;
        List<Contact> contactList = new List<Contact>();
        for(integer i=0;i<20;i++){
            contactList.add(getContact('Test'+string.valueof(i) , 'Contact' ,accountList[i].Id));
        }
        List<Address__c> addressList = new List<Address__c>();
        for(integer i=0;i<20;i++){
            addressList.add(getAddress('AddesssLine1'+string.valueof(i) , 'AddesssLine2' ,accountList[i].Id));
        }
        insert addressList;
        List<EBS_Account__c> ebsAccountList = new List<EBS_Account__c>();
        for(integer i=0;i<20;i++){
            ebsAccountList.add(getEBSAccount('EBS Account'+string.valueof(i) ,accountList[i].Id));
        }
        insert ebsAccountList;
        List<Opportunity> opportunityList = new List<Opportunity>();
        for(integer i=0;i<20;i++){
            Opportunity opportunity = new Opportunity();
            opportunity.Name = 'Testing Opportunity'+string.valueof(i);
            opportunity.StageName = 'Prepare';
            opportunity.CloseDate = system.today()+2;
            opportunity.Bill_To_Sales_Account__c = accountList[i].Id;
            opportunity.Bill_To_Account__c = ebsAccountList[i].Id;
            opportunity.Bill_To_Address__c = addressList[i].id;
            opportunity.Bill_To_Contact__c = contactList[i].Id;
            opportunity.Entitle_To_Sales_Account__c = accountList[i].id;
            opportunity.Entitle_To_Account__c = ebsAccountList[i].id;
            opportunity.Entitle_To_Address__c = addressList[i].id; 
            opportunity.Entitle_To_Contact__c = contactList[i].Id;
            opportunity.Ship_To_Sales_Account__c = accountList[i].id;
            opportunity.Ship_To_Account__c = ebsAccountList[i].id;
            opportunity.Ship_To_Address__c = addressList[i].id;
            opportunity.Ship_To_Contact__c = contactList[i].Id;
            opportunity.Sold_To_Sales_Account__c = accountList[i].id;
            opportunity.Sold_To_Account__c = ebsAccountList[i].id;
            opportunity.Sold_To_Address__c = addressList[i].id;
            opportunity.Sold_To_Contact__c = contactList[i].Id;
            opportunityList.add(opportunity);
        }
        insert opportunityList;
        
        
        List<Opportunity> clonedOpportunityList = new List<Opportunity>();
        for(integer i=0;i<20;i++){
            Opportunity opportunity = new Opportunity();
            opportunity.Name = 'Testing Opportunity';
            opportunity.StageName = 'Prepare';
            opportunity.CloseDate = system.today()+2;
            opportunity.recordtypeid = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Proof of Concept').getRecordTypeId();
            opportunity.Cloned_From_Opportunity__c = opportunityList[i].Id;
            clonedOpportunityList.add(opportunity);
        }
        test.starttest();
        
        
        insert clonedOpportunityList;   
        
         
        for(integer i=0;i<20;i++){
            clonedOpportunityList[i].Ship_To_Address__c = addressList[0].id;
            clonedOpportunityList[i].Bill_To_Address__c = addressList[0].id;
        }
        update clonedOpportunityList;
          
         test.stoptest();
    }


    // Method to test opportunity backout
    public testMethod static void backOutOpportunityTest(){
        // get record type ids
        Map<String,Id> recordTypeMap = new Map<String,Id>();
        for (RecordType recordType : [SELECT Id, Name FROM RecordType WHERE SobjectType = 'Opportunity']) {
            recordTypeMap.put(recordType.Name, recordType.Id);
        }

        // prepare boolean setting data
        BooleanSetting__c booleanSetting = getBooleanSetting('Opportunity_Trigger', true);
        insert booleanSetting;

        // prepare account data
        Account account = getAccount('Test Account record');
        insert account;

        //prepare contact data
        Contact contact = getContact('Test' , 'Contact' ,account.Id);
        insert contact;

        // prepare address data
        Address__c address = getAddress('AddesssLine1' , 'AddesssLine2' , account.Id);
        insert address;

        // prepare ebsAccount data
        EBS_Account__c ebsAccount = getEBSAccount('EBS Account' , account.Id);
        insert ebsAccount;

        // prepare opportunity data.
        Opportunity opportunity = new Opportunity();
        opportunity.Name = 'Testing Opportunity';
        opportunity.StageName = 'Closed Booked';
        opportunity.CloseDate = system.today()+2;
        opportunity.Bill_To_Sales_Account__c = account.Id;
        opportunity.Bill_To_Account__c = ebsAccount.Id;
        opportunity.Bill_To_Address__c = address.id;
        opportunity.Bill_To_Contact__c = contact.Id;
        opportunity.Entitle_To_Sales_Account__c = account.id;
        opportunity.Entitle_To_Account__c = ebsAccount.id;
        opportunity.Entitle_To_Address__c = address.id; 
        opportunity.Entitle_To_Contact__c = contact.Id;
        opportunity.Ship_To_Sales_Account__c = account.id;
        opportunity.Ship_To_Account__c = ebsAccount.id;
        opportunity.Ship_To_Address__c = address.id;
        opportunity.Ship_To_Contact__c = contact.Id;
        opportunity.Sold_To_Sales_Account__c = account.id;
        opportunity.Sold_To_Account__c = ebsAccount.id;
        opportunity.Sold_To_Address__c = address.id;
        opportunity.Sold_To_Contact__c = contact.Id;
        opportunity.RecordTypeId = recordTypeMap.get('NA Sales Opportunity');
        insert opportunity;

        Opportunity bookedOpp;
        Opportunity revertedOpp;

        // start the test
        test.starttest();

        // update the opp to Closed Booked
        opportunity.Pending_OM_Review__c = true;
        opportunity.OM_review_complete__c = true;
        opportunity.Order_Status__c = 'Booked';
        opportunity.StageName = 'Closed Booked';
        opportunity.RecordTypeId = recordTypeMap.get('Booked Opp Process');
        update opportunity;
        bookedOpp = [SELECT Id, Previous_Record_Type__c FROM Opportunity WHERE Id = :opportunity.Id];

        // back out the opp
        opportunity.StageName = 'Negotiate';
        update opportunity;
        revertedOpp = [SELECT Id, Pending_OM_Review__c, OM_review_complete__c, Order_Status__c, RecordTypeId FROM Opportunity WHERE Id = :opportunity.Id];

        // stop the test
        test.stoptest();

        // assert that previous record type was saved when booking the opp
        System.assert(bookedOpp.Previous_Record_Type__c != null);
        System.assertEquals(recordTypeMap.get('NA Sales Opportunity'), Id.valueOf(bookedOpp.Previous_Record_Type__c));

        // assert that OM flags, order status, and record type were reset when backing out the opp
        System.assert(!revertedOpp.Pending_OM_Review__c);
        System.assert(!revertedOpp.OM_review_complete__c);
        System.assertEquals(null, revertedOpp.Order_Status__c); //OpportunityTriggerBefore2.clearOrderStatus() sets this field to null
        System.assertEquals(recordTypeMap.get('NA Sales Opportunity'), revertedOpp.RecordTypeId);
    }

    // method to prepare the custom setting data.
    public static BooleanSetting__c getBooleanSetting(String name, Boolean val){

        BooleanSetting__c booleanSetting = new BooleanSetting__c();
        booleanSetting.Name = name;
        booleanSetting.Value__c = val;
        return booleanSetting;

    }

    // method to prepare the Account data.
    public static Account getAccount(String name){
        
        Account account = new Account();
        account.Name = name;
        return account;
        
    }
    
    // method to prepare the contact data.
    public static Contact getContact(String firstName , String lastName , Id accountId){
        
        Contact contact = new Contact();
        contact.FirstName = firstName;
        contact.LastName = lastName;
        contact.AccountId = accountId;
        return contact;
        
    }
    
    // method to prepare the Address data.
    public static Address__c getAddress(String addressline1 , String addressline2 , Id accountId){
        
        Address__c address = new Address__c();
        address.Address_Line1__c = addressline1;
        address.Address_Line2__c = addressline2;
        address.City__c = accountId;
        address.Country__c = 'IN';
        address.Entitle_To_Address__c = True;
        address.Identifying_Address__c = True;
        address.Ship_To_Address__c = True;
        address.Sold_To_Address__c = True;
        address.Bill_To_Address__c =  True;
        address.Sales_Account__c = accountId;
        return address;
        
    }
    
    // method to prepare the ebsaccount data.
    public static EBS_Account__c getEBSAccount(String name , Id accountId){
        
        EBS_Account__c ebsAccount= new EBS_Account__c();
        ebsAccount.Name  = name;
        ebsAccount.Sales_Account__c = accountId;
        ebsAccount.Credit_Hold__c = True;
        ebsAccount.EBS_Party_Name__c = name;
        ebsAccount.Primary_EBS_Account__c = True;
        return ebsAccount;
        
    }  
    
       
}