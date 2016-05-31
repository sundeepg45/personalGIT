/**
 * This class is an extension to AccountTriggerBefore to support all the Account Lock 
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
 * @version 2012-06-02
 * 2011-06-02 - SMR update removed the settings set as it is no longer needed
 */
public without sharing class AccountTriggerBeforeLock extends AccountTriggerBefore {
	/** BooleanSetting__c key to enable the assignDefaultDataStatus trigger method. */
	public static final String ASSIGN_STATUS_SETTING = 'Account_Before.assignStatus';
	/** BooleanSetting__c key to enable the createAccountRelatedChanges trigger method. */
	public static final String CREATE_CHANGES_SETTING = 'Account_Before.createChanges';
	/** BooleanSetting__c key to enable the changeDataStatus trigger method. */
	public static final String CHANGE_STATUS_SETTING = 'Account_Before.changeStatus';
	/** BooleanSetting__c key to enable the assignHoursToReview trigger method. */
	public static final String HOURS_REVIEW_SETTING = 'Account_Before.hoursReview';

//	public static final String NO_CHANGES_ALLOWED = 'The locked fields for this account record are currently not editable due to data maintenance purposes (e.g. territory realignment).  This account will be editable shortly.';
	public static final String FAILED_CHANGES = 'Failed to create a change request for a locked field.';
	public static final String NO_CHANGE = 'NO CHANGE';
	public static final String PENDING_DATA_REVIEW = 'Pending Data Review';
	public static final String LOCKED = 'Locked';
	public static final String PENDING_UPDATE = 'Pending Update';
	public static final String PENDING_SALES_OPS = 'Pending Sales Ops';

	/**
	 * Stardard AccountTriggerBefore type contstructor.
	 *
	 * @param xoldMap typically assigned from Trigge.oldMap
	 * @param newList typically assigned from Trigger.newList
	 */
	public AccountTriggerBeforeLock(Map<Id,Account> xoldMap,List<Account> xnewList) {
		super(xoldMap,xnewList);
	}

	/**
	 * This method tests if the specified fieldName is an a picklist.
	 * To help reduce the number of look-ups, we only check the describe
	 * field results if both values are strings.
	 * 
	 * @param fieldName to check
	 * @param refValue1 the initial field value
	 * @param refValue2 the new field value
	 */
	public static Boolean isPicklistAccountField(String fieldName,Object refValue1,Object refValue2) {
		Boolean retval = false;
		if(refValue1 instanceof String && refValue2 instanceof String) {
			Schema.DescribeFieldResult dfr = AccountChangeRequest_ControllerExtension.getAccountDescribeFieldResult(fieldName);
			if(dfr != null) {
				Schema.DisplayType t = dfr.getType();
				if(t == Schema.DisplayType.Picklist || t == Schema.DisplayType.MultiPicklist) {
					retval = true;
				}
			}
		}
		return retval;
	}

	/**
	 * This is a list PicklistEntry list for AccountChangeRequestField__c 
	 * FieldName field.
	 */
	static List<Schema.PicklistEntry> fieldNamePicklistEntries {
		get {
			if(fieldNamePicklistEntries == null) {
				fieldNamePicklistEntries = AccountChangeRequestField__c.FieldName__c.getDescribe().getPicklistValues();
			}
			return fieldNamePicklistEntries;
		}
	}

	/** 
	 * This is a list of locked fields as determined by 
	 * fieldNamePicklistEntries.
	 */
	public static Set<String> lockedFields {
		get {
			if(lockedFields == null) {
				lockedFields = new Set<String>();
				for(Schema.PicklistEntry e : fieldNamePicklistEntries) {
					lockedFields.add(e.Value.toLowerCase());
				}
			}
			return lockedFields;
		}
	}

	/**
	 * Check to see if a field is locked
	 *
	 * @param fieldName to check
	 * @return true if the fieldName is in the locked list
	 */
	public static Boolean isLockedField(String fieldName) {
		Boolean retval = false;
		if(fieldName != null) {
			retval = lockedFields.contains(fieldName.toLowerCase());
		}
		return retval;
	}

	/**
	 * This method tests if two objects are the same value by
	 * comparing the String.valueOf conversion.  We treat
	 * nulls and nill strings as the same.
	 *
	 * @param a first object to compare
	 * @param a second object to compare
	 * @return true if both objects convert to the same string
	 */
	static Boolean equalValues(Object a,Object b) {
		return (a == null || String.valueOf(a) == '')?(b == null || String.valueOf(b) == ''):(b != null && String.valueOf(a) == String.valueOf(b));
	}

	/**
	 * Assign a default value for Data_Status__c
	 */
	public void assignDefaultDataStatus() {
		for(Account a : newList) {
			if(a.Data_Status__c == null) {
				a.Data_Status__c = PENDING_DATA_REVIEW;
			}
		}
	}

	/**
	 * Create AccountChangeRequest__c records for locked fields
	 */
	public void createAccountRelatedChanges() {
		if(isUpdate && AccountChangeRequest_ControllerExtension.isDataStatusAccessible && ! AccountChangeRequest_ControllerExtension.isDataStatusUpdateable) {
			List<AccountChangeRequest__c> accountChangeRequests = new List<AccountChangeRequest__c>();
			Map<Id,List<AccountChangeRequestField__c>> acrfsMap = new Map<Id,List<AccountChangeRequestField__c>>();
			for(Account a : newList) {
				if(a.Data_Status__c != null && a.Data_Status__c != PENDING_DATA_REVIEW) {
					List<AccountChangeRequestField__c> acrfs = new List<AccountChangeRequestField__c>();
					AccountChangeRequest__c acr = new AccountChangeRequest__c(Account__c = a.Id);
					Account o = oldMap.get(a.Id);
					Boolean recordTypeChange = false;
					Boolean isPending = false;
					Set<String> fieldNameSet = AccountChangeRequest_ControllerExtension.accountFieldMap.keySet().clone();
					fieldNameSet.remove('data_status__c');
					fieldNameSet.remove('recordtypeid');
					List<String> fieldNames = new List<String>(fieldNameSet);
					fieldNames.add(0,'recordtypeid');
					for(String fieldName : fieldNames) {
						if((! fieldName.endsWith('__r'))) {
							System.debug('FieldName='+fieldName);
							try {
								Object newFieldValue = a.get(fieldName);
								Object oldFieldValue = o.get(fieldName);
								System.debug('newFieldValue='+newFieldValue+',oldFieldValue='+oldFieldValue);
								if(! ((newFieldValue instanceof SObject && oldFieldValue instanceof SObject) || equalValues(newFieldValue,oldFieldValue))) {
									Boolean lf = isLockedField(fieldName);
									if(lf || (recordTypeChange && isPicklistAccountField(fieldName,newFieldValue,oldFieldValue))) {
										// here is where we create the AccountChangeRecordField__c record
										System.debug('Changed field : '+fieldName+' from <{'+oldFieldValue+'}> to <{'+newFieldValue+'}>');
										AccountChangeRequestField__c acrf;
										if(newFieldValue instanceof Boolean && oldFieldValue instanceof Boolean) {
											acrf = new AccountChangeRequestField__c(
												FieldName__c=fieldName,
												TextValue__c=String.valueOf(newFieldValue),
												BooleanValue__c=(Boolean)newFieldValue,
												OriginalTextValue__c=String.valueOf(oldFieldValue),
												OriginalBooleanValue__c=(Boolean)oldFieldValue);
											a.put(fieldName,(Boolean)oldFieldValue);
										}
										else if(newFieldValue instanceof DateTime && oldFieldValue instanceof DateTime) {
											acrf = new AccountChangeRequestField__c(
												FieldName__c=fieldName,
												TextValue__c=String.valueOf(newFieldValue),
												DateTimeValue__c=(DateTime)newFieldValue,
												OriginalTextValue__c=String.valueOf(oldFieldValue),
												OriginalDateTimeValue__c=(DateTime)oldFieldValue);
											a.put(fieldName,(DateTime)oldFieldValue);
										}
										else if(newFieldValue instanceof Date && oldFieldValue instanceof Date) {
											acrf = new AccountChangeRequestField__c(
												FieldName__c=fieldName,
												TextValue__c=String.valueOf(newFieldValue),
												DateValue__c=(Date)newFieldValue,
												OriginalTextValue__c=String.valueOf(oldFieldValue),
												OriginalDateValue__c=(Date)oldFieldValue);
											a.put(fieldName,(Date)oldFieldValue);
										}
										else {
											acrf = new AccountChangeRequestField__c(
												FieldName__c=fieldName,
												TextValue__c=String.valueOf(newFieldValue),
												OriginalTextValue__c=String.valueOf(oldFieldValue));
											if(newFieldValue instanceof Decimal && oldFieldValue instanceof Decimal) {
												a.put(fieldName,(Decimal)oldFieldValue);
											}
											else {
												if(oldFieldValue == null) {
													oldFieldValue = '';
												}
												a.put(fieldName,(String)oldFieldValue);
											}
										}
										acrfs.add(acrf);
										recordTypeChange = recordTypeChange || fieldName == 'RecordTypeId';
										isPending = true;
									}
								}
							}
							catch (Exception e) {
								System.debug('Failed to parse Account.'+fieldName+' : '+e);
							}
						}
					}
					if(isPending) {
//						if(a.Data_Status__c == PENDING_SALES_OPS) {
//							a.addError(NO_CHANGES_ALLOWED);
//							continue;
//						}
						if(a.Data_Status__c == LOCKED || o.Data_Status__c == LOCKED || o.Data_Status__c == PENDING_UPDATE) {
							a.Data_Status__c = PENDING_UPDATE;
						}
						System.debug('Data_Status__c='+a.Data_Status__c);
						accountChangeRequests.add(acr);
						acrfsMap.put(a.Id,acrfs);
					}
				}
			}
			if(! accountChangeRequests.isEmpty()) {
				Map<Id,Account> accountByAcrIdMap = new Map<Id,Account>();
				List<AccountChangeRequestField__c> acrfs = new List<AccountChangeRequestField__c>();
				for(Database.SaveResult r : Database.insert(accountChangeRequests,false)) {
					AccountChangeRequest__c acr = accountChangeRequests.remove(0);
					Account a = accountMap.get(acr.Account__c);
					if(r.isSuccess()) {
						accountByAcrIdMap.put(acr.Id,a);
						for(AccountChangeRequestField__c acrf : acrfsMap.get(acr.Account__c)) {
							acrfs.add(new AccountChangeRequestField__c(
								ChangeRequest__c=acr.Id,
								FieldName__c=acrf.FieldName__c,
								TextValue__c=acrf.TextValue__c,
								BooleanValue__c = acrf.BooleanValue__c,
								DateTimeValue__c = acrf.DateTimeValue__c,
								DateValue__c = acrf.DateValue__c,
								OriginalTextValue__c=acrf.OriginalTextValue__c,
								OriginalBooleanValue__c = acrf.OriginalBooleanValue__c,
								OriginalDateTimeValue__c = acrf.OriginalDateTimeValue__c,
								OriginalDateValue__c = acrf.OriginalDateValue__c));
						}
					}
					else {
						for(Database.Error e : r.getErrors()) {
							a.addError(FAILED_CHANGES+':'+e.getMessage());
						}
					}
				}
				if(! acrfs.isEmpty()) {
					for(Database.SaveResult r : Database.insert(acrfs,false)) {
						AccountChangeRequestField__c acrf = acrfs.remove(0);
						if(! r.isSuccess()) {
							Account a = accountByAcrIdMap.get(acrf.ChangeRequest__c);
							for(Database.Error e : r.getErrors()) {
								a.addError(FAILED_CHANGES+':Field '+acrf.FieldName__c+':'+e.getMessage());
							}
						}
					}
				}
			}
		}
	}

	/**
	 * Update Data_Status__c
	 */
	public void changeDataStatus() {
		if(isUpdate) {
			Map<Id,Account> accountMap = new Map<Id,Account>();
			for(Account a : newList) {
				Account o = oldMap.get(a.Id);
				if(o.Data_Status__c != a.Data_Status__c) {
					if(a.Data_Status__c == LOCKED || (a.Data_Status__c == PENDING_DATA_REVIEW && o.Data_Status__c != null)) {
						accountMap.put(a.Id,a);
					}
				}
			}
			if(! accountMap.isEmpty()) {
				for(AggregateResult ar : [select Account__c from AccountChangeRequest__c where Account__c in : accountMap.keySet() and Status__c != :AccountChangeRequest_ControllerExtension.REVIEWED Group By Account__c]) {
					Id accountId = (Id)ar.get('Account__c');
					Account a = accountMap.remove(accountId);
					if(a != null) {
						a.Data_Status__c = PENDING_UPDATE;
					}
				}
			}
		}
	}

	/**
	 * Assign the Hours_to_Review__c value
	 */
	public void assignHoursToReview() {
		Long n = null;
		for(Account a : newList) {
			if(a.Hours_to_Review__c == null && (a.Data_Status__c == PENDING_UPDATE || a.Data_Status__c == LOCKED)) {
				if(n == null) {
					n = DateTime.now().getTime();
				}
				Double hoursToReview = 0;
				if(a.CreatedDate != null) {
					hoursToReview = Double.valueOf(n - a.CreatedDate.getTime())/3600000.0;
				}
				a.Hours_to_Review__c = hoursToReview;
			}
		}
	}

	/**
	 * Invoke the the triggers methods for this class.
	 *
	 * @param xoldMap typically assigned from Trigger.oldMap
	 * @param xnewList typically assigned from Trigger.newList
	 */
	public static void processTrigger(Map<Id,Account> xoldMap,List<Account> xnewList) {
		final AccountTriggerBeforeLock beforeTrigger = new AccountTriggerBeforeLock(xoldMap,xnewList);
		if(AbstractTrigger.isActive(ASSIGN_STATUS_SETTING,true)) {
			beforeTrigger.assignDefaultDataStatus();
		}
		if(AbstractTrigger.isActive(CREATE_CHANGES_SETTING,true)) {
			beforeTrigger.createAccountRelatedChanges();
		}
		if(AbstractTrigger.isActive(CHANGE_STATUS_SETTING,true)) {
			beforeTrigger.changeDataStatus();
		}
		if(AbstractTrigger.isActive(HOURS_REVIEW_SETTING,true)) {
			beforeTrigger.assignHoursToReview();
		}
	}
}