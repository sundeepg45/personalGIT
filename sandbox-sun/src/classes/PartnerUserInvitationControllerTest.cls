@isTest(seeAllData = true)
public class PartnerUserInvitationControllerTest{

    public static testmethod void doTestManage() {
        PartnerUserInvitationController ctrl = new PartnerUserInvitationController();
        ctrl.loadInvitations();
    }

    public static testmethod void doTestResponse() {
        PartnerUserInvitationController ctrl = new PartnerUserInvitationController();
        Partner_User_Invitation__c invite = new Partner_User_Invitation__c();
        invite.Date_Responded__c = System.now();

        Account acct = PartnerTestUtils.quickGenericAccountSetup('Partner User Inviation Controller Test');
//        Account acct = [SELECT Id FROM Account where RecordType.Name = 'NA Partner' limit 1];
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
    }
}