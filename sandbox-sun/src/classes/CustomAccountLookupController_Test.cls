/*****************************************************************************************
    Name    : CustomAccountLookupController_Test
    Desc    : This is a test class for CustomAccountLookupController
                            
Modification Log : 
---------------------------------------------------------------------------
 Developer              Date            Description
---------------------------------------------------------------------------
Raghunath Utpala    31/07/2014          Created
******************************************************************************************/

@isTest(seeAllData=true)
public class CustomAccountLookupController_Test
{

    public testMethod static void testCustomAccountLookup()
    {
       
       
       //Account to be searched 
         Account acctSearch=[select Id,Name from Account limit 1];
       
       //setting up the Parameters passed from VF page to the controller
         ApexPages.currentPage().getParameters().put('lksrch',acctSearch.Name);
         ApexPages.currentPage().getParameters().put('frm','test');
         ApexPages.currentPage().getParameters().put('txt','test');
       
       //create an instance of controller 
         CustomAccountLookupController customLookup=new CustomAccountLookupController();
         customLookup.Account.Name='Test';
       
       //test coverage for the controller methods
         customLookup.search();
         customLookup.saveAccount();
         customLookup.getFormTag();
         customLookup.getTextBox();
    
    
    }
    
    
    
}