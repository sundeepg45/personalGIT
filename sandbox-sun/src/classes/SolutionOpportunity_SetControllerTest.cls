/**
 * This is a test class for the SolutionOpportunity_SetController class.
 * 
 * @version 2013-09-03
 * @author Bill C Riemers <briemers@redhat.com>
 * 2013-09-03 - Created.
 */
@isTest
private class SolutionOpportunity_SetControllerTest {
	static StrategicPlan_Strategy__c strategy {
		get {
			return StrategicPlan_StrategyControllerExtnTest.strategy;
		}
	}

	static Id strategyId {
		get {
			return StrategicPlan_StrategyControllerExtnTest.strategyId;
		}
	}

	public static StrategicPlan_Solution__c solution {
		get {
			return StrategicPlan_SolutionControllerExtnTest.solution;
		}
	}

	public static Id solutionId {
		get {
			return StrategicPlan_SolutionControllerExtnTest.solutionId;
		}
	}

	static Opportunity opportunity {
		get {
			return OpportunityTriggerAfter2Test.opportunity;
		}
	}

	static void lookupTest() {
		PageReference r = new PageReference('/apex/SolutionOpportunity_Manage');
		r.getParameters().put('id',solutionId);
		Test.setCurrentPage(r);
		System.assertEquals(0,[select count() from StrategicPlan_SolutionOpportunity__c]);
		Test.startTest();
		SolutionOpportunity_SetController psc = new SolutionOpportunity_SetController();
		System.assertNotEquals(null,psc.opportunityRecords);
		List<SolutionOpportunity_SetController.SolutionOpportunity> paginations = psc.getSolutionOpportunityPagination();
		System.assertEquals(1,paginations.size());
		for(SolutionOpportunity_SetController.SolutionOpportunity so : paginations) {
			System.assertNotEquals(null,so.getSolutionOpportunity());
			so.linkOpportunity();
			System.assertEquals(1,[select count() from StrategicPlan_SolutionOpportunity__c]);
			so.unlinkOpportunity();
			System.assertEquals(0,[select count() from StrategicPlan_SolutionOpportunity__c]);
		}
		System.assertEquals(1,psc.getPageCount());
		// the following are just for coverage
		psc.last();
		psc.first();
		psc.next();
		psc.previous();
		psc.updateSearchString();
		// now lets try a search that fails
		psc.searchString = 'DOGGY DOG';
		System.assertNotEquals(null,psc.opportunityRecords);
		System.assertEquals(0,psc.getSolutionOpportunityPagination().size());
		Test.stopTest();
		System.assertNotEquals(null,psc.cancel());
	}

	@isTest
	static void lookupTest1() {
		insert opportunity;
		lookupTest();
	}

	@isTest
	static void lookupTest2() {
		insert opportunity;
		Account parent = AccountProfileSWOTControllerTest.account.clone();
		insert parent;
		Account account = new Account(Id=opportunity.AccountId,ParentId=parent.Id);
		update account;
		List<AccountHierarchy__c> accountHierarchies = new List<AccountHierarchy__c>{
			new AccountHierarchy__c(Account__c=parent.Id,AccountId__c=parent.Id),
			new AccountHierarchy__c(Account__c=account.Id,AccountId__c=account.Id) };
		insert accountHierarchies;
		accountHierarchies[1].Parent__c = accountHierarchies[0].Id;
		accountHierarchies[1].UltimateParent__c = accountHierarchies[0].Id;
		update accountHierarchies;
		lookupTest();
	}
}