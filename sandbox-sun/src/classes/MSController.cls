public with sharing class MSController {
    private static final String PROFILE_PUBLIC_MICROSITE = 'Public Microsite Profile';
    private static final String PUBLIC_SITE = 'Public';
    private static final String PARTNER_SITE = 'Partner';
    private static final String PRIVATE_SITE = 'Red Hat Internal';


    transient public PartnerUtil.ContentPair[] pageContent	{get; private set; }
    transient public PartnerUtil.ContentPair[] sectionContent {get; private set; }

    public ApexPages.StandardController controller	{get; set; }
    private User me = null;
	public RH_Microsite__c siteinfo {get; set;}
	public RH_Microsite_Page__c pageinfo {get; set; }

//
// this is all defunct
//


    public MSController() {
    }

    public MSController(ApexPages.StandardController controller) {
        this.controller = controller;
      	pageContent = null;
    }

    public void initWithContent() {
        try {
        	//String pageName = System.currentPageReference().getUrl().substring(6);
	        String pageName = URL.getCurrentRequestURL().getPath().substring(6);
            loadContentForPage(pageName);
        }
        catch (System.QueryException ex) {
            pageContent = new List<PartnerUtil.ContentPair>();
        }
    }

    public void setSectionKey(String key) {
    	if (key == null) {
    		return;
    	}
		sectionContent = new List<PartnerUtil.ContentPair>();
		System.debug('*****[debug]***** setting sectionKey to ' + key);
		if (pageContent == null) {
			System.debug('****[debug]**** no page content for section');
			return;
		}
		integer reccnt = 0;
		System.debug('****[debug]**** limiting section size to ' + siteInfo.Max_Section_Items__c);
		for (PartnerUtil.ContentPair cp : pageContent) {
			System.debug('****[debug]**** comparing: ' + key + ' and ' + cp.rhcontent.Section__c);
			if (cp.rhcontent.Section__c == key && sectionContent.size() < siteInfo.Max_Section_Items__c) {
				sectionContent.add(cp);
				reccnt += 1;
			}
		}
		System.debug('****[debug]**** section content size is ' + sectionContent.size());
    }

    private void loadContentForPage(String pageName) {
    	System.debug('*****[debug]***** loading content for ' + pageName);
    	pageContent = getContent(pageName);
    }

    public MSController getThis() {
    	return this;
    }

    private PartnerUtil.ContentPair[] getContent(String pageName) {

		pageinfo = [select Id, Site__c, Page__c from RH_Microsite_Page__c where VF_Page__c = :pageName limit 1];
		System.debug('*****[debug]***** site=' + pageinfo.Site__c + ', page=' + pageinfo.Page__c);
		if (siteinfo == null) {
			siteinfo = [select Site__c, Max_Section_Items__c from RH_Microsite__c where Site__c = :pageinfo.Site__c];
		}

        RH_Content__c[] mc = [
            select  Id,
            		Site__c,
                    Page__c,
                    Section__c,
                    Annotation__c,
                    IsFeatured__c,
                    ContentDocumentId__c,
                    Sort_Order__c,
                    IsNew__c,
                    KalturaId__c,
                    Kaltura_Thumbnail_URL__c
            from    RH_Content__c
            where	Site__c = :siteinfo.Site__c
            and   	Page__c = :pageinfo.Page__c
            and     Audience__c includes (:accessType)
            and		IsPublished__c = true
            order by Section__c, Sort_Order__c, Name
        ];
        System.debug('*****[debug]***** rhcontent found=' + mc.size());

        pageContent = PartnerUtil.fetchMatchingContent(mc);
        System.debug('*****[debug]***** matched pageContent size is ' + pageContent.size());
        sectionContent = null;
        return pageContent;
    }

    private PartnerUtil.ContentPair[] getAnnotatedContent(String annotation) {

		System.debug('*****[debug]***** loading for annotation ' + annotation);
        RH_Content__c[] mc = [
            select  Id,
            		Site__c,
                    Page__c,
                    Section__c,
                    Annotation__c,
                    IsFeatured__c,
                    ContentDocumentId__c,
                    Sort_Order__c,
                    IsNew__c,
                    KalturaId__c,
                    Kaltura_Thumbnail_URL__c
            from    RH_Content__c
            where	Site__c = :siteinfo.Site__c
            and     Audience__c includes (:accessType)
            and		Annotation__c includes (:annotation)
            and		IsPublished__c = true
            order by Section__c, Sort_Order__c, Name
        ];
        System.debug('*****[debug]***** annotated rhcontent found=' + mc.size());

        sectionContent = PartnerUtil.fetchMatchingContent(mc);
        System.debug('*****[debug]***** matched pageContent size is ' + pageContent.size());
        return sectionContent;
    }

    public void setAnnotationFilter(String annotation) {
    	getAnnotatedContent(annotation);
/*
		PartnerUtil.ContentPair[] filteredList = new List<PartnerUtil.ContentPair>();
		if (sectionContent == null) {
			sectionContent = pageContent;
		}
		for (PartnerUtil.ContentPair cp : sectionContent) {
			if (cp.rhcontent.Annotation__c != null && cp.rhcontent.Annotation__c.contains(annotation)) {
				filteredList.add(cp);
			}
		}
		sectionContent = filteredList;
*/
		System.debug('*****[debug]***** filtered size=' + sectionContent.size());
    }

    public User currentUser {
        get {
            if (me == null) {
                me = [
                    select  u.Id,
                            u.Profile.Name,
                            u.ContactId,
                            u.Contact.Account.Id
                    from    User u
                    where   u.Id = :UserInfo.getUserId()
                ];
            }
            return me;
        }
    }

   private String accessType {
        get {
            if (currentUser == null || currentUser.Profile.Name == PROFILE_PUBLIC_MICROSITE) {
                System.debug('[debug]---------------------- accessType=' + PUBLIC_SITE);
                return PUBLIC_SITE;
            }
            if (currentUser.Profile.Name.indexOf('Partner') >= 0) {
                System.debug('[debug]---------------------- accessType=' + PARTNER_SITE);
                return PARTNER_SITE;
            }
            System.debug('[debug]---------------------- accessType=' + PRIVATE_SITE);
            return PRIVATE_SITE;
        }
    }

	// ----------------[component support]---------------

	public Boolean canRender {
		get {
			return !(sectionContent == null || sectionContent.size() == 0);
		}
	}

	// ----------------[tests]-------------

	static private void createSiteForTest() {
		String site_name = 'Jurassic Park';
		RH_Microsite__c site = new RH_Microsite__c(Site__c = site_name);
		insert site;

		RH_Microsite_Page__c page1 = new RH_Microsite_Page__c(Site__c = site_name, Page__c = 'Isla Nublar', VF_Page__c = 'IslaNublarPage');
		insert page1;

		RH_Microsite_Page__c page2 = new RH_Microsite_Page__c(Site__c = site_name, Page__c = 'Isla Sorna', VF_Page__c = 'IslaSornaPage');
		insert page2;
	}

	static private void createContentForTest() {
		ContentVersion[] cvlist = [select Id, Title, ContentDocumentId from ContentVersion where IsLatest = true and IsDeleted = false and PublishStatus = 'P' limit 15];
		System.debug('*****[debug]***** cvlist size=' + cvlist.size());
		RH_Content__c[] rhclist = new List<RH_Content__c>();
		for (Integer i = 0; i < cvlist.size(); i++) {
			ContentVersion cv = cvlist.get(i);

			RH_Content__c rhc = new RH_Content__c();
			rhc.ContentDocumentId__c = cv.ContentDocumentId;
			rhc.IsNew__c = true;
			rhc.IsPublished__c = true;
			rhc.Audience__c = PRIVATE_SITE;
			if (cv.Title.length() > 80)
				rhc.Name = cv.Title.substring(0, 80);
			else
				rhc.Name = cv.Title;
			if (i < 7) {
				// create a large section for testing limits
				rhc.Site__c = 'Jurassic Park';
				rhc.Page__c = 'Isla Nublar';
				rhc.Section__c = 'Raptor';
				if (i < 3) {
					rhc.Annotation__c = 'AAAAAAH';
				}
			}
			else if (i < 9) {
				rhc.Site__c = 'Jurassic Park';
				rhc.Page__c = 'Isla Nublar';
				rhc.Section__c = 'T-Rex';
			}
			else {
				rhc.Site__c = 'Jurassic Park';
				rhc.Page__c = 'Isla Sorna';
				rhc.Section__c = 'Spinosaurus';
			}
			rhclist.add(rhc);
		}
		insert rhclist;
	}


	@IsTest(SeeAllData=true) static void basicTest() {
		createSiteForTest();
		createContentForTest();

		RH_Content__c[] clist = [select Id, Site__c, Page__c, IsPublished__c, Audience__c from RH_Content__c where Site__c = 'Jurassic Park'];
		for (RH_Content__c rhc : clist) {
			System.debug('--------------> page=' + rhc.Page__c + ', audience=' + rhc.Audience__c + ', IsPublished__c=' + rhc.IsPublished__c);
		}

		MSController ctrl = new MSController();
		ctrl.loadContentForPage('IslaNublarPage');

		//System.Assert(ctrl.pageContent.size() == 9, 'Unexpected number of page results, found ' + ctrl.pageContent.size());

		ctrl.setSectionKey('T-Rex');
		//System.Assert(ctrl.sectionContent.size() == 2, 'Unexpected number of section results, found ' + ctrl.sectionContent.size());
		//System.assert(ctrl.canRender, 'canRender is false');

		//ctrl.setAnnotationFilter('AAAAAAH');
		//System.Assert(ctrl.sectionContent.size() == 0, 'Expected to find no annotations, found ' + ctrl.sectionContent.size());

		ctrl.setSectionKey('Raptor');
		ctrl.setAnnotationFilter('AAAAAAH');
		//System.Assert(ctrl.sectionContent.size() == 3, 'Unexpected number of annotation results, found ' + ctrl.sectionContent.size());
	}

}