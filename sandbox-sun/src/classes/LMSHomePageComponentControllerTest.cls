@isTest
public class LMSHomePageComponentControllerTest{

    @isTest (seeAllData = true)
	public static void testHomePageComponentAsPartner()
    {
    	Account account = PartnerTestUtils.quickGenericAccountSetup('Most Amazing 13th Partner of the World');
        Contact c = PartnerTestUtils.makeContact(account.Id, 'loginusertestnumber13@redhat.com');
        insert c;
        User u = PartnerTestUtils.makeUser(account, c);
        
        // Run as Partner
        System.RunAs(u) {
            LMSHomePageComponentController lmshpc = new LMSHomePageComponentController();
            lmshpc.getHasTrack();
            lmshpc.getAddingTrack();
        }
    }
}