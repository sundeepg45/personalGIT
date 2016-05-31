global without sharing class CommunitiesNavigationController {

    public final Map<String,List<String>> partnerStatusMap;
    public User u { get; set; }
    public Id userId { get; set; }
    final Account acc;

    public String selectedLanguageCode { get; set; }
    public String currentLanguage { get; set; }
    public String newLanguage { get; set; }

    public Boolean isExternalUser { get; set; }
    public Boolean allowedToSearch { get; set; }

    public Set<Id> matchingAudienceIds { get; set; }

    public Map<Id,Communities_Navigation_Item__c> idToNavItem { get; set; }
    public Map<Id,List<Id>> topLevelIdsToChildIds { get; set; }
    public Map<Id,List<Id>> childrenToGrandChildIds { get; set; }

    public List<Communities_Navigation_Item__c> topLevelNavItems { get; set; }
    public List<Communities_Navigation_Item__c> childNavItems { get; set; }
    public List<Communities_Navigation_Item__c> grandChildNavItems { get; set; }

    public static Set<String> tabNamesThatAreSObjects { get; set; }
    public List<String> cleanedObjectNames { get; set; }

    public List<HierarchyNavItem> sortedNavItems { get; set; }

    public Set<String> allowedTabs { get; set; }

    // *** search URL:
    // /search/SearchResults?searchType=17&sen=007&setLast=1&sbstr=Partner+Center&search=+Go%21+

    public CommunitiesNavigationController() {

        // Test User Id - George Na
        //u = CommunityTools.getUser('00560000001ROuQ');
        u = CommunityTools.getUser(UserInfo.getUserId());
        userId = u.id;
        currentLanguage = languageCodeToLanguage.get(u.languageLocaleKey);
        isExternalUser = CommunityTools.getIsExternaluser(u);
        if(isExternalUser){
            selectedLanguageCode = CommunityTools.getLanguage(ApexPages.currentPage().getHeaders().get('Accept-Language'));
        }else{
            selectedLanguageCode = CommunityTools.getLanguage(u);
        }

        acc = CommunityTools.getAccount(u);
        partnerStatusMap = CommunityTools.getPartnerStatus(acc, u.Contact.Id, u);
        matchingAudienceIds = CommunityTools.getMatchingAudiences(partnerStatusMap);

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
        allowedToSearch = getIsAllowedToSearch();
        cleanedObjectNames = cleanObjNames(tabNamesThatAreSObjects);

        getAllowedNavItems(matchingAudienceIds);
        sortNavItems();
    }

    public String getAccountId() {
        if (acc != null) {
            String s = acc.Id;
            return s.substring(0,15);
        }
        return null;
    }

    public String getPartyNumber() {
        if (acc != null) {
            String s = acc.CDHPartyNumber__c;
            return s;
        }
        return null;
    }

    public String getAccountCountry() {
        if (acc != null) {
            return acc.BillingCountry == null ? acc.ShippingCountry : acc.BillingCountry;
        }
        return null;
    }

    public Boolean getIsRequalOverdue() {
        return acc != null && acc.RequalStatus__c == 'Overdue';
    }

    public Boolean getIsAllowedToSearch(){
        List<Audience__c> audiences = [SELECT Id, Name FROM Audience__c WHERE Name = 'Allowed to Search'];
        if(audiences.size()==1){
            return matchingAudienceIds.contains(audiences[0].id);
        }else{
            return false;
        }
    }
    public Map<String,String> languageCodeToLanguage = new Map<String,String>{
         'en_US' => 'English'
        ,'de' => 'German'
        ,'pt_BR' => 'Portuguese'
        ,'ja' => 'Japanese'
        ,'zh_HANS' => 'Chinese'
        ,'zh_CN' => 'Chinese'
        ,'fr' => 'French'
        ,'it' => 'Italian'
        ,'ko' => 'Korean'
        ,'es' => 'Spanish'
    };

    public static Map<String,String> languageToLanguageCode = new Map<String,String>{
        'English' => 'en_US'
        ,'German' => 'de'
        ,'Portuguese' => 'pt_BR'
        ,'Japanese' => 'ja'
        ,'Chinese' => 'zh_CN'
        ,'French' => 'fr'
        ,'Italian' => 'it'
        ,'Korean' => 'ko'
        ,'Spanish' => 'es'
    };

    public static Map<String,String> objNameToSearchSen = new Map<String,String>{
        'Account' => '001'
        ,'Contact' => '003'
        ,'Lead' => '00Q'
        ,'Opportunity' => '006'
        ,'Case' => '500'
        ,'Campaign' => '701'
        ,'Task' => '00T'
        ,'Note' => '002'
        ,'Idea' => '087'
        ,'Customer Reference' => 'a1M'
        ,'MDF' => 'a1B'
        ,'NFR' => 'a1b'
    };

    public static List<String> cleanObjNames(Set<String> tabNames){
        List<String> cleanedNames = new List<String>();
        for(String s : tabNames){
            String cleanedName = s.removeEnd('__c');
            cleanedName = cleanedName.replace('_',' ');
            if(objNameToSearchSen.keyset().contains(cleanedName)){
                cleanedNames.add(cleanedName);
            }
        }
        cleanedNames.sort();
        return cleanedNames;
    }


    @RemoteAction
    global static String getLanguage() {
        User u = CommunityTools.getUser(UserInfo.getUserId());
        boolean isExternalUser = CommunityTools.getIsExternaluser(u);
        String selectedLanguageCode = 'en_US';
        if(isExternalUser){
            selectedLanguageCode = CommunityTools.getLanguage(ApexPages.currentPage().getHeaders().get('Accept-Language'));
        }else{
            selectedLanguageCode = CommunityTools.getLanguage(u);
        }
        if (selectedLanguageCode == 'zh_CN'){
            // Special case to be site.com compatible
            return 'zh_HANS';
        }
        return selectedLanguageCode;
    }

    @RemoteAction
    global static String updateUserLanguage(Id userId, String lang) {
        User u = [SELECT LanguageLocaleKey FROM User WHERE Id = :userId];
        String languageCode = CommunitiesNavigationController.languageToLanguageCode.get(lang);
        u.LanguageLocaleKey = languageCode;
        update u;
        if (languageCode == 'zh_CN'){
            // Special case to be site.com compatible
            return 'zh_HANS';
        }
        return languageCode;
    }

    @RemoteAction
    global static String executeSearch(String objName, String searchString){
        String baseURL = URL.getSalesforceBaseUrl().toExternalForm();
        // *** example search url for 'Partner Center' on Account object *** //
        // /search/SearchResults?searchType=2&sen=001&setLast=1&str=Partner+Center&search=Search
        String searchURL = baseURL += '/search/SearchResults?searchType=2';
        searchURL += ('&sen=' + objNameToSearchSen.get(objName));
        searchURL += '&setLast=1';
        searchURL += ('&str=' + searchString);
        return searchURL;
    }

    public void getAllowedNavItems(Set<Id> audienceIds){
        //Map all record ids to records
       idToNavItem = new Map<Id,Communities_Navigation_Item__c>();

        system.debug('getAllowedNavItems: audienceIds: [' + audienceIds + ']');

        //Get top-level records

        topLevelNavItems = [SELECT
            Id
            ,URL__c
            ,Sequence__c
            ,Tab_Name__c
            ,English_Label__c
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
            AND (Type__c = 'Main Navigation' OR Type__c = '')
            ORDER BY Sequence__C ASC
            ];

        //Add top-level record ids to a set
        Set<Id> topLevelIds = new Set<Id>();
        for(Communities_Navigation_Item__c cni : topLevelNavItems){
            topLevelIds.add(cni.id);
            idToNavItem.put(cni.id,cni);
        }

        //Query children of top-level items
        childNavItems = [SELECT
            Id
            ,URL__c
            ,Sequence__c
            ,Tab_Name__c
            ,Parent_Item__r.id
            ,English_Label__c
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
            AND Type__c = 'Main Navigation'
            ORDER BY Sequence__C ASC
            ];

        //Add child record ids to a set and to the master Id-to-record map. Map each top-level id to its corresponding child ids.
        Set<Id> childIds = new Set<Id>();
        topLevelIdsToChildIds = new Map<Id,List<Id>>();
        if(topLevelids!=null && topLevelIds.size()>0){
            for(Communities_Navigation_Item__c tlcni : topLevelNavItems){
                List<Id> childIdList = new List<Id>();
                for(Communities_Navigation_Item__c ccni : childNavItems){
                    if(ccni.Parent_Item__r.id==tlcni.id){
                        childIds.add(ccni.id);
                        childIdList.add(ccni.id);
                        idToNavItem.put(ccni.id,ccni);
                    }
                }
                topLevelIdsToChildIds.put(tlcni.id,childIdList);
            }
        }

        //Query grandchildren
        grandChildNavItems = [SELECT
            Id
            ,URL__c
            ,Sequence__c
            ,Tab_Name__c
            ,Parent_Item__r.id
            ,English_Label__c
            ,(SELECT
                Label__c,
                Language_Code__c
                FROM Communities_Navigation_Item_Labels__r
                ORDER BY Label__c ASC
                )
            FROM Communities_Navigation_Item__c
            WHERE
            (Audience__c in :audienceIds OR Tab_Name__c in :allowedTabs)
            AND Parent_Item__c in :childIds
            AND Type__c = 'Main Navigation'
            ORDER BY Sequence__C ASC
            ];

        //Add grandchild records to the master Id-to-record map.  Map eaach child id to its corresponding grandchild ids.
        childrenToGrandChildIds = new Map<Id,List<Id>>();
        if(childNavItems!=null && childNavItems.size()>0){
            for(Communities_Navigation_Item__c ccni : childNavItems){
                List<Id> grandChildIdList = new List<Id>();
                for(Communities_Navigation_Item__c gccni : grandChildNavItems){
                    if(gccni.Parent_Item__r.id==ccni.id){
                        grandChildIdList.add(gccni.id);
                        idTonavItem.put(gccni.id,gccni);
                    }
                }
                childrenToGrandChildIds.put(ccni.id,grandChildIdList);
            }
        }
    }

    public void sortNavItems(){

        //Master list, starting from top-level parents
        sortedNavItems = new List<HierarchyNavItem>();

        for(Communities_Navigation_Item__c cni : topLevelNavItems){

            //Lists of children, under each parent
            List<HierarchyNavItem> children = new List<HierarchyNavItem>();

            if(topLevelIdsToChildIds.keyset().contains(cni.id)){
                for(Id cniChild : topLevelIdsToChildIds.get(cni.id)){

                    //Lists of grandchildren, under each child.
                    List<HierarchyNavItem> grandChildren = new List<HierarchyNavItem>();

                    if(childrenToGrandChildIds.keyset().contains(cniChild)){
                        for(Id cniGrandChild : childrenToGrandChildIds.get(cniChild)){

                            HierarchyNavItem grandChild = new HierarchynavItem(idToNavItem.get(cniGrandChild),selectedLanguageCode);
                            grandChildren.add(grandChild);
                            grandchildren.sort();
                        }
                    }

                    HierarchyNavItem child = new HierarchyNavItem(idToNavItem.get(cniChild),grandChildren,selectedLanguageCode);
                    children.add(child);
                    children.sort();

                }
            }

            HierarchyNavItem item = new HierarchyNavItem(cni,children,selectedLanguageCode);
            sortedNavItems.add(item);
            sortedNavItems.sort();

        }

        Integer index = 1;
        for (HierarchynavItem item : sortedNavItems) {
            item.index = String.valueOf(index);
            index++;
        }
    }

    public class HierarchyNavItem implements Comparable{

        public String Label { get; set; }
        public String EnglishLabel { get; set; }
        public List<HierarchyNavItem> children { get; set; }
        public String URL { get; set; }
        public String id { get; set; }
        public Decimal sequence { get; set; }
        public String index { get; set; }

        public HierarchyNavItem (Communities_Navigation_Item__c cni, String selectedLanguageCode){
            this.EnglishLabel = cni.English_Label__c;
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
            if(cni.URL__c=='#' || tabNamesThatAreSObjects.contains(cni.Tab_Name__c) || cni.URL__c.startsWith('http') || cni.URL__c.startsWith('//') || cni.URL__c.startsWith('www')){
                this.URL = cni.URL__c;
            }else{
               this.URL = '/' + cni.URL__c;
            }

            this.id = ((String)cni.id).substring(0,15);
            this.sequence = cni.Sequence__c;
        }
        public HierarchyNavItem (Communities_Navigation_Item__c cni, List<HierarchyNavItem> children, String selectedLanguageCode){
            this.EnglishLabel = cni.English_Label__c;
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

        public String internalLabel {
            get {
                return EnglishLabel.replaceAll('[^a-zA-Z0-9]', '');
            }
        }
    }
}