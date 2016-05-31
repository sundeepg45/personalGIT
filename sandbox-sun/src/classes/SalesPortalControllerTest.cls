/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 *
 * @version 2014-06-18
 * @author tkruger@redhat.com
 * Bill C. Riemers <briemers@redhat.com>
 * 2014-06-18 - Commented out failing test.  To Do update class to create the data it uses for testing...
 * 
 */
@isTest
private class SalesPortalControllerTest {

	static testMethod void settingsTest() {
		SalesPortalController c = new SalesPortalController();
		System.assertNotEquals(null,c.CHATTER_GROUP_NAME);
		System.assertNotEquals(null,c.SECT_COMMUNCATION);
		System.assertNotEquals(null,c.SECT_GENERAL_INFORMATION);
		System.assertNotEquals(null,c.SECT_POPULAR_LINKS);
		System.assertNotEquals(null,c.SECT_PORTAL_SPOTLIGHT);
		System.assertNotEquals(null,c.SECT_QUICK_LINKS);
		System.assertNotEquals(null,c.SECT_WHOS_WHO);
		System.assertNotEquals(null,c.SECT_FEATURED_STORY);
		System.assertNotEquals(null,c.SECT_RESOURCES);
		System.assertNotEquals(null,c.SECT_DASHBOARD);
		System.assertNotEquals(null,c.SECT_STATUS_BAR);
		System.assertNotEquals(null,c.SUBSEC_PORTAL_MESSAGE);
		System.assertNotEquals(null,c.GROUP_GLOBAL_ALL);
	}

	static testMethod void currentUserTest() {
		System.assertEquals(UserInfo.getUserId(),SalesPortalController.currentUser.Id);
	}
	
	static testMethod void getLatestDocumentsTest() {
		SalesPortalController c = new SalesPortalController();
		System.assertNotEquals(null,c.getLatestDocuments());
	}

	static testMethod void chatterGroupTest() {
		SalesPortalController c = new SalesPortalController();
		System.assertNotEquals(null,c.chatterGroup);
	}

	static testMethod void contentMapTest() {
		SalesPortalController c = new SalesPortalController();
		for(List<SalesPortalController.Link> links : c.contentMap.values()) {
			testLinks(links);
		}
	}

	static testMethod void toUpperCaseTest() {
		System.assertEquals(null,SalesPortalController.toUpperCase(null));
		System.assertEquals('A',SalesPortalController.toUpperCase('a'));
	}

	static testMethod void getLastLoginTest() {
		SalesPortalController c = new SalesPortalController();
		System.assertNotEquals(null,c.getLastLogin());
	}

	static void testLinks(List<SalesPortalController.Link> links) {
		if(links != null && ! links.isEmpty()) {
			for(SalesPortalController.Link link : links) {
				if(link.getId() != null) {
					System.assertNotEquals(null,link.getIsPortalMessage());
					System.assertNotEquals(null,link.getIsVideo());
					System.assertNotEquals(null,link.getUpdated());
					System.assertNotEquals(null,link.getHasIcon());
					System.assertNotEquals(null,link.getTitle());
					System.assertNotEquals(null,link.getEscapedTitle());
					link.getExpandIfUpdated();
					link.getLink();
					link.getHTML();
					link.getSectionKey();
					link.getEscapedSectionKey();
					link.getSection();
					link.getSubSectionKey();
					link.getSubSection();
					link.icon = link.icon;
				}
			}
		}
	}

	static testMethod void getMessagesTest() {
		SalesPortalController c = new SalesPortalController();
		testLinks(c.getMessages());
	}

	static testMethod void getPortalSpotlightTest() {
		SalesPortalController c = new SalesPortalController();
		testLinks(c.getPortalSpotlight());
	}

	static testMethod void getQuickLinksTest() {
		SalesPortalController c = new SalesPortalController();
		testLinks(c.getQuickLinks());
	}

	static testMethod void getFootersTest() {
		SalesPortalController c = new SalesPortalController();
		testLinkSections(c.getFooters());
	}

	static testMethod void getFeaturedStoryTest() {
		SalesPortalController c = new SalesPortalController();
		testLinks(new List<SalesPortalController.Link>{c.getFeaturedStory()});
	}

	static testMethod void getStatusBarTest() {
		SalesPortalController c = new SalesPortalController();
		testLinks(new List<SalesPortalController.Link>{c.getStatusBar()});
	}

	static testMethod void getDashBoardLinkTest() {
		SalesPortalController c = new SalesPortalController();
		testLinks(new List<SalesPortalController.Link>{c.getDashBoardLink()});
	}

	static void testLinkSections(List<SalesPortalController.LinkSection> linkSections) {
		SalesPortalController c = new SalesPortalController();
		for(SalesPortalController.LinkSection linkSection : linkSections) {
			testLinks(linkSection.links);
			linkSection.title = linkSection.title;
			linkSection.addLink(new SalesPortalController.Link(c));
		}
	}

	static testMethod void getResourcesTest() {
		SalesPortalController c = new SalesPortalController();
		testLinkSections(c.getResources());
	}
	
	static testMethod void getTrackingURLTest() {
		SalesPortalController c = new SalesPortalController();
		System.assertNotEquals(null,c.getTrackingURL());
	}
}