@isTest
public class CommunitiesFeaturedHeadlinesConTests {
	
    static TestMethod void controllerTest(){
        
        // 1. Setup the test environment
        CommunitiesFeaturedHeadlinesController con;
        
        // Create a test page context and pass parameters to the controller 
        PageReference headlinePage = Page.CommunitiesFeaturedHeadlines;
        headlinePage.getParameters().put('page','Dashboard');
        Test.setCurrentPage(headlinePage);
        
        // Create an Audience record
        Audience__c testAudience = new Audience__c(
        	Available_to_Unauthenticated_Users__c = true,
            Partner_Program__c = 'All',
            Name = 'Test Audience'
        );
        insert(testAudience);
        
        // Create a Headline in the "Dashboard" Site.com page grouping
        Communities_Featured_Headline__c testHeadline = new Communities_Featured_Headline__c(
        	Audience__c = testAudience.Id,
            Headline__c = 'Test Headline for Dashboard!',
            HTML_Value__c = '<h1>Test Headline</h1>',
            Publish_Date__c = DateTime.now(),
            Site_com_Page__c = 'Dashboard',
            Status__c = 'Published'
        );
        insert(testHeadline);
        
         
        
        // 2. Execute the test
        Test.startTest();
        	con = new CommunitiesFeaturedHeadlinesController();
        Test.stopTest();
        
        
        // 3. Test - make sure the controller returns the Dashboard headline created above
        system.assert(con.headline != null);
        system.assertEquals(con.headline.Id, testHeadline.Id);
    }
}