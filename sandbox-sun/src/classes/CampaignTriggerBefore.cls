/**
 * This class replaces all before insert and before update campaign triggers.  The
 * processTrigger method is invoked by the Campaign_Before trigger and in turn invokes
 * all the methods of this class.  This gives us a way to control the order in
 * which the code logic is invoked, as well as allowing other class features such
 * as shared data, constant values, and regorious test coverage.
 * <p>
 * The Trigger object should never be directly referenced inside this class, as
 * that would make it impossible to substituting values inside test methods.
 * </p>
 *
 * @version 2014-07-15
 * @author Bill Riemers <briemers@redhat.com>
 * 2014-07-15 - Corrected the code for assign Tracking_Campaign_ID_URL__c to use the PageReference class.
 * 2014-06-05 - Assign c.mkt_cl_cmp_media_name__c (Tactic Name) as part of assignName
 * 2014-05-28 - Updated campaign name logic, no longer record type dependant.
 * 2014-05-28 - Prepared code to allow Campaign_Tracking_Id__c to be replaced with a formula field.
 * 2013-08-09 - Null check bug fix, and a small amount of refactoring to eliminate one query
 * 2013-05-14 - Removed the maintain hierarchy method
 * 2012-06-01 - Standardize with AbstractTrigger
 * 2012-05-31 - Update for SMR - Added call to assignLegacy.
 * JY <unknown@accenture.com>
 * 2012-08-29 - September AM Release Case # RH-00183903.
 * Scott Coleman <scoleman@redhat.com>
 * 2014-06-10 - Fix case of offer_id querystring parameter in tracking campaign url (US49842).
 * 2014-05-23 - Derive tracking url on insert as well as update (US38535). New URL format for Onpage Promo and Offers (US43864).
 * 2013-05-17 - Added assignActive()
 * 2013-05-17 - Updated rules in assignStatus()
 * 2013-02-07 - Use CampaignHierarchy class to manage data in memory to reduce query count
 * 2013-01-29 - Updates for custom hierarchy rollups
 * 2013-01-23 - Implement new naming convention for Parent Campaign, Offer, Tactic
 */
public without sharing class CampaignTriggerBefore extends AbstractTrigger {
	/** BooleanSetting__c key to enable setting inititive */
	public static final String ASSIGN_INITIATIVE_SETTING = 'Campaign_Before.assignInitiative';
	/** BooleanSetting__c key to enable setting name */
	public static final String ASSIGN_NAME_SETTING = 'Campaign_Before.assignName';
	/** BooleanSetting__c key to enable setting owner */
	public static final String ASSIGN_OWNER_SETTING = 'Campaign_Before.assignOwner';
	/** BooleanSetting__c key to enable setting owner email */
	public static final String ASSIGN_OWNER_EMAIL_SETTING = 'Campaign_Before.assignOwnerEmail';
	/** BooleanSetting__c key to enable setting status */
	public static final String ASSIGN_STATUS_SETTING = 'Campaign_Before.assignStatus';
	/** BooleanSetting__c key to enable setting urls */
	public static final String ASSIGN_URLS_SETTING = 'Campaign_Before.assignUrls';
	/** BooleanSetting__c key to enable setting legacy values */
	public static final String ASSIGN_LEGACY_SETTING = 'Campaign_Before.assignLegacy';
	/** BooleanSetting__c key to enable hierarchy data maintenance */
	public static final String MAINTAIN_HIERARCHY_DATA_SETTING = 'Campaign_Before.maintainHierarchyData';
	/** BooleanSetting__c key to enable default active flag */
	public static final String ASSIGN_ACTIVE_SETTING = 'Campaign_Before.assignActive';
	/** DeveloperName of Campaign Record Type "Campaign" */
	public static final String RECORD_TYPE_CAMPAIGN = 'Campaign';
	/** DeveloperName of Campaign Record Type "Parent Campaign" */
	public static final String RECORD_TYPE_PARENT_CAMPAIGN = 'Parent Campaign';
	/** DeveloperName of Campaign Record Type "Offer" */
	public static final String RECORD_TYPE_OFFER = 'Offer';
	/** DeveloperName of Campaign Record Type "Tactic" */
	public static final String RECORD_TYPE_TACTIC = 'Tactic';

	private final Map<Id,Campaign> oldMap;
	private final List<Campaign> newList;

	public static Id campaignRecordTypeId {
		get {
			return RecordTypeLookup.getRecordTypeId(RECORD_TYPE_CAMPAIGN,'Campaign');
		}
	}

//	public static Id parentCampaignRecordTypeId {
//		get {
//			return RecordTypeLookup.getRecordTypeId(RECORD_TYPE_PARENT_CAMPAIGN,'Campaign');
//		}
//	}

	/** Lookup the Offer record type */
	public static Id offerRecordTypeId {
		get {
			return RecordTypeLookup.getRecordTypeId(RECORD_TYPE_OFFER,'Campaign');
		}
	}

	public static Id tacticRecordTypeId {
		get {
			return RecordTypeLookup.getRecordTypeId(RECORD_TYPE_TACTIC,'Campaign');
		}
	}

	/**
	 * Typical TriggerBefore type constructor
	 *
	 * @param xoldMap normally assigned from Trigger.oldMap
	 * @param xnewList normally assigned from Trigger.newList
	 */
	public CampaignTriggerBefore(Map<Id,Campaign> xoldMap,List<Campaign> xnewList) {
		super(xoldMap,xnewList,null);
		oldMap = (Map<Id,Campaign>)oldSObjectMap;
		newList = (List<Campaign>)newSObjectList;
	}

	/**
	 * Assign mkt_cl_cmp_category__c and mkt_cl_parent_campaign_name__c values
	 */ 
	public void assignInitiative() {
		for(Campaign c : newList) {
			if(c.mkt_cl_parent_campaign_name__c != null) {
				String [] values = c.mkt_cl_parent_campaign_name__c.split('_',2);
				if(values.size() > 1) {
					c.mkt_cl_cmp_category__c = values[0].trim();
					c.mkt_cl_parent_campaign_name__c = values[1].trim();
				}
			}
		}
	}

	/**
	 * Assign the Campaign Name, Offer Name, and Offer Type
	 * @param asUpdate true if this is an update
	 */ 
	public void assignName(Boolean asUpdate) {
		if(asUpdate) {
			for(Campaign c : newList) {
				if(c.Title__c != null && c.Type != null) {
					String name = '_'+c.Type+'_'+c.Title__c+'                                                                                ';
					if(c.Id != null) {
						name = c.Id + name;
					}
					name = name.substring(0,80).trim();
					if(c.Name != name) {
						c.Name = name;
					}
					if(c.mkt_cl_cmp_cta__c != c.Type || c.Offer_Name__c != name) {
						if(c.RecordTypeId == offerRecordTypeId) {
							c.mkt_cl_cmp_cta__c = c.Type; // Offer Type
							c.Offer_Name__c = name; // Offer Name
						}
					}
					if(c.mkt_cl_cmp_media_name__c != name) {
						if(c.RecordTypeId == campaignRecordTypeId || c.RecordTypeId == tacticRecordTypeId) {
							c.mkt_cl_cmp_media_name__c = name; // Tactic Name
						}
					}
				}
			}
		}
	}

	/**
	 * Assign the Campaign Name, Offer Name, and Offer Type
	 * @param asUpdate true if this is an update
	 */ 
	public void assignName() {
		assignName(isUpdate);
	}

	/** This is a set of mkt_cl_cmp_owner__c values. */
	private Set<String> ownerEmails {
		get {
			if(ownerEmails == null) {
				ownerEmails = new Set<String>();
				for(Campaign c : newList) {
					if (c.mkt_cl_cmp_owner__c != null) {
						ownerEmails.add(c.mkt_cl_cmp_owner__c);
					}
				}
			}
			return ownerEmails;
		}
		set;
	}

	private Map<Id,User> userMap {
		get {
			if(userMap == null) {
				User currentUser = new User(Id=UserInfo.getUserId(),Email=UserInfo.getUserEmail());
				// there is no need to lookup the current user
				userMap = new Map<Id,User>{currentUser.Id=>currentUser};
				Set<Id> ownerIds = new Set<Id>();
				for(Campaign c : newList) {
					// only consider user ids, not group ids
					if(c.ownerId != currentUser.Id && (''+c.ownerId).startsWith('005')) {
						ownerIds.add(c.ownerId);
					}
				}
				Set<String> ownerEmailsFiltered = ownerEmails.clone();
				ownerEmailsFiltered.remove(currentUser.Email);
				if(! (ownerIds.isEmpty() && ownerEmailsFiltered.isEmpty()) ) {
					userMap.putAll( new Map<Id,User>( [
						SELECT Email 
						FROM User 
						WHERE (Id IN :ownerIds OR Email IN :ownerEmailsFiltered)
							AND IsActive = true ] ));
				}
			}
			return userMap;
		}
		set;
	}

	/** 
	 * This is a list of all active users with email
	 * contained in the set of mkt_cl_cmp_owner__c values.
	 */
	public List<User> users {
		get {
			if(users == null) {
				users = new List<User>();
				if(! ownerEmails.isEmpty()) {
					for(User u : userMap.values()) {
						if(u.email != null) {
							users.add(u);
						}
					}
				}
			}
			return users;
		}
		set;
	}

	private Map<String,Id> userIdMap {
		get {
			if(userIdMap == null) {
				userIdMap = new Map<String,Id>();
				for (User user : users) {
					if(user.email != null) {
						userIdMap.put(user.email, user.Id);
					}
				}
			}
			return userIdMap;
		}
		set;
	}

	/**
	 * This method assigns the ownerId based on mkt_cl_cmp_owner__c
	 * value.
	 */
	public void assignOwner() {
		for (Campaign c : newList) {			
			// assign the owner id directly if updated
			if ( isUpdate )
			{
				Campaign old = oldMap.get( c.Id );
				if ( c.ownerId != old.ownerId )
				{
					c.mkt_cl_cmp_owner__c = null;
				}
			}
			// lookup the owner id from the email address
			if (c.mkt_cl_cmp_owner__c != null) {
				Id ownerId = userIdMap.get(c.mkt_cl_cmp_owner__c);
				if (ownerId != null && ownerId != c.ownerId) {
					c.ownerId = ownerId;
				}
			}
		}
	}

	/**
	 * This method assigns the mkt_cl_cmp_owner__c based on the owner email
	 * address.
	 */
	public void assignOwnerEmail() {
		for (Campaign c : newList) {
			if (c.ownerId != null) {
				User user = userMap.get(c.ownerId);
				if (user != null && user.email != null && ! user.email.equals(c.mkt_cl_cmp_owner__c)) {
					c.mkt_cl_cmp_owner__c = user.email;
				}
			}
		}
	}

	/**
	 * This method assigns the Status field.
	 */
	public void assignStatus() {
		Date today = Date.today();
		for(Campaign c : newList) {
			String status;
			if(c.StartDate > today) {
				status = 'Planned';
			}
			else if (c.StartDate <= today && c.EndDate >= today) {
				status = 'In Progress';
			}
			else if (c.EndDate < today) {
				status = 'Completed';
			}
			if(status != null && c.Status != status) {
				c.Status = status;
			}
		}
	}

	/**
	 * This method assigns Tracking_Campaign_Id_URL__c.
	 * @param asInsert true if being called from an insert
	 */
	public void assignUrls(Boolean asInsert) {
		for(Campaign c : newList) {
			Campaign old = new Campaign(Type = null, Landing_Page_URL__c = null);
			if(! asInsert) {
				old = oldMap.get(c.Id);
			}
			if(!isInsert) {
				// This is to allow the code to work both before and after we change
				// this field to a formula field.
				// To Do: Delete this code
				try {
					c.put('Campaign_Tracking_Id__c',''+c.Id);
				}
				catch(Exception ex) {}
			}
			// added as part of September AM Release Case # RH-00183903 on 2012-08-29 by JY (AM team) - Begin
			Boolean internalPromo = (c.Type == 'Homepage Promo' || c.Type == 'Onpage Widget' || c.Type == 'Onpage Promo');
			Boolean internalPromoOld = (old.Type == 'Homepage Promo' || old.Type == 'Onpage Widget' || old.Type == 'Onpage Promo');
			// added as part of September AM Release Case # RH-00183903 on 2012-08-29 by JY (AM team) - End

			String qstrpara = 'sc_cid';
			if( internalPromo ) {
				qstrpara = 'intcmp';
			}

			String landingPageURL = c.Landing_Page_URL__c;
			if(c.RecordTypeId == offerRecordTypeId) {
				landingPageURL = 'http://www.redhat.com/forms/';
				qstrpara = 'offer_id';
			}

			PageReference trackingCampaignIdRef = null;
			if((landingPageURL == null)||('http://'.equalsIgnoreCase(landingPageURL))||(landingPageURL.length() <= 'http://'.length()) ) {
				c.Tracking_Campaign_ID_URL__c = ''; 
			}
			else if(!asInsert || ! landingPageURL.equalsIgnoreCase(old.Landing_Page_URL__c)) {
				trackingCampaignIdRef = new PageReference( landingPageUrl);
			}
			else if(internalPromo != internalPromoOld && c.Tracking_Campaign_ID_URL__c != null && qstrpara != 'offer_id') {
				trackingCampaignIdRef = new PageReference(c.Tracking_Campaign_ID_URL__c);
			}
			if(trackingCampaignIdRef != null) {
				trackingCampaignIdRef.getParameters().remove('intcmp');
				trackingCampaignIdRef.getParameters().remove('sc_cid');
				trackingCampaignIdRef.getParameters().put(qstrpara,c.Id);
				c.Tracking_Campaign_ID_URL__c = trackingCampaignIdRef.getUrl();
			}
		}
	}

	
	/**
	 * This method assigns Tracking_Campaign_Id_URL__c.
	 */
	public void assignUrls() {
		assignUrls(isInsert);
	}

	/**
	 * This method assigns a defualt of TRUE to the IsActive field.
	 */
	public void assignActive() {
		if(isInsert) {
			for(Campaign c : newList) {
				c.IsActive = true;
			}
		}
	}

	/**
	 * This method is called to invoke all the trigger methods.
	 *
	 * @param xoldMap normally assigned from Trigger.oldMap
	 * @param xnewMap normally assigned from Trigger.newMap
	 */
	public static void processTrigger(Map<Id,Campaign> xoldMap,List<Campaign> xnewList) {
		final CampaignTriggerBefore beforeTrigger = new CampaignTriggerBefore(xoldMap,xnewList);
		if(AbstractTrigger.isActive(ASSIGN_INITIATIVE_SETTING,true)) {
			beforeTrigger.assignInitiative();
		}
		if(AbstractTrigger.isActive(ASSIGN_URLS_SETTING,true)) {
			beforeTrigger.assignUrls();
		}
		if(AbstractTrigger.isActive(ASSIGN_NAME_SETTING,true)) {
			beforeTrigger.assignName();
		}
		if(AbstractTrigger.isActive(ASSIGN_OWNER_SETTING,true)) {
			beforeTrigger.assignOwner();
		}
		if(AbstractTrigger.isActive(ASSIGN_OWNER_EMAIL_SETTING,true)) {
			beforeTrigger.assignOwnerEmail();
		}
		if(AbstractTrigger.isActive(ASSIGN_STATUS_SETTING,true)) {
			beforeTrigger.assignStatus();
		}
		if(AbstractTrigger.isActive(ASSIGN_LEGACY_SETTING,true)) {
			beforeTrigger.assignLegacy();
		}
//		if(AbstractTrigger.isActive(MAINTAIN_HIERARCHY_DATA_SETTING,true)) {
//			beforeTrigger.maintainHierarchyData();
//		}
		if(AbstractTrigger.isActive(ASSIGN_ACTIVE_SETTING,true)) {
			beforeTrigger.assignActive();
		}
		AbstractTrigger.processTriggerComplete();
	}
}