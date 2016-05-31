/**
 * This test class tests the AccountProfileSWOTController class.
 *
 * @version 2013-05-23
 * @author Bill C Riemers <briemers@redhat.com>
 * 2013-05-23 - Assign Account__c in the accountProfile creation
 * 2012-11-09 - created
 */
@isTest
public class AccountProfileSWOTControllerTest {
	public static Account account {
		get {
			if(account == null) {
				account = new Account(
					Name='TestAccount',
					Data_Status__c=AccountTriggerBeforeLock.PENDING_DATA_REVIEW,
					AccountClassification__c='EMEA - Hosting',
					BillingCity='Testville',
					BillingStreet='1 no where',
					BillingCountry='US',
					Middleware_Supported__c='None',
					OwnerId = UserInfo.getUserId(),
					Ownership = 'Private',
					Total_of_Subsidiaries_if_Parent__c=5,
					VATNumber__c=null,
					What_Markets_are_Targeted__c='Vertical market');
			}
			return account;
		}
		
	}

	public static Id accountId {
		get {
			if(account.Id == null) {
				insert account;
			}
			return account.Id;
		}
	}

	public static Account_Profile__c createAccountProfile(Id xaccountId) {
		return new Account_Profile__c(
			Account__c = xaccountId);
	}

	public static Account_Profile__c accountProfile {
		get {
			if(accountProfile == null) {
				accountProfile = createAccountProfile(accountId);
				accountProfile.Account__r = account;
			}
			return accountProfile;
		}
	}

	public static Id accountProfileId {
		get {
			if(accountProfile.Id == null) {
				insert accountProfile;
			}
			return accountProfile.Id;
		}
	}

	public static Account_Profile_SWOT__c createAccountProfileSWOT(Id profileId,String statement,String typeValue) {
		return new Account_Profile_SWOT__c(Account_Profile__c=profileId,Statement__c=statement,Type__c=typeValue);
	}

	public static List<Account_Profile_SWOT__c> createSWOTs(Id profileId) {
		return new List<Account_Profile_SWOT__c>{
			createAccountProfileSWOT(profileId,'Statement 1',AccountProfileSWOTController.STRENGTH),
			createAccountProfileSWOT(profileId,'Statement 2',AccountProfileSWOTController.WEAKNESS),
			createAccountProfileSWOT(profileId,'Statement 3',AccountProfileSWOTController.OPPORTUNITY),
			createAccountProfileSWOT(profileId,'Statement 4',AccountProfileSWOTController.THREAT) };
	}

	static AccountProfileSWOTController controller {
		get {
			if(controller == null) {
				controller = new AccountProfileSWOTController();
			}
			return controller;
		}
	}

	@isTest
	static void accountProfileSWOTsTest() {
		List<Account_Profile_SWOT__c> accountProfileSWOTs = createSWOTs(accountProfileId);
		insert accountProfileSWOTs;
		controller.accountProfileId = accountProfileId;
		Map<Id,Account_Profile_SWOT__c> swotMap = new Map<Id,Account_Profile_SWOT__c>(
			controller.accountProfileSWOTs);
		System.assertEquals(accountProfileSWOTs.size(),swotMap.size());
		for(Account_Profile_SWOT__c swot : accountProfileSWOTs) {
			System.assert(swotMap.containsKey(swot.Id),'Missing SWOT Analysis object '+swot);
		}
	}

	@isTest
	static void filterTest() {
		controller.accountProfileSWOTs = createSWOTs(null);
		Integer i = 0;
		for(Account_Profile_SWOT__c swot : controller.getStrengths()) {
			System.assertEquals(AccountProfileSWOTController.STRENGTH,swot.Type__c);
			i++;
		}
		System.assertEquals(1,i);
		for(Account_Profile_SWOT__c swot : controller.getWeaknesses()) {
			System.assertEquals(AccountProfileSWOTController.WEAKNESS,swot.Type__c);
			i++;
		}
		System.assertEquals(2,i);
		for(Account_Profile_SWOT__c swot : controller.getOpportunities()) {
			System.assertEquals(AccountProfileSWOTController.OPPORTUNITY,swot.Type__c);
			i++;
		}
		System.assertEquals(3,i);
		for(Account_Profile_SWOT__c swot : controller.getThreats()) {
			System.assertEquals(AccountProfileSWOTController.THREAT,swot.Type__c);
			i++;
		}
		System.assertEquals(4,i);
	}
}