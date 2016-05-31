@IsTest(SeeAllData=True)
public class CommunitiesDocsDisplayControllerTest{
	
    public static testMethod void docsDisplayTest() {
        CommuntiesDocsDisplayController controller = new CommuntiesDocsDisplayController();
        ApexPages.currentPage().getParameters().put('viewMore', 'true');
        controller = new CommuntiesDocsDisplayController();
    }
    
    public static testMethod void popDocsDisplayTest() {
        CommunitiesPopularDocsDisplayController controller = new CommunitiesPopularDocsDisplayController();
        ApexPages.currentPage().getParameters().put('viewMore', 'true');
        controller = new CommunitiesPopularDocsDisplayController();
    }
}