global without sharing class PartnerEmailUtils {


    static public String generateEmailToken(ID entityId, String email) {
        String token = entityId + '/' + email;
        Blob hash = Crypto.generateDigest('SHA1', Blob.valueOf(token));
        String hexDigest = EncodingUtil.convertToHex(hash);
        return hexDigest;
    }

    static public String getEmailConfirmationBaseURL(String page) {
        String s = System.Label.Partner_Site_URL + '/apex/' + page;
        return s;
    }

    static public String getEmailConfirmationFullURL(String token) {
        return getEmailConfirmationBaseURL('PartnerEmailConfirmation') + '?token=' + token;
    }

    static public String getEmbeddedTermsFullURL(String token) {
        PageReference pageReference = new PageReference(System.label.Red_Hat_Domain_Name + '/wapps/sso/login.html');
        String redir = '/wapps/sfconnector/protected/partner.html?action=' + PartnerGateway.ACTION_EMBED_TERMS + token;
        pageReference.getParameters().put('redirect', redir);
        return pageReference.getUrl();
    }

    static public String getCCSPTermsFullURL(String token) {
        PageReference pageReference = new PageReference(System.label.Red_Hat_Domain_Name + '/wapps/sso/login.html');
        String redir = '/wapps/sfconnector/protected/partner.html?action=' + PartnerGateway.ACTION_CCNSP_TERMS + token;
        pageReference.getParameters().put('redirect', redir);
        return pageReference.getUrl();
    }

    static public String getCCSPChecklistFullURL(String token) {
        PageReference pageReference = new PageReference(System.label.Red_Hat_Domain_Name + '/wapps/sso/login.html');
        String redir = '/wapps/sfconnector/protected/partner.html?action=' + PartnerGateway.ACTION_CCNSP_CHECKLIST + token;
        pageReference.getParameters().put('redirect', redir);
        return pageReference.getUrl();
//        String base = System.Url.getSalesforceBaseUrl().toExternalForm();
//        String url = base + '/partner/PartnerAccess?action=' + PartnerGateway.ACTION_CCNSP_CHECKLIST + '&token=' + token;
//        return url;
    }

    static public String getPARFFullURL(String token) {
        PageReference pageReference = new PageReference(System.label.Red_Hat_Domain_Name + '/wapps/sso/login.html');
        String redir = '/wapps/sfconnector/protected/partner.html?action=' + PartnerGateway.ACTION_PARF + token;
        pageReference.getParameters().put('redirect', redir);
        return pageReference.getUrl();
    }

    static public String getFCPAFullURL(String token) {
        PageReference pageReference = new PageReference(System.label.Red_Hat_Domain_Name + '/wapps/sso/login.html');
        String redir = '/wapps/sfconnector/protected/partner.html?action=' + PartnerGateway.ACTION_FCPA + token;
        pageReference.getParameters().put('redirect', redir);
        return pageReference.getUrl();
    }

    static public void resendEmail(ID rowid) {
        PartnerUser_Email_Token__c token = [
            select  Id, Email__c, Template_Name__c, Email_Confirmation_URL__c
            from    PartnerUser_Email_Token__c
            where   Id = :rowid
        ];
        OrgWideEmailAddress owe = [select id, Address from OrgWideEmailAddress where Address = 'no-reply-partners@redhat.com' limit 1];
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

        LogSwarm log = new LogSwarm('Onboarding', 'Resend Email');
        log.push('rowId', rowid);
        if (token.Template_Name__c == null) {
            log.error('Trying to resend unsupported email');
            return;
        }
        EmailTemplate[] tmpllist = [select Id, Subject, Body from EmailTemplate where DeveloperName = :token.Template_Name__c];
        if (tmpllist.size() == 0) {
            log.error('Unable to find email template');
            return;
        }
        EmailTemplate tmpl = tmpllist.get(0);

        String[] tmp = new List<String>();
        tmp.add(token.Email__c);
        mail.setSubject(tmpl.Subject);
        String body = tmpl.Body;
        String url = token.Email_Confirmation_URL__c;
        body = body.replace('{termsurl}', url);
        body = body.replace('{checklisturl}', url);
        body = body.replace('{fcpaurl}', url);
        mail.setHtmlBody(body);
        mail.setToAddresses(tmp);
        mail.setReplyTo('noreply@redhat.com');
        mail.setOrgWideEmailAddressId(owe.id);
        mail.saveAsActivity = FALSE;
        if (!Test.isRunningTest()) {
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }
    }

    static public void sendTierChangeFCPAEmail(ID targetId, String email, String language) {
        OrgWideEmailAddress owe = [select id, Address from OrgWideEmailAddress where Address = 'no-reply-partners@redhat.com' limit 1];
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

        LogSwarm log = new LogSwarm('Tier Change', 'Email');
        log.push('targetId', targetId);
        log.push('email', email);
        log.push('language', language);

        if (language == null) language = 'en';
        String templateName = 'FCPA_Questions_';
        String templName = templateName + language.toUpperCase();
        log.push('templateName', templName);
        EmailTemplate[] tmpllist = [select Id, Subject, Body from EmailTemplate where DeveloperName = :templName];
        if (tmpllist.size() == 0) {
            templName = templateName + '_EN';
            tmpllist = [select Id, Subject, Body from EmailTemplate where DeveloperName = :templName];
            if (tmpllist.size() == 0) {
                log.error('Unable to find email template');
                return;
            }
        }
        EmailTemplate tmpl = tmpllist.get(0);

        String[] tmp = new List<String>();
        tmp.add(email);
        mail.setSubject(tmpl.Subject);
        String body = tmpl.Body;
        String url = generateTierChangeFCPATokenURL(targetId, email, templName);
        if (body.contains('{fcpaurl}') == false) {
            log.error('Special tag {fcpasurl} missing from email template');
        }

        body = body.replace('{fcpaurl}', url);
        mail.setHtmlBody(body);
        mail.setToAddresses(tmp);
        mail.setReplyTo('noreply@redhat.com');
        mail.setOrgWideEmailAddressId(owe.id);
        mail.saveAsActivity = FALSE;
        if (!Test.isRunningTest()) {
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }
    }

    static public void sendEmbedTermsEmail(ID targetId, String email, String language) {
        OrgWideEmailAddress owe = [select id, Address from OrgWideEmailAddress where Address = 'no-reply-partners@redhat.com' limit 1];
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

        LogSwarm log = new LogSwarm('Onboarding', 'Email');
        log.push('targetId', targetId);
        log.push('email', email);
        log.push('language', language);

        if (language == null) language = 'en';
        String templateName = 'Embed_Terms_Invitation_';
        String templName = templateName + language.toUpperCase();
        log.push('templateName', templName);
        EmailTemplate[] tmpllist = [select Id, Subject, Body from EmailTemplate where DeveloperName = :templName];
        if (tmpllist.size() == 0) {
            templName = templateName + '_EN';
            tmpllist = [select Id, Subject, Body from EmailTemplate where DeveloperName = :templName];
            if (tmpllist.size() == 0) {
                log.error('Unable to find email template');
                return;
            }
        }
        EmailTemplate tmpl = tmpllist.get(0);

        String[] tmp = new List<String>();
        tmp.add(email);
        mail.setSubject(tmpl.Subject);
        String body = tmpl.Body;
        String url = generateEmbedTermsTokenURL(targetId, email, templName);
        if (body.contains('{termsurl}') == false) {
            log.error('Special tag {termsurl} missing from email template');
        }

        body = body.replace('{termsurl}', url);
        mail.setHtmlBody(body);
        mail.setToAddresses(tmp);
        mail.setReplyTo('noreply@redhat.com');
        mail.setOrgWideEmailAddressId(owe.id);
        mail.saveAsActivity = FALSE;
        if (!Test.isRunningTest()) {
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }
    }

    static public void sendCCSPTermsEmail(ID targetId, String email, String language) {
        OrgWideEmailAddress owe = [select id, Address from OrgWideEmailAddress where Address = 'no-reply-partners@redhat.com' limit 1];
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

        LogSwarm log = new LogSwarm('Onboarding', 'Email');
        log.push('targetId', targetId);
        log.push('email', email);
        log.push('language', language);

        if (language == null) language = 'en';
        String templateName = 'CCSP_Terms_Invitation_';
        String templName = templateName + language.toUpperCase();
        log.push('templateName', templName);
        EmailTemplate[] tmpllist = [select Id, Subject, Body from EmailTemplate where DeveloperName = :templName];
        if (tmpllist.size() == 0) {
            templName = templateName + '_EN';
            tmpllist = [select Id, Subject, Body from EmailTemplate where DeveloperName = :templName];
            if (tmpllist.size() == 0) {
                log.error('Unable to find email template');
                return;
            }
        }
        EmailTemplate tmpl = tmpllist.get(0);

        String[] tmp = new List<String>();
        tmp.add(email);
        mail.setSubject(tmpl.Subject);
        String body = tmpl.Body;
        String url = generateCCSPTermsTokenURL(targetId, email, templName);
        if (body.contains('{termsurl}') == false) {
            log.error('Special tag {termsurl} missing from email template');
        }

        body = body.replace('{termsurl}', url);
        mail.setHtmlBody(body);
        mail.setToAddresses(tmp);
        mail.setReplyTo('noreply@redhat.com');
        mail.setOrgWideEmailAddressId(owe.id);
        mail.saveAsActivity = FALSE;
        if (!Test.isRunningTest()) {
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }
    }

    static public void sendCCSPChecklistEmail(ID targetId, String email, String templateType, String language) {
        OrgWideEmailAddress owe = [select id, Address from OrgWideEmailAddress where Address = 'no-reply-partners@redhat.com' limit 1];
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        LogSwarm log = new LogSwarm('Onboarding', 'Email');
        log.push('targetId', targetId);
        log.push('email', email);
        log.push('templateType', templateType);
        log.push('language', language);

        if (language == null) language = 'en';
        String templateName = '';
        if (templateType == 'Distributor') {
            templateName = 'CCSP_Checklist_Invitation_Disti_';
        }
        else if (templateType == 'Internal') {
            templateName = 'CCSP_Checklist_Invitation_Internal_';
        }
        else if (templateType == 'User') {
            templateName = 'CCSP_Checklist_Invitation_';
        }
        else {
            log.error('Unable to send email - unknown template ' + templateType);
            return;
        }
        String templName = templateName + language.toUpperCase();
        log.push('templateName', templName);
        EmailTemplate[] tmpllist = [select Id, Subject, Body from EmailTemplate where DeveloperName = :templName];
        if (tmpllist.size() == 0) {
            templName = templateName + '_EN';
            tmpllist = [select Id, Subject, Body from EmailTemplate where DeveloperName = :templName];
            if (tmpllist.size() == 0) {
                log.error('Unable to find email template');
                return;
            }
        }
        EmailTemplate tmpl = tmpllist.get(0);

        String[] tmp = new List<String>();
        tmp.add(email);
        String body = tmpl.Body;
        if (body.contains('{checklisturl}') == false) {
            log.error('Special embedded tag {checklisturl} missing from email template');
        }
        String url = generateChecklistTokenURL(targetId, email, templName);
        body = body.replace('{checklisturl}', url);
        mail.setSubject(tmpl.Subject);
        mail.setHtmlBody(body);
        mail.setToAddresses(tmp);
        mail.setReplyTo('noreply@redhat.com');
        mail.setOrgWideEmailAddressId(owe.id);
        mail.saveAsActivity = FALSE;
        if (!Test.isRunningTest()) {
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }
    }

    static public void sendPARFEmail(ID targetId, String email, String templateType, String language) {
        OrgWideEmailAddress owe = [select id, Address from OrgWideEmailAddress where Address = 'no-reply-partners@redhat.com' limit 1];
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        LogSwarm log = new LogSwarm('Onboarding', 'Email');
        log.push('targetId', targetId);
        log.push('email', email);
        log.push('templateType', templateType);
        log.push('language', language);

        if (language == null) language = 'en';
        String templateName = '';
        if (templateType == 'Distributor') {
            templateName = 'Embedded_Invitation_Disti_';
        }
        else if (templateType == 'Internal') {
            templateName = 'Embedded_Invitation_Internal_';
        }
        else if (templateType == 'User') {
            templateName = 'Embedded_Invitation_';
        }
        else {
            log.error('Unable to send email - unknown template ' + templateType);
            return;
        }
        String templName = templateName + language.toUpperCase();
        log.push('templateName', templName);
        EmailTemplate[] tmpllist = [select Id, Subject, Body from EmailTemplate where DeveloperName = :templName];
        if (tmpllist.size() == 0) {
            templName = templateName + '_EN';
            tmpllist = [select Id, Subject, Body from EmailTemplate where DeveloperName = :templName];
            if (tmpllist.size() == 0) {
                log.error('Unable to find email template');
                return;
            }
        }
        EmailTemplate tmpl = tmpllist.get(0);

        String[] tmp = new List<String>();
        tmp.add(email);
        String body = tmpl.Body;
        if (body.contains('{checklisturl}') == false) {
            log.error('Special embedded tag {checklisturl} missing from email template');
        }
        String url = generatePARFTokenURL(targetId, email, templName);
        body = body.replace('{checklisturl}', url);
        mail.setSubject(tmpl.Subject);
        mail.setHtmlBody(body);
        mail.setToAddresses(tmp);
        mail.setReplyTo('noreply@redhat.com');
        mail.setOrgWideEmailAddressId(owe.id);
        mail.saveAsActivity = FALSE;
        if (!Test.isRunningTest()) {
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }
    }

    static public void sendEmbeddedDistiEmail(String email, String accName) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        OrgWideEmailAddress owe = [select id, Address from OrgWideEmailAddress where Address = 'no-reply-partners@redhat.com' limit 1];
        String templateName = 'Terms_Acceptance_Email_for_DISTI';
        LogSwarm log = new LogSwarm('EmbedOnboarding', 'DistiEmail');
        log.push('Receipient', email);
        log.push('EmailTemplate', templateName);

        EmailTemplate[] templates = [select Id, Subject, Body, HtmlValue from EmailTemplate where DeveloperName = :templateName];
        if (templates.size() == 0) {
            log.error('Unable to find email template' + templateName);
            return;
        }
        EmailTemplate tmpl = templates.get(0);
        //tmpl.Body = tmpl.Body.replace('{!Partner_Program__c.Program_Name__c}', pgm);
        // tmpl.Body = tmpl.Body.replace('{!Partner_Program__c.Account__c}', accName);
        tmpl.HtmlValue = tmpl.HtmlValue.replace('{!Partner_Program__c.Account__c}', accName);
        String[] tmp = new List<String>();
        tmp.add(email);

        mail.setSubject(tmpl.Subject);
        // mail.setHtmlBody(tmpl.Body);
        mail.setHtmlBody(tmpl.HtmlValue);
        mail.setToAddresses(tmp);
        mail.setReplyTo('noreply@redhat.com');
        mail.setOrgWideEmailAddressId(owe.Id);
        mail.saveAsActivity = FALSE;
        //mail.setTargetObjectId(targetObjId);
        //mail.whatId = pgmId;
        if(!Test.isRunningTest()) {
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }
    }

/*
    static public void sendLeadEmail(ID targetId, String email) {
        OrgWideEmailAddress owe = [select id, Address from OrgWideEmailAddress where Address = 'no-reply-partners@redhat.com' limit 1];
        EmailTemplate tpl = [select Id from EmailTemplate where DeveloperName = 'OEM_SI_Onboard_Email_Confirmation'];
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setTargetObjectId(targetId);
        mail.setTemplateId(tpl.Id);
    //  mail.setplaintextbody('Test');//sfdc
        mail.setReplyTo('noreply@redhat.com');
        mail.setOrgWideEmailAddressId(owe.id);
        mail.saveAsActivity = FALSE;
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        generateTokenURL(targetId, email);
    }
*/

    static public void sendLeadEmail(ID targetId, String email) {
        OrgWideEmailAddress owe = [select id, Address from OrgWideEmailAddress where Address = 'no-reply-partners@redhat.com' limit 1];
//		String template = System.Label.OEM_SI_Onboarding_Email_Body;
        String template = System.Label.Join_Onboarding_Email_Body;
	    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

	    String[] tmp = new List<String>();
	    tmp.add(email);
//	    mail.setSubject(System.Label.OEM_SI_Onboarding_Email_Subject);
        mail.setSubject(System.Label.ONB_Join_Onboarding_Subject);
	    String body = template;
        String url = generateTokenURL(targetId, email);
	    body = body.replace('{0}', url);
	    mail.setHtmlBody(body);
	    mail.setToAddresses(tmp);
	    mail.setReplyTo('noreply@redhat.com');
	    mail.setOrgWideEmailAddressId(owe.id);
	    mail.saveAsActivity = FALSE;
        if (!Test.isRunningTest()) {
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }
    }

    static public String generateChecklistTokenURL(ID targetId, String email, String templName) {
        PartnerUser_Email_Token__c token = new PartnerUser_Email_Token__c();
        token.Email__c = email;
        token.Notification_Type__c = 'CCSP Checklist';
        token.Token__c = PartnerEmailUtils.generateEmailToken(targetId, email);
        token.Template_Name__c = templName;
        deactivateDups(token.Token__c);
        insert token;
        token.Partner_Onboarding__c = targetId;
        token.Email_Confirmation_URL__c = getCCSPChecklistFullURL(token.Token__c);
        update token;
        return getCCSPChecklistFullURL(token.Token__c);
    }

    static public String generatePARFTokenURL(ID targetId, String email, String templName) {
        PartnerUser_Email_Token__c token = new PartnerUser_Email_Token__c();
        token.Email__c = email;
        token.Notification_Type__c = 'PARF';
        token.Token__c = PartnerEmailUtils.generateEmailToken(targetId, email);
        token.Template_Name__c = templName;
        deactivateDups(token.Token__c);
        insert token;
        token.Partner_Onboarding__c = targetId;
        token.Email_Confirmation_URL__c = getPARFFullURL(token.Token__c);
        update token;
        return getPARFFullURL(token.Token__c);
    }

    static public String generateEmbedTermsTokenURL(ID targetId, String email, String templName) {
        PartnerUser_Email_Token__c token = new PartnerUser_Email_Token__c();
        token.Email__c = email;
        token.Notification_Type__c = 'Embedded Terms';
        token.Template_Name__c = templName;
        token.Token__c = PartnerEmailUtils.generateEmailToken(targetId, email);
        deactivateDups(token.Token__c);
        insert token;
        if (targetId.getSObjectType() == Partner_Onboarding_Registration__c.sObjectType) {
            token.Partner_Onboarding__c = targetId;
        }
        else if (targetId.getSObjectType() == Account.sObjectType) {
            token.Account__c = targetId;
        }
        token.Email_Confirmation_URL__c = getEmbeddedTermsFullURL(token.Token__c);
        update token;
        return token.Email_Confirmation_URL__c;
    }

    static public String generateCCSPTermsTokenURL(ID targetId, String email, String templName) {
        PartnerUser_Email_Token__c token = new PartnerUser_Email_Token__c();
        token.Email__c = email;
        token.Notification_Type__c = 'CCSP Terms';
        token.Template_Name__c = templName;
        token.Token__c = PartnerEmailUtils.generateEmailToken(targetId, email);
        deactivateDups(token.Token__c);
        insert token;
        if (targetId.getSObjectType() == Partner_Onboarding_Registration__c.sObjectType) {
            token.Partner_Onboarding__c = targetId;
        }
        else if (targetId.getSObjectType() == Account.sObjectType) {
            token.Account__c = targetId;
        }
        token.Email_Confirmation_URL__c = getCCSPTermsFullURL(token.Token__c);
        update token;
        return token.Email_Confirmation_URL__c;
    }

    static public String generateTierChangeFCPATokenURL(ID targetId, String email, String templName) {
        PartnerUser_Email_Token__c token = new PartnerUser_Email_Token__c();
        token.Email__c = email;
        token.Notification_Type__c = 'Tier FCPA';
        token.Template_Name__c = templName;
        token.Token__c = PartnerEmailUtils.generateEmailToken(targetId, email);
        deactivateDups(token.Token__c);
        insert token;
        token.Program_Approval_Request__c = targetId;
        System.debug('**** [debug] **** targetId=' + targetId);
        token.Email_Confirmation_URL__c = getFCPAFullURL(token.Token__c);
        update token;
        return token.Email_Confirmation_URL__c;
    }

    static public String generateTokenURL(ID targetId, String email){
        PartnerUser_Email_Token__c token = new PartnerUser_Email_Token__c();
        token.Email__c = email;
        token.Notification_Type__c = 'Join';
        token.Token__c = PartnerEmailUtils.generateEmailToken(targetId, email);
        insert token;
        token.Partner_Onboarding__c = targetId;
        token.Email_Confirmation_URL__c = getEmailConfirmationFullURL(token.Token__c);
        update token;

        return getEmailConfirmationFullURL(token.Token__c);
    }

    static private void deactivateDups(String token) {
        PartnerUser_Email_Token__c[] recs = [select Id from PartnerUser_Email_Token__c where Token__c = :token];
        delete recs;
    }

    @future
    static public void deactivateUsers(Set<String> userIdList) {
        User[] users = [select Id, IsActive from User where Id in :userIdList];
        for (User u : users) {
            u.IsActive = false;
        }
        update users;
    }

    @future
    static public void activateUser(ID userid) {
        update new User(ID = userid, IsActive = true);
    }
}