public without sharing class QA_ST_UserInfoController {

    public	STConnector.STUser	stuser {get; private set; }
    public	User				sfuser {get; private set; }
    public	String				jobs {get; private set; }
	private	STConnector			client;


    public QA_ST_UserInfoController() {
        ID userId = (ID) ApexPages.currentPage().getParameters().get('id');
        String flush = ApexPages.currentPage().getParameters().get('flush');
        if (userId != null) {
			client = new STConnector();
            sfuser = client.getUser(userId);
            if (sfuser != null) {
                if (flush != null && flush == 'true') {
                    client.processQueue();
                }
                stuser = client.getUserInfo(userId);
                if (stuser.status == 'fail') {
                    stuser = null;
                }
                if (stuser != null && sfuser.ContactId != null) {
                    Contact_Track__c[] tracks = [select Track__c, Primary__c
                                                 from	Contact_Track__c
                                                 where	Contact__c = :sfuser.ContactId];
                    String[] names = new List<String>();
                    for (Contact_Track__c track : tracks) {
                        String  name = track.Track__c;
                        if (track.Primary__c) name = name + ' (Primary)';
                        names.add(name);
                    }
                    jobs = PartnerUtil.joinArray(names, ',');
                }
                else {
                    jobs = sfuser.Channel_Role__c;
                }
            }
        }
    }
}