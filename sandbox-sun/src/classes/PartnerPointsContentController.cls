public with sharing class PartnerPointsContentController {
	public PartnerPointsCatalogContentItem[] contentList { get; set; }
	public ContentVersion[] unassignedDocs {get; set; }
	public String commandId {get; set; }
	public String titleFilter {get; set; }
	public PartnerPointsCatalogContentItem editItem {get; set; }
	public SelectOption[] workspaceOptions {get; set; }
	public String selectedRegion {get; set; }
	public String selectedTrack {get; set; }
	public SelectOption[] subcategoryOptions {get; set; }
    public Boolean isGlobalPointAdmin { get; set; }
    public String userRegion { get; set; }


	private Map<ID, ContentWorkspace> contentWorkspaceMap;
	

	public PartnerPointsContentController() {
		titleFilter = '';
        User me = [select Global_Partner_Points_Admin__c, Region__c from User where Id = :UserInfo.getUserId()];
        isGlobalPointAdmin = me.Global_Partner_Points_Admin__c;
		userRegion = me.Region__c;
        
        if (isGlobalPointAdmin)
            selectedRegion = 'Global';
        else
            selectedRegion = userRegion;

		PP_Content_Workspace__c[] workspaces = [select Id, Name, WorkspaceId__c from PP_Content_Workspace__c order by Name];
		workspaceOptions = new List<SelectOption>();
		contentWorkspaceMap = new Map<ID, ContentWorkspace>([
			select	Id, DefaultRecordTypeId, Name
			from	ContentWorkspace
		]);
		for (PP_Content_Workspace__c workspace : workspaces) {
			ID wsid = workspace.WorkspaceId__c;
			ContentWorkspace ws = contentWorkspaceMap.get(wsid);
			// a workspace will not be visible if the user doesn't have access, so ignore
			if (ws != null) {
				workspaceOptions.add(new SelectOption(wsid, ws.Name));
				if (selectedWorkspace == null) selectedWorkspace = wsid;
			}
		}
		subcategoryOptions = new List<SelectOption>();
		for (Schema.PicklistEntry ple : PP_Content__c.Sub_Category__c.getDescribe().getPicklistValues()) {
			subcategoryOptions.add(new SelectOption(ple.getValue(), ple.getValue()));
		}

	}
	
	public ID selectedWorkspace {
		get;
		set {
			selectedWorkspace = value;
			if (selectedWorkspace != null) {
				load();
			}
		}
	}
	
	public SelectOption[] batchOptions {
		get {
			SelectOption[] options = new List<SelectOption>();
			options.add(new SelectOption('--none--', '--none--'));
			for (PP_Batch__c item : [
				select		Id, Name, Sub_Category__c
				from		PP_Batch__c
				where		isActive__c = true
				and			Region__c = :selectedRegion
				order by	Name
			]) {
				options.add(new SelectOption(item.Id, item.Name));
			}
			return options;
		} 
	}
	
	public List<SelectOption> getAvailableTracks() 
    {
    	List<SelectOption> options = new List<SelectOption>();
    	
        List<PartnerTrack__c> tracks = [
                    select Id,
                        Track__c,
                        Partner_Function__c,
                        Product_of_Interest__c
                    from PartnerTrack__c
                    order by Partner_Function__c, Product_of_Interest__c];
                    
                    
    	options.add(new SelectOption('', 'None Selected'));
        for( PartnerTrack__c pt : tracks){
        	options.add(new SelectOption(pt.id, pt.Partner_Function__c + ' / ' + pt.Product_of_Interest__c));
        }
                    
        return options;
    }

	private void load() {
		ID recId = contentWorkspaceMap.get(selectedWorkspace).DefaultRecordTypeId;

		String titlePattern = '%';
		if (titleFilter.trim().length() > 0) {
			if (titleFilter.length() > 80) {
				titleFilter = titleFilter.substring(1, 80);
			}
			titlePattern = '%' + titleFilter.trim() + '%';
		}

		PP_Content__c[] scored = [select Id, DocumentId__c from PP_Content__c where Full_Points__c > 0 and Global_Region__c = :selectedRegion];
		Set<String> scoredDocIdList = PartnerUtil.getStringFieldSet(scored, 'DocumentId__c');

		Map<ID, PP_Content__c> contentMap = new Map<ID, PP_Content__c>();
		if (selectedTrack == null || selectedTrack == 'None Selected') {
			for (PP_Content__c c : [
				select		Id, Name, DocumentId__c, IsActive__c, Full_Points__c, Sub_Category__c, ExcludeBatchId__c, Partner_Track__c
				from		PP_Content__c
				where		Name like :titlePattern
				and			WorkspaceId__c = :selectedWorkspace
				and			Global_Region__c = :selectedRegion
			]) {
				contentMap.put(c.DocumentId__c, c);
			}
		}
		else {
			for (PP_Content__c c : [
				select		Id, Name, DocumentId__c, IsActive__c, Full_Points__c, Sub_Category__c, ExcludeBatchId__c, Partner_Track__c
				from		PP_Content__c
				where		Name like :titlePattern
				and			WorkspaceId__c = :selectedWorkspace
				and			Global_Region__c = :selectedRegion
				and			Partner_Track__c = :selectedTrack
			]) {
				contentMap.put(c.DocumentId__c, c);
			}
		}
		
		ContentWorkspaceDoc[] wsdocList = [select ContentDocumentId from ContentWorkspaceDoc where ContentWorkspaceId = :selectedWorkspace];
		Set<String> docidList = PartnerUtil.getStringFieldSet(wsdocList, 'ContentDocumentId');		

		ContentVersion[] versionList = [
			select		Id, ContentSize, Title, FileType, ContentDocumentId, Expiration_Date__c
			from		ContentVersion
			where		Title like :titlePattern
//			and			RecordTypeId = :recId
			and			ContentDocumentId in :docidList
			and			IsLatest = true
			and			IsDeleted = false
			order by	Title
		];

		contentList = new List<PartnerPointsCatalogContentItem>();
		Set<ID> mappedDocIds = new Set<ID>();
		
		Date todayDate = System.today();

		ID[] expiredIds = new List<ID>();
		for (ContentVersion ver : versionList) {
			String expdate = ver.Expiration_Date__c;
			System.debug('++++[debug]++++ expiration_date__c=' + expdate);
			if (expdate != null && expdate.length() == 7) {
				Date d = Date.newInstance(Decimal.valueOf(expdate.substring(0, 4)).intValue(), Decimal.valueOf(expdate.substring(5, 7)).intValue(), 1);
				d = d.addMonths(1);
				System.debug('++++[debug]++++ expdate=' + d);
				if (d < todayDate) {
					expiredIds.add(ver.Id);
					continue;
				}
			}
			PP_Content__c citem = contentMap.get(ver.ContentDocumentId);
			if (citem != null) {
				PartnerPointsCatalogContentItem item = new PartnerPointsCatalogContentItem();
				item.contentId = citem.DocumentId__c;
				item.ppContentId = citem.Id;
				if (ver == null) {
					item.Title = '-- (document missing) --';
				}
				else {
					item.Title = ver.Title;
					mappedDocIds.add(ver.ContentDocumentId);
				}
				item.isActive = citem.IsActive__c;
				item.trackId = citem.Partner_Track__c;
				item.points = citem.Full_Points__c.intValue();
				item.contentSize = ver.ContentSize;
				item.fileType = ver.FileType;
				item.subcategory = citem.Sub_Category__c;
				item.excludeBatchId = citem.ExcludeBatchId__c;
				contentList.add(item);
			}
		}
		
		//
		// rather that pollute the above code with a bunch of short circuits for this logic just isolate it
		// for clarity.
		//
		// Get list of all mapped documents if we are looking at globals
		if (selectedRegion == 'Global') {
			PP_Content__c[] allMapped = [select DocumentId__c from PP_Content__c where Global_Region__c != 'Global'];
			for (PP_Content__c item : allMapped) {
				// make sure we don't show any documents mapped to the non-Global region
				mappedDocIds.add(item.DocumentId__c);
			}
		}
		else {
			// otherwise we don't want to show mapped global documents
			PP_Content__c[] allMapped = [select DocumentId__c from PP_Content__c where Global_Region__c = 'Global'];
			for (PP_Content__c item : allMapped) {
				mappedDocIds.add(item.DocumentId__c);
			}
		}
		
		ContentVersion[] toShow = [
			select	Id, Title, ContentSize, FileType, ContentDocumentId
			from 	ContentVersion
			where	Id in :PartnerUtil.getIdSet(versionList)
			and		ContentDocumentId not in :mappedDocIds
			and		ContentDocumentId not in :scoredDocIdList
			and		Id not in :expiredIds
			order by Title
		];

		unassignedDocs = toShow;

	}

	public PageReference deleteButton() {
		String ppContentId = System.currentPageReference().getParameters().get('ppContentId');
		PP_Content__c content = [select Id, DocumentId__c, Global_Region__c from PP_Content__c where Id = :ppContentId];
		if (content.Global_Region__c == 'Global') {
			PP_ContentStage__c[] stageList = [select Id from PP_ContentStage__c where ContentID__c = :content.DocumentId__c];
			Set<String> stageIdList = PartnerUtil.getIdSet(stageList);
			Integer cnt = [select count() from PP_Scores__c where ContentRef__c in :stageIdList];
			if (cnt > 0) {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Content has associated scores. Not deleted'));
				return null;
			}
		}
		else {
			PP_ContentStage__c[] stageList = [select Id from PP_ContentStage__c where ContentID__c = :content.DocumentId__c];
			Set<String> stageIdList = PartnerUtil.getIdSet(stageList);
			Integer cnt = [select count() from PP_Scores__c where ContentRef__c in :stageIdList and Account__r.Global_Region__c = :content.Global_Region__c];
			if (cnt > 0) {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Content has associated scores. Not deleted'));
				return null;
			}
		}
		delete new PP_Content__c(Id = ppContentId);
		load();
		return null;
	}

	public PageReference cancelEdit() {
		return Page.PartnerPointsCatalogContent;
	}
	
	public PageReference backToCatalog() {
		return Page.PartnerPointsCatalog;
	}
	
	public PageReference saveEdit() {
		try {
			if (editItem.ppContentId == null) {
				// new
				PP_Content__c c = new PP_Content__c();
				c.DocumentId__c = editItem.contentId;
				c.Full_Points__c = editItem.points;
				c.PP_Catalog__c = [select Id from PP_Catalog__c where Category__c = 'Content'].Id;
				c.WorkspaceId__c = selectedWorkspace;
				c.Global_Region__c = selectedRegion;
				c.IsActive__c = editItem.isActive;
				if (editItem.title.length() > 80)
					c.Name = editItem.title.substring(0, 80);
				else
					c.Name = editItem.title;
				c.Sub_Category__c = editItem.subcategory;
				c.Partner_Track__c = editItem.trackId;
				if (editItem.excludeBatchId == '--none--')
					c.ExcludeBatchId__c = null;
				else
					c.ExcludeBatchId__c = editItem.excludeBatchId;
				insert c;
			}
			else {
				PP_Content__c c = new PP_Content__c(Id = editItem.ppContentId);
				c.Full_Points__c = editItem.points;
				c.IsActive__c = editItem.isActive;
				c.Partner_Track__c = editItem.trackId;
				c.Sub_Category__c = editItem.subcategory;
				if (editItem.excludeBatchId == '--none--')
					c.ExcludeBatchId__c = null;
				else
					c.ExcludeBatchId__c = editItem.excludeBatchId;
				update c;
			}
			load();
			return Page.PartnerPointsCatalogContent;
		}
		catch (DMLException e) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getDmlMessage(0)));
		}
		return null;
	}
	
	public PageReference manageButton() {
		String contentId = System.currentPageReference().getParameters().get('ppContentId');
		editItem = null;
		for (PartnerPointsCatalogContentItem c : contentList) {
			if (c.ppContentId == contentId) {
				editItem = c;
				return Page.PartnerPointsCatalogContentEdit;
			}
		}
		return null;
	}

	public PageReference assignButton() {
		String contentId = System.currentPageReference().getParameters().get('contentId');
		editItem = null;
		for (ContentVersion ver : unassignedDocs) {
			if (ver.ContentDocumentId == contentId) {
				editItem = new PartnerPointsCatalogContentItem();
				editItem.isActive = true;
				editItem.contentId = contentId;
				editItem.contentSize = ver.ContentSize;
				editItem.fileType = ver.FileType;
				editItem.points = 0;
				editItem.title = ver.Title;
				break;
			}
		}
		if (editItem != null) {
			return Page.PartnerPointsCatalogContentEdit;
		}
		return null;
	}

	public PageReference filterButton() {
		load();
		return null;
	}
	
	public PageReference resetFilterButton() {
		titleFilter = '';
		load();
		return null;
	}

	
	@IsTest(SeeAllData=true)
	static void simpleTest() {

		if ([select Id from PP_Catalog__c where Category__c = 'Content'].isEmpty()) {
			PP_Catalog__c cat = new PP_Catalog__c();
			cat.Category__c = 'Content';
			cat.Global_Region__c = 'NA';
			insert cat;
		}
		PP_Content_Workspace__c[] currentws = [select Id from PP_Content_Workspace__c];
		if (!currentws.isEmpty()) delete currentws;
		ID[] wsidlist = new List<ID>();
		Map<ID, ContentWorkspace> wsMap = new Map<ID, ContentWorkspace>([select Id, Name, DefaultRecordTypeId from ContentWorkspace]);
		for (ContentWorkspace ws : wsMap.values()) {
			insert new PP_Content_Workspace__c(Name = ws.Name, WorkspaceId__c = ws.Id);
			wsidlist.add(ws.Id);
		}

		PartnerPointsContentController ctrl = new PartnerPointsContentController();
		for (ID i : wsidlist) {
			if (!ctrl.unassignedDocs.isEmpty()) {
				ctrl.selectedWorkspace = i;
				
                if (!ctrl.unassignedDocs.isEmpty()) {
					System.currentPageReference().getParameters().put('contentId', ctrl.unassignedDocs.get(0).ContentDocumentId);
					PageReference ref = ctrl.assignButton();
					ref = ctrl.saveEdit();
                }

                if (!ctrl.contentList.isEmpty()) {
                    System.currentPageReference().getParameters().put('ppContentId', ctrl.contentList.get(0).ppContentId);
                    PageReference ref = ctrl.manageButton();
                    ref = ctrl.saveEdit();				// for a dummy save
                    PageReference pref = ctrl.deleteButton();
                }

				//
				// make the Global logic run
				//
				ctrl.selectedRegion = 'Global';
				break;
			}
		}
		
		PageReference ref = ctrl.cancelEdit();
		ref = ctrl.resetFilterButton();
		ref = ctrl.filterButton();
		ref = ctrl.backToCatalog();

	}
}