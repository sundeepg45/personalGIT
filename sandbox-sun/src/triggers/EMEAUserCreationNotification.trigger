trigger EMEAUserCreationNotification  on User (after insert)
{
	String role = '';
	for( User u : Trigger.new) {
//		if( Trigger.isInsert || (Trigger.isUpdate && UserInfo.getProfileId()==Util.ApexDeployment))
//		{
			if(u.Region__c == 'EMEA') {
				EMEAUserNotification.createMail(u);	
			}
//		}
	}
}