/**
 * Opportunity_UpdateContractStage
 * @see Opportunity
 * @version 2.0
 * @author Amruta Joshi-App Maintainanace March Release.
 * @modified by Gaurav Gupte - App Maintenance March Release.
 */

trigger Opportunity_UpdateContractStage on Opportunity (after update)
{
    if(BooleanSetting__c.getInstance('DeactivateAll') != null && BooleanSetting__c.getInstance('DeactivateAll').Value__c == true) return;
   
        //
        //List of contracts if the Opportunity stage is Closed Booked, Closed Won or Closed Lost.
        //
        List<Opportunity> oppList = new List<Opportunity>();
        for (Opportunity opp : Trigger.new){
            if (opp.StageName == 'Closed Lost' || opp.StageName == 'Closed Won' || opp.StageName == 'Closed Booked'){
                oppList.add(opp);
            }
        }
        
        if (oppList.isEmpty()){
            return;
        }

        Contract[] contractList = [ select Id, Completed_Date__c from Contract 
                                where Opportunity__c 
                                in :oppList];
    
      //
      // Update Status, Stage of those contracts to 'Completed' and populate Completed Date with current date.
      //

     for(Contract contract : contractList)
     {
         contract.Status = 'Completed';
         contract.Stage__c = 'Completed';
         if(contract.Completed_Date__c == null)
         {
            contract.Completed_Date__c = System.now();
         }
     }

     if (contractList.size() != 0)
     update contractList;
}