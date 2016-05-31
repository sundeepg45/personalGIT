/*
* File Name:PartnerUpdate
* Date Implemented: 2/25/09
* Project: Routes To Market
* Description:This Trigger will update all the Partner Top 5 customer fields according to the values of lookup Red Hat Top 5 Customer fields.
*/

trigger BusinessPlan_UpdatePartnerTop5 on SFDC_Channel_Account_Plan__c (before insert, before update) 
{
    try
    {
        List<String> BPName = new List<String>();
        List<SFDC_Channel_Account_Plan__c> BP = new List<SFDC_Channel_Account_Plan__c>();
        List<Account> Acc = new List<Account>();

        for(integer i=0;i<trigger.new.size();i++)
        {
            BPName.add(Trigger.new[i].Id);      
        }

        Map< Id,String> AccMap=new Map<Id,String>();

        List<String> AccId=new List<String>();

        for(SFDC_Channel_Account_Plan__c str:trigger.new)
        {    
            
            AccId.add(str.Top_5_Customer_JBoss1__c);
            AccId.add(str.Top_5_Customer_JBoss2__c);
            AccId.add(str.Top_5_Customer_JBoss3__c);
            AccId.add(str.Top_5_Customer_JBoss4__c);
            AccId.add(str.Top_5_Customer_JBoss5__c);
            AccId.add(str.Top_5_Customer_Metamatrix1__c);
            AccId.add(str.Top_5_Customer_Metamatrix2__c);
            AccId.add(str.Top_5_Customer_Metamatrix3__c);
            AccId.add(str.Top_5_Customer_Metamatrix4__c);
            AccId.add(str.Top_5_Customer_Metamatrix5__c);
            AccId.add(str.Top_5_Customer_RHEL1__c);
            AccId.add(str.Top_5_Customer_RHEL2__c);
            AccId.add(str.Top_5_Customer_RHEL3__c);
            AccId.add(str.Top_5_Customer_RHEL4__c);
            AccId.add(str.Top_5_Customer_RHEL5__c);

        }

        Acc=[Select Id, Name from Account where Id IN :AccId];

        for(Account accvar: Acc)
        { 
            AccMap.put(accvar.Id, accvar.Name);
        }

        for(Integer i=0;i<Trigger.new.size();i++)
        {       
            Trigger.new[i].Partner_Top_5_Customer_JBoss1_new__c=AccMap.get(Trigger.new[i].Top_5_Customer_JBoss1__c);
            Trigger.new[i].Partner_Top_5_Customer_JBoss2_new__c=AccMap.get(Trigger.new[i].Top_5_Customer_JBoss2__c);
            Trigger.new[i].Partner_Top_5_Customer_JBoss3_new__c=AccMap.get(Trigger.new[i].Top_5_Customer_JBoss3__c);
            Trigger.new[i].Partner_Top_5_Customer_JBoss4_new__c=AccMap.get(Trigger.new[i].Top_5_Customer_JBoss4__c);
            Trigger.new[i].Partner_Top_5_Customer_JBoss5_new__c=AccMap.get(Trigger.new[i].Top_5_Customer_JBoss5__c);
            Trigger.new[i].Partner_Top_5_Customer_Metamatrix1_new__c=AccMap.get(Trigger.new[i].Top_5_Customer_Metamatrix1__c);
            Trigger.new[i].Partner_Top_5_Customer_Metamatrix2_new__c=AccMap.get(Trigger.new[i].Top_5_Customer_Metamatrix2__c);
            Trigger.new[i].Partner_Top_5_Customer_Metamatrix3_new__c=AccMap.get(Trigger.new[i].Top_5_Customer_Metamatrix3__c);
            Trigger.new[i].Partner_Top_5_Customer_Metamatrix4_new__c=AccMap.get(Trigger.new[i].Top_5_Customer_Metamatrix4__c);
            Trigger.new[i].Partner_Top_5_Customer_Metamatrix5_new__c=AccMap.get(Trigger.new[i].Top_5_Customer_Metamatrix5__c);
            Trigger.new[i].Partner_Top_5_Customer_RHEL1_new__c=AccMap.get(Trigger.new[i].Top_5_Customer_RHEL1__c);
            Trigger.new[i].Partner_Top_5_Customer_RHEL2_new__c=AccMap.get(Trigger.new[i].Top_5_Customer_RHEL2__c);
            Trigger.new[i].Partner_Top_5_Customer_RHEL3_new__c=AccMap.get(Trigger.new[i].Top_5_Customer_RHEL3__c);
            Trigger.new[i].Partner_Top_5_Customer_RHEL4_new__c=AccMap.get(Trigger.new[i].Top_5_Customer_RHEL4__c);
            Trigger.new[i].Partner_Top_5_Customer_RHEL5_new__c=AccMap.get(Trigger.new[i].Top_5_Customer_RHEL5__c);      
         }
    }

    catch(Exception e)
    {
       System.debug('Error in Field value '+e);
    }

}