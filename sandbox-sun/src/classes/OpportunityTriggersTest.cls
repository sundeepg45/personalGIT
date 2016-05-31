/**
 * Class Name: OpportunityTriggersTest
 * Modificaton History: 9/20/2011 - Created test class for Opportunity triggers.
 * Reason for Modification: Created test class for Opportunity triggers.
 */
@isTest
private class OpportunityTriggersTest
{
    public static Account account;
    public static Opportunity  oppNew;
    public static List<Opportunity> oppList = new List<Opportunity>();
    public static List<Opportunity> oppUpdateList = new List<Opportunity>();
    public static List<Opportunity> oppListtwo = new List<Opportunity>();
    public static List<Opportunity> oppListthree = new List<Opportunity>();
    public static Date myDate = System.today().addDays(100);
    public static testmethod void oppData()
    {
        DeactivateAllTestUtil.setDeactivateAll(false);
        account = new Account(name='account');
        insert account;
        for(Integer i=0;i<8;i++)
        {
            oppNew = new Opportunity(name= 'closeDate',closedate=myDate,stageName='Prepare' );
            oppNew.AccountId=account.Id;
            oppNew.Close_Date_Moved__c = true;
            oppNew.Close_Date_Moved_Reason__c = 'Control';
            oppNew.Value_Selling_Cycle__c = 'Immediate';
            oppNew.DateOrderBooked__c = null;
            oppNew.OracleOrderNumber__c = null ;
            oppList.add(oppNew);
        }
        insert oppList;
        test.startTest();
        chkCLoseDate();
        oppOM();
        oppBO();
        test.stopTest();
    }
    public static testmethod void oppTestData()
    {
        DeactivateAllTestUtil.setDeactivateAll(false);
        account = new Account(name='account');
        insert account;
        for(Integer i=0;i<8;i++)
        {
            oppNew = new Opportunity(name= 'closeDate',closedate=myDate,stageName='Prepare' );
            oppNew.AccountId=account.Id;
            oppNew.Close_Date_Moved__c = true;
            oppNew.Close_Date_Moved_Reason__c = 'Control';
            oppNew.Value_Selling_Cycle__c = 'Immediate';
            oppNew.DateOrderBooked__c = null;
            oppNew.OracleOrderNumber__c = null ;
            oppList.add(oppNew);
        }
        insert oppList;
        test.startTest();
        oppVS();
        oppTriage();
        test.stopTest();
    }
    //Test method for Checkclosedate trigger
    public static void chkCLoseDate()
    {
        Date newDate = myDate.addDays(15);
        oppList[0].CloseDate = newDate;
        oppList[0].Close_Date_Moved_Reason__c = 'Control';
        oppUpdateList.add(oppList[0]);
        Date nextDate = myDate.addDays(50);
        oppList[1].CloseDate = nextDate;
        oppList[1].Close_Date_Moved_Reason__c = 'Control';
        oppUpdateList.add(oppList[1]);
        Date nextDt = myDate.addDays(120);
        oppList[2].CloseDate = nextDt;
        oppList[2].Close_Date_Moved_Reason__c = 'Control';
        oppUpdateList.add(oppList[2]);
        Date prevDate = System.today();
        oppList[3].CloseDate = prevDate;
        oppList[3].Close_Date_Moved_Reason__c = 'Control';
        oppUpdateList.add(oppList[3]);
        update oppUpdateList;
        Opportunity opp = [Select Close_Date_Moved__c, Close_Date_Moved_Reason__c, Close_Date_Moved_Details__c from Opportunity where AccountId =: account.Id and closedate =: prevDate];
        System.assertEquals(false,opp.Close_Date_Moved__c);
        System.assertEquals(null,opp.Close_Date_Moved_Reason__c);
        System.assertEquals(null,opp.Close_Date_Moved_Details__c);
    }
    //Test method for BackOut_Submitted_Order trigger
    public static void oppBO()
    {
        oppUpdateList.clear();
        oppList[0].DateOrderBooked__c = null;
        oppList[0].DateOrderSubmitted__c =  System.now() ;
        oppList[0].stageName='Prepare';
        oppList[0].OracleOrderNumber__c = null ;
        oppUpdateList.add(oppList[0]);
        Task tk = new Task();
        tk.WhatId = oppList[0].Id;
        tk.RecordTypeId = Util.omProcessingRecordTypeId;
        tk.Status='Open';
        insert tk;
        update oppUpdateList;
        Opportunity opp = [Select DateOrderBooked__c from Opportunity where AccountId =: account.Id limit 1];
        System.assertEquals(null,opp.DateOrderBooked__c);
    }
    // Test method for Opportunity_Submitted_to_OM trigger
    public static void oppOM()
    {        
        oppUpdateList.clear();
        oppList[0].DateOrderSubmitted__c =  System.now() ;
        oppList[0].DateOrderBooked__c = null;
        oppList[0].stageName='Closed Won';
        List<Region__c> regions = new List<Region__c>();
        Region__c reg = new Region__c(Country__c='TestNAA',OM_Task__c = true,Super_Region__c='NA',OM_Task_Owner__c=UserInfo.getUserId());
        Region__c rg = new Region__c(Country__c='AbhiTest',OM_Task__c = true,Super_Region__c='LATAM',OM_Task_Owner__c=UserInfo.getUserId());
        Region__c rge = new Region__c(Country__c='ArtiTest',OM_Task__c = true,Super_Region__c='EMEA');
        Region__c r = new Region__c(Country__c='NiteshTest',OM_Task__c = true,Super_Region__c='APAC');
        regions.add(reg);
        regions.add(rg);
        regions.add(rge);
        regions.add(r);
        insert regions;
        oppList[0].Country_of_Order__c = 'TestNAA';
        oppUpdateList.add(oppList[0]);
        Task tks = new Task();
        //tks.WhatId = oppList[0].Id;
        tks.RecordTypeId = Util.omProcessingRecordTypeId;
        tks.Status='Open';
        //insert tks;
        oppList[1].DateOrderBooked__c = null;
        oppList[1].DateOrderSubmitted__c =  System.now() ;
        oppList[1].Country_of_Order__c = 'AbhiTest';
        oppList[1].stageName='Closed Won';
        oppUpdateList.add(oppList[1]);
        oppList[2].DateOrderBooked__c = null;
        oppList[2].DateOrderSubmitted__c =  System.now() ;
        oppList[2].Country_of_Order__c = 'ArtiTest';
        oppList[2].stageName='Closed Won';
        oppUpdateList.add(oppList[2]);
        oppList[3].DateOrderBooked__c = null;
        oppList[3].DateOrderSubmitted__c =  System.now() ;
        oppList[3].Country_of_Order__c = 'NiteshTest';
        oppList[3].stageName='Closed Won';
        oppUpdateList.add(oppList[3]);

        update oppUpdateList;
    }
    // Test method for Opportunity_UpdateValueSellingCycle trigger
    public static void oppVS()
    {
        List<Opportunity> opps = new List<Opportunity>();
        List<Date> dates = new List<Date>();
        for(Integer i=12;i>=0;) {
            dates.add(date.today().addMonths(i--));
        }
        for(Date d : dates) {
            opps.add(new Opportunity(name= 'closeDate',stageName = 'Prepare',CloseDate=d));
        }
        insert opps;
        Opportunity opp = [Select Value_Selling_Cycle__c  from Opportunity where Id = :opps[0].Id];
        System.assertEquals('12 Months',opp.Value_Selling_Cycle__c);
    }
    // Test method for OpportunityTriage trigger
    public static void oppTriage()
    {
        Opportunity opptwo = new Opportunity(name= 'closeDate',stageName = 'Prepare',closedate=myDate);
        opptwo.Triage_Opportunity__c = false;
        oppListtwo.add(opptwo);
        insert oppListtwo;
        Task task = new Task();
        task.WhatId = opptwo.Id;
        task.RecordTypeId = Util.omCorrectionRequestRecordTypeId;
        insert task;
        Task tsk = new Task();
        tsk.RecordTypeId = Util.omCorrectionRequestRecordTypeId;
        insert tsk;
        Opportunity opp = [Select Triage_Opportunity__c from Opportunity limit 1];
        System.assertEquals(false,opp.Triage_Opportunity__c);
    }
}