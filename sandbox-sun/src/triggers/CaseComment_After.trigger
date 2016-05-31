trigger CaseComment_After on CaseComment (after insert, after update) {
	CaseCommentTriggerAfter.processTrigger(Trigger.oldMap,Trigger.newMap);
}