public class FundClaim_RejectionController{


    public final SFDC_MDF_Claim__c FC; 

    public FundClaim_RejectionController(ApexPages.StandardController controller) {

    this.FC = (SFDC_MDF_Claim__c)controller.getRecord();    

    }

public PageReference saveFC(){

        PageReference page=null;

    try
    {
            String actorIdFC=UserInfo.getUserId();
    
            String profileId=UserInfo.getProfileId();
            
            System.debug('ProfileIDDDDDDDDDDDD'+profileId);
            
            String profileName=null;
            
            Profile[] profileObject=[Select Name from Profile where Id=:profileId and Name like 'System Administrator'];
    
            for(Profile temp:profileObject)
            
                { 
                profileName=temp.Name;

                }        

                if(profileName!=null)
                {
                        update FC;
                        
                        ProcessInstance piFC= [Select CreatedDate, Id, Status, TargetObjectId from ProcessInstance  where TargetObjectId  =:FC.Id and Status='Pending' limit 1];
                        
                        List<ProcessInstanceWorkitem> piwiFC = [Select Id, ProcessInstanceId from ProcessInstanceWorkitem  where  ProcessInstanceId =:piFC.Id];  
                        
                        page=new PageReference('/p/process/ProcessInstanceWorkitemWizardStageManager?id='+piwiFC[0].id);      
                }           
                else
                {
                         
                         System.debug('In elseeeee');
                            
                         update FC;
                            
                         ProcessInstance piFC= [Select CreatedDate, Id, Status, TargetObjectId from ProcessInstance  where TargetObjectId  =:FC.Id and Status='Pending' limit 1];
                            
                         List<ProcessInstanceWorkitem> piwiFC = [Select Id, ProcessInstanceId from ProcessInstanceWorkitem  where  ProcessInstanceId =:piFC.Id and ActorId=:actorIdFC];  
                            
                         page=new PageReference('/p/process/ProcessInstanceWorkitemWizardStageManager?id='+piwiFC[0].id);   
                }         
        }    
    catch(Exception e)
    {
        System.debug('Error is'+e);
    }

 return page;
}

}