public without sharing class StorybookContentUpload {

    public String fileName { get; set; }
    public Blob fileBody { get; set; }
    public String fileSource { get; set; }
    public Boolean showLocalInput { get; set; }
    public Boolean showLibraryInput { get; set; }
    public String contentSearchString { get; set; }
    public String fileDestination { get; set; }
    public String uploadLanguage { get; set; }
    public String uploadExpirationDate { get; set; }
    public String uploadDocumentType { get; set; }
    public String uploadDescription { get; set; }

    public String updateLineItemId { get; set; }
    public Map<String, ContentVersion> contentIdToRecord { get; set; }
    public Map<String, String> contentIdToOriginalStorybook { get; set; }
    public Map<Id, String> contentIdToOwningLibrary { get; set; }

    public Map<Id, String> libraryIdToName { get; set; }

    public List<ContentVersion> contentResults { get; set; }
    public List<SelectOption> libraryOptions { get; set; }
    public List<SelectOption> documentTypeOptions { get; set; }
    public List<SelectOption> languageOptions { get; set; }
    public List<SelectOption> expirationDateOptions { get; set; }

    private Map<String,Schema.SObjectField> contentVersionFieldMap;

// expiration date, document type

    public StorybookContentUpload(ApexPages.StandardController sc) {

        List<ContentWorkspace> libraries = [SELECT Id, Name FROM ContentWorkspace];
        libraryIdToName = new Map<Id,String>();
        libraryOptions = new List<SelectOption>();
        SelectOption soBlank = new SelectOption('','Select Library');
        libraryOptions.add(soBlank);
        for(ContentWorkspace cw : libraries){
            SelectOption so = new SelectOption(cw.id, cw.Name);
            libraryOptions.add(so);
            libraryIdToName.put(cw.id,cw.Name);
        }
        getFieldMap();
        documentTypeOptions = queryPicklist('Document_Type__c');
        languageOptions = queryPicklist('Language');
        expirationDateOptions = queryPicklist('Expiration_Date__c');

	}

    public void updateLineItem(){
        if(contentIdToOriginalStorybook.get(updateLineItemId)==contentIdToRecord.get(updateLineItemId).Storybook__c){
            return;
        }
        try{
            update contentIdToRecord.get(updateLineItemId);
        }catch(Exception e){
                system.debug(e);
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Update failed.  Make sure that you have administrator permissions in this library and that you are able to edit this Content Item.'));
                return;
        }
        contentIdToOriginalStorybook.put(updateLineItemId,contentIdToRecord.get(updateLineItemId).Storybook__c);
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM,'Document updated!'));
    }

    public void searchForContent(){
        String amendedSearchString = '%'+contentSearchString+'%';
        Set<Id> contentDocumentIds = new Set<Id>();
        contentResults = [SELECT Id, Title, Language, ContentDocumentId, Description, Document_Type__c,
                            Storybook__c
                            FROM ContentVersion
                            WHERE Title LIKE :amendedSearchString
                            AND isLatest = true
                            AND Origin != 'H'
                            AND PublishStatus ='P'
                            ORDER BY CreatedDate DESC
                            LIMIT 30];
        contentIdToRecord = new Map<String, ContentVersion>();
        contentIdToOriginalStorybook = new Map<String, String>();
        for(ContentVersion cv : contentResults){
            contentIdToRecord.put(cv.id, cv);
            contentIdTooriginalStorybook.put(cv.id, cv.Storybook__c);
            contentDocumentIds.add(cv.ContentDocumentId);
        }
        contentIdToOwningLibrary = new Map<Id,String>();
        List<ContentWorkspaceDoc> docLibraryLinks = [SELECT ContentWorkspaceId, ContentDocumentId FROM ContentWorkSpaceDoc WHERE ContentDocumentId IN :contentDocumentIds];
        for(ContentVersion cv : contentResults){
            for(ContentWorkspaceDoc cwd : docLibraryLinks){
                if(cwd.ContentDocumentId==cv.ContentDocumentId){
                    contentIdToOwningLibrary.put(cv.id,libraryIdToName.get(cwd.ContentWorkspaceId));
                }

            }
        }
    }

    public void uploadFile(){
        if(fileName==null || fileBody==null || fileDestination=='' || fileDestination==null){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'You must select a file and a target Library before you can upload.'));
            return;
        }
        if(uploadLanguage==null){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'You must select a Language.'));
            return;
        }
        ContentVersion cv = new ContentVersion();
        cv.PathOnClient = fileName;
        cv.OwnerId = UserInfo.getUserId();
        cv.Description = uploadDescription;
        cv.Title = fileName;
        cv.VersionData = fileBody;
        cv.Language = uploadLanguage;
        insert cv;

        ContentWorkspaceDoc cwd = new ContentWorkSpaceDoc();
        cwd.ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;
        cwd.ContentWorkspaceId = fileDestination;

        try{
            insert cwd;
        }catch(Exception e){
            return;
        }


        cv.Document_Type__c = uploadDocumentType;
        cv.Expiration_Date__c = uploadExpirationDate;
        update cv;

        String contentId = cv.id;
        cv = new ContentVersion();
        filebody = null;

        contentResults = [SELECT Id, Title, Language, ContentDocumentId, Description,
                            Document_Type__c, Expiration_Date__c, Storybook__c
                            FROM ContentVersion
                            WHERE Id = :contentId
                            AND isLatest = true
                            ORDER BY CreatedDate DESC
                            LIMIT 1
                            ];
        contentIdToOwningLibrary = new Map<Id,String>();
        contentIdToowningLibrary.put(contentResults[0].id,libraryidToname.get(cwd.ContentWorkspaceId));

        contentIdToRecord = new Map<String, ContentVersion>();
        contentIdTooriginalStorybook = new Map<String, String>();

        contentIdTooriginalStorybook.put(contentResults[0].id, contentResults[0].Storybook__c);
        contentIdToRecord.put(contentResults[0].id, contentResults[0]);

        fileSource='library';
        updateSections();

    }

    public void updateSections(){
        if(fileSource=='local'){
            showLocalInput=true;
            showLibraryInput=false;
        }else if(fileSource=='library'){
            showLibraryInput=true;
            showLocalInput=false;
        }else{
            showLibraryInput=false;
            showLocalInput=false;
        }
    }

    void getFieldMap(){
        Schema.SObjectType targetType = Schema.getGlobalDescribe().get('ContentVersion');
        Sobject contentObject = targetType.newSObject();
        Schema.sObjectType sobject_type = contentObject.getSObjectType();
        Schema.DescribeSObjectResult sobject_describe = sobject_type.getDescribe();
        contentVersionFieldMap = sobject_describe.fields.getMap();
    }

    public List<SelectOption> queryPicklist(String fieldName){
        List<Schema.PicklistEntry> pick_list_values = contentVersionFieldMap.get(fieldName).getDescribe().getPickListValues();
        return getSelectOptions(pick_list_values);
    }

    public List<SelectOption> getSelectOptions(List<Schema.PicklistEntry> entries){
        List<SelectOption> options = New List<SelectOption>();
        selectOption soBlank = new SelectOption('','');
        options.add(soBlank);
        for(Schema.PicklistEntry entry : entries){
            selectOption so = new SelectOption(entry.getValue(),entry.getLabel());
            options.add(so);
        }
        return options;
    }

}