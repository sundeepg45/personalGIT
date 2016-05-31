public without sharing class BusinessPlanFY {

    // manage our own pool of plans statically in order to avoid extra queries by various business plan section controllers
    static private Map<String,BusinessPlanFY>   pool = new Map<String, BusinessPlanFY>();

    public  SFDC_Channel_Account_Plan__c    plan        { get; private set; }
    public  Period[]                        quarters    { get; private set; }
    public  String                          fyStart     { get; private set; }
    public  String                          fyEnd       { get; private set; }
    public  String                          fiscalYear  { get; private set; }
    public  FiscalYearSettings              fys         { get; private set; }

    private BusinessPlanFY(ID bpId) {
        plan = [
            select  Id, Fiscal_Year__c, Partner_Name__c, Partner_Name__r.Global_Region__c,
                    // data for revenue section
                    Revenue_Objective_Q1_Goal__c, Revenue_Objective_Q2_Goal__c,
                    Revenue_Objective_Q3_Goal__c, Revenue_Objective_Q4_Goal__c, Revenue_Objective_Full_Year_Goal__c
            from    SFDC_Channel_Account_Plan__c
            where   Id = :bpId
        ];
        resolveQuarters();
    }
    
    private BusinessPlanFY(ID partnerId, String fiscalYear) {
        plan = [
            select  Id, Fiscal_Year__c, Partner_Name__c, Revenue_Objective_Q1_Goal__c, Revenue_Objective_Q2_Goal__c,
            Revenue_Objective_Q3_Goal__c, Revenue_Objective_Q4_Goal__c, Revenue_Objective_Full_Year_Goal__c
            from    SFDC_Channel_Account_Plan__c
            where   Partner_Name__c = :partnerId
            and     Fiscal_Year__c = :'FY' + fiscalYear
        ];
        resolveQuarters();
    }
    
    private void resolveQuarters() {
        fiscalYear = plan.Fiscal_Year__c;
        if (fiscalYear.length() > 4) fiscalYear = fiscalYear.substring(2); // strip off "FY"
        fys = [select Id, PeriodId, StartDate, EndDate from FiscalYearSettings where Name = :fiscalYear];
        System.debug('*****[debug]***** fys.Id=' + fys.Id);
        quarters = [select StartDate, EndDate, Number from Period where FiscalYearSettingsId = :fys.Id and Type = 'Quarter' order by Number];
        Date startDate = quarters.get(0).StartDate;
        Date endDate = quarters.get(3).EndDate;
        fyStart = startDate.month() + '/' + startDate.day() + '/' + startDate.year();
        fyEnd = endDate.month() + '/' + endDate.day() + '/' + endDate.year();
    }

    static public BusinessPlanFY getInstance(ID partnerId, String fiscalYear) {    
        String sId = partnerId;
        String key = sId + fiscalYear;
        if (!pool.containsKey(key)) {
            pool.put(key, new BusinessPlanFY(partnerId, fiscalYear));
        }
        return pool.get(key);
    }

    static public BusinessPlanFY getInstance(ID bpid) {
        String sId = bpid;
        if (!pool.containsKey(sid)) {
            pool.put(sid, new BusinessPlanFY(sid));
        }
        return pool.get(sid);
    }
}