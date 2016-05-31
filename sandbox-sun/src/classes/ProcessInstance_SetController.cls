/**
 * This is a controller class for seeing the approval processes a user
 * is involved with.
 * 
 * @author Bill C. Riemers <briemers@redhat.com>
 * @version 2012-08-28
 * 2012-08-28 - Created
 */
public without sharing virtual class ProcessInstance_SetController {
	/** Approval steps string constant. */
	public static final String APPROVAL_STEPS = 'Approval Steps';
	/** Summary string constant. */
	public static final String SUMMARY = 'Summary';
	/** Workitems string constant. */
	public static final String WORKITEMS = 'Workitems';
	/** Set of status values that indicate the approval is complete. */
	public static final Set<String> EXCLUDE_STATUS_SET = new Set<String>{'Approved','Rejected','Removed'};
	/** Set of status values that indicate the approval step is complete. */
	public static final Set<String> EXCLUDE_STEPSTATUS_SET = new Set<String>{'Approved','Rejected','Reassigned','NoResponse','Removed'};
	/** User for paging the the ProcessInstanceStep records. */
	public Paginator processInstanceStepPaginator = new Paginator();
	/** User for paging the the ProcessInstanceWorkitem records. */
	public Paginator processInstanceWorkitemPaginator = new Paginator();
	/** User for paging the the ProcessInstanceRecord records. */
	public Paginator processInstancePaginator = new Paginator();
	/** The complete list of ProcessInstanceWorkitems for the given set of options */
	protected transient List<ProcessInstanceWorkitem> processInstanceWorkitems = null;
	/** The complete list of ProcessInstanceSteps for the given set of options */
	protected transient List<ProcessInstanceStep> processInstanceSteps = null;
	/** The complete summary list of ProcessInstanceRecords for the given set of options */
	protected transient List<ProcessInstanceRecord> processInstances = null;

	/** 
	 * Constructor.  The activeUser Id is read from the Id cgi-bin argument
	 */
	public ProcessInstance_SetController() {
		Id userId = ApexPages.currentPage().getParameters().get('Id');
		if(userId == null) {
			userId = UserInfo.getUserId();
		}
		activeUser = [select Name from User where Id = :userId ];
	}

	/**
	 * Static map of object Id prefixes to object label.
	 */
	public static Map<String,String> keyPrefixMap {
		get {
			if(keyPrefixMap == null) {
				keyPrefixMap = new Map<String,String>();
				for(Schema.SObjectType sot : Schema.getGlobalDescribe().values()) {
					Schema.DescribeSObjectResult dsor = sot.getDescribe();
					keyPrefixMap.put(dsor.getKeyPrefix(),dsor.getLabel());
				}
			}
			return keyPrefixMap;
		}
	}

	/**
	 * The user we are reporting process instances for.
	 */
	public User activeUser {
		get;
		private set;
	}

	/**
	 * Set to true if we should look for process instances owned by groups the
	 * user is a memember of.
	 */
	public Boolean includeGroups {
		get {
			return (includeGroups != false);
		}
		set {
			if(includeGroups != value) {
				includeGroups = value;
				actorMap = null;
			}
		}
	}

	/**
	 * Set to true if we look for child groups recursively.
	 */
	public Boolean includeChildGroups {
		get {
			return (includeChildGroups == true);
		}
		set {
			if(includeChildGroups != value) {
				includeChildGroups = value;
				actorMap = null;
			}
		}
	}

	/**
	 * Set to true if we should exclude any process instance in a 
	 * completed state.
	 */
	public Boolean excludeComplete {
		get {
			return (excludeComplete == true);
		}
		set {
			if(excludeComplete != value) {
				excludeComplete = value;
				excludeStatuses = null;
				excludeStepStatuses = null;
				processInstanceWorkitems = null;
				processInstanceSteps = null;
			}
		}
	}

	/**
	 * The set of status values that will be excluded from the query.
	 */
	private Set<String> excludeStatuses {
		get {
			if(excludeStatuses == null) {
				excludeStatuses = EXCLUDE_STEPSTATUS_SET;
				if(! excludeComplete) {
					excludeStatuses = new Set<String>();
				}
			}
			return excludeStatuses;
		}
		private set;
	}

	/**
	 * The set of step status values that will be excluded from the query.
	 */
	private Set<String> excludeStepStatuses {
		get {
			if(excludeStepStatuses == null) {
				excludeStepStatuses = EXCLUDE_STEPSTATUS_SET;
				if(! excludeComplete) {
					excludeStepStatuses = new Set<String>();
				}
			}
			return excludeStepStatuses;
		}
		private set;
	}

	/**
	 * A map of all actor Id values to find to the actual user/group name.
	 */
	public Map<Id,String> actorMap {
		get {
			if(actorMap == null) {
				actorMap = new Map<Id,String>{activeUser.Id=>activeUser.Name};
				if(includeGroups) {
					// I'm not really sure if we need to do recursion here, as possibly we only need direct memberships
					for(Integer i=0, j=actorMap.size();i != j;j=actorMap.size()) {
						i=j;
						for(Group g : [
							select Name 
							from Group 
							where Id in (
								select GroupId 
								from GroupMember 
								where UserOrGroupId in :actorMap.keySet() 
									and GroupId not in :actorMap.keySet() 
									and Group.Type = 'Queue')])
						{
							actorMap.put(g.Id,g.Name);
						}
						if(! includeChildGroups) {
							break;
						}
					}
				}
			}
			return actorMap;
		}
		private set {
			actorMap = value;
			if(value == null) {
				processInstanceWorkitems = null;
				processInstanceSteps = null;
			}
		}
	}

	/**
	 * Called to query the process instance records.
	 */
	protected void doQuery() {
		if(processInstanceWorkitems == null) {
			processInstances = null;
			processInstanceWorkitems = [
				select Actor.Name, ActorId, IsDeleted, ProcessInstance.TargetObjectId, ProcessInstance.TargetObject.Name, ProcessInstance.Status
				from ProcessInstanceWorkitem
				where ActorId in :actorMap.keySet()
					and ProcessInstance.Status not in :excludeStatuses
				order by ProcessInstanceId, CreatedDate
				limit :((Limits.getLimitQueryRows() - Limits.getQueryRows())/2) ];
			processInstanceWorkitemPaginator.setResultSize(processInstanceWorkitems.size());
		}
		if(processInstanceSteps == null) {
			processInstances = null;
			processInstanceSteps = [
				select Actor.Name, ActorId, ProcessInstance.TargetObjectId,  ProcessInstance.TargetObject.Name, ProcessInstance.Status, StepStatus 
				from ProcessInstanceStep
				where ActorId in :actorMap.keySet()
					and ProcessInstance.Status not in :excludeStatuses
					and StepStatus not in :excludeStepStatuses 
				order by ProcessInstanceId, CreatedDate
				limit :(Limits.getLimitQueryRows() - Limits.getQueryRows()) ];
			processInstanceStepPaginator.setResultSize(processInstanceSteps.size());
			// For sanity sake look for missing workitems
			Set<Id> processInstanceIds = new Set<Id>();
			for(ProcessInstanceStep pis : processInstanceSteps) {
				processInstanceIds.add(pis.ProcessInstance.Id);
			}
			for(ProcessInstanceWorkitem piw : processInstanceWorkitems) {
				processInstanceIds.remove(piw.ProcessInstanceId);
			}
			// normally there are no additional records retrieved by this step
			processInstanceWorkitems.addAll([
				select Actor.Name, ActorId, IsDeleted, ProcessInstance.TargetObjectId, ProcessInstance.TargetObject.Name, ProcessInstance.Status
				from ProcessInstanceWorkitem
				where ProcessInstance.Status not in :excludeStatuses
					and ProcessInstanceId in :processInstanceIds
				order by ProcessInstanceId, CreatedDate
				limit :((Limits.getLimitQueryRows() - Limits.getQueryRows()))
				ALL ROWS ]);
			processInstanceWorkitemPaginator.setResultSize(processInstanceWorkitems.size());
		}
		if(processInstances == null) {
			processInstances = new List<ProcessInstanceRecord>();
			Map<Id,Set<String>> objectKeyPrefixesMap = new Map<Id,Set<String>>();
			for(ProcessInstanceWorkitem p : processInstanceWorkitems) {
				Set<String> objectKeyPrefixes = objectKeyPrefixesMap.get(p.ActorId);
				if(objectKeyPrefixes == null) {
					objectKeyPrefixes = new Set<String>();
					objectKeyPrefixesMap.put(p.ActorId,objectKeyPrefixes);
				}
				String keyPrefix = (p.ProcessInstance.TargetObjectId+'   ').substring(0,3);
				if(! objectKeyPrefixes.contains(keyPrefix)) {
					objectKeyPrefixes.add(keyPrefix);
					processInstances.add(new ProcessInstanceWorkitemRecord(p,actorMap));
				}
			}
			for(ProcessInstanceStep p : processInstanceSteps) {
				Set<String> objectKeyPrefixes = objectKeyPrefixesMap.get(p.ActorId);
				if(objectKeyPrefixes == null) {
					objectKeyPrefixes = new Set<String>();
					objectKeyPrefixesMap.put(p.ActorId,objectKeyPrefixes);
				}
				String keyPrefix = (p.ProcessInstance.TargetObjectId+'   ').substring(0,3);
				if(! objectKeyPrefixes.contains(keyPrefix)) {
					objectKeyPrefixes.add(keyPrefix);
					processInstances.add(new ProcessInstanceStepRecord(p,actorMap));
				}
			}
			processInstancePaginator.setResultSize(processInstances.size());
		}
	}

	/**
	 * Called to get the set of ProcessInstanceStepRecord values which will be displayed.
	 *
	 * @return list of records to display.
	 */
	public List<ProcessInstanceStepRecord> getProcessInstanceStepRecords() {
		doQuery();
		List<ProcessInstanceStepRecord> retval = new List<ProcessInstanceStepRecord>();
		for(Integer i=processInstanceStepPaginator.getOffset();retval.size() < processInstanceStepPaginator.getPageSize() && i < processInstanceStepPaginator.getResultSize();) {
			retval.add(new ProcessInstanceStepRecord(processInstanceSteps.get(i++),actorMap));
		}
		return retval;
	}

	/**
	 * Called to get the set of ProcessInstanceWorkitemRecord values which will be displayed.
	 *
	 * @return list of records to display.
	 */
	public List<ProcessInstanceWorkitemRecord> getProcessInstanceWorkitemRecords() {
		doQuery();
		List<ProcessInstanceWorkitemRecord> retval = new List<ProcessInstanceWorkitemRecord>();
		for(Integer i=processInstanceWorkitemPaginator.getOffset();retval.size() < processInstanceWorkitemPaginator.getPageSize() && i < processInstanceWorkitemPaginator.getResultSize();) {
			retval.add(new ProcessInstanceWorkitemRecord(processInstanceWorkitems.get(i++),actorMap));
		}
		return retval;
	}

	/**
	 * Called to get the set of ProcessInstanceRecord values which will be displayed.
	 *
	 * @return list of records to display.
	 */
	public List<ProcessInstanceRecord> getProcessInstanceRecords() {
		doQuery();
		List<ProcessInstanceRecord> retval = new List<ProcessInstanceRecord>();
		for(Integer i=processInstancePaginator.getOffset();retval.size() < processInstancePaginator.getPageSize() && i < processInstancePaginator.getResultSize();) {
			retval.add(processInstances.get(i++));
		}
		return retval;
	}

	/**
	 * Called to get the currently selected Paginator.
	 *
	 * @return the current Paginator.
	 */
	public Paginator getPaginator() {
		doQuery();
		Paginator retval = processInstancePaginator;
		if(displayOption == APPROVAL_STEPS) {
			retval = processInstanceStepPaginator;
		}
		else if(displayOption == WORKITEMS) {
			retval = processInstanceWorkitemPaginator;
		}
		return retval;
	}

	/**
	 * This option indicates which table will be displayed.
	 */
	public String displayOption {
		get {
			if(displayOption == null) {
				displayOption = SUMMARY;
			}
			return displayOption;
		}
		set;
	}

	/**
	 * This is a SelectOption list for choosing the displayOption.
	 */
	public List<SelectOption> getDisplayOptions() {
		doQuery();
		return new List<SelectOption>{
			new SelectOption(SUMMARY,SUMMARY),
			new SelectOption(WORKITEMS,WORKITEMS+' ('+processInstanceWorkitemPaginator.getResultSize()+')'),
			new SelectOption(APPROVAL_STEPS,APPROVAL_STEPS+' ('+processInstanceStepPaginator.getResultSize()+')') };
	}

	/**
	 * Called to find how many pages there are to display.
	 *
	 * @return the number of pages to display.
	 */
	public Integer getPageCount() {
		Integer rs = getPaginator().getResultSize();
		Integer ps = getPaginator().getPageSize();
		return (ps+rs-1)/ps;
	}

	/**
	 * Called to navigate to the first page.
	 *
	 * @return null
	 */
	public PageReference first()
	{
		processInstanceWorkitems = null;
		processInstanceSteps = null;
		getPaginator().first();
		System.debug('PageNumber='+getPaginator().getPageNumber());
		return null;
	}

	/**
	 * Called to navigate to the next page.
	 *
	 * @return null
	 */
	public PageReference next()
	{
		getPaginator().next();
		System.debug('PageNumber='+getPaginator().getPageNumber());
		return null;
	}

	/**
	 * Called to navigate to the previous page.
	 *
	 * @return null
	 */
	public PageReference previous()
	{
		getPaginator().previous();
		System.debug('PageNumber='+getPaginator().getPageNumber());
		return null;
	}

	/**
	 * Called to navigate to the last page.
	 *
	 * @return null
	 */
	public PageReference last()
	{
		getPaginator().last();
		System.debug('PageNumber='+getPaginator().getPageNumber());
		return null;
	}

	/**
	 * This class represents a high level abstraction of ProcessInstanceStep
	 * and ProcessInstanceWorkitem records.
	 */
	public abstract class ProcessInstanceRecord {
		private final Id actorId;
		private final Id targetObjectId;
		private final String targetObjectName;
		private final String status;
		private final String actor;
		protected ProcessInstanceRecord(Id actorId,String actorName,Id targetObjectId,String targetObjectName,String status,Map<Id,String> actorMap) {
			this.actorId = actorId;
			this.targetObjectId = targetObjectId;
			this.targetObjectName = targetObjectName;
			this.status = status;
			String actor = actorMap.get(actorId);
			if(actor == null) {
				actor = actorName;
				if(actor == null) {
					actor = actorId;
				}
			}
			this.actor = actor;
		}

		/** 
		 * Called to obtain the user or group name.
		 *
		 * @return user or group name
		 */
		public String getActor() { return actor; }

		/** 
		 * Called to obtain the user or group Id.
		 *
		 * @return user or group Id
		 */
		public Id getActorId() { return actorId; }

		/** 
		 * Called to obtain the target object Id.
		 *
		 * @return target object Id
		 */
		public Id getTargetObjectId() { return targetObjectId; }

		/** 
		 * Called to obtain the target object Name.
		 *
		 * @return target object Id
		 */
		public String getTargetObjectName() { return targetObjectName; }

		/** 
		 * Called to obtain the target object label.
		 *
		 * @return target object label
		 */
		public String getTargetObject() { 
			String retval = keyPrefixMap.get((targetObjectId+'   ').substring(0,3)); 
			if(retval == null) {
				retval = targetObjectId;
			}
			return retval;
		}

		/** 
		 * Called to obtain the status.
		 *
		 * @return status
		 */
		public String getStatus() { return status; }
	}

	/**
	 * This class represents a ProcessInstanceWorkitem record.
	 */
	public class ProcessInstanceWorkitemRecord extends ProcessInstanceRecord {
		public ProcessInstanceWorkitemRecord(ProcessInstanceWorkitem piw,Map<Id,String> actorMap) {
			super(piw.ActorId,piw.Actor.Name,piw.ProcessInstance.TargetObjectId,piw.ProcessInstance.TargetObject.Name,piw.ProcessInstance.Status,actorMap);
		}
	}

	/**
	 * This class represents a ProcessInstanceStep record.
	 */
	public class ProcessInstanceStepRecord extends ProcessInstanceRecord {
		private final String stepStatus;
		public ProcessInstanceStepRecord(ProcessInstanceStep pis,Map<Id,String> actorMap) {
			super(pis.ActorId,pis.Actor.Name,pis.ProcessInstance.TargetObjectId,pis.ProcessInstance.TargetObject.Name,pis.ProcessInstance.Status,actorMap);
			this.stepStatus = pis.StepStatus;
		}
		public String getStepStatus() { return stepStatus; }
	}

	/**
	 * This class implements a Paginator for our records.  Normally we would
	 * just us the StandardSetController, but that class does not support these
	 * objects.
	 */
	public class Paginator {
		Integer resultSize = 0;
		Integer pageNumber = 0;
		Integer pageSize = 20;
		/** Simple constructor */
		public Paginator() {}

		/**
		 * Called to find the number records per page.
		 *
		 * @return number of records per page
		 */
		public Integer getPageSize() {
			return pageSize;
		}

		/**
		 * Called to set the number of available rows.  When
		 * the value is changed, we reset to page 0.
		 *
		 * @param value number of available rows
		 */
		public void setResultSize(Integer value) {
			if(resultSize != value) {
				resultSize = value;
				pageNumber = 0;
			}
		}

		/**
		 * Called to get the number of available rows.
		 *
		 * @return number of available rows
		 */
		public Integer getResultSize() {
			return resultSize;
		}

		/**
		 * Called to get the current offset.
		 *
		 * @return current offset
		 */
		public Integer getOffset() {
			return pageNumber*pageSize;
		}

		/**
		 * Called to get the current page number (starting at 1).
		 *
		 * @return page number
		 */
		public Integer getPageNumber() {
			return pageNumber+1;
		}

		/**
		 * Called to find how many pages are available.
		 *
		 * @return number of pages available
		 */
		public Integer getPageCount() {
			return (resultSize+pageSize-1)/pageSize;
		}

		/**
		 * Called to advance to the next page
		 */
		public void next() {
			if(++pageNumber >= getPageCount()) {
				last();
			}
		}

		/**
		 * Called to go back to the previous page
		 */
		public void previous() {
			if(--pageNumber < 0) {
				first();
			}
		}

		/**
		 * Called to go back to the first page
		 */
		public void first() {
			pageNumber = 0;
		}


		/**
		 * Called to advance to the last page
		 */
		public void last() {
			pageNumber = (resultSize-1)/pageSize;
		}

		/**
		 * Called to find if there is a next page
		 *
		 * @return true if we are not on the last page
		 */
		public Boolean getHasNext() {
			return ((pageNumber+1) < getPageCount());
		}

		/**
		 * Called to find if there is a previous page
		 *
		 * @return true if we are not on the first page
		 */
		public Boolean getHasPrevious() {
			return (pageNumber > 0);
		}
	}
}