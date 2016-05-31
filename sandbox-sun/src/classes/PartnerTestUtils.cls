@isTest(SeeAllData=true)
public with sharing class PartnerTestUtils {

    public static boolean IGNORE_BLOCK_EDIT_ON_CDH_MERGE = false;

    public static User getAdminUser() {
        User adminuser = [Select Id, FirstName, LastName, Email, LanguageLocaleKey from User where Profile.Name = 'Administrator - Level 1' and isActive = true limit 1];
        return adminuser;
    }

    public static Account refreshAccount(Account a){
        return [select Id,
                    Name,
                    Global_Region__c,
                    Subregion__c,
                    RecordTypeId,
                    OwnerId,
                    ShippingStreet,
                    ShippingCity,
                    ShippingState,
                    ShippingCountry,
                    ShippingPostalCode,
                     ///Andreina changes
                    BillingStreet,
                    BillingCity,
                    BillingState,
                    BillingPostalCode,
                    /////
                    BillingCountry,
                    IsPartner,
                    PartnerStatuses__c,
                    RequalStatus__c,
                    RequalificationDate__c,
                    Requalification_Approver__c,
                    Finder_Partner_Type__c,
                    Finder_Partner_Tier__c,
                    Anti_Corruption_Status__c
                from Account
                where Id = :a.Id];
    }

    public static Account makeAccount(String name, User owner) {
        Account account = makeNonpartnerAccount(name, owner);
        account.ispartner = true;
        update account;
        return account;
    }

    public static Account buildPartnerAccount(String name, User owner) {
        Account account = new Account();
        account.Name = name;
        account.Global_Region__c ='NA';
        account.Subregion__c = 'Southeast';
        account.RecordTypeId = [
            select Id
              from RecordType
             where SObjectType = 'Account'
               and Name = 'NA Partner'
        ].Id;
        account.OwnerId = owner.Id;
        account.ShippingStreet = '1801 Varsity Drive';
        account.ShippingCity = 'Raleigh';
        account.ShippingState = 'NC';
        account.ShippingCountry = 'US';
        account.ShippingPostalCode = '27606';
        account.BillingCountry = 'US';
         ///Andreina changes
        account.BillingStreet = '1801 Varsity Dr';
        account.BillingCountry = 'US';
        account.BillingCity = 'Raleigh';
        account.BillingState = 'NC';
        account.BillingPostalCode = '27606';
        /////
        account.AllowedEmailDomains__c = 'redhat.Com';
        account.RequalStatus__c = null;
        account.Is_Partner_Published__c = True;
        return account;
    }

    public static Account makeNonpartnerAccount(String name, User owner) {
        Account account = new Account();
        account.Name = name;
        account.Global_Region__c ='NA';
        account.Subregion__c = 'Southeast';
        account.RecordTypeId = [
            select Id
              from RecordType
             where SObjectType = 'Account'
               and Name = 'NA Partner'
        ].Id;
        account.OwnerId = owner.Id;
        account.ShippingStreet = '1801 Varsity Drive';
        account.ShippingCity = 'Raleigh';
        account.ShippingState = 'NC';
        account.ShippingCountry = 'US';
        account.ShippingPostalCode = '27606';
        account.BillingCountry = 'US';
         ///Andreina changes
        account.BillingStreet = '1801 Varsity Dr';
        account.BillingCountry = 'US';
        account.BillingCity = 'Raleigh';
        account.BillingState = 'NC';
        account.BillingPostalCode = '27606';
        /////
        account.AllowedEmailDomains__c = 'redhat.Com';
        account.RequalStatus__c = null;
        account.Is_Partner_Published__c = True;
        insert account;
//        account.ispartner = true;
//        update account;
        return account;
    }

     public static Lead makeLead(String firstname, String lastname, String company, User owner) {
        Lead newLead = new Lead();
        newLead.LastName = lastname;
        newLead.FirstName = firstname;
        newLead.Company = company;
        newLead.Status = 'In progress';
        newLead.Revenue_Type__c = 'Subscription';
        newLead.Email = 'test@test.com' ;
        newLead.Global_Region__c = 'NA';
        newlead.Products_of_Interest__c = 'Cloud Computing';
        newLead.RecordTypeId = [
            select Id
              from RecordType
             where SObjectType = 'Lead'
               and Name = 'NA Sales Lead'
        ].Id;
        newLead.OwnerId = owner.Id;
        newLead.Street = '1801 Varsity Dr';
        newLead.Country = 'US';
        newLead.City = 'Raleigh';
        newLead.State = 'NC';
        newLead.PostalCode = '27606';
        return newLead;
    }

     public static Partner_Onboarding_Registration__c makeOnboarding(String firstname, String lastname, String company, User owner) {
        Partner_Onboarding_Registration__c newLead = new Partner_Onboarding_Registration__c();
        newLead.LastName__c = lastname;
        newLead.FirstName__c = firstname;
        newLead.Company__c = company;
        newLead.Partner_Onboarding_Status__c = 'In progress';
//        newLead.Revenue_Type__c = 'Subscription';
        newLead.Email__c = 'test@test.com' ;
        newLead.Global_Region__c = 'NA';
//        newlead.Products_of_Interest__c = 'Cloud Computing';
        newLead.RecordTypeId = [
            select Id
              from RecordType
             where SObjectType = 'Partner_Onboarding_Registration__c'
               and Name = 'Business Partner Registration'
        ].Id;
        newLead.OwnerId = owner.Id;
        newLead.address1__c = '1801 Varsity Dr';
        newLead.Country__c = [select Id from Country__c where Abbreviation__c = 'US' limit 1].Id;
        newLead.City__c = 'Raleigh';
        newLead.State_Province__c = [select Id from State__c where Abbreviation__c = 'NC' and Country__c = :newLead.Country__c limit 1].Id;
        newLead.Postal_Code__c = '27606';
        return newLead;
    }

    public static Partner_Onboarding_Registration__c makeOnboardingRequest(String firstname, String lastname, String company, User owner) {
        Partner_Onboarding_Registration__c reg = makeOnboarding(firstname, lastname, company, owner);
        Classification__c reseller = [Select c.ReferenceKey__c, c.Name, c.Id, c.HierarchyRootName__c, c.HierarchyKey__c From Classification__c c  where c.HierarchyKey__c = 'PARTNER_TYPE.RESELLER' limit 1];
        Classification__c ready = [Select c.ReferenceKey__c, c.Name, c.Id, c.HierarchyRootName__c, c.HierarchyKey__c From Classification__c c  where c.HierarchyKey__c = 'PARTNER_TIER.READY' limit 1];
        reg.Partner_Type__c = reseller.Id;
        reg.Partner_Tier__c = ready.Id;
        reg.Is_Primary_Public_Sector__c = 'No';
        return reg;
    }

    public static Lead makeOnboardingLead(String firstname, String lastname, String company, User owner) {
        Lead newLead = makeLead(firstname, lastname, company, owner);
        Classification__c reseller = [Select c.ReferenceKey__c, c.Name, c.Id, c.HierarchyRootName__c, c.HierarchyKey__c From Classification__c c  where c.HierarchyKey__c = 'PARTNER_TYPE.RESELLER' limit 1];
        Classification__c ready = [Select c.ReferenceKey__c, c.Name, c.Id, c.HierarchyRootName__c, c.HierarchyKey__c From Classification__c c  where c.HierarchyKey__c = 'PARTNER_TIER.READY' limit 1];

        RecordType port = [Select r.Name, r.Id From RecordType r where r.Name='Partner Onboarding'];
        newLead.RecordTypeId = port.Id;
        newLead.RecordType = port;
        newLead.Partner_Type__c = reseller.Id;
        newLead.Partner_Tier__c = ready.Id;
        newLead.Is_Primary_Public_Sector__c = 'No';
        newLead.Global_Region__c = 'NA';

        return newLead;
    }

    public static Partner_Location__c makeLocation(Id accountId) {
        Partner_Location__c loc = new Partner_Location__c(Partner__c = accountId);
        loc.Street__c = '1801 Varsity Drive';
        loc.Country__c = 'US';
        loc.City__c = 'Raleigh';
        loc.State_Province__c = 'NC';
        loc.Postal_Code__c = '27606';
        loc.Convert__c = False;
        return loc;
    }

    public static Account addSalesAccount(Account partnerAccount) {
        CDH_Party__c party = new CDH_Party__c();
        String partyNum = String.valueOf(Math.abs(Crypto.getRandomInteger()));
//        String partyNum = String.valueOf(Math.roundToLong(Math.random() * 100000));
        party.CDH_Party_Number_Ext__c = partyNum;
        insert party;
        Account sales = new Account();
        sales.CDH_Party_Name__c = party.Id;
        sales.Name = partnerAccount.Name;
        String rectype = partnerAccount.Global_Region__c + 'Account';
        sales.RecordTypeId = [select Id from RecordType where DeveloperName = :rectype and SObjectType = 'Account' limit 1].Id;
        insert sales;
        partnerAccount.CDH_Party_Name__c = party.Id;
        return sales;
    }

    public static void makeAccountISV(Id accountId) {
//        setNewStatus(PartnerTestUtils.makeStatus(accountId, 'PARTNER_TYPE.ISV', 'PARTNER_TIER.READY'));
        insert makeProgram(accountId, PartnerConst.ISV, PartnerConst.READY);
    }

    public static void makeAccountDistributor(Id accountId) {
        insert makeProgram(accountId, PartnerConst.DISTRIBUTOR, PartnerConst.AFFILIATED);
    }

    public static void setDraftStatus(PartnerStatus__c status) {
        List<PartnerStatus__c> psList = [select Id, isVisible__C, ApprovalStatus__c from PartnerStatus__c where Partner__c = :status.partner__c and ActivationStatus__c = 'Active'];
        if (psList != null) {
            for (PartnerStatus__c ps : psList) {
                ps.isVisible__c = False;
                ps.ApprovalStatus__c = 'Expired';
                status.Previous_Partner_Status__c = ps.Id;
            }
            update psList;
        }
        status.ApprovalStatus__c = 'Draft';
        insert status;
    }

    public static void setNewStatus(PartnerStatus__c status) {
        List<PartnerStatus__c> psList = [select Id, isVisible__C, ApprovalStatus__c from PartnerStatus__c where Partner__c = :status.partner__c and ActivationStatus__c = 'Active'];
        if (psList != null) {
            for (PartnerStatus__c ps : psList) {
                ps.isVisible__c = False;
                ps.ApprovalStatus__c = 'Expired';
                status.Previous_Partner_Status__c = ps.Id;
            }
            update psList;
        }
        status.ApprovalStatus__c = 'New';
        insert status;
        status.ApprovalStatus__c = 'Approved';
        update status;
    }

    public static void setNewStatusForAccount(PartnerStatus__c status, Account acct) {
        List<PartnerStatus__c> psList = [select Id, isVisible__C, ApprovalStatus__c from PartnerStatus__c where Partner__c = :status.partner__c and ActivationStatus__c = 'Active'];
        if (psList != null) {
            for (PartnerStatus__c ps : psList) {
                ps.isVisible__c = False;
                ps.ApprovalStatus__c = 'Expired';
                status.Previous_Partner_Status__c = ps.Id;
            }
            update psList;
        }
        insert status;
        // do this now since the actual trigger runs in a @future context and results won't be in account when needed for Finder
        PartnerStatus_UpdateAccount.performUpdateOnAccount(acct, status);

        Map<Id, Classification__c> clfnmap = new Map<Id, Classification__c>([
            select  Id, Name from Classification__c where Id in (:status.PartnerType__c, :status.PartnerTier__c)
        ]);
        acct.PartnerStatuses__c = clfnmap.get(status.PartnerTier__c).Name + ' - ' + clfnmap.get(status.PartnerType__c).Name;
    }

    public static void makeAccountReseller(Id accountId) {
//        setNewStatus(PartnerTestUtils.makeStatus(accountId, 'PARTNER_TYPE.RESELLER', 'PARTNER_TIER.ADVANCED'));
        insert makeProgram(accountId, PartnerConst.RESELLER, PartnerConst.ADVANCED);
    }

    public static Contact makeContact(Id accountId, String loginName) {
        Contact contact = new Contact();
        contact.AccountId = accountId;
        contact.Email = 'test@redhat.com';
        contact.FirstName = 'First Name';
        contact.LastName ='Last Name';
        contact.LoginName__c = loginName;
        contact.LanguagePreference__c = 'English';
        return contact;
    }

    public static User makeUser(Account account, Contact contact) {
        OnboardingExecuteConversion onboarding = new OnboardingExecuteConversion();
        User user = onboarding.getPartnerUser(contact);
/*        user.Skip_Consumer_User_Creation__c = true; */
        String profileName = account.Global_Region__c + ' Partner Portal – Strategic License';
        System.debug('Looking for profile that matches ' + profileName);
        user.ProfileId =  [select Name
                  from Profile
                 where Name like :profileName
                 limit 1].Id;
        return user;
    }

    public static User makePartnerUser(Account account, Contact contact) {
        String profileName = account.Global_Region__c + ' Partner Portal – Strategic License';
        System.debug('Looking for profile that matches ' + profileName);
        ID ProfileId =  [select Name
                        from Profile
                        where Name like :profileName
                        limit 1].Id;
        User user = new User();
        user.ProfileId = ProfileId;
        user.Username = 'testUname@test.com';
        user.Email = 'rkiran+makepUser@redhat.com';
        user.FederationIdentifier = contact.LoginName__c;
        //user.Federation_ID__c = contact.LoginName__c;
        user.FirstName = contact.FirstName;
        user.LastName = contact.LastName;
        user.Alias = 'tuser';
        user.EmailEncodingKey = 'UTF-8';
        user.LanguageLocaleKey = 'en_US';
        user.LocaleSidKey = 'en_US';
        user.TimeZoneSidKey = 'America/Chicago';
        user.ContactId = contact.Id;
        //user.Contact_Id__c = contact.Id;
        return user;
    }

/*
    public static PartnerStatus__c makeStatus(String accountId, String partnerType, String partnerTier) {
        PartnerStatus__c ps = new PartnerStatus__c();
        ps.ActivationDate__c = System.today();
        ps.ExpirationDate__c = ps.ActivationDate__c.addMonths(12);
        ps.PartnerTier__c = [select Id from Classification__c where hierarchykey__c = :partnerTier].Id;
        ps.PartnerType__c = [select Id from Classification__c where hierarchykey__c = :partnerType].Id;
        ps.Partner__c = accountId;
        ps.isVisible__c = True;
        ps.ApprovalStatus__c = 'Approved';
        return ps;
    }
*/

    public static Partner_Program__c makeProgram(String accountId, String partnerType, String partnerTier) {
        Partner_Program__c ps = new Partner_Program__c();
        ps.Tier__c = partnerTier;
        ps.Program__c = [select Id from Partner_Program_Definition__c where Program_Category__c = :partnerType limit 1].Id;
        ps.Account__c = accountId;
        ps.Is_Primary__c = true;
//        ps.isVisible__c = True;
        ps.Status__c = 'Approved';
        return ps;
    }

    public static Partner_Program__c makeProgram(String accountId, String partnerType, String partnerTier, Boolean isPrimary) {
        Partner_Program__c ps = new Partner_Program__c();
        ps.Tier__c = partnerTier;
        ps.Program__c = [select Id from Partner_Program_Definition__c where Program_Category__c = :partnerType limit 1].Id;
        ps.Account__c = accountId;
        ps.Is_Primary__c = isPrimary;
//        ps.isVisible__c = True;
        ps.Status__c = 'Approved';
        return ps;
    }

    public static Partner_Program__c makeAccountResellerProgram(Id accountId) {
        Partner_Program__c pgm = PartnerTestUtils.makeProgram(accountId, PartnerConst.RESELLER, PartnerConst.READY);
        insert pgm;
        return pgm;
    }

    public static Partner_Program__c makeAccountOEMProgram(Id accountId) {
        Partner_Program__c pgm = PartnerTestUtils.makeProgram(accountId, PartnerConst.OEM, PartnerConst.AFFILIATED);
        insert pgm;
        return pgm;
    }

    /*
    public static List<PartnerClassification__c> makeSpecializations(Account account) {
        List<PartnerClassification__c> pclfnList = new List<PartnerClassification__c>();
        for (Classification__c clfn : [
            select id from classification__c where hierarchykey__c like 'PARTNER_CLASSIFICATION.SPECIALIZATION.%'
        ]) {
            PartnerClassification__c pclfn = new PartnerClassification__c();
            pclfn.classification__c = clfn.id;
            pclfn.partner__c = account.id;
            pclfn.ActivationDate__c = System.today();
            pclfn.ExpirationDate__c = System.today().addMonths(12);
            pclfnList.add(pclfn);
        }
        return pclfnList;
    }
    */

    public static list<PartnerTraining__c> makeCertifications(Id accountId, Id contactId, String certHkey, String typeHkey){
        list<PartnerTraining__c> certs = new list<PartnerTraining__c>();

        id trainingId = [select id from classification__c where hierarchykey__c = :typeHkey].Id;
        id certId = [select id from classification__c where hierarchykey__c = :certHkey].Id;

        Integer x;
        for(x=0; x<3 ; x++){
            PartnerTraining__c cert = new PartnerTraining__c();
            cert.certificatenumber__c = 'abcdef123456';
            cert.date_achieved__c = System.today().addDays(-1);
            cert.contact__c = contactId;
            cert.trainingtype__c = trainingId;
            cert.certification__c = certId;
            cert.Partner__c = accountId;
            certs.add(cert);
        }
        certs[0].Track__c = 'Sales';
        certs[1].Track__c = 'Sales Engineer';
        certs[2].Track__c = 'Delivery';

        return certs;
    }

    public static PartnerTraining__c makeCertification(Id accountId, Id contactId, String certHkey, String typeHkey, String track) {
        PartnerTraining__c cert = new PartnerTraining__c();
        cert.certificatenumber__c = 'abcdef123456';
        cert.date_achieved__c = System.today().addDays(-1);
        cert.contact__c = contactId;
        cert.trainingtype__c = [select id from classification__c where hierarchykey__c = :typeHkey].Id;
        cert.certification__c = [select id from classification__c where hierarchykey__c = :certHkey].Id;
        cert.partner__c = accountId;
        cert.Track__c = track;
        return cert;
    }

    public static PartnerTraining__c makeCertification(Id accountId, Id contactId, String certHkey, String typeHkey) {
        return makeCertification(accountId, contactId, certHkey, typeHkey, 'null');
    }


    public static Customer_Reference__c makeCustomerReference(Id accountId, Id contactId) {
        Customer_Reference__c ref = new Customer_Reference__c();

        ref.account__c = accountId;
        ref.company_name__c = 'Test Company Ref';
        ref.contact__c = contactId;
        ref.Pl__c = 'pl__c';
        ref.Please_describe_how_the_customer_benefit__c = 'benefits';
        ref.approved_date__c = System.today().addDays(-1);
        ref.date_submitted__c = System.today().addDays(-2);
        return ref;
    }

    public static User createUser(Contact contact) {
        OnboardingExecuteConversion oec = new OnboardingExecuteConversion();
        return oec.getPartnerUser(contact);
    }

    public static PartnerProduct__c makeProduct(Id accountId) {
        PartnerProduct__c prod = new PartnerProduct__c();
        prod.partner__c = accountId;
        prod.Full_Product_Name__c = 'test product';
        prod.application_status__c = 'Approved';
        prod.application_visibility__c = 'Visible';
        prod.product_details__c = 'details';
        prod.call_to_action_text__c = 'tally-ho';
        prod.success_story__c = 'we rock';
        prod.pricing_and_support_details__c = 'no support for you';
        prod.usage_licensing__c = 'Free';
        prod.JBoss_Platform__c = 'JBoss Enterprise App Platform 5.0';
        prod.Platforms__c = 'RHEL4 - x86';
        prod.Software_Category__c = 'Networking';
        prod.Industry_Focus__c = 'Engineering';
        return prod;
    }

    public static Attachment makeProductLogo(Id productId) {
        PartnerProductLogo__c plogo = new PartnerProductLogo__c();
        plogo.PartnerProduct__c = productId;
        plogo.ActivationDate__c = System.today().addDays(-1);
        insert plogo;
        Attachment attach = new Attachment();
        attach.ParentId = plogo.Id;
        attach.Name = 'logo.png';
        attach.ContentType = 'image/png';
        attach.Body = EncodingUtil.base64Decode('a fake image body');
        insert attach;
        return attach;
    }

    public static Attachment makePartnerLogo(Id accountId) {
        PartnerLogo__c plogo = new PartnerLogo__c();
        plogo.Partner__c = accountId;
        insert plogo;
        Attachment attach = new Attachment();
        attach.ParentId = plogo.Id;
        attach.Name = 'logo.png';
        attach.ContentType = 'image/png';
        attach.Body = EncodingUtil.base64Decode('a fake image body');
        insert attach;
        return attach;
    }

    public static Attachment makeProductScreenshot(Id productId) {
        PartnerProductScreenshot__c screen = new PartnerProductScreenshot__c();
        screen.PartnerProduct__c = productId;
        insert screen;
        Attachment attach = new Attachment();
        attach.ParentId = screen.Id;
        attach.Name = 'screen.png';
        attach.ContentType = 'image/png';
        attach.Body = EncodingUtil.base64Decode('a fake image body');
        insert attach;
        return attach;
    }

    public static Account quickRequalAccountSetup(String requalStatus) {
        User adminuser = PartnerTestUtils.getAdminUser();
        Account account = PartnerTestUtils.makeAccount('PartnerRequalificationTestAccount', adminuser);
        account.RequalificationDate__c = System.today().addDays(2);
        account.Requalification_Approver__c = adminuser.Id;
        account.RequalStatus__c = requalStatus;

// trying to reduce SOQL hits
//        update account;

        Contact contact = PartnerTestUtils.makeContact(account.id, 'abc123def456ghi789j0');
        insert contact;
        User user = createUser(contact);
        //insert makeSpecializations(account);
        makeAccountReseller(account.id);
        makePartnerLogo(account.id);
        Contact refcontact = PartnerTestUtils.makeContact(account.id, 'abc123def456ghi789j1');
        insert refcontact;
        insert makeCustomerReference(account.id, refcontact.id);
        insert makeCertification(account.id, contact.id, 'PARTNER_TRAINING.RED_HAT.RED_HAT_CERTIFIED_ENGINEER', 'PARTNER_TRAINING.RED_HAT');
        PartnerProduct__c product = makeProduct(account.id);
        insert product;
        return account;
    }

    public static Account quickFinderAccountSetup(String partnerName) {
        User adminuser = PartnerTestUtils.getAdminUser();
        Account account = PartnerTestUtils.makeAccount(partnerName, adminuser);

        Contact contact = PartnerTestUtils.makeContact(account.id, 'abc123def456ghi789j0');
        insert contact;
//        User user = createUser(contact);
        //insert makeSpecializations(account);
//        makeAccountReseller(account.id);
//        Contact refcontact = PartnerTestUtils.makeContact(account.id, 'abc123def456ghi789j1');
//        insert refcontact;
        PartnerProduct__c product = makeProduct(account.id);
        insert product;
        return account;
    }

    public static Account quickGenericAccountSetup(String partnerName) {
        User adminuser = PartnerTestUtils.getAdminUser();
        Account account = PartnerTestUtils.makeAccount(partnerName, adminuser);
        makeAccountReseller(account.id);
        return account;
    }

    public static Account newMakeBasicAccount(String partnerName) {
        User adminuser = PartnerTestUtils.getAdminUser();
        Account account = PartnerTestUtils.buildPartnerAccount(partnerName, adminuser);
        return account;
    }

    public static Account basicAccountSetup(String partnerName) {
        User adminuser = PartnerTestUtils.getAdminUser();
        Account account = PartnerTestUtils.makeAccount(partnerName, adminuser);
        return account;
    }

    static public Approval.ProcessResult setApproval(ID objectId) {
        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setComments('Submitting request for approval.');
        req1.setObjectId(objectId);
        Approval.ProcessResult result = Approval.process(req1);
        return result;
    }

    static public Approval.ProcessResult autoApprove(ID objectId) {
        ProcessInstanceWorkItem[] wilist = [
            select  p.ProcessInstance.Status, p.ProcessInstance.TargetObjectId, p.ProcessInstanceId, p.Id
            from    ProcessInstanceWorkitem p
            where   p.ProcessInstance.TargetObjectId = :objectId
            and     p.ProcessInstance.Status = 'Pending'
        ];
        ProcessInstanceWorkItem wi = wilist.get(0);
        Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
        req.setAction('Approve');
        req.setComments('Auto-Approving request');
        req.setWorkitemId(wi.Id);
        Approval.ProcessResult result =  Approval.process(req);
        return result;
    }

    static public Boolean isApprovalTestingDisabled() {
        StringSetting__c setting = StringSetting__c.getInstance('ApprovalTestingDisabled');
        return setting != null ? setting.Value__c == 'true' : false;

    }

    public static Contract makeContract(String name, Id accountId, Id ownerId) {
        Contract con = new Contract();
        con.AccountId = accountId;
        con.OwnerId = ownerId;
        con.CreatedById = ownerId;
        con.Description = 'Embedded (ISV - Embedded) custom terms requested';
        con.Global__c = true;
        con.Contract_Type__c = 'Embedded Deal';
        con.Stage__c = 'New';
        con.RecordTypeId = [
            select  Id
            from    RecordType
            where   SObjectType = 'Contract'
            and     DeveloperName = 'Customer_or_Partner_Contract'
            and     IsActive = true
        ].Id;
        return con;
    }

    public static Attachment makeAttachment(Id parentId) {
        Attachment attach = new Attachment();
        attach.ParentId = parentId;
        attach.Body = EncodingUtil.base64Decode('a fake document body');
        attach.ContentType = 'text/text';
        attach.Description = 'test attachment';
        attach.Name = 'fakery.pdf';
        insert attach;
        return attach;
    }
}