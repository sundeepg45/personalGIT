public with sharing class ManageTrackController {

    public Id selectedTrack { get; set; }

    public ManageTrackController() {
    }
    
    public Boolean getIsSideNavRedirect(){
        return ApexPages.CurrentPage().getParameters().get('sidenavredirect') == 'true' && selectedTrack == null;
    }
   
    public User me {
        get {
            return [
                  select Id,
                         FederationIdentifier,
                         Contact.Id,
                         Contact.AccountId,
                         IsPartnerAdmin__c
                    from User
                   where Id = :UserInfo.getUserId()
                   limit 1];
        }
    }
    
    public List<Contact_Track__c> getContactTracks() 
    {
        List<Contact_Track__c> tracks = [
                    select Id,
                        Partner_Track__r.Partner_Function__c,
                        Partner_Track__r.Product_of_Interest__c,
                        Primary__c
                    from Contact_Track__c 
                    where Contact_Track__c.Contact__c = :me.Contact.Id
                    order by Primary__c desc];
        return tracks;
    }

    public List<SelectOption> getAvailableTracks() 
    {
        List<SelectOption> options = new List<SelectOption>();
        
        options.add(new SelectOption('', Label.Track_Select_One));
        
        List<Contact_Track__c> ctracks = getContactTracks();
        Set<Id> trackIds = new Set<Id>();
        for (Contact_Track__c track : ctracks) 
        {
            trackIds.add(track.Partner_Track__c);
        }
        
        List<PartnerTrack__c> tracks = [
                    select Id,
                        Track__c,
                        Partner_Function__c,
                        Product_of_Interest__c
                    from PartnerTrack__c
                    where Id not in :trackIds
                    and Is_Partner_Visible__c = True
                    and Product_of_Interest__c != 'All Products'
                    and Product_of_Interest__c != 'Cloud'
                    and Product_of_Interest__c != 'Middleware'
                    and Product_of_Interest__c != 'Platform'
                    and Product_of_Interest__c != 'Storage'
                    and Product_of_Interest__c != 'Virtualization'
                    order by Partner_Function__c, Product_of_Interest__c];
                    
                    
        for( PartnerTrack__c pt : tracks){
            options.add(new SelectOption(pt.id, pt.Partner_Function__c + ' / ' + pt.Product_of_Interest__c));
        }
                    
        return options;
    }
   
    
    public PageReference save()
    {
        if (selectedTrack != null){
            Contact_Track__c ct = new Contact_Track__c();
            ct.Partner_Track__c = selectedTrack;
            ct.Primary__c = getContactTracks().size() == 0;
            ct.Contact__c = me.Contact.Id;
            insert ct;
        }
        return null;
    }
   
}