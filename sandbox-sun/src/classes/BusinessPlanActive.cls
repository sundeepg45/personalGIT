public class BusinessPlanActive {
    public void setUniqueObjectiveRule(SFDC_Channel_Account_Plan__c[] BP) {   
        for(SFDC_Channel_Account_Plan__c var : BP) {
            if (Util.isBusinessPlanUpdate)
                continue;
            var.Business_Plan_Active__c = var.Fiscal_Year__c + var.Active__c + var.Partner_Name__c;      
        }
    }  
    
     public static testmethod void deployBusinessPlanActive() {           
        Account acc=new Account();
        acc.Name='Account Test Active For Business Plan';
        acc.CurrencyIsoCode='USD';
        acc.isAccountActive__c=true;
        insert acc;
        
        SFDC_Channel_Account_Plan__c[] obj_arr_deploy=new SFDC_Channel_Account_Plan__c[2];

        Util.isBusinessPlanUpdate=false;

        SFDC_Channel_Account_Plan__c BP_one=new SFDC_Channel_Account_Plan__c();
        BP_one.Partner_Name__c= acc.Id; 
        BP_one.Plan_Date__c='Current Fiscal Year';
        BP_one.Fiscal_Year__c='FY2009';
        BP_one.Name='test';
        BP_one.Active__c=true;
        
            
        SFDC_Channel_Account_Plan__c BP_two=new SFDC_Channel_Account_Plan__c();
        BP_two.Partner_Name__c= acc.Id;
        BP_two.Plan_Date__c='Next Fiscal Year';
        BP_two.Fiscal_Year__c='FY2010';
        BP_two.Name='test two';
        BP_two.Active__c=true;
        
        obj_arr_deploy[0]=BP_one;
        obj_arr_deploy[1]=BP_two;

        insert obj_arr_deploy;
        
        new BusinessPlanActive().setUniqueObjectiveRule(obj_arr_deploy);

    }
}