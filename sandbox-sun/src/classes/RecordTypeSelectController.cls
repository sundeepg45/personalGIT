/**
 * This class implements a controller used for RecordType selection 
 * based on the RecordTypeAssigment__c table.  All the required parameters
 * can be read in from the current URL if the parameters passed are the same
 * as those passed to recordtypeselect.jsp.  Otherwise, the parameters may
 * be manually set.  The only required value for this to work is the
 * objectApiName.  The rest of the values have defaults that generated 
 * from that information.
 *
 * @version 2014-05-02
 * 
 * @author Bill C Riemers <briemers@redhat.com>
 * 2013-05-02 - Corrected bug when cloning and added code to assign default values on create
 * 2013-07-23 - Updated to be able map values from different fields when cloning
 * 2013-06-17 - Added POC redirect
 * 2013-05-01 - Added code to use the FieldId__c settings to auto populate field values when cloning
 * 2012-08-22 - Updated to save record typa assignment map statically, so fewer queries are used when invoked from a trigger
 * 2012-06-27 - Refactored to allow record type name lists to be called from triggers
 * 2012-05-29 - Created
 * Scott Coleman <scoleman@redhat.com>
 * 2012-10-25 - Slight change to getRecordTypeAssignmentMap to resolve locale issue (US26587)
 */
public without sharing class RecordTypeSelectController {
	static String recordTypeAssignmentMapSuperRegion = null;
	static String recordTypeAssignmentMapProfileName = null;
	static Map<String,List<RecordTypeAssignment__c>> recordTypeAssignmentMap = null;

	transient private Schema.DescribeSObjectResult sobjectDescribe = null;

	/**
	 * The entity id we are using.  This may either be set here
	 * or parsed from the ent parameter of the currentPage url.
	 * Set a value of null or "default" to force parsing of the 
	 * currentPage url.
	 */
	public String entityKey {
		get {
			if(entityKey == null || entityKey == '' || entityKey == 'default') {
				entityKey = ApexPages.currentPage().getParameters().get('ent');
				if(entityKey == null || entityKey == '' || entityKey == 'default') {
					entityKey = objectApiName;
				}
			}
			return entityKey;
		}
		set;
	}

	/**
	 * The object name we are using.  This may either be set here
	 * or parsed from the recordId or parsed from the ent parameter 
	 * of the currentPage url.  Set a value of null or "default" to 
	 * force parsing of the recordId and currentPage url.
	 */
	public String objectApiName {
		get {
			if(objectApiName == null || objectApiName == '' || objectApiName == 'default') {
				// this only works correctly for standard objects
				objectApiName = ApexPages.currentPage().getParameters().get('ent');
				if(sobjectDescribe == null) {
					// See if we can find a describe result base on record id
					String key = recordId;
					if(key != null && key.length() >= 3) {
						String prefix = key.substring(0,3);
						for(Schema.SObjectType objectType : Schema.getGlobalDescribe().values()) {
							Schema.DescribeSObjectResult d = objectType.getDescribe();
							if(d != null && prefix.equals(d.getKeyPrefix())) {
								sobjectDescribe = d;
								break;
							}
 						}
					}
				}
				// this works for all objects, if we have a describe result value
				if (sobjectDescribe != null) {
					objectApiName = sobjectDescribe.getName();
				}
			}
			return objectApiName;
		}
		set;
	}

	/**
	 * The object id passed to this controller if there is one...
	 */
	public String recordId {
		get {
			if(recordId == null) {
				recordId = ApexPages.currentPage().getParameters().get('id');
			}
			if(recordId != null && recordId.length() == 18) {
				recordId = recordId.substring(0,15);
			}
			return recordId;
		}
		set;
	}

	public Boolean isClone {
		get {
			if(isClone == null) {
				isClone = (ApexPages.currentPage().getParameters().get('clone') == '1');
			}
			return isClone;
		}
		set;
	}
	
	public Boolean isCloneWithoutRecordType {
		get {
			if(isCloneWithoutRecordType == null) {
				isCloneWithoutRecordType = (ApexPages.currentPage().getParameters().get('clonewort') == '1');
			}
			return isCloneWithoutRecordType;
		}
		set;
	}

	/**
	 * The keyPrefix we are using.  Normally, this is looked up from the
	 * Schema describe, but it can set explicitly.
	 */
	public String keyPrefix {
		get {
			if(keyPrefix == null || keyPrefix.length() < 3) {
				keyPrefix = getDescribe().getKeyPrefix();
			}
			return keyPrefix;
		}
		set;
	}

	/**
	 * The label for the object we are using.  Normally, this is looked up from the
	 * Schema describe, but it can set explicitly.
	 */
	public String objectLabel {
		get {
			if(objectLabel == null || objectLabel == '') {
				objectLabel = getDescribe().getLabel();
			}
			return objectLabel;
		}
		set;
	}

	// queries the recordId 
	SObject record {
		get {
			if(record == null && recordId != null && recordId != '') {
				Set<String> fieldsNames = new Set<String>{'name','recordtype.name'};
				for(FieldId__c fieldId : FieldId__c.getAll().values()) {
					if(fieldId.SFACloneable__c == false && fieldId.Object__c == objectApiName && fieldId.SFACloneField__c != null) {
						fieldsNames.add(fieldId.SFACloneField__c.toLowerCase());
					}
				}
				String query = 'select ';
				String sep='';
				for(String f : fieldsNames) {
					query += sep + f;
					sep = ', ';
				}
				for(SObject o : Database.query(
					query + ' from '+objectApiName + ' where Id = :recordId') )
				{
					record = o;
				}
			}
			return record;
		}
		set;
	}

	/**
	 * The current name for the object we are updating.
	 */
	public String recordName {
		get {
			if(recordName == null && record != null) {
				recordName = ''+record.get('Name');
			}
			return recordName;
		}
		set;
	}

	/**
	 * The url to return to.  This may either be set here
	 * or parsed from retURL parameter of the currentPage url.
	 * Set a value of null or "default" to force parsing of
	 * the currentPage url.
	 */
	public String returnURL {
		get {
			if(returnURL == null || returnURL == '' || returnURL == 'default') {
				returnURL = ApexPages.currentPage().getParameters().get('retURL');
				if(returnURL == null) {
					returnURL='/'+keyPrefix+'/o';
				}
			}
			return returnURL;
		}
		set;
	}

	/**
	 * A utility function to replace null or nill values with a default value.
	 * 
	 * @param value to check
	 * @param defaultValue to replace null's with
	 * @return value or defaultValue if value is null
	 */
	static String replaceNullOrNill(String value,String defaultValue) {
		if(value == null || value == '') {
			value = defaultValue;
		}
		return value;
	}


	/**
	 * Method used to append fields to the url string.
	 *
	 * @param value current url
	 * @return modified url
	 */
	public String appendParams(String value) {
		if (currentUser.IsPortalEnabled != true) {
			String sep = '?';
			if(value.indexOf(sep) >= 0) {
				sep='&';
			}
			Map<String,String> params = ApexPages.currentPage().getParameters();
			String oName = objectApiName; 
			if(isClone || isCloneWithoutRecordType) {
				for(FieldId__c fieldId : FieldId__c.getAll().values()) {
					if(fieldId.SFACloneable__c == false && fieldId.Object__c == oName) {
						String paramName = fieldId.Name;
						if(! params.containsKey(paramName)) {
							String fieldValue = replaceNullOrNill(fieldId.SFACloneValue__c,'');
							if(fieldId.SFACloneField__c != null) {
								Object v = record.get(fieldId.SFACloneField__c);
								if(v != null) {
									fieldValue = String.valueOf(v);
								}
							}
							value += sep + paramName + '=' + EncodingUtil.urlEncode(fieldValue,'UTF-8');
							sep = '&';
						}
					}
				}
			}
			else {
				for(FieldId__c fieldId : FieldId__c.getAll().values()) {
					String fieldValue = replaceNullOrNill(fieldId.SFANewValue__c,'');
					if(fieldValue != '' && fieldId.Object__c == oName) {
						String paramName = fieldId.Name;
						if(! params.containsKey(paramName)) {
							value += sep + paramName + '=' + EncodingUtil.urlEncode(fieldValue,'UTF-8');
							sep = '&';
						}
					}
				}
			}
		}
		return value;
	}

	String passParameters(String value) {
		String sep = '?';
		if(value.indexOf(sep) >= 0) {
			sep='&';
		}
		PageReference ref = new PageReference(value);
		Map<String,String> params = ApexPages.currentPage().getParameters();
		if(params != null) {
			for(String param : params.keySet()) {
				if(param != 'save_new' && param != 'save_new_url' && param != 'ent' && param != 'id' && param != 'Name' && param != 'sobjectDescribe') {
					if(param.indexOf('%') < 0 && param.indexOf(':') < 0 && param.indexOf(';') < 0 && param.toLowerCase().indexOf('override') < 0 && param.indexOf('.') < 0) {
						if(! ref.getParameters().containsKey(param)) {
							value += sep + param+'='+EncodingUtil.urlEncode(params.get(param),'UTF-8');
							sep = '&';
						}
					}
				}
			}
		}
		return appendParams(value);
	}


	// This is a method to apply a default saveURL value and 
	// populalate retURL when it is not present.
	String modifysaveURL(String value) {
		if(value == null || value == '' || value == 'default') {
 			value = '/'+replaceNullOrNill(recordId,keyPrefix)+'/e';
		}
		PageReference saveRef = new PageReference(value);
		String sep = '?';
		if(value.indexOf(sep) >= 0) {
			sep='&';
		}
//		if((recordId == null || recordId == '') && ! saveRef.getParameters().containsKey('nooverride')) {
//			value+=sep+'nooverride=1';
//			sep='&';
//		}
		if(! saveRef.getParameters().containsKey('retURL')) {
			value+=sep+'retURL='+EncodingUtil.urlEncode(returnURL,'UTF-8');
		}
		return passParameters(value);
	}

	/**
	 * The url to navigate to for the new object edit/create.  This may either 
	 * be set here or parsed from the save_new_url parameter of the currentPage url.
	 * Set a value of null or "default" to force parsing of the currentPage url.
	 * A "RecordType" parameter will automatically be added when used.  If a retURL 
	 * parameter is not set, that will be added as well.
	 */
	public String saveURL {
		get {
			if(currentUser.IsPortalEnabled != true && recordTypeId != null && recordTypeId != '' && pocRecordTypeId == recordTypeId) {
				saveURL = modifysaveURL(Page.Opportunity_ProofOfConcept_Edit.getUrl());
			}
			if(saveURL == null ||saveURL == '' || saveURL == 'default') {
				saveURL = modifysaveURL(ApexPages.currentPage().getParameters().get('save_new_url'));
			}
			return saveURL;
		}
		set {
			saveURL = modifysaveURL(value);
		}
	}

	// Populate the the describe object to a transient value and return it.
	Schema.DescribeSObjectResult getDescribe() {
		if(sobjectDescribe == null && objectApiName != null) {
			sobjectDescribe = Schema.getGlobalDescribe().get(objectApiName).getDescribe();
		}
		return sobjectDescribe;
	}

	/**
	 * The current recordType.Name value.
	 */
	public RecordType currentRecordType {
		get {
			if(currentRecordType == null && record != null) {
				currentRecordType = (RecordType)record.getSObject('RecordType');
			}
			return currentRecordType;
		}
		set;
	}

	/**
	 * The recordTypeId we are assigning.
	 */
	public String recordTypeId {
		get {
			if(recordTypeId == null) {
				if(currentRecordType != null) {
					recordTypeId = currentRecordType.Id;
				}
				String s = ApexPages.currentPage().getParameters().get('RecordType');
				if(s != null && s != '') {
					recordTypeId = (Id)s;
				}
				if(recordTypeId == null) {
					recordTypeId = '';
				}
			}
			return recordTypeId;
		}
		set;
	}

	/** Lookup the POC record id. */
	// to do: Once this is the same on all environments this can be changed to constant value
	public static Id pocRecordTypeId {
		get {
			return RecordTypeLookup.getRecordTypeId('Proof of Concept','Opportunity');
		}
	}

	/**
	 * Static reference to the current user and the values we
	 * need to select the available record types.  This value 
	 * may be assigned, so there is no need to do a RunAs in
	 * the test class.
	 *
	 * @return the current User
	 */
	public static User currentUser {
		get {
			if(currentUser == null) {
				currentUser = [
					select
						IsPortalEnabled,
						Job_Function__c,
						Region__c,
						Profile.Name,
						UserRole.Name
					from User
					where Id = :UserInfo.getUserId() ];
			}
			return currentUser;
		}
		set;
	}

	/**
	 * This value is true if and only if there is at least one record type mapping
	 * by the RecordTypeAssigment__c object for this profile for the
	 * specified object.
	 */
	public Boolean isManagedProfile {
		get {
			if(isManagedProfile == null) {
				System.debug('objectApiName='+objectApiName);
				System.debug('currentUser.Profile.Name="'+currentUser.Profile.Name+'"');
				isManagedProfile = [
					select count()
					from RecordTypeAssignment__c
					where Object_Label__c = :objectApiName
						and ManagedProfiles__c includes (:currentUser.Profile.Name)
					limit 1 ] != 0;
			}
			return isManagedProfile;
		}
		set;
	}


	/**
	 * Lookup the record type assignment records.
	 * 
	 * @param objectApiNames a set of object to lookup
	 * @param superRegion the super region to lookup
	 * @param profileName the profile name to lookup
	 * @return a map of record typa assignment records by objectApiName
	 */
	public static Map<String,List<RecordTypeAssignment__c>> getRecordTypeAssignmentMap(
		final Set<String> objectApiNames,
		String superRegion,
		String profileName)
	{
		if(recordTypeAssignmentMap == null || profileName != recordTypeAssignmentMapProfileName || superRegion != recordTypeAssignmentMapSuperRegion) {
			recordTypeAssignmentMap = new Map<String,List<RecordTypeAssignment__c>>();
			recordTypeAssignmentMapProfileName = profileName;
			recordTypeAssignmentMapSuperRegion = superRegion;
		}
		final Set<String> neededObjectApiNames = new Set<String>();
		for(String objectApiName : objectApiNames) {
			if(! recordTypeAssignmentMap.containsKey(objectApiName.toUpperCase())) {
				recordTypeAssignmentMap.put(objectApiName.toUpperCase(),new List<RecordTypeAssignment__c>());
				neededObjectApiNames.add(objectApiName);
			}
		}
		if(! neededObjectApiNames.isEmpty()) {
			List<String> superRegions = new List<String>{superRegion,superRegion,superRegion,superRegion,superRegion};
			if(superRegion == null || 'GLOBAL' == superRegion) {
				superRegions = new List<String>{'GLOBAL','APAC','EMEA','LATAM','NA'};
			}
			for(RecordTypeAssignment__c rta : [
				select
					Job_Functions__c,
					ManagedProfiles__c,
					Object_Label__c,
					RecordType__c,
					Role_Contains_All__c,
					Role_Contains_Any__c,
					Role_Excludes_All__c,
					Role_Excludes_Any__c,
					Super_Region__c
				from RecordTypeAssignment__c
				where Object_Label__c in :neededObjectApiNames
					and ManagedProfiles__c includes (:profileName)
					and Super_Region__c includes (:superRegions[0],:superRegions[1],:superRegions[2],:superRegions[3],:superRegions[4]) ] )
			{
				recordTypeAssignmentMap.get(rta.Object_Label__c.toUpperCase()).add(rta);
			}
		}
		return recordTypeAssignmentMap;
	}

	/**
	 * Returns a list of all record types names or developer name for the current user 
	 * to select from.
	 *
	 * @param xuser the user to check with Region__c, UserRole.Name, Profile.Name, Job_Function__c, and UserRole.Name populated
	 * @param recordTypeAssignments the list of record type assignments to consider
	 * @return list of available RecordTypes
	 */
	public static Set<String> getRecordTypeNames(User xuser,List<RecordTypeAssignment__c> recordTypeAssignments) {
		// find the available RecordType names
		Set<String> recordTypeNames = new Set<String>();
		// Split the current role into keys
		Set<String> roleKeys = new Set<String>();
		String roleName = '';
		if(xuser.UserRole != null && xuser.UserRole.Name != null) {
			roleName = xuser.UserRole.Name;
		}
		for(String roleKey : roleName.split(' *[|] *',0)) {
			roleKeys.add(roleKey.toLowerCase().trim());
		}
		roleKeys.remove('');
		System.debug('xuser.Profile.Name="'+xuser.Profile.Name);
		System.debug('superRegions='+xuser.Region__c);
		for(RecordTypeAssignment__c rta : recordTypeAssignments) {
			final Boolean hasSuperRegion = (xuser.Region__c == 'GLOBAL')
				|| (rta.Super_Region__c == null)
				|| ((';'+rta.Super_Region__c+';').toUpperCase().indexOf((';'+xuser.Region__c+';').toUpperCase()) >= 0);
			if(hasSuperRegion) {
				final Boolean hasProfileName = (rta.ManagedProfiles__c == null)
					|| ((';'+rta.ManagedProfiles__c+';').toUpperCase().indexOf((';'+xuser.Profile.Name+';').toUpperCase()) >= 0);
				if(hasProfileName) {
					// The following criteria is optional.  We could try and
					// and code this into the query, but salesforce is not very
					// efficient with complex queries and we would lose readability.
					
					// If value is null, we automatically pass.
					final Boolean jobFunctionPass = (rta.Job_Functions__c == null)
						|| ((';'+rta.Job_Functions__c+';').toUpperCase().indexOf((';'+xuser.Job_Function__c+';').toUpperCase()) >= 0);
					if(jobFunctionPass) {
						// Default as passing the containsAll filter, until we find a missing value
						Boolean containsAllPass = true;
						if(rta.Role_Contains_All__c != null) {
							for(String roleKey : rta.Role_Contains_All__c.split(';',0)) {
								if(! roleKeys.contains(roleKey.toLowerCase().trim())) {
									// the value is missing, so we fail
									containsAllPass = false;
									break;
								}
							}
						}
						if(containsAllPass) {
							// we automatically pass if the filter is null
							Boolean containsAnyPass = (rta.Role_Contains_Any__c == null);
							if(! containsAnyPass) {
								for(String roleKey : rta.Role_Contains_Any__c.split(';',0)) {
									if(roleKeys.contains(roleKey.toLowerCase().trim())) {
										// this key is present, so we pass
										containsAnyPass = true;
										break;
									}
								}
							}
							if(containsAnyPass) {
								// assume we pass unless we find an excluded key
								Boolean excludesAnyPass = true;
								if(rta.Role_Excludes_Any__c != null) {
									for(String roleKey : rta.Role_Excludes_Any__c.split(';',0)) {
										if(roleKeys.contains(roleKey.toLowerCase().trim())) {
											// this key is excluded, so we fail
											excludesAnyPass = false;
											break;
										}
									}
								}
								if(excludesAnyPass) {
									// we pass if there are no excluded keys
									Boolean excludesAllPass = (rta.Role_Excludes_All__c == null);
									if(! excludesAllPass) {
										for(String roleKey : rta.Role_Excludes_All__c.split(';',0)) {
											if(! roleKeys.contains(roleKey.toLowerCase().trim())) {
												// this key is missing so we pass
												excludesAllPass = true;
												break; 
											}
										}
									}
									if(excludesAllPass) {
										recordTypeNames.addAll(rta.RecordType__c.split(';'));
									}
								}
							}
						}
					}
				}
			}
		}
		return recordTypeNames;
	}

	/**
	 * Find all record types names or developer name for the users 
	 * to select from.
	 *
	 * @param xuser the user to check with Region__c, UserRole.Name, Profile.Name, Job_Function__c, and UserRole.Name populated
	 * @param objectApiNames the list of objects to check
	 * @return a map of record type names by api object name
	 */
	public static Map<String,Set<String>> getRecordTypeNameMap(User xuser,Set<String> objectApiNames) {
		final Map<Id,Map<String,Set<String>>> retval = new Map<Id,Map<String,Set<String>>>();
		final Map<String,Set<String>> recordTypeNameMap = new Map<String,Set<String>>();
		for(String objectApiName : objectApiNames) {
			recordTypeNameMap.put(objectApiName.toUpperCase(),new Set<String>());
		}
		final Map<String,List<RecordTypeAssignment__c>> rtaMap = getRecordTypeAssignmentMap(
			objectApiNames,
			xuser.Region__c,
			xuser.Profile.Name);
		for(String objectApiName : objectApiNames) {
			recordTypeNameMap.get(objectApiName.toUpperCase()).addAll(
				getRecordTypeNames(xuser,rtaMap.get(objectApiName.toUpperCase())));
		}
		return recordTypeNameMap;
	}

	/**
	 * Returns a list of all record types available for the current user 
	 * to select from.
	 *
	 * @return list of available RecordTypes
	 */
	public List<RecordType> recordTypes {
		get {
			if(recordTypes == null) {
				// find the available RecordType names
				Set<String> recordTypeNames = getRecordTypeNameMap(
					currentUser, new Set<String>{objectApiName}).get(objectApiName.toUpperCase());
				// Query the matching list of RecordTypes
				System.debug('recordTypeNames='+recordTypeNames);
				System.debug('recordTypeId='+recordTypeId);
				String rtId = recordTypeId;
				if(isClone) {
					rtId = null;
				}
				recordTypes = [
					select
						Description,
						Name
					from RecordType
					where SObjectType = :objectApiName
						and IsActive = true
						and (Name in :recordTypeNames
							or DeveloperName in :recordTypeNames
							or Id = :rtId)
					order by Name ];
				if( recordTypeId != null 
					&& recordTypeId != ''
					&& !(new Map<Id,RecordType>(recordTypes).containsKey(recordTypeId)) )
				{
					recordTypeId = '';
				}
			}
			return recordTypes;
		}
		set;
	}

	/**
	 * Generate a list of SelectOption for the available record types.
	 *
	 * @return list of record type options
	 */
	public List<SelectOption> getRecordTypeOptions() {
		List<SelectOption> selectOptions = new List<SelectOption>();
		if(recordId == null || recordId == '') {
			selectOptions.add(new SelectOption('', '--None--'));
			selectOptions[0].setDisabled(true);
		}
		for(RecordType rt : recordTypes) {
			selectOptions.add(new SelectOption(''+rt.Id,rt.Name));
		}
		return selectOptions;
	}

	/**
	 * The URL we should redirect to for unmanaged profiles.
	 *
	 * @return the url to redirect to
	 */
	public String redirectURL {
		get {
			if(redirectURL == null || redirectURL == '' || redirectURL == 'default') {
				redirectURL = null;
				Integer recordTypeSize = recordTypes.size();
				if(recordId == null || recordId == '') {
					if(recordTypeSize == 0) {
						if(isManagedProfile) {
							ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,'Permissioned Denied!  You are not authorized to create this type of object.'));
						}
						else {
							redirectURL = passParameters(
								'/setup/ui/recordtypeselect.jsp?nooverride=1&ent='+entityKey
								+ '&retURL='+EncodingUtil.urlEncode(returnURL,'UTF-8')
								+ '&save_new_url='+EncodingUtil.urlEncode(saveURL,'UTF-8'));
						}
					}
					else if(recordTypeSize == 1) {
						redirectURL = saveURL;
						PageReference redirectRef = new PageReference(redirectURL);
						String sep = '?';
						if(redirectURL.indexOf(sep) >= 0) {
							sep='&';
						}
						if((recordId == null || recordId == '') && ! redirectRef.getParameters().containsKey('nooverride')) {
							redirectURL += sep+'nooverride=1';
							sep='&';
						}
						if(currentRecordType == null || currentRecordType.Id != recordTypes[0].Id) {
							redirectURL += sep+'RecordType='+recordTypes[0].Id;
							sep='&';
						}
						redirectURL = appendParams(redirectURL);
					}
				}
				else if(isClone && !isCloneWithoutRecordType) {
					Id rtId = null;
					if(recordTypes.size() == 1) {
						rtId = recordTypes[0].Id;
					}
					if(rtId != null || (recordTypeId != null && recordTypeId != '')||! isManagedProfile) {
//						redirectURL = passParameters('/'+recordId+'/e?nooverride=1'
//							+ '&retURL='+EncodingUtil.urlEncode(returnURL,'UTF-8'));
						redirectURL = saveURL+'&nooverride=1';
						if(rtId != null) {
							redirectURL += '&RecordType='+rtId;
						}
					}
				}
				else if(! isManagedProfile) {
					redirectURL = passParameters(
						'/setup/ui/recordtypeselect.jsp?id='+recordId
						+ '&retURL='+EncodingUtil.urlEncode(returnURL,'UTF-8'));
				}
			}
			return redirectURL;
		}
		set;
	}

	/**
	 * Returns a page reference to the redirectURL if this is an
	 * unmamanaged profile.
	 *
	 * @return page reference to redirectURL
	 */
	public PageReference redirect() {
		PageReference retval = null;
		if(!isManagedProfile) {
			retval = new PageReference(redirectURL);
			retval.setRedirect(true);
		}
		return retval;
	}

	/**
	 * Called to generate pass the selected RecordType to 
	 * the save_new_url, by adding the RecordType parameter
	 * to the url and returning the page reference.
	 *
	 * @return page reference to the modified save_new_url.
	 */
	public PageReference selectRecordType() {
		PageReference retval = new PageReference(saveURL);
		if(currentRecordType == null || currentRecordType.Id != recordTypeId) {
			retval.getParameters().put('RecordType',recordTypeId);
		}
		if(! retval.getParameters().containsKey('retURL')) {
			retval.getParameters().put('retURL',returnURL);
		}
		if((isClone || recordId == null || recordId == '') && ! retval.getParameters().containsKey('nooverride')) {
			retval.getParameters().put('nooverride','1');
		}
		if((recordId == null || recordId == '') && ! retval.getParameters().containsKey('ent')) {
			retval.getParameters().put('ent',objectApiName);
		}
		retval.setRedirect(true);
		return retval;
	}

	/**
	 * Called to cancel.
	 *
	 * @return page reference to the returnURL
	 */
	public PageReference cancel() {
		PageReference retval = new PageReference(returnURL);
		retval.setRedirect(true);
		return retval;
	}
}