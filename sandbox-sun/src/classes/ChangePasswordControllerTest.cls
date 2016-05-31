/**
* Class Name:ChangePasswordControllerTest
* Author:Accenture
* Date:4/11/2011
* Description: Test Class created for ChangePasswordController business Class
* Modificaton History:
* Modified By :Ratan Sharma
* Modified date :4/11/2011
* Reason for Modification:Separated test class from business class and created a new test class
*/
@isTest
private class ChangePasswordControllerTest
{
    public static testMethod void testChangePasswordController() {
        // Instantiate a new controller with all parameters in the page
        ChangePasswordController controller = new ChangePasswordController();
        controller.oldPassword = '123456';
        controller.newPassword = 'qwerty1'; 
        controller.verifyNewPassword = 'qwerty1';                
        
        System.assertEquals(controller.changePassword(),null);                           
    }    
}