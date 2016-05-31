public with sharing class AccountStatusSummaryController {

	public  Account myAccount {get; set; }
	public Partner_State__c myPartnerState { get; set; }

    public AccountStatusSummaryController(ApexPages.StandardController stdController) {
        this.myAccount = (Account) stdController.getRecord();
		myAccount = [	select  Id,
								Finder_Partner_Type_Name__c,
								Finder_Partner_Tier_Name__c,
								RequalStatus__c,
								RequalificationDate__c,
								Requalification_Extended__c,
								Renewal_Date__c,
								Renewal_Month_and_Day__c,
								Partner_Program_Requirements__c
						from 	Account
						where 	Id = :myAccount.Id
					];
		Partner_State__c[] states = [select Id, Legal_Blocked__c, Requal_Lockout_Exempt__c from Partner_State__c where Account__c = :myAccount.Id];
		if (!states.isEmpty()) {
			myPartnerState = states.get(0);
			System.debug('***** [debug] ***** legal blocked = ' + myPartnerState.Legal_Blocked__c);
		}
    }

	public Boolean hasState {
		get {
			return myPartnerState != null;
		}
	}
}