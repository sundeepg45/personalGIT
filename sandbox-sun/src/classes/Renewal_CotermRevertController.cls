/**
 * Renewal_CotermRevertController
 * 
 * @version	  2015-11-24
 * @author	   Bryan Bosely <bbosely@redhat.com>
 * 2010-09-21 - Created
 * Bill C Riemers <briemers@redhat.com>
 * 2014-11-03 - Copy ExternalId__c
 * 2012-09-04 - Depreciated Expiring_Products_Total_Amount__c and Total_Price__c usage.
 * 2012-03-06 - refactored
 * Scott Coleman <scoleman@redhat.com>
 * 2015-11-24 - Updating opportunity type value from "Co-Term" to "CoTerm"
 */
public class Renewal_CotermRevertController extends Renewal_Coterm 
{
	/**
	 * Constructor
	 */
	public Renewal_CotermRevertController() {
		// set the source opportunity id
		super(ApexPages.currentPage().getParameters().get( 'source' ));
	}

	/**
	 * revert products that have been co-termed
	 *
	 */
	public PageReference revertProducts() {
		PageReference page = null;
		try {
			Set<Id> selectedOpportunities = getSelectedOpportunities();

			// ensure the user has selected a renewal opportunity
			if (selectedOpportunities.isEmpty()) {
				throw new Renewal_CotermRevertControllerException('Please select a renewal opportunity');
			}

			// revert coterm products
			system.debug( 'Selected Opportunities: ' + selectedOpportunities );
			system.debug( 'Source Opportunity: ' + sourceOpportunityId );

			revertProducts( sourceOpportunity, selectedOpportunities );

			// redirect back to the source opportunity
			page = new PageReference( '/' + sourceOpportunityId );
			page.setRedirect( true );
		}
		catch (Exception e) {
			ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage());
			ApexPages.addMessage(msg);	
		}
		return page;
	}

	/**
	 * revert products that have been co-termed
	 *
	 * @param sourceOpportunity source opportunity
	 * @param targetOpportunityIds target opportunity Id set
	 */
	private void revertProducts( Opportunity sourceOpportunity, Set<Id> targetOpportunityIds ) {
		Id sourceOpportunityId = sourceOpportunity.Id;
		// convert the target opportunity id list to a map
		Map<String, Boolean> targetOpportunityMap = new Map<String, Boolean>();
		for ( String targetOpportunityId : targetOpportunityIds ) {
			targetOpportunityMap.put( targetOpportunityId, true );
		}
		system.debug( 'Target Opportunity Map: ' + targetOpportunityMap);

		// copy and re-parent co-termed products from the source opportunity
		List<Expiring_Product__c> sourceExpiringProducts = new List<Expiring_Product__c>();
		List<Expiring_Product__c> targetExpiringProducts = new List<Expiring_Product__c>();
		List<Product> targetProducts = new List<Product>();

		for ( Expiring_Product__c expiringProduct : sourceOpportunity.Expiring_Products__r ) {
			// skip expiring products whose source opportunity is not in the target opportunity map
			system.debug( 'Checking Opportunity: ' + expiringProduct.Opportunity__c );

			if ( targetOpportunityMap.containsKey( expiringProduct.Source_Opportunity__c ) == false ) {
				system.debug( 'Opportunity Skipped: ' + expiringProduct.Source_Opportunity__c );
				continue;
			}

			targetExpiringProducts.add( new Expiring_Product__c(
				Already_Renewed__c = expiringProduct.Already_Renewed__c,
				Already_Renewed_Contract_Number__c = expiringProduct.Already_Renewed_Contract_Number__c,
				Configured_Renewal_SKU__c = expiringProduct.Configured_Renewal_SKU__c,
				CurrencyIsoCode = expiringProduct.CurrencyIsoCode,
				ExternalId__c = expiringProduct.ExternalId__c,
				Expiring_Product_End_Date__c = expiringProduct.Expiring_Product_End_Date__c,
				Expiring_Contract_Number__c = expiringProduct.Expiring_Contract_Number__c,
				Expiring_Contract_PO_Number__c = expiringProduct.Expiring_Contract_PO_Number__c,
				Expiring_Product_Start_Date__c = expiringProduct.Expiring_Product_Start_Date__c,
				Expiring_Oracle_Order_Number__c = expiringProduct.Expiring_Oracle_Order_Number__c,
				Mapped_Description__c = expiringProduct.Mapped_Description__c,
				Mapped_SKU__c = expiringProduct.Mapped_SKU__c,
				Name = expiringProduct.Name,
				Opportunity__c = expiringProduct.Source_Opportunity__c,
				Product__c = expiringProduct.Product__c,
				Product_Code__c = expiringProduct.Product_Code__c,
				Quantity__c = expiringProduct.Quantity__c,
				Renewal_Opportunity__c = expiringProduct.Renewal_Opportunity__c,
				Sales_Price__c = expiringProduct.Sales_Price__c));

			// create a product from the expiring product 
			Product targetProduct = new Product();
			targetProduct.opportunityLineItem = new OpportunityLineItem(
				ActualEndDate__c = expiringProduct.Expiring_Product_End_Date__c.addYears( 1 ),
				ActualStartDate__c = expiringProduct.Expiring_Product_End_Date__c.addDays( 1 ),
				Configured_SKU__c = expiringProduct.Configured_Renewal_SKU__c,
				Contract_Numbers__c = expiringProduct.Expiring_Contract_Number__c,
				NewOrRenewal__c = 'Renewal',
				OpportunityId = expiringProduct.Source_Opportunity__c,
				Quantity = expiringProduct.Quantity__c,
				ScheduleLocked__c = true,
				UnitPrice = expiringProduct.Sales_Price__c);
			targetProduct.mappedSku = expiringProduct.Mapped_SKU__c;
			targetProducts.add( targetProduct );

			sourceExpiringProducts.add( expiringProduct );
		}

		SavePoint sp = Database.setSavepoint();
		try {
			// remove the expiring products
			system.debug( 'Source Expiring Products: ' + sourceExpiringProducts.size());
			if ( ! sourceExpiringProducts.isEmpty() ) {
				delete sourceExpiringProducts;
			}

			// add the expiring products to the target opportunity
			if ( ! targetExpiringProducts.isEmpty() ) {
				insert targetExpiringProducts;
			}

			// lookup pricebook entry ids, add the products to the target opportunity
			if ( ! targetProducts.isEmpty() ) {
				insert lookupPricebookEntryIds( targetProducts, targetExpiringProducts[0].CurrencyIsoCode );
			}

			// update the state of the source opportunity

			// retrieve the updated source opportunity
			Opportunity opportunity = [
				SELECT
					Expiring_Products_Total_Amount_RollUp__c,
					OpportunityType__c,
					(	SELECT
							Name,
							Source_Opportunity__c,
							Total_Price_Formula__c
						FROM Expiring_Products__r
						WHERE Already_Renewed__c = false)
				FROM Opportunity
				WHERE Id = :sourceOpportunityId ];

			// change the opportunity type to standard if there are no co-termed products
			// on the source opportunity
			Integer cotermedProductCount = 0;
			for (Expiring_Product__c expiringProduct : opportunity.Expiring_Products__r) {
				if (expiringProduct.Source_Opportunity__c != null) {
					cotermedProductCount += 1;
				}
			}
			system.debug( 'Coterm Count: ' + cotermedProductCount);

			if (cotermedProductCount == 0 && opportunity.OpportunityType__c == 'CoTerm') {
				for(OpportunityFieldHistory h : [
					SELECT OldValue
					FROM OpportunityFieldHistory
					WHERE Field='OpportunityType__c' 
						and OpportunityId = :sourceOpportunityId
					ORDER BY CreatedDate desc limit 1 ] )
				{
					opportunity.OpportunityType__c = ''+h.OldValue;
				}
			}

			// recalculate the total of all the expiring products
			// calculateExpiringProductsTotal( opportunity );
			update opportunity;

			// update the state of the target opportunities

			// retrieve the target opportunities
			List<Opportunity> targetOpportunities = [
				SELECT
					StageName,
					(	SELECT
							Total_Price_Formula__c
						FROM Expiring_Products__r
						WHERE Already_Renewed__c = false)
				FROM Opportunity
				WHERE Id IN :targetOpportunityIds ];

			// reopen opportunities that are set to closed lost
			for (Opportunity targetOpportunity : targetOpportunities) {
				if (targetOpportunity.StageName == 'Closed Lost') {
					targetOpportunity.StageName = 'Prepare';
					targetOpportunity.ReasonWonLostSalesProcess__c = '';
					targetOpportunity.Opportunity_Reference_Name__c = null;
				}
				// recalculate the total of all the expiring products
				// calculateExpiringProductsTotal( targetOpportunity );
			}
			update targetOpportunities;
			sp = null;
		}
		finally {
			if(sp != null) {
				Database.rollback(sp);
			}
		}
	}

	/**
	 * Redirect back to the source opportunity
	 *
	 */
	public PageReference cancel() {
		PageReference page = new PageReference( '/' + sourceOpportunityId );
		page.setRedirect( true );
		return page;
	} 

	/**
	 * Build a list of RenewalOpportunity instances.
	 *
	 */
	public List<RenewalOpportunity> renewalOpportunities {
		get {
			if(renewalOpportunities == null) {
				renewalOpportunities = new List<RenewalOpportunity>();
				Set<Id> opportunityIds = new Set<Id>();
				// populate a collection with the renewal opportunity ids to lookup
				for (Expiring_Product__c expiringProduct : sourceOpportunity.Expiring_Products__r) {
					opportunityIds.add( expiringProduct.Source_Opportunity__c );
				}

				// populate renewal opportunities collection
				List<Opportunity> opportunities = queryOpportunityDetails( opportunityIds );
				for (Opportunity opportunity : opportunities) {
					RenewalOpportunity renewalOpportunity = new RenewalOpportunity();
					renewalOpportunity.opportunity = opportunity;
					renewalOpportunity.selected = false;
					renewalOpportunities.add( renewalOpportunity );
				}
			}
			return renewalOpportunities;
		}
		private set;
	}

	/**
	 * retrieve the selected opportunities from the renewalOpportunities
	 *
	 */
	private Set<Id> getSelectedOpportunities() {
		Set<Id> selectedOpportunities = new Set<Id>();
		for ( RenewalOpportunity renewalOpportunity : renewalOpportunities ) {
			if (renewalOpportunity.selected) {
				selectedOpportunities.add( renewalOpportunity.opportunity.Id );
			}
		}
		return selectedOpportunities;
	}

	/**
	 * retrieve the details of a list of opportunities
	 *
	 */
	private static List<Opportunity> queryOpportunityDetails(Set<Id> opportunityIds) {
		return [
			SELECT
				Account.Name,
				Account.OracleAccountNumber__c,
				Name,
				OpportunityNumber__c
			FROM Opportunity
			WHERE Id = :opportunityIds ];
	}

	/**
	 * creating a new object to add an attribute to the opportunity
	 *
	 */
	public class RenewalOpportunity {
		public Opportunity opportunity { get; set; }
		public Boolean selected { get; set; }
	}

	public class Renewal_CotermRevertControllerException extends Exception {}
}