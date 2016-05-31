public class FiscalGoals{

    public void setUniqueObjectiveRule(FiscalGoals__c[] goals)
    {
        for(FiscalGoals__c goal:goals)
        {
        goal.Fiscal_Year_Active__c=goal.Fiscal_Year__c+goal.Active__c + goal.Language__c;
        }
    }  
    
     public static testmethod void deployFiscalGoals()
    {   
        FiscalGoals__c[] obj_arr_deploy=new FiscalGoals__c[2];

        FiscalGoals__c FS_Goal_one=new FiscalGoals__c();
        FS_Goal_one.Name='TESTFS_Goal_one';
        FS_Goal_one.Active__c=true;
        FS_Goal_one.Fiscal_Year__c='FY2111';
            
        FiscalGoals__c FS_Goal_two=new FiscalGoals__c();
        FS_Goal_two.Name='FS_Goal_two';
        FS_Goal_two.Active__c=false;
        FS_Goal_two.Fiscal_Year__c='FY2222';
        
        obj_arr_deploy[0]=FS_Goal_one;
        obj_arr_deploy[1]=FS_Goal_two;

        insert obj_arr_deploy;
        
        new FiscalGoals().setUniqueObjectiveRule(obj_arr_deploy);

    }
}