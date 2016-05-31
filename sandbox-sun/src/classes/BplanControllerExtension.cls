public class BplanControllerExtension 
{
    private final SFDC_Channel_Account_Plan__c bplan;
    private final SFDC_Channel_Account_Plan__c planInfo;
    private final Account accInfo;

     String Id;

        // The extension constructor initializes the private member
        // variable acct by using the getRecord method from the standard
        // controller.
        public BplanControllerExtension (ApexPages.StandardController stdController) 
        {
            this.bplan = (SFDC_Channel_Account_Plan__c)stdController.getRecord();
            Id=stdController.getRecord().id;
            planInfo=[Select Id,Name,Partner_Name__c from SFDC_Channel_Account_Plan__c where Id=:Id];
           //included this debug because of an Apex error recived that cannot be replicated 
            System.Debug('id:' + Id);
            accInfo=[Select Id,Name, Subregion__c, Global_Region__c from Account where Id=:planInfo.Partner_Name__c];
        }
    
            public String getBusinessPlanName() 
            {
                return planInfo.Name;
            }

            public String getAccountName() 
            {
                return accInfo.Name;
            }

        public PageReference CampaignPage() 
    {
        String recordType;
    	RecordType rt  =  new RecordType();
    
    	if(accInfo.Subregion__c == 'Fed Sled')
    		rt = [select id from RecordType where RecordType.Name = 'Fed Sled Campaign Plan'];
    	else if(accInfo.Global_Region__c =='APAC')
    		rt = [select id from RecordType where RecordType.Name = 'APAC Campaign Plan'];	
    	else
    		rt = [select id from RecordType where RecordType.Name = 'NA Campaign Plan'];	
    	
    	
    	recordType = rt.id;
    		
    	
        // Send the user to the detail page for the new Campaign.
        PageReference acctPage = new PageReference('/'+'a17/e?retURL=/'+planInfo.Id+'&cancelURL=/'+planInfo.Id+'&ent=Campaign_Plan__c&CF00N60000001ezKv='+
        planInfo.Name+'&CF00N60000001ezKq='+accInfo.Name + '&RecordType='+ recordType);
        acctPage.setRedirect(true);
        return acctPage;
    }

     public PageReference ObjectivePage() 
    {
        // Send the user to the detail page for the new Objective.
        PageReference objectPage = new PageReference('/'+'a14/e?retURL=/'+planInfo.Id+'&cancelURL=/'+planInfo.Id+'&ent=Campaign_Plan__c&CF00N60000001eql7='+
        planInfo.Name+'&CF00N60000001eqkQ='+accInfo.Name);
        objectPage.setRedirect(true);
        return objectPage;
    }

      public PageReference RedhatTeamPage() 
    {
        // Send the user to the detail page for the new RedhatTeam.
        PageReference teamPage = new PageReference('/'+'a15/e?retURL=/'+planInfo.Id+'&cancelURL=/'+planInfo.Id+'&ent=Campaign_Plan__c&CF00N60000001eqlW='+
        planInfo.Name+'&CF00N60000001eqkR='+accInfo.Name);
        teamPage.setRedirect(true);
        return teamPage;
    }
    
    public PageReference keyJointPage() 
    {
        // Send the user to the detail page for the new Key Joint Sales Engagement.
        PageReference keyJntPage = new PageReference('/'+'a12/e?retURL=/'+planInfo.Id+'&cancelURL=/'+planInfo.Id+'&ent=Campaign_Plan__c&CF00N60000001eqkS='+
        planInfo.Name+'&CF00N60000001eqkO='+accInfo.Name);
        keyJntPage.setRedirect(true);
        return keyJntPage;
    }
    
    public static testMethod void testBplanControllerExtension() 
     {
        Account acc=[Select Id from Account where isAccountActive__c=true limit 1];

        SFDC_Channel_Account_Plan__c Bplan=new SFDC_Channel_Account_Plan__c();
        Bplan.Partner_Name__c= acc.Id; 
        Bplan.Name='test';
        Bplan.Fiscal_Year__c='FY2009';
        insert Bplan; 
        
        ApexPages.StandardController testController=new ApexPages.StandardController(Bplan);

        PageReference pageRef = new PageReference('Page.BusinessPlanNextSteps');

        BplanControllerExtension BplanControllerExtensionObj=new BplanControllerExtension(testController);

        BplanControllerExtensionObj.CampaignPage();
        BplanControllerExtensionObj.ObjectivePage();
        BplanControllerExtensionObj.RedhatTeamPage();
        BplanControllerExtensionObj.keyJointPage();
        BplanControllerExtensionObj.getBusinessPlanName();
        BplanControllerExtensionObj.getAccountName();
        
   
     }
    
}