/**
 * This class replaces all before insert and before update lead triggers.  The
 * processTrigger method is invoked by the Lead_Before trigger and in turn invokes
 * all the methods of this class.  This gives us a way to control the order in
 * which the code logic is invoked, as well as allowing other class features such
 * as shared data, constant values, and regorious test coverage.
 * <p>
 * The Trigger object should never be directly referenced inside this class, as
 * that would make it impossible to substituting values inside test methods.
 * </p>
 * 
 * @version 2014-02-18
 *
 * @author Bill C Riemers <briemers@redhat.com>
 * 2014-02-18 - Added method assignLeadForReportingId
 * 2013-08-01 - US36497 - Added Marketing qualified as a lead conversion stage
 * 2012-10-11 - US26041 - Restored partner exclusion for setting status removed in US21120
 * 2012-09-06 - US24547 - let a lead be in working status there is a receint activity history
 * 2012-08-01 - DE3646 - all instead of one past due
 * 2012-07-19 - update to api version 24 and extending the abstract trigger class
 * 2012-03-05 - Split into a subclass
 * 2011-12-08 - Modified insertLead method to by-pass non-GLM leads
 * 2011-09-01 - Created
 * Bryan Bosely <bbosely@redhat.com>
 * 2011-11-?? - Added insertLead trigger method
 * 2011-11-17 - Added method to determine lead sub-region
 * Scott Coleman <scoleman@redhat.com>
 * 2012-10-04 - Update to updateStage to prevent stage change to Prospect when lead in penalty box
 * 2012-07-20 - Update to updateStage to move Stage back to Inquiry when appropriate
 * 2012-07-13 - Add support for capturing date of last ownership change
 * 2012-05-21 - Add support for Suspect leads from Eloqua
 */
public without sharing class LeadTriggerBeforeGLM extends LeadTriggerBefore {
	/** Number of days in the future to consider for open activities */
	public static final Integer DEVELOPING_DAYS = 30;
	/** Number of days in the past to consider for activities history entries*/
	public static final Integer WORKING_DAYS = 7;
	/** Id of the Inquiries Queue */
	public static final Id INQUIRIES_QUEUE = '00G60000001Li1I';
	/** Id of the New Leads Queue */
	public static final Id NEW_LEADS_QUEUE = '00G60000001Ln8A';
	/** Id of the Prospect Queue */
	public static final Id PROSPECT_QUEUE = '00GP0000000NbPp';
	/** Id of the Eloqua Marketing User */
	public static final Id ELOQUA_MARKETING_ID = '00560000001RQvf';
	/** Id of the Eloqua Marketing User */
	public static final Id INTEGRATION_ADMIN_ID = '00530000000f8Sv';
	/** This is the list of lead rankings high enough to set a stage value. */
	public static final String LEAD_RANKINGS_OF_INTEREST = 'P1P2A1A2A3B1B2C1';
	/** Error message to report when a lead is locked. */
	public static final String LOCKED_ERROR = 'You must accept the lead before editing it.';
	/** Sales Contact stage value */
	public static final String SALES_CONTACT = 'Sales Contact';
	/** Sales Qualified stage value */
	public static final String SALES_QUALIFIED = 'Sales Qualified';
	/** Sales Disqualified stage value */
	public static final String SALES_DISQUALIFIED = 'Sales Disqualified';
	/** Sales Accepted stage value */
	public static final String SALES_ACCEPTED = 'Sales Accepted';
	/** Sales Rejected stage value */
	public static final String SALES_REJECTED = 'Sales Rejected';
	/** Marketing Accepted stage value */
	public static final String MARKETING_ACCEPTED = 'Marketing Accepted';
	/** Marketing Rejected stage value */
	public static final String MARKETING_REJECTED = 'Marketing Rejected';
	/** Marketing Qualified stage value */
	public static final String MARKETING_QUALIFIED = 'Marketing Qualified';
	/** Marketing Disqualified stage value */
	public static final String MARKETING_DISQUALIFIED = 'Marketing Disqualified';
	/** Suspect stage value */
	public static final String SUSPECT = 'Suspect';
	/** Inquiry stage value */
	public static final String INQUIRY = 'Inquiry';
	/** Prospect stage value */
	public static final String PROSPECT = 'Prospect';
	/** This is the set of locked stages */
	public static final Set<String> LOCKED_STAGES = new Set<String> {
		INQUIRY.toUpperCase(), PROSPECT.toUpperCase(), MARKETING_QUALIFIED.toUpperCase() };
	/** Nuturing status */
	public static final String NURTURING = 'Nurturing';
	/** Waiting status */
	public static final String WAITING = 'Waiting';
	/** Developing status */
	public static final String DEVELOPING = 'Developing';
	/** Working status */
	public static final String WORKING = 'Working';
	/** Not working status */
	public static final String NOT_WORKING = 'Not Working';
	/** Converted status */
	public static final String CONVERTED = 'Converted';
	/** BooleanSetting__c key to enable the assignLeadForReportingId trigger method. */
	public static final String ASSIGN_LEAD_FOR_REPORTING_ID_SETTING = 'Lead_Before.lfrId';
	/** BooleanSetting__c key to enable the insertHistory trigger method. */
	public static final String INSERT_HISTORY_SETTING = 'Lead_Before.insertHistory';
	/** BooleanSetting__c key to enable the insertStatus trigger method. */
	public static final String INSERT_STAGE_SETTING = 'Lead_Before.insertStage';
	/** BooleanSetting__c key to enable the leadLock trigger method. */
	public static final String LEAD_LOCK_SETTING = 'Lead_Before.leadLock';
	/** BooleanSetting__c key to enable the stageUpdated trigger method. */
	public static final String STAGE_UPDATED_SETTING = 'Lead_Before.stageUpdated';
	/** BooleanSetting__c key to enable the leadConverted trigger method. */
	public static final String LEAD_CONVERTED_SETTING = 'Lead_Before.leadConverted';
	/** BooleanSetting__c key to enable the ownerUpdated trigger method. */
	public static final String OWNER_UPDATED_SETTING = 'Lead_Before.ownerUpdated';
	/** BooleanSetting__c key to enable the updateStage trigger method. */  
	public static final String UPDATE_STAGE_SETTING = 'Lead_Before.updateStage';
	/** BooleanSetting__c key to enable the updateStatus trigger method. */
	public static final String UPDATE_STATUS_SETTING = 'Lead_Before.updateStatus';

	/** Boolean value to test the lead converted to opportunity condition. */
	public static Boolean toOpportunity = false;
	/** Boolean value to test the lead converted to contact condition. */
	public static Boolean toContact = false;
	public static DateTime leadConversionStartDate = null;

	/**
	 * This constructor is normally called from the processTrigger method and
	 * test methods.
	 */
	public LeadTriggerBeforeGLM(Map<Id,Lead> xoldMap,List<Lead> xnewList) {
		super(xoldMap,xnewList);
	}


	public void assignLeadForReportingId() {
		if(isUpdate) {
			Set<String> leadIds = new Set<String>();
			for(Lead lead : newList) {
				if(lead.LFR__c == null) {
					leadIds.add(lead.Id);
				}
			}
			if(!leadIds.isEmpty()) {
				Map<Id,Id> lfrIdMap = new Map<Id,Id>();
				for(LeadForReporting__c lfr : [
					select LeadId__c
					from LeadForReporting__c
					where LeadId__c in :leadIds])
				{
					lfrIdMap.put(lfr.LeadId__c,lfr.Id);
				}
				for(Lead lead : newList) {
					if(lead.LFR__c == null) {
						lead.LFR__c = lfrIdMap.get(lead.Id);
					}
				}
			}
		}
	}
	/**
	 * Update the lead stage after a lead has been converted.
	 */
	public void leadConverted() {
		if(isUpdate) {
			for(Lead lead : newList) {
				if(Lead_GlobalManagement.GLM_RECORDTYPE_IDS.contains(lead.RecordTypeId)) {
					User owner = userMap.get(lead.OwnerId);
					if((owner != null && owner.IsPortalEnabled !=  true)||(owner == null && currentUser.IsPortalEnabled != true)) {
						if(toContact || toOpportunity || (lead.IsConverted && ! oldMap.get(lead.Id).IsConverted)) {
							if(currentUser.Is_Marketing_User__c == true) {
								if(lead.Stage__c != MARKETING_QUALIFIED) {
									lead.Stage__c = MARKETING_QUALIFIED;
								}
							}
							else if(toOpportunity || lead.ConvertedOpportunityId != null) {
								if(lead.Stage__c != SALES_QUALIFIED) {
									lead.Stage__c = SALES_QUALIFIED;
								}
							}
							else if(toContact || lead.ConvertedContactId != null) {
								if(lead.Stage__c != SALES_CONTACT) {
									lead.Stage__c = SALES_CONTACT;
								}
							}
						}
					}
				}
			}
		}
	}

	/**
	 * Update the LeadStageModifiedDateTime__c value each time the stage value
	 * is set.
	 */
	public void stageUpdated() {
		DateTime n = null;
		for(Lead lead : newList) {
			Lead oldLead = null;
			if(oldMap != null) {
				oldLead = oldMap.get(lead.Id);
			}
			if(oldLead == null || oldLead.Stage__c != lead.Stage__c) {
				if(n == null) {
					n = DateTime.now();
				}
				lead.LastStageModifiedDateTime__c = n;
			}
		}
	}
	
	/**
	 * Update the LeadOwnerModifiedDateTime__c value each time the stage value
	 * is set.
	 */
	public void ownerUpdated() {
		DateTime n = null;
		for(Lead lead : newList) {
			Lead oldLead = null;
			if(oldMap != null) {
				oldLead = oldMap.get(lead.Id);
			}
			if(oldLead == null || oldLead.OwnerId != lead.OwnerId) {
				if(n == null) {
					n = DateTime.now();
				}
				lead.LastOwnerModifiedDateTime__c = n;
			}
		}
	}

	private void setStatus(Lead ld,String status) {
		if(ld != null && ld.Status != status) {
			ld.Status = status;
		}
	}

	/**
	 * Trigger method for automatically updating stage for GLM leads.
	 */
	public void updateStage() {
		if(isUpdate) {
			for(Lead ld : newList) {
				if(ld.Lead_Ranking__c != null && Lead_GlobalManagement.GLM_RECORDTYPE_IDS.contains(ld.RecordTypeId)) {
					Lead ldOld = oldMap.get(ld.Id);				 
					if(ldOld.Stage__c == ld.Stage__c && (ldOld.OwnerId == NEW_LEADS_QUEUE || ldOld.OwnerId == INQUIRIES_QUEUE)) {
						if (LEAD_RANKINGS_OF_INTEREST.indexOf(ld.Lead_Ranking__c.toUpperCase()) >= 0) {
							if (ld.PenaltyBoxExpiration__c == null || ld.PenaltyBoxExpiration__c <= DateTime.now()) {
								ld.Stage__c = PROSPECT;
							}
						}
						else {
							ld.Stage__c = INQUIRY;		  
						}
					}
				}
			}
		}
	}
	
	public void insertStage() {
		if (isInsert) {
			for ( Lead ld : newList) {
				if (ld.Stage__c == SUSPECT) {
					ld.HistoryOnInsert__c = true;
					ld.HistoryOnInsertStage__c = SUSPECT;
					ld.Stage__c = INQUIRY;
				}
				//
				// skip API users (we assume the API users will set the correct stage)
				//
				if ( currentUser.Id != ELOQUA_MARKETING_ID && currentUser.Id != INTEGRATION_ADMIN_ID ) {
					//
					// skip partner created leads and non-GLM leads
					//
					if ( ld.Partner_Onboarding_Status__c != 'Approved' && Lead_GlobalManagement.GLM_RECORDTYPE_IDS.contains(ld.RecordTypeId)) {
						Id ownerId = currentUser.Id;
						if(ld.OwnerId != null) {
							ownerId = ld.OwnerId;
						}
						User owner = userMap.get(ownerId);
						// skip partner owned leads and leads assigned to queues
						if((owner != null && owner.IsPortalEnabled != true)) {
							String stage = MARKETING_ACCEPTED;
							if( ! owner.Is_Marketing_User__c )  {
								stage = SALES_ACCEPTED;
								ld.Route_Around__c = true;
							}
							if(stage != ld.Stage__c) {
								ld.Stage__c = stage;
							}
						}
					}
				}
			}
		}
	}

	public static Long dueTimeLimit {
		get {
			if(dueTimeLimit == null) {
				dueTimeLimit = DateTime.now().addDays(DEVELOPING_DAYS).getTime();
			}
			return dueTimeLimit;
		}
		set;
	}

	public static DateTime activityHistoriesDateTimeLimit {
		get {
			if(activityHistoriesDateTimeLimit == null) {
				activityHistoriesDateTimeLimit = DateTime.now().addDays(-WORKING_DAYS);
			}
			return activityHistoriesDateTimeLimit;
		}
		set;
	}

	/**
	 * Trigger method for automatically updating status for GLM leads.
	 */
	public void updateStatus() {
		Map<Id,Lead> leadMap = new Map<Id,Lead>();
		for(Lead ld :newList) {
			if(Lead_GlobalManagement.GLM_RECORDTYPE_IDS.contains(ld.RecordTypeId)) {
				User owner = userMap.get(ld.OwnerId);
				if((owner != null && owner.IsPortalEnabled !=  true)||(owner == null && currentUser.IsPortalEnabled != true)) {
					ld.Next_Status_Update__c = null;
					if(ld.OwnerId == INQUIRIES_QUEUE) {
						setStatus(ld,NURTURING);
					}
					else if(ld.Stage__c == INQUIRY) {
						setStatus(ld,WAITING);
					}
					else if(ld.Stage__c == null || ld.Stage__c == PROSPECT || ld.Stage__c == MARKETING_QUALIFIED) {
						setStatus(ld,WAITING);
					}
					else if(ld.Stage__c == MARKETING_REJECTED || ld.Stage__c == MARKETING_DISQUALIFIED || ld.Stage__c == SALES_REJECTED || ld.Stage__c == SALES_DISQUALIFIED) {
						setStatus(ld,NURTURING);
					}
					else if(ld.Stage__c == SALES_QUALIFIED || ld.Stage__c == SALES_CONTACT) {
						setStatus(ld,CONVERTED);
					}
					else if(ld.Stage__c == MARKETING_ACCEPTED || ld.Stage__c == SALES_ACCEPTED) {
						if(isUpdate) {
							// we need to query activites to decide which stage to set this to
							leadMap.put(ld.Id,ld);
						}
						else {
							setStatus(ld,NOT_WORKING);
						}
					}
				}
			}
		}
		if(! leadMap.isEmpty()) {
			DateTime nowDateTime = DateTime.now();
			Long nowTime = nowDateTime.getTime();
			dueTimeLimit = null;
			activityHistoriesDateTimeLimit = null;
			Map<Id,Lead> ldMap = null;
			for(Lead ld : [
				select 
					Id, 
					(   select
							ClosedDate__c
						from ActivityHistories
						where CreatedById != :ELOQUA_MARKETING_ID
							and ClosedDate__c >= :activityHistoriesDateTimeLimit
						order by ClosedDate__c desc 
						limit 1 ),
					(   select
							Due_Date_Time__c
							from OpenActivities
							where CreatedById != :ELOQUA_MARKETING_ID
								and Due_Date_Time__c != null
							order by Due_Date_Time__c asc
							limit 2 )
				from Lead 
				where Id in :leadMap.keySet() ] )
			{
				Lead newLead = leadMap.get(ld.Id);
				String status = NOT_WORKING;
				if(ld.ActivityHistories != null && ! ld.ActivityHistories.isEmpty()) {
					DateTime closedDate = ld.ActivityHistories[0].ClosedDate__c;
					//newLead.LastActivityHistoryDate__c = closedDate;
					newLead.Next_Status_Update__c = closedDate.addDays(WORKING_DAYS);
					status = WORKING;
				}
				else if(ld.OpenActivities != null && ! ld.OpenActivities.isEmpty() ) {
					DateTime dueDateTime = ld.OpenActivities[0].Due_Date_Time__c;
					Long dueTime = dueDateTime.getTime();
					// US221120: If there is at least one past due open activity and all
					// other open activities set the status to not working. // DE3646
					if(dueTime < nowTime && ld.OpenActivities.size() > 1) {
						if(ldMap == null) {
							ldMap = new Map<Id,Lead>([
								select 
								(   select
										Due_Date_Time__c
									from OpenActivities
									where CreatedById != :ELOQUA_MARKETING_ID
										and Due_Date_Time__c != null
										and Due_Date_Time__c >= :nowDateTime
									order by Due_Date_Time__c desc 
									limit 1 )
								from Lead 
								where Id in :leadMap.keySet() ] );
						}
						ld = ldMap.get(ld.Id);
						if(ld.OpenActivities != null && ! ld.OpenActivities.isEmpty() ) {
							dueDateTime = ld.OpenActivities[0].Due_Date_Time__c;
							dueTime = dueDateTime.getTime();
						}
					}
					if(dueTime >= nowTime) {
						if(dueTime > dueTimeLimit) {
							newLead.Next_Status_Update__c = dueDateTime.addDays(-DEVELOPING_DAYS);
						}
						else {
							status = DEVELOPING;
							newLead.Next_Status_Update__c = dueDateTime;
						}
					}
				}
				setStatus(newLead,status);
			}
		}
	}

	/**
	 * Compare two objects as strings to determine if they are equal.
	 * @returns true if the string values are equal.
	 */
	static Boolean equalValues(Object a,Object b) {
		return (a == null || String.valueOf(a) == '')?(b == null || String.valueOf(b) == ''):(b != null && String.valueOf(a) == String.valueOf(b));
	}

	/**
	 * This trigger method adds an error to the lead if the lead is updated while locked.
	 * The general rule is a lead can only be updated when the stage is changed, the
	 * owner is changed, the lead stage is not a in LOCKED_STAGES or there is a new 
	 * leadManagementHistoryMap record.
	 *
	 * The Unil.adminByPass(false) method is called to bypass locking checks for admin users.
	 */
	public void leadLock() {
		if(isUpdate && ! Util.adminByPass(false)) {
			FieldAccessAsUser faau = null;
			for(Lead newLead : newList) {
				Lead oldLead = oldMap.get(newLead.Id);
				if(
					newLead.Stage__c != null 
					&& oldLead.Stage__c == newLead.Stage__c 
					&& oldLead.OwnerId == newLead.OwnerId 
					&& LOCKED_STAGES.contains(newLead.Stage__c.toUpperCase()) 
					&& Lead_GlobalManagement.GLM_RECORDTYPE_IDS.contains(newLead.RecordTypeId)
					&& (! LeadTriggerAfterGLM.leadManagementHistoryMap.containsKey(newLead.Id)) )
				{
					if(faau == null) {
						faau = new FieldAccessAsUser();
					}
					for(String fieldName : faau.getFieldNames()) {
						if((! equalValues(oldLead.get(fieldName),newLead.get(fieldName)))&&faau.isUpdateable(fieldName)&&currentUser.IsPortalEnabled != true) {
							newLead.addError(LOCKED_ERROR);
							hasErrors = true;
							break;
						}
					}
				}
			}
		}
	}

	/**
	 * Create a newMap as needed.
	 */
	private Map<Id,Lead> newMap {
		get {
			if(newMap == null && isUpdate) {
				try {
					newMap = new Map<Id,Lead>(newList);
				}
				catch(Exception e) {
					// this only happens in test code where lead.Id is null
					newMap = new Map<Id,Lead>();
					for(Lead lead : newList) {
						newMap.put(lead.Id,lead);
					}
				}
			}
			return newMap;
		}
		set;
	}

	/**
	 * This trigger method inserts lead history management records if and only if
	 * the lead is being converted and the stage has changed.
	 */
	public void insertHistory() {
		hasErrors = LeadTriggerAfterGLM.insertHistory(oldMap,newMap,true,hasErrors);
	}

	/**
	 * This method is called from the Lead_Before trigger to invoke all the methods
	 * of this class, to obsolete the need for individual before triggers.  The primary
	 * reason to place all the triggers in a class is so we control the order in which
	 * the triggers are invoked.
	 *
	 * @param xoldMap the immutable map of previous Lead objects as in Trigger.oldMap.
	 * @param xnewList the list of new Lead objects as in Trigger.new
	 */
	public static void processTrigger(Map<Id,Lead> xoldMap,List<Lead> xnewList) {
		final LeadTriggerBeforeGLM beforeTrigger = new LeadTriggerBeforeGLM(xoldMap,xnewList);
		if(AbstractTrigger.isActive(ASSIGN_LEAD_FOR_REPORTING_ID_SETTING,true)) {
			beforeTrigger.assignLeadForReportingId();
		}
		// a stage update will cause locking to be by passed.
		if(AbstractTrigger.isActive(UPDATE_STAGE_SETTING,true)) {
			beforeTrigger.updateStage();
		}
		if(AbstractTrigger.isActive(STAGE_UPDATED_SETTING,true)) {
			beforeTrigger.stageUpdated();
		}
		if(AbstractTrigger.isActive(OWNER_UPDATED_SETTING,true)) {
			beforeTrigger.ownerUpdated();
		}	   
		if(AbstractTrigger.isActive(LEAD_CONVERTED_SETTING,true)) {
			beforeTrigger.leadConverted();
		}
		if(AbstractTrigger.isActive(LEAD_LOCK_SETTING,true)) {
			beforeTrigger.leadLock();
		}
		// this happens after the lead lock so this update will be allowed
		if(AbstractTrigger.isActive(UPDATE_STATUS_SETTING,true)) {
			beforeTrigger.updateStatus();
		}
		if(AbstractTrigger.isActive(INSERT_HISTORY_SETTING,true)) {
			beforeTrigger.insertHistory();
		}
	}

	/**
	 * This class allows us to access field permissions with sharing.
	 */
	public with sharing class FieldAccessAsUser {
		private final Map<String,Schema.SObjectField> fieldMap = Schema.SObjectType.Lead.fields.getMap();

		/** Query the set of field names. */
		public Set<String> getFieldNames() {
			return fieldMap.keySet();
		}

		/** Query if a field is updateable */
		public Boolean isUpdateable(String fieldName) {
			Boolean retval = false;
			Schema.SObjectField sf = fieldMap.get(fieldName);
			if(sf != null) {
				retval = sf.getDescribe().isUpdateable();
			}
			return retval;
		}
	}
}