/**
 * Renewal_CotermSearchController
 * 
 * @version	  2015-11-24
 * @author	   Bryan Bosely <bbosely@redhat.com>
 * 2010-09-13 - Created
 * Bill C Riemers <briemers@redhat.com>
 * 2015-08-06 - Use a future call for Service Allocation updates
 * 2014-11-03 - Copy ExternalId__c
 * 2012-09-04 - Depreciated Expiring_Products_Total_Amount__c, and Total_Price__c usage.
 * 2012-04 - Commented out NEEC code per US18854
 * 2012-03-06 - refactored
 * Scott Coleman <scoleman@redhat.com>
 * 2015-11-24 - Updating opportunity type value from "Co-Term" to "CoTerm"
 * 2012-05-08 - mapped referenced profiles to new profiles for security redesign
 */
 
public class Renewal_CotermSearchController extends Renewal_Coterm
{
	public static Id renewalRecordTypeId { get {
		if(renewalRecordTypeId == null) {
			renewalRecordTypeId = [
				SELECT Id
				FROM RecordType
				WHERE Name = 'Renewal'
					and SObjectType = 'Opportunity'
					and IsActive = true limit 1 ].Id;
		}
		return renewalRecordTypeId;
	}}
	public final Id targetOpportunityId;

	/**
	 * Constructor
	 */
	public Renewal_CotermSearchController() 
	{
		// set the target opportunity id
		super(ApexPages.currentPage().getParameters().get('Id'));
		targetOpportunityId = sourceOpportunityId;

		System.Debug('Target Opportunity Id: ' + targetOpportunityId);
		System.Debug('Renewals Record Type: ' + recordType.Id);
		System.Debug('User Id: ' + currentUser.Id);
			
	}

	/**
	 * search for renewal opportunities
	 * 
	 * @return the list of opportunities
	 */
	public List<RenewalOpportunity> renewalOpportunities {
		get {
			if(renewalOpportunities == null) {

				// search renewal records by account name
				List<Opportunity> searchResult = queryRenewalOpportunities(sourceOpportunity);
				System.Debug('Account Name: ' + sourceOpportunity.Account.Name);

				renewalOpportunities = new List<RenewalOpportunity>();

				// create a collection of OpportunityRenewals from the opportunities 
				// returned from the search 
				for ( Opportunity opportunity: searchResult ) {
					RenewalOpportunity renewalOpportunity = new RenewalOpportunity();
					renewalOpportunity.opportunity = opportunity;
					renewalOpportunity.selected = false;
					renewalOpportunities.add( renewalOpportunity );
				}
			}
			return renewalOpportunities;
		}
		set;
	}

	/**
	 * Redirects to the renewalDetail page
	 *
	 * @return PageRefernce
	 */
	 
	public PageReference renewalDetail() {	
		String sourceOpportunityId = ApexPages.currentPage().getParameters().get('opportunityId');
		PageReference page = new PageReference('/apex/Renewal_CotermDetail?target=' + targetOpportunityId + '&source=' + sourceOpportunityId);
		page.setRedirect(true);
		
		return page;
	}

	/**
	 * Coterms products between opportunities
	 * 
	 * @return new page to redirect to
	 */
	public PageReference cotermProducts() {
		PageReference page = null;
		try {
			Set<Id> selectedOpportunities = getSelectedOpportunities();

			// ensure the user has selected a renewal opportunity
			if (selectedOpportunities.isEmpty()) {
				throw new Renewal_CotermSearchControllerException('Please select a renewal opportunity');
			}

			// coterm the opportunities
			system.debug( 'Selected Opportunities: ' + selectedOpportunities );
			system.debug( 'Target Opportunity: ' + targetOpportunityId );
			cotermProducts( selectedOpportunities, targetOpportunityId );

			// redirect back to the target opportunity
			page = new PageReference('/' + targetOpportunityId);
			page.setRedirect(true);
		}
		catch (Exception e) {
			ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage());
			ApexPages.addMessage(msg);	
		}
		return page;
	}

	/**
	 * coterm products
	 * 
	 * @param sourceOpportunityId source opportunity Id Set
	 * @param targetOpportunityId target opportunity Id
	 */
	private void cotermProducts( Set<Id> sourceOpportunityId, Id targetOpportunityId ) {
		List<Expiring_Product__c> sourceExpiringProducts = new List<Expiring_Product__c>();
		List<OpportunityLineItem> sourceOpportunityLineItems = new List<OpportunityLineItem>();
		List<Expiring_Product__c> targetExpiringProducts = new List<Expiring_Product__c>();
		List<Product> targetProducts = new List<Product>();

		// get the details of the source opportunities
		List<Opportunity> sourceOpportunities = queryOpportunityDetails( sourceOpportunityId );
		for ( Opportunity opportunity : sourceOpportunities ) {
			// copy and re-parent expiring products from the source opportunity
			for ( Expiring_Product__c expiringProduct : opportunity.Expiring_Products__r ) {
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
					Opportunity__c = targetOpportunityId,
					Product__c = expiringProduct.Product__c,
					Product_Code__c = expiringProduct.Product_Code__c,
					Quantity__c = expiringProduct.Quantity__c,
					Renewal_Opportunity__c = expiringProduct.Renewal_Opportunity__c,
					Sales_Price__c = expiringProduct.Sales_Price__c,
					Source_Opportunity__c = opportunity.Id));
				// create a product from the expiring product 
				targetProducts.add(new Product(
					new OpportunityLineItem(
						ActualEndDate__c = expiringProduct.Expiring_Product_End_Date__c.addYears( 1 ),
						ActualStartDate__c = expiringProduct.Expiring_Product_End_Date__c.addDays( 1 ),
						Configured_SKU__c = expiringProduct.Configured_Renewal_SKU__c,
						Contract_Numbers__c = expiringProduct.Expiring_Contract_Number__c,
						NewOrRenewal__c = 'Renewal',
						OpportunityId = targetOpportunityId,
						Quantity = expiringProduct.Quantity__c,
						ScheduleLocked__c = true,
						UnitPrice = expiringProduct.Sales_Price__c),
					expiringProduct.Mapped_SKU__c));
			}

			// update the state of the source opportunity
			opportunity.StageName = 'Closed Lost';
			opportunity.ReasonWonLostSalesProcess__c = 'Co-Termed Opp';
			opportunity.Opportunity_Reference_Name__c = targetOpportunityId;
			// opportunity.Expiring_Products_Total_Amount__c = 0.00;

			// add the expiring products and lines items to a collection to be deleted later
			sourceExpiringProducts.addAll( opportunity.Expiring_Products__r );
			sourceOpportunityLineItems.addAll( opportunity.OpportunityLineItems );
		}

		SavePoint sp = Database.setSavepoint();
		try {
			OpportunityTriggerAfter2.updateServicesAllocationsNow = false;
			// remove the expiring products
			delete sourceExpiringProducts;

			// add the expiring products to the target opportunity
			if ( ! targetExpiringProducts.isEmpty() ) {
				insert targetExpiringProducts;
			}

			// lookup pricebook entry ids, add the products to the target opportunity
			if ( ! targetProducts.isEmpty()) {
				insert lookupPricebookEntryIds( targetProducts, targetExpiringProducts[0].CurrencyIsoCode );
			}

			// update the state of the source opportunities
			update sourceOpportunities;

			// remove the expiring products and the opportunity line items from the source opportunity
			delete sourceOpportunityLineItems;

			update new Opportunity(
				Id=targetOpportunityId,
				OpportunityType__c = 'CoTerm');

			sp = null;
		}
		finally {
			OpportunityTriggerAfter2.updateServicesAllocationsNow = true;
			if(sp != null) {
				Database.rollback(sp);
			}
		}
	}

	/**
	 * Redirect back to the target opportunity
	 *
	 * @return redirect to opportunity page
	 */
	public PageReference cancel() {
		PageReference page = new PageReference('/' + targetOpportunityId);
		page.setRedirect(true);
		return page;
	} 

	/**
	 * search for all renewal opportunities based on the 
	 * account name of the target opp
	 *
	 * @param targetOpportunityId the opportunity Id to exclude
	 * @return list of opportunities
	 */
	private static List<Opportunity> queryRenewalOpportunities(
		Opportunity targetOpportunity )
	{
		Id ownerId = targetOpportunity.OwnerId;
		// determine if the user is an administrator and perform a less restrictive search
		if (! isAdministrator() ) {
			ownerId = currentUser.Id;
		}
		List<Opportunity> retval = [
			SELECT
				Account.Name,
				Account.OracleAccountNumber__c,
				Amount,
				Name,
// commented out per US18854
//				NonEntitledEndCustomer__c,
				OpportunityNumber__c
			FROM Opportunity
			WHERE RecordTypeId = :renewalRecordTypeId
				AND Account.Name LIKE :'%' + targetOpportunity.Account.Name + '%'
				AND Id != :targetOpportunity.Id
				AND CurrencyIsoCode = :targetOpportunity.CurrencyIsoCode
// commented out per US18854
//				AND NonEntitledEndCustomer__c = :targetOpportunity.NonEntitledEndCustomer__c
				AND StageName NOT IN ('Closed Booked', 'Closed Lost')
				AND OwnerId = :ownerId];
		retval.addAll([
			select
				Account.Name,
				Account.OracleAccountNumber__c,
				Amount,
				Name,
// commented out per US18854
//				NonEntitledEndCustomer__c,
				OpportunityNumber__c
			from Opportunity where Id in (
				SELECT
					OpportunityId
				FROM OpportunityTeamMember
					WHERE Opportunity.RecordTypeId = :renewalRecordTypeId
						AND Opportunity.Account.Name LIKE :'%' + targetOpportunity.Account.Name + '%'
						AND OpportunityId != :targetOpportunity.Id
						AND OpportunityId not in :new Map<Id,Opportunity>(retval).keySet()
						AND UserId = :currentUser.Id
						AND OpportunityAccessLevel = 'Edit'
						AND Opportunity.CurrencyIsoCode = :targetOpportunity.CurrencyIsoCode
// commented out per US18854
//						AND Opportunity.NonEntitledEndCustomer__c = :targetOpportunity.NonEntitledEndCustomer__c
						AND Opportunity.StageName NOT IN ('Closed Booked', 'Closed Lost') ) ]);
		return retval;
	}

	/**
	 * retrieve the selected opportunities from the renewalOpportunities
	 */
	private Set<Id> getSelectedOpportunities() {
		Set<Id> selectedOpportunities = new Set<Id>();
		for ( RenewalOpportunity renewalOpportunity : renewalOpportunities ) {
			if (renewalOpportunity.selected) {
				selectedOpportunities.add( renewalOpportunity.opportunity.id );
			}
		}
		return selectedOpportunities;
	}

	public static User currentUser {
		get {
			if(currentUser == null) {
				currentUser = new User(Id=UserInfo.getUserId(),ProfileId=UserInfo.getProfileId());
			}
			return currentUser;
		}
		set;
	}

	/**
	 * determines if the user is an administrator using Util.adminByPass()
	 */
	private static Boolean isAdministrator() {
		return Util.adminByPass();
	}

	/**
	 * creating a new object to add an attribute to the opportunity
	 */
	public class RenewalOpportunity {
		public Opportunity opportunity { get; set; }
		public Boolean selected { get; set; }
	}

	public class Renewal_CotermSearchControllerException extends Exception {}
}