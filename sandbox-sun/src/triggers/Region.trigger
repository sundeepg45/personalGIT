/**
 * @author Unknown
 * @version 2012-05-10
 * Unknown date - Created
 * 2012-05-08, Scott Coleman <scoleman@redhat.com> - Removed bypass for deployment and 
 *   pushed test data creation into test class. 
 * 2012-05-10, Scott Coleman <scoleman@redhat.com> - Further updates to improve clarity
 *   of trigger code based on code review feedback.
 */
trigger Region on Opportunity (before insert, before update)
{
    Set<String> countries = new Set<String>();
    
    for(Opportunity opp : Trigger.new) {
        if (opp.Country_of_Order__c != null) {
            countries.add(opp.Country_of_Order__c.toUpperCase());
        }
    }

    //now get the countries for the region.    
    // populate the region, sub region and super region
    if (!countries.isEmpty()) {
        Map<String, Region__c> regionMap = new Map<String, Region__c>();
        Region__c[] regions= [select Country__c, Region__c, Sub_Region__c, Super_Region__c from Region__c where Country__c IN :countries];
        for(Region__c region: regions) {
            regionMap.put(region.Country__c.toUpperCase(),region);
        }

        for(Opportunity opp : Trigger.new) {
            //populate values in opportunity
            if(opp.Country_of_Order__c != null && regionMap.containsKey(opp.Country_of_Order__c.toUpperCase())) {
                Region__c oppRegion = regionMap.get(opp.Country_of_Order__c.toUpperCase());
                if (oppRegion != null) {
                    if (opp.Region__c != oppRegion.Region__c) {
                        opp.Region__c = oppRegion.Region__c;
                    }
                    if (opp.SubRegion__c != oppRegion.Sub_Region__c) {
                        opp.SubRegion__c = oppRegion.Sub_Region__c;
                    }
                    if (opp.Region_tmp__c != oppRegion.Region__c) {
                        opp.Region_tmp__c = oppRegion.Region__c;
                    }
                    if(oppRegion.Super_Region__c == 'APAC' && opp.Region2__c != '1') {
                        opp.Region2__c = '1';
                    }
                    else if(oppRegion.Super_Region__c == 'LATAM' && opp.Region2__c != '8') {
                        opp.Region2__c = '8';
                    }
                    else if(oppRegion.Super_Region__c == 'EMEA' && opp.Region2__c != '4') {
                        opp.Region2__c = '4';
                    }
                    else if(oppRegion.Super_Region__c == 'NA' && opp.Region2__c != '3') {
                        opp.Region2__c = '3';
                    }
                }
            }   
        }
    }
}