public without sharing class PFSearchContext {

	private PFSearchForm__c	form;
	public PFGeoBounds		boundingBox {get; set;}


	public PFSearchContext(PFSearchForm__c theForm) {
		form = theForm;
		if (form.PageSize__c == null) {
			form.PageSize__c = PFUtils.getDefaultPicklistValue(PFSearchForm__c.PageSize__c.getDescribe().getPicklistValues());
		}
		if (form.NameOrKeywords__c == null) {
			form.NameOrKeywords__c = '';
		}
		else {
			form.NameOrKeywords__c = form.NameOrKeywords__c.trim();
		}
	}

	public String[] specialization {
		get {
			return PFUtils.get(form.Specialization__c);
		}
	}

	public String country {
		get {
			return form.Country__c;
		}
	}

	public String state {
		get {
			return scrub(form.StateProvince__c);
		}
	}

	public String city {
		get {
			return scrub(form.City__c);
		}
	}

	public String applicationType {
		get {
			return form.ApplicationType__c;
		}
	}

	public String industryFocus {
		get {
			return form.IndustryFocus__c;
		}
	}

	public String skills {
		get {
			return form.Skills__c;
		}
	}

	public Integer pageSize {
		get {
			return Integer.valueOf(form.PageSize__c);
		}
	}

	public String keywords {
		get {
			return scrub(form.NameOrKeywords__c);
		}
	}

	public String partnerType {
		get {
			if (form.PartnerType__c != null) {
				return form.PartnerType__c;
			}
			return '';
		}
	}

	public String[] partnerTier {
		get {
			if (form.PartnerTier__c != null) {
				return form.PartnerTier__c.split(';');
			}
			return new String[0];
		}
	}

	public String latitude {
		get {
			return form.Latitude__c;
		}
	}

	public String longitude {
		get {
			return form.Longitude__c;
		}
	}

	public String distance {
		get {
			return form.Distance__c;
		}
	}

	public Boolean isMiles {
		get {
			return 'Miles'.equals(form.DistanceMetric__c);
		}
	}

	public String globalRegion {
		get {
			String globalRegion = form.GlobalRegion__c;
	    	if (globalRegion != null){
	    		globalRegion = globalRegion.split('[()]')[1];
	    	}
	    	return globalRegion;
		}
	}

	public String[] trainingTypes {
		get {
			if (form.TrainingType__c != null && form.TrainingType__c.length() > 0) {
				return form.TrainingType__c.split(';');
			}
			return new String[0];
		}
	}

	public Boolean isProximitySelected {
		get {
			return form.ProximitySearch__c != null && form.ProximitySearch__c;
		}
	}

	public Boolean hasJBossProducts {
		get {
			if (form.PlatformsSupported__c != null) {
				return form.PlatformsSupported__c.contains('JBoss');
			}
			return false;
		}
	}

	public Boolean hasPlatformProducts {
		get {
			if (form.PlatformsSupported__c != null) {
				return form.PlatformsSupported__c.contains('Red Hat Enterprise Linux');
			}
			return false;
		}
	}

	public Boolean hasProximityResults {
		get {
			if (isProximitySearch()) {
				return boundingBox != null;
			}
			return false;
		}
	}

	public Boolean hasCountrySearch {
		get {
			return !PFUtils.isEmpty(country);
		}
	}

	public Boolean isProximitySearch() {
		return isProximitySelected && (!PFUtils.isEmpty(latitude) && !PFUtils.isEmpty(longitude) && !PFUtils.isEmpty(distance));
	}

	public Boolean isLocationSearch() {
		return isProximitySelected && (!PFUtils.isEmpty(country) || !PFUtils.isEmpty(state) ||	!PFUtils.isEmpty(city));
	}

	static private String scrub(String str) {
		if (str == null) {
			return str;
		}
		return str.replaceAll('\\\\', '');
	}

}