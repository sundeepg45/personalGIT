/**
 * This is controller extension to allow finance to have a discussion via chatter and e-mail
 * with the submitters of zero value opportunities without rejecting the approval requests.
 *
 * @version 2014-04-09
 * @author Bill Riemers <briemers@redhat.com>
 * 2014-04-09 - change zero dollar order to zero value opportunity
 * 2014-04-07 - Created
 */
public without sharing class Opportunity_ApprovalReqDiscussContExtn {
	// the controller passed to the constructor
	private ApexPages.StandardController controller;
	// iterator of limit values to step through each time a user presses show more
	private List<Integer> limitValues = new List<Integer>{ 5,10,20,50,100,200,500,1000 };
	@TestVisible
	private static String fieldName = 'Opportunity.StageName';
	@TestVisible
	private static String PENDING_PLV = 'Pending';

	/**
	 * The EmailTemplate that will be used for the message.
	 */
	@TestVisible
	private static EmailTemplate APPROVAL_REQUEST_DISCUSSION_EMAIL_TEMPLATE {
		get {
			if(APPROVAL_REQUEST_DISCUSSION_EMAIL_TEMPLATE == null) {
				APPROVAL_REQUEST_DISCUSSION_EMAIL_TEMPLATE = new EmailTemplate(
					Subject='Zero Value Order Approval Discussion for {!Opportunity.Name}',
					Body='A approval request comment has been added to a Zero Value Order with the following values:\n\n'
						+ 'Account Name: {!Opportunity.Account}\n'
						+ 'Opportunity Name: {!Opportunity.Name}\n'
						+ 'Opportunity Number: {!Opportunity.OpportunityNumber__c}\n\n'
						+ '{!Opportunity.Link}\n\n'
						+ 'Description of Request (Business Justification):\n'
						+ '{!Opportunity.Description}\n\n'
						+ 'Comment:\n'
						+ '{CommentBody}\n\n');
				for(EmailTemplate et : [
					select Name, Body, HtmlValue, Subject, Description
					from EmailTemplate
					where
						Folder.Type = 'Email'
						and DeveloperName = 'ZeroValueOpportunity_ApprovalDiscussion'
						and IsActive = true
					order by LastModifiedDate desc
					limit 1 ] )
				{
					APPROVAL_REQUEST_DISCUSSION_EMAIL_TEMPLATE = et;
				}
			}
			return APPROVAL_REQUEST_DISCUSSION_EMAIL_TEMPLATE;
		}
		set;
	}

	/**
	 * Method used to substitute template values in the body and subject.
	 * @param opp the opportunity to substitute values from
	 * @param text the string to substitute values in
	 * @param commentBody value to substitute {CommentBody} with
	 * @return substituted string
	 */
	@TestVisible
	private static String substituteValues(Opportunity opp,String text,String commentBody) {
		return text
			.replace('{CommentBody}',''+commentBody)
			.replace('{!Opportunity.Account}',''+opp.Account.Name)
			.replace('{!Opportunity.Description}',''+opp.Description)
			.replace('{!Opportunity.Name}',''+opp.Name)
			.replace('{!Opportunity.OpportunityNumber__c}',''+opp.OpportunityNumber__c)
			.replace('{!Opportunity.Link}',''+opp.CreatedBy.EnterpriseServerUrl__c+opp.Id);
	}	

	/**
	 * Controller Extension constructor.
	 * @param controller the standard controller
	 */
	public Opportunity_ApprovalReqDiscussContExtn(ApexPages.StandardController controller) {
		this.controller = controller;
		feedStagePendingCommentsLimit = limitValues.remove(0);
	}

	/**
	 * The current limit used to query comments.
	 */
	public Integer feedStagePendingCommentsLimit {
		get;
		set;
	}

	/**
	 * Query the list of previously posted comments.
	 * @return comments
	 */
	public List<FeedComment> getFeedStagePendingComments() {
		List<FeedComment> retval = new List<FeedComment>();
		System.debug('feedStagePendingIds='+feedStagePendingIds);
		System.debug('limit='+feedStagePendingCommentsLimit);
		for(FeedComment fc : [
			select
				CreatedBy.FirstName,
				CreatedBy.LastName,
				CreatedDate,
				CommentBody,
				FeedItemId,
				RelatedRecordId
			from FeedComment
			where FeedItemId in :feedStagePendingIds
			order by CreatedDate desc, Id desc
			limit :feedStagePendingCommentsLimit ] )
		{
			retval.add(fc);
		}
		return retval;
	}

	/**
	 * A new FeedComment that may be inserted.
	 */
	public FeedComment feedStagePendingComment {
		get {
			if(feedStagePendingComment == null) {
				feedStagePendingComment = new FeedComment(FeedItemId=feedItemId);
			}
			return feedStagePendingComment;
		}
		set;
	}

	private Id feedItemId {
		get {
			feedStagePendingIds.isEmpty();
			return feedItemId;
		}
		set;
	}

	/**
	 * Query the list of all FeedItemId's that correspond to a field change of stage to pending.
	 * The feedStagePendingComment will be update to have the most recent FeedItemId.
	 * @return feedStagePendingIds
	 */
	@TestVisible
	private Set<Id> feedStagePendingIds {
		get {
			if(feedStagePendingIds == null) {
				final Id oppId = controller.getId();
				feedStagePendingIds = new Set<Id>();
				Id xfeedItemId = null;
				for(OpportunityFeed oppFeed : [
					select
						(	select FeedItemId, FieldName, NewValue
							from FeedTrackedChanges
							order by Id desc
							limit 100 )
					from OpportunityFeed
					where ParentId = :oppId
						and TYPE = 'TrackedChange'
					order by CreatedDate desc, Id desc
					limit 5000 ] )
				{
					for(FeedTrackedChange ftc : oppFeed.feedTrackedChanges) {
						System.debug('ftc.FieldName=""'+ftc.FieldName+'",ftc.NewValue="'+ftc.NewValue+'"');
						if(ftc.FeedItemId != null && (fieldName == null || ftc.FieldName == fieldName ) && (PENDING_PLV == null || String.valueOf(ftc.NewValue) == PENDING_PLV)) {
							feedStagePendingIds.add(ftc.FeedItemId);
							if(xfeedItemId == null) {
								xfeedItemId = ftc.FeedItemId;
							}
						}
					}
				}
				feedItemId = xfeedItemId;
			}
			return feedStagePendingIds;
		}
		set;
	}

	/**
	 * Find out if there is another limit value available.
	 * @return true if another limit value is available
	 */
	public Boolean getCanShowMoreFeedStagePendingComments() {
		return ! limitValues.isEmpty();
	}

	/**
	 * Query the e-mail addresses for all the approvers and the requester.
	 * @param oppId to query
	 * @return list of e-mail addresses
	 */
	@TestVisible
	private static List<String> getApprovalAddresses(final Id oppId) {
		Set<String> retval = new Set<String>{ UserInfo.getUserEmail() };
		for(ProcessInstance processInstance : [
			select
				CreatedBy.Email,
				CreatedBy.IsActive,
				(	select
						Actor.Email,
						Actor.IsActive,
						OriginalActor.Email,
						OriginalActor.IsActive
					from Workitems )
			from ProcessInstance 
			where TargetObjectId = :oppId
			order by CreatedDate desc
			limit 1000 ])
		{
			if(processInstance.Workitems != null && ! processInstance.Workitems.isEmpty()) {
				if(processInstance.CreatedBy != null && processInstance.CreatedBy.IsActive) {
					retval.add(processInstance.CreatedBy.Email);
				}
				for(ProcessInstanceWorkitem workitem : processInstance.Workitems) {
					if(workitem.Actor != null && workitem.Actor.IsActive) {
						retval.add(workitem.Actor.Email);
					}
					if(workitem.OriginalActor != null && workitem.OriginalActor.IsActive) {
						retval.add(workitem.OriginalActor.Email);
					}
				}
				break;
			}
		}
		return new List<String>( retval );
	}

	/**
	 * Save the feedStagePendingComment and e-mail users returned by getApprovalAddresses.
	 * @return null so the page will be reloaded with the new comment.
	 */
	public PageReference saveFeedStagePendingComment() {
		try {
			Opportunity opp = [
				select
					Account.Name,
					CreatedBy.EnterpriseServerUrl__c,
					Description,
					Name,
					OpportunityNumber__c
				from Opportunity
				where Id = :controller.getId() ];
			Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();  
			mail.setToAddresses(getApprovalAddresses(opp.Id));
			mail.setSubject(substituteValues(opp,APPROVAL_REQUEST_DISCUSSION_EMAIL_TEMPLATE.Subject,feedStagePendingComment.CommentBody));
			mail.setPlainTextBody(substituteValues(opp,APPROVAL_REQUEST_DISCUSSION_EMAIL_TEMPLATE.Body,feedStagePendingComment.CommentBody));
			insert feedStagePendingComment;
			feedStagePendingComment = null;
			Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{mail});
		}
		catch(Exception ex) {
			ApexPages.addMessages(ex);
		}
		return null;
	}

	/**
	 * Increment feedStagePendingCommentsLimit to the next limitValues entry.
	 * @return null so the page will be reloaded with the new comment.
	 */
	public PageReference showMoreFeedStagePendingComments() {
		if(! limitValues.isEmpty()) {
			feedStagePendingCommentsLimit = limitValues.remove(0);
		}
		return null;
	}
}