public with sharing class CommunitiesToolShortcuts {
	
	public final Map<String,List<String>> partnerStatusMap;
    public User u { get; set; }
    public Id userId { get; set; }
    final Account acc;

    public Boolean hasErrors { get; set; }

    public String selectedLanguageCode { get; set; }

    public static Set<String> tabNamesThatAreSObjects { get; set; }
    public Set<String> allowedTabs { get; set; }

	public List<Communities_Tool_Shortcut__c> availableShortcuts { get; set; }
	public Set<Id> activeShortcutIds { get; set; }

	public List<ShortcutWrapper> shortcutWrappers { get; set; }

	public String returnURL { get; set; }

	public CommunitiesToolShortcuts() {
		// Test User Id - George Na
        //u = CommunityTools.getUser('00560000001ROuQ');
        u = CommunityTools.getUser(UserInfo.getUserId());
        selectedLanguageCode = CommunityTools.getLanguage(u);
        acc = CommunityTools.getAccount(u);
        partnerStatusMap = CommunityTools.getPartnerStatus(acc, u.Contact.Id, u);

        allowedTabs = new Set<String>();
        tabNamesThatAreSObjects = new Set<String>();
        // Don't query Tab schema during unit tests or for unauthenticated users
        if(test.isRunningTest()){
            allowedTabs = CommunitiesTestUtils.testAllowedTabs();
        }else if(!partnerStatusMap.keyset().isEmpty()){
            Map<String,Set<String>> tabMap = CommunityTools.getAllowedTabs();
            allowedTabs = tabMap.get('allowedTabs');
            tabNamesThatAreSObjects = tabMap.get('SObjects');
            if(u.IsPartnerAdmin__c){
            	allowedTabs.add('User__IsPartnerAdmin__c');
            }
        }
        setup();
	}

	public void setup(){
		returnURL = ApexPages.currentPage().getParameters().get('retURL');
		hasErrors = false;
		getActiveShortcutIds();
		getAvailableShortcuts();
		shortcutWrappers = new List<ShortcutWrapper>();
		for(Communities_Tool_Shortcut__c cts : availableShortcuts){
			ShortcutWrapper sw = new ShortcutWrapper(cts, activeShortCutIds, selectedLanguageCode);
			shortcutWrappers.add(sw);
		}
	}

	public void getActiveShortcutIds(){
		activeShortcutIds = new Set<Id>();
		for(Contact_Tool_Shortcut__c cts :
			[SELECT Id, Communities_Tool_Shortcut__r.Id
			FROM Contact_Tool_Shortcut__c
			WHERE Contact__r.Id = :u.Contact.Id
			])
		{
			activeShortcutIds.add(cts.Communities_Tool_Shortcut__r.Id);
		}
	}

	public void getAvailableShortcuts(){
		availableShortcuts = 
			[SELECT Id,
				(SELECT 
				Link_Text__c
				,Tooltip_Text__c
				,Language_Code__c
				FROM Communities_Tool_Shortcut_Labels__r
				)
			FROM Communities_Tool_Shortcut__c
			WHERE Availability_Controlled_By__c in :allowedTabs
			ORDER By Tool_Name__c ASC
			];
	}

	public PageReference save(){
		//iterate over the list of checked items.
		Set<Id> selectedItemIds = new Set<Id>();
		for(ShortcutWrapper sw : shortcutWrappers){
			if(sw.checked){
				selectedItemIds.add(sw.id);
			}
		}
		//break and error if there are more than 4 selected.
		if(selectedItemIds.size()>4){
            hasErrors = true;
            return null;
        }
		//identify new additions and add to a list for insertion.
		List<Id> additions = new List<Id>();
		for(Id i : selectedItemIds){
			if(!activeShortcutIds.contains(i)){
				additions.add(i);
			}
		}
		//identify removals and add to a set for querying and deletion.
		Set<Id> removals = new Set<Id>();
		for(Id i : activeShortcutIds){
			if(!selectedItemIds.contains(i)){
				removals.add(i);
			}
		}
		//create new Contact Tool Shortcut records
		List<Contact_Tool_Shortcut__c> insertRecords = new List<Contact_Tool_Shortcut__c>();
		for(Id i : additions){
			Contact_Tool_Shortcut__c cts = new Contact_Tool_Shortcut__c();
			cts.Contact__c = u.Contact.Id;
			cts.Communities_Tool_Shortcut__c = i;
			insertRecords.add(cts);
		}
		//query for the records to delete
		List<Contact_Tool_Shortcut__c> deleteRecords = [SELECT Id FROM Contact_Tool_Shortcut__c WHERE Contact__c = :u.Contact.Id AND Communities_Tool_Shortcut__r.Id in :removals];
		//execute DML
		try{
			if(insertRecords.size()>0){
				insert insertRecords;
			}
			if(deleteRecords.size()>0){
				delete deleteRecords;	
			}
		}catch(Exception e){}
		//redirect
		return redirectOnComplete();
	}

	public PageReference redirectOnComplete(){
		PageReference pr;
		if(returnURL != null && returnURL != ''){
			pr = new PageReference(returnURL);	
		}else{
			pr = new PageReference('/s/dashboard');
		}
		return pr;
	}

	public class ShortcutWrapper{

		public Boolean checked { get; set; }
		public String label { get; set; }
		public String helpText { get; set; }
		public String id { get; set; }

		public ShortcutWrapper (Communities_Tool_Shortcut__c cts, Set<Id> activeIds, String selectedLanguageCode){
			this.checked = activeIds.contains(cts.id);
			this.id = cts.id;
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
}