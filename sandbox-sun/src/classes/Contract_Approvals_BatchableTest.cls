/**
 * This class a test class for Contract_Approvals_Batchable.
 *
 * @author Scott Coleman <scoleman@redhat.com>
 * @version 2014-01-23
 *
 * 2014-01-23 - Created
 */
@isTest
private class Contract_Approvals_BatchableTest {

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

	static Contract contract {
		get {
			if (contract == null) {
				contract = new Contract(
					AccountId = acc.Id,
					OwnerId = UserInfo.getUserId(),
					Global__c = true,
					Approval_Status__c = null,
					Pending_Approval_By__c = null,
					Pending_Approval_Date__c = null);
				insert contract;
			}
			return contract;
		}
		set;
	}

	@isTest
	static void coverageTest() {
		Contract_Approvals_Batchable batchable = new Contract_Approvals_Batchable();
		System.assertNotEquals(null,batchable.start(null));
		batchable.execute(null,new List<ProcessInstance>());
		batchable.finish(null);
	}

	@isTest
	static void pendingApprovalTest() {
		Approval.ProcessSubmitRequest submitRequest = new Approval.ProcessSubmitRequest();
		submitRequest.setObjectId(contract.id);
		Approval.ProcessResult result = Approval.process(submitRequest);
		System.assert(result.isSuccess());
		System.assertEquals(null,contract.Approval_Status__c);

		Test.startTest();
		Id batchInstanceId = Database.executeBatch(new Contract_Approvals_Batchable(1), 100);
		Test.stopTest();

		contract = [SELECT Approval_Status__c, Pending_Approval_By__c, Pending_Approval_Date__c FROM Contract WHERE Id = :contract.Id LIMIT 1];
		System.assertEquals('Pending',contract.Approval_Status__c);
	}
}