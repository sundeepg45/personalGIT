public class LMSHomePageComponentController{
    public User me { get; set; }
    public Contact_Track__c contactTrack { get; set; }
    public Boolean isAdmin { get; set; }

    public LMSHomePageComponentController()
    {
        me = [select Id, Username, SumTotal_ID__c, Profile.Name, ContactId, FederationIdentifier from User where Id = :UserInfo.getUserId()];
        isAdmin = me.Profile.Name == 'Administrator - Level 2' || me.Profile.Name == 'Administrator - Level 1';
        if (me.ContactId != null){
	        List<Contact_Track__c> tracks = [
                	select 
                		Partner_Track__r.Partner_Function__c, 
                		Partner_Track__r.Product_of_Interest__c 
                	from Contact_Track__c 
                	where 
                		Contact__c = :me.ContactId 
                		and Primary__c = True
            ];
            if (tracks.size() > 0){
	            contactTrack = tracks[0];
            }
        }
    }
    
    public Boolean getHasTrack(){
        return contactTrack != null;
    }
    
    public Boolean getAddingTrack(){
    	return ApexPages.CurrentPage().getParameters().get('addingtrack') == 'true' || isAdmin;
    }
}