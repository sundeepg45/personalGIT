trigger PartnerLocationGeocoder on Partner_Location__c (after insert, after update) {

    //
    // Salesforce does not allow future methods in batch mode, so just bail out if needed
    //
    if (System.isBatch()) return;

    for (Partner_Location__c loc : Trigger.new) {
        if (!loc.Convert__c) {
        	//System.debug('[mark]--------- skipping');
        	continue; // || loc.PartnerValidated__c || loc.Validated__c) continue;
        }
      	//System.debug('[PF]-------------- geocoding ' + loc.Id);
        GeocodingUtil.geocodeLocation(loc.Id);
    }
}