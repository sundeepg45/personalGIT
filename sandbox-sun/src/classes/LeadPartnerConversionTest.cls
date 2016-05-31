@isTest
private class LeadPartnerConversionTest {

/* I think all of this lead conversion stuff is defunct
    static testMethod void myUnitTest() {


    	User adminUser = PartnerTestUtils.getAdminUser();
    	Account partnerAccount = PartnerTestUtils.makeAccount('Partner Lead Conversion Account', adminuser);
    	PartnerTestUtils.makeAccountReseller(partnerAccount.Id);
    	Contact partnerAccountContact = PartnerTestUtils.makeContact(partnerAccount.Id, 'abcdefeghiandre');
    	insert partnerAccountContact;

    	Contact con = [select id, Account.Global_Region__c, LoginName__c, AccountId from Contact where Id = :partnerAccountContact.Id];
    	Contact_ConvertToUser controller = new Contact_ConvertToUser(new ApexPages.Standardcontroller(con));
		controller.convertToUser();
        User partnerLeadOwner = PartnerTestUtils.makeUser(partnerAccount, partnerAccountContact);
        insert partnerLeadOwner;
//		User  partnerLeadOwner = [Select Id, IsPortalEnabled, ProfileId from User where ContactId = :partnerAccountContact.Id];

    	System.debug( 'partner account is partner 1 '+ partnerAccount.IsPartner);
    	System.debug( 'partner user is partner 1 '+ partnerleadowner.IsPortalEnabled);
    	System.debug( 'partner user is profile partner 1'+ partnerleadowner.ProfileId);
    	Lead leadtoConvert = PartnerTestUtils.makeLead('Maria', 'Mandarina', 'Test Partner Lead Conversion', partnerLeadOwner);
    	System.RunAs(partnerLeadOwner){

    		insert leadtoConvert ;
    		System.debug( 'partner account '+ leadtoConvert.PartnerAccount.Id);
    		System.debug( 'Lead Owner '+ leadtoConvert.OwnerId + ' compares to ' +partnerleadowner.id);


    		System.debug( 'partner account is partner '+ partnerAccount.IsPartner);
    		System.debug( 'partner user is partner '+ partnerleadowner.IsPortalEnabled);
    		System.debug( 'partner user is partner '+ partnerleadowner.ProfileId);
   			ApexPages.StandardController sc = new ApexPages.StandardController(leadtoConvert);
   			apexpages.currentpage().getparameters().put('id' , leadtoConvert.Id);
   			//apexpages.currentpage().getparameters().put('jBoss_Products__c' , 'JBoss 1');
    		LeadPartnerConversion lpc = new LeadPartnerConversion(sc);
    		lpc.leadtoconvert.Jboss_Products__c = 'JBoss 1';
			lpc.convertLead();
			System.assertNotEquals(null, lpc.newOpportunity);
		//	Opportunity newopp = [Select Id, Name,  StageName from Opportunity where id = :leadConvertResultList.getOpportunityId() ];
		//	System.assertEquals('Prepare', newopp.StageName);

    	}

    }

    static testMethod void myFCPAUnitTest() {


    	User adminUser = PartnerTestUtils.getAdminUser();
    	Account partnerAccount = PartnerTestUtils.makeAccount('Partner Lead Conversion Account', adminuser);
    	PartnerTestUtils.makeAccountReseller(partnerAccount.Id);
    	Contact partnerAccountContact = PartnerTestUtils.makeContact(partnerAccount.Id, 'abcdefeghiandre');
    	insert partnerAccountContact;

    	Contact con = [select id, Account.Global_Region__c, LoginName__c, AccountId from Contact where Id = :partnerAccountContact.Id];
    	Contact_ConvertToUser controller = new Contact_ConvertToUser(new ApexPages.Standardcontroller(con));
		controller.convertToUser();
		User  partnerLeadOwner = [Select Id, IsPortalEnabled, ProfileId, AccountId from User where ContactId = :partnerAccountContact.Id];

    	System.debug( 'partner account is partner 1 '+ partnerAccount.IsPartner);
    	System.debug( 'partner user belongs to '+ partnerleadowner.AccountId);
    	System.debug( 'partner user is partner 1 '+ partnerleadowner.IsPortalEnabled);
    	System.debug( 'partner user is profile partner 1'+ partnerleadowner.ProfileId);
    	Lead leadtoConvert = PartnerTestUtils.makeLead('Maria', 'Mandarina', 'Test Partner Lead Conversion', partnerLeadOwner);
    	leadtoConvert.Have_they_been_convicted__c = 'Yes';
    	System.RunAs(partnerLeadOwner){

    		insert leadtoConvert ;
    		System.debug( 'partner account '+ leadtoConvert.PartnerAccount.Id);
    		System.debug( 'Lead Owner '+ leadtoConvert.OwnerId + ' compares to ' +partnerleadowner.id);


    		System.debug( 'partner account is partner '+ partnerAccount.IsPartner);
    		System.debug( 'partner user is partner '+ partnerleadowner.IsPortalEnabled);
    		System.debug( 'partner user is partner '+ partnerleadowner.ProfileId);
   			ApexPages.StandardController sc = new ApexPages.StandardController(leadtoConvert);
   			apexpages.currentpage().getparameters().put('id' , leadtoConvert.Id);
   			//apexpages.currentpage().getparameters().put('jBoss_Products__c' , 'JBoss 1');
    		LeadPartnerConversion lpc = new LeadPartnerConversion(sc);
    		lpc.leadtoconvert.Jboss_Products__c = 'JBoss 1';
			lpc.convertLead();
			System.assertNotEquals(null, lpc.newOpportunity);
		//	Opportunity newopp = [Select Id, Name,  StageName from Opportunity where id = :leadConvertResultList.getOpportunityId() ];
		//	System.assertEquals('Prepare', newopp.StageName);

    	}

    }
    */
}