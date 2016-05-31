/**
 * OpportunityTriggerBefore2.cls
 * 
 * @version 2015-12-11
 * @author Bill Riemers <briemers@redhat.com>
 * 2015-12-11 - Make embedded a static variable so it can be over-written.
 * 2015-10-22 - Added the clearCreditCardInformation method.
 * 2015-08-07 - Added copyOnClone and backoutOpportunities methods.
 * 2015-05-12 - Added a trigger method to clear order status when reopening a closed opportunity
 * 2014-12-18 - Added the assign Opportunity Partners method
 * 2014-04-09 - change zero dollar order to zero value opportunity
 * 2014-03-21 - added refactored POC methods to use the same processInstance query.
 * 2014-03-17 - Renamed updatePOCCloseComments to updateRejectComments
 * 2014-03-14 - extended updatePOCCloseComments to also include $0 order logic
 * 2014-03-04 - Added the checkRequired method for zero dollar orders.
 * 2014-02-27 - Added assignShippingContact method for zero dollar orders.
 * 2014-01-17 - Replace the Region trigger with the assignRegions method.
 * 2013-11-24 - Changed updatePOCParentOppOwnerRole to updatePOCParentFields and added StageName update
 * 2013-11-24 - Reduced the number of queries by using a getter for the parent poc opportunities
 * 2013-08-08 - Renamed to OpportunityTriggerBefore2 to avoid release conflicts
 * 2013-08-08 - Added closeDateMoved method to replace existing triggers and validation rules
 * 2013-07-23 - Added assignClonedFromOpportunity method
 * 2013-07-18 - Replaced Primary_Business_Unit_New__c with PrimaryBusinessUnit__c
 * 2013-07-18 - Removed setPOCApprovalFlags method
 * 2013-07-05 - added updatePOCStatus
 * 2013-05-16 - Added lookup for POC record type
 * 2013-04-30 - Added assignServicesRiskReview, and update to use new methods
 * 2013-02-15 - Update to backout submit order reasons when the nolonger apply
 * 2012-04-18 - Update for Security Model Redesign
 * Modified: Scott Coleman <scoleman@redhat.com>
 * 2014-02-10 - Replace the ELQConvertedAmount trigger with convertELQAmount method.
 * 2013-10-11 - now allowing and handling the reparenting of POCs
 * 2013-08-09 - implemented protectEmbedded()
 * 2013-08-09 - bug fix - added null check in updatePOCCloseComments()
 * 2013-07-24 - added updatePOCCloseComments()
 * 2013-07-23 - added updatePOCParentOppOwnerRole()
 * 2013-07-05 - updated setPOCApprovalFlags as primary business unit field is now single select
 * 2013-06-27 - No longer setting POC status to "Defined"
 * 2012-12-17 - Small update setPOCApprovalFlags to reset status upon cloning a POC
 * 2012-11-29 - Add method that sets approval flags for Proof of Concept opps
 */
public without sharing class OpportunityTriggerBefore2 extends AbstractTrigger {
	public static final String LOCK_STRING = 'OpportunityTriggerAfter.Lock';
	/** BooleanSetting__c key to enable the assignClonedFromOpportunity trigger method. */
	public static final String ASSIGN_CLONED_FROM_OPPORTUNITY_SETTING = 'Opp_Before.assignClonedFromOpportunity';
	/** BooleanSetting__c key to enable the assignOpportunityPartners trigger method. */
	public static final String ASSIGN_OPPORTUNITY_PARTNERS_SETTING = 'Opp_Before.assignOppPartners';
	/** BooleanSetting__c key to enable the assignRecordType trigger method. */
	public static final String ASSIGN_RECORD_TYPE_SETTING = 'Opp_Before.assignRecordType';
	/** BooleanSetting__c key to enable the assignRegion trigger method. */
	public static final String ASSIGN_REGIONS_SETTING = 'Opp_Before.assignRegion';
	/** BooleanSetting__c key to enable the assign shipping contact trigger method. */
	public static final String ASSIGN_SHIPPING_CONTACT_SETTING = 'Opp_Before.assignShipToContact';
	/** BooleanSetting__c key to enable the assignServicesRiskReview trigger method. */
	public static final String ASSIGN_SERVICES_RISK_REVIEW_SETTING = 'Opp_Before.assignRiskReview';
	/** BooleanSetting__c key to enable the backoutOpportunities trigger method. */
	public static final String BACKOUT_OPPORTUNITIES_SETTING = 'Opp_Before.backoutOpportunities';
	/** BooleanSetting__c key to enable the copyOnClone trigger method. */
	public static final String COPY_ON_CLONE_SETTING = 'Opp_Before.copyOnClone';
	/** BooleanSetting__c key to enable the updateStageName trigger method. */
	public static final String UPDATE_STAGE_NAME_SETTING = 'Opp_Before.updateStageName';
	/** BooleanSetting__c key to enable the assignLegacy trigger method. */
	public static final String ASSIGN_LEGACY_SETTING = 'Opp_Before.assignLegacy';
	/** BooleanSetting__c key to enable the checkRequired trigger method. */
	public static final String CHECK_REQUIRED_SETTING = 'Opp_Before.checkRequired';
	/** BooleanSetting__c key to enable the clearOrderStatus trigger method. */
	public static final String CLEAR_ORDER_STATUS_SETTING = 'Opp_Before.clearOrderStatus';
	/** BooleanSetting__c key to enable the clearCreditCardInformation trigger method. */
	public static final String CLEAR_CREDIT_CARD_SETTING = 'Opp_Before.clearCreditCard';
	/** BooleanSetting__c key to enable the closeDateMoved trigger method. */
	public static final String CLOSE_DATE_MOVE_SETTING = 'Opp_Before.closeDateMoved';
	/** BooleanSetting__c key to enable the updateRushOrder trigger method. */
	public static final String UPDATE_RUSH_ORDER_SETTING = 'Opp_Before.updateRushOrder';
	/** BooleanSetting__c key to enable the updatePOCStatus trigger method. */
	public static final String UPDATE_POC_STATUS_SETTING = 'Opp_Before.updatePOCStatus';
	/** BooleanSetting__c key to enable the updateRejectComments trigger method. */
	public static final String UPDATE_REJECT_COMMENTS_SETTING = 'Opp_Before.updateRejectComments';
	/** BooleanSetting__c key to enable the updatePOCParentFields trigger method. */
	public static final String UPDATE_POC_PARENT_FIELDS = 'Opp_Before.updatePOCParentFields';
	/** BooleanSetting__c key to enable the protectEmbedded trigger method. */
	public static final String PROTECT_EMBEDDED_SETTING = 'Opp_Before.protectEmbedded';
	/** BooleanSetting__c key to enable the updateReparentedPOC trigger method. */
	public static final String UPDATE_REPARENTED_POC_SETTING = 'Opp_Before.updateReparentedPOC';
	/** BooleanSetting__c key to enable the convertELQAmount trigger method. */
	public static final String CONVERT_ELQ_AMOUNT_SETTING = 'Opp_Before.convertELQAmount';

	private static final Set<Integer> START_OF_QUARTER = new Set<Integer>{3,6,9,12};

	public static final String PREPARE_PLV = 'Prepare';
	public static final String PENDING_PLV = 'Pending';
	public static final String APPROVED_PLV = 'Approved';
	public static final String REJECTED_PLV = 'Rejected';
	public static final String RECALLED_PLV = 'Recalled';
	public static final String ENGAGE_PLV = 'Engage';
	public static final String QUALIFY_PLV = 'Qualify';
	public static final String VALIDATE_PLV = 'Validate';
	public static final String PROPOSE_PLV = 'Propose';
	public static final String NEGOTIATE_PLV = 'Negotiate';
	public static final String CLOSED_WON_PLV = 'Closed Won';
	public static final String CLOSED_LOST_PLV = 'Closed Lost';
	public static final String CLOSED_BOOKED_PLV = 'Closed Booked';
	public static final Map<String,String> RENAMED_STAGENAME_MAP = new Map<String,String>{
		'UNQUALIFIED' => PREPARE_PLV,
		'QUALIFICATION AND ACCEPTANCE' => ENGAGE_PLV,
		'DISCOVERY/VALUE PROPOSITION' => QUALIFY_PLV,
		'DEVELOP PROPOSAL' => VALIDATE_PLV,
		'PRESENT QUOTE' => PROPOSE_PLV,
		'NEGOTIATION' => NEGOTIATE_PLV };
	// Opportunity.POC_Status__c values
	public static final String POC_STATUS_ENGAGED = 'Engaged';
	public static final String POC_STATUS_ACCEPTED = 'Accepted';
	public static final String POC_STATUS_CLOSED = 'Closed';


	// Opportunity.Rush_Order_Reason__c values
	public static final String RUSH_SLA_TIME_PERIOD='SLA time period';
	public static final String RUSH_PRODUCT_EXCEPTION='Product Exception';
	private final Map<Id,Opportunity> oldMap = new Map<Id,Opportunity>();
	private final List<Opportunity> newList = new List<Opportunity>();

	/** Lookup the POC record id. */
	// to do: Once this is the same on all environments this can be changed to constant value
	public static Id pocRecordTypeId {
		get {
			return RecordTypeLookup.getRecordTypeId('Proof of Concept','Opportunity');
		}
	}

	public static Id zeroValueOpportunityRecordTypeId {
		get {
			return RecordTypeLookup.getRecordTypeId('Zero Value Opportunity','Opportunity');
		}
	}

	public static List<Schema.FieldSetMember> zeroValueOpportunityRequiredFields {
		get {
			if(zeroValueOpportunityRequiredFields == null) {
				zeroValueOpportunityRequiredFields = Schema.SObjectType.Opportunity.fieldSets.ZeroValueOpportunity_Required.getFields();
			}
			return zeroValueOpportunityRequiredFields;
		}
	}

	public OpportunityTriggerBefore2(Map<Id,Opportunity> xoldMap,List<Opportunity> xnewList) {
		super(xoldMap,xnewList,null);
		if(xoldMap != null) {
			oldMap.putAll(xoldMap);
		}
		if(xnewList != null) {
			newList.addAll(xnewList);
		}
	}

	public void checkRequired() {
		if(isUpdate) {
			List<Opportunity> oppList = new List<Opportunity>();
			for(Opportunity opp : newList) {
				if(opp.ApprovalStatus__c == PENDING_PLV) {
					Opportunity oldOpp = oldMap.get(opp.Id);
					if(oldOpp != null 
						&& oldOpp.ApprovalStatus__c != opp.ApprovalStatus__c
						&& opp.RecordTypeId == zeroValueOpportunityRecordTypeId)
					{
						String errorMessage = '';
						for(Schema.FieldSetMember fsm : zeroValueOpportunityRequiredFields) {
							System.debug(fsm.getLabel()+'='+opp.get(fsm.getFieldPath()));
							if(opp.get(fsm.getFieldPath()) == null) {
								errorMessage += fsm.getLabel()+' is a required field.\n';
							}
						}
						if(opp.OpportunityType__c == 'Bridge' && opp.ProductsWithoutContractNumberCount__c > 0) {
							errorMessage+='A Contract Number is required on all products.\n';
						}
						if(! opp.HasOpportunityLineItem) {
							errorMessage+='One or more products required.\n';
						}
						if(errorMessage != '') {
							opp.addError(errorMessage.trim());
							hasErrors=true;
						}
					}
				}
			}
		}
	}

	/**
	 * Called to prevent the user from changing the value of Cloned_From_Opportunity__c
	 * as much as practical.
	 */
	public void assignClonedFromOpportunity() {
		// for now we'll by-pass this rule for channel load
		if(AdminByPass__c.getInstance().IsChannelLoad__c != true) {
			if(isUpdate) {
				for(Opportunity opp : newList ) {
					Opportunity oldOpp = oldMap.get(opp.Id);
					if(oldOpp != null && opp.RecordTypeId != pocRecordTypeId) {
						opp.Cloned_From_Opportunity__c = oldOpp.Cloned_From_Opportunity__c;
					}
				}
			}
			else if(isInsert && newList.size() == 1 && newList[0].Cloned_From_Opportunity__c != null && newList[0].RecordTypeId != pocRecordTypeId) {
				if(! HashIdControllerExtension.hasHashForId(newList[0].Cloned_From_Opportunity__c)) {
					newList[0].Cloned_From_Opportunity__c.addError('You are not allowed to edit this field.');
				}
			}
		}
	}

	/**
	 * Assign the opportunity's RecordTypeId when the default value was used.
	 */
	public void assignRecordType() {
		StringSetting__c defaultRecordTypeId = StringSetting__c.getInstance('Opportunity.DefaultRecordTypeId');
		if(defaultRecordTypeId != null) {
			List<Opportunity> oppList = new List<Opportunity>();
			for(Opportunity opp : newList) {
				if(opp.RecordTypeId == defaultRecordTypeId.Value__c) {
					oppList.add(opp);
				}
			}
			if(! oppList.isEmpty() ) {
				// we only update record types if there is a DefaultRecordTypes__c record for this user
				DefaultRecordTypes__c dfrt = DefaultRecordTypes__c.getInstance();
				if(dfrt != null &&
 					(	dfrt.PreferredOpportunityRecordType__c != null
						|| dfrt.SecondaryOpportunityRecordType__c != null) )
				{
					String recordTypeName = null;
					// determine super region to use for %r remapping
					String superRegion = currentUser.Region__c;
					if((superRegion == null || superRegion == 'GLOBAL') && dfrt.GlobalAs__c != null) {
						superRegion = dfrt.GlobalAs__c;
					}
					if(dfrt.PreferredOpportunityRecordType__c != null) {
						// lookup the record type mapping assignments
						Map<String,Set<String>> rtnMap = RecordTypeSelectController.getRecordTypeNameMap(currentUser,new Set<String>{'OPPORTUNITY','ACCOUNT'});
						// set the record type for opportunities
						String recordType = dfrt.PreferredOpportunityRecordType__c.replaceAll('%r',superRegion);
						for(String n : rtnMap.get('OPPORTUNITY')) {
							if(n == recordType) {
								recordTypeName = n;
							}
						}
					}
					// if neccessary use the secondary opportunity record type
					if (recordTypeName == null && dfrt.SecondaryOpportunityRecordType__c != null) {
						recordTypeName = dfrt.SecondaryOpportunityRecordType__c.replaceAll('%r',superRegion);
					}
					if(recordTypeName != null) {
						for(RecordType rt : [
							select Id
							from RecordType
							where (Name = :recordTypeName
								or DeveloperName = :recordTypeName)
								and SObjectType = 'Opportunity' limit 1] )
						{
							for(Opportunity opp : oppList) {
								opp.RecordTypeId = rt.Id;
							}
						}
					}
				}
				for(Opportunity opp : oppList) {
					if(opp.RecordTypeId ==  defaultRecordTypeId.Value__c) {
						opp.addError('Failed to map default opportunity RecordType');
					}
				}
			}
		}
	}

	public static Set<Id> opportunitiesAutoAssignedShippingContact = new Set<Id>();

	/**
	 * Called to automatically assign the Shipping Contact field based on the Opportunity Contact Roles.
	 */
	public void assignShippingContact() {
		if(isUpdate) {
			Map<Id,Opportunity> oppMap = new Map<Id,Opportunity>();
			for(Opportunity opp : newList) {
				if(opp.ShippingContact__c == null && opp.RecordTypeId == zeroValueOpportunityRecordTypeId) {
					oppMap.put(opp.Id,opp);
				}
			}
			opportunitiesAutoAssignedShippingContact.clear();
			if(! oppMap.isEmpty()) {
				for(Opportunity opp : [
					select
						(	select ContactId
							from OpportunityContactRoles
							where Role = 'Shipping Contact'
								and Contact.LoginName__c != null
							order by CreatedDate
							limit 2 )
					from Opportunity
					where Id in :oppMap.keySet() ])
				{
					for(OpportunityContactRole contactRole : opp.OpportunityContactRoles) {
						if(contactRole.ContactId != oldMap.get(opp.Id).ShippingContact__c) {
							opportunitiesAutoAssignedShippingContact.add(opp.Id);
							oppMap.get(opp.Id).ShippingContact__c = contactRole.ContactId;
							break;
						}
					}
				}
			}
		}
	}

	/**
	 * Returns the start date of the respective quarter.
	 *
	 * @param dateInTheQuarter a date within the quarter
	 * @return the first day of the quarter
	 */
	public static Date firstDayOfQuarter(Date dateInTheQuarter) {
		Date retval = dateInTheQuarter;
		if(retval != null) {
			while(! START_OF_QUARTER.contains(retval.month())) {
				retval = retval.addMonths(-1);
			}
			retval = retval.toStartOfMonth();
		}
		return retval;
	}

	public static AdminByPass__c adminByPass {
		get {
			if(adminByPass == null) {
				adminByPass = AdminByPass__c.getInstance();
			}
			return adminByPass;
		}
		set;
	}

	/**
	 * Method to set the Close Date Moved when an opportunity is moved into a future
	 * quarter or back again.  Validate the Close Date Moved Reason when needed.
	 */
	public void closeDateMoved() {
		if(isUpdate) {
			Date currentDay = System.today();
			Date currentQuarter = firstDayOfQuarter(currentDay);
			// this simplified logic replaces the Checkclosedate trigger
			for(Opportunity opp : newList) {
				Date newCloseDate = opp.CloseDate;
				if(opp.RecordTypeId != pocRecordTypeId && opp.RecordTypeId != zeroValueOpportunityRecordTypeId) {
					// sales users cannot move open opportunities into the past
					if(newCloseDate < currentDay && opp.IsClosed != true && adminByPass.IsSalesUser__c == true) {
						opp.CloseDate.addError('Close date cannot be prior to today.');
						hasErrors = true;
					}
					else {
						// shift the date to the start of the quarter
						newCloseDate = firstDayOfQuarter(newCloseDate);
						if(newCloseDate != firstDayOfQuarter(oldMap.get(opp.Id).CloseDate)) {
							// clear the reason and details field if current quarter or past
							if(newCloseDate <= currentQuarter) {
								opp.Close_Date_Moved__c = false;
								opp.Close_Date_Moved_Reason__c = null;
								opp.Close_Date_Moved_Details__c = null;
							}
							else if(opp.Close_Date_Moved__c != true){ // always set the flag when moved to a future quarter
								opp.Close_Date_Moved__c = true;
								// this logic replaces the validateCloseMoveDate logic
								if(opp.Close_Date_Moved_Reason__c == null && adminByPass.IsChannelLoad__c != true) {
									opp.Close_Date_Moved_Reason__c.addError('The close date has been moved from the current quarter to a future quarter. Please fill out the Close Date Moved Reason field to specify why the change has occurred.');
									hasErrors = true;
								}
							}
						}
					}
				}
			}
		}
	}

	/**
	 * Called to update the Stage Name from the old naming convention to the new one.
	 */
	public void updateStageName() {
		for(Opportunity opp : newList) {
			String stageName = null;
			if(opp.IsClosed != true && opp.RecordTypeId == zeroValueOpportunityRecordTypeId) {
				stageName = opp.ApprovalStatus__c;
				if(stageName == null) {
					stageName = PREPARE_PLV;
				}
			}
			else if(opp.StageName != null) {
				stageName = RENAMED_STAGENAME_MAP.get(opp.StageName.toUpperCase());
			}
			if(stageName != null && stageName != opp.StageName) {
				opp.StageName = stageName;
			}
		}
	}

	/**
	 * Called to update the POC Status from ACCEPTED to ENGAGED.
	 */
	public void updatePOCStatus() {
		for(Opportunity opp : newList) {
			if(opp.POC_Status__c == POC_STATUS_ACCEPTED && opp.EngagementStartDate__c != null && opp.EngagementStartDate__c.daysBetween(System.today()) >= 0) {
				opp.POC_Status__c = POC_STATUS_ENGAGED;
			}
		}
	}

	/**
	 * Find the POC and $0 dollar opportunities that have been updated to an approval rejected state.
	 */
	@TestVisible
	private Set<Id> rejectOppIds {
		get {
			if(rejectOppIds == null) {
				rejectOppIds = rejectZeroValueOpportunityIds.clone();
				rejectOppIds.addAll(rejectPOCIds);
			}
			return rejectOppIds;
		}
		set;
	}

	/**
	 * Find the $0 dollar opportunities that have been updated to an approval rejected state.
	 */
	@TestVisible
	private Set<Id> rejectZeroValueOpportunityIds {
		get {
			if(rejectZeroValueOpportunityIds == null) {
				rejectZeroValueOpportunityIds = new Set<Id>();
				for(Opportunity opp : newList) {
					Opportunity oldOpp = oldMap.get(opp.Id);
					if(opp.RecordTypeId == zeroValueOpportunityRecordTypeId
						&& opp.ApprovalStatus__c != oldOpp.ApprovalStatus__c
						&& opp.ApprovalStatus__c == REJECTED_PLV )
					{
						rejectZeroValueOpportunityIds.add(opp.Id);
					}
				}
			}
			return rejectZeroValueOpportunityIds;
		}
		set;
	}

	/**
	 * Find the POC opportunities that have been updated to an approval rejected state.
	 */
	@TestVisible
	private Set<Id> rejectPOCIds {
		get {
			if(rejectPOCIds == null) {
				rejectPOCIds = new Set<Id>();
				for(Opportunity opp : newList) {
					Opportunity oldOpp = oldMap.get(opp.Id);
					if(opp.RecordTypeId == pocRecordTypeId
							&& String.isBlank(opp.POC_Close_Comments__c)
							&& opp.POC_Status__c == POC_STATUS_CLOSED
							&& opp.POC_Close_Reason__c != null
							&& opp.POC_Close_Reason__c.startsWith('Rejected')
							&& oldOpp.POC_Status__c != POC_STATUS_CLOSED)
					{
						rejectPOCIds.add(opp.Id);
					}
				}
			}
			return rejectPOCIds;
		}
		set;
	}

	@TestVisible
	private List<ProcessInstance> processInstances {
		get {
			if(processInstances == null) {
				processInstances = new List<ProcessInstance>();
				if(! rejectOppIds.isEmpty()) {
					processInstances.addAll([
						SELECT
							TargetObjectId,
							(	SELECT
									Comments
								FROM StepsAndWorkitems
								WHERE StepStatus = 'Rejected'
									AND ProcessInstance.TargetObjectId in :rejectOppIds
								ORDER BY CreatedDate desc
								LIMIT 1)
						FROM ProcessInstance
						WHERE TargetObjectId in :rejectOppIds
						ORDER BY CreatedDate ASC]);
				}
			}
			return processInstances;
		}
		set;
	}

	@TestVisible
	private Map<Id,Opportunity> oppMapClone {
		get {
			Map<Id,Opportunity> retval = oppMapClone;
			if(retval == null) {
				retval = new Map<Id,Opportunity>(newList);
			}
			return retval.clone();
		}
		set;
	}

	/**
	 * Called to store the comments supplied during POC rejection in the Close Comments field. This is desired
	 * because in those cases where the POC is sent to a Closed status as a result of approval process rejection
	 * the user is not given an opportunity to supply the Close Comments.
	 *
	 * This trigger also applies to $0 orders.
	 */
	public void updateRejectComments() {
		if(isUpdate) {
			for(Opportunity opp : newList) {
				if(! String.isBlank(opp.POC_Close_Comments__c)) {
					Opportunity oldOpp = oldMap.get(opp.Id);
					if(opp.RecordTypeId == zeroValueOpportunityRecordTypeId && opp.ApprovalStatus__c != REJECTED_PLV) {
						opp.POC_Close_Comments__c = '';
					}
				}
			}
			if(!rejectOppIds.isEmpty()) {
				Map<Id,Opportunity> oppMap = oppMapClone;
				oppMap.keySet().retainAll(rejectOppIds);
				for(ProcessInstance approval : processInstances) {
					for(ProcessInstanceHistory history : approval.StepsAndWorkitems) {
						if(! String.isBlank(history.Comments)) {
							Opportunity opp = oppMap.get(approval.TargetObjectId);
							if(opp != null) {
								opp.POC_Close_Comments__c = history.Comments;
							}
						}
					}
				}
				oppMap.keySet().retainAll(rejectZeroValueOpportunityIds);
				for(Opportunity opp : oppMap.values()) {
					if(String.isBlank(opp.POC_Close_Comments__c)) {
						opp.addError('Comments are required.');
						hasErrors = true;
					}
				}
			}
		}
	}

	public Map<Id,Opportunity> pocParentMap {
		get {
			if(pocParentMap == null) {
				pocParentMap = new Map<Id,Opportunity>();
				Set<Id> parentIds = new Set<Id>();
				for(Opportunity opp : newList) {
					if(opp.RecordTypeId == pocRecordTypeId && opp.Cloned_From_Opportunity__c != null) {
						parentIds.add(opp.Cloned_From_Opportunity__c);
					}
				}
				if(!parentIds.isEmpty()) {
					pocParentMap = new Map<Id, Opportunity>([
						SELECT
							AccountId,
							Country_of_Order__c,
							CurrencyIsoCode,
							Owner.UserRole.Name,
							Region__c,
							Region2__c,
							StageName,
							SubRegion__c
						FROM Opportunity
						WHERE Id in :parentIds]);
				}
			}
			return pocParentMap;
		}
		set;
	}

	/**
	 * Maintains the values in POC_Parent_Opportunity_Owner_Role__c and 
	 * POC_Parent_Stage__c.  We could have done a formula field for each of
	 * these using Cloned_From_Opportunity__r.Owner__r.UserRole.Name and 
	 * Cloned_From_Opportunity__r.StageName.  However, we need to trigger workflow
	 * rules from this update, and we avoid hitting SFDC's object relationship limit.
	 */
	public void updatePOCParentFields() {
		if(!pocParentMap.isEmpty()) {
			for(Opportunity opp : newList) {
				Opportunity parentOpp = pocParentMap.get(opp.Cloned_From_Opportunity__c);
				if(parentOpp != null) {
					if(parentOpp.Owner != null && parentOpp.Owner.UserRole != null) {
						String roleName = parentOpp.Owner.UserRole.Name;
						if(opp.POC_Parent_Opportunity_Owner_Role__c != roleName) {
							opp.POC_Parent_Opportunity_Owner_Role__c = roleName;
						}
					}
					String stageName = parentOpp.StageName;
					if(opp.POC_Parent_Stage__c != stageName) {
						opp.POC_Parent_Stage__c = stageName;
					}
				}
			}
		}
	}

	/**
	 * Updates POC fields when the POC is reparented to a different opp.
	 */
	public void updateReparentedPOC() {
		if(isUpdate) {
			List<Opportunity> reparentedPOCs = new List<Opportunity>();
			for(Opportunity opp : newList) {
				Opportunity oldOpp = oldMap.get(opp.Id);
				if(opp.RecordTypeId == pocRecordTypeId
					&& opp.Cloned_From_Opportunity__c != null
					&& opp.Cloned_From_Opportunity__c != oldOpp.Cloned_From_Opportunity__c)
				{
					reparentedPOCs.add(opp);
				}
			}
			for(Opportunity poc : reparentedPOCs) {
				Opportunity parentOpp = pocParentMap.get(poc.Cloned_From_Opportunity__c);
				if(parentOpp != null) {
					poc.AccountId = parentOpp.AccountId;
					poc.Country_of_Order__c = parentOpp.Country_of_Order__c;
					poc.CurrencyIsoCode = parentOpp.CurrencyIsoCode;
					poc.Region__c = parentOpp.Region__c;
					poc.Region2__c = parentOpp.Region2__c;
					poc.SubRegion__c = parentOpp.SubRegion__c;
				}
			}
		}
	}

//	private Map<Id,Opportunity> lookupOppMap {
//		get {
//			if(lookupOppMap == null) {
//				lookupOppMap = new Map<Id,Opportunity>();
//				if(isUpdate) {
//					Set<Id> oppIds = new Set<Id>();
//					for(Opportunity opp : newList) {
//						if(opp.Rush_Order__c == true &&
//							opp.Rush_Order_Set_By_System__c == true &&
//							RUSH_PRODUCT_EXCEPTION == opp.Rush_Order_Reason__c)
//						{
//							oppIds.add(opp.Id);
//						}
//					}
//					oppIds.remove(null);
//					if(! oppIds.isEmpty()) {
//						lookupOppMap.putAll( [
//							select
//								(select PricebookEntry.ProductCode from OpportunityLineItems)
//							from Opportunity
//							where Id in :oppIds ] );
//					}
//				}
//			}
//			return lookupOppMap;
//		}
//		set;
//	}

	/**
	 * Called to backout
	 *   Rush_Order__c, Rush_Order_Set_By_System__c, and Rush_Order_Reason__c
	 * values when they are nolonger appropriate.
	 */
	public void updateRushOrder() {
		DateTime timeToSLA = DateTime.now().addHours(48);
		for(Opportunity opp : newList) {
			Boolean rushOrder = (opp.Rush_Order__c == true);
			Boolean setBySystem = (opp.Rush_Order_Set_By_System__c == true);
			String rushOrderReason = opp.Rush_Order_Reason__c;
			if (rushOrder) {
				if(setBySystem && RUSH_SLA_TIME_PERIOD == opp.Rush_Order_Reason__c) {
					// this is only a rush order if the ContractStartDate is sooner than the timeToSLA
					rushOrder = (opp.ContractStartDate__c != null) && (timeToSLA > opp.ContractStartDate__c);
				}
				else if(setBySystem && RUSH_PRODUCT_EXCEPTION == opp.Rush_Order_Reason__c) {
					// we need something that works for both managed and unmanaged products
					rushOrder = (IsUpdate && opp.BigMachines__Line_Items__c == oldMap.get(opp.Id).BigMachines__Line_Items__c);
//					// this would be the way to do it if we only had to deal with unmanaged products
//					rushOrder = false;
//					// this reason only applies if one of the product codes is found in the RushOrderSKU table
//					Opportunity o = lookupOppMap.get(opp.Id);
//					if(o != null && o.OpportunityLineItems != null) {
//						for(OpportunityLineItem lineItem : o.OpportunityLineItems) {
//							RushOrderSKU__c sku = RushOrderSKU__c.getInstance(lineItem.PricebookEntry.ProductCode);
//							if(sku != null) {
//								rushOrder = true;
//								break;
//							}
//						}
//					}
				}
				else {
					// any other reason must have been set by the user
					setBySystem = false;
				}
			}
			// if rushOrder is not set, then clear the other fields as well
			if(! rushOrder) {
				rushOrderReason = null;
				setBySystem = false;
			}
			// only assign if changed, as we do not want to trigger field history for a non-change
			if(rushOrder != opp.Rush_Order__c) {
				opp.Rush_Order__c = rushOrder;
			}
			// only assign if changed, as we do not want to trigger field history for a non-change
			if(rushOrderReason != opp.Rush_Order_Reason__c) {
				opp.Rush_Order_Reason__c = rushOrderReason;
			}
			// only assign if changed, as we do not want to trigger field history for a non-change
			if(setBySystem != opp.Rush_Order_Set_By_System__c) {
				opp.Rush_Order_Set_By_System__c = setBySystem;
			}
		}
	}

	/**
	 * The global pricebook id.
	 */
	public String globalPricebookId {
		get {
			if (globalPricebookId == null) {
				for(Pricebook2 globalPriceBook : [
					SELECT Id
			 		FROM Pricebook2
					WHERE Name = 'Global Price Book' limit 1] )

				{
					globalPriceBookId = globalPriceBook.Id;
				}
			}
			return globalPricebookId;
		}
		set;
	}

	/**
	 * Called to set Services_Risk_Review__c flag to be checked when fixed priced,
	 * and cleared when no longer fixed price.
	 */
	public void assignServicesRiskReview() {
		if(isUpdate) {
			for(Opportunity opp : newList) {
				Opportunity oldOpp = oldMap.get(opp.Id);
				if(opp.Services_Contract_Type__c != oldOpp.Services_Contract_Type__c) {
					if(opp.Services_Risk_Review__c != true && opp.Services_Contract_Type__c == 'Fixed Price') {
						opp.Services_Risk_Review__c = true;
					}
					else if(opp.Services_Risk_Review__c != false && oldOpp.Services_Contract_Type__c == 'Fixed Price') {
						opp.Services_Risk_Review__c = false;
					}
				}
			}
		}
	}

	public static EmbeddedOverride__c embedded {
		get {
			if(embedded == null) {
				embedded = EmbeddedOverride__c.getInstance();
			}
			return embedded;
		}
		set;
	}

	/**
	 * Called to enforce rules around who can set the Embedded field manually
	 * and then to record that it was set manually to prevent the system from
	 * overwriting that selection in the future.
	 */
	public void protectEmbedded() {
		if(isInsert || IsUpdate) {
			for(Opportunity opp : newList) {
				Decimal embeddedOverridden = 0;
				Boolean oldEmbedded = false;
				if(isUpdate) {
					Opportunity oldOpp = oldMap.get(opp.Id);
					if(oldOpp != null) {
						if(oldOpp.EmbeddedOverridden__c != OpportunityLineItemTriggerBefore2.EMBEDDED_TRIGGER_KEY) {
							embeddedOverridden = oldOpp.EmbeddedOverridden__c;
						}
						oldEmbedded = oldOpp.Embedded__c;
					}
				}
				//check to see if Embedded has been set or updated
				if(opp.Embedded__c != oldEmbedded) {
					//to accept the change, we must either see an expected value that
					// indicates that Embedded is being automatically set by the system
					// OR the current user must be granted the privilege to manually
					// set Embedded
					if(opp.EmbeddedOverridden__c == OpportunityLineItemTriggerBefore2.EMBEDDED_TRIGGER_KEY) {
						embeddedOverridden = 0;
					}
					else if(embedded.OverrideAllowed__c) {
						embeddedOverridden = 1;
					}
					else {
						//setting these values isn't really necessary but aids testing
						if(isInsert) {
							opp.Embedded__c = false;
							embeddedOverridden = 0;
						}
						else if(isUpdate) {
							opp.Embedded__c = oldEmbedded;
						}
						opp.Embedded__c.addError('You do not have permission to set the Embedded field value.');
					}
				}
				if(opp.EmbeddedOverridden__c != embeddedOverridden) {
					opp.EmbeddedOverridden__c = embeddedOverridden;
				}
			}
		}
	}

	/**
	 * Assign the respective region values from the country of order.
	 */
	public void assignRegions() {
		if(! hasErrors) {
			Set<String> countries = new Set<String>();
			for(Opportunity opp : newList) {
				if (opp.Country_of_Order__c != null) {
					countries.add(opp.Country_of_Order__c.toUpperCase());
				}
			}

			//now get the countries for the region.	
			// populate the region, sub region and super region
			if (! countries.isEmpty()) {
				Map<String, Region__c> regionMap = new Map<String, Region__c>();
				Region__c[] regions= [
					select
						Country__c,
						Region__c,
						Sub_Region__c,
						Super_Region__c
					from Region__c
					where Country__c in :countries ];
				for(Region__c region: regions) {
					regionMap.put(region.Country__c.toUpperCase(),region);
				}

				for(Opportunity opp : newList) {
					//populate values in opportunity
					if(opp.Country_of_Order__c != null) {
						Region__c oppRegion = regionMap.get(opp.Country_of_Order__c.toUpperCase());
						if (oppRegion != null) {
							if (opp.Region__c != oppRegion.Region__c) {
								opp.Region__c = oppRegion.Region__c;
							}
							if (opp.SubRegion__c != oppRegion.Sub_Region__c) {
								opp.SubRegion__c = oppRegion.Sub_Region__c;
							}
							if (opp.Region_tmp__c != oppRegion.Region__c) {
								opp.Region_tmp__c = oppRegion.Region__c;
							}
							if(oppRegion.Super_Region__c == 'APAC' && opp.Region2__c != '1') {
								opp.Region2__c = '1';
							}
							else if(oppRegion.Super_Region__c == 'LATAM' && opp.Region2__c != '8') {
								opp.Region2__c = '8';
							}
							else if(oppRegion.Super_Region__c == 'EMEA' && opp.Region2__c != '4') {
								opp.Region2__c = '4';
							}
							else if(oppRegion.Super_Region__c == 'NA' && opp.Region2__c != '3') {
								opp.Region2__c = '3';
							}
						}
					}
				}
			}
		}
	}

	/** Dated currency conversion helper */
	@TestVisible private static final DatedCurrencyConversion dcc = new DatedCurrencyConversion();
	/** Non-USD currency ISO codes found in this set of opps */
	@TestVisible private static Set<String> currencyIsoCodes = new Set<String>();
	/** Close dates found in this set of opps */
	@TestVisible private static Set<Date> closeDates = new Set<Date>();

	/**
	 * Static map of relevant conversion rates
	 */
	@TestVisible 
	private static Map<String, Map<Date, Double>> conversionMap {
		get {
			if(conversionMap == null) {
				try {
					conversionMap = dcc.getConversionRateMap(currencyIsoCodes, closeDates);
				}
				catch ( Exception e ) {
					system.debug( 'Unable to create conversion map: iso codes: ' + currencyIsoCodes + ' closeDates: ' + closeDates );

					// shoot the dev team an email
					String subjectText = 'Opportunity ELQ Converted Amount Trigger has experienced an exception';
					String bodyText = 'Unable to create conversion map - User: ' + UserInfo.getName() + ' : ' + UserInfo.getUserId() 
									+ ', iso codes: ' + currencyIsoCodes 
									+ ', closeDates: ' + closeDates 
									+ '\n' + e.getMessage();
									
					dcc.notifyDevTeam( subjectText, bodyText );
				}
			}
			return conversionMap;
		}
		set;
	}

	/**
	 * converts the opportunity amount to USD and populates the field ELQ_USD_AMT__c
 	 * to allow for reporting in the Eloqua campaign module 
	 */
	public void convertELQAmount() {
		// if iso code and close date static sets aren't populated yet populate them
		if(currencyIsoCodes.isEmpty() && closeDates.isEmpty()) {
			for (Opportunity opp : newList)  {
				if(opp.CurrencyIsoCode != 'USD' && opp.Amount != null && opp.Amount != 0.0) {
					currencyIsoCodes.add( opp.currencyIsoCode );
					closeDates.add( opp.CloseDate );
				}
			}
		}

		// do USD conversions for ELQ
		for (Opportunity opp : newList) {
			try {
				// do not attempt to calculate a currency conversion for records 
				// that do not contain a value for amount
				if (opp.Amount == null || opp.Amount == 0) {
					opp.ELQ_USD_AMT__c = 0.0;
					continue;
				}

				// opportunities using USD as a currency do not need to be converted
				// populate the field ELQ_USD_AMT__c with the opportunity amount
				if (opp.currencyIsoCode == 'USD') {
					opp.ELQ_USD_AMT__c = opp.Amount;
					continue;
				}
					
				// opportunities using currencies other than USD need to their amounts converted
				Map<Date, Double> conversionRateMap = conversionMap.get(opp.CurrencyIsoCode);
				Double conversionRate = 0.0;

				// when the close date of an opportunity is in the future
				// use the max date conversion rate
				if (opp.closeDate >= dcc.maxStartDateMap.get(opp.CurrencyIsoCode)) {
					conversionRate = conversionRateMap.get(dcc.maxStartDateMap.get(opp.CurrencyIsoCode));  
				}
				else if (opp.closeDate <= dcc.minStartDate)
				{
					conversionRate = conversionRateMap.get(dcc.minStartDate);
				}
				else
				{
					conversionRate = conversionRateMap.get(opp.CloseDate);
				}

				// calculate the currency conversion
				opp.ELQ_USD_AMT__c = (opp.Amount / conversionRate);
			}
			catch (system.MathException sme)
			{
				opp.ELQ_USD_AMT__c = 0.0;
				opp.addError('Unable to locate a conversion rate for opportunity: [ ' + opp.id + ', ' + opp.CurrencyIsoCode + ', ' + opp.closeDate + ']');
			}
			catch (Exception e)
			{
				opp.ELQ_USD_AMT__c = 0.0;

				// shoot the dev team an email
				String subjectText = 'Opportunity ELQ Converted Amount Trigger has experienced an exception';
				String bodyText = 'Unable to create conversion map - User: ' + UserInfo.getName() + ' : ' + UserInfo.getUserId() 
							+ ', iso codes: ' + currencyIsoCodes 
							+ ', closeDates: ' + closeDates 
							+ '\n' + e.getMessage();
							
				dcc.notifyDevTeam( subjectText, bodyText );
			}
		}
	}

	public void assignOpportunityPartners() {
		if(isUpdate) {
			List<Opportunity_Partners__c> oppPartnersList = new List<Opportunity_Partners__c>();
			for(Opportunity opp : newList) {
				if(opp.RecordTypeId != pocRecordTypeId && opp.Opportunity_Partners__c == null) {
					oppPartnersList.add(new Opportunity_Partners__c(OpportunityId__c=opp.Id,Opportunity__c=opp.Id));
				}
			}
			if(!oppPartnersList.isEmpty()) {
				Database.insert(oppPartnersList,false);
				for(Opportunity opp : newList) {
					if(opp.Opportunity_Partners__c == null) {
						Opportunity_Partners__c oppPartners = oppPartnersList.remove(0);
						opp.Opportunity_Partners__c = oppPartners.Id;
					}
				}
			}
		}
	}

	/**
	 * Clears the order status and related fields on open opportunities.
	 */
	public void clearOrderStatus() {
		for(Opportunity opp : newList) {
			if(opp.IsClosed != true) {
				if( opp.Order_Status__c != null) {
					opp.Order_Status__c = null;
				}
				if(opp.Pending_OM_Review__c != false) {
					opp.Pending_OM_Review__c = false;
				}
				if(opp.OM_review_complete__c != false) {
					opp.OM_review_complete__c = false;
				}
			}
		}
	}

	/** Copy readonly lookup fields on the cloned opportunity record since 
	 * some fields are read only for user and those would not be copied by default.
	 * Refactored from Opportunity_Trigger_Handler.copyReadOnlyFieldsOnClonedOpportunity
	 */
	public void copyOnClone() {
		if(isInsert) {
			// set to hold all the parent opportunity from which opportunity records are being cloned.
			Set<Id> clonedOppIds = new Set<Id>();
			// iteration on all the opportunities records being created.
			for(Opportunity opportunity : newList) {
				// prepare the set of all parent opportunity ids.
				clonedOppIds.add(opportunity.Cloned_From_Opportunity__c);
			}

			if(! clonedOppIds.isEmpty()) {
				// query all the parent opportunity records while creating new opportunity records after cloning.
				Map<Id,Opportunity> oppMap = new Map<Id,Opportunity>( [
					Select Bill_To_Sales_Account__c,
						Bill_To_Account__c,
						Bill_To_Address__c,
						Bill_To_Contact__c,
						Entitle_To_Sales_Account__c,
						Entitle_To_Account__c,
						Entitle_To_Address__c,
						Entitle_To_Contact__c,
						Ship_To_Sales_Account__c,
						Ship_To_Account__c,
						Ship_To_Address__c,
						Ship_To_Contact__c,
						Sold_To_Sales_Account__c,
						Sold_To_Account__c,
						Sold_To_Address__c,
						Sold_To_Contact__c
					from Opportunity 
					where Id in :clonedOppIds]);
				// iteration on the opportunity being created after cloning.
				for(Opportunity opportunity : newList){
					Opportunity opp = oppMap.get(opportunity.Cloned_From_Opportunity__c);
					if(opp != null) {
						// set the lookup fields after getting lookup fields from the parent opportunity record.
						opportunity.Bill_To_Sales_Account__c = opp.Bill_To_Sales_Account__c;
						opportunity.Bill_To_Account__c = opp.Bill_To_Account__c;
						opportunity.Bill_To_Address__c = opp.Bill_To_Address__c;
						opportunity.Bill_To_Contact__c = opp.Bill_To_Contact__c;
						opportunity.Entitle_To_Sales_Account__c = opp.Entitle_To_Sales_Account__c;
						opportunity.Entitle_To_Account__c = opp.Entitle_To_Account__c;
						opportunity.Entitle_To_Address__c = opp.Entitle_To_Address__c;
						opportunity.Entitle_To_Contact__c = opp.Entitle_To_Contact__c;
						opportunity.Ship_To_Sales_Account__c = opp.Ship_To_Sales_Account__c;
						opportunity.Ship_To_Account__c = opp.Ship_To_Account__c;
						opportunity.Ship_To_Address__c = opp.Ship_To_Address__c;
						opportunity.Ship_To_Contact__c = opp.Ship_To_Contact__c;
						opportunity.Sold_To_Sales_Account__c = opp.Sold_To_Sales_Account__c;
						opportunity.Sold_To_Account__c = opp.Sold_To_Account__c;
						opportunity.Sold_To_Address__c = opp.Sold_To_Address__c;
						opportunity.Sold_To_Contact__c = opp.Sold_To_Contact__c;
					}
				}
			}
		}
	}

	public static Boolean needBookedOppProcessRecordTypeId = true;

	public static Id BOOKED_OPP_PROCESS_RECORDTYPE_ID {
		get {
			if(needBookedOppProcessRecordTypeId) {
				needBookedOppProcessRecordTypeId = false;
				BOOKED_OPP_PROCESS_RECORDTYPE_ID = RecordTypeLookup.getRecordTypeId('Booked Opp Process','Opportunity');
			}
			return BOOKED_OPP_PROCESS_RECORDTYPE_ID;
		}
		set;
	}
	
	// static set of Ids of opps that have already been backed out to prevent multiple updates
	public static Set<Id> backedOutOpps = new Set<ID>();

	/**
	 * Backout opportunies.  Refactored from Opportunity_Trigger_Handler.backOutOpportunity.
	 */
	public void backoutOpportunities() {
		if(isUpdate) {
			// this first part is originall from Opportunity_Trigger
			List<Opportunity> oppList = new List<Opportunity>();
			for(Opportunity opportunity : newList) {
				Opportunity oldOpportunity = oldMap.get(opportunity.Id);
				if(oldOpportunity != null) {
					if(opportunity.RecordTypeId != oldOpportunity.RecordTypeId) {
						opportunity.Previous_Record_Type__c = oldOpportunity.RecordTypeId;
					}
					if( opportunity.StageName == 'Negotiate' 
						&& ( oldOpportunity.StageName == 'Closed Won'
								|| oldOpportunity.StageName == 'Closed Booked') )
					{
						oppList.add(opportunity);
					}
				}
			}

			if(!oppList.isEmpty()){
				Boolean needRecordTypeId = true;
				Id bookedOppProcessRecordTypeId = null;
				List<Order_Tracking__c> orderTrackingRecords = new List<Order_Tracking__c>();

				for(Opportunity opportunity : oppList){
					if(!backedOutOpps.contains(opportunity.Id)) {

						//Reset opportunity fields
						opportunity.Order_Status__c = 'Reverted';
						opportunity.Pending_OM_Review__c = false;
						opportunity.OM_review_complete__c = false;
						opportunity.DateOrderSubmitted__c = null;

						//Reset opportunity record type (if found)
						if(opportunity.Previous_Record_Type__c != null && opportunity.RecordTypeId != null) {
							try {
								Id previousRecordTypeId = Id.valueOf(opportunity.Previous_Record_Type__c);
								if(opportunity.RecordTypeId == BOOKED_OPP_PROCESS_RECORDTYPE_ID) {
									opportunity.RecordTypeId = previousRecordTypeId;
								}
							}
							catch(Exception ex) {}
						}

						//Create Order Tracking Record
						Order_Tracking__c orderTrackingRecord = new Order_Tracking__c(
							Opportunity__c = opportunity.Id,
							Opportunity_Owner__c = opportunity.OwnerId,
							Opportunity_Stage__c = opportunity.StageName,
							Oracle_Order_Number__c = opportunity.OracleOrderNumber__c,
							Order_Status__c = opportunity.Order_Status__c,
							Submitted_By__c = userInfo.getUserId(),
							Submitted_Date__c = System.Now() );
						orderTrackingRecords.add(orderTrackingRecord);

						backedOutOpps.add(opportunity.Id);
					}
				}
				if(!orderTrackingRecords.isEmpty()) {
					Database.insert(orderTrackingRecords, false);
				}
			}
		}
	}

	/**
	 * Clear all credit card information when changing from an operating unit that does not require tokenization 
	 * to one that does require tokenization.
	 */
	public void clearCreditCardInformation() {
		if(isUpdate) {
			for(Opportunity opp : newList) {
				// check if there is anything to clear
				if( opp.Credit_Card_First_Name__c != null
					|| opp.Credit_Card_Last_Name__c != null
					|| opp.Credit_Card_Email__c != null
					|| opp.Credit_Card_Phone__c != null
					|| opp.Credit_Card_Address__c != null
					|| opp.Credit_Card_City__c != null
					|| opp.Credit_Card_State__c != null
					|| opp.Credit_Card_Country__c != null
					|| opp.Credit_Card_Zip__c != null
					|| opp.Credit_Card_Reference_Number__c != null
					|| opp.Credit_Card_Transaction_UUID__c != null
					|| opp.Credit_Card_Type__c != null
					|| opp.Credit_Card_Expiration__c != null
					|| opp.Credit_Card_Token__c != null
					|| opp.NameOnCard__c != null
					|| opp.CreditCardType__c != null
					|| opp.Credit_Card_Number__c != null
					|| opp.ExpirationDate__c != null
					|| opp.CC_SpecialInstructions__c != null )
				{
					Opportunity oldOpp = oldMap.get(opp.Id);
					// check to be sure the only relevant field that is being updated is operating unit
					if( oldOpp != null
						&& (opp.Operating_Unit__c != null || oldOpp.Operating_Unit__c != opp.Operating_Unit__c)
						&& oldOpp.Credit_Card_First_Name__c == opp.Credit_Card_First_Name__c
						&& oldOpp.Credit_Card_Last_Name__c == opp.Credit_Card_Last_Name__c
						&& oldOpp.Credit_Card_Email__c == opp.Credit_Card_Email__c
						&& oldOpp.Credit_Card_Phone__c == opp.Credit_Card_Phone__c
						&& oldOpp.Credit_Card_Address__c == opp.Credit_Card_Address__c
						&& oldOpp.Credit_Card_City__c == opp.Credit_Card_City__c
						&& oldOpp.Credit_Card_State__c == opp.Credit_Card_State__c
						&& oldOpp.Credit_Card_Country__c == opp.Credit_Card_Country__c
						&& oldOpp.Credit_Card_Zip__c == opp.Credit_Card_Zip__c
						&& oldOpp.Credit_Card_Reference_Number__c == opp.Credit_Card_Reference_Number__c
						&& oldOpp.Credit_Card_Transaction_UUID__c == opp.Credit_Card_Transaction_UUID__c
						&& oldOpp.Credit_Card_Type__c == opp.Credit_Card_Type__c
						&& oldOpp.Credit_Card_Expiration__c == opp.Credit_Card_Expiration__c
						&& oldOpp.Credit_Card_Token__c == opp.Credit_Card_Token__c
						&& oldOpp.NameOnCard__c == opp.NameOnCard__c
						&& oldOpp.CreditCardType__c == opp.CreditCardType__c
						&& oldOpp.Credit_Card_Number__c == opp.Credit_Card_Number__c
						&& oldOpp.ExpirationDate__c == opp.ExpirationDate__c
						&& oldOpp.CC_SpecialInstructions__c == opp.CC_SpecialInstructions__c )
					{
						Boolean wasTokenRequired = Opportunity_PaymentDetailsController.isTokenRequired(oldOpp.Operating_Unit__c);
						if(oldOpp.Credit_Card_Number__c != null) {
							wasTokenRequired = (oldOpp.Credit_Card_Token__c != null);
						}
						// check to see if a the token required value has changed
						if( wasTokenRequired != null 
							&& wasTokenRequired != Opportunity_PaymentDetailsController.isTokenRequired(opp.Operating_Unit__c) )
						{
							opp.Credit_Card_First_Name__c = null;
							opp.Credit_Card_Last_Name__c = null;
							opp.Credit_Card_Email__c = null;
							opp.Credit_Card_Phone__c = null;
							opp.Credit_Card_Address__c = null;
							opp.Credit_Card_City__c = null;
							opp.Credit_Card_State__c = null;
							opp.Credit_Card_Country__c = null;
							opp.Credit_Card_Zip__c = null;
							opp.Credit_Card_Reference_Number__c = null;
							opp.Credit_Card_Transaction_UUID__c = null;
							opp.Credit_Card_Type__c = null;
							opp.Credit_Card_Expiration__c = null;
							opp.Credit_Card_Token__c = null;
							opp.NameOnCard__c = null;
							opp.CreditCardType__c = null;
							opp.Credit_Card_Number__c = null;
							opp.ExpirationDate__c = null;
							opp.CC_SpecialInstructions__c = null;
						}
					}
				}
			}
		}
	}

	/**
	 * This method is called from the Opportunity_Before trigger to invoke all the methods
	 * of this class, to obsolete the need for individual before triggers.  The primary
	 * reason to place all the triggers in a class is so we control the order in which
	 * the triggers are invoked.
	 *
	 * @param xoldMap the immutable map of previous Opportunity objects as in Trigger.oldMap.
	 * @param xnewList the list of new Opportunity objects as in Trigger.new
	 */
	public static void processTrigger(Map<Id,Opportunity> xoldMap,List<Opportunity> xnewList) {
		if(ThreadLock.lock(LOCK_STRING)) {
			try {
				final OpportunityTriggerBefore2 beforeTrigger = new OpportunityTriggerBefore2(xoldMap,xnewList);
				if(AbstractTrigger.isActive(CLOSE_DATE_MOVE_SETTING,true)) {
					beforeTrigger.closeDateMoved();
				}
				if(AbstractTrigger.isActive(ASSIGN_CLONED_FROM_OPPORTUNITY_SETTING,true)) {
					beforeTrigger.assignClonedFromOpportunity();
				}
				if(AbstractTrigger.isActive(ASSIGN_RECORD_TYPE_SETTING,true)) {
					beforeTrigger.assignRecordType();
				}
				if(AbstractTrigger.isActive(ASSIGN_SERVICES_RISK_REVIEW_SETTING,true)) {
					beforeTrigger.assignServicesRiskReview();
				}
				if(AbstractTrigger.isActive(UPDATE_STAGE_NAME_SETTING,true)) {
					beforeTrigger.updateStageName();
				}
				if(AbstractTrigger.isActive(ASSIGN_LEGACY_SETTING,true)) {
					beforeTrigger.assignLegacy();
				}
				if(AbstractTrigger.isActive(ASSIGN_SHIPPING_CONTACT_SETTING,true)) {
					beforeTrigger.assignShippingContact();
				}
				if(AbstractTrigger.isActive(COPY_ON_CLONE_SETTING,true)) {
					beforeTrigger.copyOnClone();
				}
				if(AbstractTrigger.isActive(CHECK_REQUIRED_SETTING,true)) {
					beforeTrigger.checkRequired();
				}
				if(AbstractTrigger.isActive(UPDATE_RUSH_ORDER_SETTING,true)) {
					beforeTrigger.updateRushOrder();
				}
				if(AbstractTrigger.isActive(UPDATE_POC_STATUS_SETTING,true)) {
					beforeTrigger.updatePOCStatus();
				}
				if(AbstractTrigger.isActive(UPDATE_REJECT_COMMENTS_SETTING,true)) {
					beforeTrigger.updateRejectComments();
				}
				if(AbstractTrigger.isActive(UPDATE_POC_PARENT_FIELDS,true)) {
					beforeTrigger.updatePOCParentFields();
				}
				if(AbstractTrigger.isActive(PROTECT_EMBEDDED_SETTING,true)) {
					beforeTrigger.protectEmbedded();
				}
				if(AbstractTrigger.isActive(UPDATE_REPARENTED_POC_SETTING,true)) {
					beforeTrigger.updateReparentedPOC();
				}
				if(AbstractTrigger.isActive(ASSIGN_REGIONS_SETTING,true)) {
					beforeTrigger.assignRegions();
				}
				if(AbstractTrigger.isActive(CONVERT_ELQ_AMOUNT_SETTING,true)) {
					beforeTrigger.convertELQAmount();
				}
				if(AbstractTrigger.isActive(ASSIGN_OPPORTUNITY_PARTNERS_SETTING,true)) {
					beforeTrigger.assignOpportunityPartners();
				}
				if(AbstractTrigger.isActive(CLEAR_ORDER_STATUS_SETTING,true)) {
					beforeTrigger.clearOrderStatus();
				}
				if(AbstractTrigger.isActive(CLEAR_CREDIT_CARD_SETTING,true)) {
					beforeTrigger.clearCreditCardInformation();
				}
				if(AbstractTrigger.isActive(BACKOUT_OPPORTUNITIES_SETTING,true)) {
					beforeTrigger.backoutOpportunities();
				}
				AbstractTrigger.processTriggerComplete();
			}
			finally {
				ThreadLock.unlock(LOCK_STRING);
			}
		}
	}
}