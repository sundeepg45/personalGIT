/**
 * This is a controller extension used for the StrategicPlanTab page.
 *
 * @version 2013-09-04
 * 
 * @author Scott Coleman <scoleman@redhat.com>
 * 2013-09-04 - Added getter for Attachments and action to save a PDF as an Attachment
 * 2013-04-22 - Added trend data capture and contribution tracking
 * 2013-04-04 - implemented approval proxy to deal with requirement to not lock record
 * 2013-04-02 - added approve and reject actions
 * 2013-04-01 - added submit action
 * 2013-03-21 - created
 * Bill C Riemers <briemers@redhat.com>
 * 2013-07-09 - Added getShowSummaryEnabled method
 * 2013-07-04 - Added showSummary method
 * 2013-05-23 - Automatically assign the account profile id.
 * 2013-05-09 - Updated to allow creation from account profiles
 * 2013-04-30 - Added comments, and a check that a comment is supplied when rejecting
 * 2013-04-22 - Updated field access and comments
 */
public with sharing virtual class StrategicPlanControllerExtension extends TabUIController.Extension {
	/** Name of a custom setting key for the report id to use. */
	public static final String SUMMARY_REPORT_ID_KEY = 'StrategicPlan_Summary.ReportId';
	public static final String TAB_NAME='StrategicPlan__c';
	private transient List<AccountTeamMember> accountTeamMembers = null;
	private transient List<StrategicPlan_ReviewHistory__c> reviewHistoryList = null;
	private transient Id approvalProxyId = null;
	private transient Id approvalWorkItemId = null;
	// to do: This is way too expensive to calculate to be transient 
	private transient List<PlanContributor> planContributors = null;
	private transient List<Attachment> attachments = null;

	/**
	 * Construct using a TabUIController.
	 * 
	 * @param tabUIController
	 */
	public StrategicPlanControllerExtension(TabUIController tabUIController) {
		super(TAB_NAME,tabUIController);
	}

	/**
	 * Construct using a standard controller.
	 * 
	 * @param stdController
	 */
	public StrategicPlanControllerExtension(ApexPages.StandardController stdController) {
		super(TAB_NAME);
	}

	/**
	 * Overload of the getRecord method to call getStrategicPlan.
	 *
	 * @return record
	 */
	public override SObject getRecord() {
		return getStrategicPlan();
	}

	/**
	 * Called to retrieve the strategic plan.
	 *
	 * @return record cast as a StrategicPlan__c
	 */
	public StrategicPlan__c getStrategicPlan() {
		StrategicPlan__c strategicPlan = (StrategicPlan__c)super.getRecord();
		Id id = getId();
		if(strategicPlan == null || strategicPlan.Id != id) {
			if(id == null) {
				Id accountId = tabUIController.getTabId('Account');
				Id accountProfileId = tabUIController.getTabId('Account_Profile__c');
				if(accountProfileId != null) {
					for(Account_Profile__c accountProfile : [
						select Account__c
						from Account_Profile__c
						where Id = :accountProfileId ] )
					{
						accountId = accountProfile.Account__c;
					}
				}
				else if(accountId != null) {
					List<Account_Profile__c> accountProfiles = [
						select Id
						from Account_Profile__c
						where Account__c = :accountId 
						limit 2 ];
					if(accountProfiles.size() == 1) {
						accountProfileId = accountProfiles[0].Id;
					}
				}
				strategicPlan = new StrategicPlan__c(
					Account__c = accountId,
					AccountProfile__c = accountProfileId);
			}
			else {
				strategicPlan = [
					select
						Account__r.Name,
						Account__r.Parent.Name,
						AccountBillingAddress__c,
						AccountClassification__c,
						AccountNumber__c,
						AccountProfile__r.Name,
						AccountType__c,
						AnnualITBudget__c,
						AnnualRevenue__c,
						CreatedBy.FirstName,
						CreatedBy.LastName,
						CreatedBy.Name,
						CreatedDate,
						FiscalYear__c,
						Industry__c,
						LastModifiedBy.FirstName,
						LastModifiedBy.LastName,
						LastModifiedBy.Name,
						LastModifiedDate,
						Name,
						NumberOfEmployees__c,
						Owner.Name,
						ParentAccount__c,
						PlanEndDate__c,
						PlanNumber__c,
						PlanStartDate__c,
						Status__c
					from StrategicPlan__c
					where Id = :id ];
			}
			setRecord(strategicPlan);
		}
		return strategicPlan;
	}

	/**
	 * Used to override the navigation back to the account on successful delete.
	 *
	 * @return page to navigate on successful delete
	 */
	public override PageReference navigateToOnDelete() {
		return new PageReference('/'+getStrategicPlan().Account__c);
	}

	/**
	 * Called to get a listing of account team members.
	 *
	 * @return accountTeamMembers list
	 */
	public List<AccountTeamMember> getAccountTeamMembers() {
		if (accountTeamMembers == null && getStrategicPlan() != null) {
			accountTeamMembers = [
				select
					TeamMemberRole,
					User.Id,
					User.Name
				from AccountTeamMember
				where AccountId = :getStrategicPlan().Account__c ];
		}
		return accountTeamMembers;
	}

	/**
	 * Called to retrieve the list of planContributors.
	 *
	 * @return planContributors list
	 */
	public List<PlanContributor> getPlanContributors() {
		// to do: Make this much more efficeint
		if(planContributors == null) {
			Id strategicPlanId = getId();
			if(strategicPlanId != null) {
				planContributors = new List<PlanContributor>();
				Set<String> trackedEventCodes = new Set<String>{'SPEdit','SPStrategyEdit','SPSolutionEdit'};
				Map<String,PlanContributor> userMap = new Map<String,PlanContributor>();
				Map<String,PlanContributor> roleMap = new Map<String,PlanContributor>();
				// limited to 10,000 records because we have lots of other work to do besides just this
				List<TrackingEventLog__c> trackedEvents = [
					select
						User__c,
						RelatedObjectId__c,
						Data2__c,
						TrackingEvent__r.Code__c,
						User__r.FirstName,
						User__r.LastName
					from TrackingEventLog__c
					where RelatedObjectId__c = :strategicPlanId
						and TrackingEvent__r.Code__c in :trackedEventCodes
					order by User__r.LastName, User__r.FirstName
					limit 10000 ];
				for(TrackingEventLog__c trackedEvent : trackedEvents) {
					String userName = User.sObjectType.getDescribe().label + ': ' + trackedEvent.User__r.FirstName + ' ' + trackedEvent.User__r.LastName;
					if(userMap.keySet().contains(userName)) {
						userMap.get(userName).editCount++;
					}
					else {
						userMap.put(userName,
							new PlanContributor(userName,1));
					}
					if(trackedEvent.Data2__c != null) {
						String roleName = Schema.sObjectType.AccountTeamMember.fields.TeamMemberRole.label + ': ' + trackedEvent.Data2__c;
						if(roleMap.keySet().contains(roleName)) {
							roleMap.get(roleName).editCount++;
						}
						else {
							roleMap.put(roleName,
								new PlanContributor(roleName,1));
						}
					}
				}
				List<PlanContributor> userList = userMap.values().clone();
				userList.sort();
				planContributors.addAll(userList);
				List<PlanContributor> roleList = roleMap.values().clone();
				roleList.sort();
				planContributors.addAll(roleList);
			}
		}
		return planContributors;
	}

	/**
	 * Get a list of Review History records related to this strategy.
	 * 
	 * @return reviewHistoryList
	 */
	public List<StrategicPlan_ReviewHistory__c> getReviewHistoryList() {
		if (reviewHistoryList == null) {
			reviewHistoryList = [
				select
					Id,
					Name,
					Action__c,
					ActionDate__c,
					Comments__c,
					User__c,
					UserName__c
				from StrategicPlan_ReviewHistory__c
				where StrategicPlan__c = :getId() 
				order by ActionDate__c DESC NULLS LAST ];
		}
		return reviewHistoryList;
	}

	/**
	 * Get a list of Attachment records associated with this plan.
	 * 
	 * @return attachments
	 */
	public List<Attachment> getAttachments() {
		if (attachments == null) {
			attachments = [
				select
					Id,
					Name,
					CreatedDate
				from Attachment
				where ParentId = :getId()
				order by CreatedDate DESC ];
		}
		return attachments;
	}

	/**
	 * Called to get the approvalProxyId.
	 *
	 * @return approvalProxyId
	 */
	public Id getApprovalProxyId() {
		if (approvalProxyId == null) {
			for(StrategicPlan_Review__c proxy : [
				select Id
				from StrategicPlan_Review__c
				where StrategicPlan__c = :getId()
				order by CreatedDate desc
				limit 1 ])
			{
				approvalProxyId = proxy.Id;
			}
		}
		return approvalProxyId; 
	}

	/**
	 * This just gives us a way to overload the currentUser information 
	 * when needed.
	 */
	public static User currentUser {
		get {
			if(currentUser == null) {
				currentUser = [
					select 
						Region__c
					from User
					where Id = : UserInfo.getUserId() ];
			}
			return currentUser;
		}
		set;
	}

	/** 
	 * Get the approvalWorkItemId value.
	 *
	 * @return approvalWorkItemId
	 */
	public Id getApprovalWorkItemId() {
		if (approvalWorkItemId == null) {
			Id proxyId = getApprovalProxyId();
			if (proxyId != null) {
				approvalWorkItemId = ApprovalUtil.getApprovalWorkItemId(
					currentUser.Id,
					proxyId);
			}
		}
		return approvalWorkItemId;
	}

	/**
	 * Cancel the Strategic Plan Edit
	 * 
	 * @return the retURL page reference
	 */
	public PageReference cancelStrategicPlan() {
		cancelRecord();
		return returnFromPage();
	} 

	/**
	 * Save the Strategic Plan
	 * 
	 * @return value returned by saveRecord()
	 */
	public PageReference saveStrategicPlan() {
		PageReference retval = saveRecord();
		List<String> eventData = getEventData();
		logEvent('SPEdit',getId(),eventData[0],eventData[1],eventData[2]);
		return retval;
	} 

	/**
	 * Sumbit the Strategic Plan for approval
	 *
	 * @return null
	 */
	public PageReference submitStrategicPlan() {
		Id id = getId();
		if(id != null) {
			system.savepoint sp = Database.setSavepoint();
			try {
				reviewHistory.Action__c = 'Submit';
				insert reviewHistory;
				update new StrategicPlan__c(Id=id,Status__c='Submitted');
				Id proxyId = insertApprovalProxy();
				Approval.ProcessSubmitRequest approvalRequest = new Approval.ProcessSubmitRequest();
				approvalRequest.setComments(system.label.StrategicPlan_SubmittingForManagement);
				approvalRequest.setObjectId(proxyId);
				Approval.ProcessResult result = Approval.process(approvalRequest);
				if(result.isSuccess()) {
					setRecord(null);
					sp = null;
				}
			}
			catch(Exception e) {
				if(e.getMessage().contains('Manager undefined')) {
					ApexPages.addMessage(
						new ApexPages.Message(
							ApexPages.Severity.ERROR,
							system.label.StrategicPlan_NoManager));
				}
				else {
					ApexPages.addMessages(e);
				}
			}
			finally {
				if(sp != null) {
					Database.rollback(sp);
				}
			}
		}
		return null;
	}

	/**
	 * Approve the Strategic Plan
	 *
	 * @return null
	 */
	public PageReference approveStrategicPlan() {
		Id id = getId();
		if(id != null) {
			system.savepoint sp = Database.setSavepoint();
			Id workItemId = getApprovalWorkItemId();
			try {
				reviewHistory.Action__c = 'Approve';
				system.Debug('review comments: ' + reviewHistory.Comments__c);
				insert reviewHistory;
				update new StrategicPlan__c(Id=id,Status__c='Approved');
				TrendData.captureTrendData('Strategic Plan Review','StrategicPlan__c',id);
				Approval.ProcessResult result = ApprovalUtil.processWorkitemRequest(workItemId,'Approve',reviewHistory.Comments__c);
				if(result.isSuccess()) {
					deleteApprovalProxy();
					setRecord(null);
					sp = null;
					approvalWorkItemId = null;
				}
				else {
					for(Database.Error error : result.getErrors()) {
						system.debug(error.getMessage());
					}
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Approval failed.'));
				}
			}
			catch(Exception e) {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, system.label.StrategicPlan_ApprovalFailed));
			}
			finally {
				if(sp != null) {
					Database.rollback(sp);
				}
			}
		}
		return null;
	}

	/**
	 * Reject the Strategic Plan
	 *
	 * @return null
	 */
	public PageReference rejectStrategicPlan() {
		PageReference retval = null;
		Id id = getId();
		if(id != null) {
			Id workItemId = getApprovalWorkItemId();
			system.savepoint sp = Database.setSavepoint();
			try {
				reviewHistory.Action__c = 'Reject';
				insert reviewHistory;
				update new StrategicPlan__c(Id=id,Status__c='Draft');
				TrendData.captureTrendData('Strategic Plan Review','StrategicPlan__c',id);
				Approval.ProcessResult result = ApprovalUtil.processWorkitemRequest(workItemId,'Reject',reviewHistory.Comments__c);
				if(result.isSuccess()) {
					deleteApprovalProxy();
					setRecord(null);
					sp = null;
					approvalWorkItemId = null;
				}
				else {
					for(Database.Error error : result.getErrors()) {
						system.debug(error.getMessage());
					}
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Rejection failed.'));
				}
			}
			catch(Exception e) {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Rejection failed. Approval request may have already been processed.'));
			}
			finally {
				if(sp != null) {
					Database.rollback(sp);
				}
			}
		}
		return null;
	}

	protected Id insertApprovalProxy() {
		StrategicPlan_Review__c proxy = new StrategicPlan_Review__c(StrategicPlan__c=getId());
		insert proxy;
		approvalProxyId = proxy.id;
		return approvalProxyId;
	}

	protected void deleteApprovalProxy() {
		Database.delete([
			select Id
			from StrategicPlan_Review__c
			where StrategicPlan__c = :getId() ], false);
	}

	public StrategicPlan_ReviewHistory__c reviewHistory {
		get {
			Id id = getId();
			if(reviewHistory == null || reviewHistory.Id != null || reviewHistory.StrategicPlan__c != id) {
				reviewHistory = new StrategicPlan_ReviewHistory__c(
					StrategicPlan__c=id,
					User__c = currentUser.Id);
			}
			return reviewHistory;
		}
		set;
	}

	protected List<String> getEventData() {
		//need to grab plan name, current user's account team role (if any), and current user's super region
		List<String> eventData = new List<String>();
		//plan name
		StrategicPlan__c strategicPlan = getStrategicPlan();
		eventData.add(strategicPlan.Name);
		//account team role
		List<AccountTeamMember> accountTeamMembers = getAccountTeamMembers();
		String accountTeamRole;
		for(AccountTeamMember accountTeamMember : accountTeamMembers) {
			if(accountTeamMember.UserId == currentUser.Id) {
				accountTeamRole = accountTeamMember.TeamMemberRole;
				break;
			}
		}
		eventData.add(accountTeamRole);
		//user super region
		eventData.add(currentUser.Region__c);
		return eventData;
	}

	/**
	 * Called to switch to the new Action's tab.
	 *
	 * @return null
	 */
	public PageReference newAction() {
		tabUIController.sharedParams.put('StrategicPlan_Action__r.Subject__c','Strategic Plan');
		tabUIController.activeTab = 'StrategicPlan_Action__c';
		tabUIController.setTabId('StrategicPlan_Action__c',null);
		tabUIController.tabMode.put('StrategicPlan_Action__c','new');
		return null;
	}

	/**
	 * Check if we have the custom setting allowing us to use the showSummary method.
	 *
	 * @return true if the button should be shown
	 */
	public Boolean getShowSummaryEnabled() {
		StringSetting__c reportIdSetting = StringSetting__c.getInstance(SUMMARY_REPORT_ID_KEY);
		return (reportIdSetting != null && reportIdSetting.Value__c != null);
	}

	/**
	 * Open a summary report for this strategic plan.
	 *
	 * @return reference to the summary report.
	 */
	public PageReference showSummary() {
		Id id = getId();
		PageReference retval = null;
		StringSetting__c reportIdSetting = StringSetting__c.getInstance(SUMMARY_REPORT_ID_KEY);
		if(id != null && reportIdSetting != null && reportIdSetting.Value__c != null) {
			retval = new PageReference('/'+reportIdSetting.Value__c);
			retval.getParameters().put('pv0',(''+id).substring(0,15));
			retval.setRedirect(true);
		}
		return retval;
	}

	/**
	 * Attach a PDF snapshot of the plan details to the plan.
	 *
	 * @return reference to refresh the current page
	 */
	public PageReference attachPlanPDF() {
		PageReference pdf = Page.StrategicPlan_Print;
		StrategicPlan__c strategicPlan = getStrategicPlan();
		pdf.getParameters().put('id',strategicPlan.Id);
		Attachment attach = new Attachment();
		Blob body;
		try {
			body = pdf.getContentAsPDF();	
		} 
		catch (VisualforceException e) {
    		body = Blob.valueOf('Failed to generate PDF.');
		}
		attach.Body = body;
		attach.ContentType = 'application/pdf'; 
		attach.Name = strategicPlan.Name + ' Snapshot ' + datetime.now() + '.pdf';
    	attach.IsPrivate = false;
    	attach.ParentId = strategicPlan.Id;
    	insert attach;
    	PageReference retval = Page.StrategicPlanTabSet;
    	retval.getParameters().put('id',strategicPlan.Id);
    	retval.setRedirect(true);
    	return retval;
	}

	/**
	 * Representation of a plan contributor.
	 */
	public class PlanContributor implements Comparable {
		/** The contributor's full name */
		public String fullName {
			get;
			set;
		}

		/** The contributor's edit count */
		public Integer editCount {
			get;
			set;
		}

		/** 
		 * Simple constructor
		 * 
		 * @param fullName
		 * @param editCount
		 */
		public PlanContributor(String fullName, Integer editCount) {
			this.fullName = fullName;
			this.editCount = editCount;
		}

		/**
		 * Function used for sorting.  Only sorts based on fullName.
		 * 
		 * @param object to compare to
		 * @return -1 for less than, 1 for greater than, and 0 for equal
		 */
		public Integer compareTo(Object compareTo) {
			Integer retval = -1;
			PlanContributor compareToPlanContributor = (PlanContributor)compareTo;
			if (fullName == compareToPlanContributor.fullName) {
				retval = 0;
			}
			else if (fullName > compareToPlanContributor.fullName) {
				retval = 1;
			}
			return retval;
		}
	}
}