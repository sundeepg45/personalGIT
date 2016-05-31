/**
 * This class replaces all before insert and before update lead triggers.  The
 * processTrigger method is invoked by the Lead_Before trigger and in turn invokes
 * all the methods of this class.  This gives us a way to control the order in
 * which the code logic is invoked, as well as allowing other class features such
 * as shared data, constant values, and regorious test coverage.
 * <p>
 * The Trigger object should never be directly referenced inside this class, as
 * that would make it impossible to substituting values inside test methods.
 * </p>
 *
 * @author Bill C Riemers <briemers@redhat.com>
 * @version 2012-07-19
 * 2012-07-19 - update to api version 24 and extending the abstract trigger class
 * 2012-03-05 - Split into a subclass
 * 2011-12-08 - Modified insertLead method to by-pass non-GLM leads
 * 2011-09-01 - Created
 * Bryan Bosely <bbosely@redhat.com>
 * 2011-11-?? - Added insertLead trigger method
 * 2011-09-17 - Added method to determine lead sub-region
 * Scott Coleman <scoleman@redhat.com>
 * 2012-12-12 - updated subregion mapping to eliminate join through the Country table
 * 2013-02-04 - added region mapping (for EMEA only)
 */
public without sharing class LeadTriggerBeforeRegion extends LeadTriggerBefore {
	/** BooleanSetting__c key to enable the superRegion trigger method. */
	public static final String SUPER_REGION_SETTING = 'Lead_Before.superRegion';
	/** BooleanSetting__c key to enable the region trigger method. */
	public static final String REGION_SETTING = 'Lead_Before.region';	
	/** BooleanSetting__c key to enable the superRegion trigger method. */
	public static final String SUB_REGION_SETTING = 'Lead_Before.subRegion';

	/**
	 * This constructor is normally called from the processTrigger method and
	 * test methods.
	 */
	public LeadTriggerBeforeRegion(Map<Id,Lead> xoldMap,List<Lead> xnewList) {
		super(xoldMap,xnewList);
	}

	/**
	 * A set of all Country values in the new lead objects.
	 */
	public Set<String> countries {
		get {
			if(countries == null) {
				countries = new Set<String>();
				for(Lead ld : newList) {
					if(ld.Country_of_Order__c != null) {
						countries.add(ld.Country_of_Order__c.trim().toUpperCase());
					}
					if(ld.Country != null) {
						countries.add(ld.Country.trim().toUpperCase());
					}
				}
				countries.remove('');
			}
			return countries;
		}
		set;
	}
	
	/**
	 * A set of all State values in the new lead objects.
	 */
	public Set<String> states {
		get {
			if(states == null) {
				states = new Set<String>();
				for(Lead ld : newList) {
					if(ld.State != null) {
						states.add(ld.State.trim().toUpperCase());
					}
				}
				states.remove('');
			}
			return states;
		}
		set;
	}
	
	private List<Region__c> regionList {
		get {
			if(regionList == null) {
				regionList = new List<Region__c>();
				if(!countries.isEmpty()) {
					regionList = [select country__c, Region__c, Sub_Region__c
									from Region__c
									where country__c in :countries];
				}
			}
			return regionList;
		}
		set;
	}

	/**
	 * A mapping of country abbreviation to super region for all countries
	 * in the countries set, based on the Lead_SuperRegion_Mapping__c table.
	 */
	public Map<String,Lead_SuperRegion_Mapping__c> superRegionMap {
		get {
			if(superRegionMap == null) {

				superRegionMap = new Map<String, Lead_SuperRegion_Mapping__c>();
				if(!countries.isEmpty()) {
					for(Lead_SuperRegion_Mapping__c region : [
						Select CountryFormula__c, Country_Iso_Code__c, SuperRegion__c
						from Lead_SuperRegion_Mapping__c
						where CountryFormula__c IN :countries 
							OR (Country_Iso_Code__c IN :countries 
								AND CountryFormula__c like '%_%' ) ] )
					{
						superRegionMap.put(region.CountryFormula__c, region);
						superRegionMap.put(region.Country_Iso_Code__c, region);
					}
				}
			}
			return superRegionMap;
		}
		set;
	}
	
	/**
	 * A mapping of country names to sub region based on the Region__c table.
	 *
	 * Note: US subregions are not included in the Region__c object or this map. See USStateSubRegionMap below.
	 */
	public Map<String,String> countrySubRegionMap {
		get {
			if(countrySubRegionMap == null) {
				countrySubRegionMap = new Map<String,String>();
				for(Region__c region : regionList)
				{
					countrySubRegionMap.put(region.country__c.trim().toUpperCase(), region.Sub_Region__c);
				}
			}
			return countrySubRegionMap;
		}
		set;
	}

	/**
	 * A mapping of state abbreviations to sub region for the United States,
	 * based on the State__c table.
	 */
	public Map<String,String> USStateSubRegionMap {
		get {
			if(USStateSubRegionMap == null) {

				USStateSubRegionMap = new Map<String,String>();
				if(!states.isEmpty()) {
					for(State__c state : [
						SELECT Abbreviation__c, Name, SubRegion__c
						FROM State__c
						WHERE (Abbreviation__c IN :states OR Name IN :states) 
						AND Region__c = 'NA' ] )
					{
						USStateSubRegionMap.put(state.Abbreviation__c, state.SubRegion__c);
						USStateSubRegionMap.put(state.Name.trim().toUpperCase(), state.SubRegion__c);
					}
				}
			}
			return USStateSubRegionMap;
		}
		set;
	}

	public Map<String,String> countryRegionMap {
		get {
			if(countryRegionMap == null) {
				countryRegionMap = new Map<String,String>();
				for(Region__c region : regionList)
				{
					countryRegionMap.put(region.country__c.trim().toUpperCase(), region.Region__c);
				}
			}
			return countryRegionMap;
		}
		set;	
	}

	// Date Implemented: 9/30/09
	// Modified On: 04/12/10
	// Project: App Maintainance
	// Refactored into this class on 08/18/2011
	/**
	 * This replacement for the SuperRegion trigger will map super regions on the 
	 * lead based on address country based on the Lead SuperRegion Mapping table.
	 */
	public void superRegion() {
		for(Lead ld :newList) {
			String ldCountry = ld.Country;
			if(ldCountry != null) {
				ldCountry = ldCountry.trim().toUpperCase();
			}
			Lead_SuperRegion_Mapping__c ldRegion = superRegionMap.get(ldCountry);
			//Set Super Region field to blank if Country on Lead is blank
			String superRegion = '';
			if(ldRegion != null) {
				//If match found then get Super Region value from Super Region map and assign this value to Super Region field on Lead
				superRegion = ldRegion.SuperRegion__c;
			}
			// If this field is being history tracked, we only want to update it on an 
			// actual change.
			if(ld.Super_Region__c != superRegion) {
				ld.Super_Region__c = superRegion;
			}
		}
	}

	/**
	 * Set the region based on the country of order utilizing the region map.
	 */
	public void Region() {
		for(Lead ld : newList) {
			String ldCountry = ld.Country_of_Order__c;
			String superRegion = ld.Super_Region__c;
			String region = ld.Region__c;
			// for now, only map Region for EMEA
			if(superRegion != 'EMEA')
				continue;
			if(ldCountry != null) {
				ldCountry = ldCountry.trim().toUpperCase();
				region = countryRegionMap.get(ldCountry);
				if(region != null && ld.Region__c != region) {
					ld.Region__c = region;
				}
			}
		} 
	}

	/**
	 * Set the sub region based on the country or order utilizing the region map.
	 * When the country is US utilize the state map.
	 */
	public void subRegion() {
		for(Lead ld :newList) {
			
			String subRegion = ld.SubRegion__c;
			String ldCountry = ld.Country_of_Order__c;
			String ldState = ld.State;
			
			//
			// The Partner center team has a requirement to set the value "Fed Sled" into the subRegion__c field.
			// We do not want to overwrite this value.
			//
			
			if ( subRegion == 'Fed Sled' )
				continue;
			
			
			if(ldCountry != null) {
				ldCountry = ldCountry.trim().toUpperCase();
				System.debug('--Lead Country: ' + ldCountry);
			}
			
			if(ldState != null) {
				ldState = ldState.trim().toUpperCase();
				System.debug('--Lead State: ' + ldState);
			}


			if (ldCountry == 'US' || ldCountry == 'UNITED STATES') {
				String stateSubRegion = USStateSubRegionMap.get(ldState);
				if (stateSubRegion != null) {
					subRegion = stateSubRegion;
				} 
			}
			else if (ldCountry != null) {
				String countryname = ldCountry;
				System.debug('--countryName: ' + countryName);
				
				if (countryName != null) {
					String countrySubRegion = countrySubRegionMap.get(countryName.trim().toUpperCase());
					System.debug('--CountrySubRegion: ' + countrySubRegion );
					
					if (countrySubRegion != null) {
						subRegion = countrySubRegion;
					}
				} 
			}
			
			// If this field is being history tracked, we only want to update it on an 
			// actual change.
			
			if(ld.SubRegion__c != subRegion) {
				ld.SubRegion__c = subRegion;
			}
		}
	}

	/**
	 * This method is called from the Lead_Before trigger to invoke all the methods
	 * of this class, to obsolete the need for individual before triggers.  The primary
	 * reason to place all the triggers in a class is so we control the order in which
	 * the triggers are invoked.
	 *
	 * @param xoldMap the immutable map of previous Lead objects as in Trigger.oldMap.
	 * @param xnewList the list of new Lead objects as in Trigger.new
	 */
	public static void processTrigger(Map<Id,Lead> xoldMap,List<Lead> xnewList) {
		final LeadTriggerBeforeRegion beforeTrigger = new LeadTriggerBeforeRegion(xoldMap,xnewList);
		if(AbstractTrigger.isActive(SUPER_REGION_SETTING,true)) {
			beforeTrigger.superRegion();
		}
		if(AbstractTrigger.isActive(REGION_SETTING,true)) {
			beforeTrigger.Region();
		}		
		if(AbstractTrigger.isActive(SUB_REGION_SETTING,true)) {
			beforeTrigger.subRegion();
		}
	}
}