/**
 * This is a controller extension used for the StrategicPlan_StrategyTab page.
 *
 * @version 2013-05-13
 *
 * @author Bill C Riemers <briemers@redhat.com>
 * 2013-05-09 - remove unneccessary overrride
 * 2013-03-19 - created
 * Scott Coleman <scoleman@redhat.com>
 * 2013-04-22 - Added contribution tracking
 * 2013-05-13 - Added Projected Resources field
 */
public with sharing class StrategicPlan_StrategyControllerExtn extends TabUIController.Extension {
	private static final String TAB_NAME='StrategicPlan_Strategy__c';

	/**
	 * Construct using a TabUIController.
	 * 
	 * @param tabUIController
	 */
	public StrategicPlan_StrategyControllerExtn(TabUIController tabUIController) {
		super(TAB_NAME,tabUIController);
		getRecord();
	}

	/**
	 * Construct using a standard controller.
	 * 
	 * @param stdController
	 */
	public StrategicPlan_StrategyControllerExtn(ApexPages.StandardController stdController) {
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
	 * Overload of the getRecord method to call getStrategy.
	 *
	 * @return record
	 */
	public override SObject getRecord() {
		return getStrategy();
	}

	/**
	 * Query or create the strategy.
	 *
	 * @return strategy
	 */
	public StrategicPlan_Strategy__c getStrategy() {
		StrategicPlan_Strategy__c strategy = (StrategicPlan_Strategy__c)super.getRecord();
		Id id = getId();
		if(strategy == null || strategy.Id != id) {
			strategy = null;
			if(id != null) {
				strategy = [
					select
						CreatedBy.FirstName,
						CreatedBy.LastName,
						CreatedDate,
						EventDate__c,
						EventDescription__c,
						EventName__c,
						GoalDescription__c,
						GoalName__c,
						GoalType__c,
						InitiativeDescription__c,
						InitiativeName__c,
						InitiativeType__c,
						LastModifiedBy.FirstName,
						LastModifiedBy.LastName,
						LastModifiedDate,
						Name,
						PainPointDescription__c,
						PainPointName__c,
						PainPointType__c,
						ProjectedResources__c,
						Status__c,
						StrategicPlan__r.Account__c,
						StrategicPlan__r.Name,
						StrategicPlan__r.PlanNumber__c,
						StrategyNumber__c
					from StrategicPlan_Strategy__c
					where Id = :id ];
				setStrategicPlanId(strategy.StrategicPlan__c);
			}
			else if(getMode() == 'new') {
				strategy = new StrategicPlan_Strategy__c();
				strategy.StrategicPlan__c = getStrategicPlanId();
				strategy.Status__c = 'Draft';
				if(strategy.StrategicPlan__c != null) {
					strategy.StrategicPlan__r = [
						select
							Account__c,
							Name,
							PlanNumber__c
						from StrategicPlan__c
						where Id = :strategy.StrategicPlan__c ];
				}
			}
			setRecord(strategy);
		}
		return strategy;
	}

	/**
	 * Save the Strategic Plan Strategy
	 */
	public PageReference saveStrategy() {
		PageReference retval = saveRecord();
		List<String> eventData = getEventData();
		logEvent('SPStrategyEdit',getStrategicPlanId(),eventData[0],eventData[1],eventData[2]);
		return retval;
	} 

	public List<String> getEventData() {
		//need to grab plan name, current user's account team role (if any), and current user's super region
		List<String> eventData = new List<String>();
		//plan name
		String strategicPlanName = getStrategy().StrategicPlan__r.Name;
		eventData.add(strategicPlanName);
		//account team role
		Id userId = UserInfo.getUserId();
		List<AccountTeamMember> accountTeamMembers = [
			select
				TeamMemberRole
			from AccountTeamMember
			where AccountId = :getStrategy().StrategicPlan__r.Account__c
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

	public PageReference newSolution() {
		tabUIController.setTabId('StrategicPlan_Solution__c',null);
		tabUIController.setTabId('StrategicPlan_Solution__c',null);
		tabUIController.activeTab = 'StrategicPlan_Solution__c';
		tabUIController.tabMode.put('StrategicPlan_Solution__c','new');
		return null;
	}

	public PageReference newAction() {
		tabUIController.sharedParams.put('StrategicPlan_Action__r.Subject__c','Strategic Plan Strategy');
		tabUIController.setTabId('StrategicPlan_Action__c',null);
		tabUIController.activeTab = 'StrategicPlan_Action__c';
		tabUIController.tabMode.put('StrategicPlan_Action__c','new');
		return null;
	}
}