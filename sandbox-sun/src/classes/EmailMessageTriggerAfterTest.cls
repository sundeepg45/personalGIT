/**
 * This is a test class for EmailMessageAfterTrigger.
 *
 * @author Scott Coleman <scoleman@redhat.com>
 * @version 2014-07-08
 * 2014-07-08 - Created
 */
@isTest
private class EmailMessageTriggerAfterTest {
	static Case case1 {
		get {
			if (case1 == null) {
				case1 = new Case(
					Origin='GOSS-Request',
					RelativeBenefit__c=1.0,
					RelativePenalty__c=1.0,
					RelativeCost__c=1.0);
				insert case1;
			}
			return case1;
		}
	}

	static EmailMessage emailMessage {
		get {
			if (emailMessage == null) {
				emailMessage = new EmailMessage(
					ParentId = case1.Id,
					FromAddress='from@example.com',
					ToAddress='to@example.com',
					CcAddress='to2@example.com',
					TextBody='message body');
			}
			return emailMessage;
		}
	}

	@isTest
	static void createCaseCommentTest() {
		Case testCase = case1;
		EmailMessage testMessage = emailMessage;

		Test.startTest();
		EmailMessageTriggerAfter afterTrigger = new EmailMessageTriggerAfter(null,new Map<Id,EmailMessage>{null=>testMessage},false);
		afterTrigger.createCaseComment();
		Test.stopTest();

		List<CaseComment> comments = [SELECT Id, CommentBody FROM CaseComment WHERE ParentId = :testCase.Id];
		System.assert(!comments.isEmpty());
		System.assertEquals(1, comments.size());
		System.assertNotEquals(null, comments[0].CommentBody);
		System.assert(comments[0].CommentBody.contains(testMessage.TextBody));
	}

	@isTest(SeeAllData=true) // need all data to access custom settings
	static void processTriggerTest() {
		AbstractTrigger.setBooleanSettings('EmailMessage_After.',false);
		insert emailMessage;
		EmailMessage emailMessage2 = emailMessage.clone(true);
		AbstractTrigger.setBooleanSettings('EmailMessage_After.',true);
		EmailMessageTriggerAfter.processTrigger(null,new Map<Id,EmailMessage>{emailMessage2.Id=>emailMessage2},false);
		AbstractTriggerTest.validateSettings('EmailMessage_After.');
	}

	// Just invoke the trigger.  We already tested the results in the above
	// methods.  If we check it here then we can have deployment problems
	// as the trigger may be deployed after the class, or could be inactive.
	@isTest
	static void deployTest() {
		AbstractTriggerTest.deployTest('EmailAddress_After.',new List<EmailMessage>{emailMessage},true,true,true);
	}
}