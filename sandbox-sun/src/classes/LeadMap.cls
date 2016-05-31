/**
* Class Name:LeadMap
* Author:Accenture
* Description:Used for returing ID of a queue passed from any routing class.
* Modificaton History:
* Modified By : Ratan Sharma
* Modified date :4/29/2011
* Reason for Modification:Separated test class from business class.
*/

public class LeadMap {

	Map<String,String> queues = null;

	//deployment class
	public static boolean dbbyPass = false;


	public void setMap()
	{
		getQueueId('');
	}

	public String getQueueId(String queueName)
	{
		String queueId = null;
		if(queues == null)
		{
			queues = new Map<String,String>();
			Group[] groups =[Select Id,Name from Group where type='Queue' ];
			for(Group gp:groups)
			{
				if(LeadMap.dbbyPass) continue;
				    
				queues.put(gp.Name,gp.Id);
			}
	
		}
		if(queues != null) queueId = queues.get(queueName);
		return queueId;
	}
}