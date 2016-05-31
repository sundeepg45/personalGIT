/**
 * Renewal_Coterm
 * 
 * @version	  2014-11-03
 * @author	   Bryan Bosely <bbosely@redhat.com>
 * 2011-10-03 - Created
 * Bill C Riemers <briemers@redhat.com>
 * 2014-11-03 - Add ExternalId__c field to expiring products query
 * 2012-09-04 - Depreciated Expiring_Products_Total_Amount__c and Total_Price__c usage.
 * 2012-03-06 - Updated to revert opportunity type.
 */
 
public abstract class Renewal_Coterm {
	public static Id globalPriceBookId { get {
		if(globalPriceBookId == null) {
			globalPricebookId = [
				SELECT Id 
				FROM Pricebook2 
				WHERE Name = 'Global Price Book' limit 1].Id;
		}
		return globalPriceBookId;
	}}
	public final Id sourceOpportunityId;

	/**
	 * Constructor
	 */
	protected Renewal_Coterm(Id sourceOpportunityId) {
		// set the source opportunity id
		this.sourceOpportunityId = sourceOpportunityId;
		System.debug( 'Source Opportunity Id: ' + sourceOpportunityId );
	}

	/**
	 * the details of an opportunity that is being reverted
	 */
	public Opportunity sourceOpportunity {
		get {
			if(sourceOpportunity == null && sourceOpportunityId != null) {
				sourceOpportunity = queryOpportunityDetails(new Set<Id>{sourceOpportunityId})[0];
			}
			return sourceOpportunity;
		}
		set;
	}

	/**
	 * lookup pricebook entry ids
	 *
	 * @param products list of products
	 * @param currencyIsoCode currency ISO code
	 * @return list of line items
	 *
	 */
	protected List<OpportunityLineItem> lookupPricebookEntryIds(
		List<Product> products, String currencyIsoCode) 
	{
		List<OpportunityLineItem> lineItems = new List<OpportunityLineItem>();

		// add the mapped skus to a set for the pricebook entry query
		Set<String> mappedSkus = new Set<String>();
		for (Product product : products) {
			if (product.mappedSku != null) {
				mappedSkus.add( product.mappedSku );
			}
		}

		System.debug('pricebook2Id='+globalPriceBookId+',currencyIsoCode='+currencyIsoCode+',ProductCode='+mappedSkus);
		// lookup the pricebookEntry id for the sku from the Global Pricebook
		Map<String,String> pricebookEntryMap= new Map<String, String>();
		List<PricebookEntry> pricebookEntries = [
			SELECT
				ProductCode
			FROM pricebookEntry
			WHERE pricebook2Id = :globalPriceBookId
				AND CurrencyIsoCode = :currencyIsoCode
				AND ProductCode IN :mappedSkus ];
		for (PricebookEntry pricebookEntry : pricebookEntries) {
			pricebookEntryMap.put(pricebookEntry.ProductCode, pricebookEntry.Id);
		}
		System.Debug('PricebookEntry Map: ' + pricebookEntryMap);

		// set the pricebook id for the sku
		for (Product product : products) {
			product.opportunityLineItem.pricebookEntryId = pricebookEntryMap.get( product.mappedSku );

			// extract the opportunityLineItems while we're looping through products.
			// we also need to ensure that we have a pricebookEntryId
			if (product.opportunityLineItem.pricebookEntryId != null) {
				lineItems.add(product.opportunityLineItem);
			}
		}
		return lineItems;
	}


	/**
	 * retrieve the details of an opportunity
	 *
	 * @param opportunityIds list of opportunity Ids to query for
	 * @return the queried opportunities
	 *
	 */
	protected List<Opportunity> queryOpportunityDetails( Set<Id> opportunityIds ) {
		return [
			SELECT
				Account.AccountNumber,
				Account.Name,
				Account.OracleAccountNumber__c,
				CloseDate,
				CurrencyIsoCode,
				Name,
// Commented out per US18854
//				NonEntitledEndCustomer__c,
				OpportunityNumber__c,
				OpportunityType__c,
				OwnerId,
				(	SELECT
						Already_Renewed__c,
						Already_Renewed_Contract_Number__c,
						Configured_Renewal_SKU__c,
						CurrencyIsoCode,
						Expiring_Product_End_Date__c,
						Expiring_Contract_Number__c,
						Expiring_Contract_PO_Number__c,
						Expiring_Product_Start_Date__c,
						Expiring_Oracle_Order_Number__c,
						ExternalId__c,
						Mapped_Description__c,
						Mapped_SKU__c,
						Name,
						Opportunity__c,
						Product__c,
						Product_Code__c,
						Quantity__c,
						Renewal_Opportunity__c,
						Sales_Price__c,
						Source_Opportunity__c,
						Source_Opportunity__r.OpportunityNumber__c,
						Total_Price_Formula__c
					FROM Expiring_Products__r
					WHERE Already_Renewed__c = false),
				(	SELECT
						Configured_SKU__c,
						Contract_Numbers__c,
						CurrencyIsoCode,
						Description,
						PricebookEntry.ProductCode,
						PricebookEntry.Name,
						Quantity,
						TotalPrice,
						UnitPrice
					FROM OpportunityLineItems)
			FROM Opportunity
			WHERE Id IN :opportunityIds ];
	}

	/**
	 * creating a new object to add an attribute to the opportunity line item
	 */
	public class Product {
		public Product() {}
		public Product(OpportunityLineItem opportunityLineItem,String mappedSku) {
			this.opportunityLineItem = opportunityLineItem;
			this.mappedSku = mappedSku;
		}
		public OpportunityLineItem opportunityLineItem { get; set; }
		public String mappedSku { get; set; }
	}
}