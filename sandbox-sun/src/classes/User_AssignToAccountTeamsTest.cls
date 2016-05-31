/**
* Class Name: User_AssignToAccountTeamsTest
* Description: Test Class created for User_AssignToAccountTeams class.
* Created By :Nitesh Dokania
* Created date :09/08/2011
* Reason for Creation : Code coverage of the corresponding class was zero earlier. This class is created to
*                      increase the code coverage of corresponding test class.Assert statements also added.
*/
@isTest(SeeAllData=true) // need all data to access custom settings
private class User_AssignToAccountTeamsTest
{
    static testMethod void assignAccteamTest()
    {
        List<Attachment> attachmentList = new List<Attachment>();
        List<Account> accountList = new List<Account>();
        
        Profile p = [select id from profile where name='System Administrator'];
        
        TestingIds__c salesUserProfileTesting = TestingIds__c.getValues('Sales User Profile');
        System.assertNotEquals(null,salesUserProfileTesting,'"Sales User Profile" needs to be set in the TestingIds__c');
        
        User usr = new User(alias = 'st8110', email='standarduser8110@testorg.com',
        emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
        localesidkey='en_US', profileid = salesUserProfileTesting.Id__c,
        timezonesidkey='America/Los_Angeles', username='standarduser8110@testorg.com');
        insert usr;

        system.runAs(usr){
            Account TestAccount=new Account();
            TestAccount.Name='Test';
            TestAccount.Named_Account__c=true;
            TestAccount.isAccountActive__c=true;
            accountList.add(TestAccount);
    
            Account TestAcc=new Account();
            TestAcc.Name='Test Acc';
            TestAcc.Named_Account__c=true;
            TestAcc.isAccountActive__c=true;
            accountList.add(TestAcc);
            insert accountList;
    
          
            Attachment attach = new Attachment();
            attach.OwnerId = usr.Id;
            attach.Body = Blob.valueOf('AccountId\n'+TestAccount.Id);
            attach.ParentId = accountList[0].Id;
            attach.Name = 'Test Attachment';
            attachmentList.add(attach);
    
            Attachment attachment = new Attachment();
            attachment.OwnerId = usr.Id;
            attachment.Body = Blob.valueOf('AccountId \n'+TestAccount.Id);
            attachment.ParentId = accountList[1].Id;
            attachment.Name = 'Test Attachment1';
            attachmentList.add(attachment);
            insert attachmentList;
    
            test.startTest();
    
            User_AssignToAccountTeams usrAccTeam = new User_AssignToAccountTeams();
            usrAccTeam.attachment = attachmentList[0];
    
            System.assertEquals(null, usrAccTeam.executeAssignment());
    
            User_AssignToAccountTeams usrAccAssignTeam = new User_AssignToAccountTeams();
            usrAccAssignTeam.attachment = attachmentList[1];
            usrAccAssignTeam.executeAssignment();
            test.stopTest();
        }
    }
}