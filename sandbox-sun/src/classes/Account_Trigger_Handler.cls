/*****************************************************************************************
    Name    : Account_Trigger_Handler
    Desc    : This class will act as helper class for Sales Account trigger to process different business logic related to SalesAccount
              1.) Invoke the method provided by RH Team to process domain object.


    Modification Log :
---------------------------------------------------------------------------
    Developer                 Date            Description
---------------------------------------------------------------------------
    Chandan Prusty          23 JULY 2014        Created
    Vipul Jain              06 AUG 2014         Added one more criteria for duplicate check on account (Momentum defect No : RH-00343367 / RH-00343701 )
    Vipul Jain              08 AUG 2014         By pass the duplicate check validation for Integration admin(Momentum defect Number : RH-00343524 )
    Neha Jaiswal            25 OCT 2014         To fetch the partner programs of an account if status is active and sent that to CDH outbound.
    Tiaan Kruger            6 FEB 2015          Added code to grab all active partner programs as classifications for account per it's CDH Party
    Tiaan Kruger            7 FEB 2015          Commented out unused dup detection code to improve unit testing coverage
    Scott Coleman           24 MAR 2015         Fixing bug related to messaging of new accounts
    Anshul Kumar            28 APR 2015         US67021
    Scott Coleman           06 JUL 2015         US66997 - suppress publishing of outbound messages for inactive parties
    Scott Coleman           13 Aug 2015         Suppressing publishing of test records per US71693
    Bill C Riemers          27 Aug 2015         Query MasterRecord__r.Status__c
    J Garrison              01 Oct 2015         Added logic to prevent the creation of a
                                                duplicate sales account during manual
                                                onboarding. See US73888.
    J Garrison              15 Oct 2015         Backed out changes from 1-Oct-2015 to fix issue with SFA push to Stage.
    Bill Riemers            23 Nov 2015         Restrict the query for Event__c to recent records
    Bill Riemers            26 Nov 2015         Set OpportunityId__c when creating event__c records
    Bill Riemers            06 Jan 2015         Revert createEventRecords method
******************************************************************************************/
public with sharing class Account_Trigger_Handler {
    /** BooleanSetting__c key to enable the createEventRecords2 method. */
    public static final String CREATE_EVENT_RECORDS_SETTING = 'Account_After.CreateEventRecords';

    //Method to send Sales Account Outbound message to the method to process the outbound  domain object.

    //declaring a static variable to hold the status of partner program
    public final static string ACTIVE_STATUS= 'Active';
    public final static string APPROVED_STATUS= 'Approved';

    //map of partner program tier to hold the values of it's record.
    public static Map<String,Partner_Program_Tier__c> mapOfProgramTier = new Map<String,Partner_Program_Tier__c>();

    public static void SalesAccount_Outbound_Message(map<Id,Account> newmap,map<Id,Account> oldmap){
        // The BLOCK_MESSAGE variable is used to prevent the creation of a
        // duplicate sales account during manual onboarding. This addresses
        // US73888 [RH-00431792].
        // if (OnboardingUtils.BLOCK_MESSAGE != null) {
        //     OnboardingUtils.BLOCK_MESSAGE = (OnboardingUtils.BLOCK_MESSAGE == '1' ? '2' : null);
        // } else {
            // Retrieve all of the active partner programs for all the accounts passed in
            Set<String> cdhPartyNumbers = new Set<String>();
            for (Account a : newmap.values()) {
                if (a.CDHPartyNumber__c != null &&
                    a.RecordTypeId != PartnerConst.NA_PARTNER && a.RecordTypeId != PartnerConst.EMEA_PARTNER &&
                    a.RecordTypeId != PartnerConst.LATAM_PARTNER && a.RecordTypeId != PartnerConst.APAC_PARTNER) {
                    cdhPartyNumbers.add(a.CDHPartyNumber__c);
                }
            }

            List<Partner_Program__c> partnerProgramMemberships = new List<Partner_Program__c>();
            if (!cdhPartyNumbers.isEmpty()) {
                partnerProgramMemberships = [
                    SELECT
                        Name,
                        Oracle_Classification_Code__c,
                        Program__c,
                        Program__r.Oracle_Classification_Code__c,
                        Account__r.CDHPartyNumber__c,
                        Program__r.Program_Category__c,
                        Status__c,
                        Tier__c
                    FROM Partner_Program__c
                    WHERE
                        Account__r.CDHPartyNumber__c in :cdhPartyNumbers
                        and Status__c in ('Active', 'Approved')
                    ];
            }

            System.debug('** Found ' + partnerProgramMemberships.size() + ' Partner program memberships for CDH#s: ' + cdhPartyNumbers);

            // Build a map to lookup all of the programs for a given CDH Party Number
            Map<String,List<Partner_Program__c>> cdhNumberPartnerProgramMap = new Map<String,List<Partner_Program__c>>();
            for (Partner_Program__c ppMember : partnerProgramMemberships){
                List<Partner_Program__c> ppl = null;
                if (!cdhNumberPartnerProgramMap.containsKey(ppMember.Account__r.CDHPartyNumber__c)){
                    ppl = new List<Partner_Program__c>();
                    cdhNumberPartnerProgramMap.put(ppMember.Account__r.CDHPartyNumber__c, ppl);
                } else {
                    ppl = cdhNumberPartnerProgramMap.get(ppMember.Account__r.CDHPartyNumber__c);
                }
                System.debug('Adding ' + ppMember.Program__r.Program_Category__c + '-' + ppMember.Tier__c + ' for CDH Party # ' + ppMember.Account__r.CDHPartyNumber__c);
                ppl.add(ppMember);
            }

            /*This is the scenario when a Sales Account will be created by Interface and Identifying address will be created
            under the Sales Account. Now again the standard Billing Address fields for the Sales Account will be updated. */

            //method to get the value of the tier object.
            getMapOfPartnerProgramAndTier();

            //iterating on the account created/updated. added CDH_Party_Name__r.Active__c to query for US66997
            for(Account accountToSendInOutbound : [
                Select  All_NAICS_Codes__c,
                        AnnualRevenue,
                        CDH_Party_Type__c,
                        CDH_Party_Number__c,
                        CDHPartyNumber__c,
                        CDH_Party_Name__r.Active__c,
                        CDH_Party_Name__r.Name,
                        Count_Of_Identifying_Address__c,
                        DunsNumber,
                        D_U_N_S__c,
                        Do_Not_Do_Business_with__c,
                        Domestic_Ultimate__c,
                        Fax,
                        Global_Ultimate__c,
                        Headquarters_CDH_Party_Number__c,
                        Headquarters__c,
                        Linkedin_URL__c,
                        Name,
                        NumberOfEmployees,
                        Phone,
                        SEA_Concern__c,
                        Sic,
                        SicDesc,
                        Status__c,
                        Tradestyle,
                        VATNumber__c,
                        Website,
                        YearStarted,
                        Do_Not_Publish_To_Bus__c,
                        (Select Status__c,
                            MasterRecord__r.Status__c,
                            Address_Line1__c,
                            Address_Line2__c,
                            Address_Line3__c,
                            Address_Line4__c,
                            Bill_To_Address__c,
                            CDH_Party__c,
                            CDH_Party_Site_Number__c,
                            City__c,
                            Country__c,
                            County__c,
                            Entitle_To_Address__c,
                            Identifying_Address__c,
                            Name,
                            Province__c,
                            Sales_Account__c,
                            Ship_To_Address__c,
                            Sold_To_Address__c,
                            State__c,
                            Zip_Postal_Code__c
                            from Addresses__r
                            where Identifying_Address__c = true
                                and MasterRecord__c = null
                            limit 1)
                        From Account
                        where
                        id IN : newmap.keyset()
                        and
                        Count_Of_Identifying_Address__c >0
                        and
                        RecordType.Name not in ('NA Partner', 'EMEA Partner', 'APAC Partner', 'LATAM Partner')
                        limit 1
                ]) {

                // US66997
                if(accountToSendInOutbound.CDH_Party_Name__r == null || accountToSendInOutbound.CDH_Party_Name__r.Active__c) {

                    // US71693
                    OutboundService.DoNotPublish = (OutboundService.DoNotPublish || accountToSendInOutbound.Do_Not_Publish_To_Bus__c);

                    // Get the partner programs for this account from the map
                    List<Partner_Program__c> listProgramToBeSend = new List<Partner_Program__c>();
                    if (accountToSendInOutbound.CDH_Party_Name__r.Name != null && cdhNumberPartnerProgramMap.containsKey(accountToSendInOutbound.CDH_Party_Name__r.Name)){
                        listProgramToBeSend = cdhNumberPartnerProgramMap.get(accountToSendInOutbound.CDH_Party_Name__r.Name);
                    }
                    System.debug('We have ' + listProgramToBeSend.size() + ' partner program memberships for CDH Party # ' + accountToSendInOutbound.CDH_Party_Name__r.Name);

                    //initializing list of partner program to add in wrapper structure of integrationObject
                    List<IntegrationObjects.classification> ioClassificationList = new List<IntegrationObjects.classification>();

                    //checking  the list size to send in integration object for partner programs.
                    if(!listProgramToBeSend.isEmpty()){
                        for(Partner_Program__c partnerProgramToSendWithAccount : listProgramToBeSend) {
                            /*Generating the Integration object of contact using , Integration object converter class
                            Invoke QueueContactMessage method of OutBoundService class.*/

                            //
                            // The oracle_classification_code stored in partner_program__c is a copy of the tier code
                            //
                            IntegrationObjects.Classification  ioClassification  = new IntegrationObjects.Classification();
                            ioClassification = IntegrationObjectConverter.convertClassification(partnerProgramToSendWithAccount);
                            system.debug('lisioClassification'+ioClassification);
                            ioClassificationList.add(ioClassification);

                            ioClassification = new IntegrationObjects.Classification();
                            ioClassification.Status = ACTIVE_STATUS;
                            ioClassification.Code = partnerProgramToSendWithAccount.Program__r.Oracle_Classification_Code__c;
                            ioClassificationList.add(ioClassification);
                        }
                    }

                    //checking if the count of identifying address is 1 to sent outbound.
                    if(newmap.get(accountToSendInOutbound.Id).Count_Of_Identifying_Address__c != oldmap.get(accountToSendInOutbound.Id).Count_Of_Identifying_Address__c){
                        IntegrationObjects.SalesAccount salesAccountToBeSend = new IntegrationObjects.SalesAccount();
                        salesAccountToBeSend = IntegrationObjectConverter.convertSalesAccount(accountToSendInOutbound);
                        salesAccountToBeSend.CDH_Party_Number = accountToSendInOutbound.CDH_Party_Name__r.Name;
                        salesAccountToBeSend.CDH_Party_Type = 'ORGANIZATION';

                       if(!ioClassificationList.isEmpty()){
                            salesAccountToBeSend.PartnerClassifications = ioClassificationList;
                        }

                        //Send Sales Account and Identifying Address inside it
                        OutboundService.queueAccountMessage(salesAccountToBeSend,'UPDATE');
                    }

                    // if the account record has been updated by SFDC user(not through interface) , send the account message to outbound service.
                    else if(userInfo.getName() != 'Integration Admin'){
                        //Send Only Sales Account
                        IntegrationObjects.SalesAccount salesAccountToBeSend = new IntegrationObjects.SalesAccount();
                        salesAccountToBeSend = IntegrationObjectConverter.convertSalesAccount(accountToSendInOutbound);
                        salesAccountToBeSend.CDH_Party_Number = accountToSendInOutbound.CDH_Party_Name__r.Name;
                        salesAccountToBeSend.Addresses = null;
                        salesAccountToBeSend.CDH_Party_Type = 'ORGANIZATION';

                       if(!ioClassificationList.isEmpty()){
                            salesAccountToBeSend.PartnerClassifications = ioClassificationList;
                        }

                        //Below code will invoke outbound service by passing the parameter to it's method.
                        OutboundService.queueAccountMessage(salesAccountToBeSend,'UPDATE');
                    }
                }
            }
        // }
    }
/*
    // Below method checks for duplicate Sales Account.

    public static void CheckDuplicateAcount(map<id,Account> newAccountMap) {

        if(userInfo.getName() != 'Integration Admin'){
            // variable to hold the set of all record type id
            Set<string> setOfRecordTypeId = new Set<String>();

            // variable to hold the set of all billing countries
            Set<String> setOfBillingCountry = new Set<String>();

            // variable to hold the set of all account names
            Set<String> setOfAccountName = new Set<String>();

            // variable to hold all partner tier
            Set<String> setOfFinderPartnerTier = new Set<String>();

            // variable to hold all finder partner type
            Set<String> setOfFinderPartnerType = new Set<String>();

            // Map for customer account
            Map<string,List<Account>> mapforCustomerAccount = new Map<String, List<Account>>();

            // Map for Partner Account.
            Map<string,List<Account>> mapforPartnerAccount = new Map<String, List<Account>>();

            // map for CDH Party record Id and CDH Party#.
            Map<ID,String> mapOfCDHPartyIdAndNumber = new  Map<ID,String>();

            // iterating on all accounts created/updated.
            for(Account account : newAccountMap.values()){
                setOfRecordTypeId.add(account.recordtypeid);
                setOfBillingCountry.add(account.BillingCountry);
                setOfAccountName.add(account.Name);
                setOfFinderPartnerTier.add(account.Finder_Partner_Tier__c);
                setOfFinderPartnerType.add(account.Finder_Partner_Type__c);
            }

            // iterating on all accounts which have the Name , Billing country , RecordType and attributes specific to partner account.
            for(Account account : [select BillingCountry,
                                    CDH_Party_Name__c,
                                    CDH_Party_Name__r.Name,
                                    CDH_Party_Number__c ,
                                    Finder_Partner_Tier__c,
                                    Finder_Partner_Type__c,
                                    IsPartner,
                                    Name,
                                    recordtypeid
                                    from Account
                                    where recordtypeid in :setOfRecordTypeId and
                                    BillingCountry in :setOfBillingCountry and
                                    Name in :setOfAccountName and
                                    Finder_Partner_Tier__c in :setOfFinderPartnerTier and
                                    Finder_Partner_Type__c in :setOfFinderPartnerType]){

                mapOfCDHPartyIdAndNumber.put(account.CDH_Party_Name__c,account.CDH_Party_Name__r.Name);

                // prepare the map for customer account
                if(account.IsPartner == False){

                    List<Account> accountList = new List<Account>();
                    if(mapforCustomerAccount.get(account.Name+account.BillingCountry+account.IsPartner+account.RecordTypeId+account.CDH_Party_Name__c) != Null){
                        accountList = mapforCustomerAccount.get(account.Name+account.BillingCountry+account.IsPartner+account.RecordTypeId+account.CDH_Party_Name__c);
                    }
                    accountList.add(account);
                    mapforCustomerAccount.put(account.Name+account.BillingCountry+account.IsPartner+account.RecordTypeId+account.CDH_Party_Name__c,accountList);
                }

                // prepare the map for partner account.
                if(account.IsPartner == True){

                    List<Account> partnerAccountList = new List<Account>();
                    if(mapforPartnerAccount.get(account.Name+account.BillingCountry+account.IsPartner+account.RecordTypeId+account.Finder_Partner_Tier__c+account.Finder_Partner_Type__c+account.CDH_Party_Name__c) != Null){
                        partnerAccountList = mapforPartnerAccount.get(account.Name+account.BillingCountry+account.IsPartner+account.RecordTypeId+account.Finder_Partner_Tier__c+account.Finder_Partner_Type__c+account.CDH_Party_Name__c);
                    }
                    partnerAccountList.add(account);
                    mapforPartnerAccount.put(account.Name+account.BillingCountry+account.IsPartner+account.RecordTypeId+account.Finder_Partner_Tier__c+account.Finder_Partner_Type__c+account.CDH_Party_Name__c,partnerAccountList);
                }
            }

            // iterating on all new accounts/accounts updated.
            for(Account account: newAccountMap.values()){

                // check for the customer account , if there is any other customer account having same Name ,Billing country , RecordType
                string cdhPartyNumber = account.CDH_Party_Name__c == Null ? ' ':mapOfCDHPartyIdAndNumber.get(account.CDH_Party_Name__c);
                if(account.IsPartner == False && mapforCustomerAccount.get(account.Name+account.BillingCountry+account.IsPartner+account.RecordTypeId+account.CDH_Party_Name__c) != Null && mapforCustomerAccount.get(account.Name+account.BillingCountry+account.IsPartner+account.RecordTypeId+account.CDH_Party_Name__c).size()>1){

                    // throw the error if any duplicate is there.
                    account.adderror('The Sales Account cannot be created or updated because the duplicate sales account exists for the CDH Party Number : '+cdhPartyNumber +' and Billing Country : '+account.BillingCountry);
                }

                // check for partner account , if there is any other partner having same attributes (Name, Billing Country, RecordType,FinderParterTier,Finder Partner Type).
                if(account.IsPartner == True && mapforPartnerAccount.get(account.Name+account.BillingCountry+account.IsPartner+account.RecordTypeId+account.Finder_Partner_Tier__c+account.Finder_Partner_Type__c+account.CDH_Party_Name__c) !=Null &&
                    mapforPartnerAccount.get(account.Name+account.BillingCountry+account.IsPartner+account.RecordTypeId+account.Finder_Partner_Tier__c+account.Finder_Partner_Type__c+account.CDH_Party_Name__c).size() >1){

                    //throw the error if any duplicate is there.
                    account.adderror('The Sales Account cannot be created or updated because the duplicate sales account exists for the CDH Party Number : '+cdhPartyNumber +' and Billing Country : '+account.BillingCountry);
                }
            }
        }
    }*/

      /**
    *This is the method invoked by to get the detail of the record of tier object.
    *@param :
    *@return : List of tier records in a map.   */
    public static void getMapOfPartnerProgramAndTier(){

        for(Partner_Program_Tier__c programTier : [Select CDH_Mastered__c,
                                                    Oracle_Classification_Code__c,
                                                    Partner_Program_Definition__c,
                                                    Tier__c
                                                    from Partner_Program_Tier__c]){

            //checking if the record of tier has definition value.
            if(programTier.Partner_Program_Definition__c!=Null &&
                programTier.Tier__c!= Null) {

                //inserting the values of record of map.
                mapOfProgramTier.put(programTier.Partner_Program_Definition__c+programTier.Tier__c, programTier);
            }
        }
    }

    public static void createEventRecords(){
        list<Id> lstChangedOwnerAcc = new list<Id>();
        Account accInst;
        
       //collect all the account ids for which owner has changed 
        for(SObject acc : trigger.New){
            
            accInst = (Account) acc;
            if(accInst.OwnerId != ((Account) trigger.oldMap.get(accInst.Id)).OwnerId){
                
                lstChangedOwnerAcc.add(accInst.Id);
            }
        }
        List<Event__c> events = new List<Event__c>();
        if(AbstractTrigger.isActive(CREATE_EVENT_RECORDS_SETTING,true)) {
//US80608(rollback DE7583)            if(Opportunity_Split_Batchable2.scheduledApex == null) {
               //collect all the associated Opportunity records 
                set<Id> setParentOppIds = new set<Id>();
                for(Opportunity opp : [SELECT Id FROM Opportunity WHERE AccountId IN: lstChangedOwnerAcc]){
                    
                    setParentOppIds.add(opp.Id);
                }
                
               //create map opportunity id and corresponding event record 
                map<Id, Event__c> mapParentOppId_Event = new map<Id, Event__c>();
                for(Event__c eventInst : [SELECT Opportunity__c FROM Event__c WHERE Opportunity__c IN: setParentOppIds AND Processed__c = FALSE]){
                    
                    mapParentOppId_Event.put(eventInst.Opportunity__c, eventInst);
                }
                
               //create new records in Event 
                Event__c eventInst;
                for(Id oppId : setParentOppIds){
                    
                    if(mapParentOppId_Event.get(oppId) == NULL){
                        
                        eventInst = new Event__c();
                        eventInst.Opportunity__c = oppId;
                        events.add(eventInst);
                    }
                }
//US80608(rollback DE7583)            }
//US80608(rollback DE7583)            else {
//US80608(rollback DE7583)                // only exclude opportunities which have events that have not started processing.
//US80608(rollback DE7583)                for(Opportunity opp : [
//US80608(rollback DE7583)                    SELECT Id
//US80608(rollback DE7583)                    FROM Opportunity
//US80608(rollback DE7583)                    WHERE AccountId IN :lstChangedOwnerAcc
//US80608(rollback DE7583)                        AND Id NOT IN (
//US80608(rollback DE7583)                            SELECT Opportunity__c
//US80608(rollback DE7583)                            FROM Event__c
//US80608(rollback DE7583)                            WHERE Processed__c = false
//US80608(rollback DE7583)                                AND Opportunity__r.AccountId IN :lstChangedOwnerAcc
//US80608(rollback DE7583)                                AND LastModifiedDate > :Opportunity_Split_Batchable2.maxProcessingSetting.Value__c )
//US80608(rollback DE7583)                    LIMIT :Opportunity_Split_Batchable2.dmlRows ] )
//US80608(rollback DE7583)                {
//US80608(rollback DE7583)                    events.add(new Event__c(OpportunityId__c = opp.Id, Opportunity__c = opp.Id, Processed__c = false));
//US80608(rollback DE7583)                }
//US80608(rollback DE7583)            }
            Database.insert(events, false);
        }
    }
}