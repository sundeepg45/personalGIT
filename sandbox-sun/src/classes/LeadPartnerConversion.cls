public without sharing class LeadPartnerConversion {
        
    public  Id LeadId {get; set;}
    public  Boolean saved {get; set;}
    public  User CurrentUser {get; set;}
    public  Lead leadToConvert {get; set;}
    public  id leadToConvertId {get; set;}
    public  Database.Leadconvert leadConvert;
    public  Database.LeadConvertResult leadConvertResultList;
    public  Account PartnerAccount  {get;set;}
    public  String opportunityName {get;set;}
    public  Id PartnerAccountRegion {get;set;}
    public  Id DummyContact {get;set;}
    public  List<AccountTeamMember> accountTeamCAM;
    public  List<AccountTeamMember> accountTeamiCAM;
    public  List<AccountTeamMember> accountTeamPAM;
    public  List<AccountTeamMember> accountTeamPSR;
    public  Id salesperson {get;set;}
    public Opportunity newOpportunity {get;set;}
    public Id accountId {get;set;}
    

    public LeadPartnerConversion(ApexPages.StandardController controller) {
         CurrentUser = [Select id, contactid, name from User where id=:UserInfo.getUserId()];
         saved = false;
        // leadToConvert = (Lead)controller.getRecord();
         leadToconvertId = ApexPages.currentPage().getParameters().get('id');
         leadToConvert = [Select 
                          Id, 
                          Ownerid, 
                          Name, 
                          Company, 
                          PartnerAccount.id, 
                          Distributor__c, 
                          Distributor_if_other__c, 
                          JBoss_Products__c, 
                          RHEL_Products__c, 
                          RHEV_Products__c, 
                          Cloud_Products__c, 
                          Sales_Stage__c, 
                          Stage__c,  
                          Project_Name__c, 
                          Partner_Comments__c, 
                          LeadSource, 
                          Customer_ID__c,
                          Original_Renewal_Opportunity__c
                         from Lead 
                         where 
                          id = :leadToconvertId];
    }
    
    public PageReference convertLead() {
    
        String userType = UserInfo.getUserType();
        
        If (userType != 'Standard' && leadToConvert.jBoss_Products__c == null  && leadToConvert.RHEL_Products__c == null && leadToConvert.RHEV_Products__c == null ){
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Please select a product before convert the lead'));
                return Page.LeadPartnerConversion; 
        }
        else if(userType != 'Standard' && leadToConvert.Distributor__c == 'Other' && leadToConvert.Distributor_if_other__c == null ){ 
            
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Please enter the name of the Distributor'));
            return Page.LeadPartnerConversion;
        }
        else {
        
        if (leadToConvert.PartnerAccount != null){
            loadPartnerAccountData(leadtoconvert.PartnerAccount.id);
            //Notifications per Regions EMEA PM / NA iCAM / LATAM -APAC CAM  
            loadSalesPerson(); 
            sendEmail(salesPerson);                
        }
        
        //  Lead Update : (lead stage to Partner Qualified )
        LeadToConvert.Stage__c = 'Partner Qualified';
        update LeadToConvert;

        // Lead conversion
        opportunityName = leadToConvert.Project_Name__c;
        Database.LeadConvert leadConvert = new Database.LeadConvert();
        leadConvert.setConvertedStatus('Converted');
        leadConvert.setDoNotCreateOpportunity(false);
        leadConvert.setLeadId(leadToConvert.Id);
        leadConvert.setSendNotificationEmail(false);
        if (leadToConvert.LeadSource == 'SSI Referral' && leadToConvert.Customer_ID__c != null){
            leadConvert.setAccountId(leadToConvert.Customer_ID__c);
        } else {
            leadConvert.setAccountId(PartnerAccountRegion); // merge into dummy account
            leadConvert.setContactId(DummyContact); // merge into dummy contact
        }
        leadConvert.setOpportunityName(opportunityName);
        Database.LeadConvertResult leadConvertResultList = Database.convertLead(leadConvert);
        newOpportunity = [SELECT Id, Name, OwnerId, FulfillmentChannel__c FROM Opportunity WHERE Id=:leadConvertResultList.getOpportunityId()];
                System.debug('opportunity ID:  ' + newOpportunity.Id);
                System.debug('opportynuity Name' + opportunityName);
        newopportunity.FulfillmentChannel__c = 'Indirect - VAR/VAD';
        newopportunity.pricebook2id = '01s60000000EUnsAAG';
            
        if (leadToConvert.LeadSource == 'SSI Referral' && leadToConvert.Customer_ID__c != null){
            newopportunity.Source_Opportunity_Referrals__c = leadToConvert.Original_Renewal_Opportunity__c;
        }
        update newopportunity;
        saved = true;
        ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO, Label.LeadConversionPageMessageInfo));
        return Page.LeadPartnerConversion; 
        }
    }

     private void sendEmail(Id userId) {   

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setTargetObjectId(userId); //email recipient id
        mail.setReplyTo('noreply@redhat.com');
        mail.setSubject(Label.LeadConversionPageEmailSubject + leadToConvert.Company);
        string leadproducts = '';
        If (leadToConvert.jBoss_Products__c <> null){
            leadproducts += leadToConvert.jBoss_Products__c +' ';
        }
             If (leadToConvert.RHEV_Products__c <> null){
            leadproducts += leadToConvert.RHEV_Products__c +' ';
        }
             If (leadToConvert.RHEL_Products__c <> null){
            leadproducts += leadToConvert.RHEL_Products__c +' ';
        }
             If (leadToConvert.Cloud_Products__c <> null){
            leadproducts += leadToConvert.Cloud_Products__c +' ';
        }
        mail.setHtmlBody(Label.LeadConversionPageEmailBody1 + leadToConvert.Company + Label.LeadConversionPageEmailBody2 + leadToConvert.Id + Label.LeadConversionPageEmailBody3 + ' ' + leadToConvert.Sales_Stage__c + Label.LeadConversionPageEmailBody4 + ' ' + leadToConvert.Distributor__c + Label.LeadConversionPageEmailBody5 + ' ' + leadproducts + Label.LeadConversionPageEmailBody6 + ' ' + leadToConvert.Partner_Comments__c + Label.LeadConversionPageEmailBody7);
        mail.setPlainTextBody('The following lead was converted by a partner '+ leadToConvert.Company +'  Go to the converted lead: https://na4.salesforce.com/' + leadToConvert.Id +  'Sales Stage: '+ leadToConvert.Sales_Stage__c +'  Distributor Name: '+ leadToConvert.Distributor__c +'  Products: '+ leadToConvert.jBoss_Products__c + ' ' + leadToConvert.RHEV_Products__c + ' ' + leadToConvert.RHEL_Products__c + ' ' + leadToConvert.Cloud_Products__c+' Partner Comments: '+ leadToConvert.Partner_Comments__c +' ' );
        mail.saveAsActivity = false;
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail});                  
    }
  
     private void loadPartnerAccountData(id accountid) {   

        PartnerAccount = [Select Id, Name, Global_Region__c, Owner.Id from Account where id=:accountid];   
        List<Account> DummyAccounts = [Select Id, Name, Global_Region__c, PrimaryPartnerContact__c, OwnerId from Account where Name like 'New Opp - Pending ID Assignment%' order by Name];
         
        //Mapping Regions and dummy accounts    
        Map<String, Id> mapGlobalRegion = new Map<String, Id>();
        mapGlobalRegion.put('APAC', DummyAccounts.get(0).id);
        mapGlobalRegion.put('EMEA', DummyAccounts.get(1).id);
        mapGlobalRegion.put('LATAM', DummyAccounts.get(2).id);
        mapGlobalRegion.put('NA', DummyAccounts.get(3).id);
      
        PartnerAccountRegion = mapGlobalRegion.get(PartnerAccount.Global_Region__c);
      
        //Mapping Dummy accounts and Contacts    
        Map<Id, Id> mapAccountContact = new Map<Id, Id>();
        mapAccountContact.put(DummyAccounts.get(0).id,DummyAccounts.get(0).PrimaryPartnerContact__c);
        mapAccountContact.put(DummyAccounts.get(1).id,DummyAccounts.get(1).PrimaryPartnerContact__c);
        mapAccountContact.put(DummyAccounts.get(2).id,DummyAccounts.get(2).PrimaryPartnerContact__c);
        mapAccountContact.put(DummyAccounts.get(3).id,DummyAccounts.get(3).PrimaryPartnerContact__c);
      
        DummyContact = mapAccountContact.get(PartnerAccountRegion);
      
        //Bringing the Sales Team      
        accountTeamCAM = [Select id, AccountId, TeamMemberRole, UserId from AccountTeamMember where AccountId=:leadToConvert.PartnerAccount.Id and TeamMemberRole ='Channel Account Manager' limit 1];
        accountTeamPAM = [Select id, AccountId, TeamMemberRole, UserId from AccountTeamMember where AccountId=:leadToConvert.PartnerAccount.Id and TeamMemberRole ='Partner Manager' limit 1];
        accountTeamiCAM = [Select id, AccountId, TeamMemberRole, UserId from AccountTeamMember where AccountId=:leadToConvert.PartnerAccount.Id and TeamMemberRole ='Inside Channel Account Manager' limit 1];
        accountTeamPSR = [Select id, AccountId, TeamMemberRole, UserId from AccountTeamMember where AccountId=:leadToConvert.PartnerAccount.Id and TeamMemberRole ='PSR' limit 1];
     }
     
     private void loadSalesPerson() {           
        //Assign the Sales Person to the Notifications per Regions EMEA PM / NA iCAM / LATAM -APAC CAM   
        If (PartnerAccount.Global_Region__c == 'EMEA') {
          If  (accountTeamPAM.size() >0) {
              salesPerson = accountTeamPAM.get(0).UserId;
          }
          else {
               salesPerson = PartnerAccount.Owner.Id;
          }    
        }  
        else if (PartnerAccount.Global_Region__c == 'NA'){
          If  (accountTeamPSR.size() >0) {
              salesPerson = accountTeamPSR.get(0).UserId;
          }
          else {
               salesPerson = PartnerAccount.Owner.Id;
          }   
        }   
        else {
           If  (accountTeamCAM.size() >0) {
              salesPerson = accountTeamCAM.get(0).UserId;
          }
          else {
               salesPerson = PartnerAccount.Owner.Id;
          }     
        }
    }
}