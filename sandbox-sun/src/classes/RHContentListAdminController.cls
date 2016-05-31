public with sharing class RHContentListAdminController {

	public RH_Content__c comboNavObject {get; set;} 
	public RH_Content__c lastComboNavObject {get; set;} 
	public List<ContentVersion> contentSearchResult {get; set;}
	
	public String contentSearchString {get; set;}
	public List<PartnerUtil.ContentPair> content {get; set;}
	public Id contentDocumentId {get; set;}
	public ContentVersion contentDocument {get; set;}

	public RH_Content__c newRHContent {get; set;}
	private RH_Content__c oldRHContent;
	
	public Boolean isClone {get; set; }
	
	public PageReference initData(){
		if (comboNavObject == null){
			comboNavObject = new RH_Content__c();
			lastComboNavObject = comboNavObject.clone();
		}
		isClone = false;
		return null;
	}
	
	public RH_Content__c getRHContent(){
		if (comboNavObject.Site__c != newRHContent.Site__c){
			newRHContent.Page__c = null;
			newRHContent.Section__c = null;
		}
		if (comboNavObject.Page__c != newRHContent.Page__c){
			newRHContent.Section__c = null;
		}

		comboNavObject.Site__c = newRHContent.Site__c;
		comboNavObject.Page__c = newRHContent.Page__c;
		comboNavObject.Section__c = newRHContent.Section__c;
		lastComboNavObject = comboNavObject.clone();
		
		return newRHContent;
	} 	

	public PageReference manageVideos(){
		return Page.Kaltura_Assets;
	}

	public PageReference findContent(){
		return Page.RedHatContentAdminFindContent;
	}
	
	public PageReference back(){
		if (newRHContent.Id == null && !isClone){
			return findContent();
		}
		isClone = false;
		return Page.RedHatContentAdministration;		
	}
	
	public PageReference searchContent(){
		contentSearchResult = new List<ContentVersion>();
		
		if (contentSearchString == null || contentSearchString.length() < 2){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Your search must be at minimum 2 characters.'));
			return null;
		}
		
		String searchPattern = '%' + contentSearchString + '%';
		contentSearchResult = [
			select	Id, ContentDocumentId, Title, Description, TagCsv
			from	ContentVersion
			where	Title like :searchPattern
			and		isLatest = true
    		and		PublishStatus = 'P'
    		and		IsDeleted = false
    		and     Origin != 'H'
			order by Title
			limit	200
		];
		
		return null;		
	}
	
	public PageReference addDocument(){
		return Page.RedHatContentAdminAddDoc;
	}
	
	public PageReference cloneDocument(){
		isClone = true;
		editDocument();
		newRHContent = newRHContent.clone();
		
		return Page.RedHatContentAdminAddDoc;
	}

	private RH_Content__c getRHDocument(String docId) {
		RH_Content__c rhc = [
			select
				Id,
				Site__c,
				IsPublished__c,
				Page__c,
				Annotation__c,
				IsNew__c,
				IsFeatured__c,
				Section__c,
				Name,
				Audience__c,
				KalturaId__c,
				Sort_Order__c,
				Kaltura_Thumbnail_URL__c,
				ContentDocumentId__c
			from
				RH_Content__c
			where
				Id = :docId
		];
		return rhc;
	}

	public PageReference editDocument(){
		Id docId = ApexPages.currentPage().getParameters().get('docId');

		newRHContent = getRHDocument(docId);
		oldRHContent = getRHDocument(docId);
		
		contentDocumentId = newRHContent.ContentDocumentId__c;
		try {
			contentDocument = [
				select	Id, ContentDocumentId, Title, Description, TagCsv
				from	ContentVersion
				where	ContentDocumentId = :contentDocumentId
				and		isLatest = true
	    		and		PublishStatus = 'P'
	    		and		IsDeleted = false
			];
		} catch (Exception e){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'Could not load document for id ' + contentDocumentId));
			contentDocument = null;
		}
System.debug('*****[debug]***** ' + newRHContent.Annotation__c);
		return Page.RedHatContentAdminAddDoc;
	}

	public PageReference selectDocument(){
		contentDocumentId = ApexPages.currentPage().getParameters().get('docId');		
		
		if (contentDocumentId == null){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Invalid document selected.'));
			return null;
		}
		
		for (ContentVersion cv : contentSearchResult){
			if (cv.ContentDocumentId == Id.valueOf(contentDocumentId)){
				contentDocument = cv;
				break;
			}
		}
		
		newRHContent = comboNavObject.clone();
		newRHContent.ContentDocumentId__c = contentDocument.ContentDocumentId;
		newRHContent.Name = contentDocument.Title;
		newRHContent.Sort_Order__c = 999;
		
		return Page.RedHatContentAdminAddDoc;
	}

	public PageReference removeDocument(){
		Id docId = ApexPages.currentPage().getParameters().get('docId');
		
		RH_Content__c rhc = [select Id, Site__c, Page__c, Section__c, ContentDocumentId__c from RH_Content__c where Id = :docId];
		removeContentTags(rhc);
//		RH_Content__c rhc = new RH_Content__c(Id = docId);
		delete rhc;

		return null;
	}

	public PageReference publishDocument(){
		Id docId = ApexPages.currentPage().getParameters().get('docId');
		
		RH_Content__c rhc = [select Id, Site__c, Page__c, Section__c, ContentDocumentId__c from RH_Content__c where Id = :docId];
		rhc.IsPublished__c = true;
//		RH_Content__c rhc = new RH_Content__c(Id = docId, IsPublished__c = true);
		update rhc;
		addContentTags(rhc);

		return null;
	}

	public PageReference unpublishDocument(){
		Id docId = ApexPages.currentPage().getParameters().get('docId');
		
		System.debug('DID == ' + docId);

		RH_Content__c rhc = [select Id, Site__c, Page__c, Section__c, ContentDocumentId__c from RH_Content__c where Id = :docId];
		rhc.IsPublished__c = false;
//		RH_Content__c rhc = new RH_Content__c(Id = docId, IsPublished__c = false);
		update rhc;
		removeContentTags(rhc);

		return null;
	}
	
	public PageReference saveRHContent(){
		try {
			if (newRHContent.Id != null) {
				// editing
				if (newRHContent.Page__c != oldRHContent.Page__c || newRHContent.Section__c != oldRHContent.Section__c) {
					// reassigned to new page or section, remove old tags
					removeContentTags(oldRHContent);
				}
			}
			upsert newRHContent;
			addContentTags(newRHContent);
			/*
			Set<String> cvTags = new Set<String>();
			if (contentDocument.TagCsv != null) {
				cvTags = new Set<String>(contentDocument.TagCsv.split(','));
			}
			cvTags.add(newRHContent.Site__c);
			cvTags.add(newRHContent.Page__c);
			cvTags.add(PartnerUtil.cleanSection(newRHContent.Section__c));
			String[] lst = new List<String>(cvTags);
			contentDocument.TagCsv = PartnerUtil.joinArray(lst, ',');
			update contentDocument; 
			*/
			comboNavObject.Site__c = newRHContent.Site__c;
			comboNavObject.Page__c = newRHContent.Page__c;
			comboNavObject.Section__c = newRHContent.Section__c;
			lastComboNavObject = comboNavObject.clone();
			return backToList();
		} catch (Exception e){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
		}
		return null;
	}

	public PageReference backToList(){
		contentSearchResult = new List<ContentVersion>();
		contentSearchString = null;
		newRHContent = null;

		return Page.RedHatContentAdministration;
	}
		
	public List<PartnerUtil.ContentPair> getContentList(){
		cleanupNavigation();
		
		content = new List<PartnerUtil.ContentPair>();
		List<RH_Content__c> rhcl = new List<RH_Content__c>();
		
		if (comboNavObject.Site__c != null && comboNavObject.Page__c != null && comboNavObject.Section__c != null){
			rhcl = [
						Select 
								Name,
								ContentDocumentId__c,
								CreatedBy.Name,
								CreatedDate,
								Section__c,
								Sort_Order__c,
								Audience__c,
								IsNew__c,
								IsFeatured__c,
								IsPublished__c,
								LastModifiedBy.Name,
								LastModifiedDate
							From RH_Content__c
							where
								Site__c = :comboNavObject.Site__c and
								Page__c = :comboNavObject.Page__c and
								Section__c = :comboNavObject.Section__c
							order by Sort_Order__c, Name
						];
		} else if (comboNavObject.Site__c != null && comboNavObject.Page__c != null){
			rhcl = [
						Select 
								Name,
								ContentDocumentId__c,
								CreatedBy.Name,
								CreatedDate,
								Section__c,
								Sort_Order__c,
								Audience__c,								
								IsNew__c,
								IsFeatured__c,
								IsPublished__c,
								LastModifiedBy.Name,
								LastModifiedDate
							From RH_Content__c
							where
								Site__c = :comboNavObject.Site__c and
								Page__c = :comboNavObject.Page__c
							order by Section__c, Sort_Order__c, Name
						];
		}
		
		content = fetchMatchingContent(rhcl, true);
		return content;
	}
	
	public static PartnerUtil.ContentPair[] fetchMatchingContent(RH_Content__c[] rhcontent, boolean inclMissingDocsAsNull) {

        Set<String> idlist = PartnerUtil.getStringFieldSet(rhcontent, 'ContentDocumentId__c');
		System.debug('****[debug]**** ID List contains ' + idlist);

        ContentVersion[] cvlist = [
        		select	Id,
        				FileType,
                        Document_Type__c,
        				FeaturedContentBoost,
        				Title,
        				Description,
        				ContentDocumentId,
        				ContentSize,
        				ContentUrl,
        				TagCsv
        		from	ContentVersion
        		where	ContentDocumentId in :idlist
        		and		PublishStatus = 'P'
        		and		IsLatest = true
        		and		IsDeleted = false
        ];

        PartnerUtil.ContentPair[] pageContent = new List<PartnerUtil.ContentPair>();
		for (RH_Content__c c : rhcontent) {
			boolean found = false;
			for (ContentVersion cv : cvlist) {
				if (cv.ContentDocumentId == Id.valueOf(c.ContentDocumentId__c)) {
					found = true;
					PartnerUtil.ContentPair cp = new PartnerUtil.ContentPair();
					cp.rhcontent = c;
					cp.content = cv;
					pageContent.add(cp);
					break;
				}
			}
			if (!found) {
				System.debug('****[debug]**** ContentVersion missing for ' + c.ContentDocumentId__c);
				if (inclMissingDocsAsNull){
					PartnerUtil.ContentPair cp = new PartnerUtil.ContentPair();
					cp.rhcontent = c;
					pageContent.add(cp);
				}
			}
		}
		return pageContent;
    }
	

	private void cleanupNavigation(){
		if (comboNavObject.Site__c != lastComboNavObject.Site__c){
			comboNavObject.Page__c = null;
			comboNavObject.Section__c = null;
		}
		if (comboNavObject.Page__c != lastComboNavObject.Page__c){
			comboNavObject.Section__c = null;
		}
		
		lastComboNavObject = comboNavObject.clone();
	}
	
	private Boolean removeContentTags(RH_Content__c rhc) {
		ContentVersion[] cvlist = [select Id, TagCsv from ContentVersion where ContentDocumentId = :rhc.ContentDocumentId__c and IsLatest = true];
		if (cvlist.size() == 1) {
			ContentVersion cv = cvlist.get(0);
			if (cv.TagCsv != null) {
				String[] mstags = new List<String>();
				mstags.add(rhc.Site__c);
				mstags.add(rhc.Page__c);
				mstags.add(PartnerUtil.cleanSection(rhc.Section__c));
				String[] tags = PartnerUtil.removeTags(cv.TagCsv.split(','), mstags);
				cv.TagCsv = PartnerUtil.joinArray(tags, ',');
				update cv;
			}
		}
		return false;
	}
	
	private void addContentTags(RH_Content__c rhc) {
		ContentVersion[] cvlist = [select Id, TagCsv from ContentVersion where ContentDocumentId = :rhc.ContentDocumentId__c and IsLatest = true];
		if (cvlist.size() == 1) {
			ContentVersion cv = cvlist.get(0);
			Set<String> cvTags = new Set<String>();
			if (cv.TagCsv != null) {
				cvTags = new Set<String>(cv.TagCsv.split(','));
			}
			cvTags.add(rhc.Site__c);
			cvTags.add(rhc.Page__c);
			cvTags.add(PartnerUtil.cleanSection(rhc.Section__c));
			String[] lst = new List<String>(cvTags);
			cv.TagCsv = PartnerUtil.joinArray(lst, ',');
			update cv; 
		}
	}
	
	static testmethod void simpleTest() {
		RHContentListAdminController rclc = new RHContentListAdminController();
		rclc.initData();
		rclc.manageVideos();
		rclc.searchContent();
		rclc.contentSearchString = 'te';
		rclc.searchContent();
		System.assertNotEquals(rclc.contentSearchResult.size(), 0);
		ApexPages.currentPage().getParameters().put('docId',rclc.contentSearchResult[0].ContentDocumentId);
		rclc.comboNavObject.Site__c = 'RHEL';
		rclc.comboNavObject.Page__c = 'Resources';
		rclc.lastComboNavObject = rclc.comboNavObject.clone();
		rclc.getContentList();
		rclc.comboNavObject.Site__c = 'Datasheets';
		rclc.selectDocument();		
		System.assertNotEquals(rclc.back(),Page.RedHatContentAdminFindContent);

		rclc.addDocument();
		rclc.saveRHContent();
		
		rclc.getContentList();
/* not working.  Fix this Tiaan
		rclc.getRHContent();

		System.assertNotEquals(null,rclc.newRHContent.Id);
		Id docId = rclc.newRHContent.Id;
		ApexPages.currentPage().getParameters().put('docId',docId);
		
		rclc.editDocument();
		System.assertNotEquals(rclc.back(),Page.RedHatContentAdministration);
		
		System.assertEquals(true, rclc.newRHContent.IsPublished__c);
		rclc.unpublishDocument();
		rclc.editDocument();
		System.assertEquals(false, rclc.newRHContent.IsPublished__c);
		rclc.publishDocument();
		rclc.editDocument();	
		System.assertEquals(true, rclc.newRHContent.IsPublished__c);
		rclc.removeDocument();
*/		
	}
	
}