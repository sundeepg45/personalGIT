/**
 * This class replaces all before insert and before update contact triggers.  The
 * processTrigger method is invoked by the Account_After trigger and in turn invokes
 * all the methods of this class.  This gives us a way to control the order in
 * which the code logic is invoked, as well as allowing other class features such
 * as shared data, constant values, and regorious test coverage.
 * <p>
 * The Trigger object should never be directly referenced inside this class, as
 * that would make it impossible to substituting values inside test methods.
 * </p>
 *
 * @version 2015-08-18
 * @author Bill Riemers <briemers@redhat.com>
 * 2015-08-18 - implented trigger to selectively block account merges
 */
public without sharing class AccountTriggerAfter extends AbstractTrigger {
	/** BooleanSetting__c key to enable sendOutboundMessage method. */
	public static final String BLOCK_ACCOUNT_MERGE_SETTING = 'Account_After.blockAccountMerge';

	@TestVisible
	private final Map<Id,Account> oldMap = new Map<Id,Account>();
	private final Map<Id,Account> newMap = new Map<Id,Account>();
//	// note: isUndelete == true => isInsert == true
	private Boolean isUndelete;
	@TestVisible
	private Boolean hasErrors = false;


	/**
	 * Typical TriggerBefore type constructor
	 *
	 * @param xoldMap the mapping of old values
	 * @param xnewMap the mapping of new values
	 */
	public AccountTriggerAfter(Map<Id,Account> xoldMap,Map<Id,Account> xnewMap, Boolean isUndelete) {
		super(xoldMap,null,xnewMap);
		this.isUndelete = isUndelete;
		if(xoldMap != null) {
			oldMap.putAll(xoldMap);
		}
		if(xnewMap != null) {
			newMap.putAll(xnewMap);
		}
	}

	private void addError(Account a,String errorMessage) {
		if(a != null) {
			a.addError(errorMessage);
		}
		hasErrors = true;
	}

	/**
	 * Map of account Id to MasterRecordId
	 */
	public Map<Id,Id> masterRecordIdMap {
		get {
			if(masterRecordIdMap == null) {
				masterRecordIdMap = new Map<Id,Id>();
				for(Account a : oldMap.values()) {
					if(a.MasterRecordId != null) {
						masterRecordIdMap.put(a.Id,a.MasterRecordId);
					}
				}
			}
			return masterRecordIdMap;
		}
		set;
	}

	/**
	 * Block merges to accounts with a different CDH_Party_Name__c value.
	 */
	public void blockAccountMerges() {
		if(isDelete && ! masterRecordIdMap.isEmpty()) {
			Map<Id,Account> masterRecordMap = new Map<Id,Account>([
				select Id, CDH_Party_Name__c
				from Account
				where Id in :masterRecordIdMap.values() and CDH_Party_Name__c != null ] );
			for(Id accountId : masterRecordIdMap.keySet()) {
				Account a = oldMap.get(accountId);
				if( a != null) {
					Id masterRecordId = a.MasterRecordId;
					if(masterRecordId == null) { // this only happens when running a test
						masterRecordId = masterRecordIdMap.get(a.Id);
					}
					Account a2 = masterRecordMap.get(masterRecordId);
					if(a2 == null || a2.CDH_Party_Name__c == null || a2.CDH_Party_Name__c != a.CDH_Party_Name__c) {
						addError(oldMap.remove(accountId),Label.AccountMerge_CDH_Party_MisMatch);
					}
				}
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
	public static void processTrigger(Map<Id,Account> xoldMap,Map<Id,Account> xnewMap ,Boolean isUndelete) {
		// We use a locking variable to avoid unintended recursion.
		final String lockString = 'AccountTriggerAfter.Lock';
		if(ThreadLock.lock(lockString)) {
			try {
				final AccountTriggerAfter afterTrigger = new AccountTriggerAfter(xoldMap,xnewMap, isUndelete);
				if(AbstractTrigger.isActive(BLOCK_ACCOUNT_MERGE_SETTING,true)) {
					afterTrigger.blockAccountMerges();
				}
				AbstractTrigger.processTriggerComplete();
			}
			finally {
				ThreadLock.unlock(lockString);
			}
		}
	}
}