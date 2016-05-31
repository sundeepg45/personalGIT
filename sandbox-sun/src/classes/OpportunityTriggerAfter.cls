/**
 * In the future this class should replace all "after" triggers on the Opportunity object.  
 * The processTrigger method is invoked by the Opportunity_After trigger and in turn invokes
 * all the methods of this class.  This gives us a way to control the order in
 * which the code logic is invoked, as well as allowing other class features such
 * as shared data, constant values, and rigorous test coverage.
 * <p>
 * The Trigger object should never be directly referenced inside this class, as
 * that would make it impossible to substitute values inside test methods.
 * </p>
 * NOTE: Some existing triggers have not yet been incorporated into this class (future work).
 *
 * @version 2015-01-27
 * @author Scott Coleman <scoleman@redhat.com>
 * 2013-02-25 - Added copy of POC products
 * 2012-07-12 - Created
 * Bill Riemers <briemers@redhat.com>
 * 2015-01-27 - Depreciated
 * 2013-05-14 - Added lookup for POC record type
 * 2013-04-04 - Added link solution method.  Correct usage of AbstractTrigger and such.
 */
public with sharing class OpportunityTriggerAfter /*depreciated extends AbstractTrigger*/ {
//depreciated	/** BooleanSetting__c key to enable setting legacy values */
//depreciated	public static final String INSERT_OPPORTUNITY_SNAPSHOT_SETTING = 'Opp_After.insertOppSnapshot';
//depreciated	/** BooleanSetting__c key to enable the insertOpportunitySnapshot trigger method. */
//depreciated	public static final String COPY_POC_PRODUCTS_SETTING = 'Opp_After.copyPOCProducts';
//depreciated	/** BooleanSetting__c key to enable the linkSolution trigger method. */
//depreciated	public static final String LINK_SOLUTIONS_SETTING = 'Opp_After.linkSolutions';

//depreciated	/** Normally populated as a copy of Trigger.oldMap */
//depreciated	public final Map<Id,Opportunity> oldMap = new Map<Id,Opportunity>();
//depreciated	/** Normally populated as Trigger.new */
//depreciated	public final Map<Id,Opportunity> newMap = new Map<Id,Opportunity>();
//depreciated	/** Used to keep track of errors while debugging */
//depreciated	public Boolean hasErrors = false;

//depreciated	/**
//depreciated	 * This constructor is normally called from the processTrigger method and
//depreciated	 * test methods.
//depreciated	 */
//depreciated	public OpportunityTriggerAfter(Map<Id,Opportunity> xoldMap,Map<Id,Opportunity> xnewMap) {
//depreciated		super(xoldMap,null,xnewMap);
//depreciated		if(xoldMap != null) {
//depreciated			oldMap.putAll(xoldMap);
//depreciated		}
//depreciated		if(xnewMap != null) {
//depreciated			newMap.putAll(xnewMap);
//depreciated		}
//depreciated	}

//depreciated	private boolean haveSnapshotFieldsChanged(Opportunity opp) {
//depreciated		Opportunity oldOpp = oldMap.get(opp.Id);
//depreciated		boolean retVal = false;
//depreciated		//for new opps, check if any in-scope fields have a value
//depreciated		if (oldOpp == null) {
//depreciated			if (opp.Rush_Order__c 
//depreciated					|| opp.Rush_Order_Reason__c != null 
//depreciated					|| opp.Rush_Order_Set_By_System__c) {
//depreciated				retVal = true;
//depreciated			}
//depreciated		}
//depreciated		//for updated opps, check if any in-scope fields have changed 
//depreciated		else if (opp.Rush_Order__c != oldOpp.Rush_Order__c
//depreciated				|| opp.Rush_Order_Reason__c != oldOpp.Rush_Order_Reason__c
//depreciated				|| opp.Rush_Order_Set_By_System__c != oldOpp.Rush_Order_Set_By_System__c) {
//depreciated			retVal = true;
//depreciated		}
//depreciated		return retVal;
//depreciated	}

//depreciated	private OpportunitySnapshot__c createSnapshotRecord(Opportunity opp) {
//depreciated		Opportunity oldOpp = oldMap.get(opp.Id);
//depreciated		OpportunitySnapshot__c snapshot;
//depreciated		if (oldOpp == null) {
//depreciated			snapshot = new OpportunitySnapshot__c(
//depreciated				Opportunity__c=opp.Id,
//depreciated				RushOrderFrom__c=false,
//depreciated				RushOrderTo__c=opp.Rush_Order__c,
//depreciated				RushOrderReasonFrom__c=null,
//depreciated				RushOrderReasonTo__c=opp.Rush_Order_Reason__c,
//depreciated				RushOrderSetBySystemFrom__c=false,
//depreciated				RushOrderSetBySystemTo__c=opp.Rush_Order_Set_By_System__c);
//depreciated		}
//depreciated		else {
//depreciated			snapshot = new OpportunitySnapshot__c(
//depreciated				Opportunity__c=opp.Id,
//depreciated				RushOrderFrom__c=oldOpp.Rush_Order__c,
//depreciated				RushOrderTo__c=opp.Rush_Order__c,
//depreciated				RushOrderReasonFrom__c=oldOpp.Rush_Order_Reason__c,
//depreciated				RushOrderReasonTo__c=opp.Rush_Order_Reason__c,
//depreciated				RushOrderSetBySystemFrom__c=oldOpp.Rush_Order_Set_By_System__c,
//depreciated				RushOrderSetBySystemTo__c=opp.Rush_Order_Set_By_System__c);
//depreciated		}
//depreciated		return snapshot;
//depreciated	}

//depreciated	/**
//depreciated	 * Method to insert a snapshot.
//depreciated	 */
//depreciated	public void insertOpportunitySnapshot() {
//depreciated		for(Opportunity opp : newMap.values()) {			
//depreciated			if (haveSnapshotFieldsChanged(opp) && !OpportunitySnapshotHelper.hasAlreadyCreatedSnapshot()) {
//depreciated				OpportunitySnapshot__c snapshot = createSnapshotRecord(opp);
//depreciated				OpportunitySnapshotHelper.setAlreadyCreatedSnapshot();
//depreciated				insert snapshot;
//depreciated			}
//depreciated		}
//depreciated	}

//depreciated	/** Lookup the POC record id. */
//depreciated	// to do: Once this is the same on all environments this can be changed to constant value
//depreciated	public static Id pocRecordTypeId {
//depreciated		get {
//depreciated			return RecordTypeLookup.getRecordTypeId('Proof of Concept','Opportunity');
//depreciated		}
//depreciated	}

//depreciated	/**
//depreciated	 * Lookup the global pricebook id.
//depreciated	 */
//depreciated	public static String globalPricebookId {
//depreciated		get {
//depreciated			if (globalPricebookId == null) {
//depreciated				for(Pricebook2 globalPriceBook : [
//depreciated					SELECT Id 
//depreciated			 		FROM Pricebook2 
//depreciated					WHERE Name = 'Global Price Book' limit 1] )
//depreciated					
//depreciated				{
//depreciated					globalPriceBookId = globalPriceBook.Id;
//depreciated				}
//depreciated			}
//depreciated			return globalPricebookId;
//depreciated		}
//depreciated		set;
//depreciated	}

//depreciated	// batch fetch all the line items from any opportunities used to create POC opportunities
//depreciated	private Map<Id,List<OpportunityLineItem>> sourceOppLineItems {
//depreciated		get {
//depreciated			if(sourceOppLineItems == null) {
//depreciated				Set<Id> sourceOppIds = new Set<Id>();
//depreciated				for(Opportunity opp : newMap.values()) {
//depreciated					if(opp.RecordTypeId == pocRecordTypeId && opp.Cloned_From_Opportunity__c != null) {
//depreciated						sourceOppIds.add(opp.Cloned_From_Opportunity__c);
//depreciated					}
//depreciated				}
//depreciated				if(sourceOppIds.size() > 0) {
//depreciated					List<OpportunityLineItem> lineItems = [
//depreciated						SELECT ActualEndDate__c,
//depreciated							ActualStartDate__c,
//depreciated							ActualTerm__c,
//depreciated							Base_Price__c,
//depreciated							Configured_SKU__c,
//depreciated							Contract_Numbers__c,
//depreciated							CurrencyIsoCode,
//depreciated							Description,
//depreciated							Extended_Sales_Price__c,
//depreciated							HasQuantitySchedule,
//depreciated							HasRevenueSchedule,
//depreciated							HasSchedule,
//depreciated							Line_Item_Source__c,
//depreciated							ListPrice,
//depreciated							NewOrRenewal__c,
//depreciated							OpportunityCloseDate__c,
//depreciated							OpportunityId,
//depreciated							PricebookEntryId,
//depreciated							Pricing_Attributes__c,
//depreciated							ProductDefaultTerm__c,
//depreciated							Quantity,
//depreciated							RenewalProduct__c,
//depreciated							ScheduleLocked__c,
//depreciated							ServiceDate,
//depreciated							SortOrder,
//depreciated							Suggested_List_Price__c,
//depreciated							TotalPrice,
//depreciated							UnitPrice,
//depreciated							Year1Amount__c,
//depreciated							Year2Amount__c,
//depreciated							Year3Amount__c,
//depreciated							Year4Amount__c,
//depreciated							Year5Amount__c,
//depreciated							Year6Amount__c,
//depreciated							YearlySalesPrice__c
//depreciated						FROM OpportunityLineItem
//depreciated						WHERE OpportunityId IN :sourceOppIds];
//depreciated					sourceOppLineItems = new Map<Id,List<OpportunityLineItem>>();
//depreciated					for(OpportunityLineItem lineItem : lineItems) {
//depreciated						if(sourceOppLineItems.containsKey(lineItem.OpportunityId)) {
//depreciated							sourceOppLineItems.get(lineItem.OpportunityId).add(lineItem);
//depreciated						}
//depreciated						else {
//depreciated							sourceOppLineItems.put(lineItem.OpportunityId, new List<OpportunityLineItem>{lineItem});
//depreciated						}
//depreciated					}
//depreciated				}
//depreciated			}
//depreciated			return sourceOppLineItems;
//depreciated		}
//depreciated		private set;
//depreciated	}

//depreciated	private Map<Id,String> sourceOppCurrencies {
//depreciated		get {
//depreciated			if(sourceOppCurrencies == null) {
//depreciated				sourceOppCurrencies = new Map<Id,String>();
//depreciated				Set<Id> sourceOppIds = new Set<Id>();
//depreciated				for(Opportunity opp : newMap.values()) {
//depreciated					if(opp.RecordTypeId == pocRecordTypeId && opp.Cloned_From_Opportunity__c != null) {
//depreciated						sourceOppIds.add(opp.Cloned_From_Opportunity__c);
//depreciated					}
//depreciated				}
//depreciated				if(sourceOppIds.size() > 0) {
//depreciated					List<Opportunity> opps = [SELECT Id, CurrencyISOCode 
//depreciated												FROM Opportunity 
//depreciated												WHERE Id IN :sourceOppIds];
//depreciated					for(Opportunity opp : opps) {
//depreciated						sourceOppCurrencies.put(opp.Id, opp.CurrencyISOCode);
//depreciated					}
//depreciated				}
//depreciated			}
//depreciated			return sourceOppCurrencies;
//depreciated		}
//depreciated		private set;
//depreciated	}

//depreciated	/** 
//depreciated	 * For each new proof of concept opp that was created from another opp,
//depreciated	 * copy the products from the source opp.
//depreciated	 */
//depreciated	public void copyProofOfConceptProducts() {
//depreciated		if(isInsert) {
//depreciated			List<OpportunityLineItem> targetOppLineItems = new List<OpportunityLineItem>();
//depreciated			for(Opportunity opp : newMap.values()) {
//depreciated				if(opp.RecordTypeId == pocRecordTypeId && opp.Cloned_From_Opportunity__c != null) {
//depreciated					List<OpportunityLineItem> sourceLineItems = sourceOppLineItems.get(opp.Cloned_From_Opportunity__c);
//depreciated					if(sourceLineItems != null && opp.CurrencyIsoCode == sourceOppCurrencies.get(opp.Cloned_From_Opportunity__c)) {
//depreciated						List<OpportunityLineItem> targetLineItems = sourceLineItems.deepClone(false);
//depreciated						for(OpportunityLineItem lineItem : targetLineItems) {
//depreciated							lineItem.OpportunityId = opp.Id;
//depreciated							lineItem.TotalPrice = null;
//depreciated						}
//depreciated						if(opp.Pricebook2Id != null) {
//depreciated							targetOppLineItems.addAll(targetLineItems);
//depreciated						}
//depreciated					}
//depreciated				}
//depreciated			}
//depreciated			if(! targetOppLineItems.isEmpty()) {
//depreciated				for(Database.Saveresult sr : Database.insert(targetOppLineItems,false)) {
//depreciated					OpportunityLineItem lineItem = targetOppLineItems.remove(0);
//depreciated					if(! sr.isSuccess()) {
//depreciated						Opportunity opp = newMap.get(lineItem.OpportunityId);
//depreciated						opp.addError('Failed to add line item: '+sr.getErrors());
//depreciated						hasErrors = true;
//depreciated					}
//depreciated				}
//depreciated			}
//depreciated		}
//depreciated	}

//depreciated	/**
//depreciated	 * Link the solution which created this opportunity.
//depreciated	 */
//depreciated	public void linkSolutions() {
//depreciated		if(isInsert) {
//depreciated			List<StrategicPlan_SolutionOpportunity__c> solutionOpportunities = new List<StrategicPlan_SolutionOpportunity__c>();
//depreciated			for(Opportunity opp : newMap.values()) {
//depreciated				if(opp.CreatedFromSolution__c != null) {
//depreciated					solutionOpportunities.add(
//depreciated						new StrategicPlan_SolutionOpportunity__c(
//depreciated							Opportunity__c = opp.Id,
//depreciated							StrategicPlan_Solution__c = opp.CreatedFromSolution__c));
//depreciated				}
//depreciated			}
//depreciated			if(! solutionOpportunities.isEmpty()) {
//depreciated				for(Database.Saveresult sr : Database.insert(solutionOpportunities,false)) {
//depreciated					StrategicPlan_SolutionOpportunity__c solutionOpportunity = solutionOpportunities.remove(0);
//depreciated					if(!sr.isSuccess()) {
//depreciated						Opportunity opp = newMap.get(solutionOpportunity.Opportunity__c);
//depreciated						opp.addError('Failed to link solution: '+sr.getErrors());
//depreciated						hasErrors = true;
//depreciated					}
//depreciated				}
//depreciated			}
//depreciated		}
//depreciated	}

//depreciated	/**
//depreciated	 * Method to invoke all triggers
//depreciated	 */
//depreciated	public static void processTrigger(Map<Id,Opportunity> xoldMap,Map<Id,Opportunity> xnewMap) {
//depreciated		final OpportunityTriggerAfter afterTrigger = new OpportunityTriggerAfter(xoldMap,xnewMap);
//depreciated		if(AbstractTrigger.isActive(INSERT_OPPORTUNITY_SNAPSHOT_SETTING,true)) {
//depreciated			afterTrigger.insertOpportunitySnapshot();
//depreciated		}
//depreciated		if(AbstractTrigger.isActive(COPY_POC_PRODUCTS_SETTING,true)) {
//depreciated			afterTrigger.copyProofOfConceptProducts();
//depreciated		}
//depreciated		if(AbstractTrigger.isActive(LINK_SOLUTIONS_SETTING,true)) {
//depreciated			afterTrigger.linkSolutions();
//depreciated		}
//depreciated		AbstractTrigger.processTriggerComplete();
//depreciated	}
}