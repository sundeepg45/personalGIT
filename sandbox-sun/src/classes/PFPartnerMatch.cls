public virtual without sharing class PFPartnerMatch {
	public String		partnerName			{get; private set; }
	public String  		briefDesc		    {get; private set; }
	public String		partnerAlias		{get; private set; }
	public Boolean		showAlias			{get; private set; }
	public String[]		specializations		{get; private set; }
	public Partner_Program__c[]		programs			{get; private set; }
	public String		partnerType			{get; private set; }
	public String		partnerTier			{get; private set; }
	public Id			logoAttachmentId 	{get; private set; }
	public Id			partnerId 			{get; private set; }
	public String		website 			{get; private set; }
	public String		accountPhone 		{get; private set; }
	public String		stateName 			{get; private set; }
	public String		countryName			{get; private set; }
	public Partner_Location__c primaryLocation	{get; private set; }
	public Partner_Location__c locationMatch	{get; private set;}
	public String[]		skills				{get; private set; }


	public PFPartnerMatch(Account acct, Id theLogo, Partner_Location__c primLoc, Partner_Location__c locMatch) {
		partnerName = acct.Name;
		partnerAlias = acct.Account_Alias_Name__c;
		showAlias = acct.AliasPublicViewable__c;
		partnerId = acct.Id;
		logoAttachmentId = PFUtils.get(theLogo, null);
		specializations = PFUtils.get(acct.Select_Specialization_s__c);
		website = PFUtils.get(acct.Website, null);
		if (website != null && !website.startsWith('http')){
			website = 'http://' + website;
		}
		decodeTypeTier(acct);
		primaryLocation = primLoc;
		locationMatch = locMatch;
		accountPhone = acct.Phone;
		if (locationMatch != null && locationMatch.website__c != null && !locationMatch.website__c.startsWith('http://')) {
			locationMatch.website__c = 'http://' + locationMatch.website__c;
		}
		Partner_Location__c theLoc = primLoc;
		if (locMatch != null) {
			theLoc = locMatch;
		}
		stateName = theLoc.State_Province__c;
		countryName = theLoc.Country__c;
		if (acct.Partner_Skill__c == null) {
			skills = new String[0];
		}
		else {
			skills = acct.Partner_Skill__c.split(';');
		}
		Country__c[] country = [select Id, Name from Country__c where Abbreviation__c = :theLoc.Country__c];
		if (!PFUtils.isEmpty(country)) {
			countryName = country[0].Name;
			State__c[] state = [
				select	Name
				  from	State__c
				 where	Country__c = :country[0].Id
				  and	Abbreviation__c = :theLoc.State_Province__c
			];
			if (!PFUtils.isEmpty(state)) {
				stateName = state[0].Name;
			}
			else {
				System.debug('[PF]------------- did not find state ' + theLoc.State_Province__c);
			}
		}
		else {
			System.debug('[PF]------------- did not find country ' + theLoc.Country__c);
		}

		programs = [select Id, Name from Partner_Program__c where Account__c = :acct.Id and Status__c = 'Active'];

		briefDesc = acct.Description_of_Business__c;
		if (briefDesc != null && briefDesc.length() > 200) {
			briefDesc = briefDesc.abbreviate(200);
			briefDesc = String.escapeSingleQuotes(briefDesc);
		}
	}

	public String getSpecializationsString() {
		if (specializations != null && specializations.size() > 0) {
			return PartnerUtil.joinArray(specializations, ',');
		}
		return '';
	}

	private void decodeTypeTier(Account acct) {
		partnerType = null;
		partnerTier = null;
		if (!PFUtils.isEmpty(acct.PartnerStatuses__c)) {
			String[] pslist = acct.PartnerStatuses__c.split(';');
			if (pslist.size() > 0) {
				String[] parts = pslist[0].split(' - ');
				if (parts != null && parts.size() > 1) {
					partnerTier = parts.get(0).trim();
					if (partnerTier == 'Affiliated'){
						partnerTier = '';
					}
					partnerType = parts.get(1).trim();
					if (partnerType == 'Reseller'){
						partnerType = System.Label.Onboarding_Register_Partner_PicklistOption_Reseller;
					}
				}
			}
		}
	}
}