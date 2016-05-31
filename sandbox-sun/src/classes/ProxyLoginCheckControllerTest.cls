/**
 * This the test class for ProxyLoginCheckControllerTest.
 *
 * @author Bill C Riemers <briemers@redhat.com>
 * @version 2012-10-31
 * 2012-10-31 - created
 */
@isTest
private class ProxyLoginCheckControllerTest {
	static Blob PAGE_CONTENT {
		get {
			return Blob.valueOf(
	'<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">\n'+
	'<html class="">\n'+
	'<title>IT Login Access ~ salesforce.com - Unlimited Edition</title>\n'+
	'<!-- Start report output -->\n'+
	'<div id="fchArea"><table class="reportTable tabularReportTable" border="0" cellspacing="0" cellpadding="0"><tr id=\'headerRow_0\' bgcolor=\'#aaaaff\' class=\'headerRow\'><TH align="left" scope="col"><a href="javascript:document.report.sort.value%3D%27PROFILE%27%3Bdocument.report.sortdir.value%3D%27up%27%3Bdocument.report.submit%28%29%3B" title="Profile - Click to sort ascending"><strong>Profile</strong></a></TH><TH align="left" scope="col"><a href="javascript:document.report.sort.value%3D%27FULL_NAME%27%3Bdocument.report.sortdir.value%3D%27up%27%3Bdocument.report.submit%28%29%3B" title="Full Name - Click to sort ascending"><strong>Full Name</strong></a></TH><TH align="left" scope="col"><a href="javascript:document.report.sort.value%3D%27USERNAME%27%3Bdocument.report.sortdir.value%3D%27up%27%3Bdocument.report.submit%28%29%3B" title="Username - Click to sort ascending"><strong>Username</strong></a></TH><TH class="sortCol" align="left" scope="col"><a href="javascript:document.report.sort.value%3D%27EMAIL%27%3Bdocument.report.sortdir.value%3D%27down%27%3Bdocument.report.submit%28%29%3B" title="Email - Sorted ascending"><strong>Email</strong></a><img src="/s.gif" alt="Sorted Ascending"  class="sortAsc" title="Sorted Ascending"/></TH><TH align="right" scope="col"><a href="javascript:document.report.sort.value%3D%27SU_ORG_ADMIN_EXPIRATION%27%3Bdocument.report.sortdir.value%3D%27up%27%3Bdocument.report.submit%28%29%3B" title="Admin Access Exp. Date - Click to sort ascending"><strong>Admin Access Exp. Date</strong></a></TH><TH align="left" scope="col"><a href="javascript:document.report.sort.value%3D%27LAST_LOGIN%27%3Bdocument.report.sortdir.value%3D%27up%27%3Bdocument.report.submit%28%29%3B" title="Last Login - Click to sort ascending"><strong>Last Login</strong></a></TH></tr>\n'+
	'<tr class="odd" valign="top"><td ><a href="/00e60000000rN23">Administrator - Level 2</a></td><td ><a href="/00560000000m5Ex">Brittany Olds</a></td><td >bschiada@redhat.com.fte2</td><td ><a href="mailto:bolds@redhat.com.fte2">bolds@redhat.com.fte2</a></td><td align="right">22/10/2022</td><td >15/10/2012 11:13 AM</td></tr>\n'+
	'<tr class="even" valign="top"><td ><a href="/00e60000000rN23">Administrator - Level 2</a></td><td ><a href="/00560000000mStZ">Bill Riemers</a></td><td >briemers@redhat.com.fte2</td><td ><a href="mailto:briemers@redhat.com">briemers@redhat.com</a></td><td align="right">22/10/2022</td><td >01/11/2012 4:50 PM</td></tr>\n'+
	'<tr class="odd" valign="top"><td ><a href="/00e60000000rN22">Administrator - Level 1</a></td><td ><a href="/00560000000nbpA">Cecilee Billett</a></td><td >cbillett@redhat.com.fte2</td><td ><a href="mailto:cbillett@redhat.com.fte2">cbillett@redhat.com.fte2</a></td><td align="right">22/10/2022</td><td >-</td></tr>\n'+
	'<tr class="even" valign="top"><td ><a href="/00e60000000rN23">Administrator - Level 2</a></td><td ><a href="/00560000000nNes">Chris Anderson</a></td><td >chanders@redhat.com.fte2</td><td ><a href="mailto:chanders@redhat.com.fte2">chanders@redhat.com.fte2</a></td><td align="right">22/10/2022</td><td >17/10/2012 12:28 PM</td></tr>\n'+
	'<tr class="odd" valign="top"><td ><a href="/00e60000000rN22">Administrator - Level 1</a></td><td ><a href="/00560000000mncC">Chris Mendler</a></td><td >cmendler@redhat.com.fte2</td><td ><a href="mailto:crmadmin@redhat.com">crmadmin@redhat.com</a></td><td align="right">22/10/2022</td><td >30/10/2012 2:46 PM</td></tr>\n'+
	'<tr class="even" valign="top"><td ><a href="/00e60000000rN23">Administrator - Level 2</a></td><td ><a href="/00560000001UUpZ">Holly Cullen</a></td><td >holly.cullen@accenture.com.fte2</td><td ><a href="mailto:holly.cullen@accenture.com.fte2">holly.cullen@accenture.com.fte2</a></td><td align="right">22/10/2022</td><td >01/11/2012 1:45 PM</td></tr>\n'+
	'<tr class="odd" valign="top"><td ><a href="/00e60000000rN23">Administrator - Level 2</a></td><td ><a href="/00560000001RF6g">Security Administration Group</a></td><td >sec-admin@redhat.com.fte2</td><td ><a href="mailto:infosec@redhat.com.fte2">infosec@redhat.com.fte2</a></td><td align="right">22/10/2022</td><td >21/10/2012 12:04 AM</td></tr>\n'+
	'<tr class="even" valign="top"><td ><a href="/00e60000000rN22">Administrator - Level 1</a></td><td ><a href="/00560000001RsIX">Jerry Back</a></td><td >jback@redhat.com.fte2</td><td ><a href="mailto:jback@redhat.com.fte2">jback@redhat.com.fte2</a></td><td align="right">22/10/2022</td><td >26/10/2012 1:21 PM</td></tr>\n'+
	'<tr class="odd" valign="top"><td ><a href="/00e60000000rN22">Administrator - Level 1</a></td><td ><a href="/00530000000f8Sv">Integration Admin</a></td><td >intadmin@redhat.com.fte2</td><td ><a href="mailto:jherson@redhat.com">jherson@redhat.com</a></td><td align="right">22/10/2022</td><td >01/11/2012 4:00 PM</td></tr>\n'+
	'<tr class="even" valign="top"><td ><a href="/00e60000000rN23">Administrator - Level 2</a></td><td ><a href="/00560000000m2Ea">John Herson</a></td><td >jherson@redhat.com.fte2</td><td ><a href="mailto:jherson@redhat.com.fte2">jherson@redhat.com.fte2</a></td><td align="right">22/10/2022</td><td >18/10/2012 3:04 PM</td></tr>\n'+
	'<tr class="odd" valign="top"><td ><a href="/00e60000000rN23">Administrator - Level 2</a></td><td ><a href="/00560000000nitu">Tiaan Kruger</a></td><td >jkruger@redhat.com.fte2</td><td ><a href="mailto:jkruger@redhat.com.fte2">jkruger@redhat.com.fte2</a></td><td align="right">22/10/2022</td><td >16/10/2012 9:40 AM</td></tr>\n'+
	'<tr class="even" valign="top"><td ><a href="/00e60000000rN22">Administrator - Level 1</a></td><td ><a href="/00560000001TBej">Jarrod Shumaker</a></td><td >jshumake@redhat.com.fte2</td><td ><a href="mailto:jshumake@redhat.com.fte2">jshumake@redhat.com.fte2</a></td><td align="right">22/10/2022</td><td >01/11/2012 4:28 PM</td></tr>\n'+
	'<tr class="odd" valign="top"><td ><a href="/00e60000000rN23">Administrator - Level 2</a></td><td ><a href="/00560000000mtso">Kalidass Gujar</a></td><td >kgujar@redhat.com.fte2</td><td ><a href="mailto:kalidass.gujar@accenture.com.fte2">kalidass.gujar@accenture.com.fte2</a></td><td align="right">22/10/2022</td><td >08/10/2012 9:11 AM</td></tr>\n'+
	'<tr class="even" valign="top"><td ><a href="/00e60000000rN22">Administrator - Level 1</a></td><td ><a href="/00560000001Tf1I">Kendra Blount</a></td><td >kblount@redhat.com.fte2</td><td ><a href="mailto:kblount@redhat.com.fte2">kblount@redhat.com.fte2</a></td><td align="right">22/10/2022</td><td >19/10/2012 7:59 AM</td></tr>\n'+
	'<tr class="odd" valign="top"><td ><a href="/00e60000000rN23">Administrator - Level 2</a></td><td ><a href="/00560000001SZ8k">Kiersten Grey</a></td><td >kgrey@redhat.com.fte2</td><td ><a href="mailto:kgrey@redhat.com.fte2">kgrey@redhat.com.fte2</a></td><td align="right">22/10/2022</td><td >19/10/2012 2:46 PM</td></tr>\n'+
	'<tr class="even" valign="top"><td ><a href="/00e60000000rN23">Administrator - Level 2</a></td><td ><a href="/00560000000nOPP">SFQA</a></td><td >sfqa@redhat.com.fte2</td><td ><a href="mailto:kkunchak+sfqa@redhat.com.fte2">kkunchak+sfqa@redhat.com.fte2</a></td><td align="right">22/10/2022</td><td >16/10/2012 1:12 PM</td></tr>\n'+
	'<tr class="odd" valign="top"><td ><a href="/00e60000000rN22">Administrator - Level 1</a></td><td ><a href="/00560000000nj2O">Mark Smith</a></td><td >masmith@redhat.com.prod.fte2</td><td ><a href="mailto:masmith@redhat.com.fte2">masmith@redhat.com.fte2</a></td><td align="right">22/10/2022</td><td >09/10/2012 10:36 AM</td></tr>\n'+
	'<tr class="even" valign="top"><td ><a href="/00e60000000rN23">Administrator - Level 2</a></td><td ><a href="/00560000001UkjS">Meghan Baran</a></td><td >mbaran@redhat.com.fte2</td><td ><a href="mailto:mbaran@redhat.com.fte2">mbaran@redhat.com.fte2</a></td><td align="right">22/10/2022</td><td >18/10/2012 11:38 AM</td></tr>\n'+
	'<tr class="odd" valign="top"><td ><a href="/00e60000000rN23">Administrator - Level 2</a></td><td ><a href="/00560000000nMak">Meghan Schaude</a></td><td >mschaude@redhat.com.fte2</td><td ><a href="mailto:meghan.l.schaude@accenture.com.fte2">meghan.l.schaude@accenture.com.fte2</a></td><td align="right">22/10/2022</td><td >01/11/2012 10:15 AM</td></tr>\n'+
	'<tr class="even" valign="top"><td ><a href="/00e60000000rN23">Administrator - Level 2</a></td><td ><a href="/00560000000nZxv">Maria Andreina Mendoza</a></td><td >mmendoza@redhat.com.fte2</td><td ><a href="mailto:mmendoza@redhat.com.fte2">mmendoza@redhat.com.fte2</a></td><td align="right">22/10/2022</td><td >19/10/2012 12:34 PM</td></tr>\n'+
	'<tr class="odd" valign="top"><td ><a href="/00e60000000rN23">Administrator - Level 2</a></td><td ><a href="/005g0000000Hw8p">Anusha Muppalla</a></td><td >muppalla.anusha@accenture.com.fte2</td><td ><a href="mailto:muppalla.anusha@accenture.com">muppalla.anusha@accenture.com</a></td><td align="right">30/10/2013</td><td >01/11/2012 12:20 AM</td></tr>\n'+
	'<tr class="even" valign="top"><td ><a href="/00e60000000rN23">Administrator - Level 2</a></td><td ><a href="/00560000000moOp">Nancy Brown</a></td><td >nbrown@redhat.com.fte2</td><td ><a href="mailto:nbrown@redhat.com.fte2">nbrown@redhat.com.fte2</a></td><td align="right">22/10/2022</td><td >19/10/2012 7:22 AM</td></tr>\n'+
	'<tr class="odd" valign="top"><td ><a href="/00e60000000rN23">Administrator - Level 2</a></td><td ><a href="/00560000000nf8g">Nitesh Dokania</a></td><td >ndokania@redhat.com.fte2</td><td ><a href="mailto:nitesh.dokania@accenture.com">nitesh.dokania@accenture.com</a></td><td align="right">22/10/2022</td><td >01/11/2012 1:25 AM</td></tr>\n'+
	'<tr class="even" valign="top"><td ><a href="/00e60000000rN22">Administrator - Level 1</a></td><td ><a href="/00560000001Ryvf">Red Hat System</a></td><td >rhsystem@redhat.com.fte2</td><td ><a href="mailto:noreply@redhat.com.fte2">noreply@redhat.com.fte2</a></td><td align="right">22/10/2022</td><td >31/07/2012 4:32 PM</td></tr>\n'+
	'<tr class="odd" valign="top"><td ><a href="/00e60000000rN23">Administrator - Level 2</a></td><td ><a href="/00560000001V6qa">Rohit Sethi</a></td><td >rohitse+rh@niit.com.fte2</td><td ><a href="mailto:rohitse@niit.com.fte2">rohitse@niit.com.fte2</a></td><td align="right">22/10/2022</td><td >30/05/2012 9:42 AM</td></tr>\n'+
	'<tr class="even" valign="top"><td ><a href="/00e60000000rN23">Administrator - Level 2</a></td><td ><a href="/00560000001m1c6">Santosh Bapat</a></td><td >sbapat@redhat.com.fte2</td><td ><a href="mailto:sbapat@redhat.com.fte2">sbapat@redhat.com.fte2</a></td><td align="right">22/10/2022</td><td >01/11/2012 11:06 AM</td></tr>\n'+
	'<tr class="odd" valign="top"><td ><a href="/00e60000000rN22">Administrator - Level 1</a></td><td ><a href="/00560000001UbOB">Scott Coleman</a></td><td >scoleman@redhat.com.fte2</td><td ><a href="mailto:scoleman@redhat.com">scoleman@redhat.com</a></td><td align="right">22/10/2022</td><td >01/11/2012 4:46 PM</td></tr>\n'+
	'<tr class="even" valign="top"><td ><a href="/00e60000000rN23">Administrator - Level 2</a></td><td ><a href="/00560000000muwN">Sherry James</a></td><td >sjames@redhat.com.fte2</td><td ><a href="mailto:sjames@redhat.com.fte2">sjames@redhat.com.fte2</a></td><td align="right">22/10/2022</td><td >31/10/2012 11:19 AM</td></tr>\n'+
	'<tr class="odd" valign="top"><td ><a href="/00e60000000rN23">Administrator - Level 2</a></td><td ><a href="/00560000000ms2I">Sunil Keshari</a></td><td >skeshari@redhat.com.fte2</td><td ><a href="mailto:skeshari@redhat.com.fte2">skeshari@redhat.com.fte2</a></td><td align="right">22/10/2022</td><td >25/08/2012 2:06 PM</td></tr>\n'+
	'<tr class="even" valign="top"><td ><a href="/00e60000000rN23">Administrator - Level 2</a></td><td ><a href="/00560000001CiCT">Surbhi Tiwari</a></td><td >surbhi.tiwari@accenture.com.rh.fte2</td><td ><a href="mailto:surbhi.tiwari@accenture.com">surbhi.tiwari@accenture.com</a></td><td align="right">22/10/2022</td><td >31/10/2012 5:29 AM</td></tr>\n'+
	'<tr class="odd" valign="top"><td ><a href="/00e60000000rN23">Administrator - Level 2</a></td><td ><a href="/00560000000nYyJ">Wendy Bloom</a></td><td >wbloom@redhat.com.fte2</td><td ><a href="mailto:wbloom@redhat.com.fte2">wbloom@redhat.com.fte2</a></td><td align="right">22/10/2022</td><td >05/09/2012 8:36 AM</td></tr>\n'+
	'<tr bgcolor=\'#aaaacc\' class=\'grandTotal grandTotalTop\'><td colspan="6"><strong>Grand Totals (31 records)</strong></td></tr>\n'+
	'<tr bgcolor=\'#aaaacc\' class=\'grandTotal\' valign="top"><td class="nowrapCell" align="right">&nbsp;</td>\n'+
	'<td class="nowrapCell" align="right">&nbsp;</td>\n'+
	'<td class="nowrapCell" align="right">&nbsp;</td>\n'+
	'<td class="nowrapCell" align="right">&nbsp;</td>\n'+
	'<td class="nowrapCell" align="right">&nbsp;</td>\n'+
	'<td class="nowrapCell" align="right">&nbsp;</td>\n'+
	'</tr>\n'+
	'</table>\n'+
	'<!-- page generation time: 223ms -->');
		}
	}

	@isTest
	static void getPageContentTest() {
		ProxyLoginCheckController c = new ProxyLoginCheckController();
		c.getPageContent('http://www.google.com');
	}

	@isTest 
	static void getUserIdsTest() {
		String htmlText = ProxyLoginCheckController.getHtmlText(PAGE_CONTENT);
		System.assert(htmlText.startsWith('\n<div id="fchArea">'),'Unexpected text: '+htmlText);
		System.assert(htmlText.endsWith('\n'),'Unexpected text: '+htmlText);
		Set<Id> userIds = ProxyLoginCheckController.getUserIds(htmlText);
		for(Id userId : new Set<Id>{
			'00530000000f8Sv','00560000000m2Ea','00560000000m5Ex','00560000000mncC',
			'00560000000moOp','00560000000ms2I','00560000000mStZ','00560000000mtso',
			'00560000000muwN','00560000000nbpA','00560000000nf8g','00560000000nitu',
			'00560000000nj2O','00560000000nMak','00560000000nNes','00560000000nOPP',
			'00560000000nYyJ','00560000000nZxv','00560000001CiCT','00560000001m1c6',
			'00560000001RF6g','00560000001RsIX','00560000001Ryvf','00560000001SZ8k',
			'00560000001TBej','00560000001Tf1I','00560000001UbOB','00560000001UkjS',
			'00560000001UUpZ','00560000001V6qa','005g0000000Hw8p' })
		{
			System.assert(userIds.contains(userId),'Expected '+userId);
			userIds.remove(userId);
		}
		System.assert(userIds.isEmpty(),'Unexpected Ids found: '+userIds);
	}

	@isTest
	static void getEmailAddressesTest() {
		Map<Id,User> userMap = new Map<Id,User>([select Email from User where IsActive = true and ProfileId = :UserInfo.getProfileId() limit 5]);
		Set<String> emailAddresses = ProxyLoginCheckController.getEmailAddresses(userMap.keySet());
		for(User u : userMap.values()) {
			System.assert(emailAddresses.contains(u.Email),'Expected '+u.Email);
			emailAddresses.remove(u.Email);
		}
		System.assert(emailAddresses.isEmpty(),'Unexpected Addresses: '+emailAddresses);
	}

	@isTest
	static void sendMessages() {
		System.assertNotEquals(null,ProxyLoginCheckController.sendMessage(new Set<String>{'noone@nowhere.com'}));
	}

	@isTest
	static void coverageTest() {
		AdminByPass__c adminByPass = AdminByPass__c.getInstance();
		adminByPass.IsOppAdmin__c = true;
		upsert adminByPass;
		StringSetting__c reportIdSetting = new StringSetting__c(Name=ProxyLoginCheckController.REPORT_ID_KEY,Value__c=UserInfo.getUserId());
		upsert reportIdSetting;
		ProxyLoginCheckController c = new ProxyLoginCheckController(null);
		c.pageContent = PAGE_CONTENT;
		c.checkProxyLogins();
	}
}