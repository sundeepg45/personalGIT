/**
 * This is a test class for LineStagingPagingController class.
 *
 * @author Sagar J Mehta <smehta@redhat.com>
 * @version 2014-24-03
 * 2015-24-03 - created
 */
@isTest 
private class LineStagingPagingControllerTest {

      // private static Opportunity_Header_Staging__c opportunityHeaderStaging;    
     private static Oppty_Staging_Limit__c limitSetting;
        
    /*
     * Method used to cover positive scenarios
     * @param none
     */  
      @isTest
     static void saveMethodCoverage() {
            limitSetting = new Oppty_Staging_Limit__c(name = 'PartnerStaging', Limit__c = '10');
            insert limitSetting;
        
            limitSetting = new Oppty_Staging_Limit__c(name = 'LineStaging', Limit__c = '10');
            insert limitSetting;
            
            Opportunity_Header_Staging__c opportunityHeaderStaging = new Opportunity_Header_Staging__c();
            CDH_Party__c  cdhParty = TestUtil.getCDHParty('AB12ab234','Organization');
            insert cdhParty;
                
            Account account = TestUtil.getAccount('Test Account');
            account.CDH_Party_Name__c = cdhParty.Id;
            insert account;
                
            Address__c address = TestUtil.getAddress(cdhParty.Name, account.Id);
            
            Contact contact = TestUtil.getContact('TestContact', account);
             
            EBS_Account__c ebsAcc = TestUtil.getEBSAcc ('TestAcc',account.Id,'AB12ab234'); 
            opportunityHeaderStaging.Bill_To_Account_Number__c = '1234566';
            opportunityHeaderStaging.Bill_To_Address_Line_1__c = 'Line 1';
            opportunityHeaderStaging.Bill_To_Address_Line_2__c = 'Line 2';
            opportunityHeaderStaging.Bill_To_Address_Line_3__c = 'Line 3';
            opportunityHeaderStaging.Bill_To_Address_Line_4__c = 'Line 4';
            opportunityHeaderStaging.Entitle_To_Sales_Account__c = account.Id; 
            opportunityHeaderStaging.Entitle_To_Account__c = ebsAcc.Id;
            opportunityHeaderStaging.Entitle_To_Address__c = address.Id;  
            opportunityHeaderStaging.Entitle_To_Contact__c = contact.Id;
            system.debug(address.Id);
            insert  opportunityHeaderStaging;            
            Opportunity_Line_Staging__c[] line = new List<Opportunity_Line_Staging__c>();
            for(Integer i=0;i<3;i++) {
               Opportunity_Line_Staging__c opptLine = new Opportunity_Line_Staging__c(Opportunity_Stage_Header_ID__c = opportunityHeaderStaging.Id );
                line.add(opptLine);
            }
            insert line;      
                          
            List<Opportunity_Header_Staging__c> headerList = new List<Opportunity_Header_Staging__c>();
            headerList = [Select Id, Name from Opportunity_Header_Staging__c];
                
            Test.setCurrentPage(Page.LineStagingDetailPage);
            ApexPages.currentPage().getParameters().put('id', opportunityHeaderStaging.Id);
            ApexPages.currentPage().getParameters().put('ead', address.Id);
            ApexPages.currentPage().getParameters().put('ea', ebsAcc.Id);
            ApexPages.currentPage().getParameters().put('ec', contact.Id);
            ApexPages.currentPage().getParameters().put('esa', account.Id);
            //Instantiate object of "ApexPages.StandardSetController"by passing array of records

            ApexPages.StandardSetController con = new ApexPages.StandardSetController(line);
            //Now, create Object of your Controller extension by passing object of standardSetController

            //YOUR_Extension ext = new YOUR_Extension(stdSetController);
            LineStagingPagingController lineStagingPaging = new LineStagingPagingController ();
            lineStagingPaging.getRelatedOpptyLineStagingList();
            lineStagingPaging.saveLineStaging();
            lineStagingPaging.copyEntitleToFromHeaderInformation();
            lineStagingPaging.saveAndCancel();   
            boolean t = lineStagingPaging.hasNext;
            boolean l = lineStagingPaging.hasPrevious;
            Integer n = lineStagingPaging.pageNumber;
            lineStagingPaging.first();
            lineStagingPaging.last();
            lineStagingPaging.previous();
            lineStagingPaging.next();
            
                        
            
            
            
            
    }
}