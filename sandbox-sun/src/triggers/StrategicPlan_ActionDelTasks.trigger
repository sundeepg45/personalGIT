trigger StrategicPlan_ActionDelTasks on StrategicPlan_Action__c (after delete) {
    List<Task> tasks = new List<Task>();
    for(StrategicPlan_Action__c a : Trigger.old) {
        if(a.TaskId__c != null) {
            tasks.add(new Task(Id=a.TaskId__c));
        }
    }
    if(! tasks.isEmpty()) {
        Database.delete(tasks,false); // ignore errors
    }
}