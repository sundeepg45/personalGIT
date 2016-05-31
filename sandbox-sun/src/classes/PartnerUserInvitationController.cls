/*
 * This controller combines methods for invitation management and for user acceptance/decline of a particular invite.
 */
public without sharing class PartnerUserInvitationController {

    private static final String EMAIL_TEMPLATE = 'Partner_User_Invitation';
    public Partner_User_Invitation__c[] invitations { get; set; }
    public String declinedJoinReason { get; set; }
    public String joinAcceptance {get; set; }
    private String invitationId = null;
    public String commandInvitationId {get; set; }

    /*
     * user invite form fields
     */
    public String formFirstName {get; set; }
    public String formLastName  {get; set; }
    public String formStreet    {get; set; }
    public String formCity      {get; set; }
    public String formState     {get; set; }
    public String formPostalCode {get; set; }
    public String formPhone     {get; set; }
    public String formLogin     {get; set; }


    public PartnerUserInvitationController() {
    }

    public PartnerUserInvitationController(ApexPages.StandardController controller) {
    }

    /*************************************************
     * These methods are for handling a user invite
     */

    public PageReference continueInvitation() {
        if (joinAcceptance == null || (joinAcceptance != 'Yes' && joinAcceptance != 'No')) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.Partner_User_Please_select_Yes_or_No));
            return null;
        }
        Partner_User_Invitation__c[] invites = [
            select  Id,
                    Email__c,
                    federationId__c,
                    ProfileId__c,
                    Account__c,
                    EmailEncodingKey__c,
                    LanguageLocaleKey__c,
                    LocaleSidKey__c,
                    TimeZoneSidKey__c,
                    isUserAdmin__c,
                    Response_Type__c
            from    Partner_User_Invitation__c
            where   Id = :invitationId
        ];

        if (invites.size() == 0) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, System.Label.Partner_User_Inviation_Not_Available));
            return null;
        }
        Partner_User_Invitation__c invite = invites.get(0);
        if (invite.Response_Type__c == 'A') {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, System.Label.Partner_User_Already_Accepted));
        	return null;
        }
        invite.Date_Responded__c = System.now();
        if (joinAcceptance == 'Yes') {
            invite.Response_Type__c = 'A';
        }
        if (joinAcceptance == 'No') {
            invite.Response_Type__c = 'D';
            invite.Declined_Reason__c = declinedJoinReason;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, System.Label.Partner_User_processed_decline));
            try {
            	delete [select Id from Contact where LoginName__c = :invite.federationId__c limit 1];
            } catch (System.Exception ex) {
            }
            update invite;
            return null;
        }

        List<User> tmp = [select Id from User where FederationIdentifier = :invite.federationId__c];
        if (tmp.size() > 0) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, System.Label.Partner_User_user_already_exists));
            return null;
        }

        enablePartnerUser(invite);
        update invite;
        PageReference pr = new PageReference(System.Label.Red_Hat_Domain_Name + '/wapps/sfconnector/protected/partner.html');
        pr.setRedirect(true);
        return pr;
    }

    public static boolean sendMail(Partner_User_Invitation__c invite) {
        List<EmailTemplate> tmp = [select Id, Name, Body, Subject from EmailTemplate where IsActive=true and DeveloperName = :EMAIL_TEMPLATE];
        System.assert(tmp.size() != 0, '** Missing email template ' + EMAIL_TEMPLATE);
        EmailTemplate et = tmp.get(0);

 		Contact[] contacts = [select Id from Contact where LoginName__c = :invite.federationId__c limit 1];
 		Contact contact = null;
 		if (contacts.size() == 0) {
 			contact = createContact(invite);
 		}
 		else {
 			contact = contacts.get(0);
 		}

        //String body = templateSubstitute(invite, et.Body);
        //String subject = templateSubstitute(invite, et.Subject);
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        //mail.setPlainTextBody(body);
        //mail.setSubject(subject);
        mail.setTemplateId(et.Id);
        mail.setWhatId(invite.Id);
        mail.setTargetObjectId(contact.Id);

        OrgWideEmailAddress owe = [select id, Address from OrgWideEmailAddress where Address = 'no-reply-partners@redhat.com' limit 1];
        mail.setReplyTo('noreply@redhat.com');
        mail.setOrgWideEmailAddressId(owe.id);
        mail.saveAsActivity = FALSE;

        //mail.setToAddresses(new String [] {invite.Email__c} );
        Messaging.SendEmailResult[] results = Messaging.sendEmail(new Messaging.Email[] { mail });
        System.assert(results.size() > 0, '"Unexpected return result from sendEmail()');
        Messaging.SendEmailResult result = results.get(0);
        if (!result.isSuccess()) {
            Messaging.SendEmailError[] errors = result.getErrors();
            System.debug('** ERROR ***** ' + errors[0].getMessage());
        }
        else {
        	invite.Date_Sent__c = System.now();
        	update invite;
        }
        return result.isSuccess();
    }
/*
    private static String templateSubstitute(Partner_User_Invitation__c invite, String value) {
        if (value != null) {
            value = value.replace('{!Partner_User_Invitation__c.Id}', invite.Id);

            value = value.replace('{!$Label.Red_Hat_Domain_Name}', System.Label.Red_Hat_Domain_Name);
//            value = value.replace('{!$Label.Onboarding_URL_address}', System.Label.Onboarding_URL_address);
        }
        return value;
    }
*/
    public static Contact createContact(Partner_User_Invitation__c invite) {
        Contact contact = new Contact();
        contact.Email = invite.Email__c;
        contact.AccountId = invite.Account__c;
        contact.LoginName__c = invite.federationId__c;
        contact.LastName = invite.federationId__c;
        insert contact;
        return contact;
    }

    public void enablePartnerUser(Partner_User_Invitation__c invite) {
 		Contact[] contacts = [	select	Id, Email, AccountId, Phone, LoginName__c, FirstName, LastName,
 										MailingStreet, MailingCity, MailingState, MailingPostalCode
 								from	Contact
 								where	LoginName__c = :invite.federationId__c limit 1];
 		Contact contact = null;
 		if (contacts.size() == 0) {
 			contact = createContact(invite);
 		}
 		else {
 			contact = contacts.get(0);
 		}
        contact.Phone = formPhone;
        contact.FirstName = formFirstName;
        contact.LastName = formLastName;
        contact.MailingStreet = formStreet;
        contact.MailingCity = formCity;
        contact.MailingState = formState;
        contact.MailingPostalCode = formPostalCode;
        contact.LoginName__c = formLogin;
        update contact;

        User user = new OnboardingConversion().getPartnerUser(contact);
        user.ProfileId = invite.ProfileId__c;
        user.EmailEncodingKey = invite.EmailEncodingKey__c;
        user.LanguageLocaleKey = invite.LanguageLocaleKey__c;
        user.LocaleSidKey = invite.LocaleSidKey__c;
        user.TimeZoneSidKey = invite.TimeZoneSidKey__c;
        user.isPartnerAdmin__c = invite.isUserAdmin__c;
        insert user;
    }

    public void handleUserInvitation() {
        invitationId = ApexPages.currentPage().getParameters().get('invitationid');
    }

    /***************************************************
     * These methods are for handling invitation admin
     */

    public void loadInvitations() {
        if (invitations != null) return;

        User u = [select Contact.AccountId from User where Id = :UserInfo.getUserId()];
        Id accountId = u.Contact.AccountId;
        invitations = [select  Id, CreatedBy.Name, FederationId__c, Date_Responded__c, Response_Type__c, Date_Sent__c, Email__c, Declined_Reason__c
                       from    Partner_User_Invitation__c
                       where   Account__c = :accountId];

    }

    public PageReference resendInvitation() {
    	for (Partner_User_Invitation__c invite : invitations) {
    		if (invite.Id == commandInvitationId && invite.Response_Type__c != 'A') {
    			if (sendMail(invite)) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, System.Label.Partner_User_Invitation_sent + invite.Email__c));
    			}
    			else {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.Partner_User_invitation_not_sent));
    			}
                return null;
    		}
    	}
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.Partner_User_Invitation_not_found + ' - ' + commandInvitationId));
    	return null;
    }

    public PageReference deleteInvitation() {
        integer index = 0;
        for (Partner_User_Invitation__c invite : invitations) {
            if (invite.Id == commandInvitationId && invite.Response_Type__c != 'A') {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, System.Label.Partner_User_invitation_removed + invite.Email__c));
                delete invite;
                invitations.remove(index);
                return null;
            }
            index += 1;
        }
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.Partner_User_Invitation_not_found + ' - ' + commandInvitationId));
        return null;
    }

    /***************************************************
     * unit tests
     */
  /*
    public static testmethod void doTestManage() {
        PartnerUserInvitationController ctrl = new PartnerUserInvitationController();
        ctrl.loadInvitations();
    }

    public static testmethod void doTestResponse() {
        PartnerUserInvitationController ctrl = new PartnerUserInvitationController();
        Partner_User_Invitation__c invite = new Partner_User_Invitation__c();
        invite.Date_Responded__c = System.now();
        Account acct = [select Id from Account limit 1];
        invite.Account__c = acct.Id;
        invite.Date_Sent__c = System.now();
        invite.federationId__c = 'federationidtest0001';
        invite.Email__c = 'masmith@redhat.com';
        invite.EmailEncodingKey__c = 'UTF-8';
        invite.LanguageLocaleKey__c = 'en_US';
        invite.TimeZoneSidKey__c = 'America/New_York';
        invite.LocaleSidKey__c = 'en_US';
        invite.ProfileId__c = [
                select  Id
                from    Profile
                where   Name = 'Partner Portal – Strategic License - ISV'
            ].Id;
        System.assert(invite.ProfileId__c != null, 'Missing ProfileId for invitation');
        insert invite;

        ApexPages.currentPage().getParameters().put('invitationid', invite.Id);
        ctrl.joinAcceptance = 'Yes';
        ctrl.formFirstName = 'Malcolm';
        ctrl.formLastName = 'Reynolds';
        ctrl.formStreet = '1801 Varsity Dr';
        ctrl.formCity = 'Raleigh';
        ctrl.formState = 'NC';
        ctrl.formPostalCode = '27606';
        ctrl.formPhone = '919-555-1212';
        ctrl.formLogin = invite.federationId__c;
        ctrl.handleUserInvitation();
        ctrl.continueInvitation();
        //System.assert(ApexPages.getMessages().size() == 0, 'Response returned a page error - ' + ApexPages.getMessages().get(0));
        invite = [select Response_Type__c from Partner_User_Invitation__c where Id = :invite.Id];
        System.assert(invite.Response_Type__c == 'A', 'Response type was not A');
    }

    public static testmethod void doTestEmail() {
        PartnerUserInvitationController ctrl = new PartnerUserInvitationController();
        Partner_User_Invitation__c invite = new Partner_User_Invitation__c();
        invite.Date_Responded__c = System.now();
        invite.Date_Sent__c = System.now();
        invite.Email__c = 'masmith@redhat.com';
        invite.federationId__c = 'slartibartfast';
        insert invite;

        boolean result = PartnerUserInvitationController.sendMail(invite);
        System.assert(result, 'Failed to send email');
    }  */
}