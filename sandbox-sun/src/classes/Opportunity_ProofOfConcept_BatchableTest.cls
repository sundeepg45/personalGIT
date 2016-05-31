/**
 * This class a test class for Opportunity_ProofOfConcept_Batchable.
 *
 * @author Bill C Riemers <briemers@redhat.com>
 * @version 2013-07-05
 *
 * 2013-07-05 - Created
 */
@isTest
private class Opportunity_ProofOfConcept_BatchableTest {
	@isTest
	static void coverageTest() {
		// to do: This is strictly coverage.  We really should do some testing...
		Opportunity_ProofOfConcept_Batchable batchable = new Opportunity_ProofOfConcept_Batchable();
		System.assertNotEquals(null,batchable.start(null));
		batchable.execute(null,new List<Opportunity>());
		batchable.finish(null);
	}
}