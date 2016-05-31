public class BusinessPlan_MktResourcesController {

    public class ContactInfo {
        public Contact	info {get; private set; }
        public Boolean	selected {get; private set; }
    }

   	private	ID			bpId;
    private ID			accountId;
    public	ContactInfo[]	contactList {get; private set; }
    public	Boolean		isLocked {get; private set; }
    
    public BusinessPlan_MktResourcesController() {
        String tmpid = (String) ApexPages.currentPage().getParameters().get('bpid');
        System.debug('*****[debug]***** tmpid=' + tmpid);
        if (tmpid != null) {
	        bpId = (ID) tmpid;
            SFDC_Channel_Account_Plan__c bp = [select Partner_Name__c, RecordTypeId from SFDC_Channel_Account_Plan__c where Id = :bpId];
	        isLocked = [select DeveloperName from RecordType where Id = :bp.RecordTypeId].DeveloperName == 'Business_Plan_Locked';
            accountId = bp.Partner_Name__c;
        }
    }

    public ContactInfo[] getContacts() {
        if (contactList == null) {
            Contact[] cList = [
                select	Id, Name, Phone, Email, Title
                from	Contact
                where	AccountId = :accountId
                order by Name
            ];
            Set<String> selected = PartnerUtil.getStringFieldSet([select Contact__c from BusinessPlan_MktResource__c where Business_Plan__c = :bpId], 'Contact__c');
            contactList = new List<ContactInfo>();
            for (Contact c : cList) {
                ContactInfo ci = new ContactInfo();
                ci.info = c;
                ci.selected = selected.contains(c.Id);
                contactList.add(ci);
            }
        }
        return contactList;
    }

    public PageReference saveContacts() {
        BusinessPlan_MktResource__c[] res = [select Id, Contact__r.Id from BusinessPlan_MktResource__c where Business_Plan__c = :bpId];
        Map<String,String> params = ApexPages.currentPage().getParameters();
        BusinessPlan_MktResource__c[] toInsert = new List<BusinessPlan_MktResource__c>();
        BusinessPlan_MktResource__c[] toKeep = new List<BusinessPlan_MktResource__c>();

        for (String key : params.keySet()) {
            if (key.startsWith('checkbox_')) {
                ID contactId = key.substring(9);
                BusinessPlan_MktResource__c found = null;
                for (BusinessPlan_MktResource__c bpmr : res) {
                    if (bpmr.Contact__r.Id == contactId) {
                        found = bpmr;
                        break;
                    }
                }
                Boolean isOn = params.get(key).equals('on');
                if (isOn) {
                    toInsert.add(new BusinessPlan_MktResource__c(Business_Plan__c = bpId, Contact__c = contactId));
                }
            }
        }
        delete res;
        if (!toInsert.isEmpty()) {
            insert toInsert;
            Contact[] contactsToUpdate = new List<Contact>();
            for (BusinessPlan_MktResource__c bpmr : toInsert) {
                contactsToUpdate.add(new Contact(Id = bpmr.Contact__c, PrimaryJobFunction__c = 'Marketing'));
            }
            update contactsToUpdate;
        }
        contactList = null;
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Changes saved'));
        return null;
    }
    
    public PageReference toPlan() {
        PageReference ref = new PageReference('/' + bpId);
        ref.setRedirect(true);
        return ref;
    }
 
}