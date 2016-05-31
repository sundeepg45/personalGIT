public with sharing class PartnerCCPFormControllerExt {

	private Partner_CCP_Form__c record;

	public PartnerCCPFormControllerExt(ApexPages.StandardController ctrl) {
		record = (Partner_CCP_Form__c) ctrl.getRecord();
		record = [
			select	Id,
					Cloud_Infrastructure_Type__c,
					Description_of_Services__c,
					Expected_Contract_Close_Date__c,
					Has_Tech_Qualification_Call__c,
					Lead__c,
					Partner__c,
					Moving_Details__c,
					Moving_to_Compliant_CCP__c,
					Notes__c,
					PAD_Details__c,
					Standard_CCP_Documentation__c,
					Regions__c,
					Website__c,
					Type_of_Service__c,
					Cloud_Type_Details__c,
					Cloud_Infrastructure_Details__c,
					Partner__r.Name,
					Partner__r.Owner.Name,
					Lead__r.Name
			from	Partner_CCP_Form__c
			where	Id = :record.Id
		];		
	}
	
	public PageReference submit() {
		if (record.Moving_to_Compliant_CCP__c == 'Yes') {
			if (record.Moving_Details__c == null || record.Moving_Details__c.length() == 0) {
				record.Moving_Details__c.addError('Required');
			}
//				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, '));
//				return null;
//			}
		}
		if (record.Standard_CCP_Documentation__c == 'No') {
			if (record.PAD_Details__c == null || record.PAD_Details__c.length() == 0) {
				record.PAD_Details__c.addError('Required');
				return null;
			}
		}
		update record;
		return new PageReference('/' + record.Id);
	}
	
	public String name {
		get {
			if (record.Partner__c != null) {
				return record.Partner__r.Name;
			}
			else {
				return record.Lead__r.Name;
			}
		}
	}
	
	public String ownerName {
		get {
			if (record.Partner__c != null) {
				return record.Partner__r.Owner.Name;
			}
			return '';
		}
	}

	public PageReference cancel() {
		if (record.Partner__c != null)
			return new PageReference('/' + record.Partner__c);
		else
			return new PageReference('/' + record.Lead__c);
	}
	
	public String getPartnerName() {
		return [select Company from Lead where Id = :record.Lead__c].Company;
	}
	
	public Partner_CCP_Form__c getRecord() {
		return record;
	}
}