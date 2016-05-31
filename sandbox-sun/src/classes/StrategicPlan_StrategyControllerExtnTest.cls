/**
 * This is a test class for StrategicPlan_StrategyControllerExtn.
 *
 * @version 2013-05-23
 *
 * @author Bill C Riemers <briemers@redhat.com>
 * 2013-05-23 - modified to use objects created in StrategicPlanControllerExtnTest
 * 2013-05-09 - remove unneccessary overrride
 * 2013-03-20 - created
 * Scott Coleman <scoleman@redhat.com>
 * 2013-04-30 - added coverage for saveRecord()
 */
@isTest
public class StrategicPlan_StrategyControllerExtnTest {

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

	public static StrategicPlan_Strategy__c strategy {
		get {
			if(strategy == null) {
				strategy = new StrategicPlan_Strategy__c(
					Name='Test Strategy',
					StrategicPlan__c = strategicPlanId);
				strategy.StrategicPlan__r = strategicPlan;
			}
			return strategy;
		}
	}

	public static Id strategyId {
		get {
			if(strategy.Id == null) {
				insert strategy;
			}
			return strategy.Id;
		}
	}

	@isTest
	static void createTest() {
		Test.setCurrentPage(new PageReference('/apex/StrategicPlan_StrategyNew?ids='+strategicPlanId));
		TabUIController controller = new TabUIController();
		StrategicPlan_StrategyControllerExtn extension = new StrategicPlan_StrategyControllerExtn(controller);
		System.assertEquals(null,extension.getId());
		System.assertEquals(strategicPlanId,extension.getStrategicPlanId());
		StrategicPlan_Strategy__c s = extension.getStrategy();
		System.assertEquals(null,s.Id);
		System.assertEquals(strategicPlan.Id,s.StrategicPlan__c);
		System.assertEquals(strategicPlan.Name,s.StrategicPlan__r.Name);
	}

	@isTest
	static void viewTest() {
		Test.setCurrentPage(new PageReference('/apex/StrategicPlan_StrategyView?id='+strategyId));
		ApexPages.StandardController stdController = new ApexPages.StandardController(strategy);
		StrategicPlan_StrategyControllerExtn extension = new StrategicPlan_StrategyControllerExtn(stdController);
		System.assertEquals(strategyId,extension.getId());
		System.assertEquals(strategicPlanId,extension.getStrategicPlanId());
		StrategicPlan_Strategy__c s = extension.getStrategy();
		System.assertEquals(strategyId,s.Id);
		System.assertEquals(strategy.Name,s.Name);
		System.assertEquals(strategicPlanId,s.StrategicPlan__c);
		System.assertEquals(strategicPlan.Name,s.StrategicPlan__r.Name);
		extension.newSolution();
		extension.getIsDeletable();
	}

	@isTest
	static void saveTest() {
		Test.setCurrentPage(new PageReference('/apex/StrategicPlan_StrategyView?id='+strategyId));
		TabUIController controller = new TabUIController();
		StrategicPlan_StrategyControllerExtn extension = new StrategicPlan_StrategyControllerExtn(controller);
		StrategicPlan_Strategy__c s = extension.getStrategy();
		s.Name = 'Test Strategy (edited)';
		PageReference ref = extension.saveStrategy();
		StrategicPlan_Strategy__c savedStrategy = [
			select
				Name
			from StrategicPlan_Strategy__c
			where Id = :strategyId
			limit 1 ];
		System.assertEquals('Test Strategy (edited)',savedStrategy.Name);
	}	
}