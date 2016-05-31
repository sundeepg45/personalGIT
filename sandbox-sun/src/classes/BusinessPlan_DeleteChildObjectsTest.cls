@IsTest
private class BusinessPlan_DeleteChildObjectsTest {
    public static testmethod void testDeleteObjectives() {
        Account account = new Account();
        account.Name = 'Account';
        insert account;
        
        SFDC_Channel_Account_Plan__c businessPlan = new SFDC_Channel_Account_Plan__c();
        businessPlan.Name = 'Business Plan';
        businessPlan.Partner_Name__c = account.Id;
        insert businessPlan;

        system.assertEquals(0, [
            select Name
              from SFDC_Objective__c
             where Name = 'BusinessPlan_DeleteChildObjectsTest.testDeleteObjectives()'
        ].size());  

        SFDC_Objective__c objective = new SFDC_Objective__c();
        objective.Name = 'BusinessPlan_DeleteChildObjectsTest.testDeleteObjectives()';
        objective.Channel_Plan__c = businessPlan.Id;
        insert objective;
        
        system.assertEquals(1, [
            select Name
              from SFDC_Objective__c
             where Name = 'BusinessPlan_DeleteChildObjectsTest.testDeleteObjectives()'
        ].size());  

        delete businessPlan;

        system.assertEquals(0, [
            select Name
              from SFDC_Objective__c
             where Name = 'BusinessPlan_DeleteChildObjectsTest.testDeleteObjectives()'
        ].size());  
    }

    public static testmethod void testDeleteCampaignPlan() {
        Account account = new Account();
        account.Name = 'Account';
        insert account;
        
        SFDC_Channel_Account_Plan__c businessPlan = new SFDC_Channel_Account_Plan__c();
        businessPlan.Name = 'Business Plan';
        businessPlan.Partner_Name__c = account.Id;
        insert businessPlan;

        system.assertEquals(0, [
            select Name
              from Campaign_Plan__c
             where Name = 'BusinessPlan_DeleteChildObjectsTest.testDeleteCampaignPlan()'
        ].size());  

        Campaign_Plan__c campaignPlan = new Campaign_Plan__c();
        campaignPlan.Name = 'BusinessPlan_DeleteChildObjectsTest.testDeleteCampaignPlan()';
        campaignPlan.Business_Plan__c = businessPlan.Id;
        insert campaignPlan;
        
        system.assertEquals(1, [
            select Name
              from Campaign_Plan__c
             where Name = 'BusinessPlan_DeleteChildObjectsTest.testDeleteCampaignPlan()'
        ].size());  

        delete businessPlan;

        system.assertEquals(0, [
            select Name
              from Campaign_Plan__c
             where Name = 'BusinessPlan_DeleteChildObjectsTest.testDeleteCampaignPlan()'
        ].size());  
    }

    public static testmethod void testDeleteKeyJointSalesEngagement() {
        Account account = new Account();
        account.Name = 'Account';
        insert account;
        
        SFDC_Channel_Account_Plan__c businessPlan = new SFDC_Channel_Account_Plan__c();
        businessPlan.Name = 'Business Plan';
        businessPlan.Partner_Name__c = account.Id;
        insert businessPlan;

        system.assertEquals(0, [
            select Name
              from Key_Joint_Sales_Engagement__c
             where Name = 'BusinessPlan_DeleteChildObjectsTest.testDeleteKeyJointSalesEngagement()'
        ].size());  

        Key_Joint_Sales_Engagement__c kjse = new Key_Joint_Sales_Engagement__c();
        kjse.Name = 'BusinessPlan_DeleteChildObjectsTest.testDeleteKeyJointSalesEngagement()';
        kjse.Channel_Plan__c = businessPlan.Id;
        insert kjse;
        
        system.assertEquals(1, [
            select Name
              from Key_Joint_Sales_Engagement__c
             where Name = 'BusinessPlan_DeleteChildObjectsTest.testDeleteKeyJointSalesEngagement()'
        ].size());  

        delete businessPlan;

        system.assertEquals(0, [
            select Name
              from Key_Joint_Sales_Engagement__c
             where Name = 'BusinessPlan_DeleteChildObjectsTest.testDeleteKeyJointSalesEngagement()'
        ].size());  
    }

    public static testmethod void testDeleteRHPartnerTeamMembers() {
        Account account = new Account();
        account.Name = 'Account';
        insert account;
        
        SFDC_Channel_Account_Plan__c businessPlan = new SFDC_Channel_Account_Plan__c();
        businessPlan.Name = 'Business Plan';
        businessPlan.Partner_Name__c = account.Id;
        insert businessPlan;

        system.assertEquals(0, [
            select Name
              from SFDC_Plan_Resource_Association__c
             where Name = 'BusinessPlan_DeleteChildObjectsTest.testDeleteRHPartnerTeamMembers()'
        ].size());  

        SFDC_Plan_Resource_Association__c teamMember = new SFDC_Plan_Resource_Association__c();
        teamMember.Channel_Plan__c = businessPlan.Id;
        insert teamMember;
        
        system.assertEquals(1, [
            select Name
              from SFDC_Plan_Resource_Association__c
             where Channel_Plan__c = :businessPlan.Id
        ].size());  

        delete businessPlan;

        system.assertEquals(0, [
            select Name
              from SFDC_Plan_Resource_Association__c
             where Channel_Plan__c = :businessPlan.Id
        ].size());  
    }

}