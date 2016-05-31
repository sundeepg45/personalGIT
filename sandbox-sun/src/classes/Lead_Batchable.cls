/**
 * This class is used to trigger lead routing based on the LeadCronRoutingRule2__c table.
 * The whole table is mapped into a single query string, so it is important to keep the table small.
 * This class schedules the a check for updating statuses on leads.
 * This class clears values left set from aborted custom lead conversions.
 *
 * @version 2015-12-18
 * @author	Bill C Riemers <briemers@redhat.com>
 * 2015-12-18 - created - Merged from Lead_UpdateStatus and Lead_RoutingAssignment, DE9524 defect fix
 */
global class Lead_Batchable extends AbstractBatchable implements Database.Stateful {
	global static final String GLR_ERROR_QUEUE_SETTING = 'LeadRouteAssign.ErrorQueueId';
	/** Name of a custom setting key. */
	global static final String LAST_PROCESSED_KEY = 'Lead_Batchable.LastProcessed';
	/** Must run in minutes. */
	global static final Integer MUST_RUN_IN_MINUTES = 60;
	/** Only change for test methods. */
	global static Boolean routeToGLRErrorQueue = false;
	/** Minimum age in minutes to update desired close date. */
	global static Integer DESIRED_CLOSE_DATE_TIMEOUT = 90;
	/** Maxium age in days to update desired close date. */
	global static Integer DESIRED_CLOSE_DATE_MAX_AGE = 2;
	/** Maxium age in hours to do frequent routing checks. */
	global static Integer ROUTING_CHECK_MAX_AGE = 12;
	/** Maxium age in hours to do frequent status checks. */
	global static Integer STATUS_CHECK_MAX_AGE = 48;

	/** Map of error messages by lead Id */
	global List<String> errorList = new List<String>();

	/**
	 * Default constructor.
	 */
	global Lead_Batchable() {
		super('Lead_Batchable');
	}

	/** 
	 * Keep track of the lastProcessedDateTime
	 */
	global DateTimeSetting__c lastProcessed {
		get {
			if(lastProcessed == null) {
				lastProcessed = new DateTimeSetting__c(Name=LAST_PROCESSED_KEY,Value__c=DateTime.newInstance(0L).addMinutes(DESIRED_CLOSE_DATE_TIMEOUT));
				DateTimeSetting__c xlastProcessed = DateTimeSetting__c.getInstance(LAST_PROCESSED_KEY);
				if(xlastProcessed != null && xlastProcessed.Value__c != null) {
					lastProcessed = xlastProcessed;
				}
			}
			return lastProcessed;
		}
		set;
	}

	/**
	 * Check if there is work for this job to do.
	 *
	 * @return false if there is no work to do.
	 */
	global override Boolean hasWork() {
		DateTime now = DateTime.now();
		return ! ( now < lastProcessed.Value__c.addMinutes(MUST_RUN_IN_MINUTES)
			&& getStatusLeads(1,now.addHours(-STATUS_CHECK_MAX_AGE)).isEmpty()
			&& getRoutingLeads(1,now.addHours(-ROUTING_CHECK_MAX_AGE)).isEmpty()
			&& getDesiredLeads(1).isEmpty() );
	}

	@TestVisible
	static List<Lead> getRoutingLeads(final Integer rowLimit,DateTime oldestDateTime) {
		List<Lead> retval = new List<Lead>();
		if(rowLimit > 0 && ! leadCronRoutingRules.isEmpty()) {
			final Set<Id> ownerIds = new Set<Id>();
			String query = 'select Id, Desired_Opportunity_CloseDate__c, LastModifiedDate, Lead_Ranking__c, OwnerId, PenaltyBoxExpiration__c from Lead';
			query += ' where OwnerId in :ownerIds and IsConverted = false and PenaltyBoxExpiration__c = null';
			if(oldestDateTime != null) {
				query += ' and LastModifiedDate >= :oldestDateTime';
			}
			String sep = '';
			String condition = '';
			for(LeadCronRoutingRule2__c lcrr : leadCronRoutingRules) {
				ownerIds.add(lcrr.OwnerId__c);
				condition += sep+'(OwnerId=\''+lcrr.OwnerId__c+'\' and ';
				String nextCondition = 'Super_Region__c = null and ';
				if(lcrr.Super_Region__c != null) {
					nextCondition='Super_Region__c in (\''+lcrr.Super_Region__c.replaceAll('\\s','').replaceAll(';','\',\'')+'\') and ';
				}
				condition += nextCondition;
				nextCondition = 'Lead_Ranking__c = null)';
				if(lcrr.Lead_Ranking__c != null) {
					nextCondition = 'Lead_Ranking__c in (\''+lcrr.Lead_Ranking__c.replaceAll('\\s','').replaceAll(';','\',\'')+'\'))';
				}
				condition += nextCondition;
				sep = ' or ';
			}
			if(leadCronRoutingRules.size() > 1) {
				condition = '('+condition+')';
			}
			query += ' and '+condition;
			if(rowLimit > 1 || oldestDateTime == null) {
				query += ' order by LastModifiedDate';
			}
			System.debug('query=['+query+']');
			retval = Database.query(query+' limit '+rowLimit);
		}
		return retval;
	}

	@TestVisible
	static List<Lead> getDesiredLeads(final Integer rowLimit) {
		List<Lead> retval = new List<Lead>();
		if(rowLimit > 0) {
			final DateTime newestLastModified = DateTime.now().addMinutes(-DESIRED_CLOSE_DATE_TIMEOUT);
			retval = [
				select Id,
					Desired_Opportunity_CloseDate__c,
					Lead_Ranking__c,
					LastModifiedDate,
					OwnerId,
					PenaltyBoxExpiration__c
				from Lead 
				where Desired_Opportunity_CloseDate__c != null
					and LastModifiedDate < :newestLastModified
					and LastModifiedDate >= :newestLastModified.addDays(-DESIRED_CLOSE_DATE_MAX_AGE)
					and IsConverted = false
				limit :rowLimit ];
		}
		return retval;
	}

	@TestVisible
	static List<Lead> getStatusLeads(Integer rowLimit,DateTime oldestDateTime) {
		Map<Id,Lead> retval = new Map<Id,Lead>();
		if(rowLimit > 0) {
			final DateTime now = DateTime.now();
			String query0 = 'select Id, '
				+ 	'Desired_Opportunity_CloseDate__c, '
				+ 	'Lead_Ranking__c, '
				+ 	'LastModifiedDate, '
				+ 	'OwnerId, '
				+ 	'PenaltyBoxExpiration__c '
				+ 'from Lead '
				+ 'where IsConverted = false ';
			if(oldestDateTime != null) {
				query0 += 	'and LastModifiedDate >= :oldestDateTime ';
			}
			// split this into two queries, as salesforce frequently times out if these
			// two are combined with an or condition
			for(String fieldName : new Set<String>{
				'Next_Status_Update__c',
				'PenaltyBoxExpiration__c'})
			{
				if(rowLimit > 0) {
					List<Lead> leads = Database.query( query0
						+ 	'and '+fieldName+' <= :now '
						+ 'limit :rowLimit' );
					retval.putAll(leads);
					rowLimit -= leads.size();
				}
			}
		}
		return new List<Lead>(retval.values());
	}

	global static List<LeadCronRoutingRule2__c> leadCronRoutingRules {
		get {
			if(leadCronRoutingRules == null) {
				leadCronRoutingRules = LeadCronRoutingRule2__c.getAll().values();
			}
			return leadCronRoutingRules;
		}
		set;
	}

	/**
	 * Tests if a need needs to be routed.
	 */
	static Boolean needsRouting(Lead xlead) {
		Boolean retval = false;
		if(xlead.PenaltyBoxExpiration__c == null) {
			for(LeadCronRoutingRule2__c lcrr : leadCronRoutingRules ) {
				try {
					retval = retval 
						|| ( (lcrr.OwnerId__c == xlead.OwnerId)
							&& (';'+lcrr.Lead_Ranking__c+';').replaceAll('\\s','').containsIgnoreCase(';'+xlead.Lead_Ranking__c+';')
							&& (';'+lcrr.Super_Region__c+';').replaceAll('\\s','').containsIgnoreCase(';'+xlead.Super_Region__c+';') );
				}
				catch(Exception ex) {}
			}
		}
		return retval;
	}

	/**
	 * Start method impl for Database.Batchable interface.  Our
	 * current method of writing the query limits us to around 300 to 600
	 * records maximum in the LeadCronRoutingRule__c table.  This is fine 
	 * since there are currently only 3 entries needed.   However, should 
	 * we even need to exceed the upper limit this code would need to be 
	 * rewritten.  A less efficent query that hard coded every REGION/RANKING
	 * pair with a set of owner Id's would allow a virtually unlimited table
	 * size.  However, it is unlikely that will ever be needed.
	 *
	 * @param 	bc batchable contents
	 * @return 	query locator for valid Leads
	 *
	 */
	global List<Lead> start(Database.BatchableContext bc)
//	global Database.QueryLocator start(Database.BatchableContext bc)
	{
		DateTime now = DateTime.now();
		lastProcessed.Value__c = now;
		errorList.clear();
		DateTime newestLastModified = now.addMinutes(-DESIRED_CLOSE_DATE_TIMEOUT);
		Map<Id,Lead> leadMap = new Map<Id,Lead>(getDesiredLeads(Limits.getLimitQueryRows() - Limits.getQueryRows()));
		leadMap.putAll(getStatusLeads(Limits.getLimitQueryRows() - Limits.getQueryRows(),null));
		leadMap.putAll(getRoutingLeads(Limits.getLimitQueryRows() - Limits.getQueryRows(),null));
		Database.upsert(lastProcessed,false);
		return leadMap.values();
	}

	/**
	 * execute method impl for Database.Batchable interface
	 *
	 * @param 	bc batchable content
	 * @param 	leads all mathing records
	 *
	 */
	global void execute(Database.BatchableContext bc, List<Lead> leads) {
		Date today = Date.today();
		DateTime now = DateTime.now();
		DateTime newestLastModified = now.addMinutes(-DESIRED_CLOSE_DATE_TIMEOUT);
		Database.DMLOptions dmo = new Database.DMLOptions();
		dmo.assignmentRuleHeader.useDefaultRule= true;
		for(Lead xlead : leads) {
			// this method will result in updating the status
			xlead.Next_Status_Update__c = null;
			// clear the penalty box expiration date as needed
			if (xlead.PenaltyBoxExpiration__c != null && xlead.PenaltyBoxExpiration__c <= now) {
				xlead.PenaltyBoxExpiration__c = null;
			}
			// avoid race conditions with current lead conversions in progress when clearing this value
			if(xlead.Desired_Opportunity_CloseDate__c != null && (xlead.LastModifiedDate <= newestLastModified || xlead.Desired_Opportunity_CloseDate__c < today)) {
				xlead.Desired_Opportunity_CloseDate__c = null;
			}
			// only do lead routing when needed...
			if( needsRouting(xlead) ) {
				xlead.setOptions(dmo);
			}
		}
		StringSetting__c glrErrorQueue = StringSetting__c.getInstance(GLR_ERROR_QUEUE_SETTING);
		Id glrErrorQueueId = null;
		if(glrErrorQueue != null) {
			glrErrorQueueId = (Id)glrErrorQueue.Value__c;
		}
		List<Lead> failedLeads = new List<Lead>();
		for(Database.SaveResult sr : Database.update(leads,false)) {
			Lead xlead = leads.remove(0);
			Boolean inactiveOwner = routeToGLRErrorQUeue;
			if(! sr.isSuccess()) {
				for(Database.Error e : sr.getErrors()) {
					inactiveOwner = inactiveOwner || (''+e.getStatusCode() == 'INACTIVE_OWNER_OR_USER');
				}
				errorList.add(xlead.Id+': '+sr.getErrors()+'\ninactiveOwner='+inactiveOwner+',glrErrorQueueId='+glrErrorQueueId);
			}
			if(inactiveOwner && glrErrorQueueId != null) {
				failedLeads.add(new Lead(Id=xlead.Id,OwnerId=glrErrorQueueId,Assignment_Error__c='Routed to an Inactive User'));
			}
		}
		Boolean triggerValue = AbstractTrigger.booleanSettingMap.get(LeadTriggerBefore.LEAD_ROUTING_SETTING);
		try {
			AbstractTrigger.booleanSettingMap.put(LeadTriggerBefore.LEAD_ROUTING_SETTING,false);
			dmo.assignmentRuleHeader.useDefaultRule = false;
			System.debug('failedLeads='+failedLeads);
			for(Database.SaveResult sr : Database.update(failedLeads,dmo)) {
				Lead xlead = failedLeads.remove(0);
				if(! sr.isSuccess()) {
					errorList.add(xlead.Id+': '+sr.getErrors());
				}
			}
		}
		finally {
			AbstractTrigger.booleanSettingMap.put(LeadTriggerBefore.LEAD_ROUTING_SETTING,triggerValue);
		}
	}
}