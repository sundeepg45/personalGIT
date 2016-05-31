/**
 * @version 2014-06-18
 * @author tkruger@redhat.com
 * Bill C. Riemers <briemers@redhat.com>
 * 2014-06-18 - Fixed exception for missing chatter group.
 */
public without sharing class SalesPortalController
{
	public String CHATTER_GROUP_NAME = SalesContentSections__c.getInstance('CHATTER_GROUP_NAME').Section__c;
	public String SECT_COMMUNCATION = SalesContentSections__c.getInstance('SECT_COMMUNCATION').Section__c;
	public String SECT_GENERAL_INFORMATION = SalesContentSections__c.getInstance('SECT_GENERAL_INFORMATION').Section__c;
	public String SECT_POPULAR_LINKS = SalesContentSections__c.getInstance('SECT_POPULAR_LINKS').Section__c;
	public String SECT_PORTAL_SPOTLIGHT = SalesContentSections__c.getInstance('SECT_PORTAL_SPOTLIGHT').Section__c;
	public String SECT_QUICK_LINKS = SalesContentSections__c.getInstance('SECT_QUICK_LINKS').Section__c;
	public String SECT_WHOS_WHO = SalesContentSections__c.getInstance('SECT_WHOS_WHO').Section__c;
	public String SECT_FEATURED_STORY = SalesContentSections__c.getInstance('SECT_FEATURED_STORY').Section__c;
	public String SECT_RESOURCES = SalesContentSections__c.getInstance('SECT_RESOURCES').Section__c;
	public String SECT_DASHBOARD = SalesContentSections__c.getInstance('SECT_DASHBOARD').Section__c;
	public String SECT_STATUS_BAR = SalesContentSections__c.getInstance('SECT_STATUS_BAR').Section__c;
		
	public String SUBSEC_PORTAL_MESSAGE = SalesContentSections__c.getInstance('SUBSEC_PORTAL_MESSAGE').Section__c;
	
	public String GROUP_GLOBAL_ALL = SalesContentSections__c.getInstance('GROUP_GLOBAL_ALL').Section__c;
	
	private List<Schema.PicklistEntry> sections;
	private List<Schema.PicklistEntry> subSections;
	
	private Set<String> groups = new Set<String>();
	private List<GroupMember> groupMemberships = new List<GroupMember>();
	
	private static final String SANDBOXES_DEFAULT = 'dev';
	
	private static final Map<String,String> SANDBOXES = new Map<String,String>{
        'com'=>'prod',
        'qa'=>'test',
        'fte1'=>'dev',
        'fte2'=>'dev'};

	/**
	 * Constructor
	 *
	 */
	public SalesPortalController() {}

	public static User currentUser {
		get {
			if(currentUser == null) {
				currentUser = [
					select
						Region__c,
						LastLoginDate,
						UserName
					from User
					where Id = :UserInfo.getUserId() ];
			}
			return currentUser;
		}
		set;
	}

	private static String ENVIRONMENT {
        get {
            if(ENVIRONMENT == null)
            {
                String username = currentUser.UserName;
                if(! username.contains('@redhat.com')) {
                    User u = [select UserName from User where UserName like 'intadmin@redhat.com%' limit 1];
                    username = u.UserName;
                }
                ENVIRONMENT = SANDBOXES_DEFAULT;
                Integer i = username.lastIndexOf('.');
                if(i > 0) {
                    final String s = SANDBOXES.get(username.substring(i+1));
                    if(s != null) {
                        ENVIRONMENT = s;
                    }
                }
            }
            return ENVIRONMENT;
        }
        private set;
	}

	public Id chatterGroup {
		get {
			if ( chatterGroup == null ) {
				chatterGroup = UserInfo.getUserId();
				for(CollaborationGroup cg : [
					select Id
					from CollaborationGroup
					where Name = :CHATTER_GROUP_NAME ] )
				{
					chatterGroup = cg.Id;
				}
			}
			return chatterGroup;
		}
		set;
	}
	
	private void loadSections(){
		sections = new List<Schema.PicklistEntry>();
		subSections = new List<Schema.PicklistEntry>();
		
		for (Schema.PicklistEntry ple : SalesPortalContent__c.Section__c.getDescribe().getPicklistValues()){
			sections.add(ple);
		}
		for (Schema.PicklistEntry ple : SalesPortalContent__c.SubSection__c.getDescribe().getPicklistValues()){
			subSections.add(ple);
		}
	}

	private void loadGroups(){
		Set<String> groupNames = new Set<String>();
		for (Schema.PicklistEntry ple : SalesPortalContent__c.ShowToGroups__c.getDescribe().getPicklistValues()){
			groupNames.add(ple.getValue());
		}
		
		groups.add(GROUP_GLOBAL_ALL);
		groupMemberships = [select 
								Group.Name, GroupId 
							from GroupMember 
							where GroupMember.UserOrGroupId = :UserInfo.getUserId() 
								and GroupMember.Group.Name in :groupNames];
		for (GroupMember gm : groupMemberships){
			groups.add(gm.Group.Name);
		}
	}
	
	private void buildContentMap() {

		loadSections();
		loadGroups();	

		contentMap = new Map<String,List<Link>>{
			SECT_COMMUNCATION => new List<Link>(),
			SECT_GENERAL_INFORMATION => new List<Link>(),
			SECT_POPULAR_LINKS => new List<Link>(),
			SECT_PORTAL_SPOTLIGHT => new List<Link>(),
			SECT_QUICK_LINKS => new List<Link>(),
			SECT_WHOS_WHO => new List<Link>(),
			SECT_FEATURED_STORY => new List<Link>(),
			SECT_RESOURCES => new List<Link>(),
			SECT_DASHBOARD => new List<Link>(),
			SECT_STATUS_BAR => new List<Link>()};			
			
		// Gets all the Content for the page
		Map<Id, Link> tmpContentMap = new Map<Id, Link>();
		for (SalesPortalContent__c c : [
			select
				Id,
				Section__c,
				SubSection__c,
				Name,
				Link__c,
				LinkDescription_en__c,
				KalturaId__c,
				KalturaThumbnailURL__c,
				RichText_en__c,
				ShowToGroups__c,
				LastModifiedDate,
				PortalMessageBehavior__c
			from SalesPortalContent__c
			where Published__c = true and
				ShowToGroups__c in :groups
			order by Section__c, Sub_Section_Ordering__c, Order__c, Name ] )
		{
			if (contentMap.containsKey(c.Section__c)){
				List<Link> contents = contentMap.get(c.Section__c);
				// Wrap it and add it
				Link l = new Link(c, this);
				contents.add(l);
				tmpContentMap.put(c.Id, l);
			}
		}
		
		// Attach any icons found
		List<Attachment> icons = [select Id, ParentId from Attachment where ParentId in :tmpContentMap.keySet()];
		for (Attachment a : icons){
			tmpContentMap.get(a.ParentId).icon = a;
		}
		
		// Remove any global entries that have regional overrides
		for (String section : contentMap.keySet()){
			
			Map<String,Link> reglLinkMap = new Map<String,Link>();
			List<Link> linkList = contentMap.get(section);
			List<Link> newlinkList = new List<Link>(); 
			
			for (Link l : linkList){
				if (!l.getIsGlobal()){
					// This title has a regional link
					reglLinkMap.put(l.getTitle().toLowerCase(), l);						
				}
			}
			
			for (Link l : linkList){
				// If it's global
				if (l.getIsGlobal()){
					// And doesn't have a regional override, add it
					if (!reglLinkMap.containsKey(l.getTitle().toLowerCase())){
						newlinkList.add(l);
					}
					// Otherwise skip it
				} else {
					// If it's regional, add it
					newlinkList.add(l);
				}
			}
			contentMap.put(section, newlinkList);
		}
		
	}

	/**
	 * Accessors
	 */
	public List<ContentVersion> getLatestDocuments(){
		List<ContentWorkspaceDoc> docRefs = [select ContentDocument.LatestPublishedVersion.Id, 
													ContentDocument.LatestPublishedVersion.ContentDocumentId, 
													ContentDocument.LatestPublishedVersion.Title, 
													ContentDocument.LatestPublishedVersion.Description,
													ContentDocument.LatestPublishedVersion.Category__c 
												from ContentWorkspaceDoc 
												where ContentWorkspace.Name in :groups and ContentDocument.IsArchived = false
												order by ContentDocument.LatestPublishedVersion.LastModifiedDate desc
												limit 3];
												
		List<ContentVersion> docs = new List<ContentVersion>();
		for (ContentWorkspaceDoc cwd : docRefs){
			ContentVersion cv = cwd.ContentDocument.LatestPublishedVersion;
			if (cv.Title != null && cv.Title.length() > 30){
				cv.Title = cv.Title.substring(0,30) + '...';
			}
			if (cv.Description != null && cv.Description.length() > 50){
				cv.Description = cv.Description.substring(0,50) + '...';
			}
			cv.Category__c = cv.Title;
			if (cv.Category__c != null){
				cv.Category__c = String.escapeSingleQuotes(cv.Category__c);
			}
			docs.add(cv);
		}
		
		return docs;
	}

	public Map<String, List<Link>> contentMap {
		get {
			if(contentMap == null) {
				buildContentMap();
			}
			return contentMap;
		}
		set;
	}

	public static String toUpperCase(String value) {
		if(value != null) {
			value = value.toUpperCase();
		}
		return value;
	}
	
	public Datetime getLastLogin(){
		return currentUser.LastLoginDate;
	}

	public List<Link> getMessages(){
		List<Link> messages = new List<Link>();
		
		for (Link l : contentMap.get(SECT_PORTAL_SPOTLIGHT)){
			if (l.getSubSectionKey() == SUBSEC_PORTAL_MESSAGE){
				messages.add(l);
			}
		}
		return messages;
	}

	public List<Link> getPortalSpotlight() {
		return contentMap.get(SECT_PORTAL_SPOTLIGHT);
	}
	
	public List<Link> getQuickLinks() {
		return contentMap.get(SECT_QUICK_LINKS);
	}
	
	public List<LinkSection> getFooters() {
		List<LinkSection> sections = new List<LinkSection>();
		sections.addAll(getLinkSections(SECT_POPULAR_LINKS));
		sections.addAll(getLinkSections(SECT_WHOS_WHO));
		sections.addAll(getLinkSections(SECT_GENERAL_INFORMATION));
		sections.addAll(getLinkSections(SECT_COMMUNCATION));
		return sections;
	}
	
	public Link getFeaturedStory() {
		if (contentMap.get(SECT_FEATURED_STORY).size() > 0){
			return contentMap.get(SECT_FEATURED_STORY)[0];
		}
		return new Link(this);
	}
	
	public Link getStatusBar() {
		if (contentMap.get(SECT_STATUS_BAR).size() > 0){
			return contentMap.get(SECT_STATUS_BAR)[0];
		}
		return new Link(this);
	}
	

	public Link getDashBoardLink() {
		if (contentMap.get(SECT_DASHBOARD).size() > 0){
			return contentMap.get(SECT_DASHBOARD)[0];
		}
		return new Link(this);
	}

	public List<LinkSection> getResources() {
		return getLinkSections(SECT_RESOURCES);
	}
	
	public List<LinkSection> getLinkSections(String section) {
		Map<String, LinkSection> sectionMap = new Map<String, LinkSection>();
		List<LinkSection> sections = new List<LinkSection>();
		for (Link l : contentMap.get(section)){
			if (sectionMap.get(l.getSubSection()) == null) {
				LinkSection ls = new LinkSection();
				// TODO: Add internationalization
				ls.title = l.getSubSection() == null ? l.getSection() : l.getSubSection();
				ls.links.add(l);
				sectionMap.put(l.getSubSection(), ls);
				sections.add(ls);
			} else {
				sectionMap.get(l.getSubSection()).links.add(l);
			}
		}
		return sections;
	}

	public List<Link> getResources(String section) {
		return contentMap.get(SECT_RESOURCES);
	}

	public string getTrackingURL() {
		String url;
		if (ENVIRONMENT == 'dev') {
			url = 'piwikdev-itsfa.rhcloud.com';
		}
		else if (ENVIRONMENT == 'test') {
			url = 'piwiktest-itsfa.rhcloud.com';
		}
		else if (ENVIRONMENT == 'prod') {
			url = 'piwik-itsfa.rhcloud.com';
		}
		else {
			url = 'piwikdev-itsfa.rhcloud.com';
		}
		return url;
	}

	public class LinkSection {
		public List<Link> links {
			get {
				if (links == null){
					links = new List<Link>();
				}
				return links;
			}
			set;
		}
		public String title {
			get;
			set;
		}
		
		public void addLink(Link l){
			links.add(l);			
		}
	}
	
	public class Link {
		private SalesPortalContent__c content;
		private SalesPortalController controller;

		public Link(SalesPortalController cntlr){
			controller = cntlr;
			content = new SalesPortalContent__c();
			content.Section__c = '';
			content.SubSection__c = '';
			content.Link__c = '';
			content.Name = '';
		}
		
		public Link(SalesPortalContent__c spc, SalesPortalController cntlr){
			controller = cntlr;
			content = spc;
		}

		public String getId() {
			return content.Id;
		}

		//////////////////////////////////////////////////////
		// Content Tests
		//////////////////////////////////////////////////////
		public boolean getIsGlobal() {
			return content.ShowToGroups__c == controller.GROUP_GLOBAL_ALL;
		}
		
		public boolean getIsPortalMessage() {
			return content.SubSection__c == controller.SUBSEC_PORTAL_MESSAGE;
		}
		
		public boolean getIsVideo() {
			return content.KalturaId__c != null && content.KalturaThumbnailURL__c != null;
		}
		
		// Whether this has been modified since the user last logged in
		public boolean getUpdated(){
			if (content.LastModifiedDate == null){
				return false;
			}
			if (controller.getLastLogin() == null){
				return true;
			}
			return content.LastModifiedDate.getTime() >= controller.getLastLogin().getTime();
		}
		
		public boolean getExpandIfUpdated(){
			if (content.PortalMessageBehavior__c != null && content.PortalMessageBehavior__c.substring(0,6) == 'Expand'){
				return true;
			}
			return false;
		}
		
		public boolean getHasIcon(){
			return icon != null && icon.id != null;
		}		

		//////////////////////////////////////////////////////
		// Accessors
		//////////////////////////////////////////////////////
		public String getTitle() {
			String fullKey = 'title_' + UserInfo.getLanguage() + '__c';
			String key = 'title_' + UserInfo.getLanguage().subString(0,2) + '__c';
			try {				
				String s = (String)content.get(fullKey);
				if (s != null && s != ''){
					return s;
				}
			} catch (Exception e) {}
			try {				
				String s = (String)content.get(key);
				if (s != null && s != ''){
					return s;
				}
			} catch (Exception e) {}
			return content.name;
		}
		
		public String getEscapedTitle() {
			return String.escapeSingleQuotes(getTitle());
		}		
		
		public String getLink() {
			if (getIsVideo()) {
				return '/apex/SalesPortalVideoViewer?id=' + content.Id;
			}
			return content.Link__c;
		}
		
		public String getLinkDescription() {
			return content.LinkDescription_en__c;
		}
		
		public String getHTML() {
			String fullKey = 'RichText_' + UserInfo.getLanguage() + '__c';
			String key = 'RichText_' + UserInfo.getLanguage().subString(0,2) + '__c';
			try {
				String s = (String)content.get(fullKey);
				if (s != null && s != ''){
					return s;
				}
			} catch (Exception e) {}
			try {
				String s = (String)content.get(key);
				if (s != null && s != ''){
					return s;
				}
			} catch (Exception e) {}
			return content.RichText_en__c;
		}

		// Non Translated key returned
		public String getSectionKey() {
			return content.Section__c;
		}
		
		public String getEscapedSectionKey() {
			return String.escapeSingleQuotes(getSectionKey());
		}
		
		public String getSection() {
			for (Schema.PicklistEntry ple : controller.sections){
				if (ple.getValue() == content.Section__c){
					return ple.getLabel();
				}
			}
			return content.Section__c;
		}
		
		// Non Translated key returned
		public String getSubSectionKey() {
			return content.SubSection__c;
		}
		
		public String getSubSection() {
			for (Schema.PicklistEntry ple : controller.subSections){
				if (ple.getValue() == content.SubSection__c){
					return ple.getLabel();
				}
			}
			return content.SubSection__c;
		}
		
		public Attachment icon {
			get;
			set;
		}
	}
}