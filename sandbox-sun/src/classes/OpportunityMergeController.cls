/*****************************************************************************************
    Name    : OpportunityMergeController
    Desc    : Controller class for  OpportunityMerge Page
                            
Modification Log : 
---------------------------------------------------------------------------
 Developer                Date                 Description
---------------------------------------------------------------------------
 Pankaj Banik             8 Jan, 2015         Created (US61164)
******************************************************************************************/
public class OpportunityMergeController
{ 
    //Variable declarations
    //Stores list of all source Opportunities for selection
    public List<opportunityWrapper> sourceOpportunities {get;set;}
    //Stores list of all source Opportunities for selection
    public List<opportunityDisplayWrapper> displayOpportunities {get;set;}
    //Stores the selected source opportunity for merge operation
    public Opportunity selectedSourceOpportunity {get;set;} 
    //Stores the target opportunity for merge operation
    public Opportunity targetOpportunity {get;set;} 
    //Stores condition true or false for displaying to be merge opportunities section
    public Boolean panelOpportunitySelected {get;set;}
    //Stores condition true or false for displaying the page   
    public Boolean pageVisible {get;set;}
    //Stores condition true or false for displaying error section in page
    public Boolean pageErrorVisible {get;set;}
    //Stores exception messages
    public String exceptionMessage {get;set;}
    //Stores Account id of target Opportunity
    private String accountId ; 
    //Stores Opportunity id sent by URL
    private String targetOpportunityId ;     
    
    // Wrapper Class for Source Opportunity
    public class opportunityWrapper
    {
        //Stores Opportunity record
        public Opportunity opportunity {get;set;}
        //Stores Value of radio button
        public Boolean radioButton{get;set;}
    }
    
    // Wrapper Class for displaying source and target Opportunity
    public class opportunityDisplayWrapper
    {
        //Stores Opportunity record
        public Opportunity opportunity {get;set;}
        //Stores Value of radio button
        public String type{get;set;}
    }
    
    //Constructor
    public OpportunityMergeController()
    {   
        //Fetch Target Opportunity Id
        targetOpportunityId = apexpages.currentpage().getParameters().get('Id');
        
        //Query Target opportunity details
        targetOpportunity = [SELECT Name,
            StageName,
            Amount,
            RecordTypeID,
            RecordType.Name,
            Type,
            CloseDate,
            PaymentType__c,
            FulfillmentChannel__c,
            Country_of_Order__c,
            OwnerId,
            AccountId,
            OriginalOpportunity__c,  
            Owner.Name,
            CurrencyIsoCode,Pay_Now__c,
            Country_of_Order_Formula__c,
            Deal_Registration__c,
            LeadSourceDetail__c,
            SSI_In_Scope__c,
            Source_Opportunity__c,
            Renewal_Opportunity__c,
            New_Business__c,
            Teaming_Agreement__c,
            NA_Reseller__c,
            Year1PaymentAmount__c,
            Year2PaymentAmount__c,
            Year3PaymentAmount__c,
            Year4PaymentAmount__c,
            Year5PaymentAmount__c,
            Year6PaymentAmount__c
            FROM Opportunity WHERE id = :targetOpportunityId];
        
        //Get Account id of Target opportunity    
        accountId = targetOpportunity.AccountId;
        // Display Page
        panelOpportunitySelected=false;
        pageVisible = true;
        pageErrorVisible = false;
        
        sourceOpportunities = new List<opportunityWrapper>();
        //Query for all open source opportunities for that account
        for(Opportunity opportunity:[SELECT 
                                                Name,
                                                StageName,
                                                Amount,
                                                RecordTypeID,
                                                RecordType.Name,
                                                Type,
                                                CloseDate,
                                                PaymentType__c,
                                                FulfillmentChannel__c,
                                                Country_of_Order__c,
                                                OwnerId,
                                                Account.Id,
                                                OpportunityNumber__c,
                                                Owner.Name,
                                                CurrencyIsoCode,Pay_Now__c,
                                                Country_of_Order_Formula__c,
                                                Deal_Registration__c,
                                                LeadSourceDetail__c,
                                                SSI_In_Scope__c,
                                                Source_Opportunity__c,
                                                Renewal_Opportunity__c,
                                                New_Business__c,
                                                Teaming_Agreement__c,
                                                NA_Reseller__c,
                                                Year1PaymentAmount__c,
                                                Year2PaymentAmount__c,
                                                Year3PaymentAmount__c,
                                                Year4PaymentAmount__c,
                                                Year5PaymentAmount__c,
                                                Year6PaymentAmount__c
            FROM Opportunity WHERE (StageName NOT IN ('Closed Lost','Closed Won','Closed Booked','Closed Won - Partner')   AND OracleOrderNumber__c = '') AND opportunity.account.id =:accountId])
        {   
            //Initialize Wrapper instance
            opportunityWrapper opportunityWrapperRecord = new opportunityWrapper();
            //Add opportunity record
            opportunityWrapperRecord.opportunity = opportunity;
            opportunityWrapperRecord.radioButton = false ;
            
            //add record to list of source opportunities
            sourceOpportunities.add(opportunityWrapperRecord);
            
        }
        
    }
    
    //Logic for Merge validation to be executed on pageLoad
    public void validateMerge()
    {
        if (targetOpportunity.OriginalOpportunity__c != null){
            pageVisible = false;
            pageErrorVisible = true;
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL,'This opportunity has been merged already. Please click on back button to navigate to the previous opportunity.'));
        }
    }
    
    //Logic to be executed on cleck on Select source opportunity button
    public void onSelectButtonClick()
    {   
        // Set display to true for compare target and scource opportunity records table
        panelOpportunitySelected=true;
        displayOpportunities = new List<opportunityDisplayWrapper>();
        //Retrieve Selected source Opportunity
        for(OpportunityWrapper selectedOpportunity:sourceOpportunities)
        {
            if(selectedOpportunity.radioButton == true)
            {                    
                selectedSourceOpportunity = selectedOpportunity.opportunity;
                opportunityDisplayWrapper target = new opportunityDisplayWrapper();
                opportunityDisplayWrapper source = new opportunityDisplayWrapper();
                target.type = 'Target opportunity';
                target.opportunity = targetOpportunity ;
                displayOpportunities.add(target);
                source.type = 'Source opportunity';
                source.Opportunity = selectedSourceOpportunity ;
                displayOpportunities.add(source);
            }
        }
        
    }
    
    //Logic on Click of merge Button
    public Pagereference onMerge(){
        
        Savepoint sp = Database.setSavepoint();
        Boolean opportunityUpdateSuccess = updateOpportunities(sp);
        System.debug('opportunityUpdateSuccess----->'+opportunityUpdateSuccess);
        
        if (!opportunityUpdateSuccess){
            System.debug('Inside Update opp check----->');
            pageVisible = false ;
            panelOpportunitySelected = false ;
            return NULL;
        }
        else{
            Boolean partnersSuccessFlag = copyOpportynityPartners(sp);
            System.debug('partnersSuccessFlag----->'+partnersSuccessFlag);
            Boolean teamsSuccessFlag = copyOpportunityTeamMembers(sp);
            System.debug('teamsSuccessFlag----->'+teamsSuccessFlag);
            Boolean splitsSuccessFlag = copyOpportunitySplits(sp);
            System.debug('splitsSuccessFlag----->'+splitsSuccessFlag);
            Boolean opportunityHistorySuccessFlag = createOpportunityHistoryTracking(sp);
            
            if(!partnersSuccessFlag || !teamsSuccessFlag || !splitsSuccessFlag || !opportunityHistorySuccessFlag){
                System.debug('inside child upsert check----->');
                pageVisible = false ;
                panelOpportunitySelected = false ;
                return NULL;
            }
            else
            {
                System.debug('Redirect----->');
                PageReference ref =  new PageReference('/'+targetOpportunityid);
                return ref ;
            }   
        } 
    }
    
    //Logic for Updating Source and Target opportunities
    private Boolean updateOpportunities(Savepoint sp){
        
        // Update Target opportunity details from Source Opportunity
        targetOpportunity.Deal_Registration__c = selectedSourceOpportunity.Deal_Registration__c ;
        targetOpportunity.LeadSourceDetail__c = selectedSourceOpportunity.LeadSourceDetail__c ;
        targetOpportunity.SSI_In_Scope__c = selectedSourceOpportunity.SSI_In_Scope__c ;
        targetOpportunity.New_Business__c = selectedSourceOpportunity.New_Business__c ;
        targetOpportunity.Name = selectedSourceOpportunity.Name ;
        targetOpportunity.Owner = selectedSourceOpportunity.Owner ;
        targetOpportunity.NA_Reseller__c = selectedSourceOpportunity.NA_Reseller__c ;
        targetOpportunity.Teaming_Agreement__c = selectedSourceOpportunity.Teaming_Agreement__c ;
        targetOpportunity.Source_Opportunity__c = selectedSourceOpportunity.Source_Opportunity__c ;
        targetOpportunity.Renewal_Opportunity__c = selectedSourceOpportunity.Renewal_Opportunity__c ;
        targetOpportunity.OriginalOpportunity__c  = selectedSourceOpportunity.id ;
        targetOpportunity.OwnerId= selectedSourceOpportunity.OwnerId ;
        targetOpportunity.Year1PaymentAmount__c = selectedSourceOpportunity.Year1PaymentAmount__c ;
        targetOpportunity.Year2PaymentAmount__c = selectedSourceOpportunity.Year2PaymentAmount__c ;
        targetOpportunity.Year3PaymentAmount__c = selectedSourceOpportunity.Year3PaymentAmount__c ;
        targetOpportunity.Year4PaymentAmount__c = selectedSourceOpportunity.Year4PaymentAmount__c ;
        targetOpportunity.Year5PaymentAmount__c = selectedSourceOpportunity.Year5PaymentAmount__c ;
        targetOpportunity.Year6PaymentAmount__c = selectedSourceOpportunity.Year6PaymentAmount__c ;
        targetOpportunity.FinancialPartner__c = null ;
        targetOpportunity.ResellerPartner__c = null ;
        
        //Update source opportunity details
        selectedSourceOpportunity.Deal_Registration_Expired__c = false;
        selectedSourceOpportunity.Opportunity_Reference_Name__c = targetOpportunity.id;
        selectedSourceOpportunity.StageName = 'Closed Lost';
        selectedSourceOpportunity.Reason_Closed_Lost_Marketing__c = 'Duplicate Opp';
        selectedSourceOpportunity.ReasonWonLostSalesProcess__c = 'Duplicate Opp';
        
        //DML operations to update source and target opportunity
        try{
           List<Opportunity> opportunitiesForUpdate = new List<Opportunity>();
           opportunitiesForUpdate.add(targetOpportunity);
           opportunitiesForUpdate.add(selectedSourceOpportunity);
           UPDATE opportunitiesForUpdate;
           System.debug('selectedSourceOpportunity----->'+selectedSourceOpportunity);
           System.debug('targetOpportunity----->'+targetOpportunity);
        }
        catch(Exception e)
        {
            Database.rollback( sp );
            pageErrorVisible = true;
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL,e.getMessage()));
        }
        
        if (pageErrorVisible)
            return false;
        else 
            return true;
    }
    
    //Logic for Creating Opportunity History Tracking Record
    private Boolean createOpportunityHistoryTracking(Savepoint sp){
        //Create Opportunity History record to track Merge 
        Opportunity_History__c opportunityHistory = new Opportunity_History__c();
        opportunityHistory.Opportunity__c= targetOpportunity.id;
        opportunityHistory.Opportunity_Type__c = 'Merged Into:'+selectedSourceOpportunity.OpportunityNumber__c;
        
        try {
            INSERT opportunityHistory;
        }
        catch(Exception e)
        {
            Database.rollback( sp );
            pageErrorVisible = true;
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL,e.getMessage()));
        }
        if (pageErrorVisible)
            return false;
        else 
            return true;
    }
    
    //Logic for Copying Opportunity Partners from Source to Target
    private Boolean copyOpportynityPartners(Savepoint sp){
        
        //Query records of Opportunity Partners of Target and Source opportunities
        List<OpportunityPartner__c> opportunityPartners= [SELECT Opportunity__c,Oracle_Classification_Code__c,PartnerName__c,PartnerSubTypeName__c,PartnerTierName__c,PartnerTier__c,PartnerTypeHierarchy__c,PartnerTypeName__c,PartnerType__c,Partner_Contact__c,Partner__c,RelationshipType__c FROM OpportunityPartner__c WHERE opportunity__c =:targetOpportunity.Id or opportunity__c =:selectedSourceOpportunity.Id];
        System.debug('opportunityPartners----->'+opportunityPartners);
        List<OpportunityPartner__c> deletePartners = new List<OpportunityPartner__c>();
        List<OpportunityPartner__c> newPartners = new List<OpportunityPartner__c>();
        
        for (OpportunityPartner__c partner :opportunityPartners){
            if (partner.Opportunity__c == targetOpportunity.id)
                deletePartners.add(partner);
            else {
                OpportunityPartner__c newpartner = new OpportunityPartner__c();
                newPartner = partner.clone(false);
                newPartner.Opportunity__c = targetOpportunityId;
                newPartners.add(newPartner);
            }
        }
        
        try {
            //DML
            if(!deletePartners.isEmpty()){
                DELETE deletePartners;
            }
            if(!newPartners.isEmpty()){
                System.debug('newPartners----->'+newPartners);
                INSERT newPartners;
            }
        }
        catch(Exception e)
        {
            Database.rollback( sp );
            pageErrorVisible = true;
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL,e.getMessage()));
        }
        if (pageErrorVisible)
            return false;
        else 
            return true;
        
    }
    
    //Logic for Copying Opportunity TeamMembers from Source to Target
    private Boolean copyOpportunityTeamMembers(Savepoint sp){
        
        try {
            //Query Split records of Target opportunity
            List<OpportunitySplit> targetSplits = [Select SplitOwnerId,OpportunityId,SplitPercentage from OpportunitySplit where OpportunityId =: targetOpportunity.id and SplitOwnerId !=: targetOpportunity.OwnerId];
            System.debug('targetSplits----->'+targetSplits);
            
            //Delete all non Owner Split Records
            if(!targetSplits.isEmpty()){
                DELETE targetSplits;
                System.debug('targetSplits deleted----->');
            }
            
            //Query Team member records of target and Source opportunity
            List<OpportunityTeamMember> teamMembers = [SELECT OpportunityAccessLevel,OpportunityId,TeamMemberRole,UserId FROM OpportunityTeamMember WHERE opportunityId=:targetOpportunity.id OR opportunityId=:selectedSourceOpportunity.id ];
            System.debug('teamMembers----->'+teamMembers);
            List<OpportunityTeamMember> targetTeamMembers = new List<OpportunityTeamMember>();
            List<OpportunityTeamMember> newTeamMembers = new List<OpportunityTeamMember>();
            
            for(OpportunityTeamMember teamMember : teamMembers){
                //Selecting Non owner teammember records for delete
                if(teamMember.opportunityId == targetOpportunity.id && teamMember.OpportunityAccessLevel != 'All'){
                    targetTeamMembers.add(teamMember);
                    System.debug('teamMember Owner----->'+teamMember);
                }
                //Copying Source Opportunity Team member records
                else if (teamMember.OpportunityId == selectedSourceOpportunity.id && teamMember.OpportunityAccessLevel != 'All'){
                    System.debug('teamMember----->'+teamMember);
                    OpportunityTeamMember newTeamMember = new OpportunityTeamMember();
                    newTeamMember.TeamMemberRole = teamMember.TeamMemberRole ;
                    newTeamMember.UserId = teamMember.UserId ;
                    newTeamMember.OpportunityId = targetOpportunity.id ;
                    newTeamMembers.add(newTeamMember);
                }
            }
            if(!targetTeamMembers.isEmpty()){
                System.debug('----->'+targetTeamMembers);
                DELETE targetTeamMembers;
            }
            if(!newTeamMembers.isEmpty()){
                System.debug('newTeamMembers----->'+newTeamMembers);
                INSERT newTeamMembers;
            }
        }
        catch(Exception e)
        {
            Database.rollback( sp );
            pageErrorVisible = true;
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL,e.getMessage()));
        }
        if (pageErrorVisible)
            return false;
        else 
            return true;
        
    }
    
    //Logic for Copying Opportunity Splits from Source to Target
    private Boolean copyOpportunitySplits(Savepoint sp){
        
        try {
            //Query Source Opportunity Split Records
            List<OpportunitySplit> splits = [SELECT Country__c,OpportunityId,SplitAmount,SplitNote,SplitOwnerId,SplitPercentage FROM OpportunitySplit WHERE opportunityId =:selectedSourceOpportunity.id OR opportunityId=:targetOpportunity.Id ];
            System.debug('splits----->'+splits);
            List<OpportunitySplit> targetSplits = new List<OpportunitySplit>();
            List<OpportunitySplit> newSplits = new List<OpportunitySplit>();
            List<OpportunitySplit> newSplitsInsert = new List<OpportunitySplit>();
            for(OpportunitySplit split:splits){
                if(split.OpportunityId == targetOpportunity.id){
                    System.debug('split Owner----->'+split);
                    targetSplits.add(split);
                }
            }
            System.debug('targetSplits Owner----->'+targetSplits);
            for(OpportunitySplit split:splits){
                if(split.OpportunityId != targetOpportunity.id){
                    if (split.SplitOwnerId == targetOpportunity.OwnerId){
                        System.debug('split Owner----->'+split);
                        targetSplits[0].Country__c = split.Country__c ;
                        targetSplits[0].SplitNote = split.SplitNote ;
                        targetSplits[0].SplitPercentage = split.SplitPercentage ;
                        System.debug('targetSplit Owner Update----->'+targetSplits);
                    }
                    else if(split.SplitOwnerId != targetOpportunity.OwnerId){
                        System.debug('split----->'+split);
                        OpportunitySplit newSplit = new OpportunitySplit ();
                        newSplit = split.clone(false);
                        newSplit.opportunityId = targetOpportunity.id;
                        newSplit.SplitPercentage = 0 ;
                        newSplits.add(newSplit);
                    }
                }
            }
            System.debug('targetSplits----->'+targetSplits);
            if(!newSplits.isEmpty()){
                INSERT newSplits;
            }
            for(OpportunitySplit split:splits){
                if(split.OpportunityId == selectedSourceOpportunity.id){
                    for(OpportunitySplit newSplit:newSplits){
                        if(split.SplitOwnerId == newSplit.SplitOwnerId){
                            newSplit.SplitPercentage = split.SplitPercentage;
                            targetSplits.add(newSplit);
                        }
                    }
                }
            }
            if (!targetSplits.isEmpty()){
                UPDATE targetSplits;
            }
        }
        catch(Exception e)
        {
            Database.rollback(sp);
            pageErrorVisible = true;
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL,e.getMessage()));
        }
        if (pageErrorVisible)
            return false;
        else 
            return true;
        
    }
    
    //Logic for on click of cancel
    public PageReference cancel()
    {
        Pagereference pageReferenceLink = new Pagereference('/'+targetOpportunityid);
        pageReferenceLink.setRedirect(true);
        return pageReferenceLink;
    }
}