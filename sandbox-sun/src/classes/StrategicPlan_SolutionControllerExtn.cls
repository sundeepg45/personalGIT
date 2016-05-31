/**
 * This is a controller extension used for the StrategicPlan_SolutionTab page.
 *
 * @version 2013-05-13
 *
 * @author Bill C Riemers <briemers@redhat.com>
 * 2013-05-09 - remove unneccessary overrride
 * 2013-04-26 - Added solutionOpportunityId methods
 * 2013-03-19 - created
 * Scott Coleman <scoleman@redhat.com>
 * 2013-04-22 - Added contribution tracking
 * 2013-05-13 - Added Projected Resources field
 */
public with sharing class StrategicPlan_SolutionControllerExtn extends TabUIController.Extension {
	private static final String TAB_NAME='StrategicPlan_Solution__c';
	public static final String CREATED_FROM_SOLUTION_CF='Opportunity.CreatedFromSolutionCF';

	/**
	 * Construct using a TabUIController.
	 * 
	 * @param tabUIController
	 */
	public StrategicPlan_SolutionControllerExtn(TabUIController tabUIController) {
		super(TAB_NAME,tabUIController);
		getRecord();
	}

	/**
	 * Construct using a standard controller.
	 * 
	 * @param stdController
	 */
	public StrategicPlan_SolutionControllerExtn(ApexPages.StandardController stdController) {
		super(TAB_NAME);
		getRecord();
	}

	/**
	 * Only IT can delete records.  We detect IT by requiring both AdminByPass__c.IsAdmin__c
	 * and job function.  Since many members of IT do not have job function set, we accept
	 * a blank job function as IT.
	 *
	 * @return isDeletable
	 */
	public override Boolean getIsDeletable() {
		String jobFunction = [select Job_Function__c from User where Id = :UserInfo.getUserId() ].Job_Function__c;
		return AdminByPass__c.getInstance().IsAdmin__c && 
			(jobFunction == null || jobFunction == 'IT') &&
			super.getIsDeletable();
	}

	/**
	 * Get the Strategic Plan Id.
	 *
	 * @return strategicPlanId
	 */
	public Id getStrategicPlanId() {
		return tabUIController.getTabId('StrategicPlan__c');
	}

	/**
	 * Set the Strategic Plan Id.
	 *
	 * @param strategicPlanId
	 */
	public void setStrategicPlanId(Id planId) {
		tabUIController.setTabId('StrategicPlan__c',planId);
	}

	/**
	 * Get the Strategy Id.
	 *
	 * @return strategyId
	 */
	public Id getStrategyId() {
		return tabUIController.getTabId('StrategicPlan_Strategy__c');
	}

	/**
	 * Set the Strategy Id.
	 *
	 * @param strategyId
	 */
	public void setStrategyId(Id strategyId) {
		tabUIController.setTabId('StrategicPlan_Strategy__c',strategyId);
	}

	/**
	 * Overload of the getRecord method to call getSolution.
	 *
	 * @return record
	 */
	public override SObject getRecord() {
		return getSolution();
	}

	/**
	 * Query or create the solution.
	 *
	 * @return solution
	 */
	public StrategicPlan_Solution__c getSolution() {
		StrategicPlan_Solution__c solution = (StrategicPlan_Solution__c)super.getRecord();
		Id id = getId();
		if(solution == null || solution.Id != id) {
			solution = null;
			solutionOpportunity = null;
			if(id != null) {
				solution = [
					select
						BusinessUnit__c,
						CreatedBy.FirstName,
						CreatedBy.LastName,
						CreatedDate,
						LastModifiedBy.FirstName,
						LastModifiedBy.LastName,
						LastModifiedDate,
						Name,
						ProjectedResources__c,
						SolutionDescription__c,
						SolutionNumber__c,
						Status__c,
						StrategicPlan__c,
						Strategy__r.Name,
						Strategy__r.StrategyNumber__c,
						Strategy__r.StrategicPlan__r.Account__c,
						Strategy__r.StrategicPlan__r.Name,
						Strategy__r.StrategicPlan__r.PlanNumber__c,
						StrategyName__c,
						StrategyNumber__c
					from StrategicPlan_Solution__c
					where Id = :id ];
				setStrategyId(solution.Strategy__c);
			}
			else if(getMode() == 'new') {
				solution = new StrategicPlan_Solution__c();
				solution.Strategy__c = getStrategyId();
				solution.StrategicPlan__c = getStrategicPlanId();
				solution.Status__c = 'Draft';
				if(solution.Strategy__c != null) {
					solution.Strategy__r = [
						select
							Name,
							StrategyNumber__c,
							StrategicPlan__r.Account__c,
							StrategicPlan__r.Name,
							StrategicPlan__r.PlanNumber__c
						from StrategicPlan_Strategy__c
						where Id = :solution.Strategy__c ];
					solution.StrategicPlan__c = solution.Strategy__r.StrategicPlan__c;
				}
			}
			if(solution != null && solution.Strategy__r != null) {
				setStrategicPlanId(solution.Strategy__r.StrategicPlan__c);
			}
			setRecord(solution);
		}
		return solution;
	}

	/**
	 * Called to get solutionOpportunit.Id
	 *
	 * @return solutionOpportunity.Id
	 */
	public Id getSolutionOpportunityId() {
		return solutionOpportunity.Id;
	}

	/**
	 * Called to force a lookup to set the solutionOpportunity.Id
	 * 
	 * @param value solutionOpportunity.Id
	 */
	public void setSolutionOpportunityId(Id value) {
		StrategicPlan_SolutionOpportunity__c so = solutionOpportunity;
		if(value != so.Id) {
			if(so.Id != null) {
				solutionOpportunity = new StrategicPlan_SolutionOpportunity__c(
					Opportunity__c = so.Opportunity__c,
					StrategicPlan_Solution__c = so.StrategicPlan_Solution__c);
			}
			if(value != null) {
				for(StrategicPlan_SolutionOpportunity__c spso : [
					select
						Opportunity__c,
						StrategicPlan_Solution__c
					from StrategicPlan_SolutionOpportunity__c
					where Id = :value])
				{
					solutionOpportunity = spso;
				}
			}
		}
	}

	/**
	 * The solutionOpportunity record.
	 */
	public StrategicPlan_SolutionOpportunity__c solutionOpportunity {
		get {
			if(solutionOpportunity == null) {
				solutionOpportunity = new StrategicPlan_SolutionOpportunity__c(
					StrategicPlan_Solution__c = getId());
			}
			if(solutionOpportunity.Id == null && solutionOpportunity.Opportunity__c != null && solutionOpportunity.StrategicPlan_Solution__c != null) {
				for(StrategicPlan_SolutionOpportunity__c spso : [
					select
						Opportunity__c,
						StrategicPlan_Solution__c
					from StrategicPlan_SolutionOpportunity__c
					where Opportunity__c = :solutionOpportunity.Opportunity__c
						and StrategicPlan_Solution__c = :solutionOpportunity.StrategicPlan_Solution__c ])
				{
					solutionOpportunity = spso;
				}
			}
			return solutionOpportunity;
		}
		set;
	}

	/**
	 * Get the link used to create a new Opportunity linked to this solution.
	 *
	 * @return reference to create a new Opportunity.
	 */
	public PageReference createOpportunity() {
		PageReference retval = new PageReference('/apex/Opportunity_New');
		Map<String,String> params = retval.getParameters();
		StrategicPlan_Solution__c solution = getSolution();
		String OPP_FIELD='CF'+StringSetting__c.getInstance(CREATED_FROM_SOLUTION_CF).Value__c;
		params.put(OPP_FIELD,solution.Name);
		params.put(OPP_FIELD+'_lkid',solution.Id);
		params.put('accid',solution.Strategy__r.StrategicPlan__r.Account__c);
		params.put('retURL','/'+solution.Id);
		return retval;
	}

	/**
	 * Called to link to an opportunity.
	 * 
	 * @return null
	 */
	public PageReference linkOpportunity() {
		try {
			upsert solutionOpportunity;
			tabUIController.sequenceNumber++;
			solutionOpportunity = null;
		}
		catch(Exception ex) {
			ApexPages.addMessages(ex);
		}
		return null;
	}

	/**
	 * Called to unlink to an opportunity.
	 * 
	 * @return null
	 */
	public PageReference unlinkOpportunity() {
		try {
			delete solutionOpportunity;
			tabUIController.sequenceNumber++;
			solutionOpportunity = null;
		}
		catch(Exception ex) {
			ApexPages.addMessages(ex);
		}
		return null;
	}

	/**
	 * Save the Strategic Plan Solution
	 */
	public PageReference saveSolution() {
		PageReference retval = saveRecord();
		List<String> eventData = getEventData();
		logEvent('SPSolutionEdit',getStrategicPlanId(),eventData[0],eventData[1],eventData[2]);
		return retval;
	}

	/** 
	 * Called get the account team member role and other event data.
	 *
	 * @return list of event data
	 */
	public List<String> getEventData() {
		//need to grab plan name, current user's account team role (if any), and current user's super region
		List<String> eventData = new List<String>();
		//plan name
		String strategicPlanName = getSolution().Strategy__r.StrategicPlan__r.Name;
		eventData.add(strategicPlanName);
		//account team role
		Id userId = UserInfo.getUserId();
		List<AccountTeamMember> accountTeamMembers = [
			select
				TeamMemberRole
			from AccountTeamMember
			where AccountId = :getSolution().Strategy__r.StrategicPlan__r.Account__c
			and UserId = :userId ];
		String accountTeamRole;
		if(accountTeamMembers != null && accountTeamMembers.size() > 0) {
			accountTeamRole = accountTeamMembers[0].TeamMemberRole;
		}
		eventData.add(accountTeamRole);
		//user super region
		User currentUser = [
			select 
				Region__c
			from User
			where Id = : userId ];
		eventData.add(currentUser.Region__c);
		return eventData;
	}

	/**
	 * Called to switch to the tab for creating a new Action.
	 *
	 * @return reference to new action page
	 */
	public PageReference newAction() {
		tabUIController.sharedParams.put('StrategicPlan_Action__r.Subject__c','Strategic Plan Solution');
		tabUIController.setTabId('StrategicPlan_Action__c',null);
		tabUIController.activeTab = 'StrategicPlan_Action__c';
		tabUIController.tabMode.put('StrategicPlan_Action__c','new');
		return null;
	}
}