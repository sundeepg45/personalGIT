@IsTest(SeeAllData=True)
public class viewCountTest{
    
    static testMethod void testSchedule() {        
        contentViewCountUpdate controller = new contentViewCountUpdate();
        controller.run();  
    }

}