/**
 * This is a test class for StrategicPlan_SolutionControllerExtn.
 *
 * @version 2013-08-08
 *
 * @author Bill C Riemers <briemers@redhat.com>
 * 2013-08-08 - Renamed OpportunityTriggerAfterTest to OpportunityTriggerAfter2Test
 * 2013-05-23 - updated test object inheritance
 * 2013-05-09 - remove unneccessary overrride
 * 2013-03-20 - created
 * Scott Coleman <scoleman@redhat.com>
 * 2013-04-30 - added coverage for saveRecord()
 */
@isTest
public class StrategicPlan_SolutionControllerExtnTest {
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
			if(solution == null) {
				solution = new StrategicPlan_Solution__c(
					Name='Test Solution',
					StrategicPlan__c = strategy.StrategicPlan__c,
					Strategy__c = strategyId);
				solution.Strategy__r = strategy;
				solution.StrategicPlan__r = strategy.StrategicPlan__r;
			}
			return solution;
		}
	}

	public static Id solutionId {
		get {
			if(solution.Id == null) {
				insert solution;
			}
			return solution.Id;
		}
	}

	static Opportunity opportunity {
		get {
			return OpportunityTriggerAfter2Test.opportunity;
		}
	}

	@isTest
	static void createTest() {
		Test.setCurrentPage(new PageReference('/apex/StrategicPlan_SolutionNew?ids='+strategyId));
		TabUIController controller = new TabUIController();
		StrategicPlan_SolutionControllerExtn extension = new StrategicPlan_SolutionControllerExtn(controller);
		System.assertEquals(null,extension.getId());
		System.assertEquals(strategy.StrategicPlan__c,extension.getStrategicPlanId());
		System.assertEquals(strategyId,extension.getStrategyId());
		StrategicPlan_Solution__c s = extension.getSolution();
		System.assertEquals(null,s.Id);
		System.assertEquals(strategy.StrategicPlan__c,s.StrategicPlan__c);
		System.assertEquals(strategyId,s.Strategy__c);
		System.assertEquals(strategy.Name,s.Strategy__r.Name);
		System.assertEquals(strategy.StrategicPlan__c,s.Strategy__r.StrategicPlan__c);
		System.assertEquals(strategy.StrategicPlan__r.Name,s.Strategy__r.StrategicPlan__r.Name);
	}

	@isTest
	static void viewTest() {
		Test.setCurrentPage(new PageReference('/apex/StrategicPlan_SolutionView?id='+solutionId));
		ApexPages.StandardController stdController = new ApexPages.StandardController(solution);
		StrategicPlan_SolutionControllerExtn extension = new StrategicPlan_SolutionControllerExtn(stdController);
		System.assertEquals(solutionId,extension.getId());
		System.assertEquals(strategy.StrategicPlan__c,extension.getStrategicPlanId());
		System.assertEquals(strategyId,extension.getStrategyId());
		StrategicPlan_Solution__c s = extension.getSolution();
		System.assertEquals(solutionId,s.Id);
		System.assertEquals(solution.Name,s.Name);
		System.assertEquals(strategy.StrategicPlan__c,s.StrategicPlan__c);
		System.assertEquals(strategyId,s.Strategy__c);
		System.assertEquals(strategy.Name,s.Strategy__r.Name);
		System.assertEquals(strategy.StrategicPlan__c,s.Strategy__r.StrategicPlan__c);
		System.assertEquals(strategy.StrategicPlan__r.Name,s.Strategy__r.StrategicPlan__r.Name);
		extension.getIsDeletable();
	}

	@isTest
	static void saveTest() {
		Test.setCurrentPage(new PageReference('/apex/StrategicPlan_SolutionView?id='+solutionId));
		TabUIController controller = new TabUIController();
		StrategicPlan_SolutionControllerExtn extension = new StrategicPlan_SolutionControllerExtn(controller);
		StrategicPlan_Solution__c s = extension.getSolution();
		s.Name = 'Test Solution (edited)';
		PageReference ref = extension.saveSolution();
		StrategicPlan_Solution__c savedSolution = [
			select
				Name
			from StrategicPlan_Solution__c
			where Id = :solutionId
			limit 1 ];
		System.assertEquals('Test Solution (edited)',savedSolution.Name);
	}

	@isTest(SeeAllData=true) // need to see all data to load custom setting
	static void customSettingTest() {
		System.assertNotEquals(null,StringSetting__c.getInstance(StrategicPlan_SolutionControllerExtn.CREATED_FROM_SOLUTION_CF).Value__c);
	}

	@isTest
	static void opportunityTests() {
		insert new StringSetting__c(Name=StrategicPlan_SolutionControllerExtn.CREATED_FROM_SOLUTION_CF,Value__c='00Ng0000000P8cc');
		Test.setCurrentPage(new PageReference('/apex/StrategicPlan_SolutionNew?ids='+solutionId));
		TabUIController controller = new TabUIController();
		StrategicPlan_SolutionControllerExtn extension = new StrategicPlan_SolutionControllerExtn(controller);
		System.assertNotEquals(null,extension.createOpportunity());
		insert opportunity;
		extension.solutionOpportunity.Opportunity__c = opportunity.Id;
		extension.linkOpportunity();
		StrategicPlan_SolutionOpportunity__c solutionOpportunity = [
			select
				StrategicPlan_Solution__c,
				Opportunity__c
			from StrategicPlan_SolutionOpportunity__c
			where Opportunity__c = :opportunity.Id];
		System.assertEquals(solution.Id,solutionOpportunity.StrategicPlan_Solution__c);
		extension.linkOpportunity();
		extension.solutionOpportunity.Opportunity__c = opportunity.Id;
		System.assertEquals(solutionOpportunity.Id,extension.getSolutionOpportunityId());
		extension.solutionOpportunity = null;
		extension.setSolutionOpportunityId(solutionOpportunity.Id);
		System.assertEquals(solutionOpportunity.Id,extension.getSolutionOpportunityId());
		extension.setSolutionOpportunityId(null);
		System.assertEquals(solutionOpportunity.Id,extension.getSolutionOpportunityId());
		extension.unlinkOpportunity();
		System.assertEquals(0,[select Count() from StrategicPlan_SolutionOpportunity__c where Opportunity__c = :opportunity.Id]);
		extension.unlinkOpportunity();
	}
}