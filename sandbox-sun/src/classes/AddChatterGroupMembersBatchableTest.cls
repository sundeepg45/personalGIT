/**
 * This is a test class for AddChatterGroupMembersBatchable class.
 *
 * @author Jayant Yadav <jayant.yadav@accenture.com>
 * @version 2012-09-27
 * 2012-09-27 - created
 */

@isTest
private class AddChatterGroupMembersBatchableTest {
    
    static User createUser() {
        return new User(
            alias = 'st0324', email='standarduser0324@testorg.com',
            emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
            localesidkey='en_US', profileid = UserInfo.getProfileId(),
            timezonesidkey='America/Los_Angeles', username='standarduser0324@testorg.com'
        );
    }
    
    static testMethod void testBatch1() {
        User u = createUser();      
        Insert u;
        System.Test.StartTest();
        AddChatterGroupMembersBatchable obj = new  AddChatterGroupMembersBatchable();
        ID batchId = Database.executeBatch(obj);
        System.Test.StopTest();     
    }
        
    static testMethod void testSendMail() {
        AddChatterGroupMembersBatchable batchable = new AddChatterGroupMembersBatchable();
        batchable.errorList.add('test error');
        Test.startTest();
        System.assertNotEquals(null, batchable.sendErrors(null));
        Test.stopTest();
    }
}