/**
 * This is a test class for CaseCommentTriggerAfter.
 *
 * @author Bill C Riemers <briemers@redhat.com>
 * @version 2012-12-06
 * 2012-12-06 - created
 */
@isTest
private class CaseCommentTriggerAfterTest {
	static Case case1 {
		get {
			if (case1 == null) {
				case1 = new Case();
				insert case1;
			}
			return case1;
		}
	}

	static CaseComment caseComment {
		get {
			if(caseComment == null) {
				caseComment = new caseComment(ParentId=case1.Id,CommentBody='anything');
			}
			return caseComment;
		}
	}

	static Id caseCommentId {
		get {
			if(caseComment.Id == null) {
				// Turn off all the triggers for the insert
				AbstractTrigger.setBooleanSettings('CaseComment_After.',false);
				insert caseComment;
				// Turn on all the triggers for the insert
				AbstractTrigger.setBooleanSettings('CaseComment_After.',true);
			}
			return caseComment.Id;
		}
	}

	@isTest
	static void upsertDataTest() {
		insert new BooleanSetting__c(Name=CaseCommentTriggerAfter.UPSERT_DATA,Value__c=false);
		System.assertEquals(0,[select count() from CaseCommentData__c where CaseCommentId__c=:caseCommentId]);
		Map<Id,CaseComment> ccMap = new Map<Id,CaseComment>([
			select 
				CommentBody,
				CreatedById,
				CreatedDate,
				LastModifiedById,
				LastModifiedDate,
				ParentId
			from CaseComment
			where Id = :caseCommentId]);
		CaseCommentTriggerAfter afterTrigger = new CaseCommentTriggerAfter(null,ccMap);
		Test.startTest();
		afterTrigger.upsertData();
		Test.stopTest();
		CaseCommentData__c ccd = [
			select
				Case__c,
				CaseCommentId__c
			from CaseCommentData__c
			where CaseCommentId__c=:caseCommentId ];
		System.assertEquals(caseComment.ParentId,ccd.Case__c);
	}

	@isTest(SeeAllData=true) // need all data to access custom settings
	static void processTriggerTest() {
		caseCommentTriggerAfter.processTrigger(new Map<Id,CaseComment>{caseCommentId=>caseComment},new Map<Id,CaseComment>{caseCommentId=>caseComment});
		// If there were any missing values, our test is invalid
		AbstractTriggerTest.validateSettings('CaseComment_After.');
	}

	// Just invoke the trigger.  We already tested the results in the above
	// methods.  If we check it here then we can have deployment problems
	// as the trigger may be deployed after the class, or could be inactive.
	@isTest
	static void deployTest() {
		AbstractTriggerTest.deployTest('CaseComment_After.',new List<CaseComment>{caseComment},true,false,true);
	}
}