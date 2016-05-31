/**
 * Test class for ContractAfterTrigger.cls
 *
 * @author Scott Coleman <scoleman@redhat.com>>
 * @version 2014-01-17
 * 2013-04-15 - created
 * 2014-01-17 - added test method for sendBackToBidDesk() (US42446)
 */
@isTest
private class ContractTriggerAfterTest {

	static Account acc {
		get {
			if(acc == null) {
				acc = new Account(Name='Testing');
				insert acc;
			}
			return acc;
		}
		set;
	}

	public static Opportunity opp {
		get {
			if(opp == null) {
				opp = new Opportunity(
					Name='Opportunity Test',
					CurrencyIsoCode='USD',
					CloseDate=System.today(),
					ContractStartDate__c = System.today().addDays(1),
					StageName='Unqualified',
					OwnerId=UserInfo.getUserId(),
					AccountId=acc.Id,
					Country_of_Order__c='India',
					FulfillmentChannel__c='Direct - OEM');
				insert opp;
			}
			return opp;
		}
		set;
	}	

	static Contract contract {
		get {
			if (contract == null) {
				contract = new Contract(
					AccountId = acc.Id,
					Opportunity__c = opp.Id,
					OwnerId = UserInfo.getUserId(),
					Owner__c = null);
			}
			return contract;
		}
		set;
	}

	@isTest
	static void stageChangeNotifyTest() {
		Contract testContract1 = contract;
		testContract1.Stage__c = 'Test Stage 1';
		testContract1.Status = 'Draft'; 
		AbstractTrigger.setBooleanSettings('Contract_After.',false);
		insert testContract1;
		AbstractTrigger.setBooleanSettings('Contract_After.',true);
		ContractTriggerAfter afterTrigger = new ContractTriggerAfter(null,new Map<Id,Contract>{testContract1.Id=>testContract1});
		afterTrigger.stageChangeNotify();
		Contract testContract2 = testContract1.clone();
		testContract2.Stage__c = 'Test Stage 2';
		testContract2.Status = 'Draft';
		AbstractTrigger.setBooleanSettings('Contract_After.',false);
		insert testContract2;
		AbstractTrigger.setBooleanSettings('Contract_After.',true);
		afterTrigger = new ContractTriggerAfter(new Map<Id,Contract>{testContract1.Id=>testContract1},new Map<Id,Contract>{testContract2.Id=>testContract2});
		afterTrigger.stageChangeNotify();
	}

	@isTest
	static void sendBackToBidDeskTest() {
		//this is just a coverage test - nothing to assert because of
		// dependency on approval process
		Contract testContract1 = contract;
		testContract1.SendBackToBidDesk__c = false;
		insert testContract1;
		Contract testContract2 = testContract1.clone(true);
		testContract2.SendBackToBidDesk__c = true;
		ContractTriggerAfter afterTrigger = new ContractTriggerAfter(
				new Map<Id,Contract>{testContract1.Id=>testContract1},
				new Map<Id,Contract>{testContract1.Id=>testContract2});
		afterTrigger.sendBackToBidDesk();
		Test.startTest();
		try {
			ContractTriggerAfter.submitContract(testContract1.Id);
		}
		catch(Exception ex) {}
		Test.stopTest();
	}

	@isTest(SeeAllData=true) // need all data to access custom settings
	static void processTriggerTest() {
		// Turn off all the triggers for the insert
		AbstractTrigger.setBooleanSettings('Contract_After.',false);
		// update test
		insert contract;
		// Turn on all the triggers, and make sure everything is tested.
		AbstractTrigger.setBooleanSettings('Contract_After.',true);
		ContractTriggerAfter.processTrigger(new Map<Id,Contract>{contract.Id=>contract},new Map<Id,Contract>{contract.Id=>contract});
		// If there were any missing values, our test is invalid
		AbstractTriggerTest.validateSettings('Contract_After.');
	}

	// Just invoke the trigger.  We already tested the results in the above
	// methods.  If we check it here then we can have deployment problems
	// as the trigger may be deployed after the class, or could be inactive.
	@isTest
	static void deployTest() {
		AbstractTriggerTest.deployTest('Contract_After.',new List<Contract>{contract},true,false,true);
	}
}