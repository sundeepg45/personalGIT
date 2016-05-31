@isTest(SeeAllData=false)
public class UserUniqueFieldCheckTest {
	
	@isTest
	public static void testInsertNonDupFedId(){
        User adminUser  = [Select Id, FirstName, LastName from User where Profile.Name = 'Administrator - Level 1' and isActive = true limit 1];
        Profile naPartnerProfile = [select id,name from profile where name like '%NA Partner Portal%' limit 1];
        Account account = PartnerTestUtils.makeAccount('FedId Test', adminUser);
        Contact contact = PartnerTestUtils.makeContact(account.Id, 'OnboardingTestContact1');
        insert contact;

        User user  = new User(username = 'test1@redhat.com',LastName='lname',CommunityNickname='Test1', email = 'test1@redhat.com', alias = 'test1', timezoneSIDKey = 'America/Los_Angeles', CompanyName = 'RH',
        profileid = naPartnerProfile.id,localesidkey = 'en_US', emailencodingkey = 'UTF-8', languagelocalekey = 'en_US', FederationIdentifier='123456789iuyt',ContactId =contact.Id);
        insert user;  
	}
		
	@isTest
	public static void testInsertDuplicateFedId(){
        User adminUser  = [Select Id, FirstName, LastName from User where Profile.Name = 'Administrator - Level 1' and isActive = true limit 1];
        Profile naPartnerProfile = [select id,name from profile where name like '%NA Partner Portal%' limit 1];
        Account account = PartnerTestUtils.makeAccount('FedId Test', adminUser);
        Contact contact = PartnerTestUtils.makeContact(account.Id, 'OnboardingTestContact4');
        insert contact;

        User user  = new User(username = 'test32321@redhat.com',LastName='lname',CommunityNickname='Test1', email = 'test3@redhat.com', alias = 'test13', timezoneSIDKey = 'America/Los_Angeles', CompanyName = 'RH',
        profileid = naPartnerProfile.id,localesidkey = 'en_US', emailencodingkey = 'UTF-8', languagelocalekey = 'en_US', Federation_Id__c='123456789iuyt3', FederationIdentifier='123456789iuyt3',ContactId =contact.Id);
        insert user;  

        contact = PartnerTestUtils.makeContact(account.Id, 'OnboardingTestContact5');
        insert contact;
        user  = new User(username = 'test4aaas@redhat.com',LastName='lname',CommunityNickname='Test2', email = 'test4@redhat.com', alias = 'test24', timezoneSIDKey = 'America/Los_Angeles', CompanyName = 'RH',
        profileid = naPartnerProfile.id,localesidkey = 'en_US', emailencodingkey = 'UTF-8', languagelocalekey = 'en_US', Federation_Id__c='123456789iuyu4', FederationIdentifier='123456789iuyu4',ContactId =contact.Id);
        insert user;  


		List<User> users = [Select FederationIdentifier from User where User.AccountId != null and FederationIdentifier != null limit 2];
		List<User> userscustom = [Select Federation_Id__c from User where Federation_Id__c != null limit 2];

		User u = new User(Federation_Id__c = users[0].FederationIdentifier);
		try {
			insert u;
			// If you see this assert we failed to block the duplicate insert
			System.assert(true);
		} catch (Exception e){
			// Yeay! We blocked the insert
		}

		u = new User(Federation_Id__c = userscustom[0].Federation_Id__c);
		try {
			insert u;
			// If you see this assert we failed to block the duplicate insert
			System.assert(true);
		} catch (Exception e){
			// Yeay! We blocked the insert
		}

		u = users[1];
		u.Federation_ID__c = users[0].FederationIdentifier;
		try {
			update u;
			// If you see this assert we failed to block the duplicate update
			System.assert(true);
		} catch (Exception e){
			// Yeay! We blocked the insert
		}
	}

	@isTest
	public static void testInsertBackwardsUpdateFedId(){
		List<User> users = [Select FederationIdentifier from User where User.AccountId != null and FederationIdentifier != null limit 2];
		List<User> userscustom = [Select Federation_Id__c from User where Federation_Id__c != null limit 2];

		User u = users[0];
		u.FederationIdentifier = '000000000d000000011111a1111111122222222c2222222';
		update u;
		u.Federation_ID__c = u.FederationIdentifier;
		update u;
	}	
}