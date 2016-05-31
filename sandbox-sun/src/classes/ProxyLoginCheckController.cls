/**
 * This class is a controller and a controller extension that can be used to
 * check if administators have proxy login enabled, and if so send them a 
 * warning e-mail message.
 *
 * @author Bill C Riemers <briemers@redhat.com>
 * @version 2012-10-31
 * 2012-10-31 - created
 */
 public with sharing class ProxyLoginCheckController {
	/** Name of a custom setting key for last processed date and time. */
	public static final String LAST_PROCESSED_KEY = 'ProxyLoginCheck.LastProcessed';
	/** Name of a custom setting key for the report id to use. */
	public static final String REPORT_ID_KEY = 'ProxyLoginCheck.ReportId';
	/** The body of the email message which will be sent. */
	public static final String MESSAGE_BODY = 'As an administrator you should not allow proxy logins to your account\nPlease login to salesforce and navigate to Setup->My Personal Information->Grant Access.\nOnce there change Your System Administrator\'s access to "No Access".\n';
	/** The subject of the email message which will be sent. */
	public static final String MESSAGE_SUBJECT = 'Your account is currently accessible via a proxy login.';

	/** A transient copy of the pageContent Blob. */
	public transient Blob pageContent = null;

	/** 
	 * A simple constructor to allow this class to be used as a controller.
	 */
	public ProxyLoginCheckController() {}

	/** 
	 * A generic constructor to allow this class to be used as an controller
	 * extension.
	 * @param controller any instance
	 */
	public ProxyLoginCheckController(Object controller) {}

	/**
	 * Get the page content for the specified URL.
	 * @param pageUrl the url to retrieve
	 * @return the Blob from the getContent() call.
	 */
	public Blob getPageContent(String pageUrl) {
		try {
			pageContent = new PageReference(pageUrl).getContent();
		}
		catch(Exception e) {}
		return pageContent;
	}

	/**
	 * Get the HTML content of interest from the specified Blob.
	 * @param xpageContent the blob to parse
	 * @return the html text with the report table
	 */
	public static String getHtmlText(Blob xpageContent) {
		String htmlText = '';
		if(xpageContent != null) {
			String [] s = xpageContent.toString().split('<!-- Start report output -->',2);
			if(s.size() > 1) {
				htmlText = s[1].split('</table>',2)[0];
			}
		}
		return htmlText;
	}

	/**
	 * Find all the user Id values referenced as href attributes
	 * in the specified html.
	 * @param htmlText the html to parse
	 * @return the set of user ids
	 */
	public static Set<Id> getUserIds(String htmlText) {
		Set<Id> ids = new Set<Id>();
		Integer i = htmlText.indexof('href="/005');
		if(i > 0) {
			for(String s : htmlText.substring(i).split('href="/005')) {
				try {
					ids.add('005'+s.split('"',2)[0]);
				}
				catch(Exception e) {}
			}
		}
		return ids;
	}

	/**
	 * Find the email address for all the specified user ids.
	 * @param userIds to query
	 * @return set of email addresses
	 */
	public static Set<String> getEmailAddresses(final Set<Id> userIds) {
		Set<String> emailAddresses = new Set<String>();
		for(User u : [select Email from User where Id in :userIds]) {
			System.debug('Email address='+u.Email);
			emailAddresses.add(u.Email);
		}
		return emailAddresses;
	}

	/**
	 * Called to send error message by e-mail.
	 * @param emailAddresses to send the message to
	 * @return the message sent.
	 */
	public static Messaging.SingleEmailMessage sendMessage(Set<String> emailAddresses) {
		Messaging.SingleEmailMessage mail = null;
		// Send an email to notify us of the jobs status
		if(! emailAddresses.isEmpty()) {
			String username = UserInfo.getUserName().replaceAll('.*@redhat[.]com[.]*','');
			for(User u : [select UserName from User where UserName like 'intadmin@redhat.com%' limit 1]) {
				username = u.UserName;
			}
			List<String> s = username.toUpperCase().split('@REDHAT\\.COM\\.*');
			s.add('PROD');
			mail = new Messaging.SingleEmailMessage();
			List<String> toAddresses = new List<String>();
			toAddresses.addAll( emailAddresses );
			mail.setToAddresses( toAddresses );
			mail.setSubject( s[1]+': '+ MESSAGE_SUBJECT );
			mail.setPlainTextBody( MESSAGE_BODY );
			mail.setSenderDisplayName('Salesforce Administrator');
			Messaging.sendEmail( new Messaging.SingleEmailMessage[] { mail } );
		}
		return mail;
	}

	/**
	 * Called to check the proxy logins and send e-mails.
	 */
	public PageReference checkProxyLogins() {
		StringSetting__c reportIdSetting = StringSetting__c.getInstance(REPORT_ID_KEY);
		if(reportIdSetting != null && reportIdSetting.Value__c != null && AdminByPass__c.getInstance().IsOppAdmin__c) {
			DateTimeSetting__c lastProcessed = DateTimeSetting__c.getInstance(LAST_PROCESSED_KEY);
			if(lastProcessed == null) {
				lastProcessed = new DateTimeSetting__c(Name=LAST_PROCESSED_KEY);
			}
			DateTime lastProcessedDateTime = lastProcessed.Value__c;
			DateTime now = DateTime.now();
			if(lastProcessedDateTime == null || lastProcessedDateTime.addDays(1).getTime() <= now.getTime()) {
				sendMessage(getEmailAddresses(getUserIds(getHtmlText(getPageContent('/'+reportIdSetting.Value__c)))));
				lastProcessed.Value__c = now;
				upsert lastProcessed;
			}
		}
		return null;
	}
}