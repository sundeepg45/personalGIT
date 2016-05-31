public without sharing class PFSearch {
    private static final Set<String> WordIgnoreList = new Set<String> {'and', 'the', 'or' }; // 1-character "words" are eliminated automatically
    private static final String NOT_SPECIFIC = '--None--';
    private static final String ISV_SELECT = 'Independent Software Vendor (ISV)';
    private static final String TRAINING_SELECT = 'Training Partner';
    private static final String RESELLER_SELECT = 'Solution Provider';
    private static final String CORP_RESELLER_SELECT = 'Corporate Reseller';
    private static final String SERVICECLOUD_PROVIDER = 'Service/Cloud Provider';

    private Map<String,ID> typeMap;
    private Map<String,ID> tierMap;

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // Public methods
    //
    public PFSearch() {
        typeMap = PFUtils.buildFieldIDMap('HierarchyKey__c', [
                select  Id,
                        HierarchyKey__c
                  from  Classification__c
                 where  HierarchyKey__c like 'PARTNER_TYPE.%']);

        tierMap = PFUtils.buildFieldIDMap('HierarchyKey__c', [
                select  Id,
                        HierarchyKey__c
                  from  Classification__c
                 where  HierarchyKey__c like 'PARTNER_TIER.%']);

    }

    //
    // Return the partner details for a given ID
    //
    public PFPartnerDetailsMatch partnerDetails(ID accountId) {
        Account acct = [
                select      Id,
                            Name,
                            Account_Alias_Name__c,
                            AliasPublicViewable__c,
                            Company_Email_Address__c,
                            Description_of_Business__c,
                            Select_Specialization_s__c,
                            PartnerStatuses__c,
                            Website,
                            Phone,
                            Application_Types__c,
                            Hardware_Focus__c,
                            Industry_Focus__c,
                            Middleware_Supported__c,
                            Operating_System_Supported__c,
                            Ownership_Type__c,
                            Software_Focus__c,
                            Additional_Countries_of_Operation__c,
                            Total_Partner_Sales_Certifications__c,
                            Total_Partner_Technical_Certifications__c,
                            Target_Market_Size__c,
                            Hardware_Platform__c,
                            ShippingStreet,
                            ShippingCity,
                            ShippingState,
                            ShippingPostalCode,
                            ShippingCountry,
                            BillingStreet,
                            BillingCity,
                            BillingState,
                            BillingPostalCode,
                            BillingCountry,
                            PlatformProductCount__c,
                            JBossProductCount__c,
                            Partner_Skill__c
                  from      Account
                 where      Id = :accountId
                            and Is_Partner_Published__c = True
                            and IsPartner = True
                            and VisibleApprovedStatuses__c > 0
                ];
        List<PartnerLogo__c> logoList = [
                select  Id,
                        Partner__c,
                        (select Id from Attachments)
                  from  PartnerLogo__c
                 where  Partner__c = :accountId
        ];
        List<Partner_Location__c> loclist = [
                select      Id,
                            Name,
                            Street__c,
                            City__c,
                            State_Province__c,
                            Postal_Code__c,
                            Country__c,
                            Description__c,
                            Email__c,
                            Website__c,
                            Phone__c,
                            Point_of_Contact__c,
                            Latitude__c,
                            Longitude__c,
                            Is_Primary__c
                  from      Partner_Location__c
                 where      Partner__c = :accountId
              order by      Country__c, State_Province__c
        ];
        Integer prodCount = [
                select      count()
                  from      PartnerProduct__c
                 where      Partner__c = :accountId
                            and Application_Status__c = 'Approved'
                            and Application_Visibility__c = 'Visible'
        ];
        Partner_Location__c primLoc = PFUtils.getPrimaryLocation(acct, loclist);

        ID logoMatch = null;
        if (logoList.size() > 0 && logoList.get(0).attachments != null && logoList.get(0).attachments.size() > 0){
            logoMatch = logoList.get(0).attachments[0].Id;
        }

        return new PFPartnerDetailsMatch(acct, loclist, logoMatch, primLoc, prodCount);
    }

    //
    // Main search entry point.
    //
    public PFSearchResult partnerSearch(PFSearchContext ctx) {
        String soql = createWhereClause(ctx, null);
        System.debug('[PF]-------------------------- soql=' + soql);
        PFSearchResult result = new PFSearchResult(ctx, soql);
        Datetime startTimer = Datetime.now();
        execute(ctx, result);
        result.msExecutionTime = Datetime.now().getTime() - startTimer.getTime();
        return result;
    }


    ///////////////////////////////////////////////////////////////////////////////////////////
    // Private methods
    //

    private String createWhereClause(PFSearchContext ctx, String[] words) {
        String[] soqlFilters = buildSoqlFilters(ctx, words);
        String[] soqlProximity = buildSoqlProximityFilters(ctx);
        soqlFilters.addAll(soqlProximity);
        return makeSoql(ctx, soqlFilters, 'order by Partner__r.Finder_Sort_Hint__c, Partner__r.Name');
    }

    private String[] buildSoqlProximityFilters(PFSearchContext ctx) {
        String[] soqlFilters = new List<String>();

        if (ctx.isLocationSearch() && !ctx.isProximitySearch()) {
            if (!PFUtils.isEmpty(ctx.country)) {
                soqlFilters.add('Country__c = \'' + ctx.country + '\'');
            }
            if (!PFUtils.isEmpty(ctx.state)) {
                soqlFilters.add('State_Province__c = \'' + String.escapeSingleQuotes(ctx.state) + '\'');
            }
            if (!PFUtils.isEmpty(ctx.city)) {
                soqlFilters.add('City__c like \'%' + String.escapeSingleQuotes(ctx.city) + '%\'');
            }
        }

        if (ctx.isProximitySearch()) {
            PFGeoPoint center = new PFGeoPoint(Double.valueOf(ctx.latitude), Double.valueOf(ctx.longitude));
            Double tmpdist = Double.valueOf(ctx.distance);
            Double distKm = tmpdist;
            if (ctx.isMiles) {
                distKm = PFUtils.convertMilesToKilometers(tmpdist);
            }
            ctx.boundingBox = PFUtils.getBounds(center, distKm);
            PFGeoPoint ne = ctx.boundingBox.northeast;
            PFGeoPoint sw = ctx.boundingBox.southwest;
            System.debug('[PF]----------------- ne.lng = ' + ne.lng());
            System.debug('[PF]----------------- ne.lat = ' + ne.lat());
            System.debug('[PF]----------------- sw.lng = ' + sw.lng());
            System.debug('[PF]----------------- sw.lat = ' + sw.lat());

            soqlFilters.add(    '(Latitude__c <= ' + ne.lat() + ' and ' +
                                'Longitude__c <= ' + ne.lng() + ' and ' +
                                'Latitude__c >= ' + sw.lat() + ' and ' +
                                'Longitude__c >= ' + sw.lng() + ')');
        }
        return soqlFilters;
    }

    //
    // Main function for building out the SOQL query
    //
    private String[] buildSoqlFilters(PFSearchContext ctx, String[] words) {
        String[] soqlFilters = new List<String>();
        //
        // add in the default constraints
        //
        soqlFilters.add('Partner__r.IsPartner = True');
        soqlFilters.add('Partner__r.Is_Partner_Published__c = True');
        soqlFilters.add('Partner__r.PartnerStatuses__c != \'\'');
        soqlFilters.add('Partner__r.VisibleApprovedStatuses__c > 0');
        if (!ctx.isProximitySearch() && !ctx.isLocationSearch()) {
            soqlFilters.add('ActivationStatus__c = \'Active\'');
        }

        String keywords = String.escapeSingleQuotes(ctx.keywords);
        if (words == null || words.size() == 0) {
            if (!PFUtils.isEmpty(keywords)) {
                String expr =   '(Partner__r.Name like \'%' + keywords + '%\'' +
                                ' or Partner__r.Account_Alias_Name__c like \'%' + keywords + '%\'' +
                                ' or Partner__r.PartnerKeywords__c like \'%' + keywords + '%\')';
                soqlFilters.add(expr);
            }
        }
        else {
            //
            // if words is not null then this search should be conducted on each
            // individual word rather than the entire phrase
            //
            String[] exprlist = new List<String>();
            for (String word : words) exprlist.add('Partner__r.Name like \'%' + String.escapeSingleQuotes(word.trim()) + '%\'');
            for (String word : words) exprlist.add('Partner__r.Account_Alias_Name__c like \'%' + String.escapeSingleQuotes(word.trim()) + '%\'');
            for (String word : words) exprlist.add('Partner__r.PartnerKeywords__c like \'%' + String.escapeSingleQuotes(word.trim()) + '%\'');
            String orClause = '(' + PFUtils.joinStrings(exprlist, ' or ') + ')';
            soqlFilters.add(orClause);
        }

        if (!PFUtils.isEmpty(ctx.industryFocus)) {
            soqlFilters.add('Partner__r.Industry_Focus__c includes (\'' + ctx.industryFocus + '\')');
        }
        if (!PFUtils.isEmpty(ctx.skills)) {
        	soqlFilters.add('Partner__r.Partner_Skill__c includes (\'' + ctx.skills + '\')');
        }
        if (!PFUtils.isEmpty(ctx.applicationType)) {
            soqlFilters.add('Partner__r.Application_Types__c includes (\'' + ctx.applicationType + '\')');
        }
        /*
        if (!PFUtils.isEmpty(ctx.globalRegion) && !ctx.isLocationSearch() && !ctx.isProximitySearch()) {
            soqlFilters.add('Partner__r.Global_Region__c = \'' + ctx.globalRegion + '\'');
        }
        */
        if ((ctx.partnerType == RESELLER_SELECT || ctx.partnerType == CORP_RESELLER_SELECT) && !PFUtils.isEmpty(ctx.specialization)) {
            soqlFilters.add(buildMultiselectTest('Partner__r.Select_Specialization_s__c', ctx.specialization));
        }
        if (ctx.partnerType == ISV_SELECT) {
            //
            // force this to be an OR test (set inclusion)
            //
            String[] args = new List<String>();
            if (ctx.hasJBossProducts) {
                args.add('Partner__r.JBossProductCount__c > 0');
            }
            if (ctx.hasPlatformProducts) {
                args.add('Partner__r.PlatformProductCount__c > 0');
            }
            if (args.size() > 0) {
                soqlFilters.add('(' + PFUtils.joinStrings(args, ' or ') + ')');
            }
        }
        if (ctx.partnerType == TRAINING_SELECT && ctx.trainingTypes.size() > 0) {
            soqlFilters.add(buildMultiSelectORTest('Partner__r.Training_Partner_Specifications__c', ctx.trainingTypes));
        }
        filterbyPartnerType(soqlFilters, ctx);
        filterbyPartnerTier(soqlFilters, ctx);
        return soqlFilters;
    }

    //
    // Create SOQL WHERE clause for Partner Type
    //
    private void filterByPartnerType(String[] soqlFilters, PFSearchContext ctx) {
        Boolean isIsv = False;
        String[] tmp = new List<String>();
        String partnerType = ctx.PartnerType;
        if (PFUtils.isEmpty(partnerType)) {
            String isvId = typeMap.get('PARTNER_TYPE.ISV');
            soqlFilters.add('((Partner__r.Finder_Partner_Type__c = \'' + isvId + '\' and Partner__r.PartnerProductCount__c > 0) or Partner__r.Finder_Partner_Type__c != \'' + isvId + '\')');
            return;
        }

        if (partnerType == ISV_SELECT) {
            isIsv = True;
            tmp.add(typeMap.get('PARTNER_TYPE.ISV'));
        }
        else if (partnerType == RESELLER_SELECT) {
            tmp.add(typeMap.get('PARTNER_TYPE.RESELLER'));
        }
        else if (partnerType == 'Hosting') {
            tmp.add(typeMap.get('PARTNER_TYPE.HOSTING'));
        }
        else if (partnerType == CORP_RESELLER_SELECT) {
            tmp.add(typeMap.get('PARTNER_TYPE.CORPORATE_RESELLER'));
        }
        else if (partnerType == 'OEM') {
            tmp.add(typeMap.get('PARTNER_TYPE.OEM'));
        }
        else if (partnerType == 'Systems Integrator (SI)') {
            tmp.add(typeMap.get('PARTNER_TYPE.SI'));
        }
        else if (partnerType == 'Distributor') {
            tmp.add(typeMap.get('PARTNER_TYPE.DISTRIBUTOR'));
        }
        else if (partnerType == 'Cloud / Virtualization') {
            tmp.add(typeMap.get('PARTNER_TYPE.CLOUD_VIRTUALIZATION'));
        }
        else if (partnerType == TRAINING_SELECT) {
            tmp.add(typeMap.get('PARTNER_TYPE.TRAINING'));
        }
        else if (partnerType == SERVICECLOUD_PROVIDER) {
            tmp.add(typeMap.get('PARTNER_TYPE.SERVICECLOUD_PROVIDER'));
        }
        //else if (partnerType == PartnerConst.CCNSP) { // 2015.May.12 JDG - Commented out for DE8423.
        //    tmp.add(typeMap.get('PARTNER_TYPE.CCNSP'));
        //}
        else {
            System.debug('[PF]-------------- unsupported partner type *************: ' + partnerType);
        }

        if (tmp.size() > 0) {
            String setTest = buildSetTest('Partner__r.Finder_Partner_Type__c', tmp);
            if (isIsv) {
                soqlFilters.add('(' + setTest + 'and Partner__r.PartnerProductCount__c > 0)');
            }
            else {
                soqlFilters.add(setTest);
            }
        }
    }

    //
    // Create SOQL WHERE clause for Partner Tier/Level
    //
    private void filterByPartnerTier(String[] soqlFilters, PFSearchContext ctx) {
        String[] tmp = new List<String>();
        for (String partnerTier : ctx.PartnerTier) {
            if (PFUtils.isEmpty(partnerTier)) continue;

            if (partnerTier == 'Ready') {
                tmp.add(tierMap.get('PARTNER_TIER.READY'));
            }
            else if (partnerTier == 'Advanced') {
                tmp.add(tierMap.get('PARTNER_TIER.ADVANCED'));
            }
            else if (partnerTier == 'Premier') {
                tmp.add(tierMap.get('PARTNER_TIER.PREMIER'));
            }
            else {
                System.debug('[PF]-------------- unsupported partner tier *************: ' + partnerTier);
            }
        }
        if (tmp.size() > 0) {
            soqlFilters.add(buildSetTest('Partner__r.Finder_Partner_Tier__c', tmp));
        }
    }

    //
    // Constructed SOQL query executed here.  The 'result' parameter is populated with the PartnerStatus IDs
    //
    private void execute(PFSearchContext ctx, PFSearchResult result) {
        System.debug('soql=' + result.soql);
        List<SObject> pslist = Database.query(result.soql);
        if ((pslist == null || pslist.size() == 0) && ctx.keywords.length() > 0) {
            //
            // try searching on individual keywords
            //
            String[] words = normalize(ctx.keywords.split(' '));
            if (words.size() < 2) {
                // no point searching on something we just searched on
                result.resultType = 'Partner';
                return;
            }
            String soql = createWhereClause(ctx, words);
            pslist = Database.query(soql);
        }
        result.resultIdList = new List<Id>();
        result.matchedLocations = null;

        if (!ctx.isProximitySearch() && !ctx.isLocationSearch()) {
            for (SObject sps : pslist) {
                PartnerStatus__c ps = (PartnerStatus__c) sps;
                result.resultIdList.add(ps.Partner__c);
                result.resultType = 'Partner';
            }
        }
        else {
            result.matchedLocations = new Map<ID, Partner_Location__c>();
            for (SObject sloc : pslist) {
                Partner_Location__c loc = (Partner_Location__c) sloc;
                result.resultIdList.add(loc.Id);
//              result.matchedLocations.put(loc.Partner__c, loc);
                result.resultType = 'Location';
            }
        }
    }

    private String makeSoql(PFSearchContext ctx, String[] whereFilters, String orderBy) {
        String soqlWhere = 'where ' + PFUtils.joinStrings(whereFilters, ' and ');
        if (ctx.isProximitySearch() || ctx.isLocationSearch()) {
            if (ctx.isProximitySearch()) {
                //System.debug('[PF]---------------- lng=' + ctx.longitude);
                //System.debug('[PF]---------------- lat=' + ctx.latitude);
            }
            return 'select Name, Street__c, City__c, State_Province__c, Postal_Code__c, Country__c, Partner__c, Longitude__c, Latitude__c, Is_Primary__c from Partner_Location__c ' + soqlWhere + ' ' + orderBy;


        }
        return 'select Partner__c from PartnerStatus__c ' + soqlWhere + ' ' + orderBy;

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

    private String buildMultiselectTest(String field, String[] testset) {
        //
        // start the INCLUDES clause
        //
        String s = field + ' includes (';
        //
        // make a new set enclosed in quotes
        //
        String[] workingset = new List<String>();
        for (String aTest : testset) {
            workingset.add('\'' + aTest.trim() + '\'');
        }
        s += PFUtils.joinStrings(workingset, ',');
        //
        // close the clause
        s += ')';

        return s;
    }

    private String buildMultiSelectORTest(String multiselectField, String[] values) {
        String[] args = new List<String>();
        for (String val : values) {
            args.add(multiselectField + ' includes (\'' + val + '\')');
        }
        if (args.size() > 0) {
            return '(' + PFUtils.joinStrings(args, ' or ') + ')';
        }
        return '';
    }

    private String buildSetTest(String field, String[] testset) {
        //
        // start the IN clause
        //
        String s = field + ' in (';
        //
        // make a new set enclosed in quotes
        //
        String[] workingset = new List<String>();
        for (String aTest : testset) {
            workingset.add('\'' + aTest.trim() + '\'');
        }
        s += PFUtils.joinStrings(workingset, ',');
        //
        // close the clause
        s += ')';

        return s;
    }

}