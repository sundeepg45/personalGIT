@isTest
public class CommunitiesStorybookDisplayConTests {

    static TestMethod void controllerTest(){
        
        // 1. Setup the test environment
        CommunitiesStorybookDisplayController con;
        
        // Create a test page context and pass parameters to the controller 
        PageReference pg = Page.CommunitiesStorybookDisplay;
        pg.getParameters().put('page','Dashboard');
        Test.setCurrentPage(pg);
        
        // Create an Audience record
        Audience__c testAudience = new Audience__c(
        	Available_to_Unauthenticated_Users__c = true,
            Partner_Program__c = 'All',
            Name = 'Test Audience'
        );
        insert(testAudience);
        
        // Create a Headline in the "Dashboard" Site.com page grouping
        Storybook__c testStorybook = new Storybook__c(
        	Audience__c = testAudience.Id,
            Language__c = 'English',
            Publish_Date__c = DateTime.now(),
            Site_com_Page__c = 'Dashboard',
            Status__c = 'Published'
        );
        insert(testStorybook);
        
         
        
        // 2. Execute the test
        Test.startTest();
        	con = new CommunitiesStorybookDisplayController();
        Test.stopTest();
        
        
        // 3. Test - make sure the controller returns the Dashboard headline created above
        system.assert(con.storybooks != null);
        system.assertEquals(1, con.storybooks.size());
    
    }
}