/**
 * This class replaces all after insert and after update EBS_Account__c triggers.  The
 * processTrigger method is invoked by the EBSAccount_After trigger and in turn invokes
 * all the methods of this class.  This gives us a way to control the order in
 * which the code logic is invoked, as well as allowing other class features such
 * as shared data, constant values, and regorious test coverage.
 * <p>
 * The Trigger object should never be directly referenced inside this class, as
 * that would make it impossible to substituting values inside test methods.
 * </p>
 *
 * @version 2015-09-22
 * @author Bill Riemers <briemers@redhat.com>
 * 2015-09-22 - Created  - refactored from EBSAccountTriggerHandler
 */
public without sharing class EBSAccountTriggerAfter extends AbstractTrigger {
	/** BooleanSetting__c key to enable updateEBSAccountNumbers method. */
	public static final String UPDATE_EBS_NUMBERS_SETTING = 'EBSAccount_After.updateEBSNumbers';

	private final Map<Id,EBS_Account__c> oldMap = new Map<Id,EBS_Account__c>();
	private final Map<Id,EBS_Account__c> newMap = new Map<Id,EBS_Account__c>();
//	// note: isUndelete == true => isInsert == true
	private Boolean isUndelete;

	/**
	 * Typical TriggerBefore type constructor
	 *
	 * @param xoldMap the mapping of old values
	 * @param xnewMap the mapping of new values
	 */
	public EBSAccountTriggerAfter(Map<Id,EBS_Account__c> xoldMap,Map<Id,EBS_Account__c> xnewMap, Boolean isUndelete) {
		super(xoldMap,null,xnewMap);
		this.isUndelete = isUndelete;
		if(xoldMap != null) {
			oldMap.putAll(xoldMap);
		}
		if(xnewMap != null) {
			newMap.putAll(xnewMap);
		}
	}

	/**
	 * Used for updating the EBS Account Numbers on parent accounts.
	 * Refactored from EBSAccount_TriggerHandler.
	 */
	public void updateEBSAccountNumbers(){
		Map<Id,List<EBS_Account__c>> esbAccountBySalesAccountIdsMap = new Map<Id,List<EBS_Account__c>>();
		Map<Id,EBS_Account__c> ebsAccountMap = newMap;
		if(isDelete) {
			ebsAccountMap = oldMap;
		}
		//collect all the parent account ids  
		for(EBS_Account__c ebsAccount : ebsAccountMap.values()) {
			List<EBS_Account__c> ebsAccounts = esbAccountBySalesAccountIdsMap.get(ebsAccount.Sales_Account__c);
			if(ebsAccounts == null) {
				ebsAccounts = new List<EBS_Account__c>();
				esbAccountBySalesAccountIdsMap.put(ebsAccount.Sales_Account__c,ebsAccounts);
			}
			ebsAccounts.add(ebsAccount);
		}

		List<Account> salesAccounts = new List<Account>();
		//populate the EBS Account Numbers on the parent accounts
		for(Account salesAccount : [
			SELECT
				EBS_Account_Numbers__c, 
				(	SELECT
						Name,
						Primary_EBS_Account__c
					FROM EBS_Account__r
					WHERE MasterRecord__c = null
					ORDER BY Primary_EBS_Account__c DESC, Name )
			FROM Account
			WHERE Id IN :esbAccountBySalesAccountIdsMap.keySet() ] )
		{
			Set<String> ebsAccountNumberSet  = new Set<String>();
			String ebsAccountNumbers = '';
			String sep = '';
			for(EBS_Account__c ebsAccount : salesAccount.EBS_Account__r) {
				String name = ebsAccount.Name;
				if(! ebsAccountNumberSet.contains(name)) {
					ebsAccountNumberSet.add(name);
					if(ebsAccount.Primary_EBS_Account__c){
						name += '*';
					}
					ebsAccountNumbers += sep + name;
					sep = ', ';
				}
			}
			if(ebsAccountNumbers.length()>131070) {
				ebsAccountNumbers = ebsAccountNumbers.subString(0, 131069).subStringBeforeLast(', ')+', …';
			}
			// after a delete this could actually be an empty list...
			else if(ebsAccountNumbers == '') {
				ebsAccountNumbers = null;
			}
			if(ebsAccountNumbers != salesAccount.EBS_Account_Numbers__c) {
				salesAccount.EBS_Account_Numbers__c = ebsAccountNumbers;
				salesAccounts.add(salesAccount);
			}
		}
		for(Database.SaveResult r : Database.update(salesAccounts,false)) {
			Account a = salesAccounts.remove(0);
			if(! r.isSuccess()) {
				for(EBS_Account__c e : esbAccountBySalesAccountIdsMap.get(a.Id)) {
					// we do not add an error, as we prefer the update to complete and
					// have the list wrong, than failing
					System.debug('Failed to update parent account for '+e+': '+r.getErrors());
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
	public static void processTrigger(Map<Id,EBS_Account__c> xoldMap,Map<Id,EBS_Account__c> xnewMap ,Boolean isUndelete) {
		final EBSAccountTriggerAfter afterTrigger = new EBSAccountTriggerAfter(xoldMap,xnewMap, isUndelete);
		try {
			if(AbstractTrigger.isActive(UPDATE_EBS_NUMBERS_SETTING,true)) {
				afterTrigger.updateEBSAccountNumbers();
			}
		}
		finally {
			AbstractTrigger.processTriggerComplete();
		}
	}
}