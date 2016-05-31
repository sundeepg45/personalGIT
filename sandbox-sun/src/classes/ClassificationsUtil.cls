public with sharing class ClassificationsUtil {

	public static List<SelectOption> getSelectOptions(String hierarchyKey) {
		return getSelectOptions(hierarchyKey, true);
	}
	
	public static List<SelectOption> getSelectOptions(String hierarchyKey, boolean isParentHKEY) {
		return getSelectOptions(hierarchyKey, isParentHKEY, null);
	}	
	
	public static List<SelectOption> getSelectOptionsByParentId(Id classificationId, SelectOption defaultOption){
		Classification__c clfn = [select Id, hierarchyKey__c from Classification__c where id = :classificationId];
		return getSelectOptions(clfn.hierarchyKey__c + '.%', true, defaultOption);
	}
	
	public static List<SelectOption> getSelectOptionsByParentId(Id classificationId){
		return getSelectOptionsByParentId(classificationId, null);
	}
		
	public static List<SelectOption> getSelectOptions(String hierarchyKey, boolean isParentHKEY, SelectOption defaultOption) {
    	System.debug('Fetching Classifications with a Key of ' + hierarchyKey);
    	String language = UserInfo.getLanguage();
    	Map<Id, String> translationMap = new Map<Id, String>();
    	
    	Integer depth = hierarchyKey.split('\\.').size();
    	if (!hierarchyKey.endsWith('.%')){
    		depth += 1;
    	}
    	if (!isParentHKEY){
    		depth += 1;
    	}
    	
    	for (ClassificationTranslation__c ct : [
              select Classification__c, LanguageCode__c, Translation__c, Classification__r.Name, Classification__r.HierarchyDepth__c
               	  from ClassificationTranslation__c
               	  where Classification__r.HierarchyKey__c like :hierarchyKey 
               	  and (LanguageCode__c = :language)
               	  and Classification__r.HierarchyDepth__c = :depth
              order by Translation__c desc]){
            translationMap.put(ct.Classification__c, ct.Translation__c);
        }
        
		List<Classification__c> classificationList = [
			select Id, Name, HierarchyKey__c, HierarchyDepth__c
				from Classification__c
				where HierarchyKey__c like :hierarchyKey 
				and HierarchyDepth__c = :depth
				order by Name desc
		];
              
        List<String> translatedLabels = new List<String>();
        Map<String, SelectOption> optionsMap = new Map<String, SelectOption>();
        SelectOption noneOption = null;
              
        for (Classification__c c : classificationList) {
        	String label = c.Name;
        	if (translationMap.containsKey(c.Id)){
        		label = translationMap.get(c.Id);
        		optionsMap.put(label, new SelectOption(c.Id, label));
        	} else {
          		optionsMap.put(label, new SelectOption(c.Id, label));
        	}
        	if (c.Name != 'None' && c.Name != '--None--'){
          		translatedLabels.add(label);
        	} else {
        		noneOption = optionsMap.get(label);
        	}
        }

        List<SelectOption> options = new List<SelectOption>();
        translatedLabels.sort();

		if (noneOption != null){
			options.add(noneOption);
		}

        if (defaultOption != null){
        	options.add(defaultOption);
        }
        for(String name : translatedLabels){
        	options.add(optionsMap.get(name));
        }

        return options;
    }
    
}