/**
 * Test methods for AccountProfileExecSummaryController.cls
 *
 * @version 2013-10-04
 * @author Scott Coleman <scoleman@redhat.com>
 * 2013-10-04 - created
 */
@isTest
private class AccountProfileExecSummaryControllerTest {
   
	static StrategicPlan__c strategicPlan {
		get {
			return StrategicPlanControllerExtnTest.strategicPlan;
		}
	}

	static Id strategicPlanId {
		get {
			return StrategicPlanControllerExtnTest.strategicPlanId;
		}
	}
    
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

	static StrategicPlan_Solution__c solution {
		get {
			return StrategicPlan_SolutionControllerExtnTest.solution;
		}
	}

	static Id solutionId {
		get {
			return StrategicPlan_SolutionControllerExtnTest.solutionId;
		}
	}

    @isTest
    static void getRecordsTest() {
        //creating a test solution will cause creation of a strategy, plan, profile, and account
        Id testSolutionId = solutionId;
        Id accountProfileId = strategicPlan.AccountProfile__c;
        AccountProfileExecSummaryController controller = new AccountProfileExecSummaryController(accountProfileId);
        Account fetchedAccount = controller.account;
        Account_Profile__c fetchedAccountProfile = controller.accountProfile;
       	List<Opportunity> fetchedOpps = controller.opportunities;
        StrategicPlan__c fetchedStrategicPlan = controller.strategicPlan;
        List<StrategicPlan_Strategy__c> fetchedStrategies = controller.strategies;
        system.assertNotEquals(null, fetchedAccount);
        system.assertNotEquals(null, fetchedAccountProfile);
        system.assertNotEquals(null, fetchedStrategicPlan);
        system.assertNotEquals(0,fetchedStrategies.size());
    }
}