/**
* Class Name:CreateSalesTeamTest
* Author:Accenture
* Date:4/11/2011
* Description: Test Class created for CreateSalesTeam business Class.
* Modificaton History:
* Modified By :Nitesh Dokania
* Modified date :4/11/2011
* Reason for Modification:Separated test class from business class and created a new test class
*/

@isTest
private class CreateSalesTeamTest
{
    //Deployment Methods
    public static testmethod void testCreateSalesTeam()
    {  
        User user=[Select Id from User where IsActive=true limit 1]; 
        Opportunity opp=[Select Id from Opportunity limit 1]; 
        String UserID=user.Id;
        String OpportunityID=opp.Id; 
        String accessRole='Read/Write';
        String TeamMemberRole='Partner';
        //ApexPages.StandardController standardController = new ApexPages.StandardController(CreateSalesTeam);
        CreateSalesTeam  controller = new CreateSalesTeam();
        CreateSalesTeam.salesTeam(UserID,OpportunityID,accessRole,TeamMemberRole);
    }
}