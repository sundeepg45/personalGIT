/**
 * This class will initiate the insert/update logic for copying data from legacy Opportunity Partner object to the new object.
 * As per User Story US56675
 *
 * @version 2014-12-16
 * @author Pankaj Banik   <pbanik@deloitte.com>
 * 2014-10-31 - Created
 * Bill C. Riemers <briemers@redhat.com>
 * 2014-12-18 - Added in OpportunityPartners__c field into the opportunity query and removed most of the deleteLegacyPartnersFromNewPartners code
 * 2014-12-16 - Revised not to recursively use future calls...
 */
public class OpportunityPartner_Trigger_Handler
{

	//This method fetches the list of new Opportunity Partner records and sets the values to null for reprocessing on Delete event
	public static void deleteLegacyPartnersFromNewPartners(map<Id,OpportunityPartner__C> oldOpportunityPartnersMap){
		Set<Id> opportunityIds = new Set<Id>();
		for (OpportunityPartner__c legacyPartner : oldOpportunityPartnersMap.values()) {
			opportunityIds.add(legacyPartner.opportunity__c);
		}
		System.Debug('opportunityIds1---->'+opportunityIds);
		copyOpportunityPartnersData (opportunityIds);
	}

	public static Map<Id,String> copyOpportunityPartnersData(Set<Id> opportunityIds){
		Map<Id,String> errorMap = new Map<Id,String>();
		if(System.isFuture() || System.isBatch()) {
			errorMap = copyOpportunityPartnersDataNoFuture(opportunityIds);
		}
		else {
			// future calls swallow errors.  Yuck!
			copyOpportunityPartnersDataFuture(opportunityIds);
		}
		return errorMap;
	}

	@future
	private static void copyOpportunityPartnersDataFuture(Set<Id> opportunityIds){
		copyOpportunityPartnersDataNoFuture(opportunityIds);
	}

	private static Map<Id,String> copyOpportunityPartnersDataNoFuture(Set <Id> opportunityIds) {
		//List to store opportunity and its Partner record details.
		List<Opportunity> opportunities = new List <Opportunity>();

		System.Debug('opportunityIds2---->'+opportunityIds);

		//retrieve opportunity and its corresponding partner data.
		opportunities = [Select OpportunityNumber__c , 
						Opportunity_Partners__c,
						(SELECT Opportunity__c,Opportunity__r.Name,Partner__c,PartnerTier__r.Name,PartnerType__r.Name,RelationshipType__c FROM OpportunityPartners2__r) 
						FROM Opportunity WHERE ID IN: opportunityIds ];

		System.Debug('opportunities ---->'+opportunities);

		//Invoke the method for Opportunity Partner update
		Map<Id,String> retval = ProcessOpportunityPartnerClass.processOpportunityPartners(opportunities);

		Integer myDMLLimit = Limits.getDMLStatements();
		System.debug('Inside Trigger---->'+myDMLLimit );
		return retval;
	}

	// This method invokes the insert/update logic for copying data from legacy Opportunity Partner object to the new object.   
	public static void copyOpportunityPartnerFromLegacyPartner(map<Id,OpportunityPartner__C> newOpportunityPartnersMap){
		Set<Id> opportunityIds = new Set<Id>();
		for (OpportunityPartner__c legacyPartner : newOpportunityPartnersMap.values()){
			opportunityIds.add(legacyPartner.opportunity__c);
		}
		System.Debug('opportunityIds---->'+opportunityIds);

		Map<Id,String> errorMap = copyOpportunityPartnersData(opportunityIds);
		for(Id oppId : errorMap.keySet()) {
			newOpportunityPartnersMap.get(oppId).addError(errorMap.get(oppId));
		}
	}
}