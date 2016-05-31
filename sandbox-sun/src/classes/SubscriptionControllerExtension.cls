/**
 * This implements a controller extension for both individual Subscription__c records
 * and selected lists of Subscription__c records.
 *
 * @version 2015-02-05
 * @author Bill C Riemers <briemers@redhat.com>
 * 2015-02-05 - Only create the renewal opportunity immediately when running as the same user running the DailyScheduler
 * 2015-01-15 - Update error processing
 * 2013-10-16 - Created
 */
public with sharing class SubscriptionControllerExtension {
	public static final String HOLD_FOR_DECISION_STATUS = 'HOLD for Decision';
	public static final String READY_STATUS = 'READY';
	public static final String READY_FOR_SSI_STATUS = 'READY for SSI';
	public static final String DO_NOT_LOAD_STATUS = 'DO NOT LOAD';
	public static final String ERROR_STATUS = 'ERROR';
	public static final String SUCCESS_STATUS = 'SUCCESS';
	public static final String WAIT_FOR_CHANNEL_LOAD_STATUS = 'WAIT for Channel Load';
	/** The subscription Id. */
	final Id recordId;
	/** Subscription */
	public final Subscription__c subscription;
	public final List<Subscription__c> subscriptionList;

	/**
	 * ControllerExtension constructor for individual records.
	 */
	public SubscriptionControllerExtension(ApexPages.StandardController stdController) {
		recordId = stdController.getId();
		subscriptionList = [ 
			select
				Status__c,
				SuperRegion__c
			from Subscription__c 
			where Id = :recordId ];
		subscription = subscriptionList[0];
		subscriptionReportCriteria = new SubscriptionReportCriteria__c(
			StartDate__c = Date.today(),
			EndDate__c = Date.today(),
			SuperRegion__c = null);
	}

	/**
	 * ControllerExtension constructor for sets of records.
	 */
	public SubscriptionControllerExtension(ApexPages.StandardSetController stdSetController) {
		subscriptionList = [ 
			select
				Status__c,
				SuperRegion__c
			from Subscription__c 
			where Id = :stdSetController.getSelected() ];
		recordId = null;
		subscription = null;
		subscriptionReportCriteria = new SubscriptionReportCriteria__c(
			StartDate__c = Date.today(),
			EndDate__c = Date.today(),
			SuperRegion__c = null);
	}

	public SubscriptionReportCriteria__c subscriptionReportCriteria {
		get;
		set;
	}

	/**
	 * Called to check if an individual record is in an appropriate status
	 * to be converted to a renewal opportunity.
	 * 
	 * @return true if in an HOLD or ERROR status
	 */
	public Boolean getCanCreateRenewalOpportunity() {
		return ( subscription.Status__c == HOLD_FOR_DECISION_STATUS || subscription.Status__c == ERROR_STATUS );
	}

//	public PageReference createRenewalOpportunity() {
//		if( getCanCreateRenewalOpportunity() ) {
//			Opportunity_Subscription.createRenewalOpportunity(recordId);
//		}
//		return new PageReference('/'+recordId);
//	}

	/**
	 * Called to find out if edit is allowed.
	 *
	 * @return false if in a WAIT status and required fields have been set.
	 */
	public Boolean getCanEdit() {
		return ( subscription.Status__c != WAIT_FOR_CHANNEL_LOAD_STATUS || subscription.SuperRegion__c == null);
	}

//	/** 
//	 * Invoke a future call to create the opportunity, and possibly assign to the SSI user.
//	 */
//	@future
//	static void processFuture(Id subscriptionId) {
//		Opportunity_Subscription.createRenewalOpportunity(subscriptionId);
//		// to do: If ready SSI assign to the SSI user
//	}

	/**
	 * Called to change the subscription status(es).
	 *
	 * @param status
	 * @param retval the page to redirect to on success.
	 * @return page one should redirect to.
	 */
	public PageReference changeStatus(String status,PageReference retval) {
		if(status != null && '' != status) {
			try {
				List<Subscription__c> updateList = new List<Subscription__c>();
				Boolean directConvert = ( recordId != null 
					&& (status == READY_STATUS 
						|| (status == READY_FOR_SSI_STATUS 
							&& (subscription.SuperRegion__c == 'NA'
								|| subscription.SuperRegion__c == 'LATAM'))));
				if(directConvert) {
					for(CronTrigger ct : [
						select c.OwnerId
						from CronTrigger c
						where c.CronJobDetail.Name like 'Daily Scheduler %'
							and c.CronJobDetail.JobType = '7'
						order by NextFireTime DESC
						limit 1 ] )
					{
						directConvert = (ct.OwnerId == UserInfo.getUserId());
					}
				}
				for(Subscription__c sub : subscriptionList) {
					if(sub.Status__c == HOLD_FOR_DECISION_STATUS || sub.Status__c == ERROR_STATUS || status == DO_NOT_LOAD_STATUS) {
//						sub.Status__c = HOLD_FOR_DECISION_STATUS;
//						if(! directConvert) {
							sub.Status__c = status;
//						}
						sub.ErrorMessage__c = null;
						sub.SSI_InScope__c = (status == READY_FOR_SSI_STATUS);
						updateList.add(sub);
					}
				}
				if(! updateList.isEmpty()) {
					for(Database.Saveresult sr : Database.update(updateList,false)) {
						Subscription__c s = updateList.remove(0);
						if(! sr.isSuccess()) {
							ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,s.Id+': '+sr.getErrors()));
							directConvert = false;
							retval = null;
						}
					}
					if( directConvert ) {
						for(List<Database.Error> errors : Opportunity_Subscription.createRenewalOpportunities(new Set<Id>{recordId},false).values())
						{
							for(Database.Error e : errors) {
								ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage()));
								retval = null;
							}
						}
					}
				}
			}
			catch (Exception ex) {
				ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, ex.getMessage()));
				retval = null;
			}
		}
		return retval;
	}

	/**
	 * Called to change the subscription statuses to READY.
	 * 
	 * @return page reference to view a single object or the tab.
	 */
	public PageReference changeStatusReadyForProcessing() {
		return changeStatus(READY_STATUS, new PageReference('javascript:window.location=document.referrer'));
	}

	/**
	 * Called to change the subscription statuses to READY for SSI.
	 * 
	 * @return page reference to view a single object or the tab.
	 */
	public PageReference changeStatusReadyForSSI() {
		return changeStatus(READY_FOR_SSI_STATUS, new PageReference('javascript:window.location=document.referrer'));
	}

	/**
	 * Called to change the subscription statuses to DO NOT LOAD.
	 * 
	 * @return page reference to view a single object or the tab.
	 */
	public PageReference changeStatusDoNotLoad() {
		return changeStatus(DO_NOT_LOAD_STATUS, new PageReference('javascript:window.location=document.referrer'));
	}

	/**
	 * Action called when loading the edit page.
	 *
	 * @retur the page to redirect to
	 */
	public PageReference edit() {
		PageReference retval = new PageReference('/'+recordId);
		String status = ApexPages.currentPage().getParameters().get('Status__c');
		if(status != null && '' != status) {
			retval = changeStatus( status, retval );
//			if(retval != null && 1 == [select count() from Subscription__c where Id = :recordId and (Status__c = :SUCCESS_STATUS or Status__c = :status) limit 1]) {
//				retval = new PageReference('/'+((String)recordId).substring(0,3)+'/o');
//			}
		}
		else if( getCanEdit() ) {
			retval = new PageReference('/'+recordId+'/e');
			retval.getParameters().put('retURL','/'+recordId);
			retval.getParameters().putAll(ApexPages.currentPage().getParameters());
			retval.getParameters().put('nooverride','1');
		}
		return retval; 
	}

	public PageReference downloadSSI() {
		PageReference retval = null;
		try {
			Document d = [select Id from Document where DeveloperName = 'subscriptions' limit 1];
			List<Subscription__c> subs = [
				select Id
				from Subscription__c
				where SuperRegion__c = :subscriptionReportCriteria.SuperRegion__c
					and CreatedDate >= :DateTime.newInstance(subscriptionReportCriteria.StartDate__c,Time.newInstance(0,0,0,0))
					and CreatedDate < :DateTime.newInstance(subscriptionReportCriteria.EndDate__c.addDays(1),Time.newInstance(0,0,0,0))
					and Status__c = :READY_FOR_SSI_STATUS ];
			for(Subscription__c sub : subs) {
				sub.SSI_InScope__c = true;
				sub.Status__c = SUCCESS_STATUS;
			}
			update subs;
			retval = new PageReference('/'+d.Id);
//			retval = new PageReference('/servlet/servlet.FileDownload');
//			retval.getParameters().put('file',(''+d.Id).substring(0,15));
		}
		catch(Exception ex) {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, ex.getMessage()));
		}
		return retval;
	}
}