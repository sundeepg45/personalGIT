@isTest
public class ManageTrackControllerTest{

	@isTest (seeAllData = true)
	public static void testManageTrackAsPartner()
    {
    	Account account = PartnerTestUtils.quickGenericAccountSetup('Most Amazing 13th Partner of the World');
        Contact c = PartnerTestUtils.makeContact(account.Id, 'loginusertestnumber13@redhat.com');
        insert c;
        User u = PartnerTestUtils.makeUser(account, c);
        insert u;

        // Run as Partner
        System.RunAs(u) {
            ManageTrackController mtc = new ManageTrackController();
            mtc.getIsSideNavRedirect();
            mtc.getContactTracks();
            User partnerUser = mtc.me;
            //mtc.selectedTrack = Id.valueOf(mtc.getAvailableTracks()[0].getValue());
            mtc.selectedTrack = mtc.getAvailableTracks()[1].getValue();
            mtc.save();
            mtc.getContactTracks();
            mtc.getAvailableTracks();
        }
    }
}