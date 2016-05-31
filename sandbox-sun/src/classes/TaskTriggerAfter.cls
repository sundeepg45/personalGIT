/**
 * This class replaces all after insert and after update task triggers.  The
 * processTrigger method is invoked by the Task_After trigger and in turn invokes
 * all the methods of this class.  This gives us a way to control the order in
 * which the code logic is invoked, as well as allowing other class features such
 * as shared data, constant values, and rigorious test coverage.
 * <p>
 * The Trigger object should never be directly referenced inside this class, as
 * that would make it impossible to substituting values inside test methods.
 * </p>
 *
 * @version 2016-02-11
 * @author Bill C Riemers <briemers@redhat.com>
 * @since 2014-04-19 - Added thread locking to updateLeads
 * @since 2013-10-18 - Delete duplicate monitored activities
 * @since 2013-04-08 - Added syncActions method
 * @since 2012-06-13 - Updated for monitored activities
 * @since 2011-09-22 - Created
 * @author Sundeep Godishala <sgodisha@redhat.com>
 * @since 2016-02-11 - Added blockDelete method
 */
public without sharing class TaskTriggerAfter extends AbstractTrigger {
    /** BooleanSetting__c key to enable the syncActions trigger method. */
    public static final String SYNC_ACTIONS_SETTING = 'Task_After.syncActions';
    /** BooleanSetting__c key to enable the tandemNotify trigger method. */
    public static final String TANDEM_NOTIFY_SETTING = 'Task_After.tandemNotify';
    /** BooleanSetting__c key to enable the oppTriage trigger method. */
    public static final String OPP_TRIAGE_SETTING = 'Task_After.oppTriage';
    /** BooleanSetting__c key to enable the updateLeads trigger method. */
    public static final String UPDATE_LEADS_SETTING = 'Task_After.updateLeads';
    /** BooleanSetting__c key to enable the monitorActivities trigger method. */
    public static final String MONITOR_ACTIVITIES_SETTING = 'Task_After.monitorActivities';
    /** BooleanSetting__c key to enable the blockDelete trigger method. */
    public static final String BLOCK_DELETE_SETTING = 'Task_After.blockDelete';

    /** RecordType name used for Strategic Plan Actions. */
    public static final String SPA_RECORDTYPE_NAME = 'Strategic Plan Action';

    /** Normally populated as a copy of Trigger.oldMap */
    private final Map<Id,Task> oldMap = new Map<Id,Task>();
    /** Normally populated as Trigger.new */
    private final Map<Id,Task> newMap = new Map<Id,Task>();
    /** Used to keep track of errors while debugging */
    public Boolean hasErrors = false;

    /**
     * This constructor is normally called from the processTrigger method and
     * test methods.
     */
    public TaskTriggerAfter(Map<Id,Task> xoldMap,Map<Id,Task> xnewMap) {
        super(xoldMap,null,xnewMap);
        if(xoldMap != null) {
            oldMap.putAll(xoldMap);
        }
        if(xnewMap != null) {
            newMap.putAll(xnewMap);
        }
    }

    /**
     * Synchronize the Strategic Plan Actions objects.
     */
    public void syncActions() {
        Id spaRecordTypeId = RecordTypeLookup.getRecordTypeId(SPA_RECORDTYPE_NAME,'Task');
        if((isUpdate || isDelete) && (spaRecordTypeId != null)) {
            Set<Id> taskIds = new Set<Id>();
            Map<Id,Task> taskMap = newMap;
            if(isDelete) {
                taskmap = oldMap;
            }
            for(Task tk : taskMap.values()) {
                if(tk.RecordTypeId == spaRecordTypeId) {
                    taskIds.add(tk.Id);
                }
            }
            if(! taskIds.isEmpty()) {
                List<StrategicPlan_Action__c> actions = [
                    select 
                        ActionSubject__c,
                        AssignedTo__c,
                        End__c,
                        Start__c,
                        Status__c,
                        Subject__c,
                        TaskId__c
                    from StrategicPlan_Action__c
                    where TaskId__c in :taskIds ];
                if(! actions.isEmpty()) {
                    if(isDelete) {
                        for(Database.DeleteResult dr : Database.delete(actions)) {
                            StrategicPlan_Action__c action = actions.remove(0);
                            if(! dr.isSuccess()) {
                                Task t = oldMap.get(action.TaskId__c);
                                t.addError('Failed to delete action: '+dr.getErrors());
                                hasErrors = true;
                            }
                        }
                    }
                    else {
                        List<StrategicPlan_Action__c> updatedActions = new List<StrategicPlan_Action__c>();
                        for(StrategicPlan_Action__c action : actions) {
                            Task t = newMap.get(action.TaskId__c);
                            if(action.ActionSubject__c != t.ActionSubject__c
                                || action.AssignedTo__c != t.OwnerId
                                || action.End__c != t.End__c
                                || action.Start__c != t.Start__c
                                || action.Status__c != t.Status
                                || action.Subject__c != t.Subject )
                            {
                                action.ActionSubject__c = t.ActionSubject__c;
                                action.AssignedTo__c = t.OwnerId;
                                action.End__c = t.End__c;
                                action.Start__c = t.Start__c;
                                action.Status__c = t.Status;
                                action.Subject__c = t.Subject;
                                updatedActions.add(action);
                            }
                        }
                        if(! updatedActions.isEmpty()) {
                            for(Database.SaveResult sr : Database.update(updatedActions,false)) {
                                StrategicPlan_Action__c action = updatedActions.remove(0);
                                if(! sr.isSuccess()) {
                                    Task t = newMap.get(action.TaskId__c);
                                    t.addError('Failed to update action: '+sr.getErrors());
                                    hasErrors = true;
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    /**
     * This trigger method replaces TandemTaskNotification trigger.
     */
    public void tandemNotify() {
        if(isInsert || isUpdate) {
            TandemTaskNotifcationMail ttnm = new TandemTaskNotifcationMail();
            for(Task tk : newMap.values()) {
                if(tk.RecordTypeId == Util.tandemRecordTypeId) {
                    ttnm.addTask(tk);
                }
            }
            ttnm.sendMail();
        }
    }

    /**
     * This trigger method replaces OpportunityTriage trigger.
     */
    public void oppTriage() {
        if(isInsert) {
            Map<Id,Task> taskByOppIdMap = new Map<Id,Task>();
            for(Task tk : newMap.values()) {
                if(tk.RecordTypeId == Util.omCorrectionRequestRecordTypeId && (tk.WhatId+'').startsWith('006')) {
                    taskByOppIdMap.put(tk.WhatId,tk);
                }
            }
            if(! taskByOppIdMap.isEmpty()) {
                List<Opportunity> opps = [
                    select Id 
                    from Opportunity 
                    where Id in :taskByOppIdMap.keySet()
                        and Triage_Opportunity__c != true ];
                if(! opps.isEmpty()) {
                    for(Opportunity opp : opps) {
                        opp.Triage_Opportunity__c = true;
                    }
                    for(Database.SaveResult r : Database.update(opps,false)) {
                        Opportunity opp = opps.remove(0);
                        for(Database.Error e : r.getErrors()) {
                            taskByOppIdMap.get(opp.Id).addError('Failed to update '+opp+': '+e);
                            hasErrors = true;
                        }
                    }
                }
            }
        }
    }

    /**
     * This trigger method will attempt to update Leads when there respective tasks
     * are updated.
     */
    public void updateLeads() {
        if(ThreadLock.lock('TaskTriggerAfter.updateLeads')) {
            try {
                Map<Id,Task> taskMap = newMap;
                if(isDelete) {
                    taskMap = oldMap;
                }
                Map<Id,Lead> leadMap = new Map<Id,Lead>();
                for(Task t : taskMap.values()) {
                    if((''+t.WhoId).startsWith('00Q')) {
                        leadMap.put(t.WhoId,new Lead(Id=t.WhoId));
                    }
                }
                if(! leadMap.isEmpty()) {
                    Database.update(leadMap.values(),false);
                }
            }
            finally {
                ThreadLock.unlock('TaskTriggerAfter.updateLeads');
            }
        }
    }

    @TestVisible
    private static AdminByPass__c adminByPass { get {
        if(adminByPass == null) {
            adminByPass = AdminByPass__c.getInstance();
        }
        return adminByPass;
    }}

    /**
     * Called to block deleting of SEAP tasks for sales users
     */
    public void blockDelete(){
        if(isDelete && adminByPass != null && adminByPass.IsSalesUser__c) {
            Schema.RecordTypeInfo recordTypeInfo= Schema.SObjectType.Task.getRecordTypeInfosByName().get('SEA Task');
            system.debug('recordtype@@@'+recordTypeInfo);
            if(recordTypeInfo != null) {
                Id recordTypeId = recordTypeInfo.getRecordTypeId();
                for(Task t:oldMap.values()) {
                    if(t.RecordTypeId == recordTypeId) {                   
                        t.addError(Label.SEA_Task_Cannot_be_Deleted);
                        hasErrors = true;
                    }
                }
            }
        }
    }

    /**
     * Called to create and update MonitoredActivity__c objects.
     */
    public void monitorActivities() {
        List<Task> taskList = new List<Task>();
        List<MonitoredActivity__c> monitoredActivityList = new List<MonitoredActivity__c>();
        if(! isDelete) {
            Set<String> subjects = new Set<String>();
            for(Task t : newMap.values()) {
                if(t.Monitor__c == true) {
                    Task oldTask = null;
                    if(oldMap != null) {
                        oldTask = oldMap.get(t.Id);
                    }
                    if( oldTask == null 
                        || t.ActivityDate != oldTask.ActivityDate
                        || t.OwnerId != oldTask.OwnerId
                        || t.RecordTypeId != oldTask.RecordTypeId
                        || t.Status != oldTask.Status
                        || t.Subject != oldTask.Subject )
                    {
                        subjects.add(t.Subject);
                        if(oldTask != null) {
                            subjects.add(oldTask.Subject);
                        }
                        // add a monitored activity and tasks to the lists
                        monitoredActivityList.add(new MonitoredActivity__c(
                            ActivityDate__c = DateTime.newInstance(t.ActivityDate,Time.newInstance(0,0,0,0)),
                            OwnerId = t.OwnerId,
                            RecordTypeId__c = t.RecordTypeId,
                            Status__c = t.Status,
                            Subject__c = t.Subject,
                            TaskId__c = t.Id,
                            SkippedCount__c = 0.0));
                        taskList.add(t);
                    }
                }
            }
            if(! monitoredActivityList.isEmpty()) {
                // We do not allow more than one monitored activity per subject
                Database.delete([
                    select Id
                    from MonitoredActivity__c
                    where Subject__c in :subjects
                        and TaskId__c not in :newMap.keySet() ],false);
                // insert new records and update existing ones
                for(Database.UpsertResult sr : Database.upsert(monitoredActivityList,MonitoredActivity__c.Fields.TaskId__c,false)) {
                    Task t = taskList.remove(0);
                    MonitoredActivity__c ma = monitoredActivityList.remove(0);
                    if(! sr.isSuccess()) {
                        // return an error
                        t.addError('Failed to create or update Monitored Activity: '+sr.getErrors());
                        hasErrors = true;
                    }
                }
            }
        }
        if(! isInsert) {
            Set<Id> taskIds = new Set<Id>();
            if (isDelete) {
                for(Task t : oldMap.values()) {
                    if(t.Monitor__c == true) {
                        taskIds.add(t.Id);
                    }
                }
            }
            else {
                for(Task t : newMap.values()) {
                    if(t.Monitor__c != true && oldMap.get(t.Id).Monitor__c == true) {
                        taskIds.add(t.Id);
                    }
                }
            }
            if(! taskIds.isEmpty()) {
                // for now we are ignoring delete errors, leaving orphaned records
                List<MonitoredActivity__c> monitoredActivities = [
                    select TaskId__c
                    from MonitoredActivity__c
                    where TaskId__c in :taskIds];
                for(Database.DeleteResult dr : Database.delete(monitoredActivities,false)) {
                    MonitoredActivity__c ma = monitoredActivities.remove(0);
                    if(! dr.isSuccess()) {
                        Task t = oldMap.get(ma.TaskId__c);
                        if(isUpdate) {
                            t = newMap.get(ma.TaskId__c);
                        }
                        t.addError('Failed to delete monitored activity: '+dr.getErrors());
                        hasErrors = true;
                    }
                }
            }
        }
    }

    /**
     * This method is called from the Task_After trigger to invoke all the methods
     * of this class, to obsolete the need for individual after triggers.  The primary
     * reason to place all the triggers in a class is so we control the order in which
     * the triggers are invoked.
     *
     * @param xoldMap the immutable map of previous Task objects as in Trigger.oldMap.
     * @param xnewMap the immutable map of new Task objects as in Trigger.newMap
     */
    public static void processTrigger(Map<Id,Task> xoldMap,Map<Id,Task> xnewMap) {
        final TaskTriggerAfter afterTrigger = new TaskTriggerAfter(xoldMap,xnewMap);
        if(AbstractTrigger.isActive(SYNC_ACTIONS_SETTING,true)) {
            afterTrigger.syncActions();
        }
        if(AbstractTrigger.isActive(TANDEM_NOTIFY_SETTING,true)) {
            afterTrigger.tandemNotify();
        }
        if(AbstractTrigger.isActive(OPP_TRIAGE_SETTING,true)) {
            afterTrigger.oppTriage();
        }
        if(AbstractTrigger.isActive(UPDATE_LEADS_SETTING,true)) {
            afterTrigger.updateLeads();
        }
        if(AbstractTrigger.isActive(MONITOR_ACTIVITIES_SETTING,true)) {
            afterTrigger.monitorActivities();
        }
        if(AbstractTrigger.isActive(BLOCK_DELETE_SETTING,true)) {
            afterTrigger.blockDelete();
        }
        AbstractTrigger.processTriggerComplete();
    }

}