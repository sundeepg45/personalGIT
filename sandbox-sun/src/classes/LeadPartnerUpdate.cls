public class LeadPartnerUpdate {

	public void updateLeadPartnerWorked(Lead[] ld) {
		try {
			for(Lead obj_Lead:ld) {
				User user= Util.currentUser();
		
				if(user != null) {
					obj_Lead.Lead_partner_Worked__c='yes';
					obj_Lead.Last_Modified_by_Partner__c=user.Name;
					obj_Lead.Partner_Last_Modified_Date_Time__c=System.now();
				}
			}
		}
		catch(Exception e) {
			System.debug('Exception is => ' + e.getMessage());
		}
	}

	public static testmethod void test3() {
		User adminuser = [Select Id, FirstName, LastName from User where Profile.Name = 'System Administrator' and isActive = true limit 1];
		
		Lead[] array_Lead=new Lead[1];
        Lead objLead=new Lead();
       	objLead.Company='Accenture';
		objLead.OwnerId=adminuser.Id; //Util.ldPartnerUser;
		objLead.LastName ='TestR4DeployLead';
		objLead.Title='R4';
		objLead.LeadSourceDetail__c='APAC World Tour';
        objLead.Status='New';
        objLead.Products_of_Interest__c='JBoss';
        objLead.Partner_Opt_In__c=true;
        objLead.Email='Paresh@gmail.gov';
        objLead.Country='UK';
        array_Lead[0]=objLead;
        insert array_Lead;
        new LeadPartnerUpdate().updateLeadPartnerWorked(array_Lead);
    }

}