@isTest
public class partnerUtilTest{
    
    @isTest(seeAllData = true)
    public static void testGetOnboardingProfile() {
        
        List <Classification__c> classifications = [SELECT HierarchyKey__c
                                                    FROM Classification__c
                                                    WHERE HierarchyKey__c LIKE '%.OEM'                                                  
                                                    OR HierarchyKey__c LIKE '%.ISV'
                                                    OR HierarchyKey__c LIKE '%.SI'
                                                    OR HierarchyKey__c LIKE '%.TRAINING'];
        List <String> globalRegions = new List<String>();
        globalRegions.add('NA');
        globalRegions.add('EMEA');
        globalRegions.add('LATAM');
        globalRegions.add('APAC');
        
        for (Integer i = 0; classifications.size() > i; i++) {
            String clfnHKey = classifications.get(i).HierarchyKey__c;
            for (Integer r = 0; globalRegions.size() > r; r++) {               
                Profile p = PartnerUtil.onboardingProfile(globalRegions.get(r), clfnHKey);
                System.debug('Global region: ' + globalRegions.get(r) + ' and classification key id: ' + clfnHKEY);
                System.debug('Partner Profile Name: ' + p.name);
            }
        }
    }
    
    @isTest(seeAllData = true)
    public static void testInsertOnboardingLead() {
        
        LIST <Classification__c> partnerType = [SELECT id, HierarchyKey__c
                                                FROM Classification__c
                                                WHERE HierarchyKey__c = 'PARTNER_TYPE.ISV'
                                                OR HierarchyKey__c = 'PARTNER_TYPE.RESELLER'
                                                OR HierarchyKey__c = 'PARTNER_TYPE.OEM'
                                                OR HierarchyKey__c = 'PARTNER_TYPE.SI'
                                                OR HierarchyKey__c = 'PARTNER_TYPE.TRAINING' ORDER BY HierarchyKey__c ASC];

        Classification__c partnerTier = [SELECT id
                                         FROM Classification__c
                                         WHERE HierarchyKey__c = 'PARTNER_TIER.READY'];
        
        Account a = [SELECT id FROM Account limit 1];
        User owner = [SELECT id FROM User WHERE email LIKE '%redhat.com%' limit 1];
        Lead leadRecordType = [SELECT RecordTypeId FROM lead WHERE RecordType.Name LIKE 'Partner Onboarding' limit 1];
        
        Lead leadInfo = new Lead();        
        leadInfo.Account__c = a.id;
        leadInfo.Company ='Apprivo';
        leadInfo.Street = '417 Montgomery';
        leadInfo.City = 'San Francisco';
        leadInfo.State ='CA';
        leadInfo.PostalCode ='94104';
        leadInfo.Global_Region__c ='NA';
        leadInfo.SubRegion__c ='Southeast';
        leadInfo.RHNLogin__c='123456789iuyt';
        leadInfo.Phone ='4156325768';
        leadInfo.Website ='www.apprivo.com';
        leadInfo.Industry_Focus__c ='Aerospace';
        leadInfo.Is_Primary_Public_Sector__C = 'No';
        leadInfo.Do_they_act_in_any_government_position__c='Yes';
        leadInfo.Have_they_been_convicted__c='No';
        leadInfo.RecordTypeId = leadRecordType.id;
        leadInfo.Onboarding_Language_Preference__c = 'en';
        
        
        for (Integer i = 0; partnerType.size() > i; i++) {
            Classification__c pType = partnerType.get(i);
            leadInfo.Partner_Type__c = pType.id;
            OnboardingController controller = new OnboardingController(new ApexPages.StandardController(leadInfo));            
            controller.PartnerTypeSI = partnerType.get(2);
            System.debug('controller.PartnerTypeSI = partnerType.get(2)=  ' + partnerType.get(2));
            controller.PartnerTypeOEM = partnerType.get(1);
            System.debug('controller.PartnerTypeOEM = partnerType.get(1)=  ' + partnerType.get(1));
            controller.PartnerTypeTraining = partnerType.get(3);
            System.debug('controller.PartnerTypeTraining = partnerType.get(3)=  ' + partnerType.get(3));
            controller.getLead().Global_Region__c = 'NA';
            controller.getLead().OwnerId = owner.id;
            controller.getLead().Agree_To_Partner_TC__c = true;
            controller.getLead().FirstName = 'Test';
            controller.getLead().LastName = 'Test';
            controller.getLead().Email = 'mgartner@redhat.com.test';
            controller.getLead().Salutation = 'Mr.';
            controller.getLead().Company = 'Red Hat';
            controller.getLead().RHNLogin__c = 'mgartnertest919';
            controller.getLead().Onboarding_Language_Preference__c = 'en';
            controller.getLead().Partner_Tier__c = partnerTier.id;
            controller.PartnerTierReady = partnerTier;	            
            controller.getLead().Partner_Type__c = pType.id;
            controller.getLead().Id = null;
            controller.insertOnboardingLead();
		    System.debug('I have iterated through this ' + i + ' time(s) and am currently using Partner Type ' + pType.HierarchyKey__c);        
        } 
            
    }
    
}