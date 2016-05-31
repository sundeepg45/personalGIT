/**
 * I am not really sure what this class does.  It should probably be retired or updated to
 * current coding standards.
 *
 * @version 2013-04-08
 * @author Ratan Sharma (Accenture)
 * 2011-04-28 - Refactored: Separated test class from business class.
 * Modified: Bill Riemers <briemers@redhat.com>
 * 2014-04-19 - Updated to add thread locking and avoid recursion.
 */
public class LeadTaskUpdate {

	Map<String,String> taskOwnerIdMap= new Map<String,String>();
	Map<String,String> taskLeadIdMap= new Map<String,String>();
	Map<String,String> taskOppIdMap= new Map<String,String>();
	List<String> leadIdList= new List<String>();
	List<String> taskOwnerIdList= new List<String>();
	List<Lead> Leadlist= new List<Lead>();

	List<Opportunity> OppList= new List<Opportunity>();
	private static final String updateLeadTaskLock = 'LeadTaskUpdate.updateLeadTask';

	public void updateLeadTask(Task[] ts) {
		if(ThreadLock.lock(updateLeadTaskLock)) {
			try {
				String leadTaskId;
				String taskownerId;
				String taskId;
				String oppTaskId;
				for (Task obj_Task :ts)
				{
					if( obj_Task.RecordTypeId== Util.omCorrectionRequestRecordTypeId
						|| obj_Task.RecordTypeId==Util.omProcessingRecordTypeId ) continue;
	
						leadTaskId=obj_Task.whoId;
						taskownerId=obj_Task.OwnerId;
						taskId=obj_Task.Id;
						oppTaskId=obj_Task.whatId;
				
					// start--removed nuitcase related condition from below if statement for Opp Form cleanup March '11 Release
					if(obj_Task.subject ==  'REMINDER: Renewal Opportunity : close date of opportunity is 90 days from today'
						|| obj_Task.subject == 'Action Required: Opportunity not modified within 30 days')
					{
						continue;
					}
	
					if (leadTaskId != null && leadTaskId.startsWith('00Q'))
					{
						taskOwnerIdMap.put(taskId,taskownerId);
						taskLeadIdMap.put(leadTaskId,taskId);
					}
	
					if(oppTaskId !=null && oppTaskId.startsWith('006'))
					{
						taskOwnerIdMap.put(taskId,taskownerId);
						taskOppIdMap.put(leadTaskId,taskId);
					}
	
				}
				taskleadpartnerUpdate(taskOwnerIdMap,taskLeadIdMap,ts,leadTaskId);
				taskOppPartnerUpdate(taskOwnerIdMap,taskOppIdMap,ts,oppTaskId);
			}
			finally {
				ThreadLock.unlock(updateLeadTaskLock);
			}
		}
	}

	public void taskleadpartnerUpdate(Map<String,String> taskOwnerIdMap,Map<String,String> taskLeadIdMap,Task[] ts,String leadTaskId)
	{
	
		Boolean flag=false;
		try{
	
			User user= Util.currentUser();
			if(user!=null)
			{
				Lead obj_Lead=[Select Id,Partner_Last_Modified_Date_Time__c,Last_Modified_by_Partner__c,Lead_partner_Worked__c from Lead where Id=:leadTaskId];
				obj_Lead.Lead_partner_Worked__c='yes';
				// obj_Lead.Partner_Last_Modified_Date_Time__c=System.now();
				// obj_Lead.Last_Modified_by_Partner__c=user.Name;
				// update obj_Lead;
				flag=true;
				Leadlist.add(obj_Lead);
			}
	
			if(!flag)
			{
	
				Map <String,String> profileMap= new Map<String,String> ();
				List <String> profileList= new List<String> ();
				List <String> leadIds = new List<String>();
				String ownerId = '';
				Map<String,String> partnerLead =new Map<String,String>();
				// List<Lead> leads = new List<Lead>();
	
				if (leadTaskId != null && leadTaskId.startsWith('00Q'))
				{
	
					User[] users= [Select Name,Id,ProfileId from User where Id IN : taskOwnerIdMap.Values() and Profile.Name like '%partner%'];
	
					for(User obj_user:users)
					{
							profileMap.put(obj_user.Id,obj_user.Name);
					}
	
					for (Task obj_Task:ts)
					{
							ownerId =obj_Task.OwnerId;
							if(profileMap.containskey(ownerId))
							{
									partnerLead.put(obj_Task.whoId,profileMap.get(ownerId));
							}
					}
	
					Lead[] leads=[Select Id,Partner_Last_Modified_Date_Time__c,Last_Modified_by_Partner__c,Lead_partner_Worked__c from Lead where Id IN : partnerLead.keyset()];
					for(Lead obj_Lead:leads)
					{
							obj_Lead.Lead_partner_Worked__c='yes';
							obj_Lead.Partner_Last_Modified_Date_Time__c=System.now();
							obj_Lead.Last_Modified_by_Partner__c=partnerLead.get(obj_Lead.Id);
							// update obj_Lead;
							Leadlist.add(obj_Lead);
							// leads.add(obj_Lead);
					}
					update Leadlist;

				}
	
			}
		}
		catch(exception e){}	
	}

	public void taskOppPartnerUpdate(Map<String,String> taskOwnerIdMap,Map<String,String> taskOppIdMap,Task[] ts,String OppTaskId)
	{
		Boolean flag=false;
		try{
			User user= Util.currentUser();
			if(user !=null)
			{
				Opportunity obj_opp=[Select Id,Opportunity_Last_Modified_Date_Time__c,Opportunity_Last_Modified_by_Partner__c,Opportunity_Partner_Worked__c from Opportunity where Id=:OppTaskId];
				// obj_opp.Opportunity_Last_Modified_Date_Time__c=System.now();
				// obj_opp.Opportunity_Last_Modified_by_Partner__c=user.Name;
				obj_opp.Opportunity_Partner_Worked__c='Yes';
				// update obj_opp;
				OppList.add(obj_opp);
				flag=true;
			}
			if(!flag)
			{
				Map <String,String> profileMap= new Map<String,String> ();
				List <String> profileList= new List<String> ();
				List <String> leadIds = new List<String>();
				String ownerId = '';
				Map<String,String> partnerOpp =new Map<String,String>();
				// List<Lead> leads = new List<Lead>();
				if(oppTaskId !=null && oppTaskId.startsWith('006'))
				{
					User[] users= [Select Name,Id,ProfileId from User where Id IN : taskOwnerIdMap.Values() and Profile.Name like '%partner%'];

					for(User obj_user:users)
					{
						profileMap.put(obj_user.Id,obj_user.Name);
					}

					for (Task obj_Task:ts)
					{

						ownerId =obj_Task.OwnerId;
						if(profileMap.containskey(ownerId))
						{
								partnerOpp.put(obj_Task.whatId,profileMap.get(ownerId));
						}
					}

					if(partnerOpp.size()>0)
					{

						Opportunity[] opps=[Select Id,Opportunity_Last_Modified_Date_Time__c,Opportunity_Last_Modified_by_Partner__c,Opportunity_Partner_Worked__c from Opportunity where Id IN:partnerOpp.keySet()];

						for(Opportunity obj_opp:opps)
						{
								obj_opp.Opportunity_Last_Modified_Date_Time__c=System.now();
								obj_opp.Opportunity_Last_Modified_by_Partner__c=partnerOpp.get(obj_opp.Id);
								obj_opp.Opportunity_Partner_Worked__c='Yes';
								// update obj_opp;
								OppList.add(obj_opp);
						}

						update OppList;
					}
				}
			}
		}
		catch(exception e)
		{
		
		}
	}
}