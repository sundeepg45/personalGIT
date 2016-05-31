/**
* Class Name:LeadTaskUpdateTest
* Description:Test Class created for LeadTaskUpdate business Class.
* Modificaton History:
* Modified By :Ratan Sharma
* Modified date :4/28/2011
* Reason for Modification:Separated test class from business class and created a new test class
* Modified By :Abhijeet Anand
* Reason for Modification:Enhanced code coverage and added assert statements.
*/
@isTest
private class LeadTaskUpdateTest
{
	public static testmethod void test3()
    {
       User adminuser = [Select Id, FirstName, LastName from User where Profile.Name = 'System Administrator' and isActive = true limit 1];
     
        
        Task[] array_Task=new Task[4];
        
        
        Lead objlead = new Lead();
        objLead.LastName ='TestR4DeployLead';
        objLead.Title='R4';
        objLead.LeadSourceDetail__c='APAC World Tour';
        objLead.Status='New';
        objLead.Products_of_Interest__c='JBoss';
        objLead.Partner_Opt_In__c=true;
        objLead.Email='Paresh@gmail.gov';
        objLead.Company='Accenture';
        //objLead.Lead_partner_Worked__c='No';
        insert objlead;
              
        Lead objlead1 = new Lead();
        objlead1.LastName ='TestR5DeployLead';
        objlead1.Title='R3';
        objlead1.LeadSourceDetail__c='APAC World Tour';
        objlead1.Status='New';
        objlead1.Products_of_Interest__c='JBoss';
        objlead1.Partner_Opt_In__c=true;
        objlead1.Email='ratan@gmail.gov';
        objlead1.Company='CTS';
        objlead1.Lead_partner_Worked__c='false';
        insert objlead1 ;
                
         
        Account acc = new Account(); 
        acc.name='0OppUpFinPartTest';
        acc.AccountClassification__c='Sales - Territory';                    
        acc.BillingCountry='US';                    
        //acc.OwnerId=UserInfo.getUserId();
        
        insert acc;
        
        Opportunity opp = new Opportunity(name='testOpp',StageName='Unqualified', 
        FulfillmentChannel__c='Direct - VAR/VAD',                    
        Amount=0.00, RecordTypeId='012300000000TVDAA2',                     
        OpportunityType__c='Royalty', AccountId=acc.Id,                     
        OwnerId=UserInfo.getUserId(), Pay_Now__c='No',                     
        ForecastCategoryName='Omitted', CloseDate=Date.today(),                     
        PaymentType__c='NA Purchase Order',Opportunity_Partner_Worked__c='false');            
        

        insert opp;
        
        
        
        Opportunity opp1 = new Opportunity(name='TestOppty',StageName='Unqualified', 
        FulfillmentChannel__c='Direct - VAR/VAD',                    
        Amount=0.00, RecordTypeId='012300000000TVDAA2',                     
        OpportunityType__c='Royalty', AccountId=acc.Id,                     
        OwnerId=UserInfo.getUserId(), Pay_Now__c='No',                     
        ForecastCategoryName='Omitted', CloseDate=Date.today(),                     
        PaymentType__c='NA Purchase Order',Opportunity_Partner_Worked__c='yes');            
        
        insert opp1;
        
        
        Task tk=new Task();
        tk.WhoId=objlead.Id;
        tk.OwnerId=adminuser.Id; //Util.ldPartnerUser;
        tk.Subject='OM Correction Requested';
        tk.Status='Not Started';
        tk.Priority='Normal';
        array_Task[0]=tk;
        
               
        Task tk1=new Task();
        tk1.WhatId=opp.Id;
        tk1.OwnerId=adminuser.Id; //Util.ldPartnerUser;
        tk1.Subject='Request Pre-sale Resources';
        array_Task[1]=tk1;
        
        Task tk2=new Task();
        tk2.WhatId=opp1.Id;
        //tk2.WhoId=objlead.Id;
        tk2.OwnerId=adminuser.Id; //Util.ldPartnerUser;
        tk2.Subject='Action Required: Opportunity not modified within 30 days';
        array_Task[2]=tk2;
        
        Task tk3=new Task();
        tk3.WhoId=objlead1.Id;
        tk3.OwnerId=adminuser.Id; //Util.ldPartnerUser;
        tk3.Subject='REMINDER: Renewal Opportunity : close date of opportunity is 90 days from today';
        array_Task[3]=tk3;               
        insert array_Task;
        
        Test.StartTest();
        	new LeadTaskUpdate().updateLeadTask(array_Task); 
        Test.StopTest();                
    }

}