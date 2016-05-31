/**
 * This class replaces all before insert and before update and before delete
 * event triggers.  The processTrigger method is invoked by the Event_Before trigger 
 * and in turn invokes all the methods of this class.  This gives us a way to control 
 * the order in which the code logic is invoked, as well as allowing other class 
 * features such as shared data, constant values, and rigorous test coverage.
 * <p>
 * The Trigger object should never be directly referenced inside this class, as
 * that would make it impossible to substituting values inside test methods.
 * </p>
 * To update the close date on pre-existing events run:
 * <pre>
 * Database.update([
 *  select Id 
 *  from Event 
 *  where IsRecurrence <> true 
 *      and StartDateTime <> null 
 *      and WhoId <> null 
 *      and ClosedDate__c = null
 *  limit 3000 ],false);
 * </pre>
 * 
 * @author Bill C Riemers <briemers@redhat.com>
 * @version 2012-06-02
 *
 * 2011-09-06 - created
 * 2012-06-02 - Updated for SMR
 */
public without sharing class EventTriggerBefore extends AbstractTrigger {
	/** BooleanSetting__c key to enable the closedDate trigger method. */
	public static final String CLOSED_DATE_SETTING = 'Event_Before.closedDate';
	/** BooleanSetting__c key to enable the assignLegacy trigger method. */
	public static final String ASSIGN_LEGACY_SETTING = 'Event_Before.assignLegacy';

	private final Map<Id,Event> oldMap = new Map<Id,Event>();
	private final List<Event> newList = new List<Event>();

	/**
	 * This is a typical TriggerBefore type constructor.
	 *
	 * @param oldMap typically assigned from Trigger.oldMap
	 * @param newList typically assigned from Trigger.newList
	 */
	public EventTriggerBefore(Map<Id,Event> xoldMap,List<Event> xnewList) {
		super(xoldMap,xnewList,null);
		if(xoldMap != null) {
			oldMap.putAll(xoldMap);
		}
		if(xnewList != null) {
			newList.addAll(xnewList);
		}
	}

	/**
	 * Method to set the ClosedDate__c field when the activity is closed.
	 */
	public void closedDate() {
		if(newList != null) {
			for(Event ev : newList) {
				if(ev.WhoId != null  && ev.ActivityDateTime != null) {
					ev.Due_Date_Time__c = ev.ClosedDate__c = ev.ActivityDateTime;
				}
			}
		}
	}

	/**
	 * Trigger method to assign Legacy_Profile__c and Legacy_Role__c values.
	 */
	public override void assignLegacy() {
		Set<Id> ownerIds = new Set<Id>();
		Map<Id,User> ownerMap = new Map<Id,User>{
			null=>new User(Legacy_Profile__c=null,Legacy_Role__c=null) };
		for(Event t : newList) {
			Id ownerId = null;
			if((''+t.OwnerId).startsWith('005')) {
				ownerId = t.OwnerId;
			}
			if(t.Owner__c != ownerId) {
				t.Owner__c = ownerId;
				ownerIds.add(ownerId);
			}
			else {
				ownerMap.put(
					t.Owner__c,
					new User(
						Legacy_Profile__c=t.Legacy_Profile__c,
						Legacy_Role__c=t.Legacy_Role__c));
			}
		}
		ownerIds.removeAll(ownerMap.keySet());
		if(! ownerIds.isEmpty()) {
			ownerMap.putAll(
				new Map<Id,User>([
					select
						Legacy_Profile__c,
						Legacy_Role__c
					from User
					where Id in :ownerIds]) );
			for(Event t : newList) {
				User u = ownerMap.get(t.Owner__c);
				if(u != null) {
					if(u.Legacy_Profile__c != t.Legacy_Profile__c) {
						t.Legacy_Profile__c = u.Legacy_Profile__c;
					}
					if(u.Legacy_Role__c != t.Legacy_Role__c) {
						t.Legacy_Role__c = u.Legacy_Role__c;
					}
				}
			}
		}
	}

	/**
	 * This method is called from the Event_Before trigger to invoke all the methods
	 * of this class, to obsolete the need for individual before triggers.  The primary
	 * reason to place all the triggers in a class is so we control the order in which
	 * the triggers are invoked.
	 *
	 * @param xoldMap the immutable map of previous Event objects as in Trigger.oldMap.
	 * @param xnewList the list of new Event objects as in Trigger.new
	 */
	public static void processTrigger(Map<Id,Event> xoldMap,List<Event> xnewList) {
		final EventTriggerBefore beforeTrigger = new EventTriggerBefore(xoldMap,xnewList);
		if(AbstractTrigger.isActive(CLOSED_DATE_SETTING,true)) {
			beforeTrigger.closedDate();
		}
		if(AbstractTrigger.isActive(ASSIGN_LEGACY_SETTING,true)) {
			beforeTrigger.assignLegacy();
		}
	}
}