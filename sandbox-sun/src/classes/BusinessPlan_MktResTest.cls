@IsTest(SeeAllData=true)
public class BusinessPlan_MktResTest {

    static testmethod void editScreenTest() {
        
   		SFDC_Channel_Account_Plan__c bp = [select Id, Partner_Name__c from SFDC_Channel_Account_Plan__c limit 1];
        ApexPages.currentPage().getParameters().put('bpId', bp.Id);
        BusinessPlan_MktResourcesController ctrl = new BusinessPlan_MktResourcesController();
        Contact c = PartnerTestUtils.makeContact(bp.Partner_Name__c, 'Weeping Angel');
        c.PrimaryJobFunction__c = 'Marketing';
        insert c;
        ctrl.getContacts();
        ApexPages.currentPage().getParameters().put('checkbox_' + c.Id, 'on');
        ctrl.saveContacts();
        PageReference ref = ctrl.toPlan();
    }

    static testmethod void sectionTest() {
   		SFDC_Channel_Account_Plan__c bp = [select Id from SFDC_Channel_Account_Plan__c limit 1];
        ApexPages.StandardController stdctrl = new ApexPages.StandardController(bp);
        BusinessPlan_MktRscSectionCtrl ctrl = new BusinessPlan_MktRscSectionCtrl(stdctrl);
        ctrl.getContacts();
    }
}