public without sharing class PCSearch {
    private static final Set<String> WordIgnoreList = new Set<String> { 'and', 'the', 'or' }; // 1-character "words" are eliminated automatically

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // Public methods
    //
    public PCSearch() {
    }

    //
    // Return the product details for a given ID
    //
    public PCProductDetailsMatch productDetails(ID productID) {
        PartnerProduct__c product = fetchProduct(productID);
        List<PartnerProductLogo__c> logoList = [
                select  Id,
                        PartnerProduct__c,
                        (select Id from Attachments)
                  from  PartnerProductLogo__c
                 where  PartnerProduct__c = :productID
        ];
        List<PartnerProductScreenshot__c> screenList = [
                select  Id,
                        PartnerProduct__c,
                        (select Id from Attachments)
                  from  PartnerProductScreenshot__c
                 where  PartnerProduct__c = :productID
        ];

        ID logoMatch = null;
        if (logoList.size() > 0) {
            List<Attachment> alist = logoList.get(0).Attachments;
            if (alist.size() > 0) logoMatch = alist.get(0).Id;
        }

        return new PCProductDetailsMatch(product, logoMatch, screenList);
    }

    //
    // Main search entry point.
    //
    public PCSearchResult productSearch(PCSearchContext ctx) {
        String[] soqlFilters = buildSoqlFilters(ctx, null);
        String soql = makeSoql(soqlFilters, 'order by Partner__r.Finder_Sort_Hint__c, Full_Product_Name__c');
        System.debug('[PF]-------------------------- soql=' + soql);
        PCSearchResult result = new PCSearchResult(ctx, soql);
        execute(ctx, result);
        return result;
    }

    static public PartnerProduct__c fetchProduct(ID productID) {
        PartnerProduct__c product = [
                select      Id,
                            Full_Product_Name__c,
                            Partner__c,
                            Partner__r.Name,
                            Keywords__c,
                            Product_URL_2__c,
                            Product_URL_2_Info__c,
                            Call_To_Action_Text__c,
                            Distribution_Licensing__c,
                            Pricing_And_Support_Details__c,
                            Product_Details__c,
                            ProductSummary__c,
                            Application_Website__c,
                            Source_Licensing__c,
                            Success_Story__c,
                            Software_Category__c,
                            RHEL_Platforms_Supported__c,
                            Platforms__c,
                            JBoss_Platforms_Supported__c,
                            JBoss_Platform__c,
                            Enterprise_Virtualization__c,
                            OpenStack_Platform__c,
                            Industry_Focus__c,
                            Usage_Licensing__c,
                            Language__c
                  from      PartnerProduct__c
                 where      Id = :productID
                            and Application_Status__c = 'Approved'
                            and Application_Visibility__c = 'Visible'
                            and Partner__r.Is_Partner_Published__c = True
                            and Partner__r.VisibleApprovedStatuses__c > 0
        ];
        return product;
    }

    ///////////////////////////////////////////////////////////////////////////////////////////
    // Private methods
    //

    //
    // Main function for building out the SOQL query
    //
    private String[] buildSoqlFilters(PCSearchContext ctx, String[] words) {
        String[] soqlFilters = new List<String>();
        //
        // add in the default constraints
        //
        soqlFilters.add('Partner__r.IsPartner = True');
        soqlFilters.add('Application_Status__c = \'Approved\'');
        soqlFilters.add('Partner__r.Is_Partner_Published__c = True');
        soqlFilters.add('Partner__r.VisibleApprovedStatuses__c > 0');
        soqlFilters.add('(Partner__r.PartnerStatuses__c includes (\'Ready - ISV\') or ' +
                        'Partner__r.PartnerStatuses__c includes (\'Advanced - ISV\') or ' +
                        'Partner__r.PartnerStatuses__c includes (\'Premier - ISV\'))');
        soqlFilters.add('Application_Visibility__c = \'Visible\'');

        if (ctx.partnerId != null) {
            soqlFilters.add('Partner__c = \'' + ctx.partnerId + '\'');
        }
        else if (ctx.globalRegion != null) {
            soqlFilters.add('Partner__r.Global_Region__c = \'' + ctx.globalRegion + '\'');
        }

        String rhel = ctx.RHEL;
        if (rhel != null) {
            String expr =   '(Platforms__c includes (\'' + rhel + '\'))';
            soqlFilters.add(expr);
        }
        if (ctx.JBoss != null) {
            String expr = '(JBoss_Platform__c includes (\'' + ctx.JBoss + '\'))';
            soqlFilters.add(expr);
        }
        if (ctx.RHEV != null) {
            String expr = '(Enterprise_Virtualization__c includes (\'' + ctx.RHEV + '\'))';
            soqlFilters.add(expr);
        }
        if (ctx.RHOS != null) {
            String expr = '(OpenStack_Platform__c includes (\'' + ctx.RHOS + '\'))';
            soqlFilters.add(expr);
        }


        String keywords = String.escapeSingleQuotes(ctx.keywords);
        if (words == null || words.size() == 0) {
            if (!PFUtils.isEmpty(ctx.keywords)) {
                String expr =   '(Full_Product_Name__c like \'%' + keywords + '%\'' +
                                ' or Partner__r.Name like \'%' + keywords + '%\'' +
                                ' or Partner__r.Account_Alias_Name__c like \'%' + keywords + '%\'' +
                                ' or Keywords__c like \'%' + keywords + '%\'' +
                                ' or Internal_Keywords__c like \'%' + keywords + '%\')';
                soqlFilters.add(expr);
            }
        }
        else {
            //
            // if words is not null then this search should be conducted on each
            // individual word rather than the entire phrase
            //
            String[] exprlist = new List<String>();
            exprlist.add('(Full_Product_Name__c like \'%' + keywords + '%\'' +
                            ' or Partner__r.Name like \'%' + keywords + '%\'' +
                            ' or Partner__r.Account_Alias_Name__c like \'%' + keywords + '%\')');
//            for (String word : words) exprlist.add('(Full_Product_Name__c like \'%' + String.escapeSingleQuotes(word.trim()) + '%\'' +
//                                        ' or Partner__r.Name like \'%' + String.escapeSingleQuotes(word.trim()) + '%\'' +
//                                        ' or Partner__r.Account_Alias_Name__c like \'%' + String.escapeSingleQuotes(word.trim()) + '%\')');
            //for (String word : words) exprlist.add('Keywords__c like \'%' + String.escapeSingleQuotes(word.trim()) + '%\'');
            //for (String word : words) exprlist.add('Internal_Keywords__c like \'%' + String.escapeSingleQuotes(word.trim()) + '%\'');
            String orClause = '(' + PFUtils.joinStrings(exprlist, ' or ') + ')';
            soqlFilters.add(orClause);
        }

        if (!PFUtils.isEmpty(ctx.softwareCategory)) {
            soqlFilters.add('Software_Category__c = \'' + ctx.softwareCategory + '\'');
        }

        return soqlFilters;
    }

    //
    // Fallback search - check each word.
    //
    private List<PartnerProduct__c> executeKeywordSearches(PCSearchContext ctx) {
        String[] words = normalize(ctx.keywords.split(' '));
        if (words.size() < 2) {
            //
            // no need to search for 1 word since the full search already covered it
            //
            return new PartnerProduct__c[0];
        }
        String[] soqlFilters = buildSoqlFilters(ctx, words);
        String soql = makeSoql(soqlFilters, 'order by Partner__r.Finder_Sort_Hint__c, Full_Product_Name__c');
        List<PartnerProduct__c> pslist = Database.query(soql);
        return pslist;
    }

    //
    // Constructed SOQL query executed here.  The 'result' parameter is populated with the PartnerStatus IDs
    //
    private void execute(PCSearchContext ctx, PCSearchResult result) {
        Datetime startTimer = Datetime.now();
        System.debug('**** [DEBUG] ***** SOQL=' + result.soql);
        List<PartnerProduct__c> pslist = Database.query(result.soql);
        if ((pslist == null || pslist.size() == 0) && ctx.keywords.length() > 0) {
            //
            // try searching on individual keywords
            //
            pslist = executeKeywordSearches(ctx);
        }
        result.msExecutionTime = Datetime.now().getTime() - startTimer.getTime();
        result.resultIdList = new List<Id>();
        for (PartnerProduct__c ps : pslist) result.resultIdList.add(ps.ID);
    }

    private String makeSoql(String[] whereFilters, String orderBy) {
        String soqlWhere = 'where ' + PFUtils.joinStrings(whereFilters, ' and ');
        return 'select Id from PartnerProduct__c ' + soqlWhere + ' ' + orderBy;

    }

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // Utility methods
    //


    //
    // do any needed processing on the word list before searching
    //
    private String[] normalize(String[] words) {
        if (words.size() < 2) {
            return words;
        }

        String[] tmp = new List<String>();
        //
        // eliminate troublesome words
        //
        for (String word : words) {
            if (word.length() == 1) {
                continue;
            }
            word = word.toLowerCase();
            if (WordIgnoreList.contains(word)) {
                continue;
            }
            tmp.add(word);
        }
        return tmp;
    }



}