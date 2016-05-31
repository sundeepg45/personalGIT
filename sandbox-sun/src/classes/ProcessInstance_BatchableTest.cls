/**
 * This is the test class for ProcessInstance_Batchable.
 *
 * @version 2014-04-09
 * @author Bill C Riemers <briemers@redhat.com>
 * 2014-04-09 - change zero dollar order to zero value opportunity
 * 2013-03-24 - created
 */
@isTest
private class ProcessInstance_BatchableTest {

	static Id zeroValueOpportunityRecordTypeId {
		get {
			return RecordTypeLookup.getRecordTypeId('Zero Value Opportunity','Opportunity');
		}
	}

	static ProcessInstance processInstance {
		get {
			if(processInstance == null) {
				Set<Id> targetObjectIds = new Set<Id>();
				for(ProcessInstance pi : [
					select
						Id,
						TargetObjectId,
						SystemModstamp,
						(	select Id
							from Workitems
							limit 1)
					from ProcessInstance
					order by CreatedDate desc
					limit 200 ] )
				{
					if(! targetObjectIds.contains(pi.TargetObjectId)) {
						targetObjectIds.add(pi.TargetObjectId);
						if(! pi.Workitems.isEmpty()) {
							processInstance = pi;
							break;
						}
					}
				}
			}
			return processInstance;
		}
		set;
	}

	static List<ProcessInstance> getProcessInstances(ProcessInstance_Batchable batchable) {
		List<ProcessInstance> processInstances = new List<ProcessInstance>();
		ProcessInstance_Batchable.TIME_DELAY = 0;
		batchable.lastProcessedDateTime = processInstance.SystemModstamp.addSeconds(-1);
		for(Database.QueryLocatorIterator i = batchable.start(null).iterator();i.hasNext();) {
			ProcessInstance pi = (ProcessInstance)i.next();
			if(pi.Id == processInstance.Id) {
				processInstance = pi;
				processInstances.add(pi);
				break;
			}
		}
		return processInstances;
	}

	@IsTest(SeeAllData=true)
	static void executeTest() {
		ProcessInstance_Batchable batchable = new ProcessInstance_Batchable();
		List<ProcessInstance> processInstances = getProcessInstances(batchable);
		// called just for coverage
		batchable.execute(null,processInstances);
		Opportunity opp = OpportunityTriggerBefore2Test.opportunity;
		opp.RecordTypeId = zeroValueOpportunityRecordTypeId;
		Id oppId = OpportunityTriggerBefore2Test.opportunityId;
		opp.ApprovalStatus__c = processInstance.Status;
		opp = opp.clone(true);
		Contract contract = new Contract(
			CountryOfOrder__c = 'Japan',
			Status = 'Draft',
			Notes_from_Sales__c = 'Test Notes',
			Deal_Type__c = 'Amentra',
			AccountId = opp.AccountId);
		insert contract;
		contract = contract.clone(true);
		Test.startTest();
		batchable.execute(
			new Map<Id,ProcessInstance>{processInstance.TargetObjectId => processInstance},
			new Map<Id,Opportunity>{processInstance.TargetObjectId => opp},
			new Map<Id,Contract>());
		batchable.execute(
			new Map<Id,ProcessInstance>{processInstance.TargetObjectId => processInstance},
			new Map<Id,Opportunity>(),
			new Map<Id,Contract>{processInstance.TargetObjectId => contract});
		Test.stopTest();
		System.assertNotEquals(null,contract.Pending_Approval_By__c);
		System.assertNotEquals(null,opp.AssignedApprovers__c);
	}

	@IsTest
	static void coverageTest() {
		Test.startTest();
		AbstractBatchableTest.coverageTest(new ProcessInstance_Batchable(),new List<ProcessInstance>());
		Test.stopTest();
	}
}