@isTest(SeeAllData = true)
private class PartnerProgram_BlockEditCDHMerge_Test {

	@isTest static void test() {

		List<Partner_Program__c> programs = [
			select 	Id,
					IsVisible__c,
					Account__c,
					Account__r.CDH_Party_Name__c,
					Account__r.CDH_Party_Name__r.Active__c
			from 	Partner_Program__c
			where  	Account__r.CDH_Party_Name__r.Active__c = true
		];

		if (programs.size() > 0) {
			Partner_Program__c program = programs[0];
			CDH_Party__c cdhParty = [
				select 	Id,
						Active__c
				from 	CDH_Party__c
				where 	Id = :program.Account__r.CDH_Party_Name__c
			];
			cdhParty.Active__c = false;
			update cdhParty;

			program.IsVisible__c = !program.IsVisible__c;

			try {
				update program;
			} catch (DmlException e) {
				if (!e.getMessage().contains(System.Label.PartnerProgram_CDH_Merge_Block_Error)) {
					throw new MyException(e.getMessage());
				}
			}

			try {
				delete program;
			} catch (DmlException e) {
				if (!e.getMessage().contains(System.Label.PartnerProgram_CDH_Merge_Block_Error)) {
					throw new MyException(e.getMessage());
				}
			}
		}
	}

	public class MyException extends Exception {}
}