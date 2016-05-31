/**
 * OpportunityRedirectControllerExtension.cls 
 * This is really just an opportunity controller extension used for viewing opportunities.
 * Originally this class was only used to redirect opportunity views...
 * 
 * @version 2015-05-11
 *
 * @author Bill Riemers <briemers@redhat.com>
 * 2015-05-11 - Update in progess
 * 2014-04-09 - change zero dollar order to zero value opportunity
 * 2014-03-04 - show zero dollar order errors
 * 2013-12-04 - Remove close lost warning message
 * 2013-11-22 - Add close lost warning message
 * 2013-11-13 - Switch to using POC_Enabled custom setting
 * 2013-06-24 - Changed the create POC Enabled to require an open opportunity
 * 2013-06-10 - Added redirect for proof of concepts
 * 2012-04-18 - Update for Security Model Redesign
 * Modified: Scott Coleman <scoleman@redhat.com>
 * 2015-04-23 - Exempt Zero ValUe Opportunity from financial partner requirement
 * 2015-02-06 - Comment out reference to rule 23.1
 * 2013-10-08 - Extended code for showing/hiding POC button to allow regional 
 *              differences in which profiles can see the button
 * 2013-07-15 - Implemented Opp Lock
 * 2013-02-15 - Added code for showing/hiding POC button
 * Anshul Kumar <ankumar@redhat.com>
 * 2104-11-04 - US58342 modified createPOCEnabled method. Added calls to rule 5 & 18.4 in OrderManagementControllerExtension. 
 */
public with sharing class OpportunityRedirectControllerExtension {
	public static final String NOOVERRIDE_PARAM = 'nooverride';
	public static final String RETURN_URL_PARAM = 'retURL';
	public static final String CREATE_POC_JOB_FUNCTIONS_SETTING = 'OpportunityView.POCJobFunctions';
	public static final String CREATE_POC_PROFILES_SETTING = 'OpportunityView.POCProfiles';
	public static final String APPROVED_PLV = 'Approved';
	public static final String CLOSED_WON_PLV = 'Closed Won';

	public static Boolean hasMessages(ApexPages.Severity severity,List<ApexPages.Message> messages) {
		Boolean retval = false;
		for(ApexPages.Message message : messages) {
			System.debug('hasMessages '+message);
			if (message.getSeverity() == severity) {
				retval = true;
				break;
			}
		}
		return retval;
	}

	public static Boolean hasMessages(ApexPages.Severity severity) {
		return hasMessages(severity,ApexPages.getMessages());
	}

	public static Boolean hasErrors() {
		return hasMessages(ApexPages.Severity.ERROR);
	}

	ApexPages.StandardController controller;
	public OpportunityRedirectControllerExtension(ApexPages.StandardController controller)
	{
		this.controller = controller;
	}

	public Boolean getHasErrors() {
		return hasErrors();
	}

	public Boolean financialPartnerRequired {
		get {
			if(financialPartnerRequired == null) {
				financialPartnerRequired = false;
				if(!isZeroValueOpportunity && Opportunity_ManagePartners.rootPartnerTypeId != null && Opportunity_ManagePartners.rootPartnerTierId != null) {
					try {
						financialPartnerRequired = Opportunity_ManagePartners.isFinancialPartnerRequired(controller.getId());
					}
					catch(Exception e) {
						ApexPages.addMessages(e);
					}
				}
			}
			return financialPartnerRequired;
		}
		set;
	}

	private transient Opportunity queriedOpp = null;

	@TestVisible
	Opportunity getQueriedOpp() {
		if(queriedOpp == null) {
			for(Opportunity opp : [
				select
					ApprovalStatus__c,
					IsLockedForSales__c,
					IsClosed,
					RecordTypeId,
					RecordType.Name,
					StageName
				from Opportunity
				where Id = : controller.getId()] )
			{
				queriedOpp = opp;
			}
		}
		return queriedOpp;
	}

	public User user {
		get {
			if(user == null) {
				user = [SELECT IsPortalEnabled, Job_Function__c, Profile.Name, Region__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
			}
			return user;
		}
		set;
	}

	public Boolean isPortalEnabled {
		get {
			return user.IsPortalEnabled;
		}
	}

//	  public Boolean hasOpenPOCs {
//		  get {
//			  if(hasOpenPOCs == null) {
//				  hasOpenPOCs = (1 == [
//					  select count()
//					  from Opportunity
//					  where RecordType.Name = 'Proof of Concept'
//						  and POC_Status__c != 'Closed'
//						  and Cloned_From_Opportunity__c = :controller.getId()
//					  limit 1]);
//			  }
//			  return hasOpenPOCs;
//		  }
//		  set; 
//	  }

	public Boolean isOppLocked {
		get {
			Boolean oppLocked = false;
			Opportunity opp = getQueriedOpp();
			if(opp != null) {
				AdminByPass__c bypass = AdminByPass__c.getInstance();
				if(bypass != null) {
					oppLocked = opp.IsLockedForSales__c && bypass.IsSalesUser__c;
				}
			}
			return oppLocked;
		}
	}

	/** 
	 * Return true if the current user job function or profile/region is allowed to create poc's.
	 *
	 * @return true if the user is allowed to create poc's.
	 */
	public Boolean createPOCEnabled {
		get {
			if(createPOCEnabled == null) {
				createPOCEnabled = false;
				POC_Enabled__c pocEnabled = POC_Enabled__c.getInstance();
				if(pocEnabled != null) {
					Opportunity opp = getQueriedOpp();
					if(opp != null && opp.IsClosed == false ) {
						createPOCEnabled = ( user.Region__c == 'APAC' && pocEnabled.APAC__c)
							|| (user.Region__c == 'EMEA' && pocEnabled.EMEA__c)
							|| (user.Region__c == 'LATAM' && pocEnabled.LATAM__c)
							|| (user.Region__c == 'NA' && pocEnabled.NA__c)
							|| (user.Region__c == 'GLOBAL' && pocEnabled.Global__c)
							|| ( (user.Job_Function__c != null)
							&& (('\n'+pocEnabled.Job_Functions__c+'\n').toLowerCase().indexof('\n'+user.Job_Function__c.toLowerCase()+'\n') >= 0) );
					}
				}
			}
			return createPOCEnabled;
		}
		set;
	}

	public static Id pocRecordTypeId {
		get {
			return RecordTypeLookup.getRecordTypeId('Proof of Concept','Opportunity');
		}
	}

	public static Id ZeroValueOpportunityRecordTypeId {
		get {
			return RecordTypeLookup.getRecordTypeId('Zero Value Opportunity','Opportunity');
		}
	}

	private Boolean needRecordTypeName = true;
	private String recordTypeName {
		get {
			if(needRecordTypeName) {
				needRecordTypeName = false;
				Opportunity opp = getQueriedOpp();
				if(opp != null && opp.RecordType != null) {
					recordTypeName = opp.RecordType.Name;
				}
			}
			return recordTypeName;
		}
		set;
	}

	public Boolean isProofOfConcept {
		get {
			if(isProofOfConcept == null) {
				isProofOfConcept = (recordTypeName == 'Proof of Concept');
			}
			return isProofOfConcept;
		}
		set;
	}

	public Boolean isZeroValueOpportunity {
		get {
			return (recordTypeName == 'Zero Value Opportunity');
		}
	}

	private static Boolean addZeroValueOpportunityError(Boolean showErrors,String message) {
		if(showErrors) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,message));
		}
		return true;
	}

	private transient Boolean hasZeroValueOpportunityErrors = null;

	public String getShowSumitForApprovalErrorsUrl() {
		PageReference retval = new PageReference(ApexPages.currentPage().getUrl());
		retval.getParameters().putAll(ApexPages.currentPage().getParameters());
		retval.getParameters().put('submitForApproval','1');
		return retval.getUrl();
	}

	public Boolean getHasZeroValueOpportunityErrors() {
		if(isZeroValueOpportunity && hasZeroValueOpportunityErrors == null) {
			hasZeroValueOpportunityErrors = false;
			Map<String, String> errorsMap = new Map<String, String>();
			Boolean showErrors = ApexPages.currentPage().getParameters().get('submitForApproval') == '1';
			List<Schema.FieldSetMember> ZeroValueOpportunityRequiredFields = Schema.SObjectType.Opportunity.fieldSets.ZeroValueOpportunity_Required.getFields();
			Map<String,String> fieldMap = new Map<String,String>{
				'StageName'=>null,
				'OpportunityType__c'=>null,
				'ProductsWithoutContractNumberCount__c'=>null,
				'HasOpportunityLineItem'=>null};
			String query = 'select StageName, OpportunityType__c, ProductsWithoutContractNumberCount__c, HasOpportunityLineItem';
			for(Schema.FieldSetMember fsm : ZeroValueOpportunityRequiredFields) {
				String fieldPath = fsm.getFieldPath();
				if(!fieldMap.containsKey(fieldPath)) {
					query+= ', '+fieldPath;
				}
				fieldMap.put(fieldPath,fsm.getLabel());
			}
			final Id oppId = controller.getId();
			for(Opportunity opp : (List<Opportunity>)Database.query(query+' from Opportunity where Id=:oppId')) {
				if(opp.StageName == 'Prepare' || opp.StageName == 'Reject') {
					for(String fieldPath : fieldMap.keySet()) {
						if(opp.get(fieldPath) == null) {
							//hasZeroValueOpportunityErrors = addZeroValueOpportunityError(showErrors,fieldMap.get(fieldPath)+' is a required field.');
							errorsMap.put(fieldPath, fieldMap.get(fieldPath) + ' is a required field.');
						}
					}
					for(Schema.FieldSetMember fsm : ZeroValueOpportunityRequiredFields){
						if(errorsMap.containsKey(fsm.getFieldPath())){
							hasZeroValueOpportunityErrors = addZeroValueOpportunityError(showErrors, errorsMap.get(fsm.getFieldPath()));
						}
					}
					
					if(!opp.HasOpportunityLineItem) {
						hasZeroValueOpportunityErrors = addZeroValueOpportunityError(showErrors,'One or more products required.');					   
						if(opp.OpportunityType__c == 'Bridge') {
							ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Bridge orders require a Contract Number for all products.'));					      
						}
					}
									      
					if(opp.HasOpportunityLineItem) {
						for(OpportunityLineItem lineItem : [Select Id, PricebookEntry.Name, Entitle_To_Account__c, Entitle_To_Address__c, Entitle_To_Contact__c, Entitle_To_Sales_Account__c, Contract_Numbers__c from OpportunityLineItem where OpportunityId =: oppId]){
							if(lineItem.Entitle_To_Account__c == null){
								hasZeroValueOpportunityErrors = addZeroValueOpportunityError(showErrors, 'Entitle-To Account is a required field for '+lineItem.PricebookEntry.Name + ' product');						   
							}
							if(lineItem.Entitle_To_Address__c == null){
								hasZeroValueOpportunityErrors = addZeroValueOpportunityError(showErrors, 'Entitle-To Address is a required field for '+lineItem.PricebookEntry.Name + ' product');
							}
							if(lineItem.Entitle_To_Contact__c == null){
								hasZeroValueOpportunityErrors = addZeroValueOpportunityError(showErrors, 'Entitle-To Contact is a required field for '+lineItem.PricebookEntry.Name + ' product');
							}
							if(lineItem.Entitle_To_Sales_Account__c == null){
								hasZeroValueOpportunityErrors = addZeroValueOpportunityError(showErrors, 'Entitle-To Sales Account is a required field for '+lineItem.PricebookEntry.Name + ' product');
							}
							if(opp.OpportunityType__c == 'Bridge' && lineItem.Contract_Numbers__c == null) {
								hasZeroValueOpportunityErrors = addZeroValueOpportunityError(showErrors, 'Bridge orders require a Contract Number for '+lineItem.PricebookEntry.Name + ' product');
							}
						}
					}
				}
			}
		}
		return (hasZeroValueOpportunityErrors == true);
	}

	public PageReference viewOpportunity() {
		PageReference retval = null;
		if(!isPortalEnabled) {
			if(isProofOfConcept) {
				PageReference r = Page.Opportunity_ProofOfConcept_View;
				r.getParameters().put('scontrolCaching','1');
				r.getParameters().put('id',controller.getId());
// I have no idea why getContent is called, but it disables the test method
//				r.getContent();
				r.setRedirect(true);
				retval = r;
			}
			else if(isZeroValueOpportunity) {
				hasZeroValueOpportunityErrors = null;
				getHasZeroValueOpportunityErrors();
			}
			else 
			{
				if(financialPartnerRequired) {
					if(ApexPages.currentPage().getParameters().get('nooverride') != '1') {
						Schema.DescribeSObjectResult d = PartnerStatus__c.SObjectType.getDescribe();
						Schema.DescribeSObjectResult d2 = OpportunityPartner__c.SObjectType.getDescribe();
						if(d.isQueryable() && d2.isQueryable() && d2.isUpdateable() && d2.isCreateable() && ApexPages.currentPage().getParameters().get(NOOVERRIDE_PARAM) != '1') {
							try {
								PageReference r = Page.Opportunity_ManagePartners;
								r.getParameters().put('scontrolCaching','1');
								r.getParameters().put('id',controller.getId());
// I have no idea why getContent is called, but it disables the test method
//								r.getContent();
								retval = r;
							}
							catch (Exception e) {}
						}
					}
					if(retval == null) {
						ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'A financial partner is required.  Please use the "Manage Partners" button to add one, or change the channel of this opportunity.'));   
					}
				}
				if(retval == null) {
					OrderManagementControllerExtension ext = new OrderManagementControllerExtension(controller);
					OrderManagementControllerExtension.reportErrorNumber = false;
					if(ext.opp != null && ext.opp.IsClosed == false && ext.opp.RecordType.Name != 'Proof of Concept') {
						ext.func_rule23();
						//ext.func_rule23_1();
						//added to accommodate changes requested in US58342  
						ext.func_rule5();
						ext.func_rule18_4();
						ext.func_rule38_1(FALSE);
						ext.func_rule38_2(FALSE);
//						if(hasOpenPOCs) {
//							ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING,System.Label.Opp_Close_Lost_Message));
//						}
					}
					if(isOppLocked) {
						ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING,System.Label.Opp_Lock_Message));
					}
				}
			}
		}
//		else {
//			retval = new PageReference('/'+controller.getId());
//			retval.getParameters().put(NOOVERRIDE_PARAM,'1');
//			retval.setRedirect(true);
//		}
		queriedOpp = null;
		return retval;
	}

	public PageReference editOpportunity()
	{
		PageReference retval = null;
		if((!isPortalEnabled) && isProofOfConcept) {
			PageReference r = Page.Opportunity_ProofOfConcept_Edit;
			r.getParameters().put('scontrolCaching','1');
			r.getParameters().put('id',controller.getId());
			if(!test.isRunningTest())
				r.getContent();
			r.setRedirect(true);
			retval = r;
		}
		if(retval == null && (!isPortalEnabled) && isOppLocked) {
			retval = new PageReference('/'+controller.getId());
			retval.getParameters().putAll(ApexPages.currentPage().getParameters());
			retval.setRedirect(true);
		}
		if(retval == null) {
			retval = new PageReference('/'+controller.getId()+'/e');
			retval.getParameters().putAll(ApexPages.currentPage().getParameters());
			retval.getParameters().put(NOOVERRIDE_PARAM,'1');
			retval.getParameters().put(RETURN_URL_PARAM,'/'+controller.getId());
			retval.setRedirect(true);
		}
		queriedOpp = null;
		return retval;
	}

	public Boolean getIsAccepted() {
		Opportunity opp = getQueriedOpp();
		return (opp != null && opp.ApprovalStatus__c == APPROVED_PLV);
	}

	/**
	 * Called to recall accepted apportunities back to an appropriate status.  Requires the "Zero Value Opportunity Un-Approval"
	 * approval process.
	 */
	public PageReference recallApproval() {
		PageReference retval = null;
		if(getIsAccepted()) {
			try {
				Approval.ProcessSubmitRequest submitRequest = new Approval.ProcessSubmitRequest();
				submitRequest.setObjectId(controller.getId());
				submitRequest.setNextApproverIds(new Id[] {UserInfo.getUserId()});
				// submit the Zero Value Opportunity into an approval process with the sole purpose of unlocking the record
				//  and setting the status to Recalled
				Approval.ProcessResult result = Approval.process(submitRequest);
				// get the work item Id
				List<Id> workItemIds = result.getNewWorkitemIds();
				// create a ProcessWorkitemRequest
				Approval.ProcessWorkitemRequest approveRequest = new Approval.ProcessWorkitemRequest();
				approveRequest.setComments('Successfully recalled');
				approveRequest.setAction('Approve');
				approveRequest.setWorkitemId(workItemIds[0]);
				// complete the approval
				Approval.ProcessResult result2 =  Approval.process(approveRequest);
				retval = controller.view();
				retval.setRedirect(true);
			}
			catch(Exception e) {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,e.getMessage()));
			}
		}
		queriedOpp = null;
		return retval;
	}
}