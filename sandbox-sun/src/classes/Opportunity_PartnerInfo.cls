/**
 * This is the a child class used for individual partners by the Opportunity_ManagePartners
 * controller extension.
 *
 * @author Bill C Riemers <briemers@redhat.com>
 * @version 2011-12-20
 */
public without sharing class Opportunity_PartnerInfo {
	private static Integer nextId = 1;
	public final OpportunityPartner__c opportunityPartner;
	private final Opportunity_ManagePartners parent;
	public Integer id;

	public Opportunity_PartnerInfo(Opportunity_ManagePartners parent) {
		this.parent = parent;
		this.opportunityPartner = new OpportunityPartner__c(
			Opportunity__c = parent.getOpportunity().Id );
		this.id = (nextId++);
	}

	public Opportunity_PartnerInfo(Opportunity_ManagePartners parent,OpportunityPartner__c opportunityPartner) {
		this.parent = parent;
		this.opportunityPartner = opportunityPartner;
		this.id = (nextId++);
	}

	public static Pattern getPartnerTypePattern(String channel,String rt) {
		return Opportunity_ManagePartners.getPartnerTypePattern(channel,rt);
	}

	private static void addRecursive(Map<Id,Classification__c> classificationMap,Set<Id> idSet,Id id) {
		if(! idSet.contains(id)) {
			Classification__c c = classificationMap.get(id);
			if(c != null) {
				idSet.add(id);
				addRecursive(classificationMap,idSet,c.Parent__c);
			}
		}
	}

	private static Set<Id> getClassificationIdSet(
		List<Classification__c> classificationList,Id id,Id defaultId)
	{
		final Set<Id> retval = new Set<Id>();
		for(Integer i=0;i < classificationList.size();i++) {
			final Classification__c start = classificationList.get(i);
			if(start.Id == id) {
				Classification__c c = start;
				do {
					retval.add(c.Id);
					if(++i >= classificationList.size()) {
						break;
					}
					c = classificationList.get(i);
				} while(c.HierarchyDepth__c > start.HierarchyDepth__c);
				break;
			}
		}
		if(retval.contains(defaultId)) {
			retval.add(null);
		}
		return retval;
	}

	private static List<SelectOption> getOptionsList(
		List<Classification__c> classificationList, 
		Integer depth, 
		String defaultValue)
	{
		List<SelectOption> selectOptions = new List<SelectOption>();
		try {
			Set<String> labels = new Set<String>();
			selectOptions.add(new SelectOption(defaultValue,'--None--'));
			if(classificationList != null) {
				for(Classification__c c : classificationList) {
					String [] hierarchy = c.Hierarchy__c.split(' » ',depth);
					String label = '--None--';
					if(hierarchy.size() >= depth) {
						label = hierarchy[depth-1];
					}
					if(label != null) {
						selectOptions.add(new SelectOption(c.Id,label));
						labels.add(label);
					}
				}
				if(labels.contains('--None--')) {
					selectOptions.remove(0);
				}
			}
		}
		catch(Exception e) {
			ApexPages.addMessages(e);
		}
		return selectOptions;
	}

	private static String getName(Classification__c c,Integer depth) {
		String retval = '';
		if(c != null && c.Hierarchy__c != null) {
			final String [] hierarchy = c.Hierarchy__c.split(' » ',3);
			if(hierarchy.size() > depth) {
				retval = hierarchy[depth];
			}
		}
		return retval;
	}

	private static Boolean hasDescendents(Classification__c value) {
		return (value != null)&&(value.Descendents__c != null)&&(value.Descendents__c > 0);
	}

	private static String hierarchyName(Classification__c classification) {
		String retval = null;
		if(classification != null) {
			String [] hierarchy = classification.Hierarchy__c.split(' » ',2);
			if(hierarchy.size() > 1) {
				retval = hierarchy[1];
			}
		}
		return retval;
	}
	
	private void regionFilteredPartnerStatusMapClear() {
		regionFilteredPartnerStatusMap = null;
		filteredPartnerTypeIdSet = null;
		typeFilteredPartnerStatusMap = null;
		filteredPartnerTierIdSet = null;
		partnerTierOptions = null;
		tierFilteredPartnerStatusMap = null;
		filteredPartnerSubTypeIdSet = null;
		fullyFilteredPartnerStatusMap = null;
		partnerSubTypeOptions = null;
		partnerTypeList = null;
		partnerTypeOptions = null;
	}

	transient Map<Id,PartnerStatus__c> regionFilteredPartnerStatusMap = null;
	
//	 Generate a list of PartnerStatus object filtered on 
//	 the selected region and relationship type.
	private Map<Id,PartnerStatus__c> getRegionFilteredPartnerStatusMap() {
		if(regionFilteredPartnerStatusMap == null) {
			final Set<Id> recordTypeIdSet = new Set<Id>();
			final String recordTypeName = parent.getOpportunity().RecordType.Name;
			Map<String,Set<Id>> accountRecordTypeIdByRegion = Opportunity_ManagePartners.getAccountRecordTypeIdByRegion();
			for(String regionName : accountRecordTypeIdByRegion.keySet()) {
				if(recordTypeName == regionName || recordTypeName.startsWith(regionName+' ') || recordTypeName.contains(' '+regionName+' ') || recordTypeName.endsWith(' '+regionName)) {
					recordTypeIdSet.addAll(accountRecordTypeIdByRegion.get(regionName));
					break;
				}
			}
			if(recordTypeIdSet.isEmpty() || showAllRegions) {
				showAllRegions = true;
				for(Set<Id> ids : accountRecordTypeIdByRegion.values()) {
					recordTypeIdSet.addAll(ids);
				}
			}
			Pattern pat = getPartnerTypePattern(parent.getOpportunity().FulfillmentChannel__c,opportunityPartner.RelationshipType__c);
			final Map<Id,PartnerStatus__c> retval = new Map<Id,PartnerStatus__c>();
			List<PartnerStatus__c> currentList = null;
			Map<Id,Map<String,Map<Id,PartnerStatus__c>>> m = parent.getPartnerStatusRecordTypeIdTypeHierarchyMap().clone();
			m.keySet().retainAll(recordTypeIdSet);
			for(Map<String,Map<Id,PartnerStatus__c>> m2 : m.values()) {
				for(String partnerTypeHierarchy : m2.keySet()) {
					if(pat == null || pat.matcher(partnerTypeHierarchy).matches()) {
						retval.putAll(m2.get(partnerTypeHierarchy));
					}
				}
			}
			regionFilteredPartnerStatusMap = retval;
		}
		return regionFilteredPartnerStatusMap;
	}

	transient Set<Id> filteredPartnerTypeIdSet = null;
	
//	 Use the regionFilteredPartnerStatusList to generate a set of 
//	 Partner Type Id's with associated Partner's.		
	private Set<Id> getFilteredPartnerTypeIdSet() {
		if(filteredPartnerTypeIdSet == null) {
			final Set<Id> idSet = new Set<Id>();
			Map<Id,Id> m =  parent.getPartnerTypeIdByPartnerStatusIdMap().clone();
			m.keySet().retainAll(getRegionFilteredPartnerStatusMap().keySet());
			Map<Id,Classification__c> partnerTypeMap = Opportunity_ManagePartners.getPartnerTypeMap();			
			for(Id xpartnerTypeId : new Set<Id>(m.values())) {
				addRecursive(partnerTypeMap,idSet,xpartnerTypeId);
			}
			filteredPartnerTypeIdSet = idSet;
		}
		return filteredPartnerTypeIdSet;
	}

	transient List<Classification__c>  partnerTypeList = null;
	
	private List<Classification__c>  getPartnerTypeList()
	{
		if(partnerTypeList == null) {
			final List<Classification__c> retval = new List<Classification__c>();
			for(Classification__c c : Opportunity_ManagePartners.getCompletePartnerTypeList()) {
				if(getFilteredPartnerTypeIdSet().contains(c.Id)) {
					retval.add(c);
				}
			}
			partnerTypeList = retval;
		}
		return partnerTypeList;
	}

	transient Map<Id,PartnerStatus__c> typeFilteredPartnerStatusMap = null;
	
//	 Generate a list of PartnerStatus object filtered on 
//	 the selected PartnerTypeId
	private Map<Id,PartnerStatus__c> getTypeFilteredPartnerStatusMap() {
		if(typeFilteredPartnerStatusMap == null) {
			final Set<Id> partnerTypeIdSet = getClassificationIdSet(
				getPartnerTypeList(),partnerTypeId,Opportunity_ManagePartners.rootPartnerTypeId);
			Map<Id,PartnerStatus__c> retval = new Map<Id,PartnerStatus__c>();
			Map<Id,Map<Id,PartnerStatus__c>> partnerStatusMapByIdMap=parent.getPartnerStatusMapByIdMap();
			for(Id xpartnerTypeId : partnerTypeIdSet) {
				Map<Id,PartnerStatus__c> m = partnerStatusMapByIdMap.get(xpartnerTypeId);
				if(m != null) {
					retval.putAll(m);
				}
			}
			retval.keySet().retainAll(getRegionFilteredPartnerStatusMap().keySet());
			typeFilteredPartnerStatusMap = retval;
		}
		return typeFilteredPartnerStatusMap;
	}

	transient Set<Id> filteredPartnerTierIdSet = null;
//	 Use the typeFilteredPartnerStatusList to generate a set of 
//	 Partner Tier Id's with associated Partner's.		
	private Set<Id> getFilteredPartnerTierIdSet() {
		if(filteredPartnerTierIdSet == null) {
			final Set<Id> idSet = new Set<Id>();
			Map<Id,Id> m =  parent.getPartnerTierIdByPartnerStatusIdMap().clone();
			m.keySet().retainAll(getTypeFilteredPartnerStatusMap().keySet());
			Map<Id,Classification__c> partnerTierMap = Opportunity_ManagePartners.getPartnerTierMap();
			for(Id xpartnerTierId : new Set<Id>(m.values())) {
				addRecursive(partnerTierMap,idSet,xpartnerTierId);
			}
			filteredPartnerTierIdSet = idSet;
		}
		return filteredPartnerTierIdSet;
	}

	transient Map<Id,PartnerStatus__c> tierFilteredPartnerStatusMap = null;
//	 Generate a list of PartnerStatus object in the 
//	 typeFilteredPartnerStatusLists filtered on 
//	 the selected PartnerTierId.
	private Map<Id,PartnerStatus__c> getTierFilteredPartnerStatusMap() {
		if(tierFilteredPartnerStatusMap == null) {
			List<PartnerStatus__c> currentList = null;
			final Set<Id> partnerTierIdSet = getClassificationIdSet(
				Opportunity_ManagePartners.getCompletePartnerTierList(),getPartnerTierId(),Opportunity_ManagePartners.rootPartnerTierId);
			partnerTierIdSet.retainAll(parent.getPartnerStatusMapByIdMap().keySet());
			Map<Id,PartnerStatus__c> retval = new Map<Id,PartnerStatus__c>();
			Map<Id,Map<Id,PartnerStatus__c>> partnerStatusMapByIdMap = parent.getPartnerStatusMapByIdMap();
			for(Id xpartnerTierId : partnerTierIdSet) {
				Map<Id,PartnerStatus__c> m = partnerStatusMapByIdMap.get(xpartnerTierId);
				if(m != null) {
					retval.putAll(m);
				}
			}
			retval.keySet().retainAll(getTypeFilteredPartnerStatusMap().keySet());
			tierFilteredPartnerStatusMap = retval;
		}
		return tierFilteredPartnerStatusMap;
	}

	transient Set<Id> filteredPartnerSubTypeIdSet = null;
	
//	 Use the tierFilteredPartnerStatusMap to generate a set of 
//	 Partner Sub-Type Id's with associated Partner's.		
	private Set<Id> getFilteredPartnerSubTypeIdSet()
	{
		if(filteredPartnerSubTypeIdSet == null) {
			final Set<Id> retval = new Set<Id>();
			Id xpartnerTypeId = getPartnerTypeId();
			final Classification__c partnerType = Opportunity_ManagePartners.getPartnerTypeMap().get(xpartnerTypeId);
			if(partnerType != null) {
				retval.add(xpartnerTypeId);
				if(partnerType.HierarchyDepth__c == 2 && partnerType.Descendents__c > 0) {
					final Set<Id> idSet = new Set<Id>();
					Map<Id,Id> m = parent.getPartnerTypeIdByPartnerStatusIdMap().clone();
					m.keySet().retainAll(getTierFilteredPartnerStatusMap().keySet());
					Map<Id,Classification__c> partnerTypeMap = Opportunity_ManagePartners.getPartnerTypeMap();			
					for(Id xxpartnerTypeId : new Set<Id>(m.values())) {
						addRecursive(partnerTypeMap,idSet,xxpartnerTypeId);
					}
					idSet.retainAll(getClassificationIdSet(getPartnerTypeList(),xpartnerTypeId,null));
					retval.addAll(idSet);
				}
			}
			filteredPartnerSubTypeIdSet = retval;
		}
		return filteredPartnerSubTypeIdSet;
	}

	transient Map<Id,PartnerStatus__c> fullyFilteredPartnerStatusMap = null;
	
//	 Generate a list of PartnerStatus object in the 
//	 tierFilteredPartnerStatusMap filtered on 
//	 the selected PartnerSubTypeId.
	private Map<Id,PartnerStatus__c> getFullyFilteredPartnerStatusMap()
	{
		if(fullyFilteredPartnerStatusMap == null)
		{
			List<PartnerStatus__c> currentList = null;
			final Set<Id> partnerSubTypeIdSet = getClassificationIdSet(
				getPartnerTypeList(),partnerSubTypeId,Opportunity_ManagePartners.rootPartnerTypeId);
			Map<Id,PartnerStatus__c> retval = getTierFilteredPartnerStatusMap().clone();
			Map<Id,Map<Id,PartnerStatus__c>> partnerStatusMapByIdMap = parent.getPartnerStatusMapByIdMap();
			Id xpartnerSubTypeId = getPartnerSubTypeId();
			if(xpartnerSubTypeId != getPartnerTypeId()) {
				Map<Id,PartnerStatus__c> m = partnerStatusMapByIdMap.get(xpartnerSubTypeId);
				if(m != null) {
					retval.keySet().retainAll(m.keySet());
				}
			}
			fullyFilteredPartnerStatusMap = retval;
		}
		return fullyFilteredPartnerStatusMap;
	}

//	 Accessor to the OpportunityPartner object
	public OpportunityPartner__c getOpportunityPartner()
	{
		return opportunityPartner;
	}

	public Boolean isSelected {
		get { 
			if(isSelected == null) {
				isSelected = isEdit;
			}
			return isSelected;
		}
		set;
	}

	public Boolean isEdit {
		get {
			return (isEdit == true) || isNew;
		}
		set {
			if(value != isEdit) {
				if((isEdit = value) == true) {
					showAllRegions=true;
					System.debug('Initial partnerStatusId='+partnerStatusId+',partnerTypeId='+partnerTypeId+',partnerTierId='+partnerTierId+',partnerSubTypeId='+partnerSubTypeId);
					Map<Id,Map<Id,PartnerStatus__c>> partnerStatusMapByIdMap = parent.getPartnerStatusMapByIdMap();
					Map<Id,PartnerStatus__c> partnerStatusMap = partnerStatusMapByIdMap.get(opportunityPartner.Partner__c);
					if(partnerStatusMap != null) {
						partnerStatusMap = partnerStatusMap.clone();
						Map<Id,PartnerStatus__c> partnerStatusMap2 = partnerStatusMapByIdMap.get(opportunityPartner.PartnerType__c);
						if(partnerStatusMap2 != null) {
							partnerStatusMap.keySet().retainAll(partnerStatusMap2.keySet());
						}
						partnerStatusMap2 = partnerStatusMapByIdMap.get(opportunityPartner.PartnerTier__c);
						if(partnerStatusMap2 != null) {
							partnerStatusMap.keySet().retainAll(partnerStatusMap2.keySet());
						}
						showAllRegions = partnerStatusMap.isEmpty();
					}
					if(! showAllRegions) {
						updateShowAllRegions();
						String [] splitPartnerType = opportunityPartner.PartnerType__r.Hierarchy__c.split(' » ',3);
						if(splitPartnerType.size() >= 2) {
							for(Classification__c c : getPartnerTypeList()) {
								String [] s = c.Hierarchy__c.split(' » ',3);
								if(s.size() == 2 && s[0] == splitPartnerType[0] && s[1] == splitPartnerType[1]) {
									setPartnerTypeId(c.Id);
									updatePartnerType();
									break;
								}
							}
						}
						setPartnerTierId(opportunityPartner.PartnerTier__c);
						updatePartnerTier();
						setPartnerSubTypeId(opportunityPartner.PartnerType__c);
						updatePartnerSubType();
						setPartnerTierId(opportunityPartner.PartnerTier__c);
						updatePartnerTier();
						PartnerStatus__c xpartnerStatus = partnerStatusMap.values().get(0);
						partnerStatusMap.keySet().retainAll(getFullyFilteredPartnerStatusMap().keySet());
						showAllRegions = partnerStatusMap.isEmpty();
						if(! showAllRegions) {
							xpartnerStatus = partnerStatusMap.values().get(0);
						}
						setPartnerStatus(xpartnerStatus);
						partnerTierId = null;
						updatePartnerTier();
						partnerTypeId = null;
						updatePartnerType();
					}
					if(showAllRegions) {
						updateShowAllRegions();
					}
				}
			}
		}
	}

	public Boolean isRequired {
		get {
			return (isRequired == true);
		}
		set;
	}

	public Boolean isNew {
		get {
			return (opportunityPartner.Id == null);
		}
	}

	private PartnerStatus__c partnerStatus = null;
	
//	 Partner Status as set with partnerStatusId
	public PartnerStatus__c getPartnerStatus() {
		return partnerStatus;
	}

	public void setPartnerStatus(PartnerStatus__c value ) {
		Id id = null;
		if((partnerStatus = value) != null) {
			id = value.Partner__c;
			setPartnerStatusId(value.Id);
		}
		if(opportunityPartner.Partner__c != id) {
			opportunityPartner.Partner__c = id;
		}
	}

	private Id partnerStatusId = null;
	public String getPartnerStatusId() {
		return partnerStatusId;
	}

	public void setPartnerStatusId(String value) {
		System.debug('change PartnerStatusId to = '+value+' from = '+partnerStatusId);
		if((String)partnerStatusId != value) {
			partnerStatusId = null;
			try { partnerStatusId = (Id)value; } catch(Exception e) {}
			PartnerStatus__c ps = parent.getPartnerStatusMap().get(partnerStatusId);
			if(ps == null && partnerStatusId != null) {
				List<PartnerStatus__c> psList = [select Partner__c from PartnerStatus__c where Id = :partnerStatusId limit 1];
				if(! psList.isEmpty()) {
					parent.addPartners(new Set<Id>{psList.get(0).Partner__c});
					ps = parent.getPartnerStatusMap().get(partnerStatusId);
				}
				if(ps != null) {
					updateShowAllRegions();
				}
				else {
					partnerStatusId = null;
				}
			}
			setPartnerStatus(ps);
		}
	}
	
	public Id partnerStatusId2 {
		get {
			return partnerStatusId;
		}
		set;
	}

	public String searchText { 
		get {
			if(searchText == null && partnerStatus != null) {
				searchText = partnerStatus.Partner__r.Name;
			}
			return searchText;
		}
		set {
			if(searchText != value) {
				if(value != null) {
					value = value.trim();
				}
				searchText = value;
				// if the partner exists, and it is unique (independant of selection criteria) then 
				// attempt to set the partner status id.   
				if(searchText != null && searchText != '' && (partnerStatus == null || searchText != partnerStatus.Partner__r.Name)) {
					List<PartnerStatus__c> psList = [
						select Id from PartnerStatus__c 
						where ActivationStatus__c = 'Active'
							and PartnerTier__c != null
							and PartnerType__c != null
							and Partner__c != null
							and Partner__r.Name = :searchText
						limit 2 ];
					Integer s = psList.size();
					if(s == 1) {
						setPartnerStatusId(psList.get(0).Id);
					}
					else if(s == 0) {
						setPartnerStatusId(null);
					}
				}
			}
		}
	}

	private Id partnerTierId = null;

	public Id getPartnerTierId() {
		if(! getFilteredPartnerTierIdSet().contains(partnerTierId)) {
			try {
				partnerTierId = getPartnerTierOptions().get(0).getValue();
			}
			catch(Exception e) {
				ApexPages.addMessages(e);
			}
		}
		return partnerTierId;
	}

	public void setPartnerTierId(Id value) {
		if(partnerTierId != value) {
			partnerTierId = value;
			tierFilteredPartnerStatusMap = null;
			filteredPartnerSubTypeIdSet = null;
			fullyFilteredPartnerStatusMap = null;
			partnerSubTypeOptions = null;
		}
	}

	public String getPartnerTierName() {
		return hierarchyName(opportunityPartner.PartnerTier__r);
	}

	private Id partnerTypeId = null;
	
	public Id getPartnerTypeId() {
		if(partnerTypeId == null) {
			try {
				partnerTypeId = getPartnerTypeOptions().get(0).getValue();
			}
			catch(Exception e) {
				ApexPages.addMessages(e);
			}
		}
		return partnerTypeId;
	}
	public void setPartnerTypeId(Id value) {
		if(partnerTypeId != value) {
			partnerTypeId = value;
			typeFilteredPartnerStatusMap = null;
			filteredPartnerTierIdSet = null;
			partnerTierOptions = null;
			tierFilteredPartnerStatusMap = null;
			filteredPartnerSubTypeIdSet = null;
			fullyFilteredPartnerStatusMap = null;
			partnerSubTypeOptions = null;
		}
	}

	private Id partnerSubTypeId = null;

	public Id getPartnerSubTypeId() {
		if(! getFilteredPartnerSubTypeIdSet().contains(partnerSubTypeId)) {
			fullyFilteredPartnerStatusMap = null;
			try {
				partnerSubTypeId = getPartnerSubTypeOptions().get(0).getValue();
			}
			catch(Exception e) {
				ApexPages.addMessages(e);
			}
		}
		return partnerSubTypeId;
	}

	public void setPartnerSubTypeId(Id value) {
		partnerSubTypeId = value;
	}

	public String getPartnerTypeName() {
		return getName(opportunityPartner.PartnerType__r,1);
	}

	public String getPartnerSubTypeName() {
		return getName(opportunityPartner.PartnerType__r,2);
	}

	transient List<SelectOption> partnerSubTypeOptions = null;
	
	public List<SelectOption> getPartnerSubTypeOptions() {
		if(partnerSubTypeOptions == null) {
			final List<Classification__c> classificationList = new List<Classification__c>();
			for(Classification__c p : getPartnerTypeList()) {
				if(getFilteredPartnerSubTypeIdSet().contains(p.Id))
				{
					classificationList.add(p);
				}
			}
			partnerSubTypeOptions = getOptionsList(
				classificationList,3,getPartnerTypeId());
		}
		return partnerSubTypeOptions;
	}

	public Boolean getHasPartnerSubTypes() {
		return (getPartnerSubTypeOptions().size() > 1);
	}

	transient List<SelectOption> partnerTypeOptions = null;

	public List<SelectOption> getPartnerTypeOptions() {
		if(partnerTypeOptions == null) {
			List<Classification__c> classificationList = new List<Classification__c>();
			for(Classification__c c : getPartnerTypeList()) {
				if(c.HierarchyDepth__c <= 2) {
					classificationList.add(c);
				}
			}
			partnerTypeOptions = getOptionsList(
				classificationList,2,Opportunity_ManagePartners.rootPartnerTypeId);
		}
		return partnerTypeOptions;
	}

	transient List<SelectOption> partnerTierOptions = null;
	
	public List<SelectOption> getPartnerTierOptions() {
		if(partnerTierOptions == null) {
			final List<Classification__c> partnerTierList = new List<Classification__c>();
			for(Classification__c c : Opportunity_ManagePartners.getCompletePartnerTierList()) {
				if(getFilteredPartnerTierIdSet().contains(c.Id)) {
					partnerTierList.add(c);
				}
			}
			partnerTierOptions = getOptionsList(
				partnerTierList,2,Opportunity_ManagePartners.rootPartnerTierId);
		}
		return partnerTierOptions;
	}

	public Boolean showAllRegions {
		get {
			return (showAllRegions == true);
		}
		set;
	}

	public String getLookupLink() {
		PageReference retval = Page.PartnerStatus_Lookup;
		Map<String,String> m = retval.getParameters();
		m.put('channel',parent.getOpportunity().FulfillmentChannel__c);
		m.put('transactionRole',(opportunityPartner.RelationshipType__c != null)?opportunityPartner.RelationshipType__c:'');
		m.put('partnerTierId',getPartnerTierId());
		m.put('partnerTypeId',getPartnerSubTypeId());
		m.put('partnerStatusIdField','value1');
		m.put('partnerNameField','value2');
		m.put('partnerName','value3');
		if(!showAllRegions) {
			m.put('recordTypeName',parent.getOpportunity().RecordType.Name);
		}
		return retval.getUrl();
	}

	public PageReference cancelEdit() {
		parent.cancelEdit(id);
		return null;
	}

	public PageReference updateRelationshipType() {
		regionFilteredPartnerStatusMapClear();
		setPartnerTypeId(null);
		setPartnerTierId(null);
		setPartnerSubTypeId(null);
		return updatePartnerType();
	}

	public PageReference updateShowAllRegions() {
		regionFilteredPartnerStatusMapClear();
		return updatePartnerType();
	}

	public PageReference updatePartnerType() {
		typeFilteredPartnerStatusMap = null;
		filteredPartnerTierIdSet = null;
		partnerTierOptions = null;
		tierFilteredPartnerStatusMap = null;
		filteredPartnerSubTypeIdSet = null;
		fullyFilteredPartnerStatusMap = null;
		partnerSubTypeOptions = null;
		return null;
	}

	public PageReference updatePartnerTier() {
		tierFilteredPartnerStatusMap = null;
		filteredPartnerSubTypeIdSet = null;
		fullyFilteredPartnerStatusMap = null;
		partnerSubTypeOptions = null;
		return null;
	}

	public PageReference updatePartnerSubType() {
		fullyFilteredPartnerStatusMap = null;
		return null;
	}

	public PageReference removeOpportunityPartner() {
		try
		{
			delete opportunityPartner;
			parent.setPartnerInfoList(null);
			Opportunity_ManagePartners.addConfirmationMessage();
		}
		catch (System.DmlException dmlException) {
			Opportunity_ManagePartners.addExceptionMessage(dmlException);
		}
		return null;
	}
}