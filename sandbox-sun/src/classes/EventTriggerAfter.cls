/**
 * This class replaces all after insert and after update task triggers.  The
 * processTrigger method is invoked by the Event_After trigger and in turn invokes
 * all the methods of this class.  This gives us a way to control the order in
 * which the code logic is invoked, as well as allowing other class features such
 * as shared data, constant values, and rigorious test coverage.
 * <p>
 * The Trigger object should never be directly referenced inside this class, as
 * that would make it impossible to substituting values inside test methods.
 * </p>
 *
 * @author Bill C Riemers <briemers@redhat.com>
 * @version 2011-09-22
 */
public without sharing class EventTriggerAfter {
	/** BooleanSetting__c key to enable the closedDate trigger method. */
	public static final String CLOSED_DATE_SETTING = 'Event_After.closedDate';
	/** BooleanSetting__c key to enable the updateLeads trigger method. */
	public static final String UPDATE_LEADS_SETTING = 'Event_After.updateLeads';
	/** Map of all the BooleanSetting__c values used. */
	public static final Map<String,Boolean> booleanSettingMap = new Map<String,Boolean> {
		UPDATE_LEADS_SETTING => getBooleanSettingValue(UPDATE_LEADS_SETTING),
		CLOSED_DATE_SETTING => getBooleanSettingValue(CLOSED_DATE_SETTING) };
	/** This is a set of Id's we are recursively updating.  We use this to set to avoid infinite recursion. */
	public static Set<Id> recursiveIds = new Set<Id>();

	/** Normally populated as a copy of Trigger.oldMap */
	private final Map<Id,Event> oldMap;
	/** Normally populated as Trigger.new */
	private final Map<Id,Event> newMap = new Map<Id,Event>();
	/** Logically equivalent to Trigger.IsInsert */
	private final Boolean isInsert;
	/** Logically equivalent to Trigger.IsUpdate */
	private final Boolean isUpdate;
	/** Logically equivalent to Trigger.IsDelete */
	private final Boolean isDelete;
	/** Used to keep track of errors while debugging */
	public Boolean hasErrors = false;

	/**
	 * This constructor is normally called from the processTrigger method and
	 * test methods.
	 */
	public EventTriggerAfter(Map<Id,Event> xoldMap,Map<Id,Event> xnewMap) {
		this.oldMap = xoldMap;
		isDelete = (xnewMap == null)||xnewMap.isEmpty();
		isInsert = (xoldMap == null)||xoldMap.isEmpty();
		isUpdate = !(isInsert||isDelete);
		if(! isDelete) {
			this.newMap.putAll(xnewMap);
			// remove all recursive id's
			this.newMap.keySet().removeAll(recursiveIds);
		}
	}

	/**
	 * Query a Boolean value from BooleanSetting__c constants.
	 */
	public static Boolean getBooleanSettingValue(String key) {
		Boolean retval = null;
		BooleanSetting__c bs = BooleanSetting__c.getInstance(key);
		if(bs != null) {
			retval = bs.Value__c;
		}
		return retval;
	}

	/**
	 * This trigger method will attempt to update Leads when there respective tasks
	 * are updated.
	 */
	public void updateLeads() {
		Map<Id,Event> eventMap = newMap;
		if(isDelete) {
			eventMap = oldMap;
		}
		Map<Id,Lead> leadMap = new Map<Id,Lead>();
		for(Event e : eventMap.values()) {
			if((''+e.WhoId).startsWith('00Q')) {
				leadMap.put(e.WhoId,new Lead(Id=e.WhoId));
			}
		}
		if(! leadMap.isEmpty()) {
			Database.update(leadMap.values(),false);
		}
	}

	/**
	 * It seems sometimes StartDateTime is null on create.  We are still not clear on how this happens
	 * but this trigger method is intended to resolve that problem.
	 */
	public void closedDate() {
		Map<Id,Event> eventMap = new Map<Id,Event>();
		for(Event ev : newMap.values()) {
			if(ev.WhoId != null && ev.ActivityDateTime != null && ev.IsRecurrence != true) {
				if(ev.ClosedDate__c == null || ev.Due_Date_Time__c == null) {
					Event ev2 = ev.clone(true);
					ev2.ClosedDate__c = ev.ActivityDateTime;
					ev2.Due_Date_Time__c = ev.ActivityDateTime;
					eventMap.put(ev2.Id,ev2);
				}
			}
		}
		if(! eventMap.isEmpty()) {
			recursiveIds.addAll(eventMap.keySet());
			try {
				List<Event> events = eventMap.values();
				for(Database.SaveResult sr : Database.update(events,false)) {
					Event ev = events.remove(0);
					System.debug('Update complete: '+ev);
					for(Database.Error e : sr.getErrors()) {
						newMap.get(ev.Id).addError('Failed to set Closed Date and Due Date Time: '+e);
					}
				}
			}
			finally {
				recursiveIds.removeAll(eventMap.keySet());
			}
		}
	}

	/**
	 * This method is called from the Event_After trigger to invoke all the methods
	 * of this class, to obsolete the need for individual after triggers.  The primary
	 * reason to place all the triggers in a class is so we control the order in which
	 * the triggers are invoked.
	 *
	 * @param xoldMap the immutable map of previous Event objects as in Trigger.oldMap.
	 * @param xnewMap the immutable map of new Event objects as in Trigger.newMap
	 */
	public static void processTrigger(Map<Id,Event> xoldMap,Map<Id,Event> xnewMap) {
		final EventTriggerAfter afterTrigger = new EventTriggerAfter(xoldMap,xnewMap);
		if(booleanSettingMap.get(CLOSED_DATE_SETTING) != false) {
			afterTrigger.closedDate();
		}
		if(booleanSettingMap.get(UPDATE_LEADS_SETTING) != false) {
			afterTrigger.updateLeads();
		}
	}

}