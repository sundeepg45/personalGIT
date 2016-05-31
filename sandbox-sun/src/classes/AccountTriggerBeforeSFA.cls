/**
 * This class is an extension to AccountTriggerBefore to support all misc SFA  
 * related triggers.  The methods in this class are invoked by AccountTriggerBefore 
 * will eventually replace all before insert and before update account triggers.
 * which in are invoked by by the Account_Before trigger.
 * <p>
 * The Trigger object should never be directly referenced inside this class or its 
 * subclasses as that would make it impossible to substituting values inside test 
 * methods.
 * </p>
 *
 * @author Bill C Riemers <briemers@redhat.com>
 * @version 2015-11-23
 * 2015-11-23 - Reduce the number of queries
 * 2012-06-02 - SMR update removed the settings set as it is no longer needed
 * Scott Coleman <scoleman@redhat.com>
 * 2014-04-22 - Added validation for Eligible for Disti Annual Pay Program field
 * 2012-10-22 - Added mapping of Named Account to Account Classification
 */
public without sharing class AccountTriggerBeforeSFA extends AccountTriggerBefore {
	/** BooleanSetting__c key to enable the assignRecordType trigger method. */
	public static final String ASSIGN_RECORD_TYPE_SETTING = 'Account_Before.assignRecordType';

	/** BooleanSetting__c key to enable the assignLegacy trigger method. */
	public static final String ASSIGN_LEGACY_SETTING = 'Account_Before.assignLegacy';

	/** BooleanSetting__c key to enable the assignLegacy trigger method. */
	public static final String SET_NAMED_ACCOUNT_SETTING = 'Account_Before.setNamedAccount';

	/** BooleanSetting__c key to enable validation for Eligible for Disti Annual Pay Program field. */
	public static final String VALIDATE_DISTI_ANNUAL_SETTING = 'Account_Before.validateDistiAnnual';

	/** Used to keep track of errors while debugging */
	public Boolean hasErrors = false;

	/**
	 * Stardard AccountTriggerBefore type contstructor.
	 *
	 * @param xoldMap typically assigned from Trigge.oldMap
	 * @param newList typically assigned from Trigger.newList
	 */
	public AccountTriggerBeforeSFA(Map<Id,Account> xoldMap,List<Account> xnewList) {
		super(xoldMap,xnewList);
	}

	/**
	 * Assign the account's RecordTypeId when the default value was used.
	 */
	public void assignRecordType() {
		StringSetting__c defaultRecordTypeId = StringSetting__c.getInstance('Account.DefaultRecordTypeId');
		// we only update record types if there is a DefaultRecordTypes__c record for this user
		if(defaultRecordTypeId != null) {
			List<Account> accList = new List<Account>();
			for(Account acc : newList) {
				if(acc.RecordTypeId == defaultRecordTypeId.Value__c) {
					accList.add(acc);
				}
			}
			if(! accList.isEmpty() ) {
				DefaultRecordTypes__c dfrt = DefaultRecordTypes__c.getInstance();
				if(dfrt != null &&
					(	dfrt.PreferredAccountRecordType__c != null
						|| dfrt.SecondaryAccountRecordType__c != null) )
				{
					String accountRecordTypeName = null;
					// determine super region to use for %r remapping
					String superRegion = currentUser.Region__c;
					if((superRegion == null || superRegion == 'GLOBAL') && dfrt.GlobalAs__c != null) {
						superRegion = dfrt.GlobalAs__c;
					}
					if(dfrt.PreferredAccountRecordType__c != null) {
						// lookup the record type mapping assignments
						Map<String,Set<String>> rtnMap = RecordTypeSelectController.getRecordTypeNameMap(currentUser,new Set<String>{'ACCOUNT','OPPORTUNITY'});
						// set the record type for accounts
						String recordType = dfrt.PreferredAccountRecordType__c.replaceAll('%r',superRegion);
						for(String n : rtnMap.get('ACCOUNT')) {
							if(n == recordType) {
								accountRecordTypeName = n;
							}
						}
					}
					// if neccessary use the secondary account record type
					if (accountRecordTypeName == null && dfrt.SecondaryAccountRecordType__c != null) {
						accountRecordTypeName = dfrt.SecondaryAccountRecordType__c.replaceAll('%r',superRegion);
					}
					if(accountRecordTypeName != null) {
						Schema.RecordTypeInfo recordTypeInfo= Schema.SObjectType.Account.getRecordTypeInfosByName().get(accountRecordTypeName);
						Id recordTypeId = null;
						if(recordTypeInfo != null) {
							recordTypeId = recordTypeInfo.getRecordTypeId();
						}
						if(recordTypeId == null) {
							for(RecordType rt : [
								select Id
								from RecordType
								where (Name = :accountRecordTypeName 
									or DeveloperName = :accountRecordTypeName)
									and SObjectType = 'Account' limit 1] )
							{
								recordTypeId = rt.Id;
							}
						}
						if(recordTypeId != null) {
							for(Account acc : accList) {
								acc.RecordTypeId = recordTypeId;
							}
						}
					}
				}
				for(Account acc : accList) {
					if(acc.RecordTypeId ==  defaultRecordTypeId.Value__c) {
						acc.addError('Failed to map default account RecordType');
					}
				}
			}
		}
	}

	// map that defines the rules for automatically setting the Named Account checkbox
	// Map<[Record Type Name],Map<[Account Classification],Map<[Sub Region],[Named Account]>>>
	public Map<String,Map<String,Map<String,Boolean>>> namedAccountRuleMap {
		get {
			if(namedAccountRuleMap == null) {		
				namedAccountRuleMap = new Map<String,Map<String,Map<String,Boolean>>>();
				Map<String,Map<String,Boolean>> accountClassificationMap;
				// at this time there are no subregion rules Map<String,Boolean> subRegionMap;
				
				// APAC Account
				namedAccountRuleMap.put('APAC Account',new Map<String,Map<String,Boolean>>());
				accountClassificationMap = namedAccountRuleMap.get('APAC Account');
				accountClassificationMap.put('Duplicate Account - Delete',new Map<String,Boolean>{'*' => false});
				accountClassificationMap.put('Sales - Enterprise',new Map<String,Boolean>{'*' => true});
				accountClassificationMap.put('Sales - Enterprise Territory',new Map<String,Boolean>{'*' => true});
				accountClassificationMap.put('Sales - Global',new Map<String,Boolean>{'*' => true});
				accountClassificationMap.put('Sales - Key',new Map<String,Boolean>{'*' => true});
				accountClassificationMap.put('Sales - Strategic',new Map<String,Boolean>{'*' => true});

				// APAC Partner
				namedAccountRuleMap.put('APAC Partner',new Map<String,Map<String,Boolean>>());
				accountClassificationMap = namedAccountRuleMap.get('APAC Partner');
				accountClassificationMap.put('*',new Map<String,Boolean>{'*' => false});

				//EMEA Account
				namedAccountRuleMap.put('EMEA Account',new Map<String,Map<String,Boolean>>{});
				accountClassificationMap = namedAccountRuleMap.get('EMEA Account');
				accountClassificationMap.put('Duplicate Account - Delete',new Map<String,Boolean>{'*' => false});
				accountClassificationMap.put('Sales - Focus',new Map<String,Boolean>{'*' => false});
				accountClassificationMap.put('Sales - Global',new Map<String,Boolean>{'*' => true});
				accountClassificationMap.put('Sales - Key',new Map<String,Boolean>{'*' => true});
				accountClassificationMap.put('Sales - SMB',new Map<String,Boolean>{'*' => false});
				accountClassificationMap.put('Sales - Strategic',new Map<String,Boolean>{'*' => true});

				//EMEA Partner
				namedAccountRuleMap.put('EMEA Partner',new Map<String,Map<String,Boolean>>());
				accountClassificationMap = namedAccountRuleMap.get('EMEA Partner');
				accountClassificationMap.put('*',new Map<String,Boolean>{'*' => false});

				//LATAM Account
				//no rules defined

				//LATAM Partner
				namedAccountRuleMap.put('LATAM Partner',new Map<String,Map<String,Boolean>>());
				accountClassificationMap = namedAccountRuleMap.get('LATAM Partner');
				accountClassificationMap.put('*',new Map<String,Boolean>{'*' => false});

				//NA Account
				namedAccountRuleMap.put('NA Account',new Map<String,Map<String,Boolean>>());
				accountClassificationMap = namedAccountRuleMap.get('NA Account');
				accountClassificationMap.put('Commercial',new Map<String,Boolean>{'*' => true});
				accountClassificationMap.put('Enterprise',new Map<String,Boolean>{'*' => true});
				accountClassificationMap.put('Incremental',new Map<String,Boolean>{'*' => false});
				accountClassificationMap.put('Sales - NA Strategic',new Map<String,Boolean>{'*' => true});

				//NA Partner
				namedAccountRuleMap.put('NA Partner',new Map<String,Map<String,Boolean>>());
				accountClassificationMap = namedAccountRuleMap.get('NA Partner');
				accountClassificationMap.put('*',new Map<String,Boolean>{'*' => false});

				//Fed/Sled, Master Account Layout, Strategic
				//no rules defined
			}
			return namedAccountRuleMap;
		}
		set;
	}

	/**
	 * Set the Named Account checkbox based on Account Classification
	 */
	public void setNamedAccount() {
		Map<Id,Schema.RecordTypeInfo> recordTypeInfoMap = Schema.SObjectType.Account.getRecordTypeInfosById();
		for(Account acc : newList) {
			if (isInsert
				|| (isUpdate && (acc.AccountClassification__c != oldMap.get(acc.Id).AccountClassification__c)
					|| (acc.RecordTypeId != oldMap.get(acc.Id).RecordTypeId)
					|| (acc.Subregion__c != oldMap.get(acc.Id).Subregion__c))) {

				Map<String,Map<String,Boolean>> accountClassificationMap;
				Map<String,Boolean> subRegionMap;

				//evaluate rules to determine if we should update the Named Account checkbox
				Schema.RecordTypeInfo rti = recordTypeInfoMap.get(acc.RecordTypeId);
				if(rti != null) {
					String recordTypeName = rti.getName();
					String accountClassification = acc.AccountClassification__c;
					String subRegion = acc.Subregion__c;
					Boolean namedAccount = null;
					if (namedAccountRuleMap.containsKey(recordTypeName)) {
						accountClassificationMap = namedAccountRuleMap.get(recordTypeName);
						if (accountClassificationMap.containsKey(accountClassification)) {
							subRegionMap = accountClassificationMap.get(accountClassification);
						}
						else if (accountClassificationMap.containsKey('*')) {
							subRegionMap = accountClassificationMap.get('*');
						}
						if (subRegionMap != null) {
							if (subRegionMap.containsKey(subRegion)) {
								namedAccount = subRegionMap.get(subRegion);
							}
							else if (subRegionMap.containsKey('*')) {
								namedAccount = subRegionMap.get('*');
							}
						}
					}
					if (namedAccount != null && acc.Named_Account__c != namedAccount) {
						acc.Named_Account__c = namedAccount;
					}
				}
			}
		}
	}

	/**
	 * Ensure that only members of the NA Channel Ops public group can set the Eligible 
	 * for Disti Annual Pay Program flag.
	 */
	public void validateEligibleForDistiAnnualPay() {
		
		Map<Id,Account> accountMap = new Map<Id,Account>();

		// identify accounts where the disti annual pay flag is being set or unset
		for(Account acc : newList) {

			if((isInsert && acc.Eligible_for_Disti_Annual_Pay_Program__c == true)
				|| (isUpdate && oldMap.get(acc.Id).Eligible_for_Disti_Annual_Pay_Program__c != acc.Eligible_for_Disti_Annual_Pay_Program__c)) {

				accountMap.put(acc.Id, acc);
			}
		}

		// if accounts identified, make sure user is a member of the NA Channel Ops public group
		if(!accountMap.isEmpty()) {

			Group naChannelOpsGroup = [
				SELECT
					Id,
					(SELECT
						Id
					FROM GroupMembers
					WHERE UserOrGroupId = :UserInfo.getUserId())
				FROM Group
				WHERE DeveloperName = 'NAChannelOps'
				LIMIT 1];

			if(naChannelOpsGroup != null && naChannelOpsGroup.GroupMembers.isEmpty()) {

				// user is not a member of the group - add an error to each account
				for(Account acc : accountMap.values()) {
					hasErrors = true;
					acc.Eligible_for_Disti_Annual_Pay_Program__c.addError('Only NA Channel Ops may edit this field.');
				}
			}
		}
	}

	/**
	 * Invoke the the triggers methods for this class.  Note: The assignLegacy
	 * method is defined in the AbstractTrigger.
	 *
	 * @param xoldMap typically assigned from Trigger.oldMap
	 * @param xnewList typically assigned from Trigger.newList
	 */
	public static void processTrigger(Map<Id,Account> xoldMap,List<Account> xnewList) {
		final AccountTriggerBeforeSFA beforeTrigger = new AccountTriggerBeforeSFA(xoldMap,xnewList);
		if(AbstractTrigger.isActive(ASSIGN_RECORD_TYPE_SETTING,true)) {
			beforeTrigger.assignRecordType();
		}
		if(AbstractTrigger.isActive(SET_NAMED_ACCOUNT_SETTING,true)) {
			beforeTrigger.setNamedAccount();
		}
		if(AbstractTrigger.isActive(ASSIGN_LEGACY_SETTING,true)) {
			beforeTrigger.assignLegacy();
		}
		if(AbstractTrigger.isActive(VALIDATE_DISTI_ANNUAL_SETTING,true)) {
			beforeTrigger.validateEligibleForDistiAnnualPay();
		}
	}
}