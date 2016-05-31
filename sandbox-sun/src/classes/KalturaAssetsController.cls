public with sharing class KalturaAssetsController {
    private SelectOption[] categoryList {private get; private set; }
    private KalturaClient cachedClient { private get; private set; }
    public String selectedCategory {get; set; }
    public String selectedWorkspaceName {get; set; }
    private Map<String, ContentWorkspace> workspaces;
    private Map<String,Configuration__c> configs;
 
    public KalturaAssetPageEntry[] assetList {get; private set; }


    public KalturaAssetsController() {
        loadConfig();
    	workspaces = new Map<String, ContentWorkspace>();
    	for (ContentWorkspace workspace : [
            select   Id, DefaultRecordTypeId, Name
            from     ContentWorkspace
            order by Name
        ]) {
        	workspaces.put(workspace.Name, workspace);
        }
    }

    public KalturaAssetsController(ApexPages.StandardController controller) {
    	loadConfig();
    }

    public void loadConfig() {
        configs = new Map<String,Configuration__c>();
        for (Configuration__c config : [
            select Name, Protected_Value__c, Value__c from Configuration__c where Name like 'Kaltura%'
        ]) {
        	configs.put(config.Name, config);
        }
    }

    public String kalturaPartnerId {
    	get {
            return configs.get('Kaltura.PartnerId').Value__c;    		
    	}
    }

    public String kalturaViewerId {
        get {
            return configs.get('Kaltura.ViewerId').Value__c;           
        }
    }
    
    public String kalturaUserId {
    	get {
    		return configs.get('Kaltura.UserId').Value__c;
    	}
    }
    
    public String kalturaAuthId {
    	get {
    		return configs.get('Kaltura.AuthId').Protected_Value__c;
    	}
    }

    public String kalturaAccessControlId {
        get {
            return configs.get('Kaltura.AccessControlId').Value__c;
        }
    }

    public PageReference addContent() {
        if (selectedWorkspaceName == 'none') {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Please select a target content library for import'));
            return null;
        }
    	for (KalturaAssetPageEntry entry : assetList) {
    		if (entry.doImport) {
    			ContentVersion cv = importMedia(entry.media);
    			entry.imported = true;
    			entry.doImport = false;
    		}
    	}
    	return null;
    }
    
    private ContentVersion importMedia(KalturaMediaEntry media) {
    	ContentVersion cv = new ContentVersion();
    	cv.Title = media.name;
    	cv.Description = media.description;
    	cv.ContentUrl = media.downloadUrl;
    	cv.RecordTypeId = getSelectedWorkspaceRecordType();
    	cv.FirstPublishLocationId = getCurrentWorkspaceId();
        cv.ContentUrl = URL.getSalesforceBaseUrl().toExternalForm() + '/apex/KalturaVideoViewer?kalturaId=' + media.id;
    	insert cv;
    	
    	cv = [select Id, Title, ContentDocumentId from ContentVersion where id = :cv.Id];
    	
    	RH_Content__c rhc = new RH_Content__c();
    	rhc.ContentDocumentId__c = cv.ContentDocumentId;
    	rhc.Name = cv.Title;
    	rhc.KalturaId__c = media.id;
    	rhc.Kaltura_Thumbnail_URL__c = media.thumbnailUrl;
    	rhc.IsPublished__c = false;
    	rhc.Site__c = 'VIDEO';
    	insert rhc;
    	return cv;
    }
    
    public void fetchContent() {
        if (selectedWorkspaceName == 'none') {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Please select a target content library for import'));
            return;
        }

    	Map<String,String> filters = new Map<String,String> {
            'filter:categoriesMatchOr'  => selectedCategory,
            'filter:accessControlIdIn'  => kalturaAccessControlId
    	};
    	KalturaMediaEntry[] mediaList = kalturaClient.listMedia(filters);
    	assetList = new List<KalturaAssetPageEntry>();
        ContentVersion[] docs = getContent();
        System.debug('[DEBUG]-------- content size = ' + docs.size());
        System.debug('[DEBUG]-------- selectedWorkspace = ' + selectedWorkspaceName);
        for (KalturaMediaEntry media : mediaList) {
        	Boolean found = false;
	        for (ContentVersion doc : docs) {
	        	if (doc.Title == media.name) {
	        		found = true;
	        		break;
	        	}
	        }
	        assetList.add(new KalturaAssetPageEntry(media, found));
        }
    }
    
    private ContentVersion[] getContent() {
        ContentVersion[] c = [
                select  Id,
                        Title,
                        ContentDocumentId,
                        ContentSize,
                        ContentUrl,
                        Description,
                        Document_Type__c,
                        FileType,
                        Language,
                        Is_New__c
                from    ContentVersion
                where   IsLatest = true
                and     RecordTypeId = :getSelectedWorkspaceRecordType()
                and     PublishStatus = 'P'
                and     IsDeleted = false
        ];
        
        for (ContentVersion cv : c) {
            System.debug('[debug]----------------- Content.Description=' + cv.Description);
            System.debug('[debug]----------------- Content.Document_Type__c=' + cv.Document_Type__c);
            System.debug('[debug]----------------- Content.FileType=' + cv.FileType);
            System.debug('[debug]----------------- Content.ContentDocumentId=' + cv.ContentDocumentId);
        }
        return c;
    }
    
    public KalturaClient kalturaClient {
    	get {
    		if (cachedClient == null) {
                cachedClient = new KalturaClient(kalturaUserId, kalturaPartnerId, kalturaAuthId);
    		}
    		return cachedClient;
    	}
    }
    public SelectOption[] kalturaCategories {
    	get {
    		if (categoryList == null) {
                String[] clist = kalturaClient.listCategories();
                categoryList = new List<SelectOption>();
                for (String cat : clist) {
                	categoryList.add(new SelectOption(cat, cat));
                }
    		}
    		return categoryList;
    	}
    }
    
    public ID getCurrentWorkspaceId() {
    	return workspaces.get(selectedWorkspaceName).Id;
    }
    
    public ID getSelectedWorkspaceRecordType() {
    	return workspaces.get(selectedWorkspaceName).DefaultRecordTypeId;
    }

    public SelectOption[] contentWorkspaces {
    	get {
			SelectOption[] wslist = new List<SelectOption>();
			wslist.add(new SelectOption('none', '--Select a Library--'));
			for (ContentWorkspace ws : workspaces.values()) {
				wslist.add(new SelectOption(ws.Name, ws.Name));
			}
            return wslist;
    	}
    }


	static testmethod void basicTest() {
		KalturaAssetsController ctrl = new KalturaAssetsController();
//		String s = ctrl.kalturaPartnerId;
//		s = ctrl.kalturaViewerId;
//		s = ctrl.kalturaUserId;
//		s = ctrl.kalturaAuthId;
//		s = ctrl.kalturaAccessControlId;

		ctrl.selectedWorkspaceName = 'General Workspace';
		ID id = ctrl.getCurrentWorkspaceId();
		SelectOption[] options = ctrl.contentWorkspaces;

		ContentVersion[] contentList = ctrl.getContent();
		KalturaMediaEntry km = new KalturaMediaEntry();
		km.name = 'Test Video';
		km.Description = 'I said it is a test';
		km.downloadUrl = 'http://www.amazon.com';
		km.id = 'abc123';
		ctrl.importMedia(km);
	}
 

}