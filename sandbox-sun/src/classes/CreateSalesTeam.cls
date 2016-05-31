global class CreateSalesTeam {
webservice static void salesTeam(String UserID,String OpportunityID,String accessRole,String TeamMemberRole)
{
    System.debug('inside salesteam');
    OpportunityTeamMember obj_oppTeamMem= new OpportunityTeamMember();
    System.debug('object created');
    obj_oppTeamMem.OpportunityId=OpportunityID;
    obj_oppTeamMem.UserId=UserID;
    obj_oppTeamMem.OpportunityAccessLevel=accessRole;
    System.debug(accessRole); 
    obj_oppTeamMem.TeamMemberRole=TeamMemberRole;
    insert obj_oppTeamMem;
}

}