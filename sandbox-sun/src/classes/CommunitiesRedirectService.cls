public class CommunitiesRedirectService {

	public String commURL { get; set; }
	
	public CommunitiesRedirectService(){
		CommUtils__c commUtil = CommUtils__c.getInstance('URL');
		commURL = commUtil.CommunityURL__c;
    }
}