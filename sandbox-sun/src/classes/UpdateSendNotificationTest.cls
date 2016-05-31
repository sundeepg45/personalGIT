/**
* Class Name:UpdateSendNotificationTest
* Description:Test Class created for UpdateSendNotification trigger.
* Modificaton History:
* Modified By: Nitesh Dokania
* Modified date : 6/29/2011
* Reason for Modification: Created a new test class for unit testing and code coverage.
*/

@isTest
private class UpdateSendNotificationTest 
{

    static testMethod void updateNotification() 
    {
        DeactivateAllTestUtil.setDeactivateAll(false);

        // TO DO: implement unit test
        List<Opportunity> opptyList = new List<Opportunity>();
        List<Task> taskList = new List<Task>();
        Opportunity opptyrec = new Opportunity();
        Task taskRec = new Task();
        
        Account acc = new Account(Name='Test Account');
        insert acc;
        
        for(Integer i=0;i<20;i++)
        {
        	Opportunity  opp = new Opportunity(Name='Test Opp',Triage_Opportunity__c=true,FulfillmentChannel__c='Indirect – VAR/VAD',CloseDate=System.today(),StageName='Unqualified',AccountId=acc.Id,Country_of_Order__c='India');
        	opptyList.add(opp);
        }
        insert opptyList;
        for(Opportunity opp : opptyList)
        {
        	Task tk = new Task();
        	tk.Subject = 'Conference Call';
        	tk.WhatId = opp.Id;
        	taskList.add(tk);
        }
        insert taskList;
        
        // StattTest and Stoptest is used to check governor limits.
        test.startTest();
        
        for(Task tk : taskList)
        {
        	tk.Send_Notification__c = true;
        }
        update taskList;
        
        for(Opportunity oppty : opptyList)
        {
	        oppty.Triage_Opportunity__c = false;	        
        }
        update opptyList;
	    
	    opptyrec = [Select Id, Send_Notification_to_Opp_Owner__c from Opportunity where Id in : opptyList limit 1];
	    // Verify the result
	    //System.assertEquals(true,opptyrec.Send_Notification_to_Opp_Owner__c);
	    
	    taskRec = [Select Id, Send_Notification__c from Task where Id in : taskList limit 1];
	    // Verify the result
	    //System.assertEquals(false,taskRec.Send_Notification__c);	    
	    
	    update taskList;
	    
	    taskRec = [Select Id, Send_Notification__c from Task where Id in : taskList limit 1];
	    // Verify the result
	    //System.assertEquals(true,taskRec.Send_Notification__c);
	          
        test.stopTest();
    }
}