/**
 * This is a controller class for merging accounts.
 * 
 * @author Bill C. Riemers <briemers@redhat.com>
 * @version 2016-01-13
 * 2016-01-13 - Created
 */
public with sharing class AccountMergeSetController {
	public static final String ACCOUNT_MERGE_LIMIT_SETTING = 'AccountMerge.Limit';

	private final ApexPages.StandardSetController stdSetController;

	@TestVisible
	private static List<Schema.FieldSetMember> accountMergeFields {
		get {
			if(accountMergeFields == null) {
				accountMergeFields = Schema.SObjectType.Account.fieldSets.Account_Merge.getFields();
			}
			return accountMergeFields;
		}
	}


	/**
	 * ControllerExtension constructor for sets of records.
	 */
	public AccountMergeSetController(ApexPages.StandardSetController stdSetController) {
		this.stdSetController = stdSetController;
		if(accounts == null || accounts.size() < 2) {
			ApexPages.addmessage(new ApexPages.message(
				ApexPages.severity.ERROR,
				Label.Account_Merge_At_Least));
		}
		else if (accounts.size() > accountMergeLimit ) {
			ApexPages.addmessage(new ApexPages.message(
				ApexPages.severity.ERROR,
				Label.Account_Merge_Limit.replaceAll('\\{AccountMergeLimit\\}',String.valueOf(accountMergeLimit) ) ) );
		}
	}

	public Integer accountMergeLimit {
		get {
			if(accountMergeLimit == null) {
				accountMergeLimit = 3;
				LongSetting__c accountMergeLimitSetting = LongSetting__c.getInstance(ACCOUNT_MERGE_LIMIT_SETTING);
				if(accountMergeLimitSetting == null) {
					accountMergeLimitSetting = new LongSetting__c(Name=ACCOUNT_MERGE_LIMIT_SETTING,Value__c=3);
				}
				if(accountMergeLimitSetting.Value__c != null) {
					accountMergeLimit = accountMergeLimitSetting.Value__c.intValue();
				}
			}
			return accountMergeLimit;
		}
		private set;
	}

	public Id defaultAccountId {
		get {
			if(defaultAccountId == null && accounts != null && ! accounts.isEmpty()) {
				defaultAccountId = accounts[0].Id;
			}
			return defaultAccountId;
		}
		set;
	}

	public List<Account> accounts {
		get {
			if(accounts == null && ! accountMergeFields.isEmpty()) {
				List<SObject> selected = stdSetController.getSelected();
				if(selected != null && ! selected.isEmpty()) {
					final Set<Id> accountIds = new Map<Id,SObject>(selected).keySet();
					String queryString = 'select Id,Name,CDH_Party_Name__c';
					Set<String> fieldPaths = new Set<String>{'ID','NAME','CDH_PARTY_NAME__C'};
					final Map<String,Schema.SObjectField> mapFields = Schema.SObjectType.Account.fields.getMap();
					for(Schema.FieldSetMember fsm : accountMergeFields) {
						if(! fieldPaths.contains(fsm.getFieldPath().toUpperCase())) {
							if(mapFields.get(fsm.getFieldPath()).getDescribe().isAccessible()) {
								queryString += ',' + fsm.getFieldPath();
							}
							fieldPaths.add(fsm.getFieldPath().toUpperCase());
						}
					}
					queryString += ' from Account where Id in :accountIds';
					System.debug(queryString);
					accounts = Database.query(queryString);
				}
			}
			return accounts;
		}
		set;
	}

	public List<FieldSelect> fieldSelectList {
		get {
			if(fieldSelectList == null && accounts != null && ! accounts.isEmpty()) {
				fieldSelectList = new List<FieldSelect>{ new FieldSelect(null,accounts,true) };
				final Map<String,Schema.SObjectField> mapFields = Schema.SObjectType.Account.fields.getMap();
				for(Schema.FieldSetMember fsm : accountMergeFields) {
					Schema.DescribeFieldResult describe = mapFields.get(fsm.getFieldPath()).getDescribe();
					if(describe.isAccessible()) {
						fieldSelectList.add(new FieldSelect(fsm,accounts,describe.isUpdateable()));
					}
				}
			}
			return fieldSelectList;
		}
		private set;
	}

	public PageReference selectAll() {
		PageReference retval = null;
		try {
			for(FieldSelect fs : fieldSelectList) {
				if(fs.accountId != null && fs.accountId != defaultAccountId) {
					fs.accountId = defaultAccountId;
				}
			}
		}
		catch(Exception ex) {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, ex.getMessage()));
		}
		return null;
	}

	/**
	 * Called to merge accounts.
	 * @retval PageReference to view the CDH_Party__c record if successful, otherwise null.
	 */
	public PageReference mergeAccounts() {
		System.debug('mergeAccounts accounts.size()='+accounts.size());
		PageReference retval = null;
		if(accounts != null && accounts.size() > 1) {
			Map<Id,Account> accountMap = new Map<Id,Account>(accounts);
			System.debug('mergeAccounts fieldSelectedList[0].accountId='+fieldSelectList[0].accountId);
			Account master = accountMap.remove(fieldSelectList[0].accountId);
			System.debug('mergeAccounts master='+master);
			if(master != null) {
				master = new Account(Id=master.Id);
				for(FieldSelect fs : fieldSelectList) {
					if(fs.accountId != null && fs.accountId != master.Id) {
						Schema.FieldSetMember fsm = fs.getFieldSetMember();
						if(fsm != null) {
							String fieldPath = fsm.getFieldPath();
							if(fieldPath != null) {
								Account acc = accountMap.get(fs.accountId);
								if(acc != null) {
									master.put(fieldPath,acc.get(fieldPath));
								}
							}
						}
					}
				}
				List<Account> duplicates = new List<Account>();
				for(Id accountId : accountMap.keySet()) {
					duplicates.add(new Account(Id=accountId));
				}
				try {
					System.debug('mergeAccounts merge');
					Database.merge(master,duplicates,true);
					retval = cancel();
					System.debug('mergeAccounts retval='+retval);
					accounts = null;
				}
				catch(Exception ex) {
					ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, ex.getMessage()));
				}
			}
		}
		System.debug('mergeAccounts exited');
		return retval;
	}

	/**
	 * Called to navigate back the the CDH_Party__c view page.
	 * @retval PageReference to view the CDH_Party__c record.
	 */
	public PageReference cancel() {
		String retURL = ApexPages.currentPage().getParameters().get('retURL');
		if(retURL == null) {
			retURL = '/';
			if(!accounts.isEmpty() && accounts[0].CDH_Party_Name__c != null) {
				retURL += accounts[0].CDH_Party_Name__c;
			}
		}
		Integer i = retURL.indexOf('#');
		String anchor = null;
		if(i > 0) {
			anchor = retURL.substring(i+1);
			retURL = retURL.substring(0,i);
		}
		PageReference retval = new PageReference(retURL);
		if(anchor != null) {
			retval.setAnchor(anchor);
		}
		retval.setRedirect(true);
		return retval;
	}

	public Class FieldSelect {
		private final Schema.FieldSetMember fsm;
		private final Boolean updateable;

		private FieldSelect(Schema.FieldSetMember fsm,List<Account> accounts,Boolean updateable) {
			this.fsm = fsm;
			if(updateable && ! accounts.isEmpty()) {
				if(fsm == null) {
					accountId = accounts[0].Id;
				}
				else if(! fsm.getRequired()) {
					Object value0 = accounts[0].get(fsm.getFieldPath());
					for(Account acc : accounts) {
						Object value = acc.get(fsm.getFieldPath());
						if(value != value0) {
							accountId = acc.Id;
							if(value0 != null) {
								accountId = accounts[0].Id;
							}
							break;
						}
					}
				}
			}
		}

		public Schema.FieldSetMember getFieldSetMember() {
			return fsm;
		}

		public Id accountId {
			get;
			set;
		}
	}
}