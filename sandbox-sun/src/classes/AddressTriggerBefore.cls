/**
 * This class replaces all before insert and before update address triggers.  The
 * processTrigger method is invoked by the Address_Before trigger and in turn invokes
 * all the methods of this class.  This gives us a way to control the order in
 * which the code logic is invoked, as well as allowing other class features such
 * as shared data, constant values, and regorious test coverage.
 * <p>
 * The Trigger object should never be directly referenced inside this class, as
 * that would make it impossible to substituting values inside test methods.
 * </p>
 *
 * @version 2015-11-10
 * @author Bill Riemers <briemers@redhat.com>
 * 2015-11-16 - Update to clear the isDuplicate flag when we should recheck
 * 2015-11-10 - Use a Merged status rather than Inactive for duplicate addresses
 * 2015-11-05 - Added changedCDHPartySiteNumber method
 * 2015-09-30 - Added support for the reparented flag
 * 2015-08-27 - Created
 */
public without sharing class AddressTriggerBefore extends AbstractTrigger {
	/** BooleanSetting__c key to enable inactivateDuplicates method. */
	public static final String INACTIVATE_DUPLICATES_SETTING = 'Address_Before.inactivateDuplicates';
	/** BooleanSetting__c key to enable changedCDHPartySiteNumbers method. */
	public static final String CHANGED_SITE_SETTING = 'Address_Before.changedSite';
	/** BooleanSetting__c key to enable updateCDHPartySiteNumbers method. */
	public static final String UPDATE_SITE_SETTING = 'Address_Before.updateSite';

	private final Map<Id,Address__c> oldMap = new Map<Id,Address__c>();
	private final List<Address__c> newList = new List<Address__c>();

	/**
	 * Typical TriggerBefore type constructor
	 *
	 * @param xoldMap the mapping of old values
	 * @param xnewList the mapping of new values
	 */
	public AddressTriggerBefore(Map<Id,Address__c> xoldMap,List<Address__c> xnewList) {
		super(xoldMap,xnewList,null);
		if(xoldMap != null) {
			oldMap.putAll(xoldMap);
		}
		if(xnewList != null) {
			newList.addAll(xnewList);
		}
	}

	/**
	 * Called to set the reparented flag and store the cdh party site number previous value.
	 */
	public void changedCDHPartySiteNumbers() {
		for(Address__c a : newList) {
			String prev = null;
			Address__c o = oldMap.get(a.Id);
			if(a.CDH_Party_Site_Number__c != null) {
				prev = a.CDH_Party_Site_Number_Previous__c;
				if(o != null && o.CDH_Party_Site_Number__c != null && a.CDH_Party_Site_Number__c != o.CDH_Party_Site_Number__c) {
					prev = o.CDH_Party_Site_Number__c;
					setReparented(a,true);
				}
			}
			if(prev == null 
				&& (a.MasterRecord__c != null 
					|| (o != null && 
						(o.MasterRecord__c != null
							|| (o.Status__c == 'Inactive' && o.IsDuplicate__c == true) )))) 
			{
				prev = '-';
			}
			if(prev != a.CDH_Party_Site_Number_Previous__c) {
				a.CDH_Party_Site_Number_Previous__c = prev;
				if(prev != null && prev != '-' && a.Reparented__c != true) {
					a.Reparented__c = true;
				}
			}
		}
	}

	// setting a true value will result in a duplication check
	void setReparented(Address__c address,Boolean value) {
		if(address != null) {
			if(value == true && ! isInsert) {
				AddressTriggerAfter.reparentedAddressMap.put(address.Id,address.Sales_Account__c);
			}
			value = (isInsert && value == true);
			if(address.Reparented__c != value) {
				address.Reparented__c = value;
			}
		}
	}

	/**
	 * Inactivate duplicates, and toggle the reparented and is duplicate flags.
	 */
	public void inactivateDuplicates() {
		for(Address__c address : newList) {
			Address__c old = oldMap.get(address.Id);
			// the duplicate flag may be cleared only by clearing the master record and changing the status
			Boolean isDuplicate = ( address.IsDuplicate__c == true && (old == null || old.IsDuplicate__c != true))
				|| address.MasterRecord__c != null
				|| address.Status__c == 'Merged';
			setReparented(address,
				(address.IsDuplicate__c != isDuplicate)
					|| ((address.Reparented__c == true) && ! isDuplicate)
					|| (old != null && old.Sales_Account__c != address.Sales_Account__c) );
			if(address.IsDuplicate__c != isDuplicate) {
				address.IsDuplicate__c = isDuplicate;
			}
			if(isDuplicate && address.Address_External_Id__c != null) {
				address.Address_External_Id__c = null;
			}
		}
	}

	/**
	 * Examine all the previous merges and update cdh party site numbers respectively.
	 */
	public void updateCDHPartySiteNumbers() {
		// now lets check if there is already another existing record that defines this
		// as a merge...
		Map<String,String> mergedSitesMap = new Map<String,String>();
		Set<String> sites = new Set<String>();
		for(Address__c a : newList) {
			String siteNumber = a.CDH_Party_Site_Number__c;
			if(siteNumber != null && (a.CDH_Party_Site_Number_Previous__c != null || a.MasterRecord__c == null)) {
				sites.add(siteNumber);
				if(a.CDH_Party_Site_Number_Previous__c != null && a.CDH_Party_Site_Number_Previous__c != '-') {
					mergedSitesMap.put(a.CDH_Party_Site_Number_Previous__c,siteNumber);
				}
			}
		}
		sites.removeAll(mergedSitesMap.keySet());
		if(!sites.isEmpty()) {
			for(AggregateResult ar : [
				select CDH_Party_Site_Number_Previous__c previous,
					max(CDH_Party_Site_Number__c) current
				from Address__c
				where CDH_Party_Site_Number_Previous__c = :sites
					and CDH_Party_Site_Number__c not in :sites
					and CDH_Party_Site_Number__c != null
					and Id not in :oldMap.keySet()
				group by CDH_Party_Site_Number_Previous__c
				ALL ROWS ] )
			{
				mergedSitesMap.put((String)ar.get('previous'),(String)ar.get('current'));
			}
		}
		// resolve reference chains the best we can without recursive queries
		for(String key : mergedSitesMap.keySet()) {
			String value1 = key;
			String value2 = mergedSitesMap.get(key);
			while ( value2 != null && value2 != value1 ) {
				mergedSitesMap.put(key,value2);
				value1 = value2;
				value2 = mergedSitesMap.get(value1);
			}
		}
		for(Address__c address : newList) {
			String cdhPartySiteNumber = mergedSitesMap.get(address.CDH_Party_Site_Number__c);
			if(address.Status__c == 'Merged' && address.IsDuplicate__c != true) {
				address.IsDuplicate__c = true;
			}
			if(cdhPartySiteNumber != null && cdhPartySiteNumber != address.CDH_Party_Site_Number__c) {
				address.CDH_Party_Site_Number_Previous__c = address.CDH_Party_Site_Number__c;
				address.CDH_Party_Site_Number__c = cdhPartySiteNumber;
				setReparented(address,true);
			}
		}
	}

	/**
	 * This method is called to invoke all the trigger methods.
	 *
	 * @param xoldMap normally assigned from Trigger.oldMap
	 * @param xnewList normally assigned from Trigger.newList
	 */
	public static void processTrigger(Map<Id,Address__c> xoldMap,List<Address__c> xnewList) {
		// clean-up on reentry...
		if(ThreadLock.lock(AddressTriggerAfter.RECURSION_LOCK)) {
			try {
				AddressTriggerAfter.reparentedAddressMap.clear();
			}
			finally {
				ThreadLock.unlock(AddressTriggerAfter.RECURSION_LOCK);
			}
		}
		final AddressTriggerBefore beforeTrigger = new AddressTriggerBefore(xoldMap,xnewList);
		if(AbstractTrigger.isActive(CHANGED_SITE_SETTING,true)) {
			beforeTrigger.changedCDHPartySiteNumbers();
		}
		if(AbstractTrigger.isActive(INACTIVATE_DUPLICATES_SETTING,true)) {
			beforeTrigger.inactivateDuplicates();
		}
		if(AbstractTrigger.isActive(UPDATE_SITE_SETTING,true)) {
			beforeTrigger.updateCDHPartySiteNumbers();
		}
		AbstractTrigger.processTriggerComplete();
	}
}