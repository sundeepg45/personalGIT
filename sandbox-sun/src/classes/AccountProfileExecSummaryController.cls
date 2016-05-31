/**
 * This provides the data for the read-only printable Account Planning
 * view called Executive Summary (AccountProfile_ExecSummary.page)
 *
 * @version 2013-11-14
 * @author Scott Coleman <scoleman@redhat.com>
 * 2013-11-14 - added default sort to Account Team list
 * 2013-10-07 - bug fixes
 * 2013-10-02 - created
 */
public with sharing class AccountProfileExecSummaryController{
    private final Id acctProfileId;

   	/** 
	 * Visualforce constructor
	 */ 
    public AccountProfileExecSummaryController() {
        String idParam = ApexPages.currentPage().getParameters().get('id');
        acctProfileId = Id.valueOf(idParam);
    }

	/** 
	 * Constructor for easier testing
	 */    
    public AccountProfileExecSummaryController(Id accountProfileId) {
        acctProfileId = accountProfileId;
    }
 
	/** 
	 * Account Profile record including related lists
	 */    
    public Account_Profile__c accountProfile {
        get {
            if(accountProfile == null) {
                accountProfile = [
                    SELECT 
                        Id,
                        Account__c,
                        Account_end_users__c,
                        Account_s_Biggest_Competitor_s__c,
                        Corporate_Objectives__c,
                        Corporate_Strategy_Current_Initiatives__c,
                        Critical_Success_Factors__c,
                        Industry_Position_Market_Share_History__c,
                        Pain_Point_1__c,
                        Pain_Point_2__c,
                        Pain_Point_3__c,
                        (SELECT
                            Id,
                            Business_Agenda__c,
                            CustomerKeyContact__r.FirstName,
                            CustomerKeyContact__r.LastName,
                            CustomerKeyContact__r.Name,
                            Personal_Agenda__c,
                            Point_Person_on_Red_Hat_Account_Team__c,
                            Reports_To__c,
                            Title__c,
                            Your_Relationship__c
                         FROM Account_Profile_Power_Maps__r),
                        (SELECT
                            Id,
                            PartnerStatus__r.PartnerTier__c,
                            PartnerStatus__r.PartnerType__c,
                            PartnerStatus__r.Partner__r.Name
                         FROM Account_Profile_Partner_Statuses__r),
                        (SELECT
                            Id,
                            Name,
                            Partner_Type__c
                         FROM Account_Profile_Other_Partners__r),
                        (SELECT
                            Id,
                            Competitor__c
                         FROM Competitor__r),
                        (SELECT
                            Id,
                            Statement__c,
                            Type__c
                         FROM Account_Profile_SWOTs__r)
                    FROM Account_Profile__c
                    WHERE Id = :acctProfileId
                    LIMIT 1];
            }
            return accountProfile;
        }
        set;
    }

	/** 
	 * Account record with Account Team Members
	 */     
    public Account account {
        get {
            if(account == null) {
                account = [
                    SELECT
                        Id,
                        Name,
                        AccountClassification__c,
                        AnnualRevenue,
                        BillingCity,
                        BillingCountry,
                        BillingPostalCode,
                        BillingState,
                        BillingStreet,
                        Industry,
                        IT_Budget__c,
                        NumberOfEmployees,
                        Parent.Id,
                        Parent.Name,
                        RecordType.Id,
                        RecordType.Name,
                        (SELECT
                            Id,
                            TeamMemberRole,
                            User.FirstName,
                            User.LastName,
                            User.Name
                         FROM AccountTeamMembers
                         ORDER BY User.LastName, User.FirstName)
                    FROM Account
                    WHERE Id = :accountProfile.Account__c
                    LIMIT 1];
            }
            return account;
        }
        set;
    }

	/** 
	 * Strategic Plan record - the most recently updated plan associated with the profile
	 */     
    public StrategicPlan__c strategicPlan {
        get {
            if(strategicPlan == null) {
                List<StrategicPlan__c> strategicPlans = [
                    SELECT
                        Id,
                        Name
                    FROM StrategicPlan__c
                    WHERE AccountProfile__c = :acctProfileId
                    ORDER BY LastModifiedDate DESC
                    LIMIT 1];
                if(!strategicPlans.isEmpty()) {
                    strategicPlan = strategicPlans[0];
                }
            }
            return strategicPlan;
        }
        set;
    }

	/** 
	 * Strategy records with Solutions - the 5 most recently updated strategies
	 */     
    public List<StrategicPlan_Strategy__c> strategies {
        get {
            if(strategies == null) {
                if(strategicPlan == null) {
                    strategies = new List<StrategicPlan_Strategy__c>();
                }
            	else {
                    strategies = [
                        SELECT
                            Id,
                            Name,
                            PainPointDescription__c,
                            (SELECT
                                Id,
                                Name,
                                SolutionDescription__c
                             FROM Solutions__r
                             ORDER BY CreatedDate DESC)
                        FROM StrategicPlan_Strategy__c
                        WHERE StrategicPlan__c = :strategicPlan.Id
                        ORDER BY CreatedDate DESC
                        LIMIT 5];
                }
            }
            return strategies;
        }
        set;
    }

	/** 
	 * Opportunity records with Solutions - the top 5 opps by amount 
	 */     
    public List<Opportunity> opportunities {
        get {
            if(opportunities == null) {
                if(strategicPlan == null) {
                    opportunities = new List<Opportunity>();
                }
                else {
                    opportunities = [
                        SELECT
                            Id,
                            Account.Name,
                            Amount,
                            CloseDate,
                            Name,
                            StageName,
                            (SELECT
                                Id,
                                StrategicPlan_Solution__r.Id,
                                StrategicPlan_Solution__r.Name
                             FROM StrategicPlan_SolutionOpportuniti__r)
                        FROM Opportunity
                        WHERE Id IN (SELECT Opportunity__c 
                                     FROM StrategicPlan_SolutionOpportunity__c
                                     WHERE StrategicPlan_Solution__r.StrategicPlan__c = :strategicPlan.Id)
                            AND (NOT StageName LIKE '%Closed%')
                        ORDER BY Amount DESC NULLS LAST, CloseDate ASC NULLS LAST
                        LIMIT 5];
                }
            }
            return opportunities;
        }
        set;
    }
}