trigger AcctPicklistSync on AcctPicklistSync__c (After Insert) {

	List<Account> accounts = new List<Account>();

	for (AcctPicklistSync__c item : Trigger.new) {
		Account acct = [
				select	Id
					 ,	Application_Types__c
					 ,	Hardware_Focus__c
					 ,	Hardware_Platform__c
					 ,	Industry_Focus__c
					 ,	Middleware_Supported__c
					 ,	Operating_System_Supported__c
					 ,	Software_Focus__c
					 ,	Target_Market_Size__c
					 ,  Ownership_Type__c
					 ,	Vertical__c	
				  from	Account
				 where	Id = :item.AccountId__c
			];

		List<PartnerClassification__c> clfnList = new List<PartnerClassification__c>();

		for (PartnerClassification__c clfn : [
				select	Classification__c
				     ,	Classification__r.Name
				     ,  Classification__r.Legacy_Picklist_Value__c
				     ,	Classification__r.Parent__r.Name
				  from	PartnerClassification__c
				 where	Partner__c = :item.AccountId__c
			]) clfnList.add(clfn);

		if (clfnList != null && clfnList.size() > 0) {
			accounts.add(acct);
			
			for (PartnerClassification__c clfn : clfnList) {
				if (clfn.Classification__r.Parent__r.Name == 'App Type') {
					acct.Application_Types__c = appendClfn(acct.Application_Types__c, clfn.Classification__r.Legacy_PickList_Value__c);
				}
				else if (clfn.Classification__r.Parent__r.Name == 'Hardware Focus') {
					acct.Hardware_Focus__c = appendClfn(acct.Hardware_Focus__c, clfn.Classification__r.Legacy_PickList_Value__c);
				}
				else if (clfn.Classification__r.Parent__r.Name == 'Hardware Platform') {
					acct.Hardware_Platform__c = appendClfn(acct.Hardware_Platform__c, clfn.Classification__r.Legacy_PickList_Value__c);
				}
				else if (clfn.Classification__r.Parent__r.Name == 'Industry Markets') {
					acct.Industry_focus__c = appendClfn(acct.Industry_focus__c, clfn.Classification__r.Legacy_PickList_Value__c);
				}
				else if (clfn.Classification__r.Parent__r.Name == 'Middleware Supported') {
					acct.Middleware_Supported__c = appendClfn(acct.Middleware_Supported__c, clfn.Classification__r.Legacy_PickList_Value__c);
				}
				else if (clfn.Classification__r.Parent__r.Name == 'Operating System Focus') {
					acct.Operating_System_Supported__c = appendClfn(acct.Operating_System_Supported__c, clfn.Classification__r.Legacy_PickList_Value__c);
				}
				else if (clfn.Classification__r.Parent__r.Name == 'Ownership') {
					acct.Ownership_Type__c = appendClfn(acct.Ownership_Type__c, clfn.Classification__r.Legacy_PickList_Value__c);
				}
				else if (clfn.Classification__r.Parent__r.Name == 'Software Focus') {
					acct.Software_Focus__c = appendClfn(acct.Software_Focus__c, clfn.Classification__r.Legacy_PickList_Value__c);
				}
				else if (clfn.Classification__r.Parent__r.Name == 'Target Market Size') {
					acct.Target_Market_Size__c = appendClfn(acct.Target_Market_Size__c, clfn.Classification__r.Legacy_PickList_Value__c);
				}
				else if (clfn.Classification__r.Parent__r.Name == 'Vertical Focus') {
					acct.Vertical__c = appendClfn(acct.Vertical__c, clfn.Classification__r.Legacy_PickList_Value__c);
				}
			}
		}
	}

	if (accounts.size() > 0) {
		update accounts;
	}
	
	private String appendClfn(String picklist, String name) {
		if (name == null || name.length() == 0) {
			return picklist;
		}
		if (picklist == null || picklist.length() == 0) {
			picklist = name;
			return picklist;
		}
		String[] values = picklist.split(';');
		if (!contains(values, name)) {
			if (picklist.length() > 0) picklist += ';';
			picklist += name;
		}
		return picklist;
	}

	private boolean contains(String[] values, String target) {
		for (String s : values) {
			if (s == target) {
				return true;
			}
		}
		return false;
	}
}