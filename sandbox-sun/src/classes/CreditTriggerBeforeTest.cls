/**
 * Test class for CreditTriggerBefore
 *
 * @author Scott Coleman <scoleman@redhat.com>
 * @version 2013-07-26
 * 2013-04-09 - Created
 * 2013-07-26 - added test for protectFields()
 */
@isTest
private class CreditTriggerBeforeTest {

	static Account account {
		get {
			if(account == null) {
				account = new Account();
        		account.Name = 'NewTest';
        		insert account;
			}
			return account;
		}
		set;
	}

	static Opportunity opp {
		get {
			if(opp == null) {
				opp = new Opportunity();
        		opp.AccountId = account.Id;
        		opp.Amount = 10000;
        		opp.CurrencyISOCode = 'USD';
        		opp.Name = 'test';
        		opp.Country_of_Order__c = 'USA';
        		opp.OpportunityType__c = 'Standard';
        		opp.StageName = 'Prepare';
        		opp.CloseDate = System.today();
        		insert opp;	
			}
			return opp;
		}
		set;
	}

	static Credit__c credit {
		get {
			if(credit == null) {
				credit = new Credit__c();
				credit.Opportunity__c = opp.Id;
			}
			return credit;
		}
		set;
	}

	@isTest(SeeAllData=true) // need all data to access custom settings
	static void processTriggerTest() {
		// Turn on all the triggers, and make sure everything is tested.
		AbstractTrigger.setBooleanSettings('Credit_Before.',true);
		// insert
		CreditTriggerBefore.processTrigger(null,new List<Credit__c>{credit});
		// update
		CreditTriggerBefore.processTrigger(new Map<Id,Credit__c>{credit.Id=>credit.clone(true)},new List<Credit__c>{credit});
		// If there were any missing values, our test is invalid
		AbstractTriggerTest.validateSettings('Credit_Before.');
	}

	@isTest
	static void deployTest() {
		AbstractTriggerTest.deployTest('Credit_Before.',new List<Credit__c>{credit});
	}

	@isTest
	static void setOppAmountTest() {
		CreditTriggerBefore creditTrigger = new CreditTriggerBefore(null,new List<Credit__c>{credit});
		creditTrigger.setOppAmount();
		System.assertEquals(opp.Amount, credit.Opportunity_Amount__c);
	}

	@isTest
	static void protectFieldsTest() {
		CreditTriggerBefore creditTrigger = new CreditTriggerBefore(null,new List<Credit__c>{credit});
		creditTrigger.protectFields();
	}
}