/**
 * This class implements a controller to use for tab sets.  Unlike the 
 * standard controller, this controller is intended for use with multiple
 * objects.  The general assumptions are each tab will have one primary
 * object type it will display, and the name of that tab will be the object
 * name without the __c suffix for custom objects.
 *
 * The initialization of this object is through two means.  First cgi-bin parameters
 * can be used to control the 'activeTab', 'mode', 'id' displayed in active tab, and
 * 'ids' used in the remaining tabs.  However, most of the parameters are not required.
 * Instead a naming convention for the visual force page name is used.   The suffix
 * of the page 'view', 'edit', or 'new' is the default mode.  The remaining of the
 * page name is the name of the object/active tab.  So for example if the page 
 * name was 'OpportunityView', then the active tab would be Opportunity, the 
 * object displayed in that tab would be Opportunity.  The mode would be 'view'.
 *
 * Most of the time there really isn't a need to distiquish between 'edit' and
 * 'new' in the mode.  If an 'edit' mode is selected, but no 'id' parameter
 * is supplied, then the mode becomes 'new'.  Likewise, you only need something
 * to indicate the active tab/object if the mode is 'new'.  If the mode is 'edit'
 * or 'view' then the active tab/object is determined based on the object type
 * referenced by 'id'.
 *
 * @version 2013-05-09
 *
 * @author Bill C Riemers <briemers@redhat.com>
 * 2013-05-09 - remove unneccessary virtual attribute
 * 2013-03-19 - Created
 * Scott Coleman <scoleman@redhat.com>
 * 2013-04-23 - Add event tracking method
 */
public with sharing class TabUIController {
	/** CGI-BIN parameter used for the activeTab */
	public static final String ACTIVE_TAB_PARAM = 'activeTab';
	/** CGI-BIN parameter used for the id */
	public static final String ID_PARAM = 'id';
	/** CGI-BIN parameter used for the ids */
	public static final String IDS_PARAM = 'ids';
	/** CGI-BIN parameter used for the mode */
	public static final String MODE_PARAM = 'mode';

	/** Parameters that can be shared between pages. */
	public Map<String,String> sharedParams = new Map<String,String>();

	/**
	 * Default constructor.  Initialize based on cgi-bin parameters and page name.
	 */
	public TabUIController() {
		sequenceNumber = 0;
		Map<String,String> params = ApexPages.currentPage().getParameters();
		activeTab = params.get(ACTIVE_TAB_PARAM);
		activeId = (Id)params.get(ID_PARAM);
		String mode = params.get(MODE_PARAM);
		String standardObjectName = null;
		if(pageName != null) {
			System.debug('pageName='+pageName);
			String xmode = 'view';
			String p = pageName.toLowerCase();
			if(p.endsWith('_edit')) {
				xmode = 'edit';
				standardObjectName = pageName.substring(0,p.length()-5);
			}
			else if(p.endsWith('edit')) {
				xmode = 'edit';
				standardObjectName = pageName.substring(0,p.length()-4);
			}
			else if(p.endsWith('_new')) {
				xmode = 'new';
				standardObjectName = pageName.substring(0,p.length()-4);
			}
			else if(p.endsWith('new')) {
				xmode = 'new';
				standardObjectName = pageName.substring(0,p.length()-3);
			}
			else if(p.endsWith('_view')){
				standardObjectName = pageName.substring(0,p.length()-5);
			}
			else if(p.endsWith('view')){
				standardObjectName = pageName.substring(0,p.length()-4);
			}
			if(mode == null || mode == '') {
				if(xmode == 'edit' && activeId == null) {
					xmode = 'new';
				}
				mode = xmode;
			}
			System.debug(MODE_PARAM+'='+mode);
		}
		if(mode != null && mode != '') {
			if(standardObjectName != null && (activeTab == null || activeTab == '')) {
				String custom = standardObjectName+'__c';
				for(String key : tabId.keySet()) {
					if(key == custom) {
						activeTab = key;
						break;
					}
				}
				if(activeTab == null || activeTab == '') {
					for(String key : tabId.keySet()) {
						if(key == standardObjectName) {
							activeTab = key;
							break;
						}
					}
				}
				System.debug(ACTIVE_TAB_PARAM+'='+activeTab);
			}
			if(mode == 'new' && activeId != null) {
				mode = 'edit';
			}
			else if(mode == 'edit' && activeId == null) {
				mode = 'new';
			}
			tabMode.put(activeTab,mode);
		}
	}

	/**
	 * The pageName as extracted from the currentPage url.
	 */
	public String pageName {
		get {
			if(pageName == null) {
				List<String> urlParts = ApexPages.currentPage().getUrl().split('[?/]');
				for(Integer i = 0,n=urlParts.size()-1;i < n;) {
					if(urlParts[i++] == 'apex') {
						pageName = urlParts[i].toLowerCase();
						break;
					}
				}
			}
			return pageName;
		}
		set;
	}

	/**
	 * The active tab.  When we set a new value, reset the tabMode to 'view'.
	 */
	public String activeTab {
		get;
		set {
			if(value != activeTab && value != null && value != '') {
				tabMode.put(activeTab,'view');
				activeTab = value;
			}
		}
	}

	/**
	 * The mode of the active tab.
	 */
	public String activeTabMode {
		get {
			return tabMode.get(activeTab);
		}
	}

	public Integer activeIdChangeCount { 
		get {
			if(activeIdChangeCount == null) {
				activeIdChangeCount = 0;
			}
			return activeIdChangeCount;
		} 
		set;
	}

	/**
	 * The object id which should be displayed in the active tab.
	 */
	public Id activeId {
		get {
			if(activeId == null && activeTab != null) {
				activeId = getTabId(activeTab);
			}
			return activeId;
		}
		set {
			if(value != activeId) {
				if(activeId != null || (value != null && tabMode.get(activeTab) == 'new')) {
					tabMode.put(activeTab,'view');
				}
				activeId = value;
				if(activeId != null) {
					activeIdChangeCount++;
					String prefix = ((String)activeId).substring(0,3);
					for(Schema.SObjectType objectType : Schema.getGlobalDescribe().values()) {
						Schema.DescribeSObjectResult d = objectType.getDescribe();
						if(d != null && prefix.equals(d.getKeyPrefix())) {
							String name = d.getName();
							tabId.put(name,activeId);
							activeTab = name;
							System.debug('tabId['+name+']='+activeId);
							break;
						}
					}
				}
			}
		}
	}

	/**
	 * Mapping of mode for each tab.
	 */
	public Map<String,String> tabMode {
		get {
			if(tabMode == null) {
				tabMode = new Map<String,String>{};
				for(String key : tabId.keySet()) {
					tabMode.put(key,'view');
				}
			}
			return tabMode;
		}
		set;
	}

	/**
	 * Get the id being displayed in the respective tab.
	 *
	 * @param key object/or tab name
	 * @return id to display
	 */
	public Id getTabId(String key) {
		String value = tabId.get(key);
		if(value == '') {
			value = null;
		}
		return (Id)value;
	}

	/**
	 * Set the id being displayed in the respective tab.
	 *
	 * @param key object/or tab name
	 * @param id to display
	 */
	public void setTabId(String key,Id id) {
		String value = id;
		if(value == null) {
			value = '';
		}
		tabId.put(key,value);
	}

	/**
	 * Mapping of the id being displayed in each tab.
	 */
	public Map<String,String> tabId {
		get {
			if(tabId == null) {
				Map<String,Id> prefixMap = new Map<String,Id>();
				Map<String,String> paramMap = ApexPages.currentPage().getParameters();
				// obtain the list of _lkid keys
				List<String> paramKeys = new List<String>();
				for(String key : paramMap.keySet()) {
					if(key.endsWith('_lkid')) {
						paramKeys.add(key);
					}
				}
				// process these keys last, so they take priority
				paramKeys.add(IDS_PARAM);
				paramKeys.add(ID_PARAM);
				// populate the prefixMap with respective ids
				for(String key : paramKeys) {
					String value = paramMap.get(key);
					if(value != null && value.length() >= 15) {
						for(String idString : value.trim().split('\\s*,\\s*')) {
							try {
								Id id2 = (Id)idString;
								String prefix = ((String)id2).substring(0,3);
								prefixMap.put(prefix,id2);
								System.debug('prefixMap['+prefix+']='+id2);
							}
							catch(Exception ignored) {}
						}
					}
				}
				// now populate the tabId map
				tabId = new Map<String,String>();
				for(Schema.SObjectType objectType : Schema.getGlobalDescribe().values()) {
					Schema.DescribeSObjectResult d = objectType.getDescribe();
					if(d != null) {
						String prefix = d.getKeyPrefix();
						if(prefix != null) {
							String p = prefixMap.get(prefix);
							if(p == null) {
								p='';
							}
							tabId.put(d.getName(),p);
							System.debug('tabId['+d.getName()+']="'+p+'",prefix='+prefix);
						}
					}
				}
			}
			return tabId;
		}
		set;
	}

	/**
	 * Dummy call, typically used when an action function is passing in
	 * a new id to display in the tab.
	 *
	 * @return null
	 */
	public PageReference displayId() {
		return null;
	}

	/**
	 * Increment to force query lists to refresh.
	 */
	public Integer sequenceNumber {
		get;
		set;
	}

	/**
	 * Base class used an a extension in child tabs.  This impliments all
	 * the methods one would normally find in a standard controller.
	 */
	public abstract with sharing class Extension {
		private transient Schema.DescribeSObjectResult describe = null;
		// record being displayed/edited
		private SObject record;
		/** reference to the TabUIController */
		protected final TabUIController tabUIController;
		/** The name of this tab */
		protected final String tabName;

		/**
		 * Normal constructor.
		 * @param tabName the name of this tab
		 * @param tabUIController the TabUIController of the page.
		 */
		public Extension(String tabName,TabUIController tabUIController) {
			this.tabName = tabName;
			this.tabUIController = tabUIController;
		}

		/**
		 * Constructor for stand alone page.  This is provided as a 
		 * a way to use the same page outside a tabset.
		 * @param tabName the name of the object
		 */
		public Extension(String tabName) {
			this.tabName = tabName;
			this.tabUIController = new TabUIController();
//			this.tabUIController.activeTab = tabName;
		}

		protected Schema.DescribeSObjectResult getDescribe() {
			if(describe == null) {
				describe = Schema.getGlobalDescribe().get(tabName).getDescribe();
			}
			return describe;
		}

		/**
		 * Check if the user has access permissions
		 */
		public virtual Boolean getIsAccessible() {
			return getDescribe().isAccessible();
		}

		/**
		 * Check if the user has update permissions
		 */
		public virtual Boolean getIsUpdateable() {
			return getDescribe().isUpdateable();
		}

		/**
		 * Check if the user has create permissions
		 */
		public virtual Boolean getIsCreateable() {
			return getDescribe().isCreateable();
		}

		/**
		 * Check if the user has delete permissions
		 */
		public virtual Boolean getIsDeletable() {
			return getDescribe().isDeletable();
		}

		/**
		 * Get the record being viewed or edited.  This method may be
		 * overridden.
		 * @return record
		 */
		public virtual SObject getRecord() {
			return record;
		}

		/**
		 * Set the record being viewed or edited.   This method may be
		 * overridden.
		 * @param record
		 */
		public virtual void setRecord(SObject record) {
			this.record = record;
		}

		/**
		 * Get the current mode of this page.  'view', 'edit', or 'new'
		 * @return mode
		 */
		public String getMode() {
			return tabUIController.tabMode.get(tabName);
		}

		/**
		 * Set the mode of this page.
		 * @param value mode of 'view', 'edit', or 'new'
		 */
		public void setMode(String value) {
			if(value == null || value == '') {
				value = 'view';
			}
			tabUIController.tabMode.put(tabName,value);
		}

		/**
		 * Get the id of the record to display or edit.
		 * @return id
		 */
		public Id getId() {
			return tabUIController.getTabId(tabName);
		}

		/**
		 * Set the id of the record to display or edit.
		 * @param id
		 */
		public void setId(Id value) {
			Id id = getId();
			if(id != value) {
				setRecord(null);
			}
			tabUIController.setTabId(tabName,value);
		}

		/**
		 * Return a PageReference to either the calling URL, or this
		 * record in a view mode.
		 *
		 * @return return url
		 */
		public PageReference returnFromPage() {
			String retURL = ApexPages.currentPage().getParameters().get('retURL');
			String url = retURL;
			Id id = getId();
			if(id != null) {
				url='/apex/'+tabUIController.pageName+'?mode=view&activeTab='+tabName;
				String sep='&ids=';
				url += '&id='+id;
				sep='&ids=';
				for(String key : tabUIController.tabId.keySet()) {
					String value = tabUIController.tabId.get(key);
					if(value != '' && (Id)value != id) {
						url += sep+value;
						sep = ',';
					}
				}
			}
			else {
				retURL = null;
				if(url == null) {
					url = '/';
				}
			}
			PageReference retval = new PageReference(url);
			if(retURL != null) {
				retval.getParameters().put('retURL',retURL);
			}
			return retval;
		}

		/**
		 * Restore the mode to 'view' and reset the record to null.
		 * @return null
		 */
		public PageReference cancelRecord() {
			tabUIController.activeTab = tabName;
			setMode('view');
			setRecord(null);
			return null;
		}

		/**
		 * Used to override the navigation on successful delete.  This
		 * is called before calling setRecord(null), so you can still 
		 * reference fields in the deleted object.
		 *
		 * @return page to navigate on successful delete
		 */
		public virtual PageReference navigateToOnDelete() {
			return null;
		}

		/**
		 * Delete the current record.
		 * @return the return page
		 */
		public PageReference deleteRecord() {
			tabUIController.activeTab = tabName;
			PageReference retval = null;
			try {
				SObject record = getRecord();
				delete record;
				retval = navigateToOnDelete();
				setId(null);
				setRecord(null);
				tabUIController.sequenceNumber++;
			}
			catch(Exception e) {
				ApexPages.addMessages(e);
			}
			return retval;
		}

		/**
		 * Save the record with an upsert.
		 * @return the view page for the record.
		 */
		public PageReference saveRecord() {
			tabUIController.activeTab = tabName;
			PageReference retval = null;
			try {
				SObject record = getRecord();
				upsert record;
				setId(record.Id);
				setRecord(null);
				tabUIController.sequenceNumber++;
				retval = new PageReference('/'+record.Id);
			}
			catch(Exception e) {
				ApexPages.addMessages(e);
			}
			return retval;
		}

		/**
		 * Change the mode to edit.
		 * @return null
		 */
		public PageReference editRecord() {
			tabUIController.activeTab = tabName;
			setMode('edit');
			return null;
		}

		/**
		 * Create a clone of the current record and switch to
		 * 'new' mode.
		 * @return null
		 */
		public PageReference cloneRecord() {
			tabUIController.activeTab = tabName;
			SObject record = getRecord();
			setId(null);
			setRecord(record.clone(false));
			setMode('new');
			return null;
		}

		/**
		 * Clear the current record and switch to 'new' mode.
		 * @return null
		 */
		public PageReference newRecord() {
			tabUIController.activeTab = tabName;
			setId(null);
			setRecord(null);
			setMode('new');
			return null;
		}

		/**
		 * Log an event so we can later calculate usage and contribution metrics
		 * @return null
		 */
		public void logEvent(String eventName, Id recordId, String data1, String data2, String data3) {
			Id eventId = eventMap.get(eventName);
			if(eventId != null) {
				insert new TrackingEventLog__c(
								RelatedObjectId__c = recordId,
								TrackingEvent__c = eventId,
								User__c = System.Userinfo.getUserId(),
								UserRoleId__c = System.Userinfo.getUserRoleId(),
								Data1__c = data1,
								Data2__c = data2,
								Data3__c = data3);
			}
		 }
		 
		public void logEvent(String eventName, Id recordId) {
			Id eventId = eventMap.get(eventName);
			if(eventId != null) {
				insert new TrackingEventLog__c(
								RelatedObjectId__c = recordId,
								TrackingEvent__c = eventId,
								User__c = System.Userinfo.getUserId(),
								UserRoleId__c = System.Userinfo.getUserRoleId());
			}
		 }

		private Map<String,Id> eventMap {
			get {
				if(eventMap == null) {
					eventMap = new Map<String,Id>();
					for(TrackingEvent__c event : [select Id, Code__c from TrackingEvent__c]) {
						eventMap.put(event.Code__c,event.Id);
					}
				}
				return eventMap;
			}
			set;
		}
	}
}