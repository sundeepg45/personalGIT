/**
 * This class replaces all after insert and after update Address__c triggers.  The
 * processTrigger method is invoked by the Address_After trigger and in turn invokes
 * all the methods of this class.  This gives us a way to control the order in
 * which the code logic is invoked, as well as allowing other class features such
 * as shared data, constant values, and regorious test coverage.
 * <p>
 * The Trigger object should never be directly referenced inside this class, as
 * that would make it impossible to substituting values inside test methods.
 * </p>
 *
 * @version 2015-12-04
 * @author Bill Riemers <briemers@redhat.com>
 * 2015-12-07 - Updated to allow multiple address outbound per sales account
 * 2015-12-04 - DE9500 - We need to send messages for partners when the address count is being updated
 * 2015-11-18 - Remove the deletePrevious method as it seems broken
 * 2015-11-12 - Refactored Address_Trigger_Handler methods into this class.
 * 2015-11-10 - Used Merged status for duplicates
 * 2015-11-09 - Added a method to update duplicates
 * 2015-11-06 - Added methods to auto-delete any address created with an obsolete cdh party site number and to update the external ids
 * 2015-10-01 - Created
 */
public without sharing class AddressTriggerAfter extends AbstractTrigger {
	/** BooleanSetting__c key to call the correct address external ids method. */
	public static final String CORRECT_EXTERNAL_IDS_SETTING = 'Address_After.correctExternalIds';
	/** BooleanSetting__c key to enable updateDuplicates method. */
	public static final String UPDATE_DUPLICATES_SETTING = 'Address_After.updateDuplicates';
	/** BooleanSetting__c key to enable logDuplicates method. */
	public static final String LOG_DUPLICATES_SETTING = 'Address_After.logDuplicates';
	/** BooleanSetting__c key to enable outbountMessages method. */
	public static final String OUTBOUND_MESSAGES_SETTING = 'Address_After.outboundMessages';
	/** BooleanSetting__c key to enable setIdentifying method. */
	public static final String SET_IDENTIFYING_SETTING = 'Address_After.setIdentifying';
	/** Lock key to avoid recursion. */
	public static final String RECURSION_LOCK = 'Address_After.lock';

	/** Used to keep track of the sales account ids for address ids of reparented records. */
	public static Map<Id,Id> reparentedAddressMap = new Map<Id,Id>();

	private final Map<Id,Address__c> oldMap = new Map<Id,Address__c>();
	private final Map<Id,Address__c> newMap = new Map<Id,Address__c>();


//	// note: isUndelete == true => isInsert == true
	private Boolean isUndelete;

	/**
	 * Typical TriggerBefore type constructor
	 *
	 * @param xoldMap the mapping of old values
	 * @param xnewMap the mapping of new values
	 */
	public AddressTriggerAfter(Map<Id,Address__c> xoldMap,Map<Id,Address__c> xnewMap, Boolean isUndelete) {
		super(xoldMap,null,xnewMap);
		this.isUndelete = isUndelete;
		if(xoldMap != null) {
			oldMap.putAll(xoldMap);
		}
		if(xnewMap != null) {
			newMap.putAll(xnewMap);
		}
	}

	Set<String> mergedSiteNumbers {
		get {
			if(mergedSiteNumbers == null) {
				mergedSiteNumbers = new Set<String>();
				for(Address__c a : newMap.values()) {
					if( a.Status__c == 'Merged' 
						&& a.CDH_Party_Site_Number_Previous__c == null
						&& a.CDH_Party_Site_Number__c != null
						&& a.MasterRecord__c == null )
					{
						Address__c o = oldMap.get(a.Id);
						if( o == null
							|| ( o.Status__c != 'Merged'
								&& o.MasterRecord__c == null
								&& o.CDH_Party_Site_Number_Previous__c == null) )
						{
							mergedSiteNumbers.add(a.CDH_Party_Site_Number__c);
						}
					}
				}
			}
			return mergedSiteNumbers;
		}
		set;
	}

	/**
	 * Update the external ids.  Failures will be ignored, since the external id may already be used.
	 */
	public void correctExternalIds() {
		Map<String,Address__c> updateMap = new Map<String,Address__c>();
		for(Address__c a : newMap.values()) {
			if(a.IsDuplicate__c != true && a.CDH_Party_Site_Number__c != null) {
				Address__c o = oldMap.get(a.Id);
				if(o == null || o.Sales_Account__c != a.Sales_Account__c || o.CDH_Party_Site_Number__c != a.CDH_Party_Site_Number__c) {
					String externalId = a.Sales_Account__c+a.CDH_Party_Site_Number__c;
					if(a.Address_External_Id__c != externalId) {
						updateMap.put(externalId,new Address__c(Id=a.Id,Address_External_Id__c=externalId));
					}
				}
			}
		}
		if(! updateMap.isEmpty()) {
			Database.update(updateMap.values(),false);
		}
	}

	/**
	 * Used to create the duplicate log entries.
	 */
	public void logDuplicates() {
		Set<Id> accountIds = new Set<Id>();
		for(Address__c address : newMap.values()) {
			if(isInsert) {
				accountIds.add(address.Sales_Account__c);
			}
			if((isInsert && address.Reparented__c == true)||reparentedAddressMap.containsKey(address.Id)) {
				reparentedAddressMap.put(address.Id,address.Sales_Account__c);
			}
		}
		if(! (accountIds.isEmpty() && reparentedAddressMap.isEmpty())) {
			accountIds.addAll(reparentedAddressMap.values());
			AccountMergeBatchable amb = new AccountMergeBatchable();
			amb.accountIds = accountIds;
			List<SObject> addresses = amb.getAddresses(new List<SObject>(), 0);
			if(!addresses.isEmpty()) {
				amb.discoveredBy = 'Reparent';
				amb.execute(null,addresses);
			}
		}
	}

	/**
	 * Find any additional addresses that have a previous CDH Party Site Number and 
	 * update to the current value.
	 */
	public void updateDuplicates() {
		Map<String,String> newSiteNumbersMap = new Map<String,String>();
		for(Address__c a : newMap.values()) {
			Address__c o  = oldMap.get(a.Id);
			if( (o == null || o.CDH_Party_Site_Number_Previous__c != a.CDH_Party_Site_Number_Previous__c)
				&& a.CDH_Party_Site_Number__c != null
				&& a.CDH_Party_Site_Number_Previous__c != null
				&& a.CDH_Party_Site_Number_Previous__c != '-' )
			{
				newSiteNumbersMap.put(
					a.CDH_Party_Site_Number_Previous__c,
					a.CDH_Party_Site_Number__c );
			}
		}
		if(! (mergedSiteNumbers.isEmpty() && newSiteNumbersMap.isEmpty())) {
			final Set<String> newSiteNumbers = newSiteNumbersMap.keySet();
			mergedSiteNumbers.removeAll( newSiteNumbers );
			List<Address__c> updateList = [
				select Id, CDH_Party_Site_Number__c, Sales_Account__c
				from Address__c
				where Id not in :newMap.keySet()
					and ( ( CDH_Party_Site_Number__c in : newSiteNumbers
							and CDH_Party_Site_Number_Previous__c not in : newSiteNumbers )
						or ( CDH_Party_Site_Number__c in : mergedSiteNumbers
							and CDH_Party_Site_Number_Previous__c = null
							and IsDuplicate__c != true ) ) ];
			for(Address__c a : updateList) {
				String newSiteNumber = newSiteNumbersMap.get(a.CDH_Party_Site_Number__c);
				if(newSiteNumber == null) {
					a.IsDuplicate__c = true;
				}
				else {
					a.CDH_Party_Site_Number__c = newSiteNumber;
				}
				// lets just consider everything for duplicate resolution
				reparentedAddressMap.put(a.Id,a.Sales_Account__c);
			}
			if(! updateList.isEmpty()) {
				Database.update(updateList,false);
			}
		}
	}

	List<Address__c> nonDuplicateAddresses {
		get {
			if(nonDuplicateAddresses == null) {
				nonDuplicateAddresses = new List<Address__c>();
				for(Address__c address : newMap.values()) {
					if(address.IsDuplicate__c != true) {
						nonDuplicateAddresses.add(address);
					}
				}
			}
			return nonDuplicateAddresses;
		}
		set;
	}

	Set<Id> identifyingAccountIds {
		get {
			if(identifyingAccountIds == null) {
				identifyingAccountIds = new Set<Id>();
				for(Address__c address : nonDuplicateAddresses) {
					if(address.Identifying_Address__c == true) {
						identifyingAccountIds.add(address.Sales_Account__c);
					}
				}
			}
			return identifyingAccountIds;
		}
		set;
	}

	Map<Id,Address__c> addressToConsiderMap {
		get {
			if(addressToConsiderMap == null) {
				addressToConsiderMap = new Map<Id,Address__c>();
				Set<Id> addressIds = new Set<Id>();
				if(isInsert || isUpdate) {
					for(Address__c a : nonDuplicateAddresses) {
						Address__c o = oldMap.get(a.Id);
						// only consider newly inserted records and records that where previously marked as a duplicate
						if(o == null || o.IsDuplicate__c == true) {
							addressIds.add(a.Id);
						}
					}
				}
				if(! (addressIds.isEmpty() && identifyingAccountIds.isEmpty()) ) {
					addressToConsiderMap.putAll([
						Select id, 
							Name,
							Zip_Postal_Code__c,
							MasterRecord__r.Status__c,
							Status__c,Address_Line1__c,
							Address_Line2__c,
							Address_Line3__c,
							Address_Line4__c,
							Bill_To_Address__c,
							CDH_Party_Site_Number__c,
							City__c,Country__c,
							County__c,
							Entitle_To_Address__c,
							Identifying_Address__c,
							Province__c,
							Sales_Account__c,
							Ship_To_Address__c,
							Sold_To_Address__c,
							State__c,
							Sales_Account__r.Id,
							Sales_Account__r.CDH_Party_Name__r.Active__c,
							Sales_Account__r.CDH_Party_Name__r.Name,
							Sales_Account__r.Count_Of_Identifying_Address__c,
							Do_Not_Publish_To_Bus__c,
							Do_Not_Publish_To_Bus_Account__c
						from Address__c 
						where MasterRecord__c = null
							AND IsDuplicate__c != true
							AND (( Id IN :addressIds // for outbound messages
									AND ( Identifying_Address__c != true
										OR Sales_Account__r.Count_Of_Identifying_Address__c = 1
										OR (Sales_Account__r.Count_Of_Identifying_Address__c = 0 and Sales_Account__r.RecordType.Name like '%Partner%')) // DE9500
									AND ( Sales_Account__r.CDH_Party_Name__r.Id = null
										OR Sales_Account__r.CDH_Party_Name__r.Active__c = true) )
								OR ( Id NOT IN :newMap.keySet() // for correcting identifying address flags
									AND Sales_Account__c in :identifyingAccountIds 
									AND Identifying_Address__c = true ) ) ] );
				}
			}
			return addressToConsiderMap;
		}
		set;
	}


	public void outboundMessages() {
		if((isInsert || isUpdate) && ! nonDuplicateAddresses.isEmpty() ) {
			Map<Id,Address__c> addressMap = addressToConsiderMap.clone();
			addressMap.keySet().retainAll(newMap.keySet());
			if(! addressMap.isEmpty() ) {
				Map<Boolean,List<IntegrationObjects.SalesAccount>> ioAccountsMap = new Map<Boolean,List<IntegrationObjects.SalesAccount>>();
				//iterating through all the address records created. added CDH_Party_Name__r.Active__c to query for US66997
				for(Address__c address : addressMap.values()) {
					// creating the instance of sales account integration object.
					IntegrationObjects.SalesAccount ioAccount = new IntegrationObjects.SalesAccount();

					// set the id of account record.
					ioAccount.IDs = address.Sales_Account__r.Id;

					// setting the CDH Party number value
					if(address.Sales_Account__r.CDH_Party_Name__r != Null){
						ioAccount.CDH_Party_Number = address.Sales_Account__r.CDH_Party_Name__r.Name;
					}
					// create the instance of address integration object.
					IntegrationObjects.Address  ioAddress = new IntegrationObjects.Address();

					// invoke the converter method for address record
					ioAddress = IntegrationObjectConverter.convertAddress(address);

					// CDH Party# is the CDH Party# of sales account associated to address record , this is not set in the integration object converter method
					//ioAddress.CDH_Party_Number = address.Sales_Account__r.CDH_Party_Name__r.Name;

					// creating the list of address domain object and put the address domain object created above.
					List<IntegrationObjects.Address> ioAddressList = new List<IntegrationObjects.Address>();
					ioAddressList.add(ioAddress);

					// set the list of address for sales account domain object.
					ioAccount.Addresses = ioAddressList;

					Boolean doNotPublish = OutboundService.DoNotPublish || address.Do_Not_Publish_To_Bus__c || address.Do_Not_Publish_To_Bus_Account__c;
					List<IntegrationObjects.SalesAccount> ioAccounts = ioAccountsMap.get(doNotPublish);
					if(ioAccounts == null) {
						ioAccounts = new List<IntegrationObjects.SalesAccount>();
						ioAccountsMap.put(doNotPublish,ioAccounts);
					}
					system.debug('Create event is send outbound message-->'+ioAccount);
					ioAccounts.add(ioAccount);
				}
				if(! ioAccountsMap.isEmpty()) {
					Boolean doNotPublish = OutboundService.DoNotPublish;
					try {
						for(Boolean dnp : ioAccountsMap.keySet()) {
							OutboundService.DoNotPublish = dnp;
							// invoke the outbound service method to process address message.
							OutboundService.queueAccountMessages(ioAccountsMap.get(dnp),'Create',null,true);
						}
					}
					finally {
						OutboundService.DoNotPublish = doNotPublish;
					}
				}
			}
		}
	}

	public void setIdentifying() {
		if(! (isDelete || identifyingAccountIds.isEmpty())) {
			Map<Id,Address__c> addressMap = addressToConsiderMap.clone();
			addressMap.keySet().removeAll(newMap.keySet());
			if(! addressMap.isEmpty() ) {
				// iterating all those address which are already indentifying address , set thier identfying address check box as false
				for(Address__c address : addressMap.values()) {
					// set  previous identifying address as false.
					address.Identifying_Address__c = false;
				}
				// update the address list.
				Database.update(addressMap.values(),false);
			}
		}
	}

	/**
	 * This method is called to invoke all the trigger methods.
	 *
	 * @param xoldMap normally assigned from Trigger.oldMap
	 * @param xnewMap normally assigned from Trigger.newMap
	 * @param isUndelete true if being restored from the recycle bin
	 */
	public static void processTrigger(Map<Id,Address__c> xoldMap,Map<Id,Address__c> xnewMap ,Boolean isUndelete) {
		final AddressTriggerAfter afterTrigger = new AddressTriggerAfter(xoldMap,xnewMap, isUndelete);
		Boolean hasLock = ThreadLock.lock(RECURSION_LOCK);
		try {
			if(hasLock && AbstractTrigger.isActive(UPDATE_DUPLICATES_SETTING,true)) {
				afterTrigger.updateDuplicates();
			}
			if(hasLock && AbstractTrigger.isActive(LOG_DUPLICATES_SETTING,true)) {
				afterTrigger.logDuplicates();
			}
			if(AbstractTrigger.isActive(OUTBOUND_MESSAGES_SETTING,true)) {
				afterTrigger.outboundMessages();
			}
			if(hasLock && AbstractTrigger.isActive(SET_IDENTIFYING_SETTING,true)) {
				afterTrigger.setIdentifying();
			}
			if(hasLock && AbstractTrigger.isActive(CORRECT_EXTERNAL_IDS_SETTING,true)) {
				afterTrigger.correctExternalIds();
			}
		}
		finally {
			if(hasLock) {
				ThreadLock.unlock(RECURSION_LOCK);
			}
			AbstractTrigger.processTriggerComplete();
		}
	}
}