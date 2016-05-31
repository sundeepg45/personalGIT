/**
 * This is a test class for CasePriorityTriggerAfter.
 *
 * @author Bill C Riemers <briemers@redhat.com>
 * @version 2012-11-15
 * 2012-11-15 - created
 */
@isTest
private class CasePriorityTriggerAfterTest {
	static Case case1 {
		get {
			if (case1 == null) {
				case1 = new Case(
					RelativeBenefit__c=1.0,
					RelativePenalty__c=1.0,
					RelativeCost__c=1.0);
				insert case1;
				delete [select Id from CasePriority__c where Case__c = :case1.Id];
			}
			return case1;
		}
	}

	static CasePriority__c casePriority {
		get {
			if(casePriority == null) {
				CasePriorityTotals__c totals = new CasePriorityTotals__c();
				insert totals;
				casePriority = new CasePriority__c(Case__c=case1.Id,Totals__c=totals.Id);
			}
			return casePriority;
		}
	}

	@isTest
	static void updateCaseTest() {
		insert new BooleanSetting__c(Name=CasePriorityTriggerAfter.UPDATE_CASE,Value__c=false);
		insert casePriority;
		Case c = [select CasePriority__c from Case where Id = :casePriority.Case__c];
		System.assertNotEquals(casePriority.Id,c.CasePriority__c);
		CasePriorityTriggerAfter cpta = new CasePriorityTriggerAfter(null,new Map<Id,CasePriority__c>{casePriority.Id=>casePriority});
		cpta.updateCase();
		c = [select CasePriority__c from Case where Id = :casePriority.Case__c];
		System.assertEquals(casePriority.Id,c.CasePriority__c);
	}

	@isTest(SeeAllData=true) // need all data to access custom settings
	static void processTriggerTest() {
		// Turn off all the triggers for the insert
		AbstractTrigger.setBooleanSettings('CasePriority_After.',false);
		// update test
		insert casePriority;
		// Turn on all the triggers, and make sure everything is tested.
		AbstractTrigger.setBooleanSettings('CasePriority_After.',true);
		CasePriorityTriggerAfter.processTrigger(new Map<Id,CasePriority__c>{casePriority.Id=>casePriority},new Map<Id,CasePriority__c>{casePriority.Id=>casePriority});
		// If there were any missing values, our test is invalid
		AbstractTriggerTest.validateSettings('CasePriority_After.');
	}

	// Just invoke the trigger.  We already tested the results in the above
	// methods.  If we check it here then we can have deployment problems
	// as the trigger may be deployed after the class, or could be inactive.
	@isTest
	static void deployTest() {
		AbstractTriggerTest.deployTest('CasePriority_After.',new List<CasePriority__c>{casePriority},true,false,true);
	}
}