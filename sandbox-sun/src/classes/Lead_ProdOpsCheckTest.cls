@isTest
public class Lead_ProdOpsCheckTest {
	
	@isTest(SeeAllData=true)
	private static void lead_ProdOpsCheckTest()
	{
		User owner = PartnerTestUtils.getAdminUser();
		Lead l = PartnerTestUtils.makeLead('abc', 'abc', 'abc', owner);
		insert l;
		l.Channel_Ops_Approved__c = true;
		try {
			update l;
			// Should never reach this
			System.assert(false);
		} catch (Exception e){
			// Validation error fired
		}
		
	}
	
}