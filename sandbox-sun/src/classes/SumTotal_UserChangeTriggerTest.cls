@isTest(SeeAllData=true)
private class SumTotal_UserChangeTriggerTest {
    static testmethod void testPartnerUser() {
        // have to use an existing user here to avoid SF "setup object" errors
        User u = [select Id from User where Contact.Account.IsPartner = true and IsActive = true and UserType != 'Standard' limit 1];
        u.SumTotal_ID__c = 'testing123';
        u.FirstName = 'Gus';
        update u;
        
        //SumTotal_Request__c[] request = [select Id from SumTotal_Request__c where User__c = :u.Id];
       //System.assert(request.size() == 1, 'expected to find a sumtotal request in the queue');
    }

    static testmethod void testCAMUser() {
        // try to find a suitable user in a sample of 50
        User[] cams = [select Id from User where IsActive = true and UserType = 'Standard' limit 50];
        Contact[] contacts = [select Id, OwnerId from Contact where OwnerId in :PartnerUtil.getIdSet(cams)];
        // just use the first contact
        if (contacts.size() == 0) {
            // hit and miss - we missed
            return;
        }
		Contact c = contacts.get(0);
        
        User cuser = [select Id from User where Id = :c.OwnerId];
        cuser.SumTotal_ID__c = 'nonblank';
        update cuser;

        User cam = new User(Id = c.OwnerId, Sumtotal_ID__c = 'testing123');
        update cam;
        cam.FirstName = 'Gus';
        update cam;
        
        //SumTotal_Request__c[] request = [select Id from SumTotal_Request__c where User__c = :cuser.Id];
        //System.assert(request.size() == 1, 'expected to find sumtotal request for all cam user, found ' + request.size());
    }

}