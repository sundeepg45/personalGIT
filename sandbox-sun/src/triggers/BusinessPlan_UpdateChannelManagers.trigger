trigger BusinessPlan_UpdateChannelManagers on SFDC_Channel_Account_Plan__c (before insert,before Update) 
{       List<String> accountIds=new List<String>();
        
        List<SFDC_Channel_Account_Plan__c> updateBPlan=new List<SFDC_Channel_Account_Plan__c> ();
        SFDC_Channel_Account_Plan__c objBP;

        for(Integer i=0;i<Trigger.new.size();i++){
        objBP=(SFDC_Channel_Account_Plan__c)Trigger.new[i];
        accountIds.add(objBP.Partner_Name__c);
        }
        TeamMemberList objTeamList = new TeamMemberList();
        
        List<AccountTeamMember> teamMemberList=objTeamList.getTeamMemberList(accountIds);

        for(Integer i=0;i<Trigger.new.size();i++){
            objBP=(SFDC_Channel_Account_Plan__c)Trigger.new[i];
            for(AccountTeamMember objTeam:teamMemberList)
            {if(objTeam.AccountId==objBP.Partner_Name__c)
            {
            if(objTeam!=null)
            {                     
            if(objTeam.TeamMemberRole=='Channel Account Manager')
                objBP.Responsible_Red_Hat_Account_Manager__c=objTeam.UserId;
            if(objTeam.TeamMemberRole=='Partner Manager')
                objBP.Responsible_Red_Hat_Account_Manager__c=objTeam.UserId;    
            if(objTeam.TeamMemberRole=='Inside Channel Account Manager')
                objBP.ICAM__c=objTeam.UserId;
            if(objTeam.TeamMemberRole=='Channel Marketing Manager - Country')
                objBP.Channel_Field_Marketing_Manager__c=objTeam.UserId;

            objBP.Script_Last_Run_Date__c = system.today();
            }
            }
        }
        }

}