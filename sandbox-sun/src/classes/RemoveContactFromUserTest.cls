/*
 * This class contains unit tests for validating the behavior of Apex trigger RemoveContactFromUser
 *
 * Author: Nitesh Dokania
 * Created Date : 10/26/2012
 * Modified Date:
 *
 */
 
@isTest
private class RemoveContactFromUserTest 
{   
    static testMethod void removeContact() 
    {       
        User usr = new User(Alias = 'st9437', Email='standarduser9437@example.org',
            Emailencodingkey='UTF-8', LastName='Testing', Languagelocalekey='en_US',
            Localesidkey='en_US', Profileid = UserInfo.getProfileId(), Region__c='APAC',
            Timezonesidkey='America/Los_Angeles', Username='standarduser9437@testorg.com');
        insert usr;
        
        System.RunAs(usr)
        {
            test.startTest();
            
            Contact con = new Contact(FirstName='Test',LastName='User',Email='TestUser@acc.com');  
            insert con;
            
            usr.Contact_Id__c = con.id;
            usr.Associated_Contact__c=con.FirstName+' '+con.LastName;
            update usr;
        
       
            Account acc = new Account(Name='Red Hat (Internal Use Only)');
            insert acc;  
                    
            delete con; 
            
            test.stopTest();
        }      
    }
}