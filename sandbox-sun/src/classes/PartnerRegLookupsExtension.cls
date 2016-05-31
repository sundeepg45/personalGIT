public without sharing class PartnerRegLookupsExtension {

    public class Opp {
        public ID      id {get; set; }
        public String   name {get; set; }
        public Set<String> primaryBU {get; set; }
    }
    
    private final Set<String> IGNORE_TERMS = new Set<String> {'a','and','the','la','el','un','una','uno','y','und','die','das','der','dem','et'};

    public Partner_Registration__c reg { get; private set; }
    public String accountName {get; set; }
    public Boolean isEditable {get; private set; }
    public Account customerAccount {get; private set; }
    public List<Account> accountMatches {get; private set; }
    public Account selectedAccount {get; private set; }
    private Country__c custCountry = null;
    private State__c custState = null;
    public List<Opp> opps = null;
    public String lastOppAccountName = null;
    public Opportunity selectedOpp {get; private set; }
    public Opportunity attachedOpp {get; private set; }

    

    public PartnerRegLookupsExtension(ApexPages.StandardController stdController) {
        
        User me = [select ContactId, Contact.AccountId from User where Id = :UserInfo.getUserId()];
        Boolean isPartner = me.ContactId != null;
        String regid = stdController.getRecord().Id;
        if (regid == null) {
            regid = ApexPages.currentPage().getParameters().get('id');
        }
        reg = [
            select  Id, Company_Name__c, Status__c, End_Customer__c, Company_Country__c, Company_State__c, Opportunity__c, Product_Family__c
            from    Partner_Registration__c
            where   Id = :regid
        ];
        isEditable = !isPartner && reg.Status__c == 'Pending Channel Operations Approval';
        accountName = reg.Company_Name__c;
        fetchCustomerAccount();
        fetchAttachedOpp();

        if (reg.Company_Country__c != null && reg.Company_State__c != null) {
            if (reg.Company_Country__c.length() >= 2 && reg.Company_State__c.length() >= 2) {
                try {
                    custState = [
                        select  Id, FIPSAlpha__c, Country__r.Name, Name
                        from    State__c
                        where   Country__r.Abbreviation__c = :reg.Company_Country__c
                        and     FIPSAlpha__c = :reg.Company_State__c
                        limit   1
                    ];
                    System.debug('**** [debug] custState.Name = ' + custState.Name);
                }
                catch (QueryException ex) {
                    // safe to ignore
                    System.debug('**** [debug] state not found: ' + reg.Company_State__c);
                }

            }
            if (custState == null && reg.Company_Country__c.length() >= 2) {
                try {
                    custCountry = [
                        select  Global_Region__c, Country_of_Order__c, Abbreviation__c
                        from    Country__c
                        where   Abbreviation__c = :reg.Company_Country__c
                        limit   1
                    ];
                }
                catch (QueryException ex) {
                    // safe to ignore
                    System.debug(ex);
                }
            }
        }
        else if (reg.Company_Country__c != null && reg.Company_Country__c.length() >= 2) {
            try {
                custCountry = [
                    select  Global_Region__c, Country_of_Order__c, Abbreviation__c
                    from    Country__c
                    where   Abbreviation__c = :reg.Company_Country__c
                    limit   1
                ];
            }
            catch (QueryException ex) {
                // safe to ignore
                System.debug(ex);
            }
        }
    }

    private void fetchCustomerAccount() {
        if (reg.End_Customer__c == null) return;
        customerAccount = [
            select  Id, Name, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry, Global_Region__c, Owner.Name, AccountClassification__c
            from    Account
            where   Id = :reg.End_Customer__c
        ];
    }
    
    private void fetchAttachedOpp() {
        if (reg.Opportunity__c == null) return;
        attachedOpp = [
          select  Id, Name, Account.Name, Country_of_Order__c, StageName, CloseDate, (select PriceBookEntry.Product2.Primary_Business_Unit__c from OpportunityLineItems)
          from    Opportunity
          where   Id = :reg.Opportunity__c
        ];
    }
    
    public Account getAccount() {
        ID id = System.currentPageReference().getParameters().get('accountId');
        System.debug('***** id is ' + id);
        if (id == null) return null;
        if (selectedAccount != null && selectedAccount.Id == id) {
            return selectedAccount;
        }
        selectedAccount = [
            select  Id, Name, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry, Named_Account__c, OracleAccountId__c,
                    Global_Region__c, Owner.Name, AccountClassification__c
            from    Account
            where   Id = :id
        ];
        return selectedAccount;
    }

    public Opportunity getOpportunity() {
        ID id = System.currentPageReference().getParameters().get('oppId');
        System.debug('***** [debug] oppId=' + id);
        if (id == null) return null;
        if (selectedOpp != null && selectedOpp.Id == id) {
            return selectedOpp;
        }
        selectedOpp = [
          select  Id, Name, Account.Name, Country_of_Order__c, OwnerId, Owner.Name, StageName, CloseDate, PartnerAccountId, PartnerAccount.Name, (select PriceBookEntry.Product2.Primary_Business_Unit__c from OpportunityLineItems)
          from    Opportunity
          where   Id = :id
        ];
        return selectedOpp;
    }

    private Account[] queryAccounts(String whereClause) {
        String soql = 'select Id, Name, BillingCountry, OwnerId, Owner.Name, AccountClassification__c, BillingState, Named_Account__c '+
            'from Account '+
            'where IsPartner = False and ';

        if (custState != null) {
            soql += 'BillingState = \'' + custState.FIPSAlpha__c + '\' and ';
        }
        else if (custCountry != null) {
            soql += 'BillingCountry = \'' + custCountry.Abbreviation__c + '\' and ';
            //soql += 'Global_Region__c = \'' + custCountry.Global_Region__c + '\' and ';
        }
        return (Account[]) Database.query(soql + whereClause);
    }

    private Opportunity[] queryOpps(String whereClause) {
        DateTime oldestDate = System.now().addMonths(-6);
        String s_date = oldestDate.format('yyyy-MM-dd') + 'T00:00:00Z';
        String soql = 'select Id, Name, Account.Name, StageName, CloseDate, (select PriceBookEntry.Product2.Primary_Business_Unit__c from OpportunityLineItems) '+
                      'from   Opportunity '+
                      'where  CreatedDate >= ' + s_date + ' '+
                      'and    IsClosed = false '+
                      'and    ';
        Opportunity[] opplist = (Opportunity[]) Database.query(soql + whereClause);
        
        //
        // we have to manually filter products
        //
        Opportunity[] narrowlist = new List<Opportunity>();
        for (Opportunity opp : opplist) {
            if (opp.OpportunityLineItems != null) {
                for (OpportunityLineItem oli : opp.OpportunityLineItems) {
                    if (reg.Product_Family__c != null && reg.Product_Family__c.contains(oli.PriceBookEntry.Product2.Primary_Business_Unit__c)) {
                        narrowlist.add(opp);
                        break;
                    }
                }
            }
        }
        return narrowlist;
    }

    public Set<Opportunity> getFuzzyOpps(String accountName) {
        //
        // try for the most likely positive matches first
        //
        Set<Opportunity> opplist = new Set<Opportunity>();
        opplist.addAll(queryOpps('Account.Name = \'' + accountName + '\' limit 5'));
        opplist.addAll(queryOpps('Account.Name like \'' + accountName + '%\' limit 10'));
        if (opplist.size() > 0) {
            return opplist;
        }
        //
        // fall back to partial matching
        //
        opplist.addAll(queryOpps('Account.Name like \'%' + accountName + '%\' limit 10'));
        if (opplist.size() == 0) {
            String[] parts = scrubTerms(accountName.split(','));
            if (parts.size() > 1) {
                for (String part : parts) {
                    if (part.length() > 2) {    // skip articles/small words
                        opplist.addAll(queryOpps('Account.Name like \'%' + accountName + '%\' limit 10'));
                    }
                }
            }
        }
        return opplist;
    }

    public List<Opp> getOpportunities() {
        ID id = System.currentPageReference().getParameters().get('accountId');
        if (selectedAccount == null && id == null) {
            return null;
        }
        if (id != null) {
            // because VF event handling sucks and this must be forced
            getAccount();
        }
        if (lastOppAccountName == selectedAccount.Name) {
            return opps;
        }
        lastOppAccountName = selectedAccount.Name;
        Set<Opportunity> oppset = new Set<Opportunity>();
        //if (reg.End_Customer__c == null) {
        //   oppset.addAll(getFuzzyOpps(selectedAccount.Name));
        //}
        //else {
            oppset.addAll(queryOpps('AccountId = \'' + selectedAccount.Id + '\' limit 20'));
             oppset.addAll(getFuzzyOpps(selectedAccount.Name));
        //}
        if (oppset.size() == 0) {
            opps = null;
        }
        else {
            opps = new List<Opp>();
            for (Opportunity opp : oppset) {
                Opp o = new Opp();
                o.id = opp.Id;
                o.name = opp.Name;
                o.primaryBU = new Set<String>();
                if (opp.OpportunityLineItems != null) {
                    OpportunityLineItem[] items = opp.OpportunityLineItems;
                    for (OpportunityLineItem item : items) {
                        if (item.PriceBookEntry.Product2 != null && item.PriceBookEntry.Product2.Primary_Business_Unit__c != null) {
                            o.primaryBU.add(item.PriceBookEntry.Product2.Primary_Business_Unit__c);
                        }
                    }
                }
                opps.add(o);
            }
//          opps.addAll(oppset);
        }
        return opps;
    }
    
    private String[] scrubTerms(String[] terms) {
        String[] kept = new List<String>();
        for (String s : terms) {
            s = s.toLowerCase();
            if (!IGNORE_TERMS.contains(s)) {
                kept.add(s);
            }
        }
        return kept;
    }

    public PageReference attachAccount() {
        if (selectedAccount != null) {
            reg.End_Customer__c = selectedAccount.Id;
            update reg;
            customerAccount = selectedAccount;
            selectedAccount = null;
        }
        return null;    
    }
    
    public PageReference attachOpp() {
        if (selectedOpp != null) {
            reg.Opportunity__c = selectedOpp.Id;
            update reg;
            attachedOpp = selectedOpp;
            selectedOpp = null;
            attachAccount();
            //
            // now reject from approvals
            //
            ProcessInstanceWorkItem[] wilist = [
                select  p.ProcessInstance.Status, p.ProcessInstance.TargetObjectId, p.ProcessInstanceId, p.Id
                from    ProcessInstanceWorkitem p
                where   p.ProcessInstance.TargetObjectId = :reg.Id
                and     p.ProcessInstance.Status = 'Pending'
            ];
            if (wilist.size() > 0) {
                ProcessInstanceWorkItem wi = wilist.get(0);
                Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
                req.setAction('Reject');
                req.setComments('Denied due to existing opportunity');
                req.setWorkitemId(wi.Id);
                Approval.ProcessResult result =  Approval.process(req);
                reg.Status__c = 'Existing Opportunity';
                update reg;
                return new PageReference('/' + reg.Id);
            }
        }
        return null;
    }
    
    public PageReference clearOpp() {
        reg.Opportunity__c = null;
        update reg;
        attachedOpp = null;
        selectedOpp = null;
        return null;
    }

    public PageReference searchAccounts() {
        if (accountName == null || accountName.length() == 0) return null;

        System.debug('***** looking for ' + accountName);
        accountMatches = new List<Account>();
        List<Account> matches = new List<Account>();
        Account[] tmplist = queryAccounts('Name = \'' + accountName + '\'');
        matches.addAll(tmplist);
        //
        // do a partial trailing match to be sure
        //
        tmplist = queryAccounts('Name like \'' + accountName + '%\' limit 100');
        matches.addAll(tmplist);
        if (matches.size() == 0) {
            //
            // try some fuzzy matching
            //
            String[] parts = scrubTerms(accountName.split(' '));
            for (String part : parts) {
                if (part.length() > 2) {    // skip articles/small words
                    tmplist = queryAccounts('Name like \'%' + part + '%\' limit 20');
                    matches.addAll(tmplist);
                }
            }
        }
        if (matches.size() == 0) {
            accountMatches = null;
        }
        else {
            //
            // eliminate dups but maintain order
            //
            accountMatches = PartnerUtil.dedup(matches);
        }
        return null;
    }
    
    public PageReference cancel() {
        return new PageReference('/' + reg.Id);
    }
}