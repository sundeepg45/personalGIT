/*
Checks if the NFR has any line items. If no shows an error else submits nfr for approval
Req - If done as an entry criteria on approval, error msg is not clean
Button on NFR - "Submit NFR"
*/
public class NFRApprovalExtension {

  private ApexPages.StandardController controller;

   /* Submits an object for approval*/
    public static Approval.ProcessResult submitForApproval(Id objId, String message) {
        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
        req.setComments(message);
        req.setObjectId(objId);
        Approval.ProcessResult result = Approval.process(req,false);
        return result;
    }

  public NFRApprovalExtension(ApexPages.StandardController controller) {
    this.controller = controller;
  }

  //called as an init action from the VF page
  public PageReference submitForApproval() {

    NFR_Request__c nfrM = [Select Partner__r.BillingCountry, NFRLI_Count__c from NFR_Request__c where Id = :this.controller.getId()];
        Set<String> billingCountries = new Set<String>();
        if (nfrM.Partner__r.BillingCountry != null){
            billingCountries.add(nfrM.Partner__r.BillingCountry);
        }

        Countries countriesWrapper = new Countries(billingCountries);

        String countryOfOrder = countriesWrapper.getCountryOfOrder(nfrM.Partner__r.BillingCountry);
        if (countryOfOrder == null) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.SEVERITY.ERROR, 'Account Billing Country Error. The Billing Country on the Account does not match any of the ISO Alpha 2 codes on the Country table.  Please validate the Billing Country on the Partner Account prior to submitting the NFR.'));
        }

        if (nfrM.NFRLI_Count__c == null || nfrM.NFRLI_Count__c == 0) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.SEVERITY.ERROR, 'NFR without products cannot be submitted for approval. Please return to the NFR and add Products.'));
        }

        if (nfrM.NFRLI_Count__c != null && nfrM.NFRLI_Count__c != 0 && countryOfOrder != null) {
          try {
            Approval.ProcessResult result = submitForApproval(this.controller.getId(), 'Submitting NFR for Approval.');
            if (result.isSuccess()) {
              ApexPages.addMessage(new ApexPages.Message(ApexPages.SEVERITY.INFO, 'NFR submitted for approval.'));
            } else {
              ApexPages.addMessage(new ApexPages.Message(ApexPages.SEVERITY.ERROR, 'Failed to submit NFR for approval. There are no matching Approval Policies for NFRs that are already approved or in an Approval process'));
            }
          } catch(Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.SEVERITY.ERROR, e.getMessage()));
          }
        }
        return null;
  }

/*BEGIN MH Billing Country*/
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

        User owner  = [Select Id, FirstName, LastName, FederationIdentifier from User where Profile.Name = 'System Administrator' and isActive = true limit 1];

        CDH_Party__c cdhParty = new CDH_Party__c();
        cdhParty.CDH_Party_Name__c = 'Test';
        insert cdhParty;

        Account account = new Account();
        account.CDH_Party_Name__c = cdhParty.Id;
        account.Name ='Test Acc';
        account.Global_Region__c ='APAC';
        account.OwnerId = owner.Id;
        account.BillingCountry = 'US';
        insert account;

        Contact cont = new Contact();
        cont.OwnerId = owner.Id;
        cont.AccountId = account.Id;
        cont.LoginName__c = 'someone@redhat.com';
        cont.FirstName ='FS';
        cont.LastName = 'LS';
        cont.email = 'a@b.com';
        insert cont;

        owner.FederationIdentifier = cont.LoginName__c;
        update owner;

        NFR_Request__c nfrRequest = new NFR_Request__c();
        nfrRequest.Contact_at_Partner__c = cont.Id;
        nfrRequest.Partner__c = account.Id;
        nfrRequest.OwnerId = owner.Id;
        nfrRequest.Partner_Status__c ='Ready - Reseller';
        nfrRequest.User_RHN_Entitlement_Login__c = owner.FederationIdentifier;
        insert nfrRequest;


        Product2 prd = new Product2();
        prd.Name ='Test';
        prd.LATAM_Product__c = true;
        prd.Family ='RHX';
        prd.CurrencyIsoCode ='USD';
        prd.IsActive = true;
        prd.for_NFR__c = true;
        insert prd;
        NFR_LI__c nfrLine = new NFR_LI__c();
        nfrLine.Product__c = prd.Id;
        nfrLine.NFR__c = nfrRequest.Id;
        nfrLine.Quantity__c =4;
        insert nfrLine;
        nfrRequest.Status__c ='Approved';
        update   nfrRequest;

         NFRApprovalExtension controller = new NFRApprovalExtension(new ApexPages.StandardController(nfrRequest));

         controller.submitForApproval();
    }
/*END MH Billing Country*/
}