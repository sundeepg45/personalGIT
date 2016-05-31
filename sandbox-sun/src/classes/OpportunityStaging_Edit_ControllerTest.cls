/**
 * This is a test class for OpportunityStaging_Edit_Controller class.
 *
 * @author Sagar J Mehta <smehta@redhat.com>
 * @version 2015-06-29
 * 2014-10-09 - created
 * 2015-06-29 - included tests for before triggers on header and line staging
 */
@isTest
private class OpportunityStaging_Edit_ControllerTest { 
    
    private static Opportunity_Header_Staging__c opportunityHeaderStaging;    
    private static Oppty_Staging_Limit__c limitSetting;
    private static Opportunity opportunity;
    /*
     * Method used to create test data for test class coverage
     * @param status
     */    
    static Opportunity_Header_Staging__c createStagingHeader(String status) {
        limitSetting = new Oppty_Staging_Limit__c(name = 'PartnerStaging', Limit__c = '10');
        insert limitSetting;
        
        limitSetting = new Oppty_Staging_Limit__c(name = 'LineStaging', Limit__c = '10');
        insert limitSetting;
        
        CDH_Party__c  cdhParty = TestUtil.getCDHParty('AB12ab234','Organization');
        insert cdhParty;

        CDH_Party__c  cdhParty2 = TestUtil.getCDHParty('223344','Organization');
        insert cdhParty2;
        
        Account account = TestUtil.getAccount('Test Account');
        account.CDH_Party_Name__c = cdhParty.Id;
        insert account;
        
        opportunity = TestUtil.getOpportunity('Opportunity Name' ,account);
        opportunity.OracleOrderID__c = '123456';
        opportunity.OracleOrderNumber__c = '123456';
        insert opportunity;
        
        opportunityHeaderStaging = TestUtil.getDirectOpportunityHeaderStagingData(opportunity,status,'BOOKED');
        opportunityHeaderStaging.Bill_To_Account_Number__c = '1234566';
        opportunityHeaderStaging.Bill_To_Address_Line_1__c = 'Line 1';
        opportunityHeaderStaging.Bill_To_Address_Line_2__c = 'Line 2';
        opportunityHeaderStaging.Bill_To_Address_Line_3__c = 'Line 3';
        opportunityHeaderStaging.Bill_To_Address_Line_4__c = 'Line 4';
        opportunityHeaderStaging.Bill_To_CDH_Party_Number_Account__c = '223344';
        opportunityHeaderStaging.Bill_To_Address_CDH_Party_Site_Number__c = '1212111';
        opportunityHeaderStaging.Bill_To_City__c = 'City';
        opportunityHeaderStaging.Bill_To_CDH_Party_Number__c = '122334455';
        opportunityHeaderStaging.Bill_To_Contact_Email__c = 'test@email.com';
        opportunityHeaderStaging.Bill_To_Contact_First_Name__c = 'Test';
        opportunityHeaderStaging.Bill_To_Contact_Last_Name__c = 'Last Name';
        opportunityHeaderStaging.Bill_To_Contact_Phone__c = '9891067876';
        opportunityHeaderStaging.Bill_To_Country__c = 'IN';
        opportunityHeaderStaging.Bill_To_County__c = 'County';
        opportunityHeaderStaging.Bill_To_Party_Name__c = 'Party Name';
        opportunityHeaderStaging.Bill_To_Party_Number__c = '234111144';
        opportunityHeaderStaging.Bill_To_Party_Type__c = 'PERSON';
        opportunityHeaderStaging.Bill_To_Province__c = 'Province';
        opportunityHeaderStaging.Bill_To_State__c = 'State';
        opportunityHeaderStaging.Bill_To_Zip_Postal_Code__c = '251001';
        opportunityHeaderStaging.Sales_Account__c = account.Id;
        opportunityHeaderStaging.Oracle_Order_Number__c = '123456';
        opportunityHeaderStaging.Date_Booked__c = Date.today();
        opportunityHeaderStaging.Create_New_Opportunity__c = true;
        opportunityHeaderStaging.Entitle_To_CDH_Party_Number_Account__c = '223344';
        opportunityHeaderStaging.Ship_To_CDH_Party_Number_Account__c = '223344';
        opportunityHeaderStaging.Sold_To_CDH_Party_Number_Account__c = '223344';
        return opportunityHeaderStaging;
    }         
    
    /*
     * Method used to create test data of type Match_and _Validation_Error__C for test class coverage
     * @param 
     */
    static Match_and_Validation_Error__c getErrors(){
        return new Match_and_Validation_Error__c(
            Error_Code__c = 'D5',
            Error_Description__c = 'Bill-To Account number match failed. Please review and select the correct Bill-To Account Number from the lookup field.',
            Error_Type__c = 'Header',
            Opportunity_Staging_Header__c = opportunityHeaderStaging.Id,
            Related_Field_API_Name__c = 'Bill_To_City__c');    
    }

    /*
     * Method used to cover positive scenarios
     * @param status
     */
    @isTest
    static void saveMethodCoverage() {
        createStagingHeader('Not Processed');
        insert opportunityHeaderStaging;  
        Opportunity_Line_Staging__c line = new Opportunity_Line_Staging__c();
        line.Opportunity_Stage_Header_ID__c = opportunityHeaderStaging.Id;
        insert line;      
        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(opportunityHeaderStaging);
        PageReference pageRef = Page.OpportunityStaging_Edit;
        Test.setCurrentPage(pageRef);
        Apexpages.currentpage().getparameters().put('id', opportunityHeaderStaging.Id);
        OpportunityStaging_Edit_Controller controller = new OpportunityStaging_Edit_Controller(sc);
        System.assertNotEquals(null, controller.fieldNameSet);
        List<Match_and_Validation_Error__c> errorList = controller.getErrorList();
        System.assert(errorList.isEmpty());
        controller.save();       
        Test.stopTest();
    }
    
    /*
     * Method used to cover positive scenarios    
     * @param
     */
    @isTest
    static void saveMethodCoveragePositiveScenarios() {
        createStagingHeader('Ready For Reprocessing');
        insert opportunityHeaderStaging;  
        Opportunity_Line_Staging__c line = new Opportunity_Line_Staging__c();
        line.Opportunity_Stage_Header_ID__c = opportunityHeaderStaging.Id;
        line.Entitle_To_CDH_Party_Number_Account__c = '223344';
        insert line;      
        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(opportunityHeaderStaging);
        PageReference pageRef = Page.OpportunityStaging_Edit;
        Test.setCurrentPage(pageRef);
        Apexpages.currentpage().getparameters().put('id', opportunityHeaderStaging.Id);
        OpportunityStaging_Edit_Controller controller = new OpportunityStaging_Edit_Controller(sc);
        System.assertNotEquals(null, controller.fieldNameSet);
        List<Match_and_Validation_Error__c> errorList = controller.getErrorList();
        System.assert(errorList.isEmpty());
        controller.selectedTab = 'lineStagingTab';
        List<Opportunity_Line_Staging__c> lineList = controller.relatedOpptyLineStagingList;
        controller.selectedTab = 'partnerStagingTab';
        List<Opportunity_Partner_Staging__c> partnerList = controller.relatedOpptyPartnerStagingList;
        controller.save();      
        controller.switchTabs();               
        Test.stopTest();
        system.debug(opportunityHeaderStaging);

        Opportunity_Header_Staging__c fetchedHeader = [SELECT Bill_To_CDH_Party__c, Entitle_To_CDH_Party__c, Ship_To_CDH_Party__c, Sold_To_CDH_Party__c FROM Opportunity_Header_Staging__c WHERE Id = :opportunityHeaderStaging.Id LIMIT 1];
        System.assert(fetchedHeader.Bill_To_CDH_Party__c != null);
        System.assert(fetchedHeader.Entitle_To_CDH_Party__c != null);
        System.assert(fetchedHeader.Ship_To_CDH_Party__c != null);
        System.assert(fetchedHeader.Sold_To_CDH_Party__c != null);
        Opportunity_Line_Staging__c fetchedLine = [SELECT Entitle_To_CDH_Party__c FROM Opportunity_Line_Staging__c WHERE Id = :line.Id LIMIT 1];
        System.assert(fetchedLine.Entitle_To_CDH_Party__c != null);
    }
    
    /*
     * Method used to cover negative scenarios
     * @param
     */
    @isTest
    static void saveMethodCoverageNegativeScenarios() {
        createStagingHeader('Ready For Reprocessing');                
        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(opportunityHeaderStaging);
        PageReference pageRef = Page.OpportunityStaging_Edit;
        Test.setCurrentPage(pageRef);
        Apexpages.currentpage().getparameters().put('id', opportunityHeaderStaging.Id);
        OpportunityStaging_Edit_Controller controller = new OpportunityStaging_Edit_Controller(sc);
        List<Match_and_Validation_Error__c> errorList = controller.getErrorList();        
        System.assert(errorList.isEmpty());
        controller.selectedTab = 'lineStagingTab';
        errorList = controller.getErrorList();         
        controller.selectedTab = 'partnerStagingTab';
        errorList = controller.getErrorList();        
        
        controller.save(); 
        
        Test.stopTest();
    }
    
    /*
     * Method used to cover positive scenarios    
     * @param
     */
    @isTest
    static void copyEntitleToFromHeaderInformationTest() {
        createStagingHeader('Ready For Reprocessing');
        
        
        insert opportunityHeaderStaging;  
        Opportunity_Line_Staging__c line = new Opportunity_Line_Staging__c();
        line.Opportunity_Stage_Header_ID__c = opportunityHeaderStaging.Id;
        insert line;      
        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(opportunityHeaderStaging);
        PageReference pageRef = Page.OpportunityStaging_Edit;
        Test.setCurrentPage(pageRef);
        Apexpages.currentpage().getparameters().put('id', opportunityHeaderStaging.Id);
        OpportunityStaging_Edit_Controller controller = new OpportunityStaging_Edit_Controller(sc);
        System.assertNotEquals(null, controller.fieldNameSet);
        List<Match_and_Validation_Error__c> errorList = controller.getErrorList();
        System.assert(errorList.isEmpty());
        controller.selectedTab = 'lineStagingTab';
        List<Opportunity_Line_Staging__c> lineList = controller.relatedOpptyLineStagingList;
        controller.selectedTab = 'partnerStagingTab';
        List<Opportunity_Partner_Staging__c> partnerList = controller.relatedOpptyPartnerStagingList;
        controller.copyEntitleToFromHeaderInformation();      
        opportunityHeaderStaging.Create_New_Opportunity__c = false;
        controller.selOpportunityValueId = opportunity.Id;
        controller.save();
        Test.stopTest();
                
    }
}