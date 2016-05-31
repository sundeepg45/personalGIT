/**
 * This class replaces all after insert and after update OpportunityLineItem triggers.  The
 * processTrigger method is invoked by the OpportunityLineItem_After trigger and in turn invokes
 * all the methods of this class.  This gives us a way to control the order in
 * which the code logic is invoked, as well as allowing other class features such
 * as shared data, constant values, and regorious test coverage.
 * <p>
 * The Trigger object should never be directly referenced inside this class, as
 * that would make it impossible to substituting values inside test methods.
 * </p>
 *
 * @version 2016-01-05
 * @author Bill Riemers <briemers@redhat.com>
 * 2016-01-05 - Reverted create event records
 * 2015-10-28 - Created
 */
public without sharing class OpportunityLineItemTriggerAfter2 extends AbstractTrigger {
	/** BooleanSetting__c key to enable the createEventRecords method. */
	public static final String CREATE_EVENT_RECORDS_SETTING = 'LineItem_After.CreateEventRecords';
	/** BooleanSetting__c key to enable deactivateQuotes method. */
	public static final String DEACTIVATE_QUOTES_SETTING = 'LineItem_After.deactivateQuote';

	private final Map<Id,OpportunityLineItem> oldMap = new Map<Id,OpportunityLineItem>();
	private final Map<Id,OpportunityLineItem> newMap = new Map<Id,OpportunityLineItem>();


//	// note: isUndelete == true => isInsert == true
	private Boolean isUndelete;


	/**
	 * Typical TriggerBefore type constructor
	 *
	 * @param xoldMap the mapping of old values
	 * @param xnewMap the mapping of new values
	 */
	public OpportunityLineItemTriggerAfter2(Map<Id,OpportunityLineItem> xoldMap,Map<Id,OpportunityLineItem> xnewMap, Boolean isUndelete) {
		super(xoldMap,null,xnewMap);
		this.isUndelete = isUndelete;
		if(xoldMap != null) {
			oldMap.putAll(xoldMap);
		}
		if(xnewMap != null) {
			newMap.putAll(xnewMap);
		}
	}

	public static Map<String,String> deactivateQuotesOnChangeMap {
		get {
			if(deactivateQuotesOnChangeMap == null) {
				deactivateQuotesOnChangeMap = new Map<String,String>();
				for(Schema.FieldSetMember fsm : Schema.SObjectType.OpportunityLineItem.fieldSets.DeactivateQuotesOnChange.getFields()) {
					deactivateQuotesOnChangeMap.put(fsm.getFieldPath(),fsm.getLabel());
				}
			}
			return deactivateQuotesOnChangeMap;
		}
		set;
	}

	/**
	 * Find out if this quotes should be deactivated due to a field change.
	 */
	public static Boolean hasDeactivateQuotesChange(OpportunityLineItem oldLineItem, OpportunityLineItem newLineItem) {
		Boolean retval = false;
		if(oldLineItem != null && newLineItem != null) {
			System.debug('OpportunityId='+newLineItem.OpportunityId+',OpportunityLineItemId='+newLineItem.Id);
			for(String fieldPath : deactivateQuotesOnChangeMap.keySet()) {
				try {
					String label = deactivateQuotesOnChangeMap.get(fieldPath);
					System.debug(label+' is '+newLineItem.get(fieldPath));
					retval = (oldLineItem.get(fieldPath) != newLineItem.get(fieldPath));
					if(retval) {
						System.debug(label+' was '+oldLineItem.get(fieldPath));
						break;
					}
				}
				catch(Exception ex) {}
			}
		}
		return retval;
	}

	//Method call to deactivate Quotes on Update event
	public void deactivateQuotes(){
		if (isUpdate) {
			Set<Id> oppIds = new Set<Id>();
			//Iterating on list of fields
			for(OpportunityLineItem lineItem : newMap.values()) {
				if(! oppIds.contains(lineItem.OpportunityId)) {
					if(hasDeactivateQuotesChange(oldMap.get(lineItem.Id),lineItem)) {
						oppIds.add(lineItem.OpportunityId);
					}
				}
			}
			//if value has changed, deactivate quote
			if (! oppIds.isEmpty()) {
				//Fetch list of BigMachine Quotes for an opportunity
				List<BigMachines__Quote__c> bmQuotes = [
					select Id
					from BigMachines__Quote__c
					where BigMachines__Opportunity__c in :oppIds
						and BigMachines__Is_Primary__c != false];
				if (!bmQuotes.isEmpty()) {
					for(BigMachines__Quote__c bmQuote : bmQuotes) {
						bmQuote.BigMachines__Is_Primary__c = false;
					}
					Database.update(bmQuotes,false);
				}
			}
		}
	}

	public void createEventRecords() {
//US80608(rollback DE7583)		if(Opportunity_Split_Batchable2.scheduledApex == null) {
			Set<Id> setParentOppIds = new Set<Id>();

			//collect all the parent opportunity ids
			if(! isDelete){
				for(OpportunityLineItem oppLineItmInst : newMap.values()){
					
					setParentOppIds.add(oppLineItmInst.OpportunityId);
				}
			}else {
				for(OpportunityLineItem oppLineItmInst : oldMap.values()){
					
					setParentOppIds.add(oppLineItmInst.OpportunityId);
				}
			}

			//fetch all the event records, if already present, for the corresponding parent opportunity
			List<Event__c> listEventRecs = new List<Event__c>([SELECT Opportunity__c FROM Event__c WHERE Opportunity__c IN: setParentOppIds AND Processed__c = FALSE]);

			Map<Id, Event__c> mapParentOppId_Event = new Map<Id, Event__c>();
			//create map opportunity id and corresponding event record 
			for(Event__c eventInst : listEventRecs){
				mapParentOppId_Event.put(eventInst.Opportunity__c, eventInst);
			}

			setParentOppIds = new Set<Id>();
			//collect all the opportunity ids for which there is no record present in Event object 
			if(! isDelete){
				for(OpportunityLineItem oppLineItmInst : newMap.values()){
					if(mapParentOppId_Event.get(oppLineItmInst.OpportunityId) == NULL) {
						setParentOppIds.add(oppLineItmInst.OpportunityId);
					}
				}
			}else {
				for(OpportunityLineItem oppLineItmInst : oldMap.values()){
					if(mapParentOppId_Event.get(oppLineItmInst.OpportunityId) == NULL) {
						setParentOppIds.add(oppLineItmInst.OpportunityId);
					}
				}
			}

			List<Event__c> listNewEventRecs = new List<Event__c>();
			//create new records in Event
			for(Id parentOppId : setParentOppIds){
				Event__c newEventInst = new Event__c();
				newEventInst.Opportunity__c = parentOppId;
				listNewEventRecs.add(newEventInst);
			}
			Database.Insert(listNewEventRecs, FALSE);
//US80608(rollback DE7583)		}
//US80608(rollback DE7583)		else {
//US80608(rollback DE7583)			Set<Id> oppIds = new Set<Id>();
//US80608(rollback DE7583)			Map<Id,OpportunityLineItem> lineItemMap = oldMap.clone();
//US80608(rollback DE7583)			lineItemMap.putAll(newMap);
//US80608(rollback DE7583)			for(OpportunityLineItem lineItem : lineItemMap.values()) {
//US80608(rollback DE7583)				oppIds.add(lineItem.OpportunityId);
//US80608(rollback DE7583)			}
//US80608(rollback DE7583)			OpportunityTriggerAfter2.createEventRecords(oppIds,false);
//US80608(rollback DE7583)		}
	}

	/**
	 * This method is called to invoke all the trigger methods.
	 *
	 * @param xoldMap normally assigned from Trigger.oldMap
	 * @param xnewMap normally assigned from Trigger.newMap
	 * @param isUndelete true if being restored from the recycle bin
	 */
	public static void processTrigger(Map<Id,OpportunityLineItem> xoldMap,Map<Id,OpportunityLineItem> xnewMap ,Boolean isUndelete) {
		final OpportunityLineItemTriggerAfter2 afterTrigger = new OpportunityLineItemTriggerAfter2(xoldMap,xnewMap, isUndelete);
		try {
			if(AbstractTrigger.isActive(DEACTIVATE_QUOTES_SETTING,true)) {
				afterTrigger.deactivateQuotes();
			}
			if(AbstractTrigger.isActive(CREATE_EVENT_RECORDS_SETTING,true)) {
				afterTrigger.createEventRecords();
			}
		}
		finally {
			AbstractTrigger.processTriggerComplete();
		}
	}
}