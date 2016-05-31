@isTest(seeAllData=false)
private class RequalificationControllerTest {

   static testMethod void testReadyISV() {
        DeactivateAllTestUtil.setDeactivateAll(false);

        Account account = PartnerTestUtils.quickRequalAccountSetup(null);
        account.RequalStatus__c = 'Eligible';
        update account;
        PartnerProduct__c pp = PartnerTestUtils.makeProduct(account.Id);
        insert pp;
        standardControllerTests(account);
   }

   static testMethod void testOEM() {
        DeactivateAllTestUtil.setDeactivateAll(false);
        User adminuser = PartnerTestUtils.getAdminUser();

        Account account = PartnerTestUtils.newMakeBasicAccount('testOEMRequal');
        account.RequalificationDate__c = System.today().addDays(2);
        account.Requalification_Approver__c = adminuser.Id;
        insert account;

        insert PartnerTestUtils.makeProgram(account.id, PartnerConst.OEM, PartnerConst.AFFILIATED);
        account.RequalStatus__c = 'Eligible';
        update account;
        standardControllerTests(account);
   }

   static  void testReadyReseller() {
        DeactivateAllTestUtil.setDeactivateAll(false);

        Account account = PartnerTestUtils.quickRequalAccountSetup(null);
        insert PartnerTestUtils.makeProgram(account.id, PartnerConst.RESELLER, PartnerConst.READY);
        account.RequalStatus__c = 'Eligible';
        update account;

        standardControllerTests(account);
   }


   static testMethod void testAdvancedResellerEMEA() {
        DeactivateAllTestUtil.setDeactivateAll(false);

        Account account = PartnerTestUtils.quickRequalAccountSetup(null);
        account.RequalStatus__c = 'Eligible';
        account.Global_Region__c = 'EMEA';
        update account;
        standardControllerTests(account);
   }

   static testMethod void testAdvancedResellerAPAC() {
        DeactivateAllTestUtil.setDeactivateAll(false);

        Account account = PartnerTestUtils.quickRequalAccountSetup(null);
        account.RequalStatus__c = 'Eligible';
        account.Global_Region__c = 'APAC';
        update account;
        standardControllerTests(account);
   }

   static testMethod void testAdvancedResellerLATAM() {
        DeactivateAllTestUtil.setDeactivateAll(false);

        Account account = PartnerTestUtils.quickRequalAccountSetup(null);
        account.RequalStatus__c = 'Eligible';
        account.Global_Region__c = 'APAC';
        update account;
        standardControllerTests(account);
   }

   static testMethod void testAdvancedResellerNA() {
        DeactivateAllTestUtil.setDeactivateAll(false);

        Account account = PartnerTestUtils.quickRequalAccountSetup(null);
        account.RequalStatus__c = 'Eligible';
        account.Select_Specialization_s__c = 'Data Center Infrastructure';
        update account;

        PartnerTrack__c pt = new PartnerTrack__c();
        pt.Partner_Function__c = 'Sales';
        pt.Product_of_Interest__c = 'Data Center Infrastructure';
        insert pt;

        Contact c = PartnerTestUtils.makeContact(account.Id, 'Jayne.Cobb@serenity.net');
        insert c;
        Contact_Track__c ct = new Contact_Track__c();
        ct.Contact__c = c.Id;
        ct.Partner_Track__c = pt.Id;
        insert ct;

        Partner_Point_Requal_Limits__c pl = new Partner_Point_Requal_Limits__c();
        pl.Specialization__c = 'Data Center Infrastructure';
        pl.Global_Region__c = 'NA';
        pl.Partner_Type__c = RedHatObjectReferences__c.getInstance('PARTNER_TYPE.RESELLER').ObjectId__c;
        pl.Partner_Tier__c = RedHatObjectReferences__c.getInstance('PARTNER_TIER.ADVANCED').ObjectId__c;
        pl.Delivery_Points__c = 10;
        pl.Delivery_Users__c = 5;
        pl.Sales_Points__c = 200;
        pl.Sales_Users__c = 5;
        pl.PreSales_Points__c = 500;
        pl.PreSales_Users__c = 2;
        insert pl;

        PP_Account_Points__c ap = new PP_Account_Points__c();
        ap.Account__c = account.Id;
        ap.Sales_Points__c = 100;
        ap.PreSales_Points__c = 50;
        ap.Delivery_Points__c = 20;
        insert ap;
        standardControllerTests(account);
    }

    static void standardControllerTests(Account account) {
        Test.startTest();
        ApexPages.currentPage().getParameters().put('accountId', account.id);
        RequalificationController controller = new RequalificationController();
        controller.doOnLoad();

        //account = PartnerTestUtils.refreshAccount(account);
        System.assert(controller.account.requalstatus__c == 'In Progress');

        // quick and dirty test coverage
        String[] addresses = controller.shippingStreetAddresses;
        addresses = controller.billingStreetAddresses;
        Attachment logo = controller.partnerLogo;
        List<User> users = controller.userList;
        //List<PartnerProductListItem> products = controller.partnerProductItemList;
        List<PartnerTraining__c> certs = controller.certificationList;
        List<PartnerAgreement__c> pagreements = controller.partnerAgreementList;
        List<Case> cases = controller.requestedCases;
        List<Agreement__c> agreements = controller.getAgreementList();
        //List<PartnerRequalGlobalDeal> deals = controller.dealSummary;

//      controller.getIndustryFocusOptions();

        controller.viewHome();
        controller.viewProfile();
        controller.viewUser();
        controller.viewCerts();
        controller.viewProducts();
        controller.viewCustRefs();
        controller.viewAgreement();
        controller.viewFCPA();
        controller.viewBusinessPlan();

        controller.viewHome();
        controller.nextPage();
//        controller.nextPage();
//        controller.nextPage();
//        controller.nextPage();
//        controller.nextPage();
        controller.previousPage();
//        controller.previousPage();
//        controller.previousPage();
//        controller.previousPage();
//        controller.previousPage();

        PartnerRequalification__c requalRec = controller.getRequalRec();
        requalRec.ProfileConfirmed__c = true;
        requalRec.UserConfirmed__c = true;
        requalRec.CertConfirmed__c = true;
        requalRec.ProductConfirmed__c = true;
        requalRec.CustRefConfirmed__c = true;
        requalRec.AgreementConfirmed__c = true;
        requalRec.DealRegConfirmed__c = true;
        requalRec.FCPAConfirmed__c = true;
        requalRec.BusinessPlanConfirmed__c = true;

//        controller.confirmAgreement();
        requalRec.AgreementState__c = 'Declined';
//        controller.confirmAgreement();
        requalRec.AgreementState__c = 'Accepted';
//        controller.confirmAgreement();

        requalRec.AgreementConfirmed__c = false;
//        controller.confirmAgreementByFax();
//        controller.confirmCert();
//        controller.confirmCustRef();

        controller.confirmFCPA();
        requalRec.FCPAActInGovernmentPosition__c = 'No';
        requalRec.FCPAConvictedOfCrime__c = 'Yes';
//        controller.confirmFCPA();

//        controller.confirmProduct();
//        controller.confirmProfile();
//        controller.confirmUser();
//        controller.confirmBusinessPlan();


        String x = controller.userConfirmed_By_Name;
        x = controller.BusinessPlanConfirmed_By_Name;
        x = controller.ProfileConfirmed_By_Name;
        x = controller.CertConfirmed_By_Name;
        x = controller.ProductConfirmed_By_Name;
        x = controller.CustRefConfirmed_By_Name;
        x = controller.AgreementConfirmed_By_Name;
        x = controller.FCPAConfirmed_By_Name;

        x = controller.accountContactName;
        x = controller.accountContactEmail;

        boolean ready = controller.isComplete;

        //account = PartnerTestUtils.refreshAccount(account);
        //System.debug('Account Partner Statusses ' + account.PartnerStatuses__c);
        //System.debug('Account Partner Region ' + account.Global_Region__c);
        //System.debug('Account Partner Sub Region ' + account.Subregion__c);
        //System.debug('Account Partner Requal Approver ' + account.Requalification_Approver__c);
        //System.debug('Account Partner Requal Status ' + account.RequalStatus__c);
        //controller.submitRequal();
        Test.stopTest();
    }

/*
    static private Lead makeDealReg(Account account) {
        List<Id> dealRegRecTypes = new List<Id>();
        for (RecordType rt : [
            select  Id
              from  RecordType
             where  SobjectType = 'Lead'
               and  Name like '%Deal%'
        ]) dealRegRecTypes.add(rt.Id);

        Lead lead = new Lead();
        lead.LastName = 'Reynolds';
        lead.FirstName = 'Mal';
        lead.Company = '101st Regiment';
        lead.State = 'NC';
        lead.State_Province__c = [select id from State__c where Abbreviation__c='NC' and Region__c='NA' and Subregion__c='Southeast'].Id;
        lead.City = account.BillingCity;
        lead.Country = 'US';
        lead.Country__c = account.Country__c;
        lead.Account__c = account.Id;
        lead.RecordTypeId = dealRegRecTypes.get(0);
        lead.Global_Region__c = account.Global_Region__c;
        lead.Red_Hat_Subscription_Revenue__c = 1000000.00;
        return lead;
    }
*/
}