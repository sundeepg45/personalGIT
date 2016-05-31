public with sharing class MDF_CustomTab {
        
        public Account account { get; set; }
    public List<SFDC_Budget__c> mdfs  { get; set; }
    public Boolean mdfsexist { get; set; }
    
    public MDF_CustomTab()
    {
        Id accountId = null;
                    User me = [select Contact.AccountId from User where Id = :UserInfo.getUserId()];
            accountId = me.Contact.AccountId;
        loadAccount(accountId);
    }
        
        private void loadAccount(Id accountId) {
                
                try {
                        mdfsexist = False;
                     mdfs = [
                select  Id
                     ,  Name
                     ,  Account_master__c
                     ,  Active__c
                     ,  Fiscal_Year__c
                     ,  End_Date__c
                     ,  Start_Date__c
                     ,  Allocated_Budget__c
                     ,  Available_Budget__c
                  from  SFDC_Budget__c
                  where  Account_master__c = :accountId 
                    //where Account_master__c = '001300000094XE4'
                 order by Active__c DESC, Fiscal_Year__c DESC
        ];
                        if(mdfs.size()>0){
                                mdfsexist = True;
                        }
        
         } catch (System.Exception ex) {
            }

         }      
 
          public PageReference loadmdf(){

        return null;
          }
          

      

}