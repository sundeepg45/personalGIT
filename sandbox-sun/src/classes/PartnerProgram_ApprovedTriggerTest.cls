@isTest(SeeAllData=true)
private class PartnerProgram_ApprovedTriggerTest {

	@isTest static void testApprove() {
        Partner_Program__c program = [
            select  Id, Account__c
            from    Partner_Program__c
            where   Account__r.Finder_Partner_Type_Name__c = 'DISTRIBUTOR'
            limit 1
        ];
        program.Status__c = 'Pending Terms';
        program.Program__c = [select Id from Partner_Program_Definition__c where Program_Category__c = :PartnerConst.CCNSP].Id;
        program.Is_Primary__c = False;
        CCSP_Form__c form = new CCSP_Form__c();
        form.Contact_Email__c = 'masmith@redhat.com';
        form.Account__c = program.Account__c;
        form.Contact_Preferred_Language__c = 'en';
        form.Custom_Terms_Required__c = 'No';
        insert form;
        program.CCSP_Form__c = form.Id;
        update program;
	}


}