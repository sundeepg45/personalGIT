public with sharing class ProgramMigration {

	public void run(String definitionId, String roleHkey) {

		Classification__c clfn = [
			select	Id
			from	Classification__c
			where	HierarchyKey__c = :roleHkey
			limit	1
		];

		PartnerStatus__c[] pslist = [
			select	Id, Partner__c, Partner_Role__c, CreatedById, CreatedDate, Partner__r.Global_Region__c
			from	PartnerStatus__c
			where	Partner_Role__c = :clfn.Id
			and		Manager_Completed__c = True
			and		ActivationStatus__c = 'Active'
		];
		System.debug('>>>>> accounts to migrate: ' + pslist.size());
		
		//Agreement__c theAgreement = [select Id from Agreement__c where Partner_Role__c = :clfn.Id limit 1];

		PartnerAgreement__c[] agreements = [
			select	Id, Agreement__c, Partner__c
			from	PartnerAgreement__c
			where	Partner__c in :PartnerUtil.getStringFieldSet(pslist, 'Partner__c')
			and		Agreement__r.Partner_Role__c = :clfn.Id
		];
		System.debug('>>>>> agreements found: ' + agreements.size());
		Map<ID,PartnerAgreement__c> agreementMap = new Map<ID,PartnerAgreement__c>();
		for (PartnerAgreement__c pa : agreements) agreementMap.put(pa.Partner__c, pa);

		Partner_Program__c[] programs = new List<Partner_Program__c>();
		for (PartnerStatus__c ps : pslist) {
			if (agreementMap.containsKey(ps.Partner__c) == false) {
				// no accepted agreement on file, don't migrate
			System.debug('>>>>> agreement not found for account: ' + ps.Partner__c);
				continue;
			}
			Partner_Program__c program = new Partner_Program__c();
			program.Account__c = ps.Partner__c;
			program.Enroll_Date__c = Date.newInstance(ps.CreatedDate.year(), ps.CreatedDate.month(), ps.CreatedDate.day());
			//program.Program_Contact__c = ps.CreatedById;
			program.Program__c = definitionId;
			program.Status__c = 'Draft';
			programs.add(program);
		}

		if (!programs.isEmpty()) {
			insert programs;
			System.debug('>>>>> programs inserted: ' + programs.size());
			for (Partner_Program__c program : programs) {
				program.Status__c = 'Active';
			}
			update programs;
		}
	}
}