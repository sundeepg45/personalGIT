public with sharing class Teaming_Agreement_Redirect {

    public Boolean              hasAgreements   {get; private set;}
    public List<Agreement__c>   agreements      {get; private set;}

    private Account             account;
    private Id                  countryId;

    public Teaming_Agreement_Redirect(ApexPages.StandardController controller) {
    }

    public void init() {
        User user = [
            select  Id,
                    Contact.AccountId
            from    User
            where   Id = :UserInfo.getUserId()
        ];
        account = [
            select  Id,
                    Name,
                    BillingCountry,
                    Finder_Partner_Type__c
            from    Account
            where   Id = :user.Contact.AccountId
        ];
        countryId = [
            select  Id,
                    Name,
                    Abbreviation__c
            from    Country__c
            where   Abbreviation__c = :account.BillingCountry
        ].Id;
        agreements = getTeamingAgreements();
        hasAgreements = agreements.size() > 0;
    }

    private List<Agreement__c> getTeamingAgreements() {
        List<Agreement__c> agreementList = new List<Agreement__c>();

        if (countryId != null && account != null) {

            // Here we are getting all the documents for a country.
            // We want all agreements for the user's preferred language and all non-specific ones
            Set<Id> agreementIdSet = new Set<Id>();
            List<Agreement_Country__c> agreementCountryList = [
                select  Agreement__c
                from    Agreement_Country__c
                where   Country__c = :countryId
                and     Agreement__r.PartnerType__c = :account.Finder_Partner_Type__c
                and Agreement__r.ActivationStatus__c = 'Active'
                and Agreement__r.Partner_Program__c = null
                and (Agreement__r.Type__c = 'Teaming')
            ];
            for(Agreement_Country__c agreementCountry :agreementCountryList) {
                agreementIdSet.add(agreementCountry.Agreement__c);
            }

            if (agreementIdSet != null && agreementIdSet.size() > 0) {
                    agreementList = [
                        select  Id,
                                Name,
                                Is_Terms_Document__c,
                                IsSignatureRequired__c,
                                Version__c,
                                (select Name
                                 from Attachments)
                        from    Agreement__c
                        where   Id
                        in      :agreementIdSet and Is_Terms_Document__c = False
                    ];
            }

            // Here we are getting all the global documents.
            // Prefer language-specific ones over the non-language defaults
            List<Agreement__c> globalAgreementList  = [
                    select  Id,
                            Name,
                            IsSignatureRequired__c,
                            Is_Terms_Document__c,
                            Version__c,
                            (select Name
                             from Attachments)
                    from    Agreement__c
                    where   Country_Count__c = 0
                    and     ActivationStatus__c = 'Active'
                    and     PartnerType__c = :account.Finder_Partner_Type__c
                    and     Partner_Program__c = null
                    and     Type__c != 'User'
            ];
            if (globalAgreementList != null && globalAgreementList.size() > 0) {
                for (Agreement__c globalAgreement :globalAgreementList) {
                    agreementList.add(globalAgreement);
                }
            }
        }

        if (agreementList != null && agreementList.size() > 0) {
            System.debug('Agreement List---------->::' + agreementList.size());
        }

        return agreementList;
    }
}