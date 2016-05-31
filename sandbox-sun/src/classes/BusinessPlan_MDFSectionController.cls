public with sharing class BusinessPlan_MDFSectionController {

    private BusinessPlanFY	bp;
    public boolean isAdmin { get; set; }
	
	public double Q1Count { get; set; }
	public double Q1Available { get; set; }
	public double Q1Requested { get; set; }
	public double Q1Claimed { get; set; }
	public double Q1Balance { get; set; }

	public double Q2Count { get; set; }
	public double Q2Available { get; set; }
	public double Q2Requested { get; set; }
	public double Q2Claimed { get; set; }
	public double Q2Balance { get; set; }

	public double Q3Count { get; set; }
	public double Q3Available { get; set; }
	public double Q3Requested { get; set; }
	public double Q3Claimed { get; set; }
	public double Q3Balance { get; set; }

	public double Q4Count { get; set; }
	public double Q4Available { get; set; }
	public double Q4Requested { get; set; }
	public double Q4Claimed { get; set; }
	public double Q4Balance { get; set; }
	
	public double FYAvailable { get; set; }
	public double FYRequested { get; set; }
	public double FYClaimed { get; set; }
	public double FYBalance { get; set; }
	
	public BusinessPlan_MDFSectionController(ApexPages.StandardController controller)  { 
		bp = BusinessPlanFY.getInstance(controller.getRecord().Id);
        User me = [select Profile.Name from User where Id = :UserInfo.getUserId()];
		isAdmin = me.Profile.Name == 'Administrator - Level 2' || me.Profile.Name == 'Administrator - Level 1';
	    initData();
	    loadData();
	}

	private void initData(){
		Q1Count = 0.0;
		Q1Available = 0.0;
		Q1Requested = 0.0;
		Q1Claimed = 0.0;
		Q1Balance = 0.0;
	
		Q2Count = 0.0;
		Q2Available = 0.0;
		Q2Requested = 0.0;
		Q2Claimed = 0.0;
		Q2Balance = 0.0;
	
		Q3Count = 0.0;
		Q3Available = 0.0;
		Q3Requested = 0.0;
		Q3Claimed = 0.0;
		Q3Balance = 0.0;
	
		Q4Count = 0.0;
		Q4Available = 0.0;
		Q4Requested = 0.0;
		Q4Claimed = 0.0;
		Q4Balance = 0.0;
		
		FYAvailable = 0.0;
		FYRequested = 0.0;
		FYClaimed = 0.0;
		FYBalance = 0.0;
	}

	private void loadData(){
		List<SFDC_Budget__c> budgets = [
			select 
				Id,
				Available_Budget__c,
				Allocated_Budget__c,
				Approved_Claims__c,
				Approved_Requests__c,
				Requests_Awaiting_Approval__c,
				Requests_Submitted__c,
				Unclaimed__c,
				Fiscal_Year__c,
				Fiscal_Quarter__c
			from SFDC_Budget__c
			where 
				Account_master__c = :bp.plan.Partner_Name__c
				and Fiscal_Year__c = :bp.fiscalYear
			order by Fiscal_Quarter__c
		];
		
		for (SFDC_Budget__c budget : budgets){
			FYAvailable += budget.Allocated_Budget__c;
			FYRequested += budget.Approved_Requests__c;
			FYClaimed += budget.Approved_Claims__c;
			FYBalance += budget.Available_Budget__c;

			if (budget.Fiscal_Quarter__c == 'Q1'){
				Q1Count++;
				Q1Available += budget.Allocated_Budget__c;
				Q1Requested += budget.Approved_Requests__c;
				Q1Claimed += budget.Approved_Claims__c;
				Q1Balance += budget.Available_Budget__c;
			} else if (budget.Fiscal_Quarter__c == 'Q2'){
				Q2Count++;
				Q2Available += budget.Allocated_Budget__c;
				Q2Requested += budget.Approved_Requests__c;
				Q2Claimed += budget.Approved_Claims__c;
				Q2Balance += budget.Available_Budget__c;
			} else if (budget.Fiscal_Quarter__c == 'Q3'){
				Q3Count++;
				Q3Available += budget.Allocated_Budget__c;
				Q3Requested += budget.Approved_Requests__c;
				Q3Claimed += budget.Approved_Claims__c;
				Q3Balance += budget.Available_Budget__c;
			} else if (budget.Fiscal_Quarter__c == 'Q4'){
				Q4Count++;
				Q4Available += budget.Allocated_Budget__c;
				Q4Requested += budget.Approved_Requests__c;
				Q4Claimed += budget.Approved_Claims__c;
				Q4Balance += budget.Available_Budget__c;
			}
			
		}
		/*
		List<SFDC_MDF__c> requests = [
			select 
				Id,
				Amount__c,
				Approved_Amount__c
			from SFDC_MDF__c
			where 
				Account_master__c = :bp.Partner_Name__c
				and Budget__r.Fiscal_Year__c = :fiscalYearFull
			order by Budget__r.Fiscal_Year__c, Budget__r.Fiscal_Quarter__c
		];

		List<SFDC_MDF_Claim__c> claims = [
			select 
				Id,
				Amount__c,
				Approved_Amount__c				
			from SFDC_MDF_Claim__c
			where 
				Account__c = :bp.Partner_Name__c
				and Budget__r.Fiscal_Year__c = :fiscalYearFull
				and Approval_Status__c = 'Approved'
			order by Budget__r.Fiscal_Year__c, Budget__r.Fiscal_Quarter__c
		];
		
		/*
		if (budget.Fiscal_Quarter__c == 'Q1'){
				
		} else if (budget.Fiscal_Quarter__c == 'Q2'){
			
		} else if (budget.Fiscal_Quarter__c == 'Q3'){
			
		} else if (budget.Fiscal_Quarter__c == 'Q4'){
			
		}*/
	}
	
	@IsTest(SeeAllData=true)	
	private static void simpleTest() {
		SFDC_Channel_Account_Plan__c bp = [select Id from SFDC_Channel_Account_Plan__c where Approval_Status__c = 'Approved' limit 1];
		ApexPages.Standardcontroller sctrl = new ApexPages.Standardcontroller(bp);
		BusinessPlan_MDFSectionController ctrl = new BusinessPlan_MDFSectionController(sctrl);
	}
	
}