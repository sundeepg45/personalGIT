public with sharing class CommunitiesTestUtils {

    public static User createGenericUser(){

        User testAdmin = PartnerTestUtils.getAdminuser();
        Account a = PartnerTestUtils.makeAccount('testAccount',testAdmin);
        Partner_Program__c ps = PartnerTestUtils.makeProgram(a.id, PartnerConst.RESELLER, PartnerConst.READY);
        insert ps;
        Contact c = PartnerTestUtils.makeContact(a.id,'testLogin'+ DateTime.now().getTime());
        insert c;
        PartnerTrack__c pTrack = new PartnerTrack__c(Partner_Function__c='Sales');
        insert pTrack;
        Contact_Track__c cTrack = new Contact_Track__c(Contact__c=c.id, Primary__c=true,Partner_Track__c=pTrack.id);
        insert cTrack;
        User u = PartnerTestUtils.makeUser(a,c);
        insert u;
        return u;

    }

    public static Audience__c createAllPartnerStatusAudience(){
        Audience__c aud = new Audience__c();
        aud.Partner_Region__c = 'All';
        aud.Partner_Subregion__c = 'All';
        aud.Partner_Tier__c = 'All';
        aud.Partner_Type__c = 'All';
        aud.Role__c = 'All';
        aud.Name = 'TestAud';
        insert aud;
        return aud;
    }

    public static Set<String> testAllowedTabs(){
        Set<String> allowedTabs = new Set<String>();

        List<String> testTabs = new List<String>{'Account','Lead','Opportunity'};
        for(string s : testTabs){
            allowedTabs.add(s);
        }
        return allowedTabs;
    }

    public static List<Communities_Tool_Shortcut__c> createToolShortcuts(){

        List<Communities_Tool_Shortcut__c> shortcuts = new List<Communities_Tool_Shortcut__c>();
        Communities_Tool_Shortcut__c cts1 = new Communities_Tool_Shortcut__c();
        cts1.Availability_Controlled_By__c = 'Account';
        cts1.Shortcut_URL__c = 'https://www.test.com';
        cts1.Tool_Name__c = 'test1';
        shortcuts.add(cts1);

        Communities_Tool_Shortcut__c cts2 = new Communities_Tool_Shortcut__c();
        cts2.Availability_Controlled_By__c = 'Lead';
        cts2.Shortcut_URL__c = 'https://www.test.com';
        cts2.Tool_Name__c = 'test2';
        shortcuts.add(cts2);
        insert shortcuts;

        List<Communities_Tool_Shortcut_Label__c> labels = new List<Communities_Tool_Shortcut_Label__c>();
        Communities_Tool_Shortcut_Label__c ctsl1 = new Communities_Tool_Shortcut_Label__c();
        ctsl1.Communities_Tool_Shortcut__c = cts1.id;
        ctsl1.Language__c = 'English';
        ctsl1.Link_Text__c = 'link text 1';
        ctsl1.Tooltip_Text__c = 'tooltip text 2';
        labels.add(ctsl1);

        Communities_Tool_Shortcut_Label__c ctsl2 = new Communities_Tool_Shortcut_Label__c();
        ctsl2.Communities_Tool_Shortcut__c = cts2.id;
        ctsl2.Language__c = 'English';
        ctsl2.Link_Text__c = 'link text 2';
        ctsl2.Tooltip_Text__c = 'tooltip text 2';
        labels.add(ctsl2);
        insert labels;
        return shortcuts;
    }



}