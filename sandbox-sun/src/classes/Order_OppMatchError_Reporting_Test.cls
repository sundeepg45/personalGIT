/**
 * This test class is used to test the functionality of Order_Opportunity_MatchError_Reporting class.
 *
 * @author Rajiv Gangra <rgangra@DELOITTE.com>
 * @version 2015-05-15
 * 2015-05-15 - initial version
 */

@isTest
public class Order_OppMatchError_Reporting_Test
{
    Public Static Account account;
    Public Static Opportunity opportunity;
    Public Static Opportunity_Header_Staging__c opportunityHeaderStaging;
    Public Static List<Opportunity_Match_Configuration__c> opportunityMatchConfig;
    Public Static CDH_Party__c  cdhParty;
    Public Static Contact contact;
    Public Static Contact contact1;
    Public Static List<OpportunityLineItem> OpportunityLineItemList;
    Public Static List<Opportunity_Line_Staging__c> opportunityLineStagingList;
    Public Static EBS_Account__c eBSAcc;
    Public Static Address__c addRec;
    Public Static List<Opportunity_Partner_Staging__c> OpportunityPartnerStagingList;
    Public Static List<Partner_Program_Tier__c> pptList;
    
    @future
    Public Static void setCustomSetting(){
        // custom setting for trigger.
        BooleanSetting__c booleanSettingName = new BooleanSetting__c();
        booleanSettingName.Name='EBSAccountTrigger.updtEBSaccNmbrOnAcc';
        insert booleanSettingName;   
      
    }
    
    Public Static void SetupDirectOppData(){
        setCustomSetting();
        
        opportunityMatchConfig = new List<Opportunity_Match_Configuration__c>();
        opportunityMatchConfig.add(TestUtil.getOpportunityMatchConfigurationData('RecordType__c','NOT EQUAL TO','EMEA Sales Opportunity'));
        opportunityMatchConfig.add(TestUtil.getOpportunityMatchConfigurationData('StageName','NOT EQUAL TO','Closed Booked'));
        opportunityMatchConfig.add(TestUtil.getOpportunityMatchConfigurationData('Amount','Range', '10'));
        insert opportunityMatchConfig;
        
        Indirect_Matching_Static_Data__c iMSD= new Indirect_Matching_Static_Data__c();
        iMSD.Name='Limit';
        iMSD.Value__c='10';
        insert iMSD;
        
        Indirect_Matching_Static_Data__c iMSD1= new Indirect_Matching_Static_Data__c();
        iMSD1.name='SortBy';
        iMSD1.Value__c='Name';
        insert iMSD1;
        
        pptList= new List<Partner_Program_Tier__c>();
        pptList.add(TestUtil.getPartneraprogramTier('12345'));
        insert pptList;
        
        cdhParty = TestUtil.getCDHParty('12345','Organization');
        insert cdhParty;
        
        account = TestUtil.getAccount('Test Account');
        account.CDH_Party_Name__c = cdhParty.Id;
        insert account;
        
        eBSAcc= TestUtil.getEBSAcc('12345',account.id,'12345');
        Insert eBSAcc;
        
        addRec= TestUtil.getAddress('12345',account.id);
        Insert addRec;
        
        
        contact=TestUtil.getContact('Test Con',account);
        contact.CDH_Party__c=cdhParty.id;
        insert contact;
      
        Id pricebookId = Test.getStandardPricebookId();
        Product2 product = TestUtil.getProduct('Product Test Data');
        product.ProductCode='12345';
        insert product;
        
        Pricebook2 pricebook = new Pricebook2();
        pricebook.Name = 'Global Price Book';
        insert pricebook;
        
        PricebookEntry PricebookEntry = TestUtil.getPricebookEntry(pricebookId ,product);
        insert PricebookEntry;
        
        PricebookEntry PricebookEntry1 = TestUtil.getPricebookEntry(pricebook.Id ,product);
        insert PricebookEntry1;
        
        opportunity = TestUtil.getOpportunity('Opportunity Name' ,account);
        insert opportunity;
        
        opportunity=[select id,Name,OpportunityNumber__c from Opportunity where id=:opportunity.id];
        
        OpportunityLineItemList = new List<OpportunityLineItem>();
        OpportunityLineItemList.add(TestUtil.getOpportunityLineItem(opportunity,PricebookEntry.id));
        OpportunityLineItemList.add(TestUtil.getOpportunityLineItem(opportunity,PricebookEntry.id));
        insert OpportunityLineItemList;
        
        
        opportunityHeaderStaging = TestUtil.getDirectOpportunityHeaderStagingData(opportunity,'Not Processed' ,'CLOSED');
        opportunityHeaderStaging.Opportunity_ID__c=opportunity.id;
        opportunityHeaderStaging.Order_Source__c = 'SFDC_Sales';
        opportunityHeaderStaging.Order_Type__c='MULTI SHIP/ENTITLE';
        opportunityHeaderStaging.Bill_To_Account_Number__c='12345';
        opportunityHeaderStaging.Ship_To_Account_Number__c='12345';
        opportunityHeaderStaging.Sold_To_Account_Number__c='12345';
        opportunityHeaderStaging.Entitle_To_Account_Number__c='12345';
        opportunityHeaderStaging.Bill_To_CDH_Party_Number__c='12345';
        opportunityHeaderStaging.Ship_To_CDH_Party_Number__c='12345';
        opportunityHeaderStaging.Sold_To_CDH_Party_Number__c='12345';
        opportunityHeaderStaging.Entitle_To_CDH_Party_Number__c='12345';
        opportunityHeaderStaging.Bill_To_Address_CDH_Party_Site_Number__c='12345';
        opportunityHeaderStaging.Ship_To_Address_CDH_Party_Site_Number__c='12345';
        opportunityHeaderStaging.Sold_To_Address_CDH_Party_Site_Number__c='12345';
        opportunityHeaderStaging.Entitle_To_Address_CDH_Party_Site_Number__c='12345';
        opportunityHeaderStaging.Bill_To_CDH_Party_Number_Account__c='12345';
        opportunityHeaderStaging.Ship_To_CDH_Party_Number_Account__c='12346';
        opportunityHeaderStaging.Sold_To_CDH_Party_Number_Account__c='12347';
        opportunityHeaderStaging.Entitle_To_CDH_Party_Number_Account__c='12348';
        insert opportunityHeaderStaging;
        
        opportunityLineStagingList = new List<Opportunity_Line_Staging__c>();
        opportunityLineStagingList.add(TestUtil.getDirectOpportunityLineStagingData(opportunityHeaderStaging , OpportunityLineItemList[0],'12345'));
        opportunityLineStagingList.add(TestUtil.getDirectOpportunityLineStagingData(opportunityHeaderStaging , OpportunityLineItemList[1],'12345'));
        opportunityLineStagingList[0].Entitle_To_Party_Number__c ='12345';
        opportunityLineStagingList[0].Entitle_To_CDH_Party_Number__c='12345';
        opportunityLineStagingList[0].Quantity__c=1;
        opportunityLineStagingList[0].Entitle_To_CDH_Party_Site_Number__c='12345';
        opportunityLineStagingList[0].Product_Code_Oracle__c='12345';
        opportunityLineStagingList[0].UnitPrice__c=10;
        
        opportunityLineStagingList[1].UnitPrice__c=10;
        opportunityLineStagingList[1].Product_Code_Oracle__c='12345';
        opportunityLineStagingList[1].Entitle_To_Party_Number__c ='12345';
        opportunityLineStagingList[1].Entitle_To_CDH_Party_Number__c='12345';
        opportunityLineStagingList[1].Entitle_To_CDH_Party_Site_Number__c='12345';
        opportunityLineStagingList[1].Quantity__c=1;
        insert opportunityLineStagingList;
        
        OpportunityPartnerStagingList = new List<Opportunity_Partner_Staging__c>();
        OpportunityPartnerStagingList.add(TestUtil.getPartnerStaging(opportunityHeaderStaging ,'12345'));
        OpportunityPartnerStagingList.add(TestUtil.getPartnerStaging(opportunityHeaderStaging ,'12345'));
        OpportunityPartnerStagingList[0].Partner_Contact_CDH_Party_Number__c='12345';
        OpportunityPartnerStagingList[1].Partner_Contact_CDH_Party_Number__c='12345';

        insert OpportunityPartnerStagingList;
        opportunityHeaderStaging=TestUtil.getHeaderStagingData(opportunityHeaderStaging.Id);
    }
    

    //test Positive cases
    static testMethod void opportunity_Error_Reporting_Positive(){
        
        SetupDirectOppData();
        opportunityHeaderStaging.Order_Status__c = 'BOOKED';
        opportunityHeaderStaging.status__c='Error';
        opportunityHeaderStaging.Oracle_Order_Number__c='12345';
        update opportunityHeaderStaging;
        List<Match_and_Validation_Error__c> listMVerror= new List<Match_and_Validation_Error__c>();
        for(Integer i=4;i<30;i++){
            set<String> setError= new set<String>{'D','I','In'};
            for(String s:setError){
                Match_and_Validation_Error__c MV= new Match_and_Validation_Error__c();
                MV.Error_Code__c=s+i;
                MV.Error_Description__c='test';
                MV.Opportunity_Staging_Header__c=opportunityHeaderStaging.id;
                MV.Opportunity_Partner_Staging__c=OpportunityPartnerStagingList[0].id;
                MV.Opportunity_Product_Staging__c=opportunityLineStagingList[0].id;
                listMVerror.add(MV);
            }
        }
        Insert listMVerror;
        // The query used by the batch job.
        Test.startTest();
            Order_Opportunity_MatchError_Reporting c = new Order_Opportunity_MatchError_Reporting();
            c.errorList.add('test');
            Database.executeBatch(c);
        Test.stopTest();
    }
    //test Negative cases
    static testMethod void opportunity_Error_Reporting_Negative(){
        
        SetupDirectOppData();
        
        opportunityHeaderStaging.Order_Status__c = 'BOOKED';
        opportunityHeaderStaging.status__c='Error';
        opportunityHeaderStaging.Oracle_Order_Number__c=null;
        opportunityHeaderStaging.Bill_To_Account_Number__c=null;
        opportunityHeaderStaging.Ship_To_Account_Number__c=null;
        opportunityHeaderStaging.Sold_To_Account_Number__c=null;
        opportunityHeaderStaging.Entitle_To_Account_Number__c=null;
        opportunityHeaderStaging.Bill_To_CDH_Party_Number__c=null;
        opportunityHeaderStaging.Ship_To_CDH_Party_Number__c=null;
        opportunityHeaderStaging.Sold_To_CDH_Party_Number__c=null;
        opportunityHeaderStaging.Entitle_To_CDH_Party_Number__c=null;
        opportunityHeaderStaging.Bill_To_Address_CDH_Party_Site_Number__c=null;
        opportunityHeaderStaging.Ship_To_Address_CDH_Party_Site_Number__c=null;
        opportunityHeaderStaging.Sold_To_Address_CDH_Party_Site_Number__c=null;
        opportunityHeaderStaging.Entitle_To_Address_CDH_Party_Site_Number__c=null;
        opportunityHeaderStaging.Bill_To_CDH_Party_Number_Account__c=null;
        opportunityHeaderStaging.Ship_To_CDH_Party_Number_Account__c=null;
        opportunityHeaderStaging.Sold_To_CDH_Party_Number_Account__c=null;
        opportunityHeaderStaging.Entitle_To_CDH_Party_Number_Account__c=null;

        update opportunityHeaderStaging;
        List<Match_and_Validation_Error__c> listMVerror= new List<Match_and_Validation_Error__c>();
        for(Integer i=4;i<30;i++){
            set<String> setError= new set<String>{'D','I','In'};
            for(String s:setError){
                Match_and_Validation_Error__c MV= new Match_and_Validation_Error__c();
                MV.Error_Code__c=s+i;
                MV.Error_Description__c='test';
                MV.Opportunity_Staging_Header__c=opportunityHeaderStaging.id;
                listMVerror.add(MV);
            }
        }
        Insert listMVerror;
        // The query used by the batch job.
        Test.startTest();
            Order_Opportunity_MatchError_Reporting c = new Order_Opportunity_MatchError_Reporting();
            c.errorList.add('test');
            Database.executeBatch(c);
        Test.stopTest();
    }
}