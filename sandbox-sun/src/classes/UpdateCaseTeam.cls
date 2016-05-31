/**
 * This class contains logic to add the logged in user to the Case Team if he/she is not already present in the team.
 *
 * Author: Nitesh Dokania
 * Created Date : 10/22/2012
 * Modified Date:
 *
 */

global class UpdateCaseTeam
{
    // This method is being called on click of the button add a new team member to the case team.
    
    WebService static String addUserToCaseTeam(String caseId) 
    {           
        CaseTeamRole teamRole = [Select c.Name, c.Id, c.AccessLevel From CaseTeamRole c where c.Name =: 'Case Admin'];
        
        CaseTeamMember teamMember = new CaseTeamMember ();
        teamMember.TeamRoleId = teamRole.Id;
        teamMember.ParentId = caseId;
        teamMember.MemberId = UserInfo.getUserId();
        
        try
        {
            insert teamMember;
            return null;
        }
        catch(Exception e)
        {
            System.debug('Exceptio'+e.getMessage());
            return e.getMessage();
        }

    }
}