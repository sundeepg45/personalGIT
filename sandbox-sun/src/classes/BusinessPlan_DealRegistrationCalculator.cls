public class BusinessPlan_DealRegistrationCalculator {

    public BusinessPlanFY   bp;
    public decimal trueAmount;
    Account accInfo;
    List<Lead> leadList;
    private String region;

    public boolean isTestingDR = False;
    public boolean isTestingTA = False;
    
    public Integer Q1SubmittedCount { get; set; }
    public double Q1SubmittedAmount { get; set; }
    public Integer Q1ApprovedCount { get; set; }
    public double Q1ApprovedAmount { get; set; }
    public Integer Q1ConvertedCount { get; set; }
    public double Q1ConvertedAmount { get; set; }
    public Integer Q1ClosedCount { get; set; }
    public double Q1ClosedAmount { get; set; }

    public Integer Q2SubmittedCount { get; set; }
    public double Q2SubmittedAmount { get; set; }
    public Integer Q2ApprovedCount { get; set; }
    public double Q2ApprovedAmount { get; set; }
    public Integer Q2ConvertedCount { get; set; }
    public double Q2ConvertedAmount { get; set; }
    public Integer Q2ClosedCount { get; set; }
    public double Q2ClosedAmount { get; set; }

    public Integer Q3SubmittedCount { get; set; }
    public double Q3SubmittedAmount { get; set; }
    public Integer Q3ApprovedCount { get; set; }
    public double Q3ApprovedAmount { get; set; }
    public Integer Q3ConvertedCount { get; set; }
    public double Q3ConvertedAmount { get; set; }
    public Integer Q3ClosedCount { get; set; }
    public double Q3ClosedAmount { get; set; }

    public Integer Q4SubmittedCount { get; set; }
    public double Q4SubmittedAmount { get; set; }
    public Integer Q4ApprovedCount { get; set; }
    public double Q4ApprovedAmount { get; set; }
    public Integer Q4ConvertedCount { get; set; }
    public double Q4ConvertedAmount { get; set; }
    public Integer Q4ClosedCount { get; set; }
    public double Q4ClosedAmount { get; set; }
    
    public Integer FYSubmittedCount { get; set; }
    public double FYSubmittedAmount { get; set; }
    public Integer FYApprovedCount { get; set; }
    public double FYApprovedAmount { get; set; }
    public Integer FYConvertedCount { get; set; }
    public double FYConvertedAmount { get; set; }
    public Integer FYClosedCount { get; set; }
    public double FYClosedAmount { get; set; }
    
    static Map<String,CurrencyType> currencyTypeMap = null;
    
    public BusinessPlan_DealRegistrationCalculator(ApexPages.StandardController controller) 
    {
        bp = BusinessPlanFY.getInstance(controller.getRecord().Id);
        region = bp.plan.Partner_Name__r.Global_Region__c;
    }
    
    public PageReference initData()
    {
        // Teaming agreements and subscriptions use the EXACT same calculation, just with different record types
        List<String> recordTypes = new List<String>();
        if (isTestingDR || ApexPages.currentPage().getUrl().indexOf('BusinessPlan_DealRegistrationStatistics') > -1) {
            if (region == 'NA'){
                recordTypes.add(region + ' Subscription Deal Registration');
                recordTypes.add(region + ' Services Deal Registration');
                recordTypes.add(region + ' Fed/Sled Deal Registration');
            } else {
                recordTypes.add(region + ' Deal Registration');
            }
        } else if (isTestingTA || ApexPages.currentPage().getUrl().indexOf('BusinessPlan_TeamingAgreementsSection') > -1) {
            recordTypes.add('Reseller Teaming Agreement Deal Registration');
        }
        
        Q1SubmittedCount = 0;
        Q1SubmittedAmount = 0;
        Q1ApprovedCount = 0;
        Q1ApprovedAmount = 0;
        Q1ConvertedCount = 0;
        Q1ConvertedAmount = 0;
        Q1ClosedCount = 0;
        Q1ClosedAmount = 0;
    
        Q2SubmittedCount = 0;
        Q2SubmittedAmount = 0;
        Q2ApprovedCount = 0;
        Q2ApprovedAmount = 0;
        Q2ConvertedCount = 0;
        Q2ConvertedAmount = 0;
        Q2ClosedCount = 0;
        Q2ClosedAmount = 0;
    
        Q3SubmittedCount = 0;
        Q3SubmittedAmount = 0;
        Q3ApprovedCount = 0;
        Q3ApprovedAmount = 0;
        Q3ConvertedCount = 0;
        Q3ConvertedAmount = 0;
        Q3ClosedCount = 0;
        Q3ClosedAmount = 0;
    
        Q4SubmittedCount = 0;
        Q4SubmittedAmount = 0;
        Q4ApprovedCount = 0;
        Q4ApprovedAmount = 0;
        Q4ConvertedCount = 0;
        Q4ConvertedAmount = 0;
        Q4ClosedAmount = 0;
        Q4ClosedCount = 0;
        
        FYSubmittedCount = 0;
        FYSubmittedAmount = 0;
        FYApprovedCount = 0;
        FYApprovedAmount = 0;
        FYConvertedCount = 0;
        FYConvertedAmount = 0;
        FYClosedCount = 0;
        FYClosedAmount = 0;

        leadList = [
            Select 
                Id, 
                Red_Hat_Total_Revenue__c,
                ConvertedOpportunity.Amount,
                ConvertedOpportunity.id,
                ConvertedOpportunity.CreatedDate, 
                Deal_Approved_Date__c,
                CreatedDate,
                CurrencyIsoCode,
                Deal_Registration_Status__c
            from Lead 
            where 
                PartnerAccountId =:bp.plan.Partner_Name__c
                and Deal_Registration_Status__c NOT IN ('Draft') 
                and RecordType.Name IN :recordTypes
                and CreatedDate <= :bp.fys.EndDate
                and CreatedDate >= :bp.fys.StartDate
                
        ];
        
        for (Lead l : leadList) {
            Integer q = getQuarter(l);
            trueAmount = checkNull(l.ConvertedOpportunity.Amount);
            if (q == 1) {
                Q1SubmittedCount++;
                if (trueAmount != 0) {
                    Q1SubmittedAmount += l.ConvertedOpportunity.Amount;
                }
                else if (trueAmount == 0 && l.ConvertedOpportunity.CreatedDate == null) {
                    Q1SubmittedAmount += l.Red_Hat_Total_Revenue__c;
                }
            } else if (q == 2) {
                Q2SubmittedCount++;
                if (trueAmount != 0) {
                    Q2SubmittedAmount += l.ConvertedOpportunity.Amount;
                }
                else if (trueAmount == 0 && l.ConvertedOpportunity.CreatedDate == null) {
                    Q2SubmittedAmount += l.Red_Hat_Total_Revenue__c;
                }
            } else if (q == 3) {
                Q3SubmittedCount++;
                if (trueAmount != 0) {
                    Q3SubmittedAmount += l.ConvertedOpportunity.Amount;
                }
                else if (trueAmount == 0 && l.ConvertedOpportunity.CreatedDate == null) {
                    Q3SubmittedAmount += l.Red_Hat_Total_Revenue__c;
                }
            } else if (q == 4) {
                Q4SubmittedCount++;
                if (trueAmount != 0) {
                    Q4SubmittedAmount += l.ConvertedOpportunity.Amount;
                }
                else if (trueAmount == 0 && l.ConvertedOpportunity.CreatedDate == null) {
                    Q4SubmittedAmount += l.Red_Hat_Total_Revenue__c;
                }
            }
            FYSubmittedCount++;
            if (trueAmount != 0) {
                    FYSubmittedAmount += l.ConvertedOpportunity.Amount;
                }
                else if (trueAmount == 0 && l.ConvertedOpportunity.CreatedDate == null) {
                    FYSubmittedAmount += l.Red_Hat_Total_Revenue__c;
                }
            if (l.Deal_Registration_Status__c == 'Approved'){
                if (q == 1) {
                    Q1ApprovedCount++;
                    if (trueAmount != 0) {
                        Q1ApprovedAmount += l.ConvertedOpportunity.Amount;
                    }
                    else if (trueAmount == 0 && l.ConvertedOpportunity.CreatedDate == null) {
                        Q1ApprovedAmount += l.Red_Hat_Total_Revenue__c;
                    }
                } else if (q == 2) {
                    Q2ApprovedCount++;
                    if (trueAmount != 0) {
                        Q2ApprovedAmount += l.ConvertedOpportunity.Amount;
                    }
                    else if (trueAmount == 0 && l.ConvertedOpportunity.CreatedDate == null) {
                        Q2ApprovedAmount += l.Red_Hat_Total_Revenue__c;
                    }
                } else if (q == 3) {
                    Q3ApprovedCount++;
                    if (trueAmount != 0) {
                        Q3ApprovedAmount += l.ConvertedOpportunity.Amount;
                    }
                    else if (trueAmount == 0 && l.ConvertedOpportunity.CreatedDate == null) {
                        Q3ApprovedAmount += l.Red_Hat_Total_Revenue__c;
                    }
                } else if (q == 4) {
                    Q4ApprovedCount++;
                    if (trueAmount != 0) {
                        Q4ApprovedAmount += l.ConvertedOpportunity.Amount;
                    }
                    else if (trueAmount == 0 && l.ConvertedOpportunity.CreatedDate == null) {
                        Q4ApprovedAmount += l.Red_Hat_Total_Revenue__c;
                    }
                }
                FYApprovedCount++;
                if (trueAmount != 0) {
                    FYApprovedAmount += l.ConvertedOpportunity.Amount;
                }
                else if (trueAmount == 0 && l.ConvertedOpportunity.CreatedDate == null) {
                    FYApprovedAmount += l.Red_Hat_Total_Revenue__c;
                }
            }
        }
        
        leadList = [
            Select 
                Id,
                Deal_Approved_Date__c,
                CreatedDate,
                Red_Hat_Total_Revenue__c, 
                ConvertedOpportunity.Id, 
                ConvertedOpportunity.Amount, 
                ConvertedOpportunity.CloseDate,
                ConvertedOpportunity.CreatedDate,
                ConvertedOpportunity.CurrencyIsoCode,
                ConvertedOpportunity.StageName
            from Lead 
                where 
                PartnerAccountId =:bp.plan.Partner_Name__c
                and ConvertedOpportunityId != null 
                and RecordType.Name IN :recordTypes
                and CreatedDate <= :bp.fys.EndDate
                and CreatedDate >= :bp.fys.StartDate
        ];
        
        for (Lead l : leadList) {
            Integer q = getQuarter(l);
            trueAmount = checkNull(l.ConvertedOpportunity.Amount);
            // All of them count as converted
            if (q == 1) {
                Q1ConvertedCount++;
                if (trueAmount != 0) {
                    Q1ConvertedAmount += l.ConvertedOpportunity.Amount;
                }
                else if (trueAmount == 0 && l.ConvertedOpportunity.CreatedDate == null) {
                    Q1ConvertedAmount += l.Red_Hat_Total_Revenue__c;
                }
            } else if (q == 2) {
                Q2ConvertedCount++;
                if (trueAmount != 0) {
                    Q2ConvertedAmount += l.ConvertedOpportunity.Amount;
                }    
                else if (trueAmount == 0 && l.ConvertedOpportunity.CreatedDate == null) {
                    Q2ConvertedAmount += l.Red_Hat_Total_Revenue__c;
                }
            } else if (q == 3) {
                Q3ConvertedCount++;
                if (trueAmount != 0) {
                    Q3ConvertedAmount += l.ConvertedOpportunity.Amount;
                }
                else if (trueAmount == 0 && l.ConvertedOpportunity.CreatedDate == null) {
                    Q3ConvertedAmount += l.Red_Hat_Total_Revenue__c;
                }
            } else if (q == 4) {
                Q4ConvertedCount++;
                if (trueAmount != 0) {
                    Q4ConvertedAmount += l.ConvertedOpportunity.Amount;
                }
                else if (trueAmount == 0 && l.ConvertedOpportunity.CreatedDate == null) {
                    Q4ConvertedAmount += l.Red_Hat_Total_Revenue__c;
                }
            }
            FYConvertedCount++;
            if (trueAmount != 0) {
                FYConvertedAmount += l.ConvertedOpportunity.Amount;
            }
            else if (trueAmount == 0 && l.ConvertedOpportunity.CreatedDate == null) {
                FYConvertedAmount += l.Red_Hat_Total_Revenue__c;
            }

            // Only closed booked opportunities count as closed
            if (l.ConvertedOpportunity.StageName == 'Closed Booked') {
                if (q == 1) {
                    Q1ClosedCount++;
                    Q1ClosedAmount += l.ConvertedOpportunity.Amount;
                } else if (q == 2) {
                    Q2ClosedCount++;
                    Q2ClosedAmount += l.ConvertedOpportunity.Amount;
                } else if (q == 3) {
                    Q3ClosedCount++;
                    Q3ClosedAmount += l.ConvertedOpportunity.Amount;
                } else if (q == 4) {
                    Q4ClosedCount++;
                    Q4ClosedAmount += l.ConvertedOpportunity.Amount;
                }
                FYClosedCount++;
                FYClosedAmount += l.ConvertedOpportunity.Amount;
            }
        } 
        return null;
    }
    
    public Decimal checkNull(Decimal trueAmount) {
         if (trueAmount == null){ 
             trueAmount = 0;
         }
         return trueAmount;
    }
    
    public Integer getQuarter(Lead l)
    {
        Integer quarter = 1;
        Date parseDate = Date.newinstance(l.CreatedDate.Year(), l.CreatedDate.Month(), l.CreatedDate.Day());       
        for(Period q : bp.quarters){           
            if (parseDate >= q.StartDate
                && parseDate <= q.EndDate)
            {
                return quarter;
            }
            quarter++;
        }
        return -1;
    }
    
    public BusinessPlanFY getBusinessPlan()
    {
        return bp;
    }

    public String getPartnerId()
    {
        return String.valueOf(bp.plan.Partner_Name__c).substring(0,15);
    }
    
    public Boolean getIsInternalUser() {
        User me = [select Contact.AccountId from User where Id = :UserInfo.getUserId()];
        return me.Contact.AccountId == null;
    }

    @IsTest(SeeAllData=true)
    public static void testMyController() 
    {
        SFDC_Channel_Account_Plan__c mbp = [select Id from SFDC_Channel_Account_Plan__c where id = 'a1360000000KBd6']; 
        
        ApexPages.StandardController testController=new ApexPages.StandardController(mbp);

        PageReference pageRef = Page.BusinessPlan_DealRegistrationStatistics;
        test.setCurrentPage(pageRef);      
       
        BusinessPlan_DealRegistrationCalculator businessPlan_DealRegistrationCalculatorObj=new BusinessPlan_DealRegistrationCalculator(testController);

        businessPlan_DealRegistrationCalculatorObj.isTestingDR = True;
        businessPlan_DealRegistrationCalculatorObj.initData();
        businessPlan_DealRegistrationCalculatorObj.isTestingDR = False;
        businessPlan_DealRegistrationCalculatorObj.isTestingTA = True;
        businessPlan_DealRegistrationCalculatorObj.initData();

        mbp = [select Id from SFDC_Channel_Account_Plan__c where id = 'a136000000081s2']; 
        
        testController=new ApexPages.StandardController(mbp);
        pageRef = Page.BusinessPlan_DealRegistrationStatistics;
        test.setCurrentPage(pageRef);      
       
        businessPlan_DealRegistrationCalculatorObj=new BusinessPlan_DealRegistrationCalculator(testController);

        businessPlan_DealRegistrationCalculatorObj.isTestingDR = True;
        businessPlan_DealRegistrationCalculatorObj.initData();
        businessPlan_DealRegistrationCalculatorObj.isTestingDR = False;
        businessPlan_DealRegistrationCalculatorObj.isTestingTA = True;
        businessPlan_DealRegistrationCalculatorObj.initData();
        businessPlan_DealRegistrationCalculatorObj.getIsInternalUser();
        businessPlan_DealRegistrationCalculatorObj.getBusinessPlan();
        businessPlan_DealRegistrationCalculatorObj.getPartnerId();
    }
}