public with sharing class PartnerPointsLMSController {
    public PartnerPointsCatalogLMSItem[] contentList { get; set; }
    public SumTotal_Catalog__c[] unassignedDocs {get; set; }
    public String commandId {get; set; }
    public String selectedTrack {get; set; }
    public String titleFilter {get; set; }
    public PartnerPointsCatalogLMSItem editItem {get; set; }
    public SelectOption[] languageOptions {get; set; }
    public SelectOption[] subcategoryOptions {get; set; }
    public Boolean isGlobalPointAdmin { get; set; }
    public String userRegion { get; set; }

    Map<String,String> langmap = new Map<String,String> {
        'en'    => 'English',
        'zh_TW' => 'Chinese',
        'zh_tw' => 'Chinese',
        'zh_CN' => 'Chinese (simplified)',
        'zh_cn' => 'Chinese (simplified)',
        'zh'    => 'Chinese (simplified)',
        'ja'    => 'Japanese',
        'pt_BR' => 'Portuguese',
        'pt'    => 'Portuguese',
        'ko'    => 'Korean',
        'de'    => 'German',
        'es'    => 'Spanish',
        'fr'    => 'French',
        'it'    => 'Italian',
        'ru'    => 'Russian'
    };



    public PartnerPointsLMSController() {
        titleFilter = '';
        User me = [select Global_Partner_Points_Admin__c, Region__c from User where Id = :UserInfo.getUserId()];
        isGlobalPointAdmin = me.Global_Partner_Points_Admin__c;
    	userRegion = me.Region__c;

        if (isGlobalPointAdmin)
            selectedRegion = 'Global';
        else
            selectedRegion = userRegion;

        languageOptions = new List<SelectOption>();
        AggregateResult[] groupedResults = [
            select  Language__c, count(id)
            from    SumTotal_Catalog__c
            group by Language__c
        ];
        for (AggregateResult result : groupedResults) {
            String langloc = (String) result.get('Language__c');
            if (langloc != null) {
                langloc = langloc.toLowerCase();
                boolean found = false;
                for (String key : langmap.keySet()) {
                    if (langloc.startsWith(key)) {
                        found = true;
                        languageOptions.add(new SelectOption(langloc, langmap.get(key) + ' [' + langloc + ']'));
                        break;
                    }
                }
                if (!found)
                    languageOptions.add(new SelectOption(langloc, langloc));
            }
        }
        subcategoryOptions = new List<SelectOption>();
        for (Schema.PicklistEntry ple : Partner_Points_LMS_Catalog__c.Sub_Category__c.getDescribe().getPicklistValues()) {
            subcategoryOptions.add(new SelectOption(ple.getValue(), ple.getValue()));
        }

        selectedLanguage = 'en_us';
    }
    
    private void load() {

        String titlePattern = '%';
        if (titleFilter.trim().length() > 0) {
            titlePattern = '%' + titleFilter.trim() + '%';
        }
        
        Partner_Points_LMS_Catalog__c[] scoredList = [select Id, Course_Id__c from Partner_Points_LMS_Catalog__c where Full_Points__c > 0 and Global_Region__c = :selectedRegion];
        Set<String> scoredCourses = PartnerUtil.getStringFieldSet(scoredList, 'Course_Id__c');

        Map<String, Partner_Points_LMS_Catalog__c> contentMap = new Map<String, Partner_Points_LMS_Catalog__c>();
        Partner_Points_LMS_Catalog__c[] lmscat = null;
        if (selectedTrack == null || selectedTrack == 'None Selected') {
	        lmscat = [
	            select      Id, Name, Course_Id__c, IsActive__c, Full_Points__c, Language__c, Sub_Category__c, Partner_Track__c
	            from        Partner_Points_LMS_Catalog__c
	            where       Name like :titlePattern
	            and         Global_Region__c = :selectedRegion
	        ];
        }
        else {
	        lmscat = [
	            select      Id, Name, Course_Id__c, IsActive__c, Full_Points__c, Language__c, Sub_Category__c, Partner_Track__c
	            from        Partner_Points_LMS_Catalog__c
	            where       Name like :titlePattern
	            and			Partner_Track__c = :selectedTrack
	            and         Global_Region__c = :selectedRegion
	        ];
        }
        for (Partner_Points_LMS_Catalog__c c : lmscat) {
            if (selectedRegion != 'Global' && c.Language__c == selectedLanguage) {
                contentMap.put(c.Course_Id__c, c);
            }
            else
            if (selectedRegion == 'Global') {
                contentMap.put(c.Course_Id__c, c);
            }
        }

        System.debug('***** [debug] contentMap keys=' + contentMap.keySet());
        SumTotal_Catalog__c[] courseList = null;
        courseList = [
            select      Id, Activity_Name__c, SumTotal_ID__c, Training_Type__c, Training_Path__c
            from        SumTotal_Catalog__c
            where       Language__c = :selectedLanguage
            and         SumTotal_ID__c in :contentMap.keySet()
            and         IsDeleted = false
            order by    Activity_Name__c
        ];

        contentList = new List<PartnerPointsCatalogLMSItem>();
        String[] mappedDocIds = new List<String>();
        
        for (SumTotal_Catalog__c ver : courseList) {
            Partner_Points_LMS_Catalog__c citem = contentMap.get(ver.SumTotal_ID__c);
            if (citem != null) {
                PartnerPointsCatalogLMSItem item = new PartnerPointsCatalogLMSItem();
                item.courseId = citem.Course_Id__c;
                item.ppLMSId = citem.Id;
                if (ver == null) {
                    item.Title = '-- (course missing) --';
                }
                else {
                    item.Title = ver.Activity_Name__c;
                    mappedDocIds.add(ver.SumTotal_ID__c);
                }
                item.isActive = citem.IsActive__c;
                item.points = citem.Full_Points__c.intValue();
                item.language = citem.Language__c;
                item.isExam = ver.Training_Type__c == 'Exam';
                item.trackId = ver.Training_Path__c;
                item.subcategory = citem.Sub_Category__c;
                contentList.add(item);
            }
        }
        System.debug('***** [debug] ContentList size = ' + contentList.size());

        // Get list of all mapped documents if we are looking at globals
        if (selectedRegion == 'Global') {
            Partner_Points_LMS_Catalog__c[] allMapped = [select Course_Id__c from Partner_Points_LMS_Catalog__c where Global_Region__c != 'Global'];
            for (Partner_Points_LMS_Catalog__c item : allMapped) {
                // make sure we don't show any documents mapped to the non-Global region
                mappedDocIds.add(item.Course_Id__c);
            }
        } 
        else {
            // otherwise we don't want to show mapped global documents
            Partner_Points_LMS_Catalog__c[] allMapped = [select Course_Id__c from Partner_Points_LMS_Catalog__c where Global_Region__c = 'Global'];
            for (Partner_Points_LMS_Catalog__c item : allMapped) {
                mappedDocIds.add(item.Course_Id__c);
            }
        }

		SumTotal_Catalog__c[] toShow = new List<SumTotal_Catalog__c>();
        if (selectedTrack == null || selectedTrack == 'None Selected') {
            toShow = [
                select  Id, Activity_Name__c, SumTotal_ID__c, Language__c, Training_Type__c, Training_Path__c
                from    SumTotal_Catalog__c
                where   SumTotal_ID__c not in :mappedDocIds
                and     SumTotal_ID__c != null
                and		SumTotal_ID__c not in :scoredCourses
                and     Global_Region__c = :selectedRegion
                and     Activity_Name__c like :titlePattern
                //and     SumTotal_ID__c in :PartnerUtil.getStringFieldSet(lmscat, 'SumTotal_Id__c')
                order by Activity_Name__c
            ];
        }
        else {
            toShow = [
                select  Id, Activity_Name__c, SumTotal_ID__c, Language__c, Training_Type__c, Training_Path__c
                from    SumTotal_Catalog__c
                where   SumTotal_ID__c not in :mappedDocIds
                and     SumTotal_ID__c != null
                and		SumTotal_ID__c not in :scoredCourses
                and     Global_Region__c = :selectedRegion
                and     Activity_Name__c like :titlePattern
                and		Training_Path__c = :selectedTrack
                //and     SumTotal_ID__c in :PartnerUtil.getStringFieldSet(lmscat, 'SumTotal_Id__c')
                order by Activity_Name__c
            ];
        }


        unassignedDocs = toShow;
    }

    public String selectedRegion {
        get;
        set {
            if (selectedRegion != value) {
                selectedRegion = value;
                if (selectedLanguage != null) {
                    load();
                }
            }
        }
    }
    public String selectedLanguage {
        get;
        set {
            if (selectedLanguage != value) {
                selectedLanguage = value;
                if (selectedLanguage != null) {
                    load();
                }
            }
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
    

    public PageReference deleteButton() {
        String ppLMSId = System.currentPageReference().getParameters().get('ppLMSId');
        Partner_Points_LMS_Catalog__c content = [select Id, Course_Id__c, Global_Region__c from Partner_Points_LMS_Catalog__c where Id = :ppLMSId];
        PP_LMS_Stage__c[] stageList = [
            select  Id
            from    PP_LMS_Stage__c
            where   Course_Id__c = :content.Course_Id__c
            and     Language__c = :selectedLanguage
            and     Global_Region__c = :content.Global_Region__c
        ];
        Set<String> stageIdList = PartnerUtil.getIdSet(stageList);
        Integer cnt = 0;
        if (content.Global_Region__c == 'Global') {
          cnt = [select count() from PP_Scores__c where LMS_Ref__c in :stageIdList];
        }
        else {
          cnt = [select count() from PP_Scores__c where LMS_Ref__c in :stageIdList and Account__r.Global_Region__c = :content.Global_Region__c];
        }
        if (cnt > 0) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Training has associated scores. Not deleted'));
            return null;
        }
        delete new Partner_Points_LMS_Catalog__c(Id = ppLMSId);
        load();
        return null;
    }

    public PageReference cancelEdit() {
        return Page.PartnerPointsCatalogLMS;
    }
    
    public PageReference backToCatalog() {
        return Page.PartnerPointsCatalog;
    }
    
    public PageReference saveEdit() {
        try {
            if (editItem.ppLMSId == null) {
                // new
                Partner_Points_LMS_Catalog__c c = new Partner_Points_LMS_Catalog__c();
                c.Course_Id__c = editItem.courseId;
                c.Full_Points__c = editItem.points;
                c.PP_Catalog__c = [select Id from PP_Catalog__c where Category__c = 'LMS'].Id;
                c.Global_Region__c = selectedRegion;
                c.Language__c = editItem.language;
                c.IsActive__c = editItem.isActive;
                c.Sub_Category__c = editItem.subcategory;
                c.Partner_Track__c = editItem.trackId;
                c.SumTotal_Catalog__c = editItem.catalogId;
                if (editItem.title.length() > 80)
                    c.Name = editItem.title.substring(0, 80);
                else
                    c.Name = editItem.title;
                insert c;
            }
            else {
                Partner_Points_LMS_Catalog__c c = new Partner_Points_LMS_Catalog__c(Id = editItem.ppLMSId);
                c.Full_Points__c = editItem.points;
                c.IsActive__c = editItem.isActive;
                c.Partner_Track__c = editItem.trackId;
                c.Sub_Category__c = editItem.subcategory;
                update c;
            }
            load();
            return Page.PartnerPointsCatalogLMS;
        }
        catch (DMLException e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getDmlMessage(0)));
        }
        return null;
    }
    
    public PageReference manageButton() {
        String contentId = System.currentPageReference().getParameters().get('ppLMSId');
        editItem = null;
        for (PartnerPointsCatalogLMSItem c : contentList) {
            if (c.ppLMSId == contentId) {
                editItem = c;
                return Page.PartnerPointsCatalogLMSEdit;
            }
        }
        return null;
    }

    public PageReference assignButton() {
        String contentId = System.currentPageReference().getParameters().get('contentId');
        editItem = null;
        for (SumTotal_Catalog__c ver : unassignedDocs) {
            if (ver.Sumtotal_ID__c == contentId) {
                editItem = new PartnerPointsCatalogLMSItem();
                editItem.isActive = true;
                editItem.courseId = contentId;
                editItem.points = 0;
                editItem.catalogId = ver.Id;
                editItem.isExam = ver.Training_Type__c == 'Exam';
                editItem.title = ver.Activity_Name__c;
                editItem.language = selectedLanguage;
                editItem.trackId = ver.Training_Path__c;
                editItem.subcategory = 'E-Learning';
                if (editItem.isExam)
                    editItem.subcategory += ' with Exam';
                else
                    editItem.subcategory += ' without Exam';

                break;
            }
        }
        if (editItem != null) {
            return Page.PartnerPointsCatalogLMSEdit;
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
    PP_Catalog__c catLMS = null;
        PP_Catalog__c[] catLMSList = [select Id from PP_Catalog__c where Category__c = 'LMS' limit 1];
        if (!catLMSList.isEmpty()) {
          catLMS = catLMSList.get(0);
        }
        else {
          catLMS = new PP_Catalog__c();
          catLMS.Category__c = 'LMS';
          catLMS.Global_Region__c = 'NA';
            
          catLMS.Description__c = 'LMS';
          insert catLMS;
        }
        
        PartnerPointsLMSController ctrl = new PartnerPointsLMSController();

        
/*
        System.currentPageReference().getParameters().put('ppLMSId', ctrl.unassignedDocs.get(0).Id);
        PageReference ref = ctrl.manageButton();
        System.assert(ref != null, 'Did not find record to edit');
        ref = ctrl.saveEdit();              // for a dummy save
        PageReference pref = ctrl.deleteButton();
*/
        
        PageReference ref = null;
        if (ctrl.unassignedDocs.size() > 0){
	        System.currentPageReference().getParameters().put('contentId', ctrl.unassignedDocs.get(0).SumTotal_ID__c);
	        ref = ctrl.assignButton();
	        ctrl.editItem.points = 36;
	        ref = ctrl.saveEdit();
	        ref = ctrl.manageButton();
        }
        
        if (!ctrl.contentList.isEmpty()) {
            System.currentPageReference().getParameters().put('ppLMSId', ctrl.contentList.get(0).ppLMSId);
            ref = ctrl.deleteButton();
        
            ref = ctrl.cancelEdit();
            ref = ctrl.resetFilterButton();
            ref = ctrl.filterButton();
        }
    }
}