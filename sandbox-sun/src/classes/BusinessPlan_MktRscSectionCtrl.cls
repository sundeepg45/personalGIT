public without sharing class BusinessPlan_MktRscSectionCtrl {

    public	 ID			bpId {get; private set; }
    public	Contact[]	contactList {get; private set; }


	public BusinessPlan_MktRscSectionCtrl(ApexPages.StandardController controller)  { 
		bpId = controller.getRecord().Id;
	} 

    public Contact[] getContacts() {
        if (contactList == null) {
            Set<String> selected = PartnerUtil.getStringFieldSet([select Contact__c from BusinessPlan_MktResource__c where Business_Plan__c = :bpId], 'Contact__c');
            contactList = [
                select	Id, Name, Phone, Email, Title
                from	Contact
                where	Id in :selected
                order by Name
            ];
        }
        return contactList;
    }
}