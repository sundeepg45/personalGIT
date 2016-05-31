public without sharing class PFSearchResult {

	public Id[]							resultIdList		{ get; set; }
	public String						resultType			{ get; set; }
	public Map<Id,Partner_Location__c>	matchedLocations	{ get; set; }
	public PFSearchContext				ctx					{ get; private set; }
	public String						soql				{ get; private set; }
	public Long							msExecutionTime		{ get; set; }
	public Integer						currentPage		    { get; set; }
	public Integer						totalPages			{ get; set; }


	public PFSearchResult(PFSearchContext aContext, String theSoql) {
		currentPage = 0;
		totalPages = 0;
		ctx = aContext;
		soql = theSoql;
	}

	public List<PFPartnerMatch> getPage(Integer pagenum) {
		return getPartnerPage(pagenum);
	}

	public List<PFPartnerMatch> getPartnerPage(Integer pagenum) {
		currentPage = pagenum + 1;
		if (resultIdList != null && ctx != null){
			totalPages = pageCount();
		} else {
			totalPages = 0;
		}

		if (resultType == 'Partner') {
			return getPartnerPageFromPartnerList(pagenum);
		}
		return getPartnerPageFromLocationList(pagenum);
	}

	private List<PFPartnerMatch> getPartnerPageFromPartnerList(Integer pagenum) {
		List<PFPartnerMatch> rows = new List<PFPartnerMatch>();
		if (resultIdList == null) {
			return rows;
		}
		if (pagenum > totalPages) {
			return rows;
		}
		Integer pagestart = pagenum * ctx.pagesize;

		System.debug('[PF]----------------- resultsize=' + resultIdList.size());
		//
		// batch up all the account IDs for faster retrieval
		//
		List<Id> acctIdList = new List<Id>();
		for (Integer rownum = 0; rownum < ctx.pagesize; rownum++) {
			Integer absrownum = pagestart + rownum;
			if (absrownum >= resultIdList.size()) {
				break;
			}
			Id rowId = resultIdList[absrownum];
			acctIdList.add(rowId);
		}
		System.debug('[PF]----------------------- acctIdlist.size=' + acctIdList.size());

		List<Account> acctlist = fetchAccountList(acctIdList);
		List<PartnerLogo__c> logoList = fetchLogoList(acctIdList);
		List<Partner_Location__c> primaryLocationList = fetchLocations('Partner__c', acctIdList, true);

		System.debug('[PF]----------------------- idlist=' + acctIdList);

		//
		// bundle it all together
		//
		for (Account acct : acctlist) {
			Id logoMatch = findPartnerLogo(logoList, acct.id);
			Partner_Location__c primLoc = findPrimaryLocation(primaryLocationList, acct);
			rows.add(new PFPartnerMatch(acct, logoMatch, primLoc, null));
		}
		System.debug('[PF]---------------------------- returning rows=' + rows.size());

		return rows;
	}

	private List<PFPartnerMatch> getPartnerPageFromLocationList(Integer pagenum) {
		List<PFPartnerMatch> rows = new List<PFPartnerMatch>();
		if (resultIdList == null) {
			return rows;
		}
		if (pagenum > totalPages) {
			return rows;
		}
		Integer pagestart = pagenum * ctx.pagesize;

		System.debug('[PF]----------------- resultsize=' + resultIdList.size());
		//
		// batch up all the Location IDs for faster retrieval
		//
		List<Id> locationIdList = new List<Id>();
		for (Integer rownum = 0; rownum < ctx.pagesize; rownum++) {
			Integer absrownum = pagestart + rownum;
			if (absrownum >= resultIdList.size()) {
				break;
			}
			Id rowId = resultIdList[absrownum];
			locationIdList.add(rowId);
		}

		//
		// Get all the locations for this page of results
		//
		List<Partner_Location__c> loclist = fetchLocations('Id', locationIdList, false);

		//
		// Make a list of the account IDs for the locations
		//
		List<ID> acctIdList = new List<ID>();
		for (Partner_Location__c ploc : loclist) acctIdList.add(ploc.Partner__c);

		//
		// Get the accounts and logos
		//
		Map<ID, Account> acctmap = fetchAccountMap(acctIdList);
		List<PartnerLogo__c> logoList = fetchLogoList(new List<ID>(acctmap.keySet()));

		//
		// Now get just the primary locations if we need to
		//
		List<Partner_Location__c> primaryLocationList = null;
		primaryLocationList = fetchLocations('Partner__c', new List<Id>(acctmap.keySet()), True);

		//
		// bundle it all together
		//
		for (Partner_Location__c ploc : loclist) {
			Account acct = acctmap.get(ploc.Partner__c);
			Id logoMatch = findPartnerLogo(logoList, acct.Id);
			Partner_Location__c primLoc = findPrimaryLocation(primaryLocationList, acct);
			rows.add(new PFPartnerMatch(acct, logoMatch, primLoc, ploc));
		}

		return rows;
	}

	private PartnerLogo__c[] fetchLogoList(ID[] acctIdList) {
		return [
				select	Id,
						Partner__c,
						(select Id from Attachments)
				  from	PartnerLogo__c
				 where	Partner__c in :acctIdList
		];
	}

	private List<Account> fetchAccountList(ID[] idlist) {
		return [
			select		Id,
						Name,
						Account_Alias_Name__c,
						AliasPublicViewable__c,
						Select_Specialization_s__c,
						Partner_Skill__c,
						Partner_Type__c,
						PartnerStatuses__c,
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
						Phone,
						Website,
						Description_of_Business__c
			  from		Account
			 where		Id in :idList
			 order by 	Finder_Sort_Hint__c, Name
		];
	}

	private Map<ID, Account> fetchAccountMap(ID[] idList) {
		return new Map<ID, Account>(fetchAccountList(idList));
	}

	private ID findPartnerLogo(PartnerLogo__c[] logoList, ID acctId) {
		for (PartnerLogo__c logo : logoList) {
			if (logo.Partner__c == acctId) {
				List<Attachment> attachments = logo.Attachments;
				if (attachments != null && attachments.size() > 0) {
					return attachments[0].Id;
				}
			}
		}
		return null;
	}

	private Partner_Location__c findPrimaryLocation(Partner_Location__c[] primaryLocationList, Account acct) {
		//
		// Find the primary location.  If not found, fall back
		//
		for (Partner_Location__c loc : primaryLocationList) {
			if (loc.Partner__c == acct.Id) {
				return loc;
			}
		}
		return PFUtils.getPrimaryLocation(acct, null);
	}

	private List<Partner_Location__c> fetchLocations(String matchOn, ID[] idList, Boolean primaryOnly) {
		 String soql =	'select Id, Name, Street__c, City__c, State_Province__c, Postal_Code__c,Country__c,	Description__c,' +
		 				'	 	Email__c,Website__c,Phone__c,Point_of_Contact__c,Latitude__c,Longitude__c,Is_Primary__c,Partner__c,' +
		 				'		Point_of_Contact_Phone__c' +
		 				'  from		Partner_Location__c ' +
						' where		' + matchOn + ' in :idList';
		if (primaryOnly) soql += ' and Is_Primary__c = True';
		soql += ' order by  Partner__r.Finder_Sort_Hint__c, Partner__r.Name';

		return Database.query(soql);
	}

	public PFPartnerMatch[] getFeaturedPartners() {
		if (ctx.country == null) {
			System.debug('*****[debug]***** country is null');
			return new PFPartnerMatch[0];
		}
		System.debug('*****[debug]***** country=' + ctx.country);
		Country__c country = [select Global_Region__c from Country__c where Abbreviation__c = :ctx.country limit 1];
		Featured_Partner__c[] fplist = [select Id, Partner__c from Featured_Partner__c where Status__c = 'Active' and Partner__r.Global_Region__c = :country.Global_Region__c];
		System.debug('*****[debug]***** featured rows is ' + fplist.size());
		ID[] accountids = new List<ID>();
		for (Integer i = 0; i < Math.min(3, fplist.size()); i++) {
			accountids.add(fplist.get(i).Partner__c);
		}
		List<Account> acctlist = fetchAccountList(accountids);
		List<PartnerLogo__c> logoList = fetchLogoList(accountids);
		List<Partner_Location__c> primaryLocationList = fetchLocations('Partner__c', accountids, true);

		//
		// bundle it all together
		//
		PFPartnerMatch[] matches = new List<PFPartnerMatch>();
		for (Account acct : acctlist) {
			Id logoMatch = findPartnerLogo(logoList, acct.id);
			Partner_Location__c primLoc = findPrimaryLocation(primaryLocationList, acct);
			matches.add(new PFPartnerMatch(acct, logoMatch, primLoc, null));
		}
		System.debug('*****[debug]***** matches = ' + matches.size());
		return matches;
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