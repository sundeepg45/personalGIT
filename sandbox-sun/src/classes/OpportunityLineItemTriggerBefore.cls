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
 * @version 2015-10-28
 * @author Bill C Riemers <briemers@redhat.com>
 * 2015-10-28 - commented everything out to mark as depreciated
 * 2012-09-27 - initial version
 * Scott Coleman <scoleman@redhat.com>
 * 2013-07-15 - implemented Opp Lock
 */
@IsTest
private class OpportunityLineItemTriggerBefore {}
//depreciated public without sharing  class OpportunityLineItemTriggerBefore extends AbstractTrigger {
//depreciated	/** BooleanSetting__c key to enable the calculateActual trigger method. */
//depreciated	public static final String CALC_ACTUAL_SETTING = 'LineItem_Before.calcActual';
//depreciated	/** BooleanSetting__c key to enable the calculateSchedule trigger method. */
//depreciated	public static final String CALC_SCHEDULE_SETTING = 'LineItem_Before.calcSchedule';
//depreciated	/** BooleanSetting__c key to enable the oppLock trigger method. */
//depreciated	public static final String OPP_LOCK_SETTING = 'LineItem_Before.oppLock';
//depreciated	/** 
//depreciated	 * Used to overload close date when testing, so we do not need to insert an opportunity
//depreciated	 * and a line item.
//depreciated	 */
//depreciated	public static Date testingCloseDate = null;

//depreciated	/** Normally populated as Trigger.oldMap */
//depreciated	protected final Map<Id,OpportunityLineItem> oldMap = new Map<Id,OpportunityLineItem>();
//depreciated	/** Normally populated as Trigger.new */
//depreciated	protected final List<OpportunityLineItem> newList = new List<OpportunityLineItem>();

//depreciated	/**
//depreciated	 * This is a typical TriggerBefore type constructor.
//depreciated	 *
//depreciated	 * @param xoldMap typically assigned from Trigger.oldMap
//depreciated	 * @param xnewList typically assigned from Trigger.newList
//depreciated	 */
//depreciated	public OpportunityLineItemTriggerBefore(Map<Id,OpportunityLineItem> xoldMap,List<OpportunityLineItem> xnewList) {
//depreciated		super(xoldMap,xnewList,null);
//depreciated		if(xoldMap != null) {
//depreciated			oldMap.putAll(xoldMap);
//depreciated		}
//depreciated		if(xnewList != null) {
//depreciated			newList.addAll(xnewList);
//depreciated		}
//depreciated	}

//depreciated	private Date calculateActualEndDate(Date actualStartDate,Date refDate,OpportunityLineItem lineItem) {
//depreciated		Date actualEndDate;
//depreciated		// this code is inherently unstable.  Each time called
//depreciated		// the actual end date may shift.
//depreciated		Decimal xactualTerm = lineItem.ActualTerm__c;
//depreciated		if (xactualTerm == 0.0 || xactualTerm == 365.0) {
//depreciated			actualEndDate = actualStartDate.addYears(1);
//depreciated		}
//depreciated		else {
//depreciated			for(actualEndDate = actualStartDate;xactualTerm >= 365.0;xactualTerm -= 365.0) {
//depreciated				actualEndDate = actualEndDate.addYears(1);
//depreciated			}
//depreciated			// the pricebook stores days, but we actually
//depreciated			// want number of months...
//depreciated			if (xactualTerm == 30.0) {
//depreciated				actualEndDate = actualEndDate.addMonths(1);
//depreciated			}
//depreciated			else if (xactualTerm == 60.0) {
//depreciated				actualEndDate = actualEndDate.addMonths(2);
//depreciated			}
//depreciated			else if (xactualTerm == 90.0) {
//depreciated				actualEndDate = actualEndDate.addMonths(3);
//depreciated			}
//depreciated			else if (xactualTerm == 335.0) {
//depreciated				actualEndDate = actualEndDate.addMonths(11);
//depreciated			}
//depreciated			else if (xactualTerm > 0.0) {
//depreciated				// simply add the specific number of days correcting for leap days
//depreciated				// This is probably really not what we want.
//depreciated				actualEndDate = refDate.addDays(Math.ceil(1461.0*(xactualTerm+Math.floor(1460.0*refDate.daysBetween(actualEndDate)/1461.0))/1460.0).intValue());
//depreciated			}
//depreciated		}
//depreciated		// Start to end dates are not inclusive, remove one day
//depreciated		return actualEndDate.addDays(-1);
//depreciated	}

//depreciated	/**
//depreciated	 * This method blocks deletion of a line item when the opp is locked.
//depreciated	 */
//depreciated	public void oppLock() {
//depreciated		if(isDelete) {
//depreciated			AdminByPass__c bypass = AdminByPass__c.getInstance();
//depreciated			if(bypass != null && bypass.IsSalesUser__c) {
//depreciated				Map<Id,Boolean> oppLockMap = new Map<Id,Boolean>();
//depreciated				for(OpportunityLineItem lineItem: oldMap.values()) {
//depreciated					oppLockMap.put(lineItem.OpportunityId,false);
//depreciated				}
//depreciated		
//depreciated				List<Opportunity> opps = [
//depreciated					SELECT IsLockedForSales__c
//depreciated					FROM Opportunity
//depreciated					WHERE Id IN :oppLockMap.keySet()];
//depreciated				for(Opportunity opp: opps) {
//depreciated					oppLockMap.put(opp.Id,opp.IsLockedForSales__c);
//depreciated				}
//depreciated		
//depreciated				for(OpportunityLineItem lineItem: oldMap.values()) {
//depreciated					if(oppLockMap.get(lineItem.OpportunityId)) {
//depreciated						lineItem.addError(System.Label.Opp_Lock_Message);
//depreciated						hasErrors = true;
//depreciated					}
//depreciated				}
//depreciated			}
//depreciated		}
//depreciated	}

//depreciated	/**
//depreciated	 * This method is a replaces the part of the OpportunityLineItem_CalculateBookingSchedule 
//depreciated	 * that computes ActualTerm__c, ActualStartDate__c, and ActualEndDate__c values.
//depreciated	 */
//depreciated	public void calculateActual() {
//depreciated		Date refDate = Date.newInstance(2000,2,28);
//depreciated		// Loop through each opportunity line item (aka opportunity product)
//depreciated		for(Integer i=newList.size();i-- > 0;) {
//depreciated			OpportunityLineItem lineItem = newList[i];
//depreciated			// determine the actual start date
//depreciated			Date actualStartDate = lineItem.ActualStartDate__c;
//depreciated			Date closeDate = lineItem.OpportunityCloseDate__c;
//depreciated			if(closeDate == null) {
//depreciated				closeDate = testingCloseDate;
//depreciated			}
//depreciated			if (actualStartDate == null || (closeDate != null && lineItem.ScheduleLocked__c == false)) {
//depreciated				if(closeDate == null) {
//depreciated					lineItem.addError('No close date for Opportunity '+lineItem.OpportunityId);
//depreciated					newList.remove(i);
//depreciated					continue;
//depreciated				}
//depreciated				actualStartDate = closeDate.addDays(1);
//depreciated			}
//depreciated			Integer actualStartNormalized = Math.floor(1460.0*refDate.daysBetween(actualStartDate)/1461.0).intValue();
//depreciated			// We have changed the way the actual term value is
//depreciated			// calculated.  As such we may need to adjust the 
//depreciated			// actual term value when it has been unchanged.
//depreciated			OpportunityLineItem previous = oldMap.get(lineItem.id);
//depreciated			if(previous != null 
//depreciated				&& previous.ScheduleLocked__c == false
//depreciated				&& previous.ActualTerm__c != null
//depreciated				&& previous.ActualTerm__c != 0
//depreciated				&& previous.ActualTerm__c == lineItem.ActualTerm__c
//depreciated				&& previous.ActualStartDate__c != null
//depreciated				&& previous.ActualEndDate__c != null )
//depreciated			{
//depreciated				Date previousActualEndDate = calculateActualEndDate(previous.ActualStartDate__c,refDate,previous);
//depreciated				if(previousActualEndDate.addDays(1) == previous.ActualEndDate__c
//depreciated					|| (previous.ActualTerm__c > 1460 && previousActualEndDate.addDays(2) == previous.ActualEndDate__c))
//depreciated				{
//depreciated					lineItem.ActualTerm__c = 1
//depreciated						+ Math.floor(1460.0*refDate.daysBetween(previousActualEndDate)/1461.0).intValue()
//depreciated						- actualStartNormalized;
//depreciated				}
//depreciated			}
//depreciated			if(lineItem.ActualTerm__c == null) {
//depreciated				Decimal xactualTerm = lineItem.ProductDefaultTerm__c;
//depreciated				if(xactualTerm == null || xactualTerm == 0.0) {
//depreciated					xactualTerm = 365.0;
//depreciated				}
//depreciated				lineItem.ActualTerm__c = xactualTerm;
//depreciated			}
//depreciated			Date actualEndDate = lineItem.ActualEndDate__c;
//depreciated			if (actualEndDate == null || lineItem.ScheduleLocked__c == false) {
//depreciated				actualEndDate = calculateActualEndDate(actualStartDate,refDate,lineItem);
//depreciated			}
//depreciated			System.debug ('- Actual End Date = ' + actualEndDate);
//depreciated			Integer actualEndNormalized = Math.floor(1460.0*refDate.daysBetween(actualEndDate)/1461.0).intValue();
//depreciated			Integer actualTerm = 1+actualEndNormalized-actualStartNormalized;
//depreciated			if(actualTerm <= 0) {
//depreciated				lineItem.addError('ActualStartDate must be before the ActualEndDate.');
//depreciated				newList.remove(i);
//depreciated				continue;
//depreciated			}
//depreciated			// we now have all the actual values lets store them
//depreciated			if(actualTerm != lineItem.ActualTerm__c ) {
//depreciated				// if we used actual term to compute the actual end date, then keep the current actual term value
//depreciated				if(actualTerm == 365.0 || lineItem.ScheduleLocked__c != false ) {
//depreciated					lineItem.ActualTerm__c = actualTerm;
//depreciated				}
//depreciated			}
//depreciated			if(actualStartDate != lineItem.ActualStartDate__c) {
//depreciated				lineItem.ActualStartDate__c = actualStartDate;
//depreciated			}
//depreciated			if(actualEndDate != lineItem.ActualEndDate__c) {
//depreciated				lineItem.ActualEndDate__c = actualEndDate;
//depreciated			}
//depreciated		}
//depreciated	}

//depreciated	/**
//depreciated	 * This method is a replacement for the OpportunityLineItem_CalculateBookingSchedule trigger.
//depreciated	 * This uses the new R-12 SYB rules to calculate the SYB and the booking for subsiquent years.
//depreciated	 */
//depreciated	public void calculateSchedule() {
//depreciated		Date refDate = Date.newInstance(2000,2,28);
//depreciated		// Loop through each opportunity line item (aka opportunity product)
//depreciated		for(Integer i=newList.size();i-- > 0;) {
//depreciated			OpportunityLineItem lineItem = newList[i];
//depreciated			if(lineItem.ActualStartDate__c != null && lineItem.ActualEndDate__c != null) {
//depreciated				if (lineItem.Quantity == null) {
//depreciated					lineItem.Quantity = 0.0;
//depreciated				}
//depreciated				if (lineItem.UnitPrice == null && lineItem.TotalPrice == null) {
//depreciated					lineItem.UnitPrice = 0.0;
//depreciated				}
//depreciated				// Calculate a total price. Because SF waits until after 
//depreciated				// triggers to determine the total price, we need to do this 
//depreciated				// up front.
//depreciated				Decimal totalPrice = lineItem.TotalPrice;
//depreciated				if (lineItem.UnitPrice != null) {
//depreciated					totalPrice = lineItem.Quantity * lineItem.UnitPrice;
//depreciated				}
//depreciated				System.debug('Total Price = '+totalPrice+' = '+lineItem.Quantity+'*'+lineItem.UnitPrice);

//depreciated				Date closeDate = lineItem.OpportunityCloseDate__c;
//depreciated				if(closeDate == null) {
//depreciated					closeDate = testingCloseDate;
//depreciated					if(closeDate == null) {
//depreciated						lineItem.addError('No close date for Opportunity '+lineItem.OpportunityId);
//depreciated						newList.remove(i);
//depreciated						continue;
//depreciated					}
//depreciated				}
//depreciated				Integer closeDateNormalized = Math.floor(1460.0*refDate.daysBetween(closeDate)/1461.0).intValue();

//depreciated				Integer actualStartNormalized = Math.floor(1460.0*refDate.daysBetween(lineItem.ActualStartDate__c)/1461.0).intValue();
//depreciated				Integer actualEndNormalized = Math.floor(1460.0*refDate.daysBetween(lineItem.ActualEndDate__c)/1461.0).intValue();
//depreciated				Integer actualTerm = 1+actualEndNormalized-actualStartNormalized;
//depreciated				if(actualTerm <= 0) {
//depreciated					lineItem.addError('ActualStartDate must be before the ActualEndDate.');
//depreciated					newList.remove(i);
//depreciated					continue;
//depreciated				}

//depreciated				Double perDiem = totalPrice / actualTerm;
//depreciated				Double yearlyPrice = perDiem * 365.0;
//depreciated				Decimal remainingAmount = totalPrice;

//depreciated				List<Decimal> amounts = new List<Double>();
//depreciated				Integer sybStart = actualStartNormalized;
//depreciated				Integer sybNextStart = closeDateNormalized+366;
//depreciated				// keep looping until the next year starts after the actual start date
//depreciated				for(;sybNextStart <= actualStartNormalized;sybNextStart += 365) {
//depreciated					amounts.add(0.0);
//depreciated				}
//depreciated				// find out if we have less than a full year
//depreciated				if(sybNextStart > actualEndNormalized ) {
//depreciated					sybNextStart = actualEndNormalized+1;
//depreciated				}
//depreciated				Decimal roundoff = 0.000;
//depreciated				// use the perDiem to compute the amount
//depreciated				if(sybNextStart > sybStart) {
//depreciated					Decimal amount0 = Decimal.valueOf(perDiem * (sybNextStart - sybStart));
//depreciated					Decimal amount = amount0.divide(1,2,System.RoundingMode.HALF_EVEN);
//depreciated					roundoff = amount0 - amount;
//depreciated					amounts.add(amount);
//depreciated					remainingAmount -= amount;
//depreciated				}
//depreciated				// the remaining years are just the lesser of the yearly amount of the remaining amount
//depreciated				while(Math.abs(remainingAmount) > 0.005 && amounts.size() < 5) {
//depreciated					Decimal amount0 = ((yearlyPrice >= 0.0) ?
//depreciated						Math.min(remainingAmount,yearlyPrice+roundoff) :
//depreciated						Math.max(remainingAmount,yearlyPrice+roundoff));
//depreciated					Decimal amount = amount0.divide(1,2,System.RoundingMode.HALF_EVEN);
//depreciated					roundoff = amount0-amount;
//depreciated					remainingAmount -= amount;
//depreciated					amounts.add(amount);
//depreciated				}
//depreciated				// this is just to make sure we don't have an index out of bounds error
//depreciated				amounts.addAll(new List<Decimal>{0.00,0.00,0.00,0.00,0.00,0.00});
/* Don't set, this field is for quoting tools only
//depreciated				Decimal yearlySalesPrice = yearlyPrice;
//depreciated				if(lineItem.Quantity != 0) {
//depreciated					yearlySalesPrice = yearlySalesPrice.divide(lineItem.Quantity,2,System.RoundingMode.HALF_EVEN);
//depreciated				}
//depreciated				if(yearlySalesPrice != lineItem.YearlySalesPrice__c) {
//depreciated					lineItem.YearlySalesPrice__c = yearlySalesPrice;
//depreciated				}
*/
//depreciated				lineItem.Year1Amount__c = amounts[0];
//depreciated				lineItem.Year2Amount__c = amounts[1];
//depreciated				lineItem.Year3Amount__c = amounts[2];
//depreciated				lineItem.Year4Amount__c = amounts[3];
//depreciated				lineItem.Year5Amount__c = amounts[4];
//depreciated				lineItem.Year6Amount__c = (totalPrice-amounts[0]-amounts[1]-amounts[2]-amounts[3]-amounts[4]-amounts[5]).divide(1,2,System.RoundingMode.HALF_EVEN);
//depreciated			}
//depreciated		}
//depreciated	}

//depreciated	/**
//depreciated	 * This method is called from the OpportunityLineItem_Before trigger to invoke all the methods
//depreciated	 * of this class, to obsolete the need for individual before triggers.  The primary
//depreciated	 * reason to place all the triggers in a class is so we control the order in which
//depreciated	 * the triggers are invoked.
//depreciated	 *
//depreciated	 * @param xoldMap the immutable map of previous OpportunityLineItem objects as in Trigger.oldMap.
//depreciated	 * @param xnewList the list of new OpportunityLineItem objects as in Trigger.new
//depreciated	 */
//depreciated	public static void processTrigger(Map<Id,OpportunityLineItem> xoldMap,List<OpportunityLineItem> xnewList) {
//depreciated		final OpportunityLineItemTriggerBefore beforeTrigger = new OpportunityLineItemTriggerBefore(xoldMap,xnewList);
//depreciated		if(AbstractTrigger.isActive(OPP_LOCK_SETTING,true)) {
//depreciated			beforeTrigger.oppLock();
//depreciated		}
//depreciated		if(AbstractTrigger.isActive(CALC_ACTUAL_SETTING,true)) {
//depreciated			beforeTrigger.calculateActual();
//depreciated		}
//depreciated		if(AbstractTrigger.isActive(CALC_SCHEDULE_SETTING,true)) {
//depreciated			beforeTrigger.calculateSchedule();
//depreciated		}
//depreciated	}
//depreciated }