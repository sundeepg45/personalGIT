/**
 * This is a test class for CaseTriggerAfter.
 *
 * @author Bill C Riemers <briemers@redhat.com>
 * @version 2012-11-15
 * 2012-11-15 - created
 */
@isTest
private class CaseTriggerAfterTest {
	static Case case1 {
		get {
			if (case1 == null) {
				case1 = new Case(
					RelativeBenefit__c=1.0,
					RelativePenalty__c=1.0,
					RelativeCost__c=1.0);
			}
			return case1;
		}
	}

	@isTest
	static void upsertCasePriorityTest() {
		upsert new BooleanSetting__c(Name=CaseTriggerAfter.UPSERT_CASE_PRIORITY,Value__c=false);
		Case case2 = new Case();
		insert new List<Case>{case1,case2};
		// make sure the trigger really is disabled
		System.assertEquals(0,[select Count() from CasePriority__c where Case__c in :new Set<Id>{case1.Id,case2.Id}]);
		// insert test
		CaseTriggerAfter triggerAfter = new CaseTriggerAfter(null,new Map<Id,Case>{case1.Id=>case1,case2.Id=>case2});
		triggerAfter.upsertCasePriority();
		System.assertEquals(1,[select Count() from CasePriority__c where Case__c in :new Set<Id>{case1.Id,case2.Id}]);
		// update test
		Case case3 = new Case(Id=case2.Id,RelativeBenefit__c=1.0);
		triggerAfter = new CaseTriggerAfter(new Map<Id,Case>{case2.Id=>case2},new Map<Id,Case>{case3.Id=>case3});
		triggerAfter.upsertCasePriority();
		System.assertEquals(1,[select Count() from CasePriority__c where Case__c = :case3.Id]);
	}

	@isTest(SeeAllData=true) // need all data to access custom settings
	static void processTriggerTest() {
		// Turn on all the triggers, and make sure everything is tested.
		AbstractTrigger.setBooleanSettings('Case_Before.',true);
		AbstractTrigger.setBooleanSettings('Case_After.',true);
		// update test
		insert case1;
		CaseTriggerAfter.processTrigger(new Map<Id,Case>{case1.Id=>case1},new Map<Id,Case>{case1.Id=>case1});
		// If there were any missing values, our test is invalid
		AbstractTriggerTest.validateSettings('Case_After.');
	}

	// Just invoke the trigger.  We already tested the results in the above
	// methods.  If we check it here then we can have deployment problems
	// as the trigger may be deployed after the class, or could be inactive.
	@isTest
	static void deployTest() {
		AbstractTriggerTest.deployTest('Case_After.',new List<Case>{case1},true,false,true);
	}
}