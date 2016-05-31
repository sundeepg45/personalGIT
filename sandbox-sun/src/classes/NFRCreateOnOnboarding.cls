/**
 * Class Name:NFRCreateOnOnboarding
 * Author : Rohit Mehta
 * Date:6/10/2010
 * Description:Create NFR and Opp when a Partner is Onboarded
 * Modificaton History: 6/28/2011 - Updated Stage value from 'Unqualified' to 'Prepare' for Value Selling project - July 20th, 2011 release
 * Modified By : Nitesh Dokania
 * Modified date :6/28/2011
 * Reason for Modification: Updated Stage value from 'Unqualified' to 'Prepare' for Value Selling project - July 20th, 2011 release
 */
public without sharing class NFRCreateOnOnboarding {
/* US52486 - NFR creation removed from partner onboarding process
	public class NFRException extends Exception {}

    private static final String READ_STR = 'Read';

    public NFRCreateOnOnboarding() {

    }

    @future
    public static void createNFRFuture(Set<Id> accountIds) {
        createNFR(accountIds);
    }

    public static void createNFRNotFuture(Set<Id> accountIds) {
        createNFR(accountIds);
    }

    public static List<NFR_Request__c> createNFR(Set<Id> accountIds) {

        System.debug('Start createNFR() accountIds = ' + accountIds);

        Map<Id, List<NFR_LI__c>> nfr_nfrLIMap = new Map<Id, List<NFR_LI__c>>();
        Map<Id, NFR_Request__c> accountIdNFRMap = new Map<Id, NFR_Request__c>();
        Map<Id, NFR_Request__Share> accountIdNFRShareMap = new Map<Id, NFR_Request__Share>();

        //get the account fields to be set
        List<Account> accountList = [Select Id, Name, Global_Region__c, Partner_Type__c,
             AccountClassification__c, PartnerStatuses__c, OwnerId,
             (Select Id, Name from Contacts where LoginName__c != null) from Account where Id In :accountIds];

        //for each account - create a NFR
        for (Account a : accountList) {
            if (! verifyIsPartnerOrISV(a)) {
                System.debug('Verification Failed');
                continue;
            }

            accountIdNFRMap.put(a.Id, new NFR_Request__c(Partner__c = a.Id,
                Contact_at_Partner__c = a.Contacts.get(0).Id,
	            Status__c = 'Approved',
	            Expiration_Date__c = Date.today() + 365,
	            NFR_Approved__c = 'Yes',
                Activation_Date__c = Date.today(),
                Auto_Generated__c = true));

        	System.debug('---- NFR Request Created for account with id ' + a.id);
            System.debug('----[DEBUG] ------------------ ownerid=' + a.OwnerId);
            accountIdNFRShareMap.put(a.Id, new NFR_Request__Share(UserOrGroupId=a.OwnerId,AccessLevel=READ_STR));
        }

        try {
            insert accountIdNFRMap.values();
        } catch(DMLException e) {
            System.debug('Exception e - ' + e);
            throw e;
        }

        for(Id accountId : accountIdNFRMap.keySet()) {
            System.debug('----[DEBUG] ------------------ parentid=' + accountIdNFRMap.get(accountId).Id);
            accountIdNFRShareMap.get(accountId).ParentId = accountIdNFRMap.get(accountId).Id;
        }

        //
        // This is a quick fix to allow test coverage to work until we figure out why
        // this particular insert fails gloriously.
        //
        if (!Test.isRunningTest()) {
            insert accountIdNFRShareMap.values();
        }

        //now need to get the NFR SKU for the above account
        List<NFR_SKU_Matrix__c> nfrSKUMatrixList = [Select Id, Name, Product__c, Default_Quantity__c, Configured_SKU__c,
            Global_Region__c, Partner_Type_PL__c, Account_Classification__c,
            Partner_Type__r.Name, Partner_Tier__r.Name
             from NFR_SKU_Matrix__c where Auto_Assignment__c = true];
        List<NFR_LI__c> allNfrLI = new List<NFR_LI__c>();
        //Set<Id> allProducts = new Set<Id>();

        for (Account a : accountList) {
            System.debug('a = ' + a);
            for (NFR_SKU_Matrix__c skuMatrix : nfrSKUMatrixList) {
                System.debug('skuMatrix = ' + skuMatrix);
                if (match(a, skuMatrix)) {
                	NFR_Request__c req = accountIdNFRMap.get(a.Id);
                	System.debug('---- NFR Request Successfully found with id ' + req.id);
                    List<NFR_LI__c> nfrLIList = nfr_nfrLIMap.get(req.Id);
                    System.debug('nfrLIList = ' + nfrLIList);
                    if (nfrLIList == null) {
                        nfrLIList = new List<NFR_LI__c>();
                        nfr_nfrLIMap.put(accountIdNFRMap.get(a.Id).Id, nfrLIList);
                    }
                    NFR_LI__c nfrLi = new NFR_LI__c(NFR__c = accountIdNFRMap.get(a.Id).Id,
                     Product__c = skuMatrix.Product__c, Configured_SKU__c = skuMatrix.Configured_SKU__c, Quantity__c = skuMatrix.Default_Quantity__c, NFR_Product_Name__c= skuMatrix.Name );
                    nfrLIList.add(nfrLi);
                    allNfrLI.add(nfrLi);
                    //allProducts.add(skuMatrix.Product__c);
                }

            }
        }

        insert allNfrLI;
        System.debug('allNfrLI = ' + allNfrLI);
        System.debug('nfr_nfrLIMap = ' + nfr_nfrLIMap);

        createNFROpportunitiesPreApproved(accountIdNFRMap.values());

        return accountIdNFRMap.values();
    }

    public static Boolean verifyIsPartnerOrISV(Account a) {
        System.debug('verifyIsPartnerOrISV(): a.PartnerStatuses__c = ' + a.PartnerStatuses__c);
        if (a.PartnerStatuses__c != null && a.PartnerStatuses__c.indexOf('-') > -1) {
            String partnerType = a.PartnerStatuses__c.substring((a.PartnerStatuses__c.indexOf('-') + 1)).trim();
            System.debug('verifyIsPartnerOrISV(): partnerType = ' + partnerType);
            return (partnerType.equalsIgnoreCase('Corporate Reseller') || partnerType.equalsIgnoreCase('Reseller') || partnerType.equalsIgnoreCase('ISV') || partnerType.equalsIgnoreCase('Systems Integrator') );
        }
        return false;
    }

    private static void createNFROpportunitiesPreApproved(NFR_Request__c[] nfrlist) {
    	Set<Id> idlist = new Set<Id>();
    	for (NFR_Request__c nfr : nfrlist) {
    		System.debug('[debug]-------------------------- processing id ' + nfr.Id);
    		idlist.add(nfr.Id);
    	}
    	createNFROpportunity(idlist);
    }

	*/

    static private Address__c findAddress(Address__c[] addressList, String partyId, String trueField) {
        for (Address__c addr : addressList) {
            if (addr.Sales_Account__r.CDH_Party_Name__r.CDH_Party_Number_Ext__c == partyId && addr.get(trueField) == true) {
                return addr;
            }
        }
        //
        // Found nothing specific, default to identifying address
        //
        if (trueField != 'Identifying_Address__c') {   // prevent infinite loop
            return findAddress(addressList, partyId, 'Identifying_Address__c');
        }
        return null;
    }

    public static void createNFROpportunity(Set<Id> nfrIds) {

        Set<Id> allProducts = new Set<Id>();
        Set<String> allCurrencies = new Set<String>();
        List<Opportunity> opportunityList = new List<Opportunity>();
        List<OpportunityLineItem> pliList = new List<OpportunityLineItem>();

        Map<Id, NFR_Request__c> nfrMap = new Map<Id, NFR_Request__c>([
        	Select	Id, Partner__c,
           			Partner__r.Global_Region__c, Partner__r.Name, Partner__r.OwnerId, Name, Partner__r.BillingCountry,
                    Contact_at_Partner__r.Email, Contact_at_Partner_Email__c,
					CurrencyIsoCode, RHN_Login__c, (Select Id, Product__c, Configured_SKU__c, Quantity__c from NFR_LIs__r)
            from	NFR_Request__c
            where	Id In :nfrIds
        ]);

        //
        // Find related sales account for partners via EBS_Account__c table and use to populate data
        //
        Map<ID,Account> partnerMap = new Map<ID,Account>([
            select  Id, CDH_Party_Name__c, CDHPartyNumber__c, BillingStreet, BillingCity, BillingState, BillingCountry, BillingPostalCode
            from    Account
            where   Id in :PartnerUtil.getStringFieldSet(nfrMap.values(), 'Partner__c')
        ]);
        Set<String> partyIdList = new Set<String>();
        for (Account acct : partnerMap.values()) {
            if (acct.CDHPartyNumber__c != null) {
                partyIdList.add(acct.CDHPartyNumber__c);
            }
        }
        System.debug('***** [debug] ***** partyidlist size=' + partyIdList.size());
        EBS_Account__c[] ebsAccounts = [
            select  Id, CDH_Party_Number__c, Sales_Account__c, Primary_EBS_Account__c
            from    EBS_Account__c
            where   CDH_Party_Number__c in :partyIdList
        ];

        //
        // US66101 - need to filter esb account list
        //
        // Arrange by party number since there can be multiple ebs accounts per
        Map<String,List<EBS_Account__c>> ebsmap = new Map<String,List<EBS_Account__c>>();
        for (EBS_Account__c ebsAcct : ebsAccounts) {
            if (ebsmap.containsKey(ebsAcct.CDH_Party_Number__c)) {
                EBS_Account__c[] ebslist = ebsmap.get(ebsAcct.CDH_Party_Number__c);
                if (ebslist == null) {
                    ebslist = new List<EBS_Account__c>();
                    ebsmap.put(ebsAcct.CDH_Party_Number__c, ebslist);
                }
                ebslist.add(ebsAcct);
            }
        }
        // Now we have a map as follows:
        //   KEY: cdh party 1 -> LIST: ebs account 1, ebs account 2, ...
        //   KEY: cdh party 2 -> LIST: ebs account 3, ebs account 4, ...
        // For each list of ebs accounts per party number reduce down to just one.
        // If there is only 1 account, use that one.
        // If there are multiple, find the primary. If there is no primary, do nothing
        //
        ebsAccounts = new List<EBS_Account__c>();   // replace original list with new filtered list so logic below doesn't need to change
        for (List<EBS_Account__c> ebslist : ebsmap.values()) {
            if (ebslist.size() == 1) {
                ebsAccounts.add(ebslist.get(0));
            }
            else {
                for (EBS_Account__c acct : ebslist) {
                    if (acct.Primary_EBS_Account__c) {
                        ebsAccounts.add(acct);
                        break;
                    }
                }
            }
        }


        Map<String, ID> partyEBSMap = new Map<String,ID>();
        Map<String,ID> partySalesMap = new Map<String,ID>();
        Set<ID> salesIdList = new Set<ID>();
        for (EBS_Account__c ebsAcct : ebsAccounts) {
            partySalesMap.put(ebsAcct.CDH_Party_Number__c, ebsAcct.Sales_Account__c);
            salesIdList.add(ebsAcct.Sales_Account__c);
            partyEBSMap.put(ebsAcct.CDH_Party_Number__c, ebsAcct.Id);
        }
        Address__c[] addressList = [
            select  Id, Sales_Account__c, Sales_Account__r.CDH_Party_Name__r.CDH_Party_Number_Ext__c,
                    Identifying_Address__c, Bill_to_Address__c, Ship_To_Address__c, Sold_To_Address__c,
                    Entitle_To_Address__c
            from    Address__c
            where   Sales_Account__c in :salesIdList
            and     (Bill_To_Address__c = true or Entitle_To_Address__c = true or Ship_To_Address__c = true or Sold_To_Address__c = true or Identifying_Address__C = true)
        ];


        Set<String> billingCountries = new Set<String>();
        for (NFR_Request__c nfr : nfrMap.values()) {
            billingCountries.add(nfr.Partner__r.BillingCountry);
            allCurrencies.add(nfr.CurrencyIsoCode);
        }

        Id pricebookId = NFRUtil.getDefaultPriceBook();

        Countries countriesWrapper = new Countries(billingCountries);

        //get all the NFRLI associated
        System.debug('[debugNFR].......................... nfr count=' + nfrMap.size());

        /** Commenting using the LoginId as dup detector since its gets wiped of by CDH

            //get contacts from the sales account which matches the RHN Login on NFR
            List<Contact> salesAccCon = [select id, LoginName__c from Contact Where AccountId in: salesIdList and LoginName__c in: PartnerUtil.getStringFieldSet(nfrMap.values(), 'RHN_Login__c')];
            Map<String, ID> loginNameContacts = new Map<String, ID>();

            for(Contact con: salesAccCon) {
                loginNameContacts.put(con.LoginName__c, con.id);
            }
        */

        //get contacts from the sales account which matches the Email on NFR for dup elimination
        List<Contact> salesAccCon = [select id, Email from Contact Where AccountId in: salesIdList and Email in: PartnerUtil.getStringFieldSet(nfrMap.values(), 'Contact_at_Partner_Email__c')];
        Map<String, ID> emailContacts = new Map<String, ID>();

        for(Contact con: salesAccCon) {
            emailContacts.put(con.Email, con.id);
        }


        for (NFR_Request__c nfr : nfrMap.values()) {
            //get the right country

            String countryOfOrder = countriesWrapper.getCountryOfOrder(nfr.Partner__r.BillingCountry);
            if (countryOfOrder == null) {
                nfr.addError('Billing Country not found in list of Countries.');
                continue;
            }

            Account partnerAccount = partnerMap.get(nfr.Partner__c);
/*
            if (partnerAccount.CDH_Party_Name__c == null) {
                nfr.addError('CDH Party is missing on the partner account');
                continue;
            }
*/

            ID primaryEBSAccount = partyEBSMap.get(partnerAccount.CDHPartyNumber__c);
            Address__c billToAddress = findAddress(addressList, partnerAccount.CDHPartyNumber__c, 'Bill_To_Address__c');
            Address__c shipToAddress = findAddress(addressList, partnerAccount.CDHPartyNumber__c, 'Ship_To_Address__c');
            Address__c entitleToAddress = findAddress(addressList, partnerAccount.CDHPartyNumber__c, 'Entitle_To_Address__c');
            Address__c soldToAddress = findAddress(addressList, partnerAccount.CDHPartyNumber__c, 'Sold_To_Address__c');

/*
            if (billToAddress == null) {
                nfr.addError('Bill-To Address could not be determined from CDH Party Number ' + partnerAccount.CDHPartyNumber__c);
                continue;
            }
            if (shipToAddress == null) {
                nfr.addError('Ship-To Address could not be determined from CDH Party Number ' + partnerAccount.CDHPartyNumber__c);
                continue;
            }
            if (soldToAddress == null) {
                nfr.addError('Sold-To Address could not be determined from CDH Party Number ' + partnerAccount.CDHPartyNumber__c);
                continue;
            }
            if (entitleToAddress == null) {
                nfr.addError('Entitle-To Address could not be determined from CDH Party Number ' + partnerAccount.CDHPartyNumber__c);
                continue;
            }
*/

            // changed Opportunity StageName to 'Prepare' as Value Selling Enhancement July 20th Release.
            Opportunity opp = new Opportunity(AccountId = nfr.Partner__c,
                RecordTypeId = NFRUtil.getNfrRT(),
                NFR__c = nfr.Id,
                Pricebook2Id = pricebookId,
                CloseDate = Date.today().addDays(30),
                StageName = 'Prepare',
                // Name = nfr.Partner__r.Name + ' - NFR Opp',
                Name = 'Opp-' + nfr.Name,
          //      DateOrderSubmitted__c = DateTime.now(),
                Region__c = nfr.Partner__r.Global_Region__c,
                Country_Of_Order__c = countryOfOrder,
                CurrencyIsoCode = nfr.CurrencyIsoCode,
                OwnerId = nfr.Partner__r.OwnerId);

            opp.Bill_To_Account__c = primaryEBSAccount;
            if (billToAddress != null) {
                opp.Bill_To_Address__c = billToAddress.Id;
                opp.Bill_To_Sales_Account__c = billToAddress.Sales_Account__c;
            }
            opp.Ship_To_Account__c = primaryEBSAccount;
            if (shipToAddress != null) {
                opp.Ship_To_Address__c = shipToAddress.Id;
                opp.Ship_To_Sales_Account__c = shipToAddress.Sales_Account__c;
            }
            opp.Sold_To_Account__c = primaryEBSAccount;
            if (soldToAddress != null) {
                opp.Sold_To_Address__c = soldToAddress.Id;
                opp.Sold_To_Sales_Account__c = soldToAddress.Sales_Account__c;
            }
            opp.Entitle_To_Account__c = primaryEBSAccount;
            if (entitleToAddress != null) {
                opp.Entitle_To_Address__c = entitleToAddress.Id;
                opp.Entitle_To_Sales_Account__c = entitleToAddress.Sales_Account__c;
            }
            opp.Order_Status__c = 'Submitted for OM Review';
            opp.Pending_OM_Review__c = true;
            opp.Future_Reporting_Requirement__c = 'No';
            opp.OpportunityType__c = 'Standard';
            opp.CDH_Party_Number__c = partnerAccount.CDHPartyNumber__c;
            opp.FulfillmentChannel__c = 'Direct End Customer';

            /*
            if (nfr.Contact_at_Partner__c != null) {
                opp.Ship_To_Contact__C = nfr.Contact_at_Partner__c;
                opp.Bill_To_Contact__C = nfr.Contact_at_Partner__c;
                opp.Entitle_To_Contact__C = nfr.Contact_at_Partner__c;
                opp.Sold_To_Contact__C = nfr.Contact_at_Partner__c;
            }
            */

            //populate Bill-to, Ship-to, Entitle-to and Sold-to contacts on oppty
            if(emailContacts.containsKey(nfr.Contact_at_Partner__r.Email)) {
                opp.Ship_To_Contact__C = emailContacts.get(nfr.Contact_at_Partner__r.Email);
                opp.Bill_To_Contact__C = emailContacts.get(nfr.Contact_at_Partner__r.Email);
                opp.Entitle_To_Contact__C = emailContacts.get(nfr.Contact_at_Partner__r.Email);
                opp.Sold_To_Contact__C = emailContacts.get(nfr.Contact_at_Partner__r.Email);
            }

            opportunityList.add(opp);

            List<NFR_LI__c> nfrLIs = nfr.NFR_LIs__r;
            for (NFR_LI__c nfrLI : nfrLIs) {
                allProducts.add(nfrLi.Product__c);
            }
        }

        System.debug('opportunityList = ' + opportunityList);
        if (! opportunityList.isEmpty()) {
            insert opportunityList;
        }

        Map<String, Map<Id, PricebookEntry>> pb_prod_pbe_Map = NFRUtil.getPricebookEntries(allProducts, pricebookId, allCurrencies);
        System.debug('pb_prod_pbe_Map = ' + pb_prod_pbe_Map);

        //now we need to add the PLI to the opp
        for (Opportunity opp : opportunityList) {
            Id nfrId = opp.NFR__c;
            System.debug('nfrId = ' + nfrId);
            //sku to create
            List<NFR_LI__c> nfrLIList = nfrMap.get(nfrId).NFR_LIs__r;
            System.debug('nfrLIList = ' + nfrLIList);
            if (nfrLIList == null || nfrLIList.isEmpty()) {
                System.debug('THIS LIST IS NULL!!!');
                continue;
            }

            for (NFR_LI__c nfrLI : nfrLIList) {
                OpportunityLineItem pli = new OpportunityLineItem(OpportunityId = opp.Id);
                pli.UnitPrice = 0;  //always 0 price

                if(pb_prod_pbe_Map.containsKey(opp.CurrencyIsoCode)){
                    System.debug('pricebookId = ' + pricebookId);
                   if(pb_prod_pbe_Map.get(opp.CurrencyIsoCode).containsKey(nfrLI.Product__c)){
                        System.debug('Product__c = ' + nfrLI.Product__c);
						//MH
						pli.Quantity = nfrLI.Quantity__c;
						pli.Configured_SKU__c = nfrLI.Configured_SKU__c;
                        pli.PricebookEntryId = pb_prod_pbe_Map.get(opp.CurrencyIsoCode).get(nfrLI.Product__c).Id;
                        pli.Entitle_To_Account__c = opp.Entitle_To_Account__c;
                        pli.Entitle_To_Address__c = opp.Entitle_To_Address__c;
                        pli.Entitle_To_Sales_Account__c = opp.Entitle_To_Sales_Account__c;
                        pli.Entitle_To_Contact__c = opp.Entitle_To_Contact__c;
                        pliList.add(pli);
                    }
                }
            }
            //nfr_nfrLIMap.keySet()
        }
        System.debug('pliList = ' + pliList);
        if (! pliList.isEmpty()) {
            insert pliList;
        }

        // now update the opp to closed won.
        for (Opportunity opp : opportunityList) {
            opp.StageName = 'Closed Won';
            opp.DateOrderSubmitted__c = DateTime.now();
        }

        update opportunityList;
    }

    public static Boolean match(Account a, NFR_SKU_Matrix__c skuMatrix) {
        String partnerType = '';
        String classification = '';
        if (a.PartnerStatuses__c != null && a.PartnerStatuses__c.indexOf('-') > -1) {
            partnerType = a.PartnerStatuses__c.substring((a.PartnerStatuses__c.indexOf('-') + 1)).trim();
            classification = a.PartnerStatuses__c.substring(0, (a.PartnerStatuses__c.indexOf('-'))).trim();
            //'Partner - Advanced Partner';
        }
        System.debug('partnerType = ' + partnerType);
        System.debug('classification = ' + classification);
        return (NFRUtil.compare(a.Global_Region__c, skuMatrix.Global_Region__c) &&
            NFRUtil.compare(partnerType, skuMatrix.Partner_Type__r.Name) &&
            NFRUtil.compare(classification, skuMatrix.Partner_Tier__r.Name));
    }

    public static void createTask(List<Opportunity> oppList) {
        List<Task> taskList = new List<Task>();
        Id recordTypeId = [Select Id from RecordType where Name='OM Processing Task' And SObjectType='Task'].Id;
        for (Opportunity opp : oppList) {
            if (opp.NFR__c == null) { //not a nfr opp
                continue;
            }
            taskList.add(new Task(
                Subject = 'NFR',
                ActivityDate = Date.today().addDays(30),
                RecordTypeId = recordTypeId));
        }

        if (! taskList.isEmpty()) {
            insert taskList;
        }
    }

    /* Submits an object for approval*/
    public static Approval.ProcessResult submitForApproval(Id objId, String message) {
        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
        req.setComments(message);
        req.setObjectId(objId);
        Approval.ProcessResult result = Approval.process(req,false);
        return result;
    }

    /*
    * Wrapper class for list of countries.
    */
    class Countries {
        Map<String, Country__c> countryNameMap = new Map<String, Country__c>();
        Map<String, Country__c> countryIso2Map = new Map<String, Country__c>();
        Map<String, Country__c> countryIso3Map = new Map<String, Country__c>();

        public Countries(Set<String> billingCountries) {
            for (Country__c c : [Select Id, Name, Country_of_Order__c,
                Iso3166Alpha2__c, Iso3166Alpha3__c from Country__c where
                    (Iso3166Alpha3__c In :billingCountries OR Iso3166Alpha2__c In :billingCountries
                     OR Name In :billingCountries)])
            {
                countryNameMap.put(c.Name.toUpperCase(), c);
                countryIso2Map.put(c.Iso3166Alpha2__c, c);
                countryIso3Map.put(c.Iso3166Alpha3__c, c);
            }

        }

        public String getCountryOfOrder(String billingCountry) {
            if(billingCountry == null) return null;
            billingCountry = billingCountry.toUpperCase();
            String countryOfOrder = null;
            if (billingCountry.length() == 2) {
                if (countryIso2Map.containsKey(billingCountry)) {
                    countryOfOrder = countryIso2Map.get(billingCountry).Country_of_Order__c;
                }
            }  else if (billingCountry.length() == 3) {
                if (countryIso3Map.containsKey(billingCountry)) {
                    countryOfOrder = countryIso3Map.get(billingCountry).Country_of_Order__c;
                }
            }
            //check in name if still not found
            if (countryOfOrder == null && countryNameMap.containsKey(billingCountry)) {
                countryOfOrder = countryNameMap.get(billingCountry).Country_of_Order__c;
            }

            return countryOfOrder;

        }
    }

    /*
    testMethod static void countriesTest() {
        Country__c country = new Country__c(Name = 'Test Country', Iso3166Alpha2__c = 'T1',
            Iso3166Alpha3__c = 'T12', Country_of_Order__c = 'United Test Country',
            Global_Region__c = 'TEST');
        insert country;

        Set<String> billingCountries = new Set<String> {'T1'};
        Countries c = new Countries(billingCountries);

        String countryOfOrder = c.getCountryOfOrder('T1');
        System.assertEquals(countryOfOrder, 'United Test Country');

        countryOfOrder = c.getCountryOfOrder('T12');
        System.assertEquals(countryOfOrder, 'United Test Country');

        countryOfOrder = c.getCountryOfOrder('Test Country');
        System.assertEquals(countryOfOrder, 'United Test Country');

        countryOfOrder = c.getCountryOfOrder('Testing Country');
        System.assert(countryOfOrder == null);

        //test case
        countryOfOrder = c.getCountryOfOrder('t12');
        System.assertEquals(countryOfOrder, 'United Test Country');
    }


    testMethod static void unit() {
        Account acct = PartnerTestUtils.basicAccountSetup('NFR unit test');
        PartnerTestUtils.makeAccountISV(acct.id);
        insert PartnerTestUtils.makeContact(acct.Id, 'masmith010101');
        Set<Id> accountSet = new Set<Id>();
        accountSet.add(acct.Id);
        NFRCreateOnOnboarding.createNFRNotFuture(accountSet);
    }
*/

}