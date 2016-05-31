global class CloseBizPlan {
        public class BusinessPlan_CloseException extends Exception {}
        
        webservice static String BizPlan(String BizID)
        {
                SavePoint sp = Database.setSavepoint();
        
                SFDC_Channel_Account_Plan__c oldBP= [
                    Select Active__c
                         , Is_Latest__c
                         , Requester_Email__c
                         , Requester_Name__c
                         , Leads_Closed__c
                         , Leads_Closed_Amount__c
                         , Leads_Passed__c
                         , Leads_Passed_Amount__c
                         , Approval_Status__c
                         , Approval_Status_Partner__c
                         , Business_Plan_Approval_Date__c
                         , Business_Plan_Number_new__c
                         , Business_Plan_Version__c
                         , Close_Out_Review_Date__c
                         , Company_Mission_Statement__c
                         , CreatedById
                         , CreatedDate
                         , CurrencyIsoCode
                         , Customer_Focus__c
                         , Deal_Registration_Amount_Closed__c
                         , Deal_Registration_Amount_Submitted__c
                         , Deal_Registration_Closed__c
                         , Deal_Registration_of_Submitted__c
                         , Employees__c
                         , Exec_Summary__c
                         , Fax__c
                         , Fiscal_Year__c
                         , ICAM__c
                         , IsDeleted
                         , Key_Events__c
                         , LastActivityDate
                         , LastModifiedById
                         , LastModifiedDate
                         , Name
                         , National_Regional_Sales_Alignment__c
                         , New_Customer_Actions__c
                         , New_Customers_Current_Year__c
                         , New_Customers_Prior_Year__c
                         , New_Customers_Prior_Year_2__c
                         , Offices_Locations__c
                         , Other_Partner_Alliances__c
                         , Other_Performance_Targets__c
                         , Partner_Address__c
                         , Partner_Engagement_Details__c
                         , Partner_Name__c
                         , Partner_Name_formula__c
                         , Partner_OpenSource_Alliance_Offerings__c
                         , Partner_Priorities__c
                         , Partner_Red_Hat_C_Level_Meetings__c
                         , Partner_Red_Hat_Offerings__c
                         , Partner_Renewal_Current_Year__c
                         , Partner_Renewal_Prior_Year__c
                         , Partner_Renewal_Prior_Year_2__c
                         , Partner_RH_Revenue_Current_Yr_JBoss__c
                         , Partner_RH_Revenue_Current_Yr_Metamatrix__c
                         , Partner_RH_Revenue_Current_Yr_RHEL__c
                         , Partner_RH_Revenue_Current_Yr_Total__c
                         , Partner_RH_Revenue_Prior_Year2_Total__c
                         , Partner_RH_Revenue_Prior_Yr_JBoss__c
                         , Partner_RH_Revenue_Prior_Yr_Metamatrix__c
                         , Partner_RH_Revenue_Prior_Yr_RHEL__c
                         , Partner_RH_Revenue_Prior_Yr_Total__c
                         , Partner_RH_Revenue_Prior_Yr2_JBos__c
                         , Partner_RH_Revenue_Prior_Yr2_Metamatrix__c
                         , Partner_RH_Revenue_Prior_Yr2_RHEL__c
                         , Partner_s_Largest_Customer__c
                         , Partner_Tier__c
                         , Partner_Top_5_Customer_JBoss1_new__c
                         , Partner_Top_5_Customer_JBoss2_new__c
                         , Partner_Top_5_Customer_JBoss3_new__c
                         , Partner_Top_5_Customer_JBoss4_new__c
                         , Partner_Top_5_Customer_JBoss5_new__c
                         , Partner_Top_5_Customer_Metamatrix1_new__c
                         , Partner_Top_5_Customer_Metamatrix2_new__c
                         , Partner_Top_5_Customer_Metamatrix3_new__c
                         , Partner_Top_5_Customer_Metamatrix4_new__c
                         , Partner_Top_5_Customer_Metamatrix5_new__c
                         , Partner_Top_5_Customer_RHEL1_new__c
                         , Partner_Top_5_Customer_RHEL2_new__c
                         , Partner_Top_5_Customer_RHEL3_new__c
                         , Partner_Top_5_Customer_RHEL4_new__c
                         , Partner_Top_5_Customer_RHEL5_new__c
                         , Partner_Type_formula__c
                         , Partnership_Highlights__c
                         , Phone__c, Plan_Approval_Date__c
                         , Plan_Date__c
                         , PR_Actions__c
                         , Q1_Review_Date__c
                         , Q2_Review_Date__c
                         , Q3_Review_Date__c
                         , Record_Type__c
                         , RecordTypeId
                         , Red_Hat_Trained_Engineers__c
                         , Red_Hat_Trained_Sales__c
                         , Renewal_Actions__c
                         , Responsible_Red_Hat_Account_Manager__c
                         , Revenue_Growth_Plans__c
                         , Sales_Reps__c
                         , SystemModstamp
                         , Target_Markets__c
                         , Top_5_Customer_JBoss1__c
                         , Top_5_Customer_JBoss2__c
                         , Top_5_Customer_JBoss3__c
                         , Top_5_Customer_JBoss4__c
                         , Top_5_Customer_JBoss5__c
                         , Top_5_Customer_Metamatrix1__c
                         , Top_5_Customer_Metamatrix2__c
                         , Top_5_Customer_Metamatrix3__c
                         , Top_5_Customer_Metamatrix4__c
                         , Top_5_Customer_Metamatrix5__c
                         , Top_5_Customer_RHEL1__c
                         , Top_5_Customer_RHEL2__c
                         , Top_5_Customer_RHEL3__c
                         , Top_5_Customer_RHEL4__c
                         , Top_5_Customer_RHEL5__c
                         , Top_5_Joint_RH_Partner_Customers_JBoss__c
                         , Top_5_Joint_RH_Partner_Customers_RHEL__c
                      from SFDC_Channel_Account_Plan__c 
                     where Id = : BizID
                ];

                List<SFDC_Channel_Account_Plan__c> listChannelAccount= new List<SFDC_Channel_Account_Plan__c>();
                listChannelAccount.add(oldBP);

        
                List<SFDC_Channel_Account_Plan__c> listNewChannelAccount=listChannelAccount.deepClone(false);

                oldBP.Record_Type__c='Business Plan Locked';
                RecordType objRecordType=[Select Id from RecordType where Name='Business Plan Locked' and  SobjectType='SFDC_Channel_Account_Plan__c'];       
                oldBP.RecordTypeId=objRecordType.Id;
                oldBP.Active__c=False;
                oldBP.Is_Latest__c=True;
                Util.isBusinessPlanUpdate=true;
                oldBP.Business_Plan_Active__c=null;
                update oldBP;

                // STOP!!!!
//                Database.rollback(sp);
//                throw new BusinessPlan_CloseException();


                Util.isBusinessPlanUpdate = false;

                //System.debug('inside CreateBizPlan');
                String yearString = OldBP.Fiscal_Year__c.substring(2,6);
                System.debug('Substring:' + yearString);
                Decimal yearDecimal = decimal.valueOf(yearString);
                System.debug('decimal:' + yearDecimal);
                yearDecimal = yearDecimal + 1; 
                System.debug('Plus 1:' + yearDecimal);
                yearString = 'FY' + yearDecimal; 
                System.debug('finished string:' + yearString);
           

                SFDC_Channel_Account_Plan__c obj_bizPlan=listNewChannelAccount.get(0);
                System.debug('obj_bizPlan'+obj_bizPlan);
                obj_bizPlan.Name=oldBP.Partner_Name_formula__c+'-'+Schema.SObjectType.SFDC_Channel_Account_Plan__c.Label+'-'+yearString+'-V-1';
            
                obj_bizPlan.Business_Plan_Version__c=1;
                obj_bizPlan.Approval_Status__c='Draft';
                obj_bizPlan.Approval_Status_Partner__c='Draft';
                obj_bizPlan.Business_Plan_Approval_Date__c=null;
                obj_bizPlan.Q1_Review_Date__c=null;
                obj_bizPlan.Q2_Review_Date__c=null;
                obj_bizPlan.Q3_Review_Date__c=null;
                obj_bizPlan.Close_Out_Review_Date__c=null;
                obj_bizPlan.Partner_RH_Revenue_Prior_Yr_RHEL__c=oldBP.Partner_RH_Revenue_Current_Yr_RHEL__c;
                obj_bizPlan.Partner_RH_Revenue_Prior_Yr_JBoss__c=oldBP.Partner_RH_Revenue_Current_Yr_JBoss__c;
                obj_bizPlan.Partner_RH_Revenue_Prior_Yr_Metamatrix__c=oldBP.Partner_RH_Revenue_Current_Yr_Metamatrix__c;
                obj_bizPlan.Partner_RH_Revenue_Prior_Yr2_RHEL__c=oldBP.Partner_RH_Revenue_Prior_Yr_RHEL__c;
                obj_bizPlan.Partner_RH_Revenue_Prior_Yr2_JBos__c=oldBP.Partner_RH_Revenue_Prior_Yr_JBoss__c;
                obj_bizPlan.Partner_RH_Revenue_Prior_Yr2_Metamatrix__c=oldBP.Partner_RH_Revenue_Prior_Yr_Metamatrix__c;
                obj_bizPlan.Partner_Renewal_Prior_Year__c=oldBP.Partner_Renewal_Current_Year__c;
                obj_bizPlan.Partner_Renewal_Prior_Year_2__c=oldBP.Partner_Renewal_Prior_Year__c;
                obj_bizPlan.New_Customers_Prior_Year__c=oldBP.New_Customers_Current_Year__c;
                obj_bizPlan.New_Customers_Prior_Year_2__c=oldBP.New_Customers_Prior_Year__c;
                obj_bizPlan.Plan_Date__c='Next Fiscal Year';
                obj_bizPlan.Active__c=True;
                obj_bizPlan.Is_Latest__c=True;
             
                obj_bizPlan.Fiscal_Year__c = yearString;
                

                insert obj_bizPlan;

                List<SFDC_Plan_Resource_Association__c> redHatAndPartnerList = [
                    Select Account_Name__c
                         , Account_Role__c
                         , Channel_Plan__c
                         , CreatedById
                         , CreatedDate
                         , CurrencyIsoCode
                         , Email__c
                         , Id
                         , IsDeleted
                         , LastModifiedById
                         , LastModifiedDate
                         , Mobile__c
                         , Name
                         , Phone__c
                         , Resource__c
                         , Role__c
                         , SystemModstamp
                         , Title__c 
                      from SFDC_Plan_Resource_Association__c 
                     where Channel_Plan__c = : oldBP.Id
                 ];
                List<SFDC_Plan_Resource_Association__c> newRedHatAndPartnerList=redHatAndPartnerList.deepClone(false);
                
        for(SFDC_Plan_Resource_Association__c obj:newRedHatAndPartnerList)
            {
                obj.Channel_Plan__c=obj_bizPlan.Id;
                        }
                
        insert newRedHatAndPartnerList;
        
                //System.Debug('new id'+obj_bizPlan.Id);

                return obj_bizPlan.Id;
        }

}