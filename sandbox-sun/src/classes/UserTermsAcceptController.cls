public class UserTermsAcceptController {

    private String       provider;
    private Agreement__c agreement;
    public  Attachment   agreementDoc {get; set; }
    public  Boolean      termsDeclined {get; set; }
    public  DomainValidation__c domain;

    public UserTermsAcceptController() {
        termsDeclined = false;
    }

    public PageReference init() {

        provider = ApexPages.currentPage().getParameters().get('provider');
        domain = DomainValidation__c.getValues(provider);
        if (provider != null && UserAgreementsHelper.hasAcceptedForFeature(UserInfo.getUserId(), provider)) {
            return getRedirectPage();
        }

        agreement = UserAgreementsHelper.getAgreementForFeature(UserInfo.getLanguage(), provider);
        if (agreement == null || agreement.Attachments.size() != 1) {
            // what do we do here -- continue or throw an error?
            System.debug('*****[debug]***** No agreement or attachment found for provider ' + provider);
            return null;
        }
        agreementDoc = agreement.Attachments.get(0);
        return null;
    }

    public String getForwardLink() {
        return domain.ProviderURL__c;
    }

    private PageReference getRedirectPage() {
//        Auth_Token__c atoken = new Auth_Token__c(User__c = UserInfo.getUserId(), Token__c = UserInfo.getSessionId());
//        insert atoken;
        PageReference ref = new PageReference(getForwardLink());
//        ref.getParameters().put('rhauthtoken', atoken.Token__c);
        ref.setRedirect(true);
        return ref;
    }

    public PageReference acceptTerms() {
        termsDeclined = false;
        User_Agreement__c ua = UserAgreementsHelper.acceptAgreement(UserInfo.getUserId(), agreement.Id);
        return getRedirectPage();
    }

    public PageReference declineTerms() {
        termsDeclined = true;
//        if (ApexPages.currentPage().getHeaders().get('Referer') != null) {
//            return new PageReference(ApexPages.currentPage().getHeaders().get('Referer'));
//        }
        return null;
    }
}