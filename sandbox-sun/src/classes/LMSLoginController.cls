public without sharing class LMSLoginController {
    
    public User me { get; set; }
    public String timestamp { get; set; }
    public Boolean shouldProvisionUser { get; set; }
    public Boolean provisioningUser { get; set; }
    public String returnURL { get; set; }
    public String errorMessage { get; set; }
    public String stepsToReproduce { get; set; }
    public Boolean caseCreated { get; set; }
    public Id caseId { get; set; }
    
    public Boolean testingSkipCallout { get; set; }
    
    private STConnector stconn;
    
    public LMSLoginController()
    {
        provisioningUser = false;
        testingSkipCallout = false;
        me = [select Id, Username, SumTotal_ID__c, Profile.Name, ContactId, FederationIdentifier, Channel_Role__c, Contact.Account.IsPartner from User where Id = :UserInfo.getUserId()];
        stconn = new STConnector();
        
        if (me.SumTotal_ID__c == null && errorMessage == null){
            shouldProvisionUser = true;
        }   
        
        //isAdmin = me.Profile.Name == 'Administrator - Level 2' || me.Profile.Name == 'Administrator - Level 1';
        timestamp = Datetime.now().format('yyyy:MM:dd:HH:mm:ss', 'US/Pacific');
        returnURL = ApexPages.currentPage().getParameters().get('redirect');
    }
    
    public Boolean getHasTrack(){
        if (getIsPartnerUser()){
            // Partner users should have a track
            Integer i = [select count () from Contact_Track__c where Contact__c = :me.ContactId];
            return i > 0;
        } else {
            // Internal users should have a channel role
            return me.Channel_Role__c != null && me.Channel_Role__c != '';
        }
        return true;
    }

    public Boolean getIsPartnerUser(){
        return me.ContactId != null && me.Contact.Account.IsPartner;
    }
    
    public String getAuthToken()
    {
        return EncodingUtil.convertToHex(Crypto.generateDigest('MD5', Blob.valueOf(getSSOUsername() + timestamp + StringSetting__c.getInstance('SumTotal.LMS.SSO.Secret').Value__c)));
    }
    
    public String getSSOUsername()
    {
        if (me.UserName.length() > 30){
            return me.UserName.substring(0,30);
        }
        return me.UserName;
    }
    
    public PageReference provisionUser(){
        shouldProvisionUser = false;
        provisioningUser = true;
        STConnector.JSONResponse response = null;
        if (testingSkipCallout){
            response = new STConnector.JSONResponse();
            response.status = 'fail';
            errorMessage = 'bob';
        } else {
            try {
                response = stconn.createUser(me.Id);
                if (response == null) {
                    errorMessage = System.label.LMS_Not_Responding;
                }
                else {
                    if (response.status == 'fail') {
                        errorMessage = response.reason;
                    }
                }
            }
            catch (STConnector.STDuplicateUserException ex) {
                me.SumTotal_ID__c = ex.userid;
                update me;
            }
            catch (STConnector.STException ex) {
                errorMessage = ex.getMessage();
            }
        }
        provisioningUser = false;
        return null;
    }
    
    public PageReference createLMSDownCase() {

        Id partnerGeneralIssuesRecordTypeId = [        
            select id
              from RecordType
             where sObjectType = 'Case'
               and Name = 'Partner General Issues' 
        ].id;
        
        Case c = new Case();

        if (me.ContactId != null){
            Contact con = [Select
                            Id,
                            AccountId,
                            Account.Global_Region__c,
                            Account.ShippingCountry
                         from
                            Contact
                         where
                            Id = :me.ContactId
                         ];
            
            c.Region__c = con.Account.Global_Region__c;
            c.Country__c = con.Account.ShippingCountry;
            c.AccountId = con.AccountId;
            c.ContactId = con.Id;
        }
        
        c.RecordTypeId = partnerGeneralIssuesRecordTypeId;
        c.Issue_Type_Classification__c = 'General Questions';
        c.Issue_Type__c = 'LMS Access';
        c.Subject = 'Partner is having issues accessing the LMS';
        c.Description = 'The following error has occurred: ' + errorMessage + '\n\nSteps to Reproduce:\n' + stepsToReproduce;
        
        System.debug('Case Description ***** ' + c.Description);
        
        c.Origin = 'Email-to-case-LMS';
        c.RedHatLoginName__c = me.FederationIdentifier;
        c.Status = 'New';
        c.Priority = 'Medium';
        
        Database.Dmloptions dmo = new Database.Dmloptions();
        dmo.assignmentRuleHeader.useDefaultRule = true;
        c.setOptions(dmo);        

        insert c;
        caseCreated = true;
        caseId = c.Id;
        return null;
    }
}