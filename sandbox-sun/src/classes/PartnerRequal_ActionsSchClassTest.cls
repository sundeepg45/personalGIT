@isTest
private class PartnerRequal_ActionsSchClassTest {

	static testMethod void testDueIn60() {
		// ISV
		testNotification('testDueIn60', 60, 'Eligible', true, 2, new List<String>{'Partner Notification -60'});
	}

	static testMethod void testDueIn30() {
		// ISV
		testNotification('testDueIn30', 30, 'Eligible', true, 2, new List<String>{'Partner Notification -30'});
	}

	static testMethod void testDueToday() {
		// ISV
		testNotification('testDueToday', 0, 'Eligible', true, 2, new List<String>{'Partner Notification 0'});
	}

	static testMethod void testPastDue15() {
		// Reseller
		testNotification('testPastDue15', 15, 'Eligible', false, 3, new List<String>{'Partner Notification +15', 'Case Created +15'});
	}

	static testMethod void testPastDue30() {
		// Reseller
		testNotification('testPastDue30', -30, 'Eligible', false, 2, new List<String>{'Partner Notification +30'});
	}

	static testMethod void testPastDue90() {
		// Reseller
		testNotification('testPastDue90', -90, 'Completed', false, 0, new List<String>());
	}

/*
	static void testNotification(Integer dueIn, String status, boolean isISV, Integer expectedLogEntries, List<String> expectedEventTypes){
		String ptype = 'ISV';
		if (!isISV) ptype = 'RESELLER';
		Account account = [
			select	Id
			from	Account
			where	IsPartner = true
			and		Finder_Partner_Type__r.HierarchyKey__c = :'PARTNER_TYPE.' + ptype
			and		Finder_Partner_Tier__r.HierarchyKey__c = :'PARTNER_TIER.READY'
			and		Global_Region__c = 'NA'
			limit	1
		];
		account.RequalificationDate__c = System.today().addDays(dueIn);
    	account.RequalStatus__c = status;
        update account;

		PartnerRequal_ActionsSchClass c = new PartnerRequal_ActionsSchClass();
		c.testMode = True;
		c.run();
	}
*/

	static void testNotification(String uniqueName, Integer dueIn, String status, boolean isISV, Integer expectedLogEntries, List<String> expectedEventTypes){
		System.debug('[requal]-------------------- time check 1');
		User adminuser = PartnerTestUtils.getAdminUser();
//    	Account account = PartnerTestUtils.makeAccount('PartnerRequalificationSchedMinus60Test', adminuser);
    	Account account = PartnerTestUtils.makeNonpartnerAccount('PartnerRequalificationSchedMinus60Test', adminuser);
    	account.IsPartner = true;
    	account.RequalificationDate__c = System.today().addDays(dueIn);
    	if (isISV) {
    	   account.PartnerStatuses__c = 'Ready - ISV';
    	}
    	else {
    		account.PartnerStatuses__c = 'Ready - Reseller';
    	}
        update account;
		System.debug('[requal]-------------------- time check 2');

        account = PartnerTestUtils.refreshAccount(account);
        Contact contact1 = PartnerTestUtils.makeContact(account.Id, 'isISV' + isISV + 'dueIn' + dueIn + 'User1' + uniqueName);
        insert contact1;
		System.debug('[requal]-------------------- time check 3');
        User user1 = PartnerTestUtils.makeUser(account, contact1);
        insert user1;
//        Contact contact2 = PartnerTestUtils.makeContact(account.Id, 'isISV' + isISV + 'dueIn' + dueIn + 'User2');
//        insert contact2;
//		System.debug('[requal]-------------------- time check 4');
//        User user2 = PartnerTestUtils.makeUser(account, contact2);
//        insert user2;
        if (isISV){
        	PartnerTestUtils.makeAccountISV(account.Id);
        } else {
        	PartnerTestUtils.makeAccountReseller(account.Id);
        }
		System.debug('[requal]-------------------- time check 5');
    	account.RequalStatus__c = status; //'Eligible';
        update account;
		System.debug('[requal]-------------------- time check 6');

		PartnerRequal_ActionsSchClass c = new PartnerRequal_ActionsSchClass();
		c.testMode = True;
		c.run();
		System.debug('[requal]-------------------- time check 7');

		//List<Partner_Requalification_Log__c> logs = getLogs(account, expectedEventTypes);
		//System.assert(logs.size() == expectedLogEntries);
		System.debug('[requal]-------------------- time check 8');
	}


	static private List<Partner_Requalification_Log__c> getLogs(Account account, List<String> expectedEventTypes){
		List<Partner_Requalification_Log__c> logs = new List<Partner_Requalification_Log__c>();
		try {
			logs = [select Id,
						Event_Date__c,
						Event_Type__c,
						User__c
				from Partner_Requalification_Log__c
				where Account__c = :account.Id
					and Event_Type__c in :expectedEventTypes];
		} catch (Dmlexception dE){
			// Eat Error
		}
		return logs;
	}
}