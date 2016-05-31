trigger SumTotal_UpdateTrack on Contact_Track__c (after insert, after delete) {

	User[] users = null;

    if (Trigger.isDelete) {
        users = [
            select	Id, ContactId, SumTotal_ID__c
            from	User
            where	ContactId in :PartnerUtil.getStringFieldSet(Trigger.old, 'Contact__c')
            and		SumTotal_ID__c != null
            and		IsActive = True
        ];
    }
    else {
        users = [
            select	Id, ContactId, SumTotal_ID__c
            from	User
            where	ContactId in :PartnerUtil.getStringFieldSet(Trigger.new, 'Contact__c')
            and		SumTotal_ID__c != null
            and		IsActive = True
        ];
    }    

    if (users == null || users.isEmpty()) {
        return;
    }
    ID[] idlist = new List<ID>();
    for (User u : users) idlist.add(u.Id);
    STConnector.enqueue(idlist, STConnector.ACTION_UPDATE_USER);
}