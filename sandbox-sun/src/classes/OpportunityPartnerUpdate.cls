public class OpportunityPartnerUpdate
{

public void updateOpportunityPartnerWorked(Opportunity[] opp)
{
		try
		{
			for(Opportunity obj_Opp:opp)
			{

				// do not run the trigger if opportunity is closed
				if(obj_Opp.StageName =='Closed Won'
					|| obj_Opp.StageName =='Closed Lost'
					|| obj_Opp.StageName =='Closed Booked'
					|| obj_Opp.DateOrderSubmitted__c != null)
					{
						continue;
					}

					User user= Util.currentUser();

					if(user != null)
					{
						obj_Opp.Opportunity_partner_Worked__c='Yes';
						obj_Opp.Opportunity_Last_Modified_by_Partner__c=user.Name;
						obj_Opp.Opportunity_Last_Modified_Date_Time__c=System.now();
					}

				}
		}catch(Exception e){}
}



public static testmethod void test3()
			{
					
					Opportunity[] array_Opp=new Opportunity[1];
					

					Opportunity opp=[Select Id,OwnerId from Opportunity where StageName !='Closed Won' AND StageName !='Closed Lost' AND StageName !='Closed Booked' AND DateOrderSubmitted__c= null limit 1];  
					
					array_Opp[0]=opp;

					new OpportunityPartnerUpdate().updateOpportunityPartnerWorked(array_Opp);

			}



}