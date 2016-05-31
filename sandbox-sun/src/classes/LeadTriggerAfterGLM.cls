/**
 * This class replaces all after insert and after update lead triggers.  The
 * processTrigger method is invoked by the Lead_After trigger and in turn invokes
 * all the methods of this class.  This gives us a way to control the order in
 * which the code logic is invoked, as well as allowing other class features such
 * as shared data, constant values, and regorious test coverage.
 * <p>
 * The Trigger object should never be directly referenced inside this class, as
 * that would make it impossible to substituting values inside test methods.
 * </p>
 *
 * @version 2016-03-01
 * @author Bill C Riemers <briemers@redhat.com>
 * @since 2016-03-01 - cleaned up formatting
 * @since 2014-02-20 - Added insertLeadForReporting method
 * @since 2013-08-07 - Added methods for leadConvertWizard
 * @since 2012-03-29 - Commented out code for US17312
 * @since 2012-03-05 - split into a subclass
 * @since 2011-09-01 - Created
 * @author Scott Coleman <scoleman@redhat.com>
 * @since 2013-09-17 - Added notification back to lead dev user if updates to opp, contact, account fail
 * @since 2013-09-12 - Added method to clear lead dev user's opportunity team 
 * @since 2013-08-12 - Added additional methods for leadConvertWizard (default opp amount and stage)
 * @since 2013-05-01 - Now touching related CampaignMember objects to invoke their triggers
 * @since 2012-10-04 - Exclude partner led leads from Lead Management History
 * @since 2012-07-16 - Now generating LMH records on ownership change
 * @since 2012-07-13 - Populate last ownership change datetime on LMH records
 * @since 2012-05-31 - Exclude deal reg leads from Lead Management History
 * @since 2012-05-21 - Add support for Suspect leads from Eloqua
 * @author Sundeep Godishala <sgodisha@redhat.com>
 * @since 2016-01-26 - Added fields (US81525) 
 * @since 2016-02-01 - Added method upsertLMH to capture new fields(US81256) on Lead Management History
 */
public without sharing class LeadTriggerAfterGLM extends LeadTriggerAfter {
	/** BooleanSetting__c key to enable the insertHistory trigger method. */
	public static final String INSERT_HISTORY_SETTING = 'Lead_After.insertHistory';
	/** BooleanSetting__c key to enable the insertLeadForReporting trigger method. */
	public static final String LEAD_FOR_REPORT_SETTING = 'Lead_After.leadForReport';
	/** BooleanSetting__c key to enable the leadConvertWizard trigger method. */
	public static final String LEAD_CONVERT_WIZARD_SETTING = 'Lead_After.leadConvWizard';
	/** BooleanSetting__c key to enable the updateHistory trigger method. */
	public static final String UPDATE_HISTORY_SETTING = 'Lead_After.updateHistory';
	/** BooleanSetting__c key to enable the touchCampaignMember trigger method. */
	public static final String UPSERT_HISTORY_SETTING = 'Lead_After.upsertLMH';
	/** BooleanSetting__c key to enable the upsertLMH trigger method. */
	public static final String TOUCH_CAMPAIGN_MEMBERS_SETTING = 'Lead_After.touchCampaignMembers';
	/** StringSetting__c key for opportunity assignment e-mail template. */
	public static final String OPPORTUNITY_ASSIGNMENT_EMAIL_TEMPLATE_SETTING = 'Opportunity.AssignmentEmailTemplate';
	/** StringSetting__c key for lead conversion wizard failure email template. */
	public static final String LEAD_CONVERSION_ERROR_EMAIL_TEMPLATE_SETTING = 'Lead.ConversionFailureEmailTemplate';	
	/** Team Member Role for inside sales rep. */
	public static final String INSIDE_REP_STRING = 'INSIDE REP';
	/** Team Member Role for outside sales rep. */
	public static final String OUTSIDE_REP_STRING = 'OUTSIDE REP';

//US17312   /** BooleanSetting__c key to enable the createNPSA trigger method. */
//US17312   public static final String CREATE_NPSA_SETTING = 'Lead_After.createNPSA';
	
	/** Set of records type Ids for which we should generate Lead Management History records **/
	public static Set<Id> lmhRecordTypeIds {
		get {
			if (lmhRecordTypeIds == null) {
				List<RecordType> recordTypeList = new List<RecordType>([select Name
					from RecordType 
					where SobjectType = 'Lead' 
						and Name in ('APAC Sales Lead','EMEA Sales Lead','LATAM Sales Lead','Lead Gen','NA Sales Lead') ]);
				
				lmhRecordTypeIds = new Set<Id>();
				for (RecordType rt : recordTypeList) {
					lmhRecordTypeIds.add(rt.Id);
				}
			}
			return lmhRecordTypeIds;
		}
		set;
	}

	/** Email template for opportunity assignment notifications. */
	public static EmailTemplate OPPORTUNITY_ASSIGNMENT_EMAIL_TEMPLATE {
		get {
			if(OPPORTUNITY_ASSIGNMENT_EMAIL_TEMPLATE == null) {
				StringSetting__c emailTemplateSetting = StringSetting__c.getInstance(OPPORTUNITY_ASSIGNMENT_EMAIL_TEMPLATE_SETTING);
				if(emailTemplateSetting != null && emailTemplateSetting.Value__c != null) {
					for(EmailTemplate et : [
						select Name, Body, Subject, Description
						from EmailTemplate
						where
							DeveloperName = :emailTemplateSetting.Value__c
							and IsActive = true
						order by LastModifiedDate desc limit 1 ] )
					{
						OPPORTUNITY_ASSIGNMENT_EMAIL_TEMPLATE = et;
					}
				}
			}
			return OPPORTUNITY_ASSIGNMENT_EMAIL_TEMPLATE;
		}
		set;
	}

	/** Email template to notify of conversion errors. */
	public static EmailTemplate LEAD_CONVERSION_ERROR_EMAIL_TEMPLATE {
		get {
			if(LEAD_CONVERSION_ERROR_EMAIL_TEMPLATE == null) {
				StringSetting__c emailTemplateSetting = StringSetting__c.getInstance(LEAD_CONVERSION_ERROR_EMAIL_TEMPLATE_SETTING);
				if(emailTemplateSetting != null && emailTemplateSetting.Value__c != null) {
					for(EmailTemplate et : [
						select Name, Body, Subject, Description
						from EmailTemplate
						where
							DeveloperName = :emailTemplateSetting.Value__c
							and IsActive = true
						order by LastModifiedDate desc limit 1 ] )
					{
						LEAD_CONVERSION_ERROR_EMAIL_TEMPLATE = et;
					}
				}
			}
			return LEAD_CONVERSION_ERROR_EMAIL_TEMPLATE;
		}
		set;
	}

	/** static map of Lead Management History objects to be inserted or updated */
	public static Map<Id,LeadManagementHistory__c> leadManagementHistoryMap = new Map<Id,LeadManagementHistory__c>();

	/** static map of Lead Management History objects created by this class */
	private static Map<Id,LeadManagementHistory__c> cache = new Map<Id,LeadManagementHistory__c>();

	/** when the cache map should be cleared */
	private static Long timeout = null;

	/** set to simulate converting a lead to an account */
	public static Id toAccountId = null;

	/** set to simulate converting a lead to an opportunity */
	public static Id toOpportunityId = null;

	/**
	 * This constructor is normally called from the processTrigger method and
	 * test methods.
	 */
	public LeadTriggerAfterGLM(Map<Id,Lead> xoldMap,Map<Id,Lead> xnewMap) {
		super(xoldMap,xnewMap);
	}

	/**
	 * Set Lead Management History values given a oldLead and a newLead.
	 *
	 * @param oldLead the old lead value
	 * @param newLead the new lead value
	 * @param lmh the Lead Management History object to update
	 * @returns the updated Lead Management History object
	 */
	public static LeadManagementHistory__c updateLMH(Lead oldLead,Lead newLead,LeadManagementHistory__c lmh) {
		if(lmh.LeadStageFrom__c == null) {
			lmh.LeadStageFrom__c = oldLead.Stage__c;
		}
		if(lmh.LeadStageTo__c == null) {
			lmh.LeadStageTo__c = newLead.Stage__c;
		}
		if(lmh.OwnerId_From__c == null) {
			lmh.OwnerId_From__c = oldLead.OwnerId;
		}
		if(lmh.Id == null) {
			lmh.FromStageModifiedDateTime__c = oldLead.LastStageModifiedDateTime__c;
			lmh.FromOwnerModifiedDateTime__c = oldLead.LastOwnerModifiedDateTime__c;
		}
		lmh.OwnerId_To__c = newLead.OwnerId;
		lmh.Lead__c = newLead.Id;
		lmh.Lead_Ranking__c = newLead.Lead_Ranking__c;
		lmh.Lead_Source__c = newLead.LeadSource;
		lmh.Lead_Source_Detail__c = newLead.LeadSourceDetail__c;
		lmh.Qualification_Score__c = newLead.Qualification_Score__c;
		lmh.Interest_Score__c = newLead.Interest_Score__c;
		//Surbhi - Below code has been added for April 2012 AM release case #RH-00131893 - Begin
		lmh.Pre_Qualified_To__c = newLead.Pre_Qualified__c;
		lmh.Pre_Qualified_From__c = oldLead.Pre_Qualified__c;
		//End
		lmh.Qualified_By__c = newLead.Qualified_By__c;
		//Sundeep - Added for US78564
		//Sundeep - modified for US81525
		system.debug('New@@@' + newLead.Contact_Sales__c + ' old@@@' + oldLead.Contact_Sales__c);
		lmh.Contact_Sales_To__c = newLead.Contact_Sales__c;
		lmh.Contact_Sales_From__c = oldLead.Contact_Sales__c;
		lmh.Came_From_Eloqua_To__c = newLead.Came_From_Eloqua__c;
		lmh.Came_From_Eloqua_From__c = oldLead.Came_From_Eloqua__c;
		lmh.Sent_to_Lead_Development_To__c = newLead.Sent_to_Lead_Development__c;
		lmh.Sent_to_Lead_Development_From__c = oldLead.Sent_to_Lead_Development__c;
		//End 
		lmh.Route_Around_To__c = newLead.Route_Around__c;
		lmh.Route_Around_From__c = oldLead.Route_Around__c;
		return lmh;
	}

	/**
	 * Method to upsert lead management history records.
	 */
	public void upsertLMH() {
			// generate the list of Lead Ids that need a new lead management history record
			Map<Id,Id> LeadIdByLeadForReportingIdMap = new Map<Id,Id>();
			for(Lead ld : newMap.values()) {
				if(ld.LFR__c != null) {
					Lead oldLd = oldMap.get(ld.Id);
				   
					if(oldLd.Original_Offer__c != ld.Original_Offer__c || oldLd.Original_Tactic__c != ld.Original_Tactic__c || oldLd.Most_Recent_Offer__c != ld.Most_Recent_Offer__c || oldLd.Most_Recent_Tactic__c != ld.Most_Recent_Tactic__c) {
						LeadIdByLeadForReportingIdMap.put(ld.LFR__c,ld.Id);
					}
				}
			}
			if(! LeadIdByLeadForReportingIdMap.isEmpty()) {
				List<LeadManagementHistory__c> lmhList = new List<LeadManagementHistory__c>();
				// query the related leads and most recent history record
				for(LeadForReporting__c lfr : [
					select
						Id,
						(   select
								Most_Recent_Offer_From__c,
								Most_Recent_Offer_To__c,
								Most_Recent_Tactic_From__c,
								Most_Recent_Tactic_To__c,
								Original_Offer_From__c,
								Original_Offer_To__c,	   
								Original_Tactic_From__c,
								Original_Tactic_To__c					  
							from Lead_Management_Histories__r
							order by CreatedDate desc,Id desc
							limit 1)
					from LeadForReporting__c
					where Id in :LeadIdByLeadForReportingIdMap.keySet() ])
				{
					Id ldId = LeadIdByLeadForReportingIdMap.get(lfr.Id);
					// if there is a history record create a new history record
					for(LeadManagementHistory__c lmh : lfr.Lead_Management_Histories__r) {
						Lead ld= newMap.get(ldId);
						Lead oldLd = oldMap.get(ldId);					  
						if((oldLd.Original_Offer__c != ld.Original_Offer__c) || (oldLd.Original_Tactic__c != ld.Original_Tactic__c) || (oldLd.Most_Recent_Offer__c != ld.Most_Recent_Offer__c) || (oldLd.Most_Recent_Tactic__c != ld.Most_Recent_Tactic__c)) {
							LeadManagementHistory__c lmh2 = lmh.clone(true);
							lmh2.Most_Recent_Offer_To__c = ld.Most_Recent_Offer__c;
							lmh2.Original_Offer_To__c = ld.Original_Offer__c;
							lmh2.Most_Recent_Tactic_To__c = ld.Most_Recent_Tactic__c;
							lmh2.Original_Tactic_To__c = ld.Original_Tactic__c;
							lmh2.Most_Recent_Offer_From__c = oldLd.Most_Recent_Offer__c;
							lmh2.Original_Offer_From__c = oldLd.Original_Offer__c;
							lmh2.Most_Recent_Tactic_From__c = oldLd.Most_Recent_Tactic__c;
							lmh2.Original_Tactic_From__c = oldLd.Original_Tactic__c;
																				   
							lmhList.add(lmh2);
						}
					}
				}
				if(! lmhList.isEmpty()) {
					for(Database.UpsertResult sr : Database.upsert(lmhList,false)) {
						LeadManagementHistory__c lmh = lmhList.remove(0);
						if((! sr.isSuccess())) {
							Lead ld = newMap.get(lmh.Lead__c);
							ld.addError('Failed to insert LMH Record: '+sr.getErrors());
							hasErrors = true;
						}
					}
				}
			}
		}

	/**
	 * Insert and update reference objects that can be can continue to be used
	 * after a lead has been converted.
	 */
	public void insertLeadForReporting() {
		if(isInsert) {
			List<LeadForReporting__c> lfrList = new List<LeadForReporting__c>();
			for(Lead ld : newMap.values()) {
				lfrList.add(new LeadForReporting__c(
					Lead__c=ld.Id,
					LeadId__c=ld.Id));
			}
			Database.insert(lfrList,false);
		}
	}

	private static Map<Id,Id> getLeadForReportingIdMap(List<Lead> leads,Map<Id,Id> retval) {
		if(retval == null) {
			retval = new Map<Id,Id>();
			Set<String> leadIds = new Set<String>();
			for(Lead lead : leads) {
				retval.put(lead.Id,lead.LFR__c);
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
					retval.put(lfr.LeadId__c,lfr.Id);
				}
			}
		}
		return retval;
	}

	/**
	 * Called by the insertHistory methods of both the before and after trigger classes.
	 * This triggerMethod inserts Lead Management History records when the 
	 * stage changes or there is a record in the static map.
	 *
	 * @param oldMap the map of old lead values
	 * @param newMap the updatable map of new lead values
	 * @param isBefore true if called from the before trigger class
	 * @param retval the previous value of hasErrors
	 * @returns the new value of hasErrors
	 */
	public static Boolean insertHistory(Map<Id,Lead> oldMap,Map<Id,Lead> newMap,Boolean isBefore,Boolean retval) {
		if(newMap != null && ! retval ) {
			DateTime currentDateTime = DateTime.now();
			if(timeout != null && timeout < currentDateTime.getTime()) {
				cache.clear();
			}
			cache.keySet().retainAll(newMap.keySet());
			timeout = currentDateTime.addSeconds(60).getTime();
			List<LeadManagementHistory__c> lmhList = new List<LeadManagementHistory__c>();
			Map<Id,Id> lfrIdMap = null;
			for(Lead lead : newMap.values()) {
				if(lead.IsConverted == isBefore && lmhRecordTypeIds.contains(lead.RecordTypeId) && !lead.Partner_Led_Lead__c) {
					Lead oldLead;
					if(oldMap != null) {
						oldLead = oldMap.get(lead.Id);
					}
					else if (lead.HistoryOnInsert__c) {
						oldLead = new Lead(
							Stage__c = lead.HistoryOnInsertStage__c, 
							OwnerId = lead.OwnerId,
							LastStageModifiedDateTime__c = lead.LastStageModifiedDateTime__c,
							LastOwnerModifiedDateTime__c = lead.LastOwnerModifiedDateTime__c,
							Pre_Qualified__c = lead.Pre_Qualified__c,
							Qualified_By__c = lead.Qualified_By__c,
							Route_Around__c = lead.Route_Around__c,
							//Came_From_Eloqua__c = lead.Came_From_Eloqua__c,
							Contact_Sales__c = lead.Contact_Sales__c,
							Sent_to_Lead_Development__c = lead.Sent_to_Lead_Development__c
							);
					}
					if(oldLead != null) {
						LeadManagementHistory__c lmh2 = cache.remove(lead.Id);
						LeadManagementHistory__c lmh = leadManagementHistoryMap.get(lead.Id);
						if(lmh == null && (oldLead.Stage__c != lead.Stage__c || oldLead.OwnerId != lead.OwnerId)) {
							lfrIdMap = getLeadForReportingIdMap(newMap.values(),lfrIdMap);
							lmh = new LeadManagementHistory__c(LFR__c=lfrIdMap.get(lead.Id));
							if(lmh2 != null && lmh2.LeadStageFrom__c == oldLead.Stage__c && lmh2.LeadStageTo__c == lead.Stage__c) {
								lmh = lmh2;
								cache.put(lead.Id,lmh);
							}
						}
						if(lmh != null && lmh.Id == null) {
							lmhList.add(updateLMH(oldLead,lead,lmh));
						}
					}
				}
			}
			if(! lmhList.isEmpty()) {
				for(Database.SaveResult sr : Database.insert(lmhList,false)) {
					LeadManagementHistory__c lmh = lmhList.remove(0);
					cache.put(lmh.Lead__c,lmh);
					retval = LeadTriggerAfter.addErrorsToLead(lmh.Lead__c,newMap,'Unable to insert Lead Management History for lead '+lead.Id,sr.getErrors(),retval);
				}
			}
			cache.keySet().removeAll(leadManagementHistoryMap.keySet());
		}
		return retval;
	}

	/**
	 * This triggerMethod inserts Lead Management History records when the 
	 * stage changes or there is a record in the static map.
	 */
	public void insertHistory() {
		hasErrors = LeadTriggerAfterGLM.insertHistory(oldMap,newMap,false,hasErrors);
	}

	/**
	 * This triggerMethod updates Lead Management History records that are
	 * in the map when the owner id has been updated since creation.
	 * This allows us to correctly indicate the owner from workflow
	 * updates when routing with the send to sales button.
	 */
	public void updateHistory() {
		if(isUpdate && ! hasErrors) {
			List<LeadManagementHistory__c> lmhList = new List<LeadManagementHistory__c>();
			for(Lead lead : newMap.values()) {
				LeadManagementHistory__c lmh = leadManagementHistoryMap.get(lead.Id);
				if(lmh == null) {
					lmh = cache.get(lead.Id);
				}
				if(lmh != null && lmh.Id != null && lmh.OwnerId_To__c != lead.OwnerId) {
					lmh.OwnerId_To__c = lead.OwnerId;
					lmhList.add(lmh);
//				cache.remove(lead.Id);
				}
			}
			if(! lmhList.isEmpty()) {
				for(Database.Saveresult sr : Database.update(lmhList,false)) {
					LeadManagementHistory__c lmh = lmhList.remove(0);
					hasErrors = addErrorsToLead(lmh.Lead__c,newMap,'Unable to update Lead Management History for lead '+lead.Id,sr.getErrors(),hasErrors);
				}
			}
		}
	}

	/**
	 * This triggerMethod touched any CampaignMember objects related to
	 * updated leads that have a stage transition (detected using forumla
	 * field Rejected__c). This lets CampaignMember triggers reevaluate
	 * CampaignMember.IsLeadActive__c.
	 */
	public void touchCampaignMembers() {
		if(isUpdate) {
			Set<Id> leadIds = new Set<Id>();
			for(Lead newLead : newMap.values()) {
				Lead oldLead = oldMap.get(newLead.Id);
				if(newLead.Rejected__c != oldLead.Rejected__c) {
					leadIds.add(newLead.Id);
				}
			}
			if(!leadIds.isEmpty()) {
				List<CampaignMember> members = [
					select
						Id
					from CampaignMember
					where LeadId in :leadIds ];
				if(!members.isEmpty()) {
					//intentionlly swallowing any errors here - if there's a problem updating 
					// the campaign member (like a validation rule) we can't block the Lead update
					List<Database.SaveResult> results = Database.update(members, false);
				}
			}
		}
	}

	/**
	 * The set of field paths used by the lead conversion wizard.
	 */
	public static Set<String> leadConversionWizardFieldPaths {
		get {
			if(leadConversionWizardFieldPaths == null) {
				leadConversionWizardFieldPaths = new Set<String>();
				for(Schema.FieldSetMember fsm : Schema.SObjectType.Lead.fieldSets.LeadConversionWizardFields1.getFields()) {
					leadConversionWizardFieldPaths.add(fsm.getFieldPath());
				}
				for(Schema.FieldSetMember fsm : Schema.SObjectType.Lead.fieldSets.LeadConversionWizardFields2.getFields()) {
					leadConversionWizardFieldPaths.add(fsm.getFieldPath());
				}
				for(Schema.FieldSetMember fsm : Schema.SObjectType.Lead.fieldSets.LeadConversionWizardFields3.getFields()) {
					leadConversionWizardFieldPaths.add(fsm.getFieldPath());
				}
			}
			return leadConversionWizardFieldPaths;
		}
		set;
	}

	/**
	 * The set of field paths used by the lead conversion wizard for e-mail
	 * notification.
	 */
	public static Set<String> opportunityAssignmentFieldPaths {
		get {
			if(opportunityAssignmentFieldPaths == null) {
				opportunityAssignmentFieldPaths = new Set<String>();
				for(Schema.FieldSetMember fsm : Schema.SObjectType.Lead.fieldSets.Opportunity_Assignment.getFields()) {
					opportunityAssignmentFieldPaths.add(fsm.getFieldPath());
				}
			}
			return opportunityAssignmentFieldPaths;
		}
		set;
	}

	/**
	 * A map of default amounts for opportunities created by the lead conversion wizard by super region and business unit.
	 */
	public static Map<String,Map<String,LeadConvertWizardOppDefaultAmount__c>> opportunityDefaultAmountMap {
		get {
			if(opportunityDefaultAmountMap == null) {
				opportunityDefaultAmountMap = new Map<String,Map<String,LeadConvertWizardOppDefaultAmount__c>>();
				List<LeadConvertWizardOppDefaultAmount__c> oppDefaults = [
					SELECT 
						Amount__c,
						Business_Unit__c,
						Currency__c,
						Super_Region__c
					FROM LeadConvertWizardOppDefaultAmount__c
					ORDER BY Super_Region__c, Business_Unit__c];
				for(LeadConvertWizardOppDefaultAmount__c oppDefault : oppDefaults) {
					if(!opportunityDefaultAmountMap.keySet().contains(oppDefault.Super_Region__c)) {
						opportunityDefaultAmountMap.put(oppDefault.Super_Region__c,
							new Map<String,LeadConvertWizardOppDefaultAmount__c>{oppDefault.Business_Unit__c=>oppDefault});
					}
					else {
						opportunityDefaultAmountMap.get(oppDefault.Super_Region__c).put(oppDefault.Business_Unit__c,oppDefault);						
					}
				}
			}
			return opportunityDefaultAmountMap;
		}
		set;
	}

	/**
	 * A map of default stage values for opportunities created by the lead conversion wizard by super region.
	 */
	public static Map<String,LeadConvertWizardOppDefaultStage__c> opportunityDefaultStageMap {
		get {
			if(opportunityDefaultStageMap == null) {
				opportunityDefaultStageMap = new Map<String,LeadConvertWizardOppDefaultStage__c>();
				List<LeadConvertWizardOppDefaultStage__c> oppDefaults = [
					SELECT
						Probability__c,
						Stage__c,
						Super_Region__c
					FROM LeadConvertWizardOppDefaultStage__c
					ORDER BY Super_Region__c];
				for(LeadConvertWizardOppDefaultStage__c oppDefault : oppDefaults) {
					opportunityDefaultStageMap.put(oppDefault.Super_Region__c,oppDefault);
				}
			}
			return opportunityDefaultStageMap;
		}
		set;
	}

	/**
	 * Called by the leadConvertWizardFuture method to clear the default opp teams added to opps
	 * as these are the opp teams of the user that converted the lead, not the desired opp owner
	 * @param opps
	 */
	public static void clearOpportunityTeam(List<Opportunity> opps) {
		Set<Id> oppIds = new Set<Id>();
		for(Opportunity opp : opps) {
			if(opp.OwnerId != null) {
				oppIds.add(opp.Id);
			}
		}
		if(!oppIds.isEmpty()) {
			List<OpportunityTeamMember> teamMembers = [
				SELECT 
					Id
				FROM OpportunityTeamMember
				WHERE OpportunityId IN :oppIds];
			if(!teamMembers.isEmpty()) {
				for(Database.DeleteResult dr : Database.delete(teamMembers,false)) {
					if(! dr.isSuccess()) {
						System.debug('Failed to delete opportunity team: '+dr.getErrors());
					}
				}
			}
		}
		return;
	}

	/**
	 * Called by the leadConvertWizardFuture method to send a notification ofr opportunity
	 * assignments.
	 *
	 * @return a map of success and failed messages
	 */
	public static Map<Boolean,List<Messaging.SingleEmailMessage>> opportunityAssignmentNotification(List<Lead> leads) {
		Map<Boolean,List<Messaging.SingleEmailMessage>> retval = new Map<Boolean,List<Messaging.SingleEmailMessage>>{
				true=>new List<Messaging.SingleEmailMessage>(),
				false=>new List<Messaging.SingleEmailMessage>() };
		try {
			Set<Id> oppIds = new Set<Id>();
			Set<Id> leadIds = new Set<Id>();
			for(Lead ld : leads) {
				if(ld.SendEmailToOpportunityTeam__c != false && ld.ConvertedOpportunityId != null) {
					oppIds.add(ld.ConvertedOpportunityId);
					leadIds.add(ld.Id);
				}
			}
			if((! oppIds.isEmpty()) && OPPORTUNITY_ASSIGNMENT_EMAIL_TEMPLATE != null) {
				Map<Id,Set<String>> emailsMap = new Map<Id,Set<String>>();
				for(OpportunityTeamMember teamMember : [
					select OpportunityId, User.Email from OpportunityTeamMember
					where OpportunityId in :oppIds
						and User.IsActive = true 
						and TeamMemberRole in (:INSIDE_REP_STRING, :OUTSIDE_REP_STRING)] )
				{
					Set<String> emails = emailsMap.get(teamMember.OpportunityId);
					if(emails == null) {
						emails = new Set<String>();
						emailsMap.put(teamMember.OpportunityId,emails);
					}
					emails.add(teamMember.User.Email);
				}
				List<Messaging.SingleEmailMessage> messages = new List<Messaging.SingleEmailMessage>();
				List<Task> tasks = new List<Task>();
				for(Lead ld : leadConvertWizardQueryLeads(leadIds)) {
					Opportunity opp = ld.ConvertedOpportunity;
					if(opp != null) {
						Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
//					  if(opp.Owner.Contact_Id__c != null) {
//						  mail.setTargetObjectId(opp.Owner.Contact_Id__c);
//					  }
						mail.setToAddresses(new List<String>{opp.Owner.Email});
//					  mail.setWhatId(opp.Id);
						Set<String> emails = emailsMap.get(opp.Id);
						if(emails != null) {
							emails.remove(opp.Owner.Email);
							mail.setCcAddresses(new List<String>(emails));
						}
						String subject = OPPORTUNITY_ASSIGNMENT_EMAIL_TEMPLATE.Subject
							.replaceAll('\\{!Opportunity\\.Account\\}',opp.Account.Name)
							.replaceAll('\\{!Opportunity\\.ProductsOfInterest__c\\}',''+opp.ProductsOfInterest__c)
							.replaceAll('\\{!Lead\\.Business_Unit__c\\}',''+ld.Business_Unit__c);
						mail.setSubject(subject);
						String body = OPPORTUNITY_ASSIGNMENT_EMAIL_TEMPLATE.Body
							.replaceAll('\\{!Opportunity\\.OwnerFullName\\}',opp.Owner.Name)
							.replaceAll('\\{!Opportunity\\.Account\\}',opp.Account.Name)
							.replaceAll('\\{!Opportunity\\.CreatedBy\\}',opp.CreatedBy.Name)
							.replaceAll('\\{!Opportunity\\.Link\\}',opp.Owner.EnterpriseServerUrl__c+opp.Id);
						for(Schema.FieldSetMember fsm : Schema.SObjectType.Lead.fieldSets.Opportunity_Assignment.getFields()) {
							String value = ':\t'+ld.get(fsm.getFieldPath());
							if(value == ':\tnull') {
								value = ':';
							}
							body += '\n'+fsm.getLabel()+value;
						}
						mail.setPlainTextBody(body);
						messages.add(mail);
						tasks.add(new Task(
							ActivityDate = System.today(),
							Description = body,
							OwnerId = UserInfo.getUserId(),
							Subject = subject,
							Status = 'Sent',
							Type = 'Email',
							WhatId = opp.Id));
						
					}
				}
				for(Messaging.SendEmailResult ser : Messaging.sendEmail(messages,false)) {
					Task t = tasks.remove(0);
					Messaging.SingleEmailMessage mail = messages.remove(0);
					if(ser.isSuccess()) {
						tasks.add(t);
					}
					retval.get(ser.isSuccess()).add(mail);
					System.debug(mail);
					System.debug(ser.getErrors());
				}
				Database.insert(tasks,false);
			}
		}
		// an exception will be thrown when SendEmailToOpportunityTeam__c is not in the field set
		catch(Exception ex) {}
		return retval;
	}

	/**
	 * Called by the leadConvertWizardFuture method to send a failure notification to the lead development user if necessary.
	 * 
	 * @param leads
	 * @param errors
	 * @return a map of success and failed messages
	 */
	public static Map<Boolean,List<Messaging.SingleEmailMessage>> errorNotification(List<Lead> leads, List<String> errors) {
		Map<Boolean,List<Messaging.SingleEmailMessage>> retval = new Map<Boolean,List<Messaging.SingleEmailMessage>>{
						true=>new List<Messaging.SingleEmailMessage>(),
						false=>new List<Messaging.SingleEmailMessage>() };	  
		if(!errors.isEmpty() && LEAD_CONVERSION_ERROR_EMAIL_TEMPLATE != null) {
			String leadNames;
			Integer i = 0;
			for(Lead lead : leads) {			
				if(String.isBlank(leadNames)) {
					leadNames = lead.Name;
				}
				else if (i >= 10) {
					leadNames += ', ... [truncated]';
					break;
				}
				else {			  
					leadNames += ', ' + lead.Name;
				}
				i++;
			}
			if(String.isBlank(leadNames)) {
				leadNames = 'Unknown';
			}
			String errorMessages;
			i = 0;
			for(String error : errors) {
				if(String.isBlank(errorMessages)) {
					errorMessages = error;
				}
				else if (i >= 10) {
					errorMessages += '\n ... [truncated]';
					break;
				}
				else {			  
					errorMessages += '\n' + error;
				}
				i++;
			}		   
			Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
			mail.setToAddresses(new List<String>{UserInfo.getUserEmail()});
			mail.setSubject(LEAD_CONVERSION_ERROR_EMAIL_TEMPLATE.Subject);
			String body = LEAD_CONVERSION_ERROR_EMAIL_TEMPLATE.Body
				.replaceAll('\\{!Lead\\.Name\\}',leadNames)
				.replaceAll('\\{ERRORS\\}',errorMessages);
			mail.setPlainTextBody(body);
			for(Messaging.SendEmailResult ser : Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{mail},false)) {
				retval.get(ser.isSuccess()).add(mail);
			}
		}
		return retval;
	}

	/**
	 * Future method called to update the converted records.
	 *
	 * @param ids set of leads to update
	 * @param compareTime used to detect newly created accounts
	 */
	@future
	public static void leadConvertWizardFuture(final Set<Id> ids,Long compareTime) {
		List<Lead> leads;
		try {
			Map<Id,Account> accountMap = new Map<Id,Account>();
			Map<Id,Contact> contactMap = new Map<Id,Contact>();
			Map<Id,Opportunity> opportunityMap = new Map<Id,Opportunity>();
			leads = leadConvertWizardQueryLeads(ids);
			List<String> errors = new List<String>();
			leadConvertWizardFindRecords(leads,compareTime,accountMap,contactMap,opportunityMap);
			clearOpportunityTeam(opportunityMap.values());
			List<Opportunity> opps = new List<Opportunity>(opportunityMap.values());
			AbstractTrigger.booleanSettingMap.put(OpportunityTriggerBefore2.CLOSE_DATE_MOVE_SETTING,false);
			for(Database.UpsertResult ur : Database.upsert(opps,false)) {
				Opportunity opp = opps.remove(0);
				if(! ur.isSuccess()) {
					opportunityMap.remove(opp.Id);
					System.debug('Failed to upsert opportunity ' + opp + ': ' + ur.getErrors());
					errors.add('Failed to update opportunity ' + opp.id + ': ' + ur.getErrors());
				}
			}
			opportunityAssignmentNotification(leads);
			AbstractTrigger.booleanSettingMap.remove(OpportunityTriggerBefore2.CLOSE_DATE_MOVE_SETTING);
			List<Contact> contacts = new List<Contact>(contactMap.values());
			for(Database.UpsertResult ur : Database.upsert(contacts,false)) {
				Contact contact = contacts.remove(0);
				if(! ur.isSuccess()) {
					System.debug('Failed to upsert contact ' + contact + ': ' + ur.getErrors());
					errors.add('Failed to update contact ' + contact.id + ': ' + ur.getErrors());
				}
			}
			List<Account> accounts = new List<Account>(accountMap.values());
			for(Database.UpsertResult ur : Database.upsert(accounts,false)) {
				Account account = accounts.remove(0);
				if(! ur.isSuccess()) {
					System.debug('Failed to upsert account ' + account + ': ' + ur.getErrors());
					errors.add('Failed to update account ' + account.id + ': ' + ur.getErrors());			   
				}
			}
			if(!errors.isEmpty()) {
				errorNotification(leads, errors);
			}
		}
		catch(Exception ex) {
			List<String> errors = new List<String>{ex.getMessage()};
			errorNotification(leads, errors);
		}
	}

	/**
	 * The field portion query for specified leads.
	 */
	public static String leadConvertWizardQueryString {
		get {
			if(leadConvertWizardQueryString == null) {
				String query = 'select';
				String sepChar = ' ';
				Set<String> fieldPaths = new Set<String>{
					'Business_Unit__c',
					'ConvertedOpportunityId',
					'Name',
					'Super_Region__c',
					'ConvertedAccount.CreatedDate',
					'ConvertedContact.CreatedDate',
					'ConvertedOpportunityId',
					'ConvertedOpportunity.Account.Name',
					'ConvertedOpportunity.Owner.Contact_Id__c',
					'ConvertedOpportunity.Owner.Name',
					'ConvertedOpportunity.Owner.Email',
					'ConvertedOpportunity.Owner.EnterpriseServerUrl__c',
					'ConvertedOpportunity.CreatedBy.Name',
					'ConvertedOpportunity.ProductsOfInterest__c',
					'SendEmailToOpportunityTeam__c' };
				fieldPaths.addAll(leadConversionWizardFieldPaths);
				fieldPaths.addAll(opportunityAssignmentFieldPaths);
				for(String fieldPath : fieldPaths) {
					query += sepChar+fieldPath;
					sepChar = ',';
				}
				leadConvertWizardQueryString = query;
			}
			return leadConvertWizardQueryString;
		}
	}

	/**
	 * Method called to query the specified leads.
	 *
	 * @param ids set of leads to query
	 * @return list of leads
	 */
	public static List<Lead> leadConvertWizardQueryLeads(final Set<Id> ids) {
		return Database.query(leadConvertWizardQueryString+' from Lead where Id in :ids and IsConverted = true');
	}

	/**
	 * Method called to find the converted records to update.
	 *
	 * @param leads to update
	 * @param compareTime time to compare to
	 * @param accountMap to be loaded with accounts to update
	 * @param contactMap to be loaded with contacts to update
	 * @param opportunityMap to be loaded with opportunities to update
	 */
	public static void leadConvertWizardFindRecords(List<Lead> leads,Long compareTime,Map<Id,Account> accountMap,Map<Id,Contact> contactMap,Map<Id,Opportunity> opportunityMap) {
		for(Lead lead : leads) {
			// we copy a lead to avoid exceptions with fields not in the list
			Lead leadCopy = new Lead();
			for(String fieldPath : leadConversionWizardFieldPaths) {
				leadCopy.put(fieldPath,lead.get(fieldPath));
			}
			if(lead.ConvertedAccount != null && lead.ConvertedAccount.CreatedDate != null && compareTime <= lead.ConvertedAccount.CreatedDate.getTime()) {
				Account acc = new Account(Id=lead.ConvertedAccount.Id);
				if(lead.Desired_Account_Owner__c != null) {
					acc.OwnerId = lead.Desired_Account_Owner__c;
					accountMap.put(acc.Id,acc);
				}
			}
			if(lead.ConvertedContact != null && lead.ConvertedContact.CreatedDate != null && compareTime <= lead.ConvertedContact.CreatedDate.getTime()) {
				Contact con = new Contact(Id=lead.ConvertedContact.Id);
				if(lead.Desired_Contact_Owner__c != null) {
					con.OwnerId = lead.Desired_Contact_Owner__c;
					contactMap.put(con.Id,con);
				}
			}
			if(lead.ConvertedOpportunityId != null) {
				Opportunity opp = new Opportunity(Id=lead.ConvertedOpportunityId);
				// sorry this bit of code is not dynamic.  We could add a mapping object,
				// but that would be overkill at this time
				if(lead.Desired_Opportunity_CloseDate__c != null) {
					opp.CloseDate = lead.Desired_Opportunity_CloseDate__c;
					opportunityMap.put(opp.Id,opp);
				}
				if(lead.Desired_Opportunity_Owner__c != null) {
					opp.OwnerId = lead.Desired_Opportunity_Owner__c;
					opportunityMap.put(opp.Id,opp);
				}
				//determine the currency and total amount for the opportunity based on super region and business unit(s)
				if(lead.Super_Region__c != null && lead.Business_Unit__c != null) {
					Map<String,LeadConvertWizardOppDefaultAmount__c> oppDefaultMap = opportunityDefaultAmountMap.get(lead.Super_Region__c);
					if(oppDefaultMap != null) {
						Decimal totalAmount = 0;
						String currencyIsoCode = '';
						String[] businessUnits = lead.Business_Unit__c.split(';',0);
						for(String businessUnit: businessUnits) {
							LeadConvertWizardOppDefaultAmount__c oppDefault = oppDefaultMap.get(businessUnit);
							//this doesn't support a mix of different currencies for the same super region. this should be fine
							//  because IT controls the settings. if additional currencies are found for different business units
							//  in the same super region those defaults are ignored
							if(oppDefault != null && oppDefault.Amount__c != null && oppDefault.Currency__c != null) {
								if(String.IsBlank(currencyIsoCode) || oppDefault.Currency__c == currencyIsoCode) {
									currencyIsoCode = oppDefault.Currency__c;
									totalAmount = totalAmount + oppDefault.Amount__c;
								}
							}
						}
						if(totalAmount > 0) {
							opp.CurrencyIsoCode = currencyIsoCode;
							opp.Amount = totalAmount;
							opportunityMap.put(opp.Id,opp);
						}
					}
				}
				//set the default stage, forecast category, and probability for the opportunity based on super region
				if(lead.Super_Region__c != null) {
					LeadConvertWizardOppDefaultStage__c oppDefault = opportunityDefaultStageMap.get(lead.Super_Region__c);
					if(oppDefault != null) {
						if(oppDefault.Stage__c != null) {
							opp.StageName = oppDefault.Stage__c;
							opportunityMap.put(opp.Id,opp);
						}
						if(oppDefault.Probability__c != null) {
							opp.Probability = oppDefault.Probability__c;
							opportunityMap.put(opp.Id,opp);
						}
					}
				}
			}
		}
	}

	/**
	 * Wizard lead conversion.  We will use a future call here to avoid nesting the logic too deeply
	 * and help avoid governor limits.
	 *
	 * @return set of leads ids which used the wizard
	 */
	public Set<Id> leadConvertWizard() {
		Set<Id> ids = new Set<Id>();
		if(isUpdate) {
			DateTime currentTime = DateTime.now();
			for(Lead lead : newMap.values()) {
				if(lead.StandardConversion__c == false && Lead_GlobalManagement.GLM_RECORDTYPE_IDS.contains(lead.RecordTypeId)) {
					if(LeadTriggerBeforeGLM.toContact || LeadTriggerBeforeGLM.toOpportunity || (lead.IsConverted && oldMap.get(lead.Id).IsConverted == false)) {
						for(String fieldPath : leadConversionWizardFieldPaths) {
							if(lead.get(fieldPath) != null) {
								ids.add(lead.Id);
							}
						}
					}
				}
			}
			if(! ids.isEmpty()) {
				leadConvertWizardFuture(ids,currentTime.addMinutes(-5).getTime());
			}
		}
		return ids;
	}

//US17312   String npsaAsString(NonPrimaryShippingAddress__c npsa) {
//US17312	   return npsa.Account__c+'\n'
//US17312		   +npsa.ShippingAddress__c+'\n'
//US17312		   +npsa.ShippingCity__c+'\n'
//US17312		   +npsa.ShippingState__c+'\n'
//US17312		   +npsa.ShippingZipPostalCode__c+'\n'
//US17312		   +npsa.ShippingCountry__c;
//US17312   }

//US17312   /**
//US17312	* Trigger method to create NPSA on lead convert.  If there is already a matching NPSA
//US17312	* then simply map that to the newly created opportunity.
//US17312	*/
//US17312   public void createNPSA() {
//US17312	   if(isUpdate) {
//US17312		   Map<Id,String> npsaKeyByOpportunityId = new Map<Id,String>();
//US17312		   Map<String,NonPrimaryShippingAddress__c> npsaMap = new Map<String,NonPrimaryShippingAddress__c>();
//US17312		   Map<Id,String> npsaKeyByLeadId = new Map<Id,String>();
//US17312		   for(Lead lead : newMap.values()) {
//US17312			   if(Lead_GlobalManagement.GLM_RECORDTYPE_IDS.contains(lead.RecordTypeId)) {
//US17312				   User owner = userMap.get(lead.OwnerId);
//US17312				   if((owner != null && owner.IsPortalEnabled !=  true)||(owner == null && currentUser.IsPortalEnabled != true)) {
//US17312					   if(toAccountId != null || (lead.IsConverted && ! oldMap.get(lead.Id).IsConverted)) {
//US17312						   Id accountId = lead.ConvertedAccountId;
//US17312						   if(accountId == null) {
//US17312							   accountId = toAccountId;
//US17312						   }
//US17312						   if(accountId != null && (lead.Street != null || lead.City != null || lead.State != null || lead.Country != null || lead.PostalCode != null))
//US17312						   {
//US17312							   Id opportunityId = lead.ConvertedOpportunityId;
//US17312							   if(opportunityId == null) {
//US17312								   opportunityId = toOpportunityId;
//US17312							   }
//US17312							   if(opportunityId != null) {
//US17312								   NonPrimaryShippingAddress__c npsa = new NonPrimaryShippingAddress__c(
//US17312									   Account__c=accountId,
//US17312									   ShippingAddress__c=lead.Street,
//US17312									   ShippingCity__c=lead.City,
//US17312									   ShippingState__c=lead.State,
//US17312									   ShippingCountry__c=lead.Country,
//US17312									   ShippingZipPostalCode__c=lead.PostalCode);
//US17312								   String key = npsaAsString(npsa);
//US17312								   npsaMap.put(key,npsa);
//US17312								   npsaKeyByLeadId.put(lead.Id,key);
//US17312								   npsaKeyByOpportunityId.put(opportunityId,key);
//US17312							   }
//US17312						   }
//US17312					   }
//US17312				   }
//US17312			   }
//US17312		   }
//US17312		   if(! npsaMap.isEmpty()) {
//US17312			   // search for matching shipping addresses
//US17312			   Set<Id> accountIds = new Set<Id>();
//US17312			   Set<String> shippingAddresses = new Set<String>();
//US17312			   Set<String> shippingCities = new Set<String>();
//US17312			   Set<String> shippingStates = new Set<String>();
//US17312			   Set<String> shippingCountries = new Set<String>();
//US17312			   Set<String> shippingZipPostalCodes = new Set<String>();
//US17312			   for(NonPrimaryShippingAddress__c npsa : npsaMap.values()) {
//US17312				   accountIds.add(npsa.Account__c);
//US17312				   shippingAddresses.add(npsa.ShippingAddress__c);
//US17312				   shippingCities.add(npsa.ShippingCity__c);
//US17312				   shippingStates.add(npsa.ShippingState__c);
//US17312				   shippingCountries.add(npsa.ShippingCountry__c);
//US17312				   shippingZipPostalCodes.add(npsa.ShippingZipPostalCode__c);
//US17312			   }
//US17312			   // Unfortunately there is no good way to query for just the addresses
//US17312			   // we need.  In most cases this super set will not contain too many 
//US17312			   // extra values.
//US17312			   for(NonPrimaryShippingAddress__c npsa : [
//US17312				   select
//US17312					   Account__c,
//US17312					   ShippingAddress__c,
//US17312					   ShippingCity__c,
//US17312					   ShippingState__c,
//US17312					   ShippingCountry__c,
//US17312					   ShippingZipPostalCode__c,
//US17312					   ASIDST__c
//US17312				   from NonPrimaryShippingAddress__c
//US17312				   where Account__c in :accountIds
//US17312					   and ShippingAddress__c in :shippingAddresses
//US17312					   and ShippingCity__c in :shippingCities
//US17312					   and ShippingState__c in :shippingStates
//US17312					   and ShippingCountry__c in :shippingCountries
//US17312					   and ShippingZipPostalCode__c in :shippingZipPostalCodes ] )
//US17312			   {
//US17312				   String key = npsaAsString(npsa);
//US17312				   npsaMap.put(key,npsa);
//US17312			   }
//US17312			   // create a list of addresses we need to create
//US17312			   List<NonPrimaryShippingAddress__c> npsaList = new List<NonPrimaryShippingAddress__c>();
//US17312			   for(NonPrimaryShippingAddress__c npsa : npsaMap.values()) {
//US17312				   if(npsa.Id == null) {
//US17312					   npsaList.add(npsa);
//US17312				   }
//US17312			   }
//US17312			   // now update the non primary shipping addresses
//US17312			   Map<String,String> errorMap = new Map<String,String>();
//US17312			   if(! npsaList.isEmpty()) {
//US17312				   for(Database.SaveResult sr : Database.insert(npsaList,false)) {
//US17312					   NonPrimaryShippingAddress__c npsa = npsaList.remove(0);
//US17312					   String key = npsaAsString(npsa);
//US17312					   if(! sr.isSuccess()) {
//US17312						   errorMap.put(key,'Failed to create NonPrimaryShippingAddress__c: '+sr.getErrors());
//US17312					   }
//US17312				   }
//US17312			   }
//US17312			   // create a list of opportunities to update
//US17312			   npsaKeyByOpportunityId.remove(null);
//US17312			   if(! npsaKeyByOpportunityId.isEmpty()) {
//US17312				   List<Opportunity> opps = new List<Opportunity>();
//US17312				   for(Id opportunityId : npsaKeyByOpportunityId.keySet()) {
//US17312					   String key = npsaKeyByOpportunityId.get(opportunityId);
//US17312					   NonPrimaryShippingAddress__c npsa = npsaMap.get(key);
//US17312					   opps.add(new Opportunity(
//US17312						   Id=opportunityId,
//US17312						   ASIDST__c = npsa.ASIDST__c,
//US17312						   NonPrimaryShippingAddress__c = npsa.Id,
//US17312						   ShippingAddress__c = npsa.ShippingAddress__c,
//US17312						   ShippingCity__c = npsa.ShippingCity__c,
//US17312						   ShippingState__c = npsa.ShippingState__c,
//US17312						   ShippingZipPostalCode__c = npsa.ShippingZipPostalCode__c,
//US17312						   ShippingCountry__c = npsa.ShippingCountry__c));
//US17312				   }
//US17312				   for(Database.SaveResult sr : Database.update(opps,false)) {
//US17312					   Opportunity opp = opps.remove(0);
//US17312					   String key = npsaKeyByOpportunityId.get(opp.Id);
//US17312					   if(! sr.isSuccess()) {
//US17312						   errorMap.put(key,'Failed to update opportunity '+opp.Id+' : '+sr.getErrors());
//US17312					   }
//US17312				   }
//US17312			   }
//US17312			   // return errors
//US17312			   hasErrors = hasErrors || ! errorMap.isEmpty();
//US17312			   for(String leadId : npsaKeyByLeadId.keySet()) {
//US17312				   String e = errorMap.get(npsaKeyByLeadId.get(leadId));
//US17312				   if(e != null) {
//US17312					   newMap.get(leadId).addError(e);
//US17312				   }
//US17312			   }
//US17312		   }
//US17312	   }
//US17312   }

	/**
	 * This method is called from the Lead_After trigger to invoke all the methods
	 * of this class, to obsolete the need for individual after triggers.  The primary
	 * reason to place all the triggers in a class is so we control the order in which
	 * the triggers are invoked.
	 *
	 * @param xoldMap the immutable map of previous Lead objects as in Trigger.oldMap.
	 * @param xnewMap the immutable map of new Lead objects as in Trigger.newMap
	 */
	public static void processTrigger(Map<Id,Lead> xoldMap,Map<Id,Lead> xnewMap) {
		final LeadTriggerAfterGLM afterTrigger = new LeadTriggerAfterGLM(xoldMap,xnewMap);
		if(AbstractTrigger.isActive(LEAD_FOR_REPORT_SETTING,true)) {
			afterTrigger.insertLeadForReporting();
		}
		if(AbstractTrigger.isActive(INSERT_HISTORY_SETTING,true)) {
			afterTrigger.insertHistory();
		}
		if(AbstractTrigger.isActive(UPDATE_HISTORY_SETTING,true)) {
			afterTrigger.updateHistory();
		}
		if(AbstractTrigger.isActive(TOUCH_CAMPAIGN_MEMBERS_SETTING,true)) {
			afterTrigger.touchCampaignMembers();
		}
		if(AbstractTrigger.isActive(LEAD_CONVERT_WIZARD_SETTING,true)) {
			afterTrigger.leadConvertWizard();
		}
		if(AbstractTrigger.isActive(UPSERT_HISTORY_SETTING,true)) {
			afterTrigger.upsertLMH();
		}
//US17312	   if(LeadTriggerAfter.booleanSettingMap.get(CREATE_NPSA_SETTING) != false) {
//US17312		   afterTrigger.createNPSA();
//US17312	   }
	}
}