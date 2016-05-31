/*
Type Name: Class Opportunity_VerifiableOutcome
Created Date: 09/22/2011
Reason: This class is used to create or delete new verifiable outcome records depending on certain conditions.
*/

public class Opportunity_VerifiableOutcome
{   
    // Maximum records that can be inserted at once
    final Integer MAX_RECORDS = 10000;
    
    // Maximum latency time to restrict double-entry bug
    final Integer MAX_LATENCY = 2;
    
    // Default time if not defined by the ideal sales time matrix
    final Integer DEFAULT_IDEAL_TIME = 4;
    
    Opportunity[] oppNewList = (Opportunity[])Trigger.new;
    Opportunity[] oppOldList = (Opportunity[])Trigger.old;
    Map<Id,Opportunity> oppOldMap = (Map<Id,Opportunity>)Trigger.oldMap;
    List<Opportunity> oppInsertUpdateList = new List<Opportunity>();
    String currentLogInUser = UserInfo.getUserName();
    
    /*  This method contains conditions which checks weather VO should be created for particular Opportunity and if so then calls appropriate 
        method for creating VO's
    */
    public void opportunityVO()
    {
        
        // checking for opportunity type for which VO should not get created
        for(Integer i=0;i<oppNewList.size();i++)            
        {
            //
            // Exclude opportunities if Stage is 'Closed Lost' or Opportunity Type is not proper
            //
            if(oppNewList[i].StageName == 'Closed Lost' || Util.oppTypeSet.contains(oppNewList[i].OpportunityType__c))
            continue;
            
            oppInsertUpdateList.add(oppNewList[i]);
        }
        if(trigger.isBefore && trigger.isUpdate && oppInsertUpdateList.size() > 0)
        {
            // Method called when Opportunity is updated and VO should get created.
            oppUpdateVO(oppInsertUpdateList);
        }
        if(trigger.isAfter && trigger.isInsert && oppInsertUpdateList.size() > 0)
        {
            // Method called when Opportunity is inserted and VO should get created.
            oppInsertVO(oppInsertUpdateList);
        }
    }    
     
    // Batch list for insert
    List <Verifiable_Outcome__c> outcomeGroup = new List <Verifiable_Outcome__c> ();
    List <String> outcomeSatgeDelList = new List<String>();
    List <Verifiable_Outcome__c> outcomeDelGroup = new List <Verifiable_Outcome__c> ();
    List <Verifiable_Outcome__c> outcomeDelList = new List <Verifiable_Outcome__c> ();
    List <Verifiable_Outcome__c> outcomeToUpdate = new List <Verifiable_Outcome__c> ();
    List <Verifiable_Outcome__c> allOutcomeGroup = new List <Verifiable_Outcome__c> ();
    Map <String,Verifiable_Outcome__c> dupOutcomeChkMap = new Map <String,Verifiable_Outcome__c> ();
    //List <Verifiable_Outcome__c> allOppOutcome = new List <Verifiable_Outcome__c> ();
    Map <Id,List<Verifiable_Outcome__c>> outcomeOpptyMap = new Map <Id,List<Verifiable_Outcome__c>>();
        
    /*  This method contains logic for creating parameters to create VO when Opportunity Stage changes and then calls the appropriate method
        to create VO.
    */      
    public void oppUpdateVO(List<Opportunity> oppUpdateList)
    {
        // Creating Map for Opportunity and list of VO's that are associated with that Opoortunity           
        allOutcomeGroup = [Select Id, Due_On__c, Completed__c, Stage__c, Opportunity__c from Verifiable_Outcome__c where Opportunity__c in : oppUpdateList];
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
        System.debug('outcomeOpptyMap&&&&'+outcomeOpptyMap);
        for (Opportunity opportunity : oppUpdateList) {
            Integer indexNew = 0;
            Integer indexOld = 0;
            Integer intNew = 0;
            Integer intOld = 0;
            
            // checks if stage changed or not and old Opportuntiy Type should not be equal to one for which VO should  not get created.
            if (opportunity.StageName == oppOldMap.get(opportunity.Id).StageName || Util.oppTypeSet.contains(oppOldMap.get(opportunity.Id).OpportunityType__c))
                continue;
                
            // getting index of new Stage and Old stage
            for(String str : Util.stageList)
            {
                if(str == opportunity.StageName)indexNew = intNew;
                    intNew++;
                if(str == oppOldMap.get(opportunity.Id).StageName)indexOld = intOld;
                    intOld++;               
            }
            System.debug('indexNew**'+indexNew);
            System.debug('indexOld**'+indexOld);
            Boolean flag = false;
            dupOutcomeChkMap.clear();
            if(outcomeOpptyMap.get(opportunity.Id) != null){
                for(Verifiable_Outcome__c vo : outcomeOpptyMap.get(opportunity.Id)){
                    dupOutcomeChkMap.put(vo.Stage__c,vo);
                }}
            /*  method called to create VO's as desired by passing parameters. Parameters are (current stage index,old stage index and current 
                opportunity record
            */ 
            oppUpdateInsertVO(indexNew,indexOld,opportunity);
        }
        
        //  inserts the VO records after checking the size. If size greater than 10000 then it will inserts 10000 records and then inserts rest.
        if(outcomeGroup.size()>0)
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
            System.debug('insert in class -- outcomeGroup --- '+outcomeGroup);
        }
        
        //  deletes the VO records after checking the size. If size greater than 10000 then it will deletes 10000 records and then deletes rest.
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
    }
    
    //  This method accepts parameters and create VO records to insert for corresponding stages.
    public void oppUpdateInsertVO(Integer indexNew,Integer indexOld,Opportunity opportunity)
    {
        //outcomeDelGroup = outcomeOpptyMap.get(opportunity.Id);
        System.debug('outcomeDelGroup****'+dupOutcomeChkMap.values());
        if((dupOutcomeChkMap.values() == null || dupOutcomeChkMap.values().size() == 0) && opportunity.StageName == Util.stageList.get(0))
        {
            outcomeGroup.add (new Verifiable_Outcome__c (
                Opportunity__c = opportunity.Id,
                Outcome__c = Util.voList.get(indexNew),
                Stage__c = Util.stageList.get(indexNew),
                Value_Selling_Stage__c = Util.stageList.get(indexNew)
            ));
        }
        else{
            Integer outcomeSize = dupOutcomeChkMap.values().size();
            System.debug('inside elsee^^^');
            Integer indexToRemove;
            Integer intRemove = 0;
            System.debug('outcomeDelGroup.size()****'+dupOutcomeChkMap.values().size());                   
            for(Integer i=0;i<Util.stageList.size();i++){
                if(dupOutcomeChkMap.containsKey(Util.stageList.get(i)) && i>indexNew)
                {
                    System.debug('inside delete');
                    outcomeDelGroup.add(dupOutcomeChkMap.get(Util.stageList.get(i)));
                }
                else if(dupOutcomeChkMap.containsKey(Util.stageList.get(i)) && i==indexNew)
                {
                    System.debug('newStage***'+Util.stageList.get(indexNew));
                    System.debug('newStageIndex**'+indexNew);
                    dupOutcomeChkMap.get(Util.stageList.get(i)).Completed__c = null;
                    outcomeToUpdate.add(dupOutcomeChkMap.get(Util.stageList.get(i)));
                    //indexToRemove = intRemove;              
                    System.debug('indexToRemove***'+indexToRemove);
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
    }
    
    //  This method contains logic for creating VO records when Opportuntiy is inserted into the system.
    public void oppInsertVO(List<Opportunity> oppInsertList)
    {
        System.debug('OutcomeGroup**'+outcomeGroup.size()); 
        // logic execute during insert of Opportuntiy.
        
        for (Opportunity opportunity : oppInsertList) 
        {
            if(opportunity.StageName != Util.stageList.get(0))
                continue;
            System.debug('after insert');
           
            //
            // Create the verifiable outcome and add to the batch list
            //
            outcomeGroup.add (new Verifiable_Outcome__c (
                Opportunity__c = opportunity.Id,
                Outcome__c = opportunity.Verifiable_Outcome__c,
                Stage__c = opportunity.StageName,
                Value_Selling_Stage__c = opportunity.Value_Selling_Stage__c
            ));
        }
        if(outcomeGroup.size()>0)
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
    }
}