/**
* Class Name: Opportunity_VerifiableOutcomeTest
* Description: Test Class created for Opportunity_VerifiableOutcome and OpptyType_VerifiableOutcome class.
* Craeted By : Nitesh
* Created Date :11/14/2011
* Modified By : Nitesh Dokania 
* Modified date :12/22/2011 
* Reason for Modification: Updated the test class code so that Non VO profile user can also execute thie test
*                          without any error.
*/

@isTest
private class Opportunity_VerifiableOutcomeTest
{
     public static testmethod void oppvo1()  
     {
        List <Opportunity> oppList = new List <Opportunity> ();
        List <Verifiable_Outcome__c> outcomeList = new List <Verifiable_Outcome__c> ();
        List <Verifiable_Outcome__c> outcomeDelList = new List <Verifiable_Outcome__c> ();
        List <Verifiable_Outcome__c> outcomeAfterUpdate = new List <Verifiable_Outcome__c> ();
        
        Account acc = new Account();
        acc.Name = 'NewTest';
        insert acc;
        
        Opportunity opp = new Opportunity();
        opp.AccountId = acc.Id;
        opp.Name = 'test';
        opp.Country_of_Order__c = 'USA';
        opp.OpportunityType__c = 'Standard';
        opp.StageName = 'Prepare';
        opp.CloseDate = System.today();
        oppList.add(opp);
        
        Opportunity oppty = new Opportunity();
        oppty.AccountId = acc.Id;
        oppty.Name = 'test';
        oppty.Country_of_Order__c = 'USA';
        oppty.OpportunityType__c = 'Standard';
        oppty.StageName = 'Propose';
        oppty.CloseDate = System.today();
        oppList.add(oppty);
        
        insert oppList;
        
        test.startTest();
        
        // getting profiles from custom setting for whom VO should not get created
        List<SalesOperations__c> customSettingObj  = null ;
        Set<Id> profileIdSet = new Set<Id>();
        
        customSettingObj  = SalesOperations__c.getall().values();      
        for(SalesOperations__c profileId : customSettingObj)
        {
            profileIdSet.add(profileId.ProfileId__c);
        }
        
        opp.DateOrderSubmitted__c = System.today();
        update opp;
        
        outcomeList = [Select Id,Stage__c from Verifiable_Outcome__c where Opportunity__c =: opp.Id];
        for(Verifiable_Outcome__c vo : outcomeList)
        {
            if(vo.Stage__c=='Prepare')
            outcomeDelList.add(vo);
        }
        delete outcomeDelList;
        
        opp.StageName = 'Engage';
        update opp;
        
        outcomeAfterUpdate = [Select Id,Stage__c from Verifiable_Outcome__c where Opportunity__c =: opp.Id];
        
        if(profileIdSet.contains(UserInfo.getProfileId()))
            System.assertEquals(0, outcomeAfterUpdate.size());
        else
            System.assertEquals(2, outcomeAfterUpdate.size());

        test.stopTest();        
    }

    public static testmethod void oppvo2() {
        List <Opportunity> oppList = new List <Opportunity> ();

        Account acc = new Account();
        acc.Name = 'NewTest';
        insert acc;
        
        Opportunity opp = new Opportunity();
        opp.AccountId = acc.Id;
        opp.Name = 'test';
        opp.Country_of_Order__c = 'USA';
        opp.OpportunityType__c = 'Standard';
        opp.StageName = 'Engage';
        opp.CloseDate = System.today();
        opp.DateOrderSubmitted__c = System.today();
        oppList.add(opp);
        
        insert oppList;
        
        test.startTest();

        opp.OpportunityType__c = 'Eval';
        opp.DateOrderSubmitted__c = null;
        update opp;
        
        opp.OpportunityType__c = 'Standard';
        opp.DateOrderSubmitted__c = System.today();
        opp.StageName = 'Closed Won';
        update opp;
        
        Profile profile = [select id from profile where name='Administrator - Level 1'];
        User usr = new User(alias = 'st8236', email='standrduser8236@testorg.com',
        emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
        localesidkey='en_US', profileid = profile.Id,
        timezonesidkey='America/Los_Angeles', username='standrduser8236@testorg.com');
        // use a runAs statement to create a new context to avoid mixed DML errors
        User thisUser = [ select Id from User where Id = :UserInfo.getUserId() ];
        System.runAs ( thisUser ) {
            insert usr;
        }
        // runAs newly created user
        System.runAs(usr)
        {
            opp.OpportunityType__c = 'Eval';
            update opp;
        }

        opp.OpportunityType__c = 'Standard';
        opp.StageName = 'Validate';
        update opp;
        
        opp.StageName = 'Closed Lost';
        opp.ReasonWonLostSalesProcess__c = 'Company out of business/acquired';
        update opp;

        test.stopTest();
    }

}