/**
 * Test class for OpportunityTriggerAfter.cls
 *
 * @version 2015-01-27
 * @author Scott Coleman <scoleman@redhat.com>
 * 2012-07-12 - Created
 * 2012-08-10 - Updated with additional asserts
 * 2013-02-26 - Added test for proof of concept product copy
 * Bill Riemers <briemers@redhat.com>
 * 2015-01-27 - Depreciated
 * 2013-07-18 - Updating to PrimaryBusinessUnit__c 
 * 2013-06-19 - Correct linkSolutions test.
 * 2013-04-04 - Add test for linkSolutions.  Add missing test methods.
 */
@isTest
public class OpportunityTriggerAfterTest {
//depreciated	static StrategicPlan_Solution__c solution {
//depreciated		get {
//depreciated			return StrategicPlan_SolutionControllerExtnTest.solution;
//depreciated		}
//depreciated	}

//depreciated	static Id solutionId {
//depreciated		get {
//depreciated			return StrategicPlan_SolutionControllerExtnTest.solutionId;
//depreciated		}
//depreciated	}

//depreciated	public static Opportunity opportunity {
//depreciated		get {
//depreciated			if(opportunity == null) {
//depreciated				RecordType recordType2 = [
//depreciated					select Id,name
//depreciated					from RecordType
//depreciated					where name like 'EMEA %'
//depreciated						and SObjectType = 'Opportunity'
//depreciated						and IsActive = true
//depreciated					limit 1 ];
//depreciated				opportunity = new Opportunity(
//depreciated					Name='Opportunity Test',
//depreciated					CloseDate=System.today(),
//depreciated					StageName='Unqualified',
//depreciated					OwnerId=UserInfo.getUserId(),
//depreciated					AccountId=solution.StrategicPlan__r.Account__c,
//depreciated					Country_of_Order__c='India',
//depreciated					FulfillmentChannel__c='Direct - OEM',
//depreciated					RecordTypeId = recordType2.Id);
//depreciated			}
//depreciated			return opportunity;
//depreciated		}
//depreciated	}

//depreciated	@IsTest(SeeAllData=true)
//depreciated	static void insertOpportunitySnapshotTest() {
//depreciated		Opportunity opp = opportunity;
//depreciated		insert opp;
//depreciated		List<Opportunity> opportunities = new List<Opportunity>{opp};
//depreciated		Map<Id,Opportunity> oldMap = new Map<Id,Opportunity>{ opp.Id => opp };
//depreciated		List<Opportunity> newList = opportunities.deepClone(true);
//depreciated		Map<Id,Opportunity> newMap = new Map<Id,Opportunity>(newList);
//depreciated		newList[0].Rush_Order__c = true;
//depreciated		newList[0].Rush_Order_Reason__c = 'test';
//depreciated		OpportunityTriggerAfter trig = new OpportunityTriggerAfter(oldMap,newMap);
//depreciated		trig.insertOpportunitySnapshot();
//depreciated		List<OpportunitySnapshot__c> snapshots = [
//depreciated			select
//depreciated				Name,
//depreciated				RushOrderFrom__c,
//depreciated				RushOrderTo__c,
//depreciated				RushOrderReasonFrom__c,
//depreciated				RushOrderReasonTo__c,
//depreciated				RushOrderSetBySystemFrom__c,
//depreciated				RushOrderSetBySystemTo__c
//depreciated			from OpportunitySnapshot__c 
//depreciated			where Opportunity__c = :opp.Id];
//depreciated		System.assert(snapshots.size()==1, 'Incorrect number of OpportunitySnapshot__c records generated');
//depreciated		System.assertEquals(false,snapshots[0].RushOrderFrom__c);
//depreciated		System.assertEquals(true,snapshots[0].RushOrderTo__c);
//depreciated		System.assertEquals(null,snapshots[0].RushOrderReasonFrom__c);
//depreciated		System.assertEquals('test',snapshots[0].RushOrderReasonTo__c);
//depreciated		System.assertEquals(false,snapshots[0].RushOrderSetBySystemFrom__c);
//depreciated		System.assertEquals(false,snapshots[0].RushOrderSetBySystemTo__c);
//depreciated	}

//depreciated	@IsTest(SeeAllData=true)
//depreciated	static void copyProofOfConceptProductsTest() {
//depreciated		Opportunity opp = OpportunityTriggerBeforeTest.opportunity;
//depreciated		opp.Pricebook2Id = OpportunityTriggerAfter.globalPricebookId;
//depreciated		Opportunity poc = opp.clone(false,true,false,false);
//depreciated		upsert new List<Opportunity>{opp,poc};
//depreciated		poc.Name = 'Test POC';
//depreciated		poc.RecordTypeId = OpportunityTriggerAfter.pocRecordTypeId;
//depreciated		poc.PrimaryBusinessUnit__c = 'TestBU';
//depreciated		update poc;
//depreciated		List<OpportunityLineItem> lineItems = new List<OpportunityLineItem>{OpportunityTriggerBeforeTest.opportunityLineItemGlobal};
//depreciated		List<OpportunityLineItem> sourceLineItems = lineItems.deepClone(false);
//depreciated		for(OpportunityLineItem lineItem : sourceLineItems) {
//depreciated			lineItem.OpportunityId = opp.Id;
//depreciated			lineItem.TotalPrice = null;
//depreciated		}
//depreciated		insert sourceLineItems;
//depreciated		poc.Cloned_From_Opportunity__c = opp.Id;
//depreciated		OpportunityTriggerAfter trig = new OpportunityTriggerAfter(null,new Map<Id,Opportunity>{poc.Id=>poc});
//depreciated		trig.copyProofOfConceptProducts();
//depreciated		List<OpportunityLineItem> targetLineItems = [SELECT Id FROM OpportunityLineItem WHERE OpportunityId = :poc.Id];
//depreciated		System.assertNotEquals(opp.Id,poc.Id);
//depreciated		System.assert(targetLineItems.size() > 0);
//depreciated	}

//depreciated	@isTest
//depreciated	static void linkSolutionsTest() {
//depreciated		insert new BooleanSetting__c(Name=OpportunityTriggerAfter.LINK_SOLUTIONS_SETTING,Value__c=false);
//depreciated		insert opportunity;
//depreciated		opportunity.CreatedFromSolution__c = solutionId;
//depreciated		OpportunityTriggerAfter afterTrigger = new OpportunityTriggerAfter(
//depreciated			null,
//depreciated			new Map<Id,Opportunity>{opportunity.Id=>opportunity} );
//depreciated		afterTrigger.linkSolutions();
//depreciated		StrategicPlan_SolutionOpportunity__c solutionOpportunity = [
//depreciated			select
//depreciated				StrategicPlan_Solution__c,
//depreciated				Opportunity__c
//depreciated			from StrategicPlan_SolutionOpportunity__c
//depreciated			where Opportunity__c = :opportunity.Id];
//depreciated		System.assertEquals(solutionId,solutionOpportunity.StrategicPlan_Solution__c);
//depreciated		System.assert(! afterTrigger.hasErrors);
//depreciated		delete solution;
//depreciated		afterTrigger.linkSolutions();
//depreciated		System.assert(afterTrigger.hasErrors);
//depreciated	}

//depreciated	@isTest(SeeAllData=true) // need all data to access price books?
//depreciated	static void processTriggerTest() {
//depreciated		// Turn off all triggers, as we are going to test those next
//depreciated		AbstractTrigger.setBooleanSettings('Opp_After.',false);
//depreciated		// insert missing boolean settings
//depreciated		AbstractTrigger.insertMissing = 0;
//depreciated		OpportunityTriggerAfter.processTrigger(null,new Map<Id,Opportunity>{null=>opportunity});
//depreciated		// insert the opportunity, again with the triggers off
//depreciated		insert opportunity;
//depreciated		// Turn on all the triggers, and make sure everything is tested.
//depreciated		AbstractTrigger.setBooleanSettings('Opp_After.',true);
//depreciated		Opportunity opp2 = opportunity.clone(true);
//depreciated		Test.startTest();
//depreciated		// insert test
//depreciated		OpportunityTriggerAfter.processTrigger(null,new Map<Id,Opportunity>{opp2.Id=>opp2});
//depreciated		// update test
//depreciated		OpportunityTriggerAfter.processTrigger(new Map<Id,Opportunity>{opportunity.Id=>opportunity},new Map<Id,Opportunity>{opp2.Id=>opp2});
//depreciated		// delete test
//depreciated		OpportunityTriggerAfter.processTrigger(new Map<Id,Opportunity>{opportunity.Id=>opportunity},null);
//depreciated		Test.stopTest();
//depreciated		// Confirm all missing settings were added
//depreciated		AbstractTriggerTest.validateSettings('Opp_After.');
//depreciated	}

//depreciated	@isTest
//depreciated	static void deployTest() {
//depreciated		AbstractTriggerTest.deployTest('Opp_After.',new List<Opportunity>{opportunity});
//depreciated	}

}