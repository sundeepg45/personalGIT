//
// Tests that enforce the integrity of our production environment by validation
// specific configuration and data items that must be present.
//
@isTest(SeeAllData=true)
private class RTMIntegrityTest {

    static testMethod void verifyRedHatObjectReferences() {
        RedHatObjectReferences__c[] refs = [select Name, ObjectId__c from RedHatObjectReferences__c];
        Classification__c[] clfnlist = [select Id, Name, HierarchyKey__c from Classification__c];
        for (RedHatObjectReferences__c ref : refs) {
            Boolean found = false;
            for (Classification__c clfn : clfnlist) {
                if (clfn.Id == ref.ObjectId__c) {
                    found = true;
                    break;
                }
            }
            System.assert(found, 'Classification missing for RedHatObjectReference: ' + ref.Name);
        }
    }
    
    static testMethod void verifyPartnerPointsUserLimits() {
        Partner_Points__c[] ulimits = [select Id, Name, Max_User_Points__c from Partner_Points__c order by Name];
        System.assert(ulimits.size() == 4, 'Missing a required max user limit in Custom Settings - Partner_Points__c');
        System.assert(ulimits.get(0).Name == 'APAC', 'Expected to find APAC');
        System.assert(ulimits.get(1).Name == 'EMEA', 'Expected to find EMEA');
        System.assert(ulimits.get(2).Name == 'LATAM', 'Exepcted to find LATAM');
        System.assert(ulimits.get(3).Name == 'NA', 'Expected to find NA');
    }
    
    static testMethod void verifyClfnPartnerTypes() {
        Classification__c isv = [select Id from Classification__c where HierarchyKey__c = 'PARTNER_TYPE.ISV'];
        Classification__c res = [select Id from Classification__c where HierarchyKey__c = 'PARTNER_TYPE.RESELLER'];
    }

    static testMethod void verifyClfnPartnerTiers() {
        Classification__c ready = [select Id from Classification__c where HierarchyKey__c = 'PARTNER_TIER.READY'];
        Classification__c adv = [select Id from Classification__c where HierarchyKey__c = 'PARTNER_TIER.ADVANCED'];
        Classification__c prem = [select Id from Classification__c where HierarchyKey__c = 'PARTNER_TIER.PREMIER'];
    }

    static testMethod void verifyTempOpportunityAccounts() {
        Account apac = [select Id from Account where Name = 'New Opp - Pending ID Assignment - APAC'];
        Account emea = [select Id from Account where Name = 'New Opp - Pending ID Assignment - EMEA'];
        Account latam = [select Id from Account where Name = 'New Opp - Pending ID Assignment - LATAM'];
        Account na = [select Id from Account where Name = 'New Opp - Pending ID Assignment - NA'];
    }
}