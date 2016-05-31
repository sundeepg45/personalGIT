trigger MA_NotifyCaseTeamMember on MonitoredActivity__c (after insert) {
  DailyScheduler.injectBatchable(Trigger.new,'NotifyCaseTeamMember',new NotifyCaseTeamMember());
}