/**
 * OpportunityTriggerBefore.cls
 *
 * @version 2015-01-27
 * @author Bill Riemers <briemers@redhat.com>
 * 2015-01-27 - Depreciated
 * 2013-07-23 - Added assignClonedFromOpportunity method
 * 2013-07-18 - Replaced Primary_Business_Unit_New__c with PrimaryBusinessUnit__c
 *            - Removed setPOCApprovalFlags method
 * 2013-07-05 - added updatePOCStatus
 * 2013-05-16 - Added lookup for POC record type
 * 2013-04-30 - Added assignServicesRiskReview, and update to use new methods
 * 2013-02-15 - Update to backout submit order reasons when the nolonger apply
 * 2012-04-18 - Update for Security Model Redesign
 * Modified: Scott Coleman <scoleman@redhat.com>
 * 2013-08-09 - bug fix - added null check in updatePOCCloseComments()
 * 2013-07-24 - added updatePOCCloseComments()
 * 2013-07-23 - added updatePOCParentOppOwnerRole()
 * 2013-07-05 - updated setPOCApprovalFlags as primary business unit field is now single select
 * 2013-06-27 - No longer setting POC status to "Defined"
 * 2012-12-17 - Small update setPOCApprovalFlags to reset status upon cloning a POC
 * 2012-11-29 - Add method that sets approval flags for Proof of Concept opps
 */
public without sharing class OpportunityTriggerBefore /* depreciated extends AbstractTrigger */ {
//depreciated	/** BooleanSetting__c key to enable the assignClonedFromOpportunity trigger method. */
//depreciated	public static final String ASSIGN_CLONED_FROM_OPPORTUNITY_SETTING = 'Opp_Before.assignClonedFromOpportunity';
//depreciated	/** BooleanSetting__c key to enable the assignRecordType trigger method. */
//depreciated	public static final String ASSIGN_RECORD_TYPE_SETTING = 'Opp_Before.assignRecordType';
//depreciated	/** BooleanSetting__c key to enable the assignServicesRiskReview trigger method. */
//depreciated	public static final String ASSIGN_SERVICES_RISK_REVIEW_SETTING = 'Opp_Before.assignRiskReview';
//depreciated	/** BooleanSetting__c key to enable the updateStageName trigger method. */
//depreciated	public static final String UPDATE_STAGE_NAME_SETTING = 'Opp_Before.updateStageName';
//depreciated	/** BooleanSetting__c key to enable the assignLegacy trigger method. */
//depreciated	public static final String ASSIGN_LEGACY_SETTING = 'Opp_Before.assignLegacy';
//depreciated	/** BooleanSetting__c key to enable the updateRushOrder trigger method. */
//depreciated	public static final String UPDATE_RUSH_ORDER_SETTING = 'Opp_Before.updateRushOrder';
//depreciated	/** BooleanSetting__c key to enable the updatePOCStatus trigger method. */
//depreciated	public static final String UPDATE_POC_STATUS_SETTING = 'Opp_Before.updatePOCStatus';
//depreciated	/** BooleanSetting__c key to enable the updatePOCCloseComments trigger method. */
//depreciated	public static final String UPDATE_POC_CLOSE_COMMENTS_SETTING = 'Opp_Before.updatePOCCloseComments';	
//depreciated	/** BooleanSetting__c key to enable the updatePOCParentOppOwnerRole trigger method. */
//depreciated	public static final String UPDATE_POC_OWNER_ROLE = 'Opp_Before.updatePOCOwnerRole';	

//depreciated	public static final String PREPARE_PLV = 'Prepare';
//depreciated	public static final String ENGAGE_PLV = 'Engage';
//depreciated	public static final String QUALIFY_PLV = 'Qualify';
//depreciated	public static final String VALIDATE_PLV = 'Validate';
//depreciated	public static final String PROPOSE_PLV = 'Propose';
//depreciated	public static final String NEGOTIATE_PLV = 'Negotiate';
//depreciated	public static final String CLOSED_WON_PLV = 'Closed Won';
//depreciated	public static final String CLOSED_LOST_PLV = 'Closed Lost';
//depreciated	public static final String CLOSED_BOOKED_PLV = 'Closed Booked';
//depreciated	public static final Map<String,String> RENAMED_STAGENAME_MAP = new Map<String,String>{
//depreciated		'UNQUALIFIED' => PREPARE_PLV,
//depreciated		'QUALIFICATION AND ACCEPTANCE' => ENGAGE_PLV,
//depreciated		'DISCOVERY/VALUE PROPOSITION' => QUALIFY_PLV,
//depreciated		'DEVELOP PROPOSAL' => VALIDATE_PLV,
//depreciated		'PRESENT QUOTE' => PROPOSE_PLV,
//depreciated		'NEGOTIATION' => NEGOTIATE_PLV };
//depreciated	// Opportunity.POC_Status__c values
//depreciated	public static final String POC_STATUS_ENGAGED = 'Engaged'; 
//depreciated	public static final String POC_STATUS_ACCEPTED = 'Accepted';
//depreciated	public static final String POC_STATUS_CLOSED = 'Closed';

//depreciated	// Opportunity.Rush_Order_Reason__c values
//depreciated	public static final String RUSH_SLA_TIME_PERIOD='SLA time period';
//depreciated	public static final String RUSH_PRODUCT_EXCEPTION='Product Exception';
//depreciated	private final Map<Id,Opportunity> oldMap = new Map<Id,Opportunity>();
//depreciated	private final List<Opportunity> newList = new List<Opportunity>();

//depreciated	/** Lookup the POC record id. */
//depreciated	// to do: Once this is the same on all environments this can be changed to constant value
//depreciated	public static Id pocRecordTypeId {
//depreciated		get {
//depreciated			return RecordTypeLookup.getRecordTypeId('Proof of Concept','Opportunity');
//depreciated		}
//depreciated	}


//depreciated	public OpportunityTriggerBefore(Map<Id,Opportunity> xoldMap,List<Opportunity> xnewList) {
//depreciated		super(xoldMap,xnewList,null);
//depreciated		if(xoldMap != null) {
//depreciated			oldMap.putAll(xoldMap);
//depreciated		}
//depreciated		if(xnewList != null) {
//depreciated			newList.addAll(xnewList);
//depreciated		}
//depreciated	}

//depreciated	/**
//depreciated	 * Called to prevent the user from changing the value of Cloned_From_Opportunity__c
//depreciated	 * as much as practical.
//depreciated	 */
//depreciated	public void assignClonedFromOpportunity() {
//depreciated		// for now we'll by-pass this rule for channel load
//depreciated		if(AdminByPass__c.getInstance().IsChannelLoad__c != true) {
//depreciated			if(isUpdate) {
//depreciated				for(Opportunity opp : newList ) {
//depreciated					Opportunity oldOpp = oldMap.get(opp.Id);
//depreciated					if(oldOpp != null) {
//depreciated						opp.Cloned_From_Opportunity__c = oldOpp.Cloned_From_Opportunity__c;
//depreciated					}
//depreciated				}
//depreciated			}
//depreciated			else if(isInsert && newList.size() == 1 && newList[0].Cloned_From_Opportunity__c != null && newList[0].RecordTypeId != pocRecordTypeId) {
//depreciated				if(! HashIdControllerExtension.hasHashForId(newList[0].Cloned_From_Opportunity__c)) {
//depreciated					newList[0].Cloned_From_Opportunity__c.addError('You are not allowed to edit this field.');
//depreciated				}
//depreciated			}
//depreciated		}
//depreciated	}

//depreciated	/**
//depreciated	 * Assign the opportunity's RecordTypeId when the default value was used.
//depreciated	 */
//depreciated	public void assignRecordType() {
//depreciated		StringSetting__c defaultRecordTypeId = StringSetting__c.getInstance('Opportunity.DefaultRecordTypeId');
//depreciated		if(defaultRecordTypeId != null) {
//depreciated			List<Opportunity> oppList = new List<Opportunity>();
//depreciated			for(Opportunity opp : newList) {
//depreciated				if(opp.RecordTypeId == defaultRecordTypeId.Value__c) {
//depreciated					oppList.add(opp);
//depreciated				}
//depreciated			}
//depreciated			if(! oppList.isEmpty() ) {
//depreciated				// we only update record types if there is a DefaultRecordTypes__c record for this user
//depreciated				DefaultRecordTypes__c dfrt = DefaultRecordTypes__c.getInstance();
//depreciated				if(dfrt != null &&
//depreciated					(	dfrt.PreferredOpportunityRecordType__c != null
//depreciated						|| dfrt.SecondaryOpportunityRecordType__c != null) )
//depreciated				{
//depreciated					String recordTypeName = null;
//depreciated					// determine super region to use for %r remapping
//depreciated					String superRegion = currentUser.Region__c;
//depreciated					if((superRegion == null || superRegion == 'GLOBAL') && dfrt.GlobalAs__c != null) {
//depreciated						superRegion = dfrt.GlobalAs__c;
//depreciated					}
//depreciated					if(dfrt.PreferredOpportunityRecordType__c != null) {
//depreciated						// lookup the record type mapping assignments
//depreciated						Map<String,Set<String>> rtnMap = RecordTypeSelectController.getRecordTypeNameMap(currentUser,new Set<String>{'OPPORTUNITY','ACCOUNT'});
//depreciated						// set the record type for opportunities
//depreciated						String recordType = dfrt.PreferredOpportunityRecordType__c.replaceAll('%r',superRegion);
//depreciated						for(String n : rtnMap.get('OPPORTUNITY')) {
//depreciated							if(n == recordType) {
//depreciated								recordTypeName = n;
//depreciated							}
//depreciated						}
//depreciated					}
//depreciated					// if neccessary use the secondary opportunity record type
//depreciated					if (recordTypeName == null && dfrt.SecondaryOpportunityRecordType__c != null) {
//depreciated						recordTypeName = dfrt.SecondaryOpportunityRecordType__c.replaceAll('%r',superRegion);
//depreciated					}
//depreciated					if(recordTypeName != null) {
//depreciated						for(RecordType rt : [
//depreciated							select Id
//depreciated							from RecordType
//depreciated							where (Name = :recordTypeName 
//depreciated								or DeveloperName = :recordTypeName)
//depreciated								and SObjectType = 'Opportunity' limit 1] )
//depreciated						{
//depreciated							for(Opportunity opp : oppList) {
//depreciated								opp.RecordTypeId = rt.Id;
//depreciated							}
//depreciated						}
//depreciated					}
//depreciated				}
//depreciated				for(Opportunity opp : oppList) {
//depreciated					if(opp.RecordTypeId ==  defaultRecordTypeId.Value__c) {
//depreciated						opp.addError('Failed to map default opportunity RecordType');
//depreciated					}
//depreciated				}
//depreciated			}
//depreciated		}
//depreciated	}

//depreciated	/**
//depreciated	 * Called to update the Stage Name from the old naming convention to the new one.
//depreciated	 */
//depreciated	public void updateStageName() {
//depreciated		for(Opportunity opp : newList) {
//depreciated			if(opp.StageName != null) {
//depreciated				final String stageName = RENAMED_STAGENAME_MAP.get(opp.StageName.toUpperCase());
//depreciated				if(stageName != null) {
//depreciated					opp.StageName = stageName;
//depreciated				}
//depreciated			}
//depreciated		}
//depreciated	}

//depreciated	/**
//depreciated	 * Called to update the POC Status from ACCEPTED to ENGAGED.
//depreciated	 */
//depreciated	public void updatePOCStatus() {
//depreciated		for(Opportunity opp : newList) {
//depreciated			if(opp.POC_Status__c == POC_STATUS_ACCEPTED && opp.EngagementStartDate__c != null && opp.EngagementStartDate__c.daysBetween(System.today()) >= 0) {
//depreciated				opp.POC_Status__c = POC_STATUS_ENGAGED;
//depreciated			}
//depreciated		}
//depreciated	}

//depreciated	/**
//depreciated	 * Called to store the comments supplied during POC rejection in the Close Comments field. This is desired
//depreciated	 *  because in those cases where the POC is sent to a Closed status as a result of approval process rejection
//depreciated	 *  the user is not given an opportunity to supply the Close Comments.
//depreciated	 */
//depreciated	public void updatePOCCloseComments() {
//depreciated		if(isUpdate) {
//depreciated			Set<Id> rejectedPOCIds = new Set<Id>();
//depreciated			for(Opportunity opp : newList) {
//depreciated				Opportunity oldOpp = oldMap.get(opp.Id);
//depreciated				if(opp.RecordTypeId == pocRecordTypeId 
//depreciated						&& opp.POC_Status__c == POC_STATUS_CLOSED
//depreciated						&& opp.POC_Close_Reason__c != null
//depreciated						&& opp.POC_Close_Reason__c.startsWith('Rejected')
//depreciated						&& String.isBlank(opp.POC_Close_Comments__c)
//depreciated						&& oldOpp.POC_Status__c != POC_STATUS_CLOSED) {
//depreciated					rejectedPOCIds.add(opp.Id);
//depreciated				}			
//depreciated			}
//depreciated			if(!rejectedPOCIds.isEmpty()) {
//depreciated				List<ProcessInstance> approvals = [
//depreciated					SELECT 
//depreciated						Id,
//depreciated						TargetObjectId,
//depreciated						(SELECT 
//depreciated							Id, 
//depreciated							StepStatus, 
//depreciated							Comments 
//depreciated						FROM StepsAndWorkitems 
//depreciated						WHERE StepStatus = 'Rejected')
//depreciated					FROM ProcessInstance
//depreciated					WHERE TargetObjectId in :rejectedPOCIds
//depreciated					ORDER BY CreatedDate ASC];
//depreciated				if(!approvals.isEmpty()) {
//depreciated					Map<Id,String> rejectCommentMap = new Map<Id,String>();
//depreciated					for(ProcessInstance approval : approvals) {
//depreciated						for(ProcessInstanceHistory history : approval.StepsAndWorkitems) {
//depreciated							rejectCommentMap.put(approval.TargetObjectId, history.Comments);
//depreciated						}
//depreciated					}
//depreciated					if(!rejectCommentMap.isEmpty()) {
//depreciated						for(Opportunity opp : newList) {
//depreciated							if(rejectedPOCIds.contains(opp.Id) && rejectCommentMap.keySet().contains(opp.Id)) {
//depreciated								opp.POC_Close_Comments__c = rejectCommentMap.get(opp.Id);
//depreciated							}			
//depreciated						}
//depreciated					}
//depreciated				}
//depreciated			}
//depreciated		}
//depreciated	} 

//depreciated	/**
//depreciated	 * Maintains the value in POC_Parent_Opportunity_Owner_Role__c. Necessary because
//depreciated	 *	creation of a forumla field for the same purpose is blocked by the SFDC
//depreciated	 *	object relationship limit for Opportunity. We aren't updating the value
//depreciated	 *	when the User record changes, only when the POC is updated. This should be
//depreciated	 *	sufficient.
//depreciated	 */
//depreciated	public void updatePOCParentOppOwnerRole() {
//depreciated		Set<Id> parentIds = new Set<Id>();
//depreciated		for(Opportunity opp : newList) {
//depreciated			if(opp.RecordTypeId == pocRecordTypeId && opp.Cloned_From_Opportunity__c != null) {
//depreciated				parentIds.add(opp.Cloned_From_Opportunity__c);
//depreciated			}
//depreciated		}
//depreciated		if(!parentIds.isEmpty()) {
//depreciated			Map<Id, Opportunity> ownerRoleMap = new Map<Id, Opportunity>([
//depreciated				SELECT 
//depreciated					Id, 
//depreciated					Owner.UserRole.Name 
//depreciated				FROM Opportunity 
//depreciated				WHERE Id in :parentIds]);
//depreciated			for(Opportunity opp : newList) {
//depreciated				if(opp.RecordTypeId == pocRecordTypeId && opp.Cloned_From_Opportunity__c != null && ownerRoleMap.keySet().contains(opp.Cloned_From_Opportunity__c)) {
//depreciated					String roleName = ownerRoleMap.get(opp.Cloned_From_Opportunity__c).Owner.UserRole.Name;
//depreciated					if(opp.POC_Parent_Opportunity_Owner_Role__c != roleName) {
//depreciated						opp.POC_Parent_Opportunity_Owner_Role__c = roleName;
//depreciated					}
//depreciated				}
//depreciated			}
//depreciated		}	
//depreciated	}	

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

//depreciated	/**
//depreciated	 * Called to backout 
//depreciated	 *   Rush_Order__c, Rush_Order_Set_By_System__c, and Rush_Order_Reason__c
//depreciated	 * values when they are nolonger appropriate.
//depreciated	 */
//depreciated	public void updateRushOrder() {
//depreciated		DateTime timeToSLA = DateTime.now().addHours(48);
//depreciated		for(Opportunity opp : newList) {
//depreciated			Boolean rushOrder = (opp.Rush_Order__c == true);
//depreciated			Boolean setBySystem = (opp.Rush_Order_Set_By_System__c == true);
//depreciated			String rushOrderReason = opp.Rush_Order_Reason__c;
//depreciated			if (rushOrder) {
//depreciated				if(setBySystem && RUSH_SLA_TIME_PERIOD == opp.Rush_Order_Reason__c) {
//depreciated					// this is only a rush order if the ContractStartDate is sooner than the timeToSLA
//depreciated					rushOrder = (opp.ContractStartDate__c != null) && (timeToSLA > opp.ContractStartDate__c);
//depreciated				}
//depreciated				else if(setBySystem && RUSH_PRODUCT_EXCEPTION == opp.Rush_Order_Reason__c) {
//depreciated					// we need something that works for both managed and unmanaged products
//depreciated					rushOrder = (IsUpdate && opp.BigMachines__Line_Items__c == oldMap.get(opp.Id).BigMachines__Line_Items__c);
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
//depreciated				}
//depreciated				else {
//depreciated					// any other reason must have been set by the user
//depreciated					setBySystem = false;
//depreciated				}
//depreciated			}
//depreciated			// if rushOrder is not set, then clear the other fields as well
//depreciated			if(! rushOrder) {
//depreciated				rushOrderReason = null;
//depreciated				setBySystem = false;
//depreciated			}
//depreciated			// only assign if changed, as we do not want to trigger field history for a non-change
//depreciated			if(rushOrder != opp.Rush_Order__c) {
//depreciated				opp.Rush_Order__c = rushOrder;
//depreciated			}
//depreciated			// only assign if changed, as we do not want to trigger field history for a non-change
//depreciated			if(rushOrderReason != opp.Rush_Order_Reason__c) {
//depreciated				opp.Rush_Order_Reason__c = rushOrderReason;
//depreciated			}
//depreciated			// only assign if changed, as we do not want to trigger field history for a non-change
//depreciated			if(setBySystem != opp.Rush_Order_Set_By_System__c) {
//depreciated				opp.Rush_Order_Set_By_System__c = setBySystem;
//depreciated			}
//depreciated		}
//depreciated	}

//depreciated	/**
//depreciated	 * The global pricebook id.
//depreciated	 */
//depreciated	public String globalPricebookId {
//depreciated		get {
//depreciated			if (globalPricebookId == null) {
//depreciated				for(Pricebook2 globalPriceBook : [
//depreciated					SELECT Id 
//depreciated			 		FROM Pricebook2 
//depreciated					WHERE Name = 'Global Price Book' limit 1] )
//depreciated					
//depreciated				{
//depreciated					globalPriceBookId = globalPriceBook.Id;
//depreciated				}
//depreciated			}
//depreciated			return globalPricebookId;
//depreciated		}
//depreciated		set;
//depreciated	}

//depreciated	/**
//depreciated	 * Called to set Services_Risk_Review__c flag to be checked when fixed priced, 
//depreciated	 * and cleared when no longer fixed price.
//depreciated	 */
//depreciated	public void assignServicesRiskReview() {
//depreciated		if(isUpdate) {
//depreciated			for(Opportunity opp : newList) {
//depreciated				Opportunity oldOpp = oldMap.get(opp.Id);
//depreciated				if(opp.Services_Contract_Type__c != oldOpp.Services_Contract_Type__c) {
//depreciated					if(opp.Services_Risk_Review__c != true && opp.Services_Contract_Type__c == 'Fixed Price') {
//depreciated						opp.Services_Risk_Review__c = true;
//depreciated					}
//depreciated					else if(opp.Services_Risk_Review__c != false && oldOpp.Services_Contract_Type__c == 'Fixed Price') {
//depreciated						opp.Services_Risk_Review__c = false;
//depreciated					}
//depreciated				}
//depreciated			}
//depreciated		}
//depreciated	}

//depreciated	/**
//depreciated	 * This method is called from the Opportunity_Before trigger to invoke all the methods
//depreciated	 * of this class, to obsolete the need for individual before triggers.  The primary
//depreciated	 * reason to place all the triggers in a class is so we control the order in which
//depreciated	 * the triggers are invoked.
//depreciated	 *
//depreciated	 * @param xoldMap the immutable map of previous Opportunity objects as in Trigger.oldMap.
//depreciated	 * @param xnewList the list of new Opportunity objects as in Trigger.new
//depreciated	 */
//depreciated	public static void processTrigger(Map<Id,Opportunity> xoldMap,List<Opportunity> xnewList) {
//depreciated		final OpportunityTriggerBefore beforeTrigger = new OpportunityTriggerBefore(xoldMap,xnewList);
//depreciated		if(AbstractTrigger.isActive(ASSIGN_CLONED_FROM_OPPORTUNITY_SETTING,true)) {
//depreciated			beforeTrigger.assignClonedFromOpportunity();
//depreciated		}
//depreciated		if(AbstractTrigger.isActive(ASSIGN_RECORD_TYPE_SETTING,true)) {
//depreciated			beforeTrigger.assignRecordType();
//depreciated		}
//depreciated		if(AbstractTrigger.isActive(ASSIGN_SERVICES_RISK_REVIEW_SETTING,true)) {
//depreciated			beforeTrigger.assignServicesRiskReview();
//depreciated		}
//depreciated		if(AbstractTrigger.isActive(UPDATE_STAGE_NAME_SETTING,true)) {
//depreciated			beforeTrigger.updateStageName();
//depreciated		}
//depreciated		if(AbstractTrigger.isActive(ASSIGN_LEGACY_SETTING,true)) {
//depreciated			beforeTrigger.assignLegacy();
//depreciated		}
//depreciated		if(AbstractTrigger.isActive(UPDATE_RUSH_ORDER_SETTING,true)) {
//depreciated			beforeTrigger.updateRushOrder();
//depreciated		}
//depreciated		if(AbstractTrigger.isActive(UPDATE_POC_STATUS_SETTING,true)) {
//depreciated			beforeTrigger.updatePOCStatus();
//depreciated		}
//depreciated		if(AbstractTrigger.isActive(UPDATE_POC_CLOSE_COMMENTS_SETTING,true)) {
//depreciated			beforeTrigger.updatePOCCloseComments();
//depreciated		}
//depreciated		if(AbstractTrigger.isActive(UPDATE_POC_OWNER_ROLE,true)) {
//depreciated			beforeTrigger.updatePOCParentOppOwnerRole();
//depreciated		}		
//depreciated		AbstractTrigger.processTriggerComplete();
//depreciated	}
}