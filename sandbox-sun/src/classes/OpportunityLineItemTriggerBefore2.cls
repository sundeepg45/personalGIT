/**
 * This class replaces all before insert, before update, and before delete 
 * OpportunityLineItem triggers.  The processTrigger method is invoked by the 
 * OpportunityLineItem_Before trigger and in turn invokes all the processTrigger 
 * methods of the subclasses.  This gives us a way to control the order in which 
 * the code logic is invoked, as well as allowing other class features 
 * such as shared data, constant values, and complete test coverage.
 * <p>
 * The Trigger object should never be directly referenced inside this class or it's subclasses
 * as that would make it impossible to substituting values inside test methods.
 * </p>
 * 
 * @version 2015-12-11
 * @author Bill C Riemers <briemers@redhat.com>
 * 2015-12-11 - capture errors when setting embedded, and set the description when needed
 * 2015-10-28 - Moved process opportunity products trigger method into this class
 * 2012-09-27 - initial version
 * Scott Coleman <scoleman@redhat.com>
 * 2013-08-09 - Renamed to avoid release conflicts, implemented Embedded
 * 2013-07-15 - implemented Opp Lock
 */
public without sharing class OpportunityLineItemTriggerBefore2 extends AbstractTrigger {
	/** BooleanSetting__c key to enable the calculateActual trigger method. */
	public static final String CALC_ACTUAL_SETTING = 'LineItem_Before.calcActual';
	/** BooleanSetting__c key to enable the calculateSchedule trigger method. */
	public static final String CALC_SCHEDULE_SETTING = 'LineItem_Before.calcSchedule';
	/** BooleanSetting__c key to enable the calculateSchedule trigger method. */
	public static final String RESTRICT_DELETIONS_SETTING = 'LineItem_Before.restrictDeletions';
	/** BooleanSetting__c key to enable the oppLock trigger method. */
	public static final String OPP_LOCK_SETTING = 'LineItem_Before.oppLock';
	/** BooleanSetting__c key to enable the setEmbedded trigger method. */
	public static final String SET_EMBEDDED_SETTING = 'LineItem_Before.setEmbedded';
	/** StringSetting__c key for the line item description substring that indicates an Embedded deal **/
	public static final String EMBEDDED_DESCRIPTION_SETTING = 'Opportunity.EmbeddedDescription';
	/** Key value used to signal that an update to Embedded originated in this trigger class **/
	public static final Integer EMBEDDED_TRIGGER_KEY = -1;
	/** 
	 * Used to overload close date when testing, so we do not need to insert an opportunity
	 * and a line item.
	 */
	public static Date testingCloseDate = null;

	/** Normally populated as Trigger.oldMap */
	protected final Map<Id,OpportunityLineItem> oldMap = new Map<Id,OpportunityLineItem>();
	/** Normally populated as Trigger.new */
	protected final List<OpportunityLineItem> newList = new List<OpportunityLineItem>();

	/**
	 * This is a typical TriggerBefore type constructor.
	 *
	 * @param xoldMap typically assigned from Trigger.oldMap
	 * @param xnewList typically assigned from Trigger.newList
	 */
	public OpportunityLineItemTriggerBefore2(Map<Id,OpportunityLineItem> xoldMap,List<OpportunityLineItem> xnewList) {
		super(xoldMap,xnewList,null);
		if(xoldMap != null) {
			oldMap.putAll(xoldMap);
		}
		if(xnewList != null) {
			newList.addAll(xnewList);
		}
	}

	private Date calculateActualEndDate(Date actualStartDate,Date refDate,OpportunityLineItem lineItem) {
		Date actualEndDate;
		// this code is inherently unstable.  Each time called
		// the actual end date may shift.
		Decimal xactualTerm = lineItem.ActualTerm__c;
		if (xactualTerm == 0.0 || xactualTerm == 365.0) {
			actualEndDate = actualStartDate.addYears(1);
		}
		else {
			for(actualEndDate = actualStartDate;xactualTerm >= 365.0;xactualTerm -= 365.0) {
				actualEndDate = actualEndDate.addYears(1);
			}
			// the pricebook stores days, but we actually
			// want number of months...
			if (xactualTerm == 30.0) {
				actualEndDate = actualEndDate.addMonths(1);
			}
			else if (xactualTerm == 60.0) {
				actualEndDate = actualEndDate.addMonths(2);
			}
			else if (xactualTerm == 90.0) {
				actualEndDate = actualEndDate.addMonths(3);
			}
			else if (xactualTerm == 335.0) {
				actualEndDate = actualEndDate.addMonths(11);
			}
			else if (xactualTerm > 0.0) {
				// simply add the specific number of days correcting for leap days
				// This is probably really not what we want.
				actualEndDate = refDate.addDays(Math.ceil(1461.0*(xactualTerm+Math.floor(1460.0*refDate.daysBetween(actualEndDate)/1461.0))/1460.0).intValue());
			}
		}
		// Start to end dates are not inclusive, remove one day
		return actualEndDate.addDays(-1);
	}

	/**
	 * This method blocks deletion of a line item when the opp is locked.
	 */
	public void oppLock() {
		if(isDelete) {
			AdminByPass__c bypass = AdminByPass__c.getInstance();
			if(bypass != null && bypass.IsSalesUser__c) {
				Map<Id,Boolean> oppLockMap = new Map<Id,Boolean>();
				for(OpportunityLineItem lineItem: oldMap.values()) {
					oppLockMap.put(lineItem.OpportunityId,false);
				}
		
				List<Opportunity> opps = [
					SELECT IsLockedForSales__c
					FROM Opportunity
					WHERE Id IN :oppLockMap.keySet()];
				for(Opportunity opp: opps) {
					oppLockMap.put(opp.Id,opp.IsLockedForSales__c);
				}
		
				for(OpportunityLineItem lineItem: oldMap.values()) {
					if(oppLockMap.get(lineItem.OpportunityId)) {
						lineItem.addError(System.Label.Opp_Lock_Message);
						hasErrors = true;
					}
				}
			}
		}
	}

	Map<Id,PricebookEntry> pricebookEntryMap {
		get {
			if(pricebookEntryMap == null) {
				Set<Id> pricebookEntryIds = new Set<Id>();
				for(OpportunityLineItem lineItem: newList) {
					System.Debug('#####pricebook entry id: ' + lineItem.PricebookEntryId);
					if(lineItem.PricebookEntryId != null && !pricebookEntryIds.contains(lineItem.PricebookEntryId)) {
						pricebookEntryIds.add(lineItem.PricebookEntryId);
					}
				}
				pricebookEntryMap = new Map<Id,PricebookEntry>([
					SELECT
						Id,
						ProductCode,
						Product2.Description
					FROM PricebookEntry
					WHERE Id IN :pricebookEntryIds ]);
			}
			return pricebookEntryMap;
		}
		set;
	}

	/**
	 * This method sets the embedded flag on the associated Opportunity
	 * if an appropriate line item is added and Opportunity.EmbeddedOverridden__c is false.
	 */
	public void setEmbedded() {
		if(isInsert || isUpdate) {
			//build product code map
			//determine which line items are embedded
			Map<String,EmbeddedSku__c> embeddedSkus = EmbeddedSku__c.getAll();
			StringSetting__c embeddedDescription = StringSetting__c.getInstance(EMBEDDED_DESCRIPTION_SETTING);
			Set<Id> opportunityIds = new Set<Id>();
			Boolean isRunningTest = Test.isRunningTest();
			for(OpportunityLineItem lineItem: newList) {
				// assign description, because we need it
				if(lineItem.Description == null) {
					PricebookEntry pbe = pricebookEntryMap.get(lineItem.PricebookEntryId);
					if(pbe != null && pbe.Product2 != null) {
						lineItem.Description = pbe.Product2.Description;
					}
				}
				if( ( isRunningTest 
						|| ( lineItem.Embedded_Opportunity__c != true 
							&& ( lineItem.EmbeddedOverridden__c == null || lineItem.EmbeddedOverridden__c <= 0 ) ) )
					&& ! opportunityIds.contains(lineItem.OpportunityId) )
				{
					//embedded because the product description contains the embedded keyword
					if (embeddedDescription != null
						&& embeddedDescription.Value__c != null
						&& lineItem.Description != null 
						&& lineItem.Description.containsIgnoreCase(embeddedDescription.Value__c))
					{
						opportunityIds.add(lineItem.OpportunityId);
					}
					else if (!embeddedSkus.isEmpty()) {
						//embedded because the sku or config sku is in the embedded skus list
						if (lineItem.Configured_SKU__c != null && embeddedSkus.keySet().contains(lineItem.Configured_SKU__c)) {
							opportunityIds.add(lineItem.OpportunityId);
						}
						else {
							PricebookEntry pbe = pricebookEntryMap.get(lineItem.PricebookEntryId);
							if (pbe != null && embeddedSkus.keySet().contains(pbe.ProductCode)) {
								opportunityIds.add(lineItem.OpportunityId);
							}
						}
					}
				}
			}
			//update opportunities that need updating
			if(!opportunityIds.isEmpty()) {
				List<Opportunity> embeddedOpportunities = new List<Opportunity>();
				for(Id oppId: opportunityIds) {
					embeddedOpportunities.add( new Opportunity(
						Id = oppId,
						Embedded__c = true,
						EmbeddedOverridden__c = EMBEDDED_TRIGGER_KEY) );
				}
				for(Database.SaveResult sr : Database.update(embeddedOpportunities,false)) {
					Opportunity opp = embeddedOpportunities.remove(0);
					if(! sr.isSuccess()) {
						for(OpportunityLineItem lineItem: newList) {
							if(lineItem.OpportunityId == opp.Id) {
								lineItem.addError('Failed to set embedded flag:\n'+sr.getErrors());
								hasErrors = true;
							}
						}
					}
				}
			}
		}
	}

	/**
	 * This method is a replaces the part of the OpportunityLineItem_CalculateBookingSchedule 
	 * that computes ActualTerm__c, ActualStartDate__c, and ActualEndDate__c values.
	 */
	public void calculateActual() {
		Date refDate = Date.newInstance(2000,2,28);
		// Loop through each opportunity line item (aka opportunity product)
		for(Integer i=newList.size();i-- > 0;) {
			OpportunityLineItem lineItem = newList[i];
			// determine the actual start date
			Date actualStartDate = lineItem.ActualStartDate__c;
			Date closeDate = lineItem.OpportunityCloseDate__c;
			if(closeDate == null) {
				closeDate = testingCloseDate;
			}
			if (actualStartDate == null || (closeDate != null && lineItem.ScheduleLocked__c == false)) {
				if(closeDate == null) {
					lineItem.addError('No close date for Opportunity '+lineItem.OpportunityId);
					newList.remove(i);
					continue;
				}
				actualStartDate = closeDate.addDays(1);
			}
			Integer actualStartNormalized = Math.floor(1460.0*refDate.daysBetween(actualStartDate)/1461.0).intValue();
			// We have changed the way the actual term value is
			// calculated.  As such we may need to adjust the 
			// actual term value when it has been unchanged.
			OpportunityLineItem previous = oldMap.get(lineItem.id);
			if(previous != null 
				&& previous.ScheduleLocked__c == false
				&& previous.ActualTerm__c != null
				&& previous.ActualTerm__c != 0
				&& previous.ActualTerm__c == lineItem.ActualTerm__c
				&& previous.ActualStartDate__c != null
				&& previous.ActualEndDate__c != null )
			{
				Date previousActualEndDate = calculateActualEndDate(previous.ActualStartDate__c,refDate,previous);
				if(previousActualEndDate.addDays(1) == previous.ActualEndDate__c
					|| (previous.ActualTerm__c > 1460 && previousActualEndDate.addDays(2) == previous.ActualEndDate__c))
				{
					lineItem.ActualTerm__c = 1
						+ Math.floor(1460.0*refDate.daysBetween(previousActualEndDate)/1461.0).intValue()
						- actualStartNormalized;
				}
			}
			if(lineItem.ActualTerm__c == null) {
				Decimal xactualTerm = lineItem.ProductDefaultTerm__c;
				if(xactualTerm == null || xactualTerm == 0.0) {
					xactualTerm = 365.0;
				}
				lineItem.ActualTerm__c = xactualTerm;
			}
			Date actualEndDate = lineItem.ActualEndDate__c;
			if (actualEndDate == null || lineItem.ScheduleLocked__c == false) {
				actualEndDate = calculateActualEndDate(actualStartDate,refDate,lineItem);
			}
			System.debug ('- Actual End Date = ' + actualEndDate);
			Integer actualEndNormalized = Math.floor(1460.0*refDate.daysBetween(actualEndDate)/1461.0).intValue();
			Integer actualTerm = 1+actualEndNormalized-actualStartNormalized;
			if(actualTerm <= 0) {
				lineItem.addError('ActualStartDate must be before the ActualEndDate.');
				newList.remove(i);
				continue;
			}
			// we now have all the actual values lets store them
			if(actualTerm != lineItem.ActualTerm__c ) {
				// if we used actual term to compute the actual end date, then keep the current actual term value
				if(actualTerm == 365.0 || lineItem.ScheduleLocked__c != false ) {
					lineItem.ActualTerm__c = actualTerm;
				}
			}
			if(actualStartDate != lineItem.ActualStartDate__c) {
				lineItem.ActualStartDate__c = actualStartDate;
			}
			if(actualEndDate != lineItem.ActualEndDate__c) {
				lineItem.ActualEndDate__c = actualEndDate;
			}
		}
	}

	/**
	 * This method is a replacement for the OpportunityLineItem_CalculateBookingSchedule trigger.
	 * This uses the new R-12 SYB rules to calculate the SYB and the booking for subsiquent years.
	 */
	public void calculateSchedule() {
		Date refDate = Date.newInstance(2000,2,28);
		// Loop through each opportunity line item (aka opportunity product)
		for(Integer i=newList.size();i-- > 0;) {
			OpportunityLineItem lineItem = newList[i];
			if(lineItem.ActualStartDate__c != null && lineItem.ActualEndDate__c != null) {
				if (lineItem.Quantity == null) {
					lineItem.Quantity = 0.0;
				}
				if (lineItem.UnitPrice == null && lineItem.TotalPrice == null) {
					lineItem.UnitPrice = 0.0;
				}
				// Calculate a total price. Because SF waits until after 
				// triggers to determine the total price, we need to do this 
				// up front.
				Decimal totalPrice = lineItem.TotalPrice;
				if (lineItem.UnitPrice != null) {
					totalPrice = lineItem.Quantity * lineItem.UnitPrice;
				}
				System.debug('Total Price = '+totalPrice+' = '+lineItem.Quantity+'*'+lineItem.UnitPrice);

				Date closeDate = lineItem.OpportunityCloseDate__c;
				if(closeDate == null) {
					closeDate = testingCloseDate;
					if(closeDate == null) {
						lineItem.addError('No close date for Opportunity '+lineItem.OpportunityId);
						newList.remove(i);
						continue;
					}
				}
				Integer closeDateNormalized = Math.floor(1460.0*refDate.daysBetween(closeDate)/1461.0).intValue();

				Integer actualStartNormalized = Math.floor(1460.0*refDate.daysBetween(lineItem.ActualStartDate__c)/1461.0).intValue();
				Integer actualEndNormalized = Math.floor(1460.0*refDate.daysBetween(lineItem.ActualEndDate__c)/1461.0).intValue();
				Integer actualTerm = 1+actualEndNormalized-actualStartNormalized;
				if(actualTerm <= 0) {
					lineItem.addError('ActualStartDate must be before the ActualEndDate.');
					newList.remove(i);
					continue;
				}

				Double perDiem = totalPrice / actualTerm;
				Double yearlyPrice = perDiem * 365.0;
				Decimal remainingAmount = totalPrice;

				List<Decimal> amounts = new List<Double>();
				Integer sybStart = actualStartNormalized;
				Integer sybNextStart = closeDateNormalized+366;
				// keep looping until the next year starts after the actual start date
				for(;sybNextStart <= actualStartNormalized;sybNextStart += 365) {
					amounts.add(0.0);
				}
				// find out if we have less than a full year
				if(sybNextStart > actualEndNormalized ) {
					sybNextStart = actualEndNormalized+1;
				}
				Decimal roundoff = 0.000;
				// use the perDiem to compute the amount
				if(sybNextStart > sybStart) {
					Decimal amount0 = Decimal.valueOf(perDiem * (sybNextStart - sybStart));
					Decimal amount = amount0.divide(1,2,System.RoundingMode.HALF_EVEN);
					roundoff = amount0 - amount;
					amounts.add(amount);
					remainingAmount -= amount;
				}
				// the remaining years are just the lesser of the yearly amount of the remaining amount
				while(Math.abs(remainingAmount) > 0.005 && amounts.size() < 5) {
					Decimal amount0 = ((yearlyPrice >= 0.0) ?
						Math.min(remainingAmount,yearlyPrice+roundoff) :
						Math.max(remainingAmount,yearlyPrice+roundoff));
					Decimal amount = amount0.divide(1,2,System.RoundingMode.HALF_EVEN);
					roundoff = amount0-amount;
					remainingAmount -= amount;
					amounts.add(amount);
				}
				// this is just to make sure we don't have an index out of bounds error
				amounts.addAll(new List<Decimal>{0.00,0.00,0.00,0.00,0.00,0.00});
/* Don't set, this field is for quoting tools only
				Decimal yearlySalesPrice = yearlyPrice;
				if(lineItem.Quantity != 0) {
					yearlySalesPrice = yearlySalesPrice.divide(lineItem.Quantity,2,System.RoundingMode.HALF_EVEN);
				}
				if(yearlySalesPrice != lineItem.YearlySalesPrice__c) {
					lineItem.YearlySalesPrice__c = yearlySalesPrice;
				}
*/
				lineItem.Year1Amount__c = amounts[0];
				lineItem.Year2Amount__c = amounts[1];
				lineItem.Year3Amount__c = amounts[2];
				lineItem.Year4Amount__c = amounts[3];
				lineItem.Year5Amount__c = amounts[4];
				lineItem.Year6Amount__c = (totalPrice-amounts[0]-amounts[1]-amounts[2]-amounts[3]-amounts[4]-amounts[5]).divide(1,2,System.RoundingMode.HALF_EVEN);
			}
		}
	}

	@TestVisible
	static AdminByPass__c adminByPass { get {
		if(adminByPass == null) {
			adminByPass = AdminByPass__c.getInstance();
		}
		return adminByPass;
	}}

	/**
	 * Disallow product deletes for on closed won opportunities for sales users
	 * and disallow product deletes for all non-admin users for closed booked opportunities.
	 */
	public void restrictDeletions() {
		if(isDelete && adminByPass.IsIT__c != true) {
			Set<String> stageNames = new Set<String>{ OpportunityTriggerBefore2.CLOSED_BOOKED_PLV };
			if(adminByPass.IsSalesUser__c == true) {
				stageNames.add(OpportunityTriggerBefore2.CLOSED_WON_PLV);
			}
			Set<Id> oppIds = new Set<Id>();
			for(OpportunityLineItem lineItem : oldMap.values()){
				oppIds.add(lineItem.OpportunityId);  
			}
			oppIds = new Map<Id, Opportunity>([
				select Id
				from Opportunity
				where Id IN :oppIds and StageName in :stageNames ]).keySet();
			for(OpportunityLineItem lineItem : oldMap.values()){
				if(oppIds.contains(lineItem.OpportunityId)) {
					lineItem.addError(Label.OppProducts_Cannot_Be_Deleted);
					hasErrors = true;
				}
			}
		}
	}

	/**
	 * This method is called from the OpportunityLineItem_Before trigger to invoke all the methods
	 * of this class, to obsolete the need for individual before triggers.  The primary
	 * reason to place all the triggers in a class is so we control the order in which
	 * the triggers are invoked.
	 *
	 * @param xoldMap the immutable map of previous OpportunityLineItem objects as in Trigger.oldMap.
	 * @param xnewList the list of new OpportunityLineItem objects as in Trigger.new
	 */
	public static void processTrigger(Map<Id,OpportunityLineItem> xoldMap,List<OpportunityLineItem> xnewList) {
		final OpportunityLineItemTriggerBefore2 beforeTrigger = new OpportunityLineItemTriggerBefore2(xoldMap,xnewList);
		if(AbstractTrigger.isActive(OPP_LOCK_SETTING,true)) {
			beforeTrigger.oppLock();
		}
		if(AbstractTrigger.isActive(SET_EMBEDDED_SETTING,true)) {
			beforeTrigger.setEmbedded();
		}
		if(AbstractTrigger.isActive(CALC_ACTUAL_SETTING,true)) {
			beforeTrigger.calculateActual();
		}
		if(AbstractTrigger.isActive(CALC_SCHEDULE_SETTING,true)) {
			beforeTrigger.calculateSchedule();
		}
		if(AbstractTrigger.isActive(RESTRICT_DELETIONS_SETTING,true)) {
			beforeTrigger.restrictDeletions();
		}
	}
}