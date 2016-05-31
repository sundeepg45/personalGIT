public without sharing class BusinessPlan_CustomTab {

    public Integer businessplansize { get; set; }

        public Account account { get; set; }
        public List<SFDC_Channel_Account_Plan__c> businessplans  { get; set; }
        public Boolean businessplansexist { get; set; }
        public id accountId { get; set; }
        
        
        

    public BusinessPlan_CustomTab()
    {
          id  accountId = null;
                    User me = [select Contact.AccountId from User where Id = :UserInfo.getUserId()];
            accountId = me.Contact.AccountId;
             
        loadAccount(accountId);
    }
        
        private void loadAccount(Id accountId) {
                
                try {
                         businessplansexist = False;
                     businessplans = [
                select  Id
                     ,  Name
                     ,  Partner_Name__c
                     , Active__c
              //       , Responsible_Red_Hat_Account_Manager__c
                     , Fiscal_Year__c
                     ,Business_Plan_Number_new__c
                     , Business_Plan_Number__c
                     , Business_Plan_Version__c         
                  from  SFDC_Channel_Account_Plan__c
                      where  Partner_Name__c = :accountId 
      //  where Partner_Name__c = '0016000000cFY29'
                 order by Active__c DESC, Fiscal_Year__c DESC
        ];
        
        businessplansize = businessplans.size();
                        if(businessplansize>0){
                                businessplansexist = True;
                        }
        
         } catch (System.Exception ex) {
            }

         }      
 
          public PageReference loadbp(){

        return null;
          }
          

        

}