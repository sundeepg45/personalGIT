public without sharing class BusinessPlan_RevenueSectionController {

    public BusinessPlanFY					bp {get; private set; }
	private	Double							q1attainment = null;
	private	Double							q2attainment = null;
	private	Double							q3attainment = null;
	private	Double							q4attainment = null;
	private	Integer							q1accounts = null;
	private	Integer							q2accounts = null;
	private	Integer							q3accounts = null;
	private	Integer							q4accounts = null;


	public BusinessPlan_RevenueSectionController(ApexPages.StandardController controller)  { 
        bp = BusinessPlanFY.getInstance(controller.getRecord().Id);
	} 

    public String getBPId() {
        String s = bp.plan.Partner_Name__c;
        if (s.length() > 15) s = s.substring(0,15);
        return s;
    }

	public Decimal getFullYearGoal() {
		return bp.plan.Revenue_Objective_Full_Year_Goal__c;
	}
	
	public Decimal getFullYearAttainment() {
		return q1attainment + q2attainment + q3attainment + q4attainment;
	}
	
	public Integer getFullYearCustomerCount() {
		return q1accounts + q2accounts + q3accounts + q4accounts;
	}

	public Integer getQ1CustomerCount() {
		if (q1accounts == null) {
			q1accounts = getQuarterCustomers(1);
		}
		return q1accounts;
	}

	public Integer getQ2CustomerCount() {
		if (q2accounts == null) {
			q2accounts = getQuarterCustomers(2);
		}
		return q2accounts;
	}

	public Integer getQ3CustomerCount() {
		if (q3accounts == null) {
			q3accounts = getQuarterCustomers(3);
		}
		return q3accounts;
	}
	
	public Integer getQ4CustomerCount() {
		if (q4accounts == null) {
			q4accounts = getQuarterCustomers(4);
		}
		return q4accounts;
	}

    public Decimal getQ1Goal() {
       	if (bp.plan.Revenue_Objective_Q1_Goal__c == null) return 0.0;
       	return bp.plan.Revenue_Objective_Q1_Goal__c;
	}
	
	public Double getQ1Attainment() {
		if (q1attainment == null) {
			q1attainment = getQuarterAttainment(1);
		}
		return q1attainment;
	}

	public Decimal getQ2Goal() {
        if (bp.plan.Revenue_Objective_Q2_Goal__c == null) return 0.0;
		return bp.plan.Revenue_Objective_Q2_Goal__c;
	}
	
	public Decimal getQ2Attainment() {
		if (q2attainment == null) {
			q2attainment = getQuarterAttainment(2);
		}
		return q2attainment;
	}

	public Decimal getQ3Goal() {
        if (bp.plan.Revenue_Objective_Q3_Goal__c == null) return 0.0;
		return bp.plan.Revenue_Objective_Q3_Goal__c;
	}
	
	public Decimal getQ3Attainment() {
		if (q3attainment == null) {
			q3attainment = getQuarterAttainment(3);
		}
		return q3attainment;
	}

	public Decimal getQ4Goal() {
        if (bp.plan.Revenue_Objective_Q4_Goal__c == null) return 0.0;
		return bp.plan.Revenue_Objective_Q4_Goal__c;
	}
	
	public Decimal getQ4Attainment() {
		if (q4attainment == null) {
			q4attainment = getQuarterAttainment(4);
		}
		return q4attainment;
	}

	private Integer getQuarterCustomers(integer quarter) {
		Period q = bp.quarters.get(quarter-1);
		OpportunityPartner__c[] opprows = [
			select	Opportunity__r.AccountId
			from	OpportunityPartner__c
			where	Partner__c = :bp.plan.Partner_Name__c
			and		Opportunity__r.StageName = 'Closed Booked'
			and		Opportunity__r.CloseDate >= :q.StartDate
			and		Opportunity__r.CloseDate <= :q.EndDate
            and		Opportunity__r.Amount != null
			and		RelationshipType__c in ('Reseller 2','Reseller 3','Reseller 4','Reseller 5','Reseller 6','Reseller 7','Reseller 8','Reseller 9','Reseller 10')
		];
		Set<ID> unique = new Set<ID>();
		for (OpportunityPartner__c op : opprows) unique.add(op.Opportunity__r.AccountId);
		System.debug('*****[debug]****** customer count=' + unique.size());
		return unique.size();
	}

	private Double getQuarterAttainment(integer quarter) {

		Period q = bp.quarters.get(quarter-1);
		AggregateResult[] totals = [
			select	sum(Opportunity__r.Amount)
			from	OpportunityPartner__c
			where	Partner__c = :bp.plan.Partner_Name__c
			and		Opportunity__r.StageName = 'Closed Booked'
			and		Opportunity__r.CloseDate >= :q.StartDate
			and		Opportunity__r.CloseDate <= :q.EndDate
            and		Opportunity__r.Amount != null
			and		RelationshipType__c in ('Reseller 2','Reseller 3','Reseller 4','Reseller 5','Reseller 6','Reseller 7','Reseller 8','Reseller 9','Reseller 10')
		];
		
		Double total = (Double) totals.get(0).get('expr0');
		System.debug('*****[debug]***** attainment total: ' + total + ' for quarter ' + quarter);
		if (total == null) total = 0.0;
		return total;
		
	}
    
    public Boolean getIsInternalUser() {
        User me = [select Contact.AccountId from User where Id = :UserInfo.getUserId()];
        return me.Contact.AccountId == null;
    }

	@IsTest(SeeAllData=true)	
	private static void simpleTest() {
		SFDC_Channel_Account_Plan__c bp = [select Id from SFDC_Channel_Account_Plan__c where Revenue_Objective_Q1_Goal__c != null limit 1];
		ApexPages.Standardcontroller sctrl = new ApexPages.Standardcontroller(bp);
		BusinessPlan_RevenueSectionController ctrl = new BusinessPlan_RevenueSectionController(sctrl);
        Double d = ctrl.getQ1Goal();
        d = ctrl.getQ2Goal();
        d = ctrl.getQ3Goal();
        d = ctrl.getQ4Goal();
        d = ctrl.getQ1Attainment();
        d = ctrl.getQ2Attainment();
        d = ctrl.getQ3Attainment();
        d = ctrl.getQ4Attainment();
        d = ctrl.getFullYearGoal();
        d = ctrl.getQ1CustomerCount();
        d = ctrl.getQ2CustomerCount();
        d = ctrl.getQ3CustomerCount();
        d = ctrl.getQ4CustomerCount();
        d = ctrl.getFullYearAttainment();
        d = ctrl.getFullYearCustomerCount();

	}
}