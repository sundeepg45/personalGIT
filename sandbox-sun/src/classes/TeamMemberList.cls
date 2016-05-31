public class TeamMemberList
{
public List<AccountTeamMember> getTeamMemberList(List<String> accountIds)
{
    List<AccountTeamMember> teamMemberMap=new List<AccountTeamMember>();
    List<AccountTeamMember> Bp_Account =[Select AccountId,TeamMemberRole,UserId from AccountTeamMember where AccountId IN :accountIds and TeamMemberRole IN ('Channel Account Manager' ,'Inside Channel Account Manager', 'Marketing Program Manager', 'Partner Manager','Channel Marketing Manager - Country')];
    for(AccountTeamMember objTeamMember:Bp_Account)
    {
      teamMemberMap.add(objTeamMember);
    }
    return teamMemberMap;
    }
}