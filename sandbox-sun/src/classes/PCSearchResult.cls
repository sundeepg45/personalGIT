public without sharing class PCSearchResult {

    public Id[] resultIdList { get; set; }
    public PCSearchContext ctx { get; private set; }
    public Long msExecutionTime { get; set; }
    public Integer  currentPage { get; set; }
    public Integer  totalPages  { get; set; }
    public String soql { get; private set; }


    public PCSearchResult(PCSearchContext aContext, String theSoql) {
        currentPage = 0;
        totalPages = 0;
        ctx = aContext;
        soql = theSoql;
    }

    public List<PCProductMatch> getPage(Integer pagenum) {
        currentPage = pagenum + 1;
        if (resultIdList != null && ctx != null){
            totalPages = pageCount();
        } else {
            totalPages = 0;
        }
        return getProductPage(pagenum);
    }

    public List<PCProductMatch> getProductPage(Integer pagenum) {
        List<PCProductMatch> rows = new List<PCProductMatch>();
        if (resultIdList == null) {
            return rows;
        }
        if (pagenum > (resultIdList.size() / ctx.pagesize)) {
            return rows;
        }
        Integer pagestart = pagenum * ctx.pagesize;

        //
        // batch up all the product IDs for faster retrieval
        //
        List<Id> idList = new List<Id>();
        for (Integer rownum = 0; rownum < ctx.pagesize; rownum++) {
            Integer absrownum = pagestart + rownum;
            if (absrownum >= resultIdList.size()) {
                break;
            }
            Id rowId = resultIdList[absrownum];
            idList.add(rowId);
        }

        List<PartnerProduct__c> prodlist = [
                select      Id,
                            Full_Product_Name__c,
                            Partner__r.Name,
                            Application_Type__r.Name,
                            Keywords__c,
                            Product_URL_2__c,
                            Product_URL_2_Info__c,
                            Call_To_Action_Text__c,
                            Distribution_Licensing__c,
                            Product_Details__c,
                            pricing_and_support_details__c,
                            ProductSummary__c,
                            Application_Website__c,
                            Source_Licensing__c,
                            Success_Story__c,
                            Software_Category__c,
                            RHEL_Platforms_Supported__c,
                            Platforms__c,
                            JBoss_Platforms_Supported__c,
                            JBoss_Platform__c,
                            Industry_Focus__c,
                            Usage_Licensing__c
                  from      PartnerProduct__c
                 where      Id in :idList
                 order by   Partner__r.Finder_Sort_Hint__c, Name
        ];
        List<PartnerProductLogo__c> logoList = [
                select  Id,
                        PartnerProduct__c,
                        (select Id from Attachments)
                  from  PartnerProductLogo__c
                 where  PartnerProduct__c in :prodlist
        ];

        //
        // bundle it all together
        //
        for (PartnerProduct__c prod : prodlist) {
            Id logoMatch = null;
            for (PartnerProductLogo__c logo : logoList) {
                if (logo.PartnerProduct__c == prod.Id) {
                    List<Attachment> attachments = logo.Attachments;
                    if (attachments != null && attachments.size() > 0) {
                        logoMatch = attachments[0].Id;
                    }
                    break;
                }
            }
            rows.add(new PCProductMatch(prod, logoMatch));
        }

        return rows;
    }

    public Integer matchCount() {
        return resultIdList.size();
    }

    public Integer pageCount() {
        Integer pages = matchCount() / ctx.pageSize;
        if (math.mod(matchCount(), ctx.pageSize) > 0) pages++;
        return pages;
    }

    public Integer skipFivePrevPages
    {
        get {
            if (currentPage - 5 > 0)
                return currentPage - 5;
            else
                return -1;
        }
    }

    public Integer skipPrevPage
    {
        get {
            if (currentPage - 2 > 0)
                return currentPage - 2;
            else
                return -1;
        }
    }

    public Integer prevPage
    {
        get {
            if (currentPage - 1 > 0)
                return currentPage - 1;
            else
                return -1;
        }
    }

    public Integer nextPage
    {
        get {
            if (currentPage + 1 <= totalPages)
                return currentPage + 1;
            else
                return -1;
        }
    }

    public Integer skipNextPage
    {
        get {
            if (currentPage + 2 <= totalPages)
                return currentPage + 2;
            else
                return -1;
        }
    }

    public Integer skipFiveNextPages
    {
        get {
            if (currentPage + 5 <= totalPages)
                return currentPage + 5;
            else
                return -1;
        }
    }
}