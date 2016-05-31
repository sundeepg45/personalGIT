/**
 * This is the controller used for linking channel opportunities.
 *
 * @version 2014-08-22
 * @author unknown
 * Bill C Riemers <briemers@redhat.com>
 * 2014-08-22 Use the most recently modified active pricebook entry
 * 2012-07-31 Updated admin bypass to include partner related records.
 * Scott Coleman <scoleman@redhat.com>
 * 2014-04-25 Now leaving Deal Registration flag alone if it's checked on target. (US45939)
 * 2014-02-20 Now setting Touched flag regardless of channel. (US41044)
 * 2013-05-28 Now clearing primary flag on all BigMachines quotes related to the target opp. This is to prevent
 *		unwanted error messages regarding quote recalculation during submit order for the target opp.
 * 2012-09-13 Removing Channel Load restriction on Touched flag logic
 */
 public with sharing class LinkChannelOppController
{
	//
	// collection of line items from the sourceOpportunity found in the global price book
	//
	public List<OpportunityLineItem> sourceLineItems  { get; set; }
	public Map<String, String> convertedSKUS { get; set; } 

	public Id targetOpportunityId {
		get {
			if (targetOpportunityId == null) {
				targetOpportunityId = (Id)System.currentPageReference().getParameters ().get('targetOpportunityId');
			}
			return targetOpportunityId;
		}
		set;
	}

	public String sourceOpportunityNumber {
		get;
		set {
			if(value != null) {
				value = value.replaceAll('[^\\d]', '');
			}
			if('' == value) {
				value = null;
			}
			if(sourceOpportunityNumber != value) {
				sourceOpportunityNumber = value;
				sourceOpportunity = null;
			}
		}
	}

	public String globalPricebookId {
		get {
			if (globalPricebookId == null) {
				for(Pricebook2 globalPriceBook : [
					SELECT Id 
			 		FROM Pricebook2 
					WHERE Name = 'Global Price Book' limit 1] )
					
				{
					globalPriceBookId = globalPriceBook.Id;
				}
			}
			return globalPricebookId;
		}
		set;
	}

	public Opportunity sourceOpportunity {
		get {
			if(sourceOpportunity == null) {
				sourceOpportunity = new Opportunity();
				if(sourceOpportunityNumber != null) {
					// Assign the potentials
					for(Opportunity opp : [
						select
							Amount,
							AmountText__c,
							Channel_Load_Date__c,
							Channel_Load_Opp__c,
							CloseDate,
							ContractEndDate__c,
							ContractStartDate__c,
							Country_Of_Order__c,
							CreatedBy.Profile.Name,
							CurrencyIsoCode,
							Deal_Registration__c,
							FulfillmentChannel__c,
							Name,
							//US17551 NonEntitledEndCustomer__c,
							OpportunityNumber__c,
							OracleOrderNumber__c,
							Pay_Now__c,
							Pricebook2Id,
							PONumber__c,
							FinancialPartner__c,
							Probability,
							Region_Of_Order__c,
							StageName,
							Touched__c,
							Year1Amount__c,
							Year1AmountText__c,
							Year1PaymentAmount__c,
							Year2Amount__c,
							Year2AmountText__c,
							Year2PaymentAmount__c,
							Year3Amount__c,
							Year3AmountText__c,
							Year3PaymentAmount__c,
							Year4Amount__c,
							Year4AmountText__c,
							Year4PaymentAmount__c,
							Year5Amount__c,
							Year5AmountText__c,
							Year5PaymentAmount__c,
							Year6Amount__c,
							Year6AmountText__c,
							Year6PaymentAmount__c,
							(	select
									ActualEndDate__c,
									ActualStartDate__c,
									ActualTerm__c,
									Base_Price__c,
									Configured_SKU__c,
									Contract_Numbers__c,
									CurrencyIsoCode,
									Description,
									Extended_Sales_Price__c,
									HasQuantitySchedule,
									HasRevenueSchedule,
									HasSchedule,
									Line_Item_Source__c,
									ListPrice,
									NewOrRenewal__c,
									OpportunityCloseDate__c,
									OpportunityId,
									PricebookEntry.Product2.Name,
									PricebookEntry.ProductCode,
									PricebookEntryId,
									Pricing_Attributes__c,
									ProductDefaultTerm__c,
									Quantity,
									RenewalProduct__c,
									ScheduleLocked__c,
									ServiceDate,
									SortOrder,
									Suggested_List_Price__c,
									TotalPrice,
									UnitPrice,
									Year1Amount__c,
									Year2Amount__c,
									Year3Amount__c,
									Year4Amount__c,
									Year5Amount__c,
									Year6Amount__c,
									YearlySalesPrice__c
								from OpportunityLineItems),
							(	select
									CurrencyIsoCode,
									Name,
									Opportunity__c,
									PartnerName__c,
									PartnerTier__c,
									PartnerType__c,
									Partner__c,
									RelationshipType__c
								from OpportunityPartners2__r 
								where RelationshipType__c != 'Influencing' )
						from Opportunity
						where OpportunityNumber__c = :sourceOpportunityNumber limit 1 ] )
					{
						sourceOpportunity = opp;
					}
				}
			}
			return sourceOpportunity;
		}
		set;
	}

	public Opportunity targetOpportunity {
		get {
			if(targetOpportunity == null) {
				targetOpportunity = new Opportunity();
				if (targetOpportunityId != null) {
					for(Opportunity opp : [
						select
							Amount,
							AmountText__c,
							Channel_Load_Date__c,
							Channel_Load_Opp__c,
							CloseDate,
							ContractEndDate__c,
							ContractStartDate__c,
							Country_Of_Order__c,
							CreatedBy.Profile.Name,
							CurrencyIsoCode,
							Deal_Registration__c,
							FulfillmentChannel__c,
							Name,
							//US17551 NonEntitledEndCustomer__c,
							OpportunityNumber__c,
							OracleOrderNumber__c,
							Pay_Now__c,
							PONumber__c,
							FinancialPartner__c,
							Pricebook2Id,
							Probability,
							Region_Of_Order__c,
							StageName,
							Touched__c,
							Year1Amount__c,
							Year1AmountText__c,
							Year1PaymentAmount__c,
							Year2Amount__c,
							Year2AmountText__c,
							Year2PaymentAmount__c,
							Year3Amount__c,
							Year3AmountText__c,
							Year3PaymentAmount__c,
							Year4Amount__c,
							Year4AmountText__c,
							Year4PaymentAmount__c,
							Year5Amount__c,
							Year5AmountText__c,
							Year5PaymentAmount__c,
							Year6Amount__c,
							Year6AmountText__c,
							Year6PaymentAmount__c,
							(	select
									ActualEndDate__c,
									ActualStartDate__c,
									ActualTerm__c,
									Base_Price__c,
									Configured_SKU__c,
									Contract_Numbers__c,
									CurrencyIsoCode,
									Description,
									Extended_Sales_Price__c,
									HasQuantitySchedule,
									HasRevenueSchedule,
									HasSchedule,
									Line_Item_Source__c,
									ListPrice,
									NewOrRenewal__c,
									OpportunityCloseDate__c,
									OpportunityId,
									PricebookEntry.Product2.Name,
									PricebookEntry.ProductCode,
									PricebookEntryId,
									Pricing_Attributes__c,
									ProductDefaultTerm__c,
									Quantity,
									RenewalProduct__c,
									ScheduleLocked__c,
									ServiceDate,
									SortOrder,
									Suggested_List_Price__c,
									TotalPrice,
									UnitPrice,
									Year1Amount__c,
									Year2Amount__c,
									Year3Amount__c,
									Year4Amount__c,
									Year5Amount__c,
									Year6Amount__c,
									YearlySalesPrice__c
								from OpportunityLineItems ),
							(	select
									CurrencyIsoCode,
									Name,
									Opportunity__c,
									PartnerName__c,
									PartnerTier__c,
									PartnerType__c,
									Partner__c,
									RelationshipType__c
								from OpportunityPartners2__r
								where RelationshipType__c != 'Influencing'),
							(select IsActive__c from Quotes__r),
							(select BigMachines__Is_Primary__c from BigMachines__BigMachines_Quotes__r)
						from Opportunity
						where Id = :targetOpportunityId ] )
					{
						targetOpportunity = opp;
					}
				}
			}
			return targetOpportunity;
		}
		set;
	}

	public String getReturnUrl () {
		Map <String, String> parameters = System.currentPageReference ().getParameters ();
		return parameters.containsKey ('retURL') ? parameters.get ('retURL') : '/home/home.jsp';
	}

	public void convert2GlobalPriceBook() {
		convertedSKUS = ConvertSKUS(sourceOpportunity.OpportunityLineItems);
		System.Debug('DEBUG: ' + convertedSKUS);

		//
		// add the line items found in the global pricebook to the sourceLineItems collection
		// for display to the user
		//
		sourceLineItems = new List<OpportunityLineItem>();
		for (OpportunityLineItem lineItem : sourceOpportunity.OpportunityLineItems) {
			String priceBookEntryId = convertedSKUS.get(lineItem.PricebookEntry.productCode);
			System.Debug('PRICEBOOK_ENTRY_ID:' + priceBookEntryId);
			if (priceBookEntryId != null) {
				sourceLineItems.add(lineItem);
			}
		}
	}

	public Map<String, String> ConvertSKUS(List<OpportunityLineItem> lineItems) {
		//
		// obtain the product code from the line items
		//
		
		Set<String> productCodes = new Set<String>();
		for ( OpportunityLineItem lineItem : lineItems )
			productCodes.add(lineItem.PricebookEntry.ProductCode);

		//
		// lookup the pricebookEntry id for the sku from the Global Pricebook
		//
		Map<String,String> pricebookEntryMap= new Map<String, String>();
		for (PricebookEntry pricebookEntry : [
			SELECT 
				Id,
				IsActive,
				ProductCode
			FROM PricebookEntry
			WHERE pricebook2Id = :globalPriceBookId
				AND CurrencyIsoCode = :sourceOpportunity.CurrencyIsoCode
				AND ProductCode IN :productCodes
			ORDER BY LastModifiedDate ] )
		{
			if(pricebookEntry.IsActive == true || ! pricebookEntryMap.containsKey(pricebookEntry.ProductCode)) {
				pricebookEntryMap.put(pricebookEntry.ProductCode, pricebookEntry.Id);
			}
		}
		System.Debug('PricebookEntry Map: ' + pricebookEntryMap);

		return pricebookEntryMap;
	}

	public PageReference cancel()  {
		PageReference pageReference = new PageReference (getReturnUrl ());
		pageReference.setRedirect (true);
		return pageReference;
	}

	public PageReference search() {
		sourceOpportunity = null;
		if (sourceOpportunity.OpportunityNumber__c != null) {
			sourceOpportunityNumber = sourceOpportunity.OpportunityNumber__c;
		}
		convert2GlobalPriceBook();

		return null;
	}

	public PageReference saveChanges() 
	{
		PageReference pageReference = null;
		//
		// Not allowed to copy information to a target opportunity marked Closed Booked.
		//
		if (targetOpportunity.StageName != 'Closed Booked') {
			System.Savepoint sp = Database.setSavepoint();
			try {
				//
				// Save stage and probability for future use
				//
				String savedStageName = targetOpportunity.StageName;
				Decimal savedProbability = targetOpportunity.Probability;
				AsAdmin asAdmin = new AsAdmin();

				// set touched values
				Boolean touched = (
					sourceOpportunity.StageName == 'Closed Booked');
				if(touched && sourceOpportunity.Touched__c != true) {
					sourceOpportunity.Touched__c = true;
					asAdmin.updateObject(sourceOpportunity);
				}
				targetOpportunity.Touched__c = touched || (targetOpportunity.Touched__c == true);

				//
				// Copy field values and update
				//
				targetOpportunity.Channel_Load_Opp__c = sourceOpportunity.OpportunityNumber__c;
				targetOpportunity.CloseDate = sourceOpportunity.CloseDate;
				targetOpportunity.ContractEndDate__c = sourceOpportunity.ContractEndDate__c;
				targetOpportunity.ContractStartDate__c = sourceOpportunity.ContractStartDate__c;
				// DE2974 targetOpportunity.CurrencyIsoCode = sourceOpportunity.CurrencyIsoCode;
				// US45939 - don't overwrite Deal Registration flag on taget if it's checked
				if(!targetOpportunity.Deal_Registration__c) {
					targetOpportunity.Deal_Registration__c = sourceOpportunity.Deal_Registration__c;
				}
				targetOpportunity.Pay_Now__c = sourceOpportunity.Pay_Now__c;
				targetOpportunity.PONumber__c = sourceOpportunity.PONumber__c;
				targetOpportunity.FinancialPartner__c = sourceOpportunity.FinancialPartner__c;

				//
				// Any active quote value needs to be deactivated and cleared out from the target opp
				//
				for (Quote__c quote : targetOpportunity.Quotes__r) {
					quote.IsActive__c = false;
				}

				update targetOpportunity.Quotes__r;

				targetOpportunity.QuoteNumber__c = null;

				//
				// Similarly, any BigMachines quotes marked primary on the target opp should be marked not primary
				//

				for (BigMachines__Quote__c quote : targetOpportunity.BigMachines__BigMachines_Quotes__r) {
					quote.BigMachines__Is_Primary__c = false;
				}

				update targetOpportunity.BigMachines__BigMachines_Quotes__r;

				//
				// Use a special name for the merging, but only if we are updating the stage name.
				//
				if (savedProbability > 0) {
					targetOpportunity.StageName = 'VAR/VAD Merge';
					targetOpportunity.Probability = 0;
				
					update targetOpportunity;
				}

				//
				// Per the supplied business rule (Ian Zepp, Sherry James 2009/08), if the year 1 payment
				// amount on the source opp is 0, then erase all of the target opp payment amounts for 
				// all years and place the source opp amount into the target opp year 1 payment field.
				//
				// Otherwise, copy over the payment schedule.
				//
				if (sourceOpportunity.Year1PaymentAmount__c == 0 || sourceOpportunity.Year1PaymentAmount__c == null) {
					targetOpportunity.Year1PaymentAmount__c = sourceOpportunity.Amount;
					targetOpportunity.Year2PaymentAmount__c = 0;
					targetOpportunity.Year3PaymentAmount__c = 0;
					targetOpportunity.Year4PaymentAmount__c = 0;
					targetOpportunity.Year5PaymentAmount__c = 0;
					targetOpportunity.Year6PaymentAmount__c = 0;
				}
				else {
					targetOpportunity.Year1PaymentAmount__c = sourceOpportunity.Year1PaymentAmount__c;
					targetOpportunity.Year2PaymentAmount__c = sourceOpportunity.Year2PaymentAmount__c;
					targetOpportunity.Year3PaymentAmount__c = sourceOpportunity.Year3PaymentAmount__c;
					targetOpportunity.Year4PaymentAmount__c = sourceOpportunity.Year4PaymentAmount__c;
					targetOpportunity.Year5PaymentAmount__c = sourceOpportunity.Year5PaymentAmount__c;
					targetOpportunity.Year6PaymentAmount__c = sourceOpportunity.Year6PaymentAmount__c;
				}

				//
				// Delete all target opportunity product line items
				//
				delete targetOpportunity.OpportunityLineItems;

				//
				// use the global pricebook for the target opportunity
				//
				targetOpportunity.Pricebook2Id = globalPriceBookId;
				
				// DE2974 
				// copy the source currency to the target
				//
				targetOpportunity.CurrencyIsoCode = sourceOpportunity.CurrencyIsoCode;

				update targetOpportunity;

				//
				// Copy and re-parent the line items from the sourceLineItems collection
				//
				List <OpportunityLineItem> targetOpportunityLineItems = sourceLineItems.deepClone(false);
				for(OpportunityLineItem opportunityLineItem : targetOpportunityLineItems) {
					opportunityLineItem.OpportunityId = targetOpportunity.Id;
					opportunityLineItem.PricebookEntryId = convertedSKUS.get(opportunityLineItem.PricebookEntry.ProductCode);
					opportunityLineItem.TotalPrice = null;
				}

				insert targetOpportunityLineItems;

				//
				// Copy opportunity partners (opportunityPartner__c) from the source opportunity.
				// Deep clone is not behaving as expected, so we're looping through the source partners and recreating them.
				//
				List <OpportunityPartner__c> targetOpportunityPartners = new List <OpportunityPartner__c>();
				for (OpportunityPartner__c opportunityPartner: sourceOpportunity.OpportunityPartners2__r) {
					
					OpportunityPartner__c partner = new OpportunityPartner__c();
					partner.CurrencyIsoCode = opportunityPartner.CurrencyIsoCode;
					partner.Opportunity__c = targetOpportunity.Id;
					partner.Partner__c = opportunityPartner.Partner__c;
					partner.PartnerTier__c = opportunityPartner.PartnerTier__c;
					partner.PartnerType__c = opportunityPartner.PartnerType__c;
					partner.RelationshipType__c = opportunityPartner.RelationshipType__c;
				
					targetOpportunityPartners.add(partner);
				}

				//
				// Delete the partners on the target opportunity. Influential partners will remain on the opportunity
				//
				List <OpportunityPartner__c> targetPartners = [select Id
					from OpportunityPartner__c
				   where RelationshipType__c != 'Influencing'
					 and Opportunity__c =: targetOpportunity.Id			 
				];

				asAdmin.deleteList(targetPartners);

				//
				// Add the partners copied from the source opportunity to the target opportunity 
				//
				asAdmin.insertList(targetOpportunityPartners);

				//
				// Re-update the target opp with the correct stage + probability
				//
				if (savedProbability > 0) {
					targetOpportunity.StageName = savedStageName;
					targetOpportunity.Probability = savedProbability;
					update targetOpportunity;
				}
				//
				// Finished
				//
				pageReference = new PageReference ('/' + targetOpportunity.Id);
				pageReference.setRedirect (true);
			}
			catch (Exception e)
			{
				String errorMsg = e.getMessage();
				ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.Error, errorMsg);
				ApexPages.addMessage(msg);
				Database.rollback(sp);
			}

		}
		return pageReference;
	}

	public PageReference reverseOrder() {
		Opportunity holderOpportunity = sourceOpportunity;
		sourceOpportunityNumber = targetOpportunity.OpportunityNumber__c;
		sourceOpportunity = targetOpportunity;
		
		targetOpportunityId = holderOpportunity.Id;
		targetOpportunity = holderOpportunity;
		return null;
	}

	private without sharing class AsAdmin
	{
		void updateObject(SObject o) {
			update o;
		}
		void insertList(List<SObject> objects) {
			insert objects;
		}
		void deleteList(List<SObject> objects) {
			delete objects;
		}
	}
}