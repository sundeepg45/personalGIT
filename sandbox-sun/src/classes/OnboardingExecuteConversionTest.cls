@IsTest
private class OnboardingExecuteConversionTest {

     public static testMethod void testLanguagePreferenceMigration() {
        User user  = [Select Id, FirstName, LastName from User where Profile.Name = 'Administrator - Level 1' and isActive = true limit 1];
        List<Country__c> countryList = [select name, abbreviation__c, isMigrated__c, Iso3166Alpha2__c  from country__c where isMigrated__c = false limit 1];
        Profile p = [select id,name from profile where name like '%NA Partner Portal%' limit 1];
        RecordType recordType = [Select r.Name, r.Id From RecordType r where r.Name='Partner Onboarding']; 
        RecordType caseRecordType = [Select r.Name, r.Id From RecordType r where r.name='Partner General Issues' limit 1];
        
        Classification__c partnerTypeClassification = new Classification__c();
        partnerTypeClassification.Name = 'Partner Type';
        insert partnerTypeClassification;
        
        Classification__c resellerClassification = new Classification__c();
        resellerClassification.Name = 'Reseller';
        resellerClassification.Parent__c = partnerTypeClassification.Id;
        insert resellerClassification;
        
        List<Classification__c> partnerTypeClassifications = new List<Classification__c>();
        
        partnerTypeClassifications.add(resellerClassification);
        
        Classification__c isvClassification = new Classification__c();
        isvClassification.Name = 'ISV';
        isvClassification.Parent__c = partnerTypeClassification.Id;
        insert isvClassification;
        
        List<Classification__c> isvPartnerClassification = new List<Classification__c>();
        isvPartnerClassification.add(isvClassification);
        
        
        Classification__c partnerTierClassificationObj = new Classification__c();
        partnerTierClassificationObj.Name = 'Partner Tier';
        insert partnerTierClassificationObj; 
        
        Classification__c readyClassification = new Classification__c();
        readyClassification.Name = 'Ready';
        readyClassification.Parent__c = partnerTierClassificationObj.Id;
        insert readyClassification;
        
        List<Classification__c> partnerTierClassification = new List<Classification__c>();
        partnerTierClassification.add(readyClassification);
       
        Account account = new Account();
        account.Name ='Test Acc';
        account.Global_Region__c ='APAC';
        account.OwnerId = user.Id;
        account.BillingCountry ='US';
        insert account;
        
         
        Lead leadInfo = new Lead();
        leadInfo.Partner_Type__c =partnerTypeClassifications.get(0).Id;
        leadInfo.Account__c = account.Id;
        leadInfo.Company ='Apprivo';
        leadInfo.LastName = 'Last';
        leadInfo.FirstName = 'First';
        leadInfo.Street = '417 Montgomery';
        leadInfo.City = 'San Francisco';
        leadInfo.Email = 'me@mydomain.com';
        leadInfo.State ='CA';
        leadInfo.Country = 'US';
        leadInfo.PostalCode ='94104';
        leadInfo.Global_Region__c ='NA';
        leadInfo.SubRegion__c ='Southeast';
        leadInfo.RHNLogin__c='123456789iuyt';
        leadInfo.Phone ='4156325768';
        leadInfo.Website ='www.apprivo.com';
        leadInfo.Other_Countries__c ='Camaroon';
        leadInfo.Industry_Focus__c ='Aerospace';
        leadInfo.Do_they_act_in_any_government_position__c='Yes';
        leadInfo.Onboarding_Language_Preference__c = 'ko';
        leadInfo.Have_they_been_convicted__c='No';
        leadInfo.RecordTypeId = recordType.Id;
        leadInfo.Partner_Onboarding_Profile__c = p.Name;
        insert leadInfo;
        
	    List<Database.LeadConvert> leadConvertList = new List<Database.LeadConvert>();
        Database.LeadConvert leadConvert = new Database.LeadConvert();
        leadConvert.setConvertedStatus('Converted');
        leadConvert.setDoNotCreateOpportunity(true);
        leadConvert.setLeadId(leadInfo.Id);
        leadConvert.setSendNotificationEmail(false);
        leadConvert.setAccountId(leadInfo.Account__c);
        leadConvertList.add(leadConvert);
	    List<Database.LeadConvertResult> leadConvertResultList = Database.convertLead(leadConvertList);
	
	    Set<Id> leadConvertedIds = new Set<Id>();
        leadConvertedIds.add(leadInfo.Id);

        test.starttest();

		OnboardingExecuteConversion conv = new OnboardingExecuteConversion();
		OnboardingExecuteConversion.convertContactToUser(leadConvertedIds);
		
		String lang = [select LanguageLocaleKey from User where FederationIdentifier = :leadInfo.RHNLogin__c].LanguageLocaleKey;
		System.assert(lang == leadInfo.Onboarding_Language_Preference__c, 'Expected LanguageLocaleKey of ' + leadInfo.Onboarding_Language_Preference__c);

        test.stopTest();
     }
}