/**
 * This is a test class for Opportunity_ApprovalReqDiscussContExtn.
 *
 * @author Bill Riemers <briemers@redhat.com>
 * @version 2014-04-08
 * 2014-04-08 - Created
 */
@isTest
private class Opportunity_ApprovReqDiscussContExtnTest {
	static Account account {
		get {
			if(account == null) {
				account = new Account(
					CurrencyIsoCode='USD',
					name='Test Account');
				insert account;
			}
			return account;
		}
	}

	static Opportunity opportunity {
		get {
			if(opportunity == null) {
				opportunity = new Opportunity(
					Name='Opportunity Test',
					CloseDate=System.today(),
					StageName='Prepare',
					OwnerId=UserInfo.getUserId(),
					AccountId=account.Id,
					Country_of_Order__c='India',
					FulfillmentChannel__c='Direct - OEM',
					Engagement_SA__c=null);
			}
			return opportunity;
		}
	}

	static ProcessInstance processInstance {
		get {
			if(processInstance == null) {
				Set<Id> targetObjectIds = new Set<Id>();
				for(ProcessInstance pi : [
					select
						Id,
						TargetObjectId,
						SystemModstamp,
						(	select Id
							from Workitems
							where ActorId != :UserInfo.getUserId()
								and Actor.IsActive = true
							limit 1)
					from ProcessInstance
					where TargetObjectId in (select Id from Opportunity)
						and CreatedBy.IsActive = true
						and CreatedById != :UserInfo.getUserId()
					order by CreatedDate desc
					limit 200 ] )
				{
					if(! targetObjectIds.contains(pi.TargetObjectId)) {
						targetObjectIds.add(pi.TargetObjectId);
						if(! pi.Workitems.isEmpty()) {
							processInstance = pi;
							break;
						}
					}
				}
			}
			return processInstance;
		}
		set;
	}

	static void upsertOpportunity(Opportunity opp) {
			AbstractTrigger.setBooleanSettings('Opp_Before.',false);
			AbstractTrigger.setBooleanSettings('Opp_After.',false);
			upsert opportunity;
			AbstractTrigger.setBooleanSettings('Opp_Before.',true);
			AbstractTrigger.setBooleanSettings('Opp_After.',true);
	}

	// fake the pending stage
	static void pending(Opportunity opp) {
		opp.StageName = 'Pending';
		upsertOpportunity(opp);
	}

	static Id getOpportunityId() {
		if(opportunity.Id == null) {
			upsertOpportunity(opportunity);
		}
		return opportunity.Id;
	}

	static Opportunity_ApprovalReqDiscussContExtn createController(Opportunity opp) {
		ApexPages.StandardController sc = new ApexPages.StandardController(opp);
		return new Opportunity_ApprovalReqDiscussContExtn(sc);
	}

	@isTest
	static void limitTest() {
		Opportunity_ApprovalReqDiscussContExtn controller = createController(opportunity);
		Test.startTest();
		Integer limit1 = controller.feedStagePendingCommentsLimit;
		System.assert(limit1 > 0,'Expected a limit greater than 0');
		System.assertEquals(limit1,controller.feedStagePendingCommentsLimit);
		System.assert(controller.getCanShowMoreFeedStagePendingComments(),'Expected more limits');
		while(controller.getCanShowMoreFeedStagePendingComments()) {
			controller.showMoreFeedStagePendingComments();
			Integer limit2 = controller.feedStagePendingCommentsLimit;
			System.assert(limit2 > limit1,'Expected an increased limit');
			System.assertEquals(limit2,controller.feedStagePendingCommentsLimit);
			limit1 = limit2;
		}
		controller.showMoreFeedStagePendingComments();
		System.assertEquals(limit1,controller.feedStagePendingCommentsLimit);
		Test.stopTest();
	}

	@isTest
	static void commentsTest1() {
		getOpportunityId();
		Opportunity_ApprovalReqDiscussContExtn controller = createController(opportunity);
		Test.startTest();
		// check the initial values
		System.assertEquals(null,controller.feedStagePendingComment.FeedItemId,'Unexpected FeedItemId');
		System.assert(controller.feedStagePendingIds.isEmpty(),'Unexpected FeedItemId\'s');
		System.assert(controller.getFeedStagePendingComments().isEmpty(),'Unexpected comments');
		Test.stopTest();
	}

	@isTest(SeeAllData=true)
	static void commentsTest2() {
		for(OpportunityFeed oppFeed : [
				select
					ParentId,
					(	select FeedItemId, FieldName, NewValue
						from FeedTrackedChanges
						order by Id 
						limit 1)
				from OpportunityFeed
				where TYPE = 'TrackedChange'
				order by CreatedDate desc, Id desc
				limit 100 ] )
		{
			if(oppFeed.FeedTrackedChanges != null && ! oppFeed.FeedTrackedChanges.isEmpty()) {
				for(FeedTrackedChange ftc : oppFeed.FeedTrackedChanges) {
					Opportunity_ApprovalReqDiscussContExtn.fieldName = ftc.FieldName;
					Opportunity_ApprovalReqDiscussContExtn.PENDING_PLV = (ftc.NewValue != null)?String.valueOf(ftc.NewValue):null;
					Opportunity_ApprovalReqDiscussContExtn controller = createController(new Opportunity(Id=oppFeed.ParentId));
					Test.startTest();
					System.assertNotEquals(null,controller.feedStagePendingComment.FeedItemId,'Expected FeedItemId');
					System.assert(! controller.feedStagePendingIds.isEmpty(),'Expected FeedItemId\'s');
					Integer i=controller.getFeedStagePendingComments().size();
					// now save a comment, and see what happens
					String commentBody = 'This is a comment.\nThis is just for testing.\n';
					controller.feedStagePendingComment.CommentBody = commentBody;
					controller.saveFeedStagePendingComment();
					System.assertNotEquals(null,controller.feedStagePendingComment.FeedItemId,'Expected FeedItemId');
					System.assert(! controller.feedStagePendingIds.isEmpty(),'Expected FeedItemId\'s');
					List<FeedComment> comments = controller.getFeedStagePendingComments();
					Test.stopTest();
					System.assertEquals((controller.feedStagePendingCommentsLimit > i)?i+1:i,comments.size(),'Expected a new comment');
					System.assertEquals(commentBody.trim(),comments[0].CommentBody.trim());
					break;
				}
				break;
			}
		}
	}

	@isTest(SeeAllData=true)
	static void getApprovalAddressesTest() {
		if(processInstance != null) {
			Integer i = Opportunity_ApprovalReqDiscussContExtn.getApprovalAddresses(processInstance.TargetObjectId).size();
			System.assert(i > 1,'Expected at least two e-mail addresses');
		}
	}
}