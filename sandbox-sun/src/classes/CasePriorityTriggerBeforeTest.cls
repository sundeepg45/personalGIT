/**
 * This is a test class for CasePriorityTriggerBefore.
 *
 * @author Bill C Riemers <briemers@redhat.com>
 * @version 2012-11-15
 * 2012-11-15 - created
 */
@isTest
private class CasePriorityTriggerBeforeTest {
	static CasePriority__c casePriority {
		get {
			if(casePriority == null) {
				Case case1 = new Case();
				insert case1;
				CasePriorityTotals__c cpt = new CasePriorityTotals__c();
				insert cpt;
				casePriority = new CasePriority__c(Case__c=case1.Id,Totals__c=cpt.Id);
			}
			return casePriority;
		}
	}

	public void assignRelativeTest() {
		casePriority.RelativeCost__c = 1.0;
		casePriority.RelativeValue__c = 2.0;
		CasePriorityTriggerBefore triggerBefore = new CasePriorityTriggerBefore(null,new List<CasePriority__c>{casePriority});
		triggerBefore.assignRelative();
		System.assertEquals(casePriority.RelativeCostFormula__c,casePriority.RelativeCost__c);
		System.assertEquals(casePriority.RelativeValueFormula__c,casePriority.RelativeValue__c);
	}

	@isTest(SeeAllData=true) // need all data to access custom settings
	static void processTriggerTest() {
		// Turn on all the triggers, and make sure everything is tested.
		AbstractTrigger.setBooleanSettings('CasePriority_Before.',true);
		// insert
		CasePriorityTriggerBefore.processTrigger(null,new List<CasePriority__c>{casePriority});
		// update
		CasePriorityTriggerBefore.processTrigger(new Map<Id,CasePriority__c>{casePriority.Id=>casePriority.clone(true)},new List<CasePriority__c>{casePriority});
		// delete
		CasePriorityTriggerBefore.processTrigger(new Map<Id,CasePriority__c>{casePriority.Id=>casePriority},null);
		// If there were any missing values, our test is invalid
		AbstractTriggerTest.validateSettings('CasePriority_Before.');
	}

	@isTest
	static void deployTest() {
		AbstractTriggerTest.deployTest('CasePriority_Before.',new List<CasePriority__c>{casePriority});
	}
}