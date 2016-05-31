/**
 * This is a test for the ProcessInstance_SetController class.
 * 
 * @author Bill C. Riemers <briemers@redhat.com>
 * @version 2012-08-28
 * 2012-08-28 - Created
 */
@isTest
private class ProcessInstance_SetControllerTest extends ProcessInstance_SetController {
	static final Id DUMMY_ACCOUNT = '001002003004005';
	static final Id DUMMY_CONTACT = '003002003004005';
	static final Id DUMMY_LEAD = '00Q002003004005';
	static final Id DUMMY_GROUP = '00G002003004005';
	
	static List<ProcessInstance> processInstanceList {
		get {
			if(processInstanceList == null) {
				processInstanceList = new List<ProcessInstance>{
					new ProcessInstance(TargetObjectId=DUMMY_ACCOUNT,Status='Pending'),
					new ProcessInstance(TargetObjectId=DUMMY_CONTACT,Status='Rejected'),
					new ProcessInstance(TargetObjectId=DUMMY_LEAD,Status='Approved')
				};
			}
			return processInstanceList;
		}
	}

	static List<ProcessInstanceWorkitem> processInstanceWorkitemList {
		get {
			if(processInstanceWorkitemList == null) {
				
				processInstanceWorkitemList = new List<ProcessInstanceWorkitem>();
				for(ProcessInstance pi : processInstanceList) {
					processInstanceWorkitemList.add(new ProcessInstanceWorkitem(ActorId=UserInfo.getUserId(),ProcessInstance=pi));
					processInstanceWorkitemList.add(new ProcessInstanceWorkitem(ActorId=DUMMY_GROUP,ProcessInstance=pi));
				}
			}
			return processInstanceWorkitemList;
		}
	}

	static List<ProcessInstanceStep> processInstanceStepList {
		get {
			if(processInstanceStepList == null) {
				
				processInstanceStepList = new List<ProcessInstanceStep>();
				for(ProcessInstance pi : processInstanceList) {
					processInstanceStepList.add(new ProcessInstanceStep(ActorId=UserInfo.getUserId(),ProcessInstance=pi,StepStatus='A'));
					processInstanceStepList.add(new ProcessInstanceStep(ActorId=DUMMY_GROUP,ProcessInstance=pi,StepStatus='A'));
					processInstanceStepList.add(new ProcessInstanceStep(ActorId=UserInfo.getUserId(),ProcessInstance=pi,StepStatus='B'));
					processInstanceStepList.add(new ProcessInstanceStep(ActorId=DUMMY_GROUP,ProcessInstance=pi,StepStatus='B'));
				}
			}
			return processInstanceStepList;
		}
	}

	
	static ProcessInstance_SetControllerTest controller {
		get {
			if(controller == null) {
				Test.setCurrentPageReference(new PageReference('/apex/somepage?id='+UserInfo.getUserId()));
				controller = new ProcessInstance_SetControllerTest();
			}
			return controller;
		}
	}

	@isTest
	static void keyPrefixMapTest() {
		System.assertEquals('Account',ProcessInstance_SetController.keyPrefixMap.get((DUMMY_ACCOUNT+'   ').substring(0,3)));
		System.assertEquals('Contact',ProcessInstance_SetController.keyPrefixMap.get((DUMMY_CONTACT+'   ').substring(0,3)));
		System.assertEquals('Lead',ProcessInstance_SetController.keyPrefixMap.get((DUMMY_LEAD+'   ').substring(0,3)));
	}

	@isTest
	static void actorMapTest() {
		// to do insert groups for this test
		controller.excludeComplete = false;
		controller.includeGroups = true;
		controller.includeChildGroups = true;
		System.assertNotEquals(null,controller.actorMap.get(UserInfo.getUserId()));
	}

	List<ProcessInstanceWorkitem> getProcessInstanceWorkitems() {
		return processInstanceWorkitems;
	}

	void setProcessInstanceWorkitems(List<ProcessInstanceWorkitem> values) {
		processInstanceWorkitems = values;
		if(values != null) {
			processInstanceWorkitemPaginator.setResultSize(values.size());
		}
	}

	List<ProcessInstanceStep> getProcessInstanceSteps() {
		return processInstanceSteps;
	}

	void setProcessInstanceSteps(List<ProcessInstanceStep> values) {
		processInstanceSteps = values;
		if(values != null) {
			processInstanceStepPaginator.setResultSize(values.size());
		}
	}

	List<ProcessInstanceRecord> getProcessInstances() {
		return processInstances;
	}

	void setProcessInstances(List<ProcessInstanceRecord> values) {
		processInstances = values;
		if(values != null) {
			processInstancePaginator.setResultSize(values.size());
		}
	}

	void xdoQuery() {
		doQuery();
	}

	static void validate(ProcessInstanceRecord r) {
		if(r.getActorId() == DUMMY_GROUP) {
			System.assertEquals('Dummy Group',r.getActor());
		}
		else {
			System.assertEquals(UserInfo.getUserId(),r.getActorId());
			System.assertNotEquals(null,r.getActor());
		}
		if(r.getTargetObjectId() == DUMMY_ACCOUNT) {
			System.assertEquals('Account',r.getTargetObject());
		}
		else if(r.getTargetObjectId() == DUMMY_CONTACT) {
			System.assertEquals('Contact',r.getTargetObject());
		}
		else {
			System.assertEquals(DUMMY_LEAD,r.getTargetObjectId());
			System.assertEquals('Lead',r.getTargetObject());
		}
	}

	@isTest
	static void doQueryTest() {
		controller.actorMap.put(DUMMY_GROUP,'Dummy Group');
		controller.xdoQuery();
		System.assert(controller.getProcessInstanceWorkitems().isEmpty());
		System.assert(controller.getProcessInstanceSteps().isEmpty());
		System.assert(controller.getProcessInstances().isEmpty());
		controller.setProcessInstanceWorkitems(processInstanceWorkitemList);
		controller.setProcessInstanceSteps(processInstanceStepList);
		controller.setProcessInstances(null);
		controller.xdoQuery();
		System.assertEquals(processInstanceWorkitemList.size(),controller.getProcessInstances().size());
		for(ProcessInstanceRecord r : controller.getProcessInstances()) {
			validate(r);
		}
	}

	@isTest
	static void paginatorTests() {
		Paginator p = new Paginator();
		System.assertNotEquals(0,p.getPageSize());
		p.setResultSize(p.getPageSize()*10+1);
		System.assertEquals(p.getPageSize()*10+1,p.getResultSize());
		System.assertEquals(0,p.getOffset());
		System.assertEquals(1,p.getPageNumber());
		System.assertEquals(11,p.getPageCount());
		System.assert(p.getHasNext(),'Expected next page');
		System.assert(! p.getHasPrevious(),'Unexpected previous page');
		p.next();
		System.assertEquals(p.getPageSize(),p.getOffset());
		System.assertEquals(2,p.getPageNumber());
		System.assert(p.getHasNext(),'Expected next page');
		System.assert(p.getHasPrevious(),'Expected previous page');
		p.previous();
		System.assertEquals(0,p.getOffset());
		System.assertEquals(1,p.getPageNumber());
		System.assert(p.getHasNext(),'Expected next page');
		System.assert(! p.getHasPrevious(),'Unexpected previous page');
		p.last();
		System.assertEquals(p.getPageSize()*10,p.getOffset());
		System.assertEquals(11,p.getPageNumber());
		System.assert(! p.getHasNext(),'Unexpected next page');
		System.assert(p.getHasPrevious(),'Expected previous page');
		p.first();
		System.assertEquals(0,p.getOffset());
		System.assertEquals(1,p.getPageNumber());
		System.assert(p.getHasNext(),'Expected next page');
		System.assert(! p.getHasPrevious(),'Unexpected previous page');
	}

	@isTest
	static void processInstanceRecordsTest() {
		controller.actorMap.put(DUMMY_GROUP,'Dummy Group');
		controller.setProcessInstanceWorkitems(processInstanceWorkitemList);
		controller.setProcessInstanceSteps(processInstanceStepList);
		System.assertEquals(processInstanceWorkitemList.size(),controller.getProcessInstanceRecords().size());
		for(ProcessInstanceRecord r : controller.getProcessInstanceRecords()) {
			validate(r);
		}
	}

	@isTest
	static void processInstanceWorkitemRecordsTest() {
		controller.actorMap.put(DUMMY_GROUP,'Dummy Group');
		controller.setProcessInstanceWorkitems(processInstanceWorkitemList);
		System.assertEquals(processInstanceWorkitemList.size(),controller.getProcessInstanceWorkitemRecords().size());
		for(ProcessInstanceWorkitemRecord r : controller.getProcessInstanceWorkitemRecords()) {
			validate(r);
			System.assertNotEquals(null,r.getStatus());
		}
	}

	@isTest
	static void processInstanceStepRecordsTest() {
		controller.actorMap.put(DUMMY_GROUP,'Dummy Group');
		controller.setProcessInstanceSteps(processInstanceStepList);
		System.assertEquals(processInstanceStepList.size(),controller.getProcessInstanceStepRecords().size());
		for(ProcessInstanceStepRecord r : controller.getProcessInstanceStepRecords()) {
			validate(r);
			System.assertNotEquals(null,r.getStatus());
			System.assertNotEquals(null,r.getStepStatus());
		}
	}

	@isTest
	static void displayOptionsTest() {
		// this is just coverage
		controller.actorMap.put(DUMMY_GROUP,'Dummy Group');
		controller.setProcessInstanceWorkitems(processInstanceWorkitemList);
		controller.setProcessInstanceSteps(processInstanceStepList);
		System.assertEquals(3,controller.getDisplayOptions().size());
		for(SelectOption so : controller.getDisplayOptions()) {
			if(so.getValue() == ProcessInstance_SetController.SUMMARY) {
				System.assertEquals(ProcessInstance_SetController.SUMMARY,so.getLabel());
			}
			else if(so.getValue() == ProcessInstance_SetController.WORKITEMS) {
				System.assertEquals(ProcessInstance_SetController.WORKITEMS+' ('+processInstanceWorkitemList.size()+')',so.getLabel());
			}
			else {
				System.assertEquals(ProcessInstance_SetController.APPROVAL_STEPS,so.getValue());
				System.assertEquals(ProcessInstance_SetController.APPROVAL_STEPS+' ('+processInstanceStepList.size()+')',so.getLabel());
			}
		}
		System.assertEquals(ProcessInstance_SetController.SUMMARY,controller.displayOption);
	}

	@isTest
	static void actionTests() {
		// this is just coverage
		controller.actorMap.put(DUMMY_GROUP,'Dummy Group');
		controller.setProcessInstanceWorkitems(processInstanceWorkitemList);
		controller.setProcessInstanceSteps(processInstanceStepList);
		controller.displayOption = ProcessInstance_SetController.WORKITEMS;
		System.assertNotEquals(null,controller.getPaginator());
		System.assertEquals(null,controller.next());
		System.assertEquals(null,controller.previous());
		System.assertEquals(null,controller.last());
		System.assertEquals(null,controller.first());
	}
}