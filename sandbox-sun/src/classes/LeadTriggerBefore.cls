/**
 * This class replaces all before insert and before update lead triggers.  The
 * processTrigger method is invoked by the Lead_Before trigger and in turn invokes
 * all the processTrigger methods of the subclasses.  This gives us a way to control 
 * the order in which the code logic is invoked, as well as allowing other class features 
 * such as shared data, constant values, and complete test coverage.
 * <p>
 * The Trigger object should never be directly referenced inside this class or it's subclasses
 * as that would make it impossible to substituting values inside test methods.
 * </p>
 *
 * @author Bill C Riemers <briemers@redhat.com>
 * @version 2012-07-19
 * 2012-07-19 - update to api version 24 and extending the abstract trigger class
 * 2012-05-15 - Added LeadTriggerBeforeSFA class
 * 2012-03-05 - Refactor to create sub classes.
 * 2011-12-08 - Modified insertLead method to by-pass non-GLM leads
 * Bryan Bosely <bbosely@redhat.com>
 * 2011-11-?? - Added insertLead trigger method
 * 2011-09-17 - Added method to determine lead sub-region
 */
public abstract without sharing class LeadTriggerBefore  extends AbstractTrigger {
	/** BooleanSetting__c key to enable the leadRouting trigger method. */
	public static final String LEAD_ROUTING_SETTING = 'Lead_Before.leadRouting';

	/** Normally populated as Trigger.oldMap */
	protected final Map<Id,Lead> oldMap = new Map<Id,Lead>();
	/** Normally populated as Trigger.new */
	protected final List<Lead> newList = new List<Lead>();
	/** Used to keep track of errors while debugging */
	public Boolean hasErrors = false;

	public static Map<String,Boolean> booleanSettingMap {
		get {
			if(booleanSettingMap == null) {
				booleanSettingMap = AbstractTrigger.booleanSettingMap;
				// this is so we do not need to update the Partner trigger class
				for(String key : LeadTriggerBeforePartner.booleanSettingKeys) {
					AbstractTrigger.isActive(key,true);
				}
			}
			return booleanSettingMap;
		}
	}

	/**
	 * This constructor is normally called via the child super methods.
	 */
	public LeadTriggerBefore(Map<Id,Lead> xoldMap,List<Lead> xnewList) {
		super(xoldMap,xnewList,null);
		if(xoldMap != null) {
			oldMap.putAll(xoldMap);
		}
		if(xnewList != null) {
			newList.addAll(xnewList);
		}
	}

	static Map<Id,User> staticUserMap = new Map<Id,User>();

	/**
	 * Create a newMap as needed.
	 */
	protected Map<Id,Lead> newMap {
		get {
			if(newMap == null) {
				try {
					newMap = new Map<Id,Lead>(newList);
				}
				catch(Exception e) {
					// this only happens in test code where lead.Id, and on delete
					newMap = new Map<Id,Lead>();
					for(Lead lead : newList) {
						newMap.put(lead.Id,lead);
					}
				}
			}
			return newMap;
		}
		set;
	}

	/**
	 * This method is called from the Lead_Before trigger to invoke all the methods
	 * of this class, to obsolete the need for individual before triggers.  The primary
	 * reason to place all the triggers in a class is so we control the order in which
	 * the triggers are invoked.
	 *
	 * @param xoldMap the immutable map of previous Lead objects as in Trigger.oldMap.
	 * @param xnewList the list of new Lead objects as in Trigger.new
	 */
	public static void processTrigger(Map<Id,Lead> xoldMap,List<Lead> xnewList) {
		if(AbstractTrigger.isActive(LEAD_ROUTING_SETTING,true) && xnewList != null) {
			new LeadAssignment().assignLead(xnewList,(xoldMap == null));
		}
		LeadTriggerBeforePartner.processTrigger(xoldMap,xnewList);
		LeadTriggerBeforeRegion.processTrigger(xoldMap,xnewList);
		LeadTriggerBeforeGLM.processTrigger(xoldMap,xnewList);
		LeadTriggerBeforeSFA.processTrigger(xoldMap,xnewList);
		AbstractTrigger.processTriggerComplete();
	}
}