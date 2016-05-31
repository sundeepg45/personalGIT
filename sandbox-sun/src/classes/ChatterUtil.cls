/**
 * This is a static Chatter util class
 *
 * @author Scott Coleman <scoleman@redhat.com>
 * @version 2013-04-11
 * 2013-04-11 - created
 */
public with sharing class ChatterUtil {

	public static void postMessage(Id objectId, String message) {
		FeedItem item = new FeedItem(ParentId=objectId, Body=message);
		insert item;
	}

	public static void postMessage(Id objectId, String message, List<User> mentions, String sessionId) {
		String salesforceHost = System.Url.getSalesforceBaseURL().toExternalForm();
		String url =  salesforceHost + '/services/data/v27.0/chatter/feeds/record/' + objectId + '/feed-items';
		HttpRequest req = new HttpRequest();
		req.setMethod('POST');
		req.setEndpoint(url);
		req.setHeader('Content-type', 'application/json');
		req.setHeader('Authorization', 'OAuth ' + sessionId);
		String body = '{ "body" : { "messageSegments" : [ ';
		body = body + '{ "type": "text",  "text" : "' + ' ' + message +  ' " }';
		for(User mention : mentions) {
			body = body + ', { "type": "mention", "id" : "' + mention.Id + '" }, { "type": "text",  "text" : " " }';
		}
		body = body + ' ] } }';
		System.debug(body);
		req.setBody(body);
		Http http = new Http();
		if(!test.isRunningTest()) {
			HTTPResponse res = http.send(req);
		}
	}

	/* methods that support use of Chatter groups */
	
	public static Id createGroup(String groupName, Boolean isPrivate) {
		String groupType;
		if(isPrivate) {
			groupType='Private';
		}
		else {
			groupType='Public';
		}
		CollaborationGroup newGroup = new CollaborationGroup(Name=groupName, CollaborationType=groupType);
		insert newGroup;
		return newGroup.Id;
	}

	public static CollaborationGroup getGroup(Id groupId) {
		CollaborationGroup chatterGroup;
		List<CollaborationGroup> chatterGroups = [
			select
				Id, Name
			from CollaborationGroup
			where Id = :groupId ];
		if(chatterGroups.size()>0) {
			chatterGroup = chatterGroups[0];
		}
		return chatterGroup;
	}

	public static List<CollaborationGroup> findGroup(String groupName) {
		String searchName = '%'+groupName+'%';
		List<CollaborationGroup> chatterGroups = new List<CollaborationGroup>([
			select
				Id, Name
			from CollaborationGroup
			where Name LIKE :searchName]);
		return chatterGroups;
	}

	public static void deleteGroup(Id groupId) {
		delete new CollaborationGroup(Id=groupId);
	}

	public static void addUsersToGroup(Id groupId, List<User> users) {
		List<CollaborationGroupMember> members = new List<CollaborationGroupMember>();
		for(User user : users) {
			members.add(new CollaborationGroupMember(MemberId = user.Id, CollaborationGroupId = groupId));
		}
		if(members.size()>0) {
			insert members;
		}
	}

	public static void deleteUsersFromGroup(Id groupId, List<User> users) {
		Set<Id> userIds = new Set<Id>();
		for(User user : users) {
			userIds.add(user.Id);
		}
		List<CollaborationGroupMember> members = [
			select
				Id
			from CollaborationGroupMember
			where CollaborationGroupId = :groupId
			and MemberId in :userIds ];
		if(members!=null && members.size()>0) {
			delete members;
		}
	}

	public static void postGroupMessage(Id groupId, String message) {
		postMessage(groupId, message);
	}
}