/**
 * AccountHierarchyControllerExtension.cls
 *
 * @author  Bill Riemers <briemers@redhat.com>
 * @version 2012-05-02
 * 2011-10-07 - Created to add support for field sets
 * Scott Coleman <scoleman@redhat.com>
 * 2012-05-02 - Added TrackPageView() to log page views in TrackingEventLog
 */
public with sharing class AccountHierarchyControllerExtension {
	public AccountHierarchyControllerExtension(ApexPages.StandardController controller) {
		currentAccount = (Account)controller.getRecord();
	}
	public Account currentAccount {get; set;}
	
	public void TrackPageView() {
		
		// get relevant tracking event
		TrackingEvent__c event = [
			select 
				Name 
			from TrackingEvent__c 
			where Code__c = 'AcctHierView' ];
		
		if (event != null) {
			// log page view
			TrackingEventLog__c logEntry = new TrackingEventLog__c(
				TrackingEvent__c = event.Id,
				User__c = System.Userinfo.getUserId(),
				UserRoleId__c = System.Userinfo.getUserRoleId() );
			
			insert logEntry;
		}	
	}
}