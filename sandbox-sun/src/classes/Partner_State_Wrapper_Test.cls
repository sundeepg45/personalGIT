@isTest(SeeAllData=true)
public class Partner_State_Wrapper_Test {

	static testmethod void testLoad() {
        Account[] accountlist = [select Id from Account limit 10];
        Partner_State_Wrapper.load(PartnerUtil.getIdSet(accountlist));
        Partner_State_Wrapper.setLegalBlocked(accountlist.get(0).Id, true);
        Partner_State_Wrapper.commitCache();
        Partner_State__c ps = [select Id, Legal_Blocked__c from Partner_State__c where Account__c = :accountlist.get(0).Id];
        System.assert(ps.Legal_Blocked__c == true, 'Expected legal blocked true');
	}
}