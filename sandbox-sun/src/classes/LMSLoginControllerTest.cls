@isTest
public class LMSLoginControllerTest{

    @isTest (seeAllData = true)
	public static void testLoginControllerAsPartner()
    {
    	Account account = PartnerTestUtils.quickGenericAccountSetup('Most Amazing 13th Partner of the World');
        Contact c = PartnerTestUtils.makeContact(account.Id, 'loginusertestnumber13@redhat.com');
        insert c;
        User u = PartnerTestUtils.makeUser(account, c);
        insert u;

        // Run as Partner
        System.RunAs(u) {
            LMSLoginController lmslc = new LMSLoginController();
            lmslc.testingSkipCallout = true;
            lmslc.getAuthToken();
            lmslc.getHasTrack();
            lmslc.provisionUser();
            lmslc.createLMSDownCase();
        }
    }

    @isTest (seeAllData = true)
	public static void testLoginControllerAsAdmin()
    {
        // Run as Admin
        LMSLoginController lmslc = new LMSLoginController();
        lmslc.testingSkipCallout = true;
        lmslc.getAuthToken();
        lmslc.getHasTrack();
        lmslc.provisionUser();
        lmslc.createLMSDownCase();
    }
}