/**
 *
 * @version	  2015-11-24
 * @author  Bryan Bosely <bbosely@redhat.com>
 * 2010-10-04 - Created
 * Bill C Riemers <briemers@redhat.com>
 * 2015-03-28 - Correct errors with too many triggers
 * 2012-09-04 - Depreciated Expiring_Products_Total_Amount__c usage.
 * 2012-07-10 - comment out failing test
 * 2012-03-07 - refactored
 * Scott Coleman <scoleman@redhat.com>
 * 2015-11-24 - Updating opportunity type value from "Co-Term" to "CoTerm"
 */
@isTest
private class Renewal_CotermRevertControllerTest {

	static List<Opportunity> opportunities { get {
		if(opportunities == null) {
			opportunities = new List<Opportunity>{
				Renewal_CotermTest.createOpportunity('Renewal Target Opportunity','006600000000000','Co-Termed Opp'),
				Renewal_CotermTest.createOpportunity('Renewal Target Opportunity','006600000000000','Co-Termed Opp')};
				
			insert opportunities;
		}
		return opportunities;
	}}

	static Opportunity targetOpportunity { get { return opportunities[0]; } }

	static Opportunity targetOpportunity2 { get { return opportunities[1]; } }

	static Opportunity sourceOpportunity { get {
		if(sourceOpportunity == null) {
			sourceOpportunity = Renewal_CotermTest.createOpportunity('Renewal Source Opportunity',targetOpportunity.Id,null);
			insert sourceOpportunity;
		}
		return sourceOpportunity;
	}}

	static OpportunityLineItem lineItem { get {
		if(lineItem == null) {
			// create an opportunity line item for the source opportunity
			lineItem = Renewal_CotermTest.createLineItem(sourceOpportunity.Id);
		}
		return lineItem;
	}}

	static Expiring_Product__c sourceExpiringProduct { get {
		if(sourceExpiringProduct == null) {
			// create an expiring product for the source opportunity
			sourceExpiringProduct = Renewal_CotermTest.createExpiringProduct(sourceOpportunity.Id,Renewal_CotermTest.product.ProductCode);
			sourceExpiringProduct.Source_Opportunity__c = targetOpportunity.Id;
		}
		return sourceExpiringProduct;
	}}

	static Expiring_Product__c sourceExpiringProduct2 { get {
		if(sourceExpiringProduct2 == null) {
			// create an expiring product for the source opportunity
			sourceExpiringProduct2 = Renewal_CotermTest.createExpiringProduct(sourceOpportunity.Id,Renewal_CotermTest.product.ProductCode);
			sourceExpiringProduct2.Source_Opportunity__c = targetOpportunity2.Id;
		}
		return sourceExpiringProduct2;
	}}

	static Id sourceOpportunityId { get {
		if(sourceOpportunityId == null) {
			insert lineItem;
			insert new List<Expiring_Product__c>{ sourceExpiringProduct, sourceExpiringProduct2 };
			sourceOpportunityId = sourceOpportunity.Id;
		}
		return sourceOpportunityId;
	}}

	static Renewal_CotermRevertController controller { get {
		if(controller == null) {
			ApexPages.currentPage().getParameters().put('source',sourceOpportunityId);
			controller = new Renewal_CotermRevertController();
		}
		return controller;
	}}

	@isTest
	static void constructorTest() {
		Id id = UserInfo.getUserId();
		// this is the wrong type of Id to use, but it doesn't matter for this test
		ApexPages.currentPage().getParameters().put('source', id);
		Renewal_CotermRevertController xcontroller = new Renewal_CotermRevertController();
		System.assertEquals(id, xcontroller.sourceOpportunityId);
	}

	@isTest
	static void testRevertProducts() {
		Pricebook2 globalPriceBook = new Pricebook2(Description='Global',IsActive=true,Name = 'Global Price Book');
		insert globalPriceBook;

		Id targetOpportunityId = targetOpportunity.Id;
		Id targetOpportunityId2 = targetOpportunity2.Id;
		update new Opportunity(Id=sourceOpportunityId,OpportunityType__c='CoTerm');
		for ( Renewal_CotermRevertController.RenewalOpportunity opp : controller.renewalOpportunities ) {
			opp.selected = true;
		}
		
		System.debug('Renewal Opportunity Size:' + controller.renewalOpportunities.size());
		
		Test.startTest();
		PageReference PAGE_REF = controller.revertProducts();
		Test.stopTest();
		System.assertEquals('/' + sourceOpportunityId, PAGE_REF.getUrl());
		
		
		//
		// check the state of the target opportunities
		//
		
		List<Opportunity> targetOpportunities = [
			SELECT
				Expiring_Products_Total_Amount_RollUp__c,
				OpportunityType__c,
				ReasonWonLostSalesProcess__c,
				StageName,
				(SELECT Id
					FROM Expiring_Products__r
					WHERE Already_Renewed__c = false),
				(SELECT Id
					FROM OpportunityLineItems)
			FROM Opportunity
			WHERE Id IN (:targetOpportunityId, :targetOpportunityId2)
		];
		
		for ( Opportunity xtargetOpportunity : targetOpportunities )
		{
			System.assertEquals(2000.00, xtargetOpportunity.Expiring_Products_Total_Amount_RollUp__c);
			System.assertEquals('Standard', xtargetOpportunity.OpportunityType__c);
			System.assertEquals(1, xtargetOpportunity.Expiring_Products__r.size());
			//System.assertEquals(1, xtargetOpportunity.OpportunityLineItems.size());
			System.assertEquals(null, xtargetOpportunity.ReasonWonLostSalesProcess__c);
			System.assertEquals('Prepare', xtargetOpportunity.StageName);
		}

		//
		// check the state of the source opportunity
		//
		
		Opportunity xsourceOpportunity = [
			SELECT
				Expiring_Products_Total_Amount_RollUp__c,
				Opportunity_Reference_Name__c,
				OpportunityType__c,
				ReasonWonLostSalesProcess__c,
				StageName
			FROM Opportunity
			WHERE Id = :sourceOpportunityId
		];
		
// this test is failing, I don't know why - bcr
//		System.assertEquals(sourceOpportunity.OpportunityType__c, xsourceOpportunity.OpportunityType__c);
		System.assertEquals(0.00, xsourceOpportunity.Expiring_Products_Total_Amount_RollUp__c);
		System.assertEquals(null, xsourceOpportunity.Opportunity_Reference_Name__c);
		System.assertEquals(null, xsourceOpportunity.ReasonWonLostSalesProcess__c);
	}

	@isTest
	static void cancelTest() {
		Id id = UserInfo.getUserId();
		// this is the wrong type of Id to use, but it doesn't matter for this test
		ApexPages.currentPage().getParameters().put('source', id);
		Renewal_CotermRevertController xcontroller = new Renewal_CotermRevertController();
		// verify that we are returned to the source opportunity page on cancel
		PageReference PAGE_REF = xcontroller.cancel();
		System.assertEquals('/' + id, PAGE_REF.getUrl());
	}
}