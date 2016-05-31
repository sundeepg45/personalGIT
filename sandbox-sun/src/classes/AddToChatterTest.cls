@isTest(SeeAllData=true)
public class AddToChatterTest{     
   
   
   
   public static testMethod void addToChatterGroup(){
     
        // For instance, if you want to create a user 
        // with the Salesforce Platform License,
        // you could grab the "Standard Platform User" Profile
        //  and use this to create a test user
        Profile directSalesUser = [select id from Profile where Name = 'Direct Sales User'];
        User testUser = new User(
               Alias = 'standt', 
               Email='standarduser@testorg.com', 
               EmailEncodingKey='UTF-8', 
               LastName='Testing', 
               LanguageLocaleKey='en_US', 
               LocaleSidKey='en_US', 
               ProfileId = directSalesUser.Id, 
               TimeZoneSidKey='America/Los_Angeles', 
               UserName='standarduser01@testorgc.com',
               Region__c='EMEA'
            );
        insert testUser;
        
        AddToChatter.addUserToGroup(new List<ID>{testUser.id});
        AddToChatter.doFutureCall(new List<ID>{testUser.id});
        AddToChatter.regularSyncCall(new List<ID>{testUser.id});


   }
}