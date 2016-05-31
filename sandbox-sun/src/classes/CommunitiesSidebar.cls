public without sharing class CommunitiesSidebar {
	public final Map<String,List<String>> partnerStatusMap { get; set; }
    public final User u { get; set; }
    public final Account acc { get; set; }
    public String selectedLanguageCode { get; set; }

    public String userFirstName { get; set; }
    public String userLastName { get; set; }
    public String accName { get; set; }
    public String accTier { get; set; }
    public Boolean canRequalify { get; set; }
    public Boolean hasTrack { get; set; }

    public Decimal currentPartnerPoints { get; set; }

    public Map<Id,Communities_Navigation_Item__c> idToNavItem { get; set; }
    public Map<Id,List<Id>> navItemsToNavItemChildren { get; set; }

    public List<Communities_Navigation_Item__c> sidebarNavItems { get; set; }
    public List<Communities_Navigation_Item__c> sidebarNavItemChildren { get; set; }

    public static Set<String> tabNamesThatAreSObjects { get; set; }
    public List<HierarchyNavItem> sortedNavItems { get; set; }

    public Set<String> allowedTabs { get; set; }

    public List<SidebarShortcut> sidebarShortcuts { get; set; }

    public CommunitiesSidebar() {

    	 u = CommunityTools.getUser(UserInfo.getUserId());
         hasTrack = CommunityTools.getHasTrack(u);
    	 userFirstName = u.firstName;
    	 userLastName = u.lastName;

        // Test User Id - George Na
        //u = CommunityTools.getUser('00560000001ROuQ');

        selectedLanguageCode = CommunityTools.getLanguage(u);

        acc = CommunityTools.getAccount(u);
        if(acc!=null){
        	accName = acc.Name;
        	accTier = acc.Finder_Partner_Tier__r.Name;
            if(acc.RequalStatus__c == 'Eligible' || acc.RequalStatus__c == 'In Progress'){
                canRequalify = true;
            }else{
                canRequalify = false;
            }
        }else{
        	accName = 'No Account Found';
        	accTier = 'N/A';
        }
        partnerStatusMap = CommunityTools.getPartnerStatus(acc, u.Contact.Id, u);
        Set<Id> matchingAudienceIds = CommunityTools.getMatchingAudiences(partnerStatusMap);

        allowedTabs = new Set<String>();
        tabNamesThatAreSObjects = new Set<String>();
        // Don't query Tab schema during unit tests or for unauthenticated users
        if(test.isRunningTest()){
            allowedTabs = CommunitiesTestUtils.testAllowedTabs();
        }else if(!partnerStatusMap.keyset().isEmpty()){
            Map<String,Set<String>> tabMap = CommunityTools.getAllowedTabs();
            allowedTabs = tabMap.get('allowedTabs');
            tabNamesThatAreSObjects = tabMap.get('SObjects');
        }

        getPartnerPoints();
        getAllowedNavItems(matchingAudienceIds);
        sortNavItems();
        getSidebarShortcuts();
    }

    public void getSidebarShortcuts(){
        sidebarShortcuts = new List<SidebarShortcut>();
        Set<Id> activeShortcutIds = new Set<Id>();

        for(Contact_Tool_Shortcut__c cts :
            [SELECT Id, Communities_Tool_Shortcut__r.Id
            FROM Contact_Tool_Shortcut__c
            WHERE Contact__r.Id = :u.Contact.Id
            ])
        {
            activeShortcutIds.add(cts.Communities_Tool_Shortcut__r.Id);
        }

        List<Communities_Tool_Shortcut__c> shortcutRecords = [SELECT Id
            ,Shortcut_URL__c
                ,(SELECT
                Link_Text__c
                ,Tooltip_Text__c
                ,Language_Code__c
                FROM Communities_Tool_Shortcut_Labels__r
                )
            FROM Communities_Tool_Shortcut__c
            WHERE Id in :activeShortcutIds
            ORDER BY Tool_Name__c ASC
            LIMIT 4
            ];

        for(Communities_Tool_Shortcut__c cts : shortcutRecords){
            SidebarShortcut ss = new SidebarShortcut(cts, selectedLanguageCode);
            sidebarShortcuts.add(ss);
        }
    }

    public void getPartnerPoints(){
        Contact c = [SELECT Id
            ,(SELECT
                Current_Points__c
                ,IsActive__c
                FROM PP_User_Points__r
            )
            FROM Contact
            WHERE Id = :u.Contact.Id
        ];
        currentPartnerPoints = 0;
        For(PP_User_Points__c pp : c.PP_User_Points__r){
            if(pp.IsActive__c){
                currentPartnerPoints += pp.Current_Points__c;
            }
        }
    }

    public void getAllowedNavItems(Set<Id> audienceIds){
        //Map all record ids to records
       idToNavItem = new Map<Id,Communities_Navigation_Item__c>();

        //Get top-level records

        sidebarNavItems = [SELECT
            Id
            ,URL__c
            ,Sequence__c
            ,Tab_Name__c
            ,(SELECT
                Label__c,
                Language_Code__c
                FROM Communities_Navigation_Item_Labels__r
                ORDER BY Label__c ASC
            )
            FROM Communities_Navigation_Item__c
            WHERE
            (Audience__c in :audienceIds OR Tab_Name__c in :allowedTabs)
            AND Parent_Item__c = null
            AND Type__c = 'Sidebar Navigation'
            ORDER BY Sequence__C ASC
            ];

        //Add top-level record ids to a set
        Set<Id> topLevelIds = new Set<Id>();
        for(Communities_Navigation_Item__c cni : sidebarNavItems){
            topLevelIds.add(cni.id);
            idToNavItem.put(cni.id,cni);
        }

        //Query children of top-level items
        sidebarNavItemChildren = [SELECT
            Id
            ,URL__c
            ,Sequence__c
            ,Tab_Name__c
            ,Parent_Item__r.id
            ,(SELECT
                Label__c,
                Language_Code__c
                FROM Communities_Navigation_Item_Labels__r
                ORDER BY Label__c ASC
                )
            FROM Communities_Navigation_Item__c
            WHERE
            (Audience__c in :audienceIds OR Tab_Name__c in :allowedTabs)
            AND Parent_Item__c in :topLevelIds
            AND Type__c = 'Sidebar Navigation'
            ORDER BY Sequence__C ASC
            ];

        //Add child record ids to a set and to the master Id-to-record map. Map each top-level id to its corresponding child ids.
        Set<Id> childIds = new Set<Id>();
        navItemsToNavItemChildren = new Map<Id,List<Id>>();
        if(topLevelids!=null && topLevelIds.size()>0){
            for(Communities_Navigation_Item__c tlcni : sidebarNavItems){
                List<Id> childIdList = new List<Id>();
                for(Communities_Navigation_Item__c ccni : sidebarNavItemChildren){
                    if(ccni.Parent_Item__r.id==tlcni.id){
                        childIds.add(ccni.id);
                        childIdList.add(ccni.id);
                        idToNavItem.put(ccni.id,ccni);
                    }
                }
                navItemsToNavItemChildren.put(tlcni.id,childIdList);
            }
        }


    }

    public void sortNavItems(){

        //Master list, starting from top-level parents
        sortedNavItems = new List<HierarchyNavItem>();

        for(Communities_Navigation_Item__c cni : sidebarNavItems){

            //Lists of children, under each parent
            List<HierarchyNavItem> children = new List<HierarchyNavItem>();

            if(navItemsToNavItemChildren.keyset().contains(cni.id)){
                for(Id cniChild : navItemsToNavItemChildren.get(cni.id)){
                    HierarchyNavItem child = new HierarchyNavItem(idToNavItem.get(cniChild),selectedLanguageCode);
                    children.add(child);
                    children.sort();

                }
            }

            HierarchyNavItem item = new HierarchyNavItem(cni,children,selectedLanguageCode);
            sortedNavItems.add(item);
            sortedNavItems.sort();

        }
    }

    public class SidebarShortcut{

        public String label { get; set; }
        public String helpText { get; set; }
        public String URL { get ;set; }
        public String id { get; set; }

        public SidebarShortcut (Communities_Tool_Shortcut__c cts, String selectedLanguageCode){
            this.id = ((String)cts.id).substring(0,15);
            this.URL = '/' + cts.Shortcut_URL__c;
            this.label = '';
            this.helpText = '';
            for(Communities_Tool_Shortcut_Label__c ctsl : cts.Communities_Tool_Shortcut_Labels__r){
                if(ctsl.Language_Code__c==selectedLanguageCode){
                    this.label = ctsl.Link_Text__c;
                    this.helpText = ctsl.Tooltip_Text__c;
                }
            }
            if(this.label=='' || this.helpText==''){
                for(Communities_Tool_Shortcut_Label__c ctsl : cts.Communities_Tool_Shortcut_Labels__r){
                    if(ctsl.Language_Code__c=='en_US'){
                        if(this.label==''){                         
                            this.label = ctsl.Link_Text__c;
                        }
                        if(this.helpText==''){
                            this.helpText = ctsl.Tooltip_Text__c;
                        }
                    }
                }
            }
        }
    }
    public class HierarchyNavItem implements Comparable{

        public String Label { get; set; }
        public List<HierarchyNavItem> children { get; set; }
        public String URL { get; set; }
        public String id { get; set; }
        public Decimal sequence { get; set; }

        public HierarchyNavItem (Communities_Navigation_Item__c cni, String selectedLanguageCode){
            this.label = '';
            for(Communities_Navigation_Item_Label__c cnil : cni.Communities_Navigation_Item_Labels__r){
                if(cnil.Language_Code__c==selectedLanguageCode){
                    this.label = cnil.Label__c;
                }
            }
            if(this.label==''){
                for(Communities_Navigation_Item_Label__c cnil : cni.Communities_Navigation_Item_Labels__r){
                    if(cnil.Language_Code__c=='en_US'){
                        this.label = cnil.Label__c;
                    }
                }
            }
            system.debug('***cni: ' + cni);
            system.debug('***tabNames: ' + tabNamesThatAreSObjects);
            system.debug('***label: ' + this.label);
            system.debug('***cni.tab_name__c: ' + cni.Tab_name__c);
            if(cni.URL__c=='#' || tabNamesThatAreSObjects.contains(cni.Tab_Name__c) || cni.URL__c.startsWith('http') || cni.URL__c.startsWith('//') || cni.URL__c.startsWith('www')){
                this.URL = cni.URL__c;
            }else{
               this.URL = '/' + cni.URL__c;
            }
            this.id = ((String)cni.id).substring(0,15);
            this.sequence = cni.Sequence__c;
        }
        public HierarchyNavItem (Communities_Navigation_Item__c cni, List<HierarchyNavItem> children, String selectedLanguageCode){
            this.label = '';
            for(Communities_Navigation_Item_Label__c cnil : cni.Communities_Navigation_Item_Labels__r){
                if(cnil.Language_Code__c==selectedLanguageCode){
                    this.label = cnil.Label__c;
                }
            }
            if(this.label==''){
                for(Communities_Navigation_Item_Label__c cnil : cni.Communities_Navigation_Item_Labels__r){
                    if(cnil.Language_Code__c=='en_US'){
                        this.label = cnil.Label__c;
                    }
                }
            }

            if(this.label==''){
                for(Communities_Navigation_Item_Label__c cnil : cni.Communities_Navigation_Item_Labels__r){
                    if(cnil.Language_Code__c=='en_US'){
                        this.label = cnil.Label__c;
                    }
                }
            }
            system.debug('***cni: ' + cni);
            system.debug('***tabNames: ' + tabNamesThatAreSObjects);
            system.debug('***label: ' + this.label);
            system.debug('***cni.tab_name__c: ' + cni.Tab_name__c);
            if(cni.URL__c=='#' || tabNamesThatAreSObjects.contains(cni.Tab_Name__c) || cni.URL__c.startsWith('http') || cni.URL__c.startsWith('//') || cni.URL__c.startsWith('www')){
                this.URL = cni.URL__c;
            }else{
                this.URL = '/' + cni.URL__c;
            }
            this.children = children;
            this.id = ((String)cni.id).substring(0,15);
            this.sequence = cni.Sequence__c;
        }

        public Integer compareTo(Object compareTo) {
            HierarchyNavItem compareToNav = (HierarchyNavItem)compareTo;
            Integer returnValue = 0;
            if(sequence > compareToNav.sequence || sequence==null) return 1;
            if(sequence < compareToNav.sequence) return -1;
            if(sequence == compareToNav.sequence){
                returnValue = label.compareTo(compareToNav.label);
            }
            return returnValue;
        }
    }
}