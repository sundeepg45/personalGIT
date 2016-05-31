@isTest(SeeAllData=true)
private class RegistrationHomeControllerTest {

	//
	// There isn't much actual validation to be done here since setting up data to conform to all 4 lead types would be massive
	//
    static testMethod void myUnitTest() {
        RegistrationHomeController ctrl = new RegistrationHomeController();
        ctrl.dealRegLeadListSetup();
        Lead[] leads = ctrl.getLeads();
        ctrl.salesLeadListSetup();
        leads = ctrl.getLeads();
        ctrl.teamingListSetup();
        leads = ctrl.getLeads();
        ctrl.registerDeal();
        ctrl.registerPar();
        ctrl.registerSales();
        ctrl.registerTeaming();
        
        ctrl.getHasDealRegAccess();
        ctrl.getHasParAccess();
        ctrl.getHasTeamingAccess();
    }
}