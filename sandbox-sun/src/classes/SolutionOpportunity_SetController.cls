/**
 * This is a controller of for looking up opportunities that can be linked
 * to strategic plan solutions.
 *
 * @version 2013-08-30
 * @author Bill C Riemers <briemers@redhat.com>
 * 2013-08-30 - Created.
 */
public without sharing class SolutionOpportunity_SetController {
	private Id strategicPlanSolutionId;

	/**
	 * Basic constructor for the controller.  Reads the URL parameters for the
	 * currentPage and initialize the class.
	 */
	public SolutionOpportunity_SetController()
	{
		Map<String,String> paramMap = ApexPages.currentPage().getParameters();
		strategicPlanSolutionId = paramMap.get('id');
		System.debug('strategicPlanSolutionId='+strategicPlanSolutionId);
	}

	/**
	 * The StrategicPlan_Solution__c record specified by the currentPage Id parameter.
	 */
	public StrategicPlan_Solution__c solution {
		get {
			if(solution == null) {
				solution = [
					select
						Name,
						StrategicPlan__r.Account__c,
						StrategicPlan__r.Name
					from StrategicPlan_Solution__c
					where Id = :strategicPlanSolutionId ];
			}
			return solution;
		}
		private set;
	}

	public Set<Id> accountIds {
		get {
			if(accountIds == null) {
				accountIds = new Set<Id>{};
				if(solution != null && solution.StrategicPlan__r != null) {
					accountIds.add(solution.StrategicPlan__r.Account__c);
					for(AccountHierarchy__c ah : [
						select UltimateParentId__c
						from AccountHierarchy__c
						where Account__c = :solution.StrategicPlan__r.Account__c
						limit 1 ])
					{
						Id ultimateParentId = ah.UltimateParentId__c;
						System.debug('UltimateParentId='+ultimateParentId);
						for(AccountHierarchy__c ah2 : [
							select Account__c
							from AccountHierarchy__c
							where Id = :ultimateParentId
								or Parent__c = :ultimateParentId
								or UltimateParent__c = :ultimateParentId ])
						{
							accountIds.add(ah2.Account__c);
						}
					}
				}
			}
			return accountIds;
		}
		private set;
	}

	/**
	 * Contains the StandardSetController for listed all the PartnerStatus__c records 
	 * related to the StrategicPlan_Solution__c via a reseller OpportunityPartner__c object.
	 * @return the StandardSetController of Opportunity records.
	 */
	public ApexPages.StandardSetController opportunityRecords {
		get {
			if(opportunityRecords == null) {
				String s = searchString;
				if(s == null) {
					s = '';
				}
				s=s.replace('%','_').replace('*','%').replace('?','_')+'%';
				System.debug('searchString='+s);
				Set<Id> xaccountIds = accountIds;
				System.debug('accounts.size()='+xaccountIds.size());
				Integer maxQuerySize = 100*((10000 - Limits.getQueryRows() - 100)/100);
				String queryConditions =
					+'Name like :s' 
					+'	or OpportunityNumber__c like :s'
					+'	or PONumber__c like :s'
					+'	or OracleOrderNumber__c like :s';
				if(! xaccountIds.isEmpty()) {
					queryConditions = 'AccountId in :xaccountIds and ( '+queryConditions+' )';
				}
				opportunityRecords = new ApexPages.StandardSetController(Database.getQueryLocator(
					'	select'
					+'		Name,'
					+'		OpportunityNumber__c,'
					+'		Account.Name,'
					+'		PONumber__c,'
					+'		OracleOrderNumber__c'
					+'	from Opportunity'
					+'	where '+queryConditions
					+'	order by Name,'
					+'		OpportunityNumber__c,'
					+'		Account.Name,'
					+'		PONumber__c,'
					+'		OracleOrderNumber__c,'
					+'		LastModifiedDate desc'
					+'	limit :maxQuerySize'));
			}
			return opportunityRecords;
		}
		private set;
	}

	/**
	 * The opportunity name (search String) to use.
	 */
	public String searchString {
		get;
		set {
			if(value != searchString) {
				searchString = value;
				opportunityRecords = null;
			}
		}
	}

	/**
	 * The number of pages available.
	 * @return number of pages
	 */
	public Integer getPageCount() {
		Integer rs = opportunityRecords.getResultSize();
		Integer ps = opportunityRecords.getPageSize();
		return (ps+rs-1)/ps;
	}

	/**
	 * Dummy call.
	 * @return null
	 */
	public PageReference updateSearchString()
	{
		return null;
	}

	/**
	 * The current page of PartnerStatus__c records.
	 * @return list of PartnerStatus__c records.
	 */
	public List<SolutionOpportunity> getSolutionOpportunityPagination() {
		List<Opportunity> opps = opportunityRecords.getRecords();
		Map<Id,StrategicPlan_SolutionOpportunity__c> soppMap = new Map<Id,StrategicPlan_SolutionOpportunity__c>();
		for(StrategicPlan_SolutionOpportunity__c sopp : [
			select
				Name,
				Opportunity__r.Name,
				Opportunity__r.OpportunityNumber__c,
				Opportunity__r.Account.Name,
				Opportunity__r.PONumber__c,
				Opportunity__r.OracleOrderNumber__c
			from StrategicPlan_SolutionOpportunity__c
			where Opportunity__c in :opps
				and StrategicPlan_Solution__c = :strategicPlanSolutionId ])
		{
			soppMap.put(sopp.Opportunity__c,sopp);
		}
		List<SolutionOpportunity> retval = new List<SolutionOpportunity>();
		for(Opportunity opp : opps) {
			StrategicPlan_SolutionOpportunity__c sopp = soppMap.get(opp.Id);
			if(sopp == null) {
				sopp = new StrategicPlan_SolutionOpportunity__c(Opportunity__c=opp.Id,Opportunity__r=opp,StrategicPlan_Solution__c=solution.Id);
			}
			retval.add(new SolutionOpportunity(sopp));
		}
		return retval;
	}

	/**
	 * Navigate to the first page.
	 * @return null
	 */
	public PageReference first()
	{
		opportunityRecords.first();
		return null;
	}

	/**
	 * Navigate to the next page.
	 * @return null
	 */
	public PageReference next()
	{
		opportunityRecords.next();
		return null;
	}

	/**
	 * Navigate to the previous page.
	 * @return null
	 */
	public PageReference previous()
	{
		opportunityRecords.previous();
		return null;
	}

	/**
	 * Navigate to the last page.
	 * @return null
	 */
	public PageReference last()
	{
		opportunityRecords.last();
		return null;
	}

	/**
	 * Called to navigate back the the StrategicPlan_Solution__c view page.
	 * @retval PageReference to view the StrategicPlan_Solution__c record.
	 */
	public PageReference cancel() {
		String retURL = ApexPages.currentPage().getParameters().get('retURL');
		if(retURL == null) {
			retURL = '/'+strategicPlanSolutionId+'#PreferredPartners_target';
		}
		Integer i = retURL.indexOf('#');
		String anchor = null;
		if(i > 0) {
			anchor = retURL.substring(i+1);
			retURL = retURL.substring(0,i);
		}
		PageReference retval = new PageReference(retURL);
		if(anchor != null) {
			retval.setAnchor(anchor);
		}
		retval.setRedirect(true);
		return retval;
	}

	public with sharing class SolutionOpportunity {
		private final StrategicPlan_SolutionOpportunity__c solutionOpportunity;

		public SolutionOpportunity(StrategicPlan_SolutionOpportunity__c solutionOpportunity) {
			this.solutionOpportunity = solutionOpportunity;
		}

		public StrategicPlan_SolutionOpportunity__c getSolutionOpportunity() {
			return solutionOpportunity;
		}

		/**
		 * Called to link to an opportunity.
		 * 
		 * @return null
		 */
		public PageReference linkOpportunity() {
			try {
				upsert solutionOpportunity;
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
			}
			catch(Exception ex) {
				ApexPages.addMessages(ex);
			}
			return null;
		}
	} 

}