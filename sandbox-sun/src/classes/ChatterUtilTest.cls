/**
 * Test class for the static Chatter util class
 *
 * @author Scott Coleman <scoleman@redhat.com>
 * @version 2013-04-11
 * 2013-04-11 - created
 */
@isTest
private class ChatterUtilTest {

	static User user {
		get {
			if(user==null) {
				user = new User(
					alias = 'st7482', email='standarduser7482@testorg.com',
					emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
					localesidkey='en_US', profileid = UserInfo.getProfileId(),
					timezonesidkey='America/Los_Angeles', username='standarduser7482@testorg.com');

				System.runAs(new User(Id = UserInfo.getUserId())) {
					insert user;
				}
			}
			return user;
		}
		set;
	}

	static Account acc {
		get {
			if(acc == null) {
				acc = new Account(Name='Testing');
				insert acc;
			}
			return acc;
		}
	}

	static Opportunity opp {
		get {
			if(opp == null) {
				opp = new Opportunity(
					Name='Testing',
					AccountId=acc.Id,
					FulfillmentChannel__c = 'Direct - VAR/VAD',
					Country_of_Order__c = 'United States',
					CurrencyIsoCode = 'USD',
					Pay_Now__c = 'Yes',
					CloseDate=System.today(),
					OpportunityType__c='Standard',
					StageName='Prepare',
					Amount = 3000.00 );
				insert opp;
			}
			return opp;
		}
	}

	@isTest
    static void testGroups() {
        Id groupId = ChatterUtil.createGroup('Test Group', true);
        CollaborationGroup chatterGroup = ChatterUtil.getGroup(groupId);
        system.assertEquals('Test Group',chatterGroup.Name);
        List<CollaborationGroup> chatterGroups = ChatterUtil.findGroup('Test');
        system.assertEquals(1,chatterGroups.size());
        system.assertEquals('Test Group',chatterGroups[0].Name);
        ChatterUtil.addUsersToGroup(groupId, new List<User>{user});
        ChatterUtil.postGroupMessage(groupId, 'Test message');
        ChatterUtil.deleteUsersFromGroup(groupId, new List<User>{user});
        ChatterUtil.deleteGroup(groupId);
        chatterGroup = ChatterUtil.getGroup(groupId);
        system.assertEquals(null,chatterGroup);
        chatterGroups = ChatterUtil.findGroup('Test');
        system.assertEquals(0,chatterGroups.size());
    }
 
 	@isTest
 	static void testMessages() {
 		ChatterUtil.postMessage(opp.Id, 'Test Opp Message');
 		ChatterUtil.postMessage(opp.Id, 'Test Opp Message with mentions', new List<User>{user}, null);
 	}
 
}