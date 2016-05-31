public class OpportunityBookedErrorClass{
    Opportunity_Header_Staging__c headerStaging;
    
    /**
     * Constructor of the Controller class - Initializes all the variables.
     * Populates forecast quarter data into forecast list
     * @param StandardController
     */    
    public OpportunityBookedErrorClass(ApexPages.StandardController controller) {
        if (!Test.isRunningTest()) { 
             controller.addFields(new List<String>{'Status__c', 'Order_Status__c'});}
        
        headerStaging = (Opportunity_Header_Staging__c)controller.getRecord();                     
    }
    
    public void showErrorMessage(){
        List<Profile> profileList = new List<Profile>();
        profileList = [Select Id, Name from Profile where Id =: UserInfo.getProfileid()];
        
        if(headerStaging.Status__c != 'Error' && headerStaging.Order_Status__c == 'BOOKED' && !profileList.isEmpty() && profileList.get(0).Name != Label.Administrator_Level_1 && profileList.get(0).Name != Label.Administrator_Level_2)
           ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, Label.Order_Status_Not_Error));
        else if(headerStaging.Order_Status__c != 'BOOKED' && !profileList.isEmpty() && profileList.get(0).Name != Label.Administrator_Level_1 && profileList.get(0).Name != Label.Administrator_Level_2)
           ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, Label.Order_Status_Not_Booked));   
    }
}