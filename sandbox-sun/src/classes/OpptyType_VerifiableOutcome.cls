/*
Type Name: Class OpptyType_VerifiableOutcome
Created Date: 09/22/2011
Reason: This class is used to create or delete new verifiable outcome records depending on certain conditions.
*/

public class OpptyType_VerifiableOutcome
{   
    Opportunity[] oppNewList = (Opportunity[])Trigger.new;
    Opportunity[] oppOldList = (Opportunity[])Trigger.old;
    Map<Id,Opportunity> oppOldMap = (Map<Id,Opportunity>)Trigger.oldMap;
    List<Opportunity> oppInsertUpdateList = new List<Opportunity>();
    List<Opportunity> oppVODelList = new List<Opportunity>();
    /*List<SalesOperations__c> customSettingObj  = null ;
    Set<Id> profileIdSet = new Set<Id>();*/
    
    // Maximum records that can be inserted at once
    final Integer MAX_RECORDS = 10000;
    
    /*  This method contains conditions on which VO should be created or deleted whenever Oppotuntiy Type changes. And on those conitions calls
        methods for inserting or deleting VO's associated to an Opportunity.
    */    
    public void opportunityTypeVO()
    {    
        /*customSettingObj  = SalesOperations__c.getall().values();      
        for(SalesOperations__c profileId : customSettingObj)
        {
            profileIdSet.add(profileId.ProfileId__c);
        }
        if(profileIdSet.contains(UserInfo.getProfileId()))
            return;
        */
        System.debug('listsize***'+oppNewList);
        for(Integer i=0;i<oppNewList.size();i++)
        {  
            if(oppNewList[i].StageName != 'Closed Lost' && (oppOldList[i].OpportunityType__c != oppNewList[i].OpportunityType__c) && (Util.oppTypeVOSet.contains(oppNewList[i].OpportunityType__c)))
            {
                 oppInsertUpdateList.add(oppNewList[i]);
            }
            else if((Util.oppTypeSet.contains(oppNewList[i].OpportunityType__c)) && (oppOldList[i].OpportunityType__c != oppNewList[i].OpportunityType__c))
            {
                oppVODelList.add(oppNewList[i]);
            }
        }
        System.debug('size****'+oppInsertUpdateList.size());
        if(trigger.isUpdate && oppVODelList.size()>0)
        {
            opportunityTypeDelVO(oppVODelList);
        }
        if(trigger.isUpdate && oppInsertUpdateList.size()>0)
        {
            opportunityTypeCreateVO(oppInsertUpdateList);
        }
    }
    
    //  This method contains logic for inserting new VO's for current Stage as well as for stages prior to current stage on Opportunity.
    public void opportunityTypeCreateVO(List<Opportunity> opportuntiyList)
    {   
        System.debug('inside method***'+opportuntiyList.size());
        List <Verifiable_Outcome__c> outcomeGroup = new List <Verifiable_Outcome__c> ();
        List <Verifiable_Outcome__c> allOutcomeGroup = new List <Verifiable_Outcome__c> ();
        List <Verifiable_Outcome__c> outcomeDelGroup = new List <Verifiable_Outcome__c> ();
        Map <Id,List<Verifiable_Outcome__c>> outcomeOpptyMap = new Map <Id,List<Verifiable_Outcome__c>>();
        Map <String,Verifiable_Outcome__c> dupOutcomeChkMap = new Map <String,Verifiable_Outcome__c> ();
        List <Verifiable_Outcome__c> outcomeToUpdate = new List <Verifiable_Outcome__c> ();
            
        // Creating Map for Opportunity and list of VO's that are associated with that Opoortunity           
        allOutcomeGroup = [Select Id, Due_On__c, Completed__c, Stage__c, Opportunity__c from Verifiable_Outcome__c where Opportunity__c in : opportuntiyList];
        for(Verifiable_Outcome__c vOutcome: allOutcomeGroup) 
        {
            
            if(outcomeOpptyMap.containsKey(vOutcome.Opportunity__c)) 
            {
                List<Verifiable_Outcome__c> lstOutcome =  outcomeOpptyMap.get(vOutcome.Opportunity__c);
                lstOutcome.add(vOutcome);
                outcomeOpptyMap.put(vOutcome.Opportunity__c, lstOutcome);
            }
            else {
                outcomeOpptyMap.put(vOutcome.Opportunity__c, new List<Verifiable_Outcome__c>{vOutcome});
            }
        }
        for(Opportunity opportunity : opportuntiyList)
        {     
            String oppStage = opportunity.StageName;
            if(UserInfo.getUserName().contains(Util.dataCleanupUser) && oppStage.contains('Closed'))
            continue;
            
            Integer indexNew;
            Integer intNew=0;           
            for(String str : Util.stageList)
            {
                if(str == opportunity.StageName)indexNew = intNew;
                intNew++;
            }
            dupOutcomeChkMap.clear();            
            if(outcomeOpptyMap.get(opportunity.Id) != null){
                for(Verifiable_Outcome__c vo : outcomeOpptyMap.get(opportunity.Id)){
                    dupOutcomeChkMap.put(vo.Stage__c,vo);
                }}
                      
            for(Integer i=0;i<Util.stageList.size();i++){
                if(dupOutcomeChkMap.containsKey(Util.stageList.get(i)) && i>indexNew)
                {
                    outcomeDelGroup.add(dupOutcomeChkMap.get(Util.stageList.get(i)));
                }
                else if(dupOutcomeChkMap.containsKey(Util.stageList.get(i)) && i==indexNew)
                {
                    dupOutcomeChkMap.get(Util.stageList.get(i)).Completed__c = null;
                    outcomeToUpdate.add(dupOutcomeChkMap.get(Util.stageList.get(i)));
                }
                else if(!dupOutcomeChkMap.containsKey(Util.stageList.get(i)) && !Util.stageList.get(i).contains('Closed') && i<=indexNew)
                {
                    outcomeGroup.add (new Verifiable_Outcome__c (
                        Opportunity__c = opportunity.Id,
                        Outcome__c = Util.voList.get(i),
                        Stage__c = Util.stageList.get(i),
                        Value_Selling_Stage__c = Util.stageList.get(i)
                    ));
                }
            }            
        }
        if(outcomeGroup!=null && outcomeGroup.size()>0)
        {
            List <Verifiable_Outcome__c> outcomeBatch = new List <Verifiable_Outcome__c> ();        
            for (Verifiable_Outcome__c outcome : outcomeGroup) {        
                outcomeBatch.add (outcome);                
                if (outcomeBatch.size () >= MAX_RECORDS) {            
                    System.debug('veriOutcome'+outcome);            
                    insert outcomeBatch;            
                    outcomeBatch.clear ();        
                }    
            }        
            //    
            // Insert any remaining outcomes    
            //    
            if (outcomeBatch.size () > 0)        
            insert outcomeBatch;
        }
        
        //  updates the VO records after checking the size. If size greater than 10000 then it will updates 10000 records and then updates rest.
        if(outcomeToUpdate!=null)
        {
            List <Verifiable_Outcome__c> outcomeBatchUpdate = new List <Verifiable_Outcome__c> ();        
            for (Verifiable_Outcome__c outcome : outcomeToUpdate) {        
                outcomeBatchUpdate.add (outcome);                
                if (outcomeBatchUpdate.size () >= MAX_RECORDS) {            
                    System.debug('veriOutcome'+outcome);            
                    update outcomeBatchUpdate;            
                    outcomeBatchUpdate.clear ();        
                }    
            }        
            //    
            // Insert any remaining outcomes    
            //    
            if (outcomeBatchUpdate.size () > 0)        
            update outcomeBatchUpdate;
        }
        
        //  updates the VO records after checking the size. If size greater than 10000 then it will updates 10000 records and then updates rest.
        if(outcomeDelGroup!=null)
        {
            List <Verifiable_Outcome__c> outcomeBatchDel = new List <Verifiable_Outcome__c> ();        
            for (Verifiable_Outcome__c outcome : outcomeDelGroup) {        
                outcomeBatchDel.add (outcome);                
                if (outcomeBatchDel.size () >= MAX_RECORDS) {            
                    System.debug('veriOutcome'+outcome);            
                    delete outcomeBatchDel;            
                    outcomeBatchDel.clear ();        
                }    
            }        
            //    
            // Insert any remaining outcomes    
            //    
            if (outcomeBatchDel.size () > 0)        
            delete outcomeBatchDel;
        }
    }
        
    //  This method contains logic for deleting all VO's whenever Opportynity Type changes to one for which VO should not be created. 
    public void opportunityTypeDelVO(List<Opportunity> opptyUpdateList)
    {   
        List <Verifiable_Outcome__c> deloutcomeGroup = new List <Verifiable_Outcome__c> ();
        
        deloutcomeGroup = [Select Outcome__c,Value_Selling_Stage__c from Verifiable_Outcome__c where Opportunity__c in : opptyUpdateList ];
        
        if(deloutcomeGroup!=null && deloutcomeGroup.size()>0)
        {
            List <Verifiable_Outcome__c> outcomeBatch = new List <Verifiable_Outcome__c> ();        
            for (Verifiable_Outcome__c outcome : deloutcomeGroup) {        
                outcomeBatch.add (outcome);                
                if (outcomeBatch.size () >= MAX_RECORDS) {            
                    System.debug('veriOutcome'+outcome);            
                    delete outcomeBatch;            
                    outcomeBatch.clear ();        
                }    
            }        
            //    
            // Insert any remaining outcomes    
            //    
            if (outcomeBatch.size () > 0)        
            delete outcomeBatch;
        }
    }
}