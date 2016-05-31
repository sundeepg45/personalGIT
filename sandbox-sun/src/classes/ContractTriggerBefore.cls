/**
 * In the future this class can replace all before insert and before update contract triggers.  
 * The processTrigger method is invoked by the Contract_Before trigger and in turn invokes
 * all the methods of this class.  This gives us a way to control the order in
 * which the code logic is invoked, as well as allowing other class features such
 * as shared data, constant values, and rigorous test coverage.
 * <p>
 * The Trigger object should never be directly referenced inside this class, as
 * that would make it impossible to substituting values inside test methods.
 * </p>
 * NOTE: Some other existing triggers have not yet been incorporated into this class (future).
 *
 * @version 2012-12-12
 * @author Scott Coleman <scoleman@redhat.com>
 * 2012-06-01 - Created
 * Bill Riemers <briemers@redhat.com>
 * 2013-12-12 - Add assignRegions method
 */
public with sharing class ContractTriggerBefore extends AbstractTrigger {
	/** BooleanSetting__c key to enable setting legacy values */
	public static final String ASSIGN_LEGACY_SETTING = 'Contract_Before.assignLegacy';
	/** BooleanSetting__c key to enable assigning region values */
	public static final String ASSIGN_REGIONS_SETTING = 'Contract_Before.assignRegions';
	/** BooleanSetting__c key to enable assignFieldsFromAccount */
	public static final String ASSIGN_FIELDS_FROM_ACCOUNT_SETTING = 'Contract_Before.assignAccountFields';
	/** BooleanSetting__c key to enable assignCompletedDate */
	public static final String ASSIGN_COMPLETED_DATE_SETTING = 'Contract_Before.assignCompletedDate';

	private final Map<Id,Contract> oldMap = new Map<Id,Contract>();
	private final List<Contract> newList = new List<Contract>();
	
	public ContractTriggerBefore(Map<Id,Contract> xoldMap,List<Contract> xnewList) {
		super(xoldMap,xnewList,null);
		if(xoldMap != null) {
			oldMap.putAll(xoldMap);
		}
		if(xnewList != null) {
			newList.addAll(xnewList);
		}
	}

	public void assignRegions() {
		Set<String> countries = new Set<String>();
		for(Contract con : newList) {
			Contract oldCon = oldMap.get(con.Id);
			if( con.Global__c != true && con.Country_of_Order__c != null && con.CountryOfOrder__c != con.Country_of_Order__c ) {
				con.CountryOfOrder__c = con.Country_of_Order__c;
			}
			if(con.Opportunity__c == null && oldCon != null && con.CountryOfOrder__c != null && oldCon.CountryOfOrder__c != con.CountryOfOrder__c) {
				con.Global__c = false;
			}
			if(con.Global__c != true) {
				// default country of order from the opportunity whenever a new opportunity is assigned
				if(con.CountryOfOrder__c != null) {
					countries.add(con.CountryOfOrder__c);
				}
//				else {
//					con.Global__c = true;
//				}
			}
			if(con.Global__c == true || con.CountryOfOrder__c == null) {
				if(con.CountryOfOrder__c != null) {
					con.CountryOfOrder__c = null;
				}
				if(con.Sub_Region__c != null) {
					con.Sub_Region__c = null;
				}
				if(con.Region__c != null) {
					con.Region__c = null;
				}
				if(con.Super_Region__c != null) {
					con.Super_Region__c = null;
				}
			}
		}

		//now get the countries for the region.	
		// assign the region, sub region and super region
		if (! hasErrors && ! countries.isEmpty()) {
			Map<String, Region__c> regionObjectByCountry = new Map<String, Region__c>();
			List<Region__c> regionObjects= [
				select 
					Country__c,
					Region__c,
					Sub_Region__c,
					Super_Region__c
				from Region__c 
				where Country__c in :countries
				order by CreatedDate desc ];
			for(Region__c regionObject: regionObjects) {
				if(regionObject.Country__c != null) {
					regionObjectByCountry.put(regionObject.Country__c.toUpperCase(),regionObject);
				}
			}
			for(Contract con : newList) {
				Region__c regionObject = regionObjectByCountry.get((''+con.CountryOfOrder__c).toUpperCase());
				if(regionObject != null) {
					con.Super_Region__c = regionObject.Super_Region__c;
					if(con.Sub_Region__c != null || con.CountryOfOrder__c != null) {
						con.Region__c = regionObject.Region__c;
						if(con.CountryOfOrder__c != null) {
							con.Sub_Region__c = regionObject.Sub_Region__c;
						}
					}
				}
			}
		}
	}

	/**
	 * Assigns values to SubTerritory, Territory, Vertical, and RecordTypeName__c based on the
	 * account.
	 */
	public void assignFieldsFromAccount() {
		if(isInsert) {
			Set<Id> accountIds = new Set<Id>();
			for(Contract con : newList) {
				accountIds.add(con.AccountId);
			}
			Map<Id,Account> accountMap = new Map<Id,Account>([
				select 
					SubTerritory__c,
					Territory1__c,
					Vertical__c,
					RecordType.Name 
				from Account 
				where Id in :accountIds ]);
			Map<Id,Id> accountRecordTypeIdMap = new Map<Id,Id>();
			for(Contract con : newList)
			{
				Account acc = accountMap.get(con.AccountId);
				if(acc != null) {
					con.SubTerritory__c= acc.SubTerritory__c;
					con.Territory__c = acc.Territory1__c ;
					con.Vertical__c  = acc.Vertical__c ;
					// Start ---23-06-2010---
					// added for populating new Account Record Type field in Contract when a Contract in inserted. 
					if(acc.RecordType != null) {
						con.Account_Record_Type__c = acc.RecordType.Name;
					}
				}
			}
		}
	}

	/**
	 * Assigns values to SubTerritory, Territory, Vertical, and RecordTypeName__c based on the
	 * account.
	 */
	public void assignCompletedDate() {
		if(isUpdate) {
			DateTime n = System.now();
			for(Contract con : newList) {
				//--August Release-- Case-RH-00038373
				if(con.Stage__c=='Completed' && con.Completed_Date__c == null && con.Stage__c != oldMap.get(con.Id).Stage__c)
				{
					 con.Completed_Date__c = n;
				}
			}
		}
	}

	public static void processTrigger(Map<Id,Contract> xoldMap,List<Contract> xnewList) {
		final ContractTriggerBefore beforeTrigger = new ContractTriggerBefore(xoldMap,xnewList);
		if(AbstractTrigger.isActive(ASSIGN_LEGACY_SETTING,true)) {
			beforeTrigger.assignLegacy();
		}
		if(AbstractTrigger.isActive(ASSIGN_REGIONS_SETTING,true)) {
			beforeTrigger.assignRegions();
		}
		if(AbstractTrigger.isActive(ASSIGN_FIELDS_FROM_ACCOUNT_SETTING,true)) {
			beforeTrigger.assignFieldsFromAccount();
		}
		if(AbstractTrigger.isActive(ASSIGN_COMPLETED_DATE_SETTING,true)) {
			beforeTrigger.assignCompletedDate();
		}
		AbstractTrigger.processTriggerComplete();
	}
}