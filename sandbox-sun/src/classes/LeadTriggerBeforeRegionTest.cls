/**
 * This class contains unit tests for validating the LeadTriggerBeforeRegion class.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * @author Bill C Riemers <briemers@redhat.com>
 * @version 2012-07-19
 * 2012-07-19 - update to api version 24 and extending the abstract trigger class
 * 2011-09-01 - Created
 * 2012-03-05 - refactored into sub classes
 * Scott Coleman <scoleman@redhat.com>
 * 2013-02-04 - Added test for region()
 */
@isTest
private class LeadTriggerBeforeRegionTest {
	static Lead createLead() {
		return LeadTriggerBeforeTest.createLead();
	}

	static Lead_SuperRegion_Mapping__c createLeadSuperRegionMapping() {
		return new Lead_SuperRegion_Mapping__c(
			Country__c = 'Narnia',
			Country_Iso_Code__c = 'N-',
			SuperRegion__c = 'LEWIS');
	}

	static Region__c createRegionMapping() {
		return new Region__c(
			Name = 'Test Region',
			Country__c = 'Narnia',
			Region__c = 'Region X',
			Sub_Region__c = 'Subregion Y');
	}

	@isTest
	static void countryTest() {
		Lead lead = createLead();
		LeadTriggerBeforeRegion t = new LeadTriggerBeforeRegion(null,new List<Lead>{lead});
		System.assert(t.countries.contains(lead.Country.toUpperCase()));
	}

	@isTest
	static void superRegionMapTest() {
		Lead lead = createLead();
		Lead_SuperRegion_Mapping__c leadSuperRegionMapping = createLeadSuperRegionMapping();
		insert leadSuperRegionMapping;
		LeadTriggerBeforeRegion t = new LeadTriggerBeforeRegion(null,new List<Lead>{lead});
		t.countries = new Set<String>{leadSuperRegionMapping.Country__c.toUpperCase()};
		System.assertEquals(leadSuperRegionMapping.Id,t.superRegionMap.get(leadSuperRegionMapping.Country_Iso_Code__c).Id);
		System.assertEquals(leadSuperRegionMapping.Id,t.superRegionMap.get(leadSuperRegionMapping.Country__c.toUpperCase()).Id);
	}

	@isTest
	static void superRegion() {
		Lead lead = createLead();
		Lead_SuperRegion_Mapping__c leadSuperRegionMapping = createLeadSuperRegionMapping();
		LeadTriggerBeforeRegion t = new LeadTriggerBeforeRegion(null,new List<Lead>{lead});
		t.superRegionMap = new Map<String,Lead_SuperRegion_Mapping__c>{
			leadSuperRegionMapping.Country_Iso_Code__c => leadSuperRegionMapping,
			leadSuperRegionMapping.Country__c.toUpperCase() => leadSuperRegionMapping };
		t.superRegion();
		System.assertEquals(leadSuperRegionMapping.SuperRegion__c,lead.Super_Region__c);
		t.superRegionMap.clear();
		t.superRegion();
		System.assertEquals('',lead.Super_Region__c);
	}

	@isTest
	static void region() {
		Region__c region = createRegionMapping();
		insert region;
		Lead lead = createLead();
		lead.Super_Region__c = 'EMEA';
		Lead lead2 = createLead();
		lead2.Super_Region__c = 'NA';
		LeadTriggerBeforeRegion t = new LeadTriggerBeforeRegion(null, new List<Lead>{lead,lead2});
		t.region();
		System.assertEquals('Region X',lead.Region__c);
		System.assertEquals(null,lead2.Region__c);
	}

	@isTest
	static void subRegion() {
		Lead lead = createLead();
		Lead lead2 = createLead();
		lead2.Country = lead2.Country_of_Order__c = 'United States';
		lead2.State = 'NC';

		
		//Country__c country =  new Country__c(Name = 'Narnia',Iso3166Alpha2__c='N-',Global_Region__c='EMEA');
		//insert country;
		Country__c country2 =  new Country__c(Name = 'United States',Iso3166Alpha2__c='US',Global_Region__c='NA');
		Database.insert(country2,false);
		country2 = [select Name,Abbreviation__c from Country__c where Abbreviation__c = 'US'];
		Region__c region = new Region__c(Name='Fantasia',country__c = 'Narnia', Sub_Region__c = 'Fantasy Land');
		insert region;
		State__c state = new State__c(Name='North Carolinia',Abbreviation__c = 'NC', SubRegion__c = 'South East', Country__c=country2.Id, FIPSAlpha__c='NC',FIPSNumeric__c=37);
		Database.insert(state,false);
		state = [select Abbreviation__c, SubRegion__c from State__c where Abbreviation__c = 'NC'];
		LeadTriggerBeforeRegion t = new LeadTriggerBeforeRegion(null, new List<Lead>{lead, lead2});

		t.subRegion();
		system.assertEquals(region.sub_region__c, lead.subRegion__c);
		system.assertEquals(state.subRegion__c, lead2.subRegion__c);
		
		//t.countryNameMap.clear();
		t.countrySubRegionMap.clear();
		t.USStateSubRegionMap.clear();
		t.subRegion();
		
		system.assertNotEquals('',lead.subRegion__c);
		system.assertEquals('Fantasy Land',lead.subRegion__c);
		system.assertNotEquals('',lead2.subRegion__c);
		system.assertEquals('South East',lead2.subRegion__c);
	}
}