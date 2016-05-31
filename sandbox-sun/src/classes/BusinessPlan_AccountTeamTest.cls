@IsTest
private class BusinessPlan_AccountTeamTest {
    public static testmethod void deployPopulate_CAM_ICAM() {
        User[] usernames=[Select Id,Name from User where IsActive=true limit 2]; 

        Account acct = new Account();
        acct.Name = 'Account';
        acct.IsAccountActive__c = true;
        insert acct; 

        AccountTeamMember AcctMember1=new AccountTeamMember();
        AcctMember1.TeamMemberRole ='Channel Account Manager';
        AcctMember1.AccountId=acct.Id; 
        AcctMember1.UserId=usernames[0].Id;
        insert AcctMember1;

        AccountTeamMember AcctMember2=new AccountTeamMember();
        AcctMember2.TeamMemberRole ='Inside Channel Account Manager';
        AcctMember2.AccountId=acct.Id; 
        AcctMember2.UserId=usernames[0].Id;
        insert AcctMember2;

        List<SFDC_Channel_Account_Plan__c> BusinessPlans=new List<SFDC_Channel_Account_Plan__c>();
        SFDC_Channel_Account_Plan__c BPlan=new SFDC_Channel_Account_Plan__c();
        BPlan.Partner_Name__c=acct.Id; 
        Bplan.Name='testBp1';
        Bplan.Plan_Date__c='FY2011';
        BusinessPlans.add(Bplan);
        insert BusinessPlans;
                
        Bplan.Name='testBp2';
        update Bplan;
    } 

    public static testmethod void deploysubmitValidation()
    {
            Account acct=[Select  Id from Account where isAccountActive__c=true limit 1]; 
            User usernames=[Select Id,Name from User where IsActive=true limit 1];

            AccountTeamMember AcctMember1=new AccountTeamMember();
            AcctMember1.TeamMemberRole ='Partner';
            AcctMember1.AccountId=acct.Id; 
            AcctMember1.UserId=usernames.Id;
            insert AcctMember1;


            List<SFDC_Channel_Account_Plan__c> BusinessPlans=new List<SFDC_Channel_Account_Plan__c>();
            SFDC_Channel_Account_Plan__c BPlan=new SFDC_Channel_Account_Plan__c();
            BPlan.Partner_Name__c=acct.Id; 
            Bplan.Name='testBp1New';
            Bplan.Approval_Status__c='Draft';
            Bplan.Sales_Reps__c=2;
            Bplan.Responsible_Red_Hat_Account_Manager__c=usernames.Id;
            Bplan.ICAM__c=usernames.Id;
            Bplan.Plan_Date__c='FY2010';
            Bplan.Partner_Red_Hat_Offerings__c='RHEL';
            Bplan.Red_Hat_Trained_Sales__c=10;
            Bplan.Red_Hat_Trained_Engineers__c=5;
            Bplan.Employees__c=15;
            Bplan.Partner_Priorities__c='Test Coverage';
            BusinessPlans.add(Bplan);
            insert BusinessPlans;

                SFDC_Objective__c test_obj=new SFDC_Objective__c();
                test_obj.Name='test';
                test_obj.Account_Name__c= acct.Id; 
                test_obj.Channel_Plan__c=Bplan.Id;
                insert test_obj;

                SFDC_Plan_Resource_Association__c test_Redacc=new SFDC_Plan_Resource_Association__c();
                test_Redacc.Account_Name__c= acct.Id; 
                test_Redacc.Channel_Plan__c=Bplan.Id;
                test_Redacc.Role__c='Business Planning Partner Participant';
                insert test_Redacc;
                
                SFDC_Plan_Resource_Association__c test_Redacc1=new SFDC_Plan_Resource_Association__c();
                test_Redacc1.Account_Name__c= acct.Id; 
                test_Redacc1.Channel_Plan__c=Bplan.Id;
                test_Redacc1.Role__c='Channel Account Manager';
                insert test_Redacc1;
                   
                 SFDC_Plan_Resource_Association__c test_Redacc2=new SFDC_Plan_Resource_Association__c();
                test_Redacc2.Account_Name__c= acct.Id; 
                test_Redacc2.Channel_Plan__c=Bplan.Id;
                test_Redacc2.Role__c='Key Partner Executive';
                insert test_Redacc2;
                
                 SFDC_Plan_Resource_Association__c test_Redacc3=new SFDC_Plan_Resource_Association__c();
                test_Redacc3.Account_Name__c= acct.Id; 
                test_Redacc3.Channel_Plan__c=Bplan.Id;
                test_Redacc3.Role__c='Account Champion Partner Executive';
                insert test_Redacc3;

            Bplan.Approval_Status__c='Pending First Approval';
            update Bplan;   
        }
        
        public static testmethod void testdeleteBPChildObjectsAndtestdeleteMDFChildObjects()
        {
             SFDC_Channel_Account_Plan__c testBP = [select Id from SFDC_Channel_Account_Plan__c where id <> null limit 1];
             delete testBP;
             SFDC_Budget__c testMDF = [select Id from SFDC_Budget__c where id <> null limit 1];
             delete testMDF;
        } 
        

}