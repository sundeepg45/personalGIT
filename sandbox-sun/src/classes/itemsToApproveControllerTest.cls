@isTest(SeeAllData=true)
public class itemsToApproveControllerTest{  
    
    static testmethod void pageTest() {
    	//This is only a test
        User u = [SELECT Id FROM User WHERE Profile.Name = 'Business Affairs User' AND IsActive = True LIMIT 1];
        System.runAs(u){
            itemsToApproveController controller = new itemsToApproveController();
            controller.getItemList();
        }
    }

}