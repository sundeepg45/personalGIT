/**
 * This class is used by Opportunity_ManageParters, which runs without sharing,
 * to at least verify that a user has access to edit an Opportunity before
 * the calling class lets them add partners to the Opp.
 *
 * @author Scott Coleman <scoleman@redhat.com>
 * @version 2012-07-31
 */
public with sharing class Opportunity_ManagePartners_AsUser {
	public boolean checkPermissions(SObject o) {
		UserRecordAccess access = [
			SELECT RecordId,
				HasEditAccess
     		FROM UserRecordAccess
     		WHERE UserId = :UserInfo.getUserId()
     		  	AND RecordId = :o.Id];
    	return access.HasEditAccess;
	}
}