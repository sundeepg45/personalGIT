public with sharing class MSSectionListController {
	private MSController	ctrl;
	private String			key;


	public void setCtrl(MSController c) {
		ctrl = c;
	}
	
	public MSController getCtrl() {
		return ctrl;
	}

	public void setSectionKey(String sk) {
		System.debug('****[debug]**** setting sectionKey to ' + sk);
		key = sk;
	}
	
	public String getSectionKey() {
		return key;
	}

	public PartnerUtil.ContentPair[] getSectionContent() {
		System.debug('****[debug]**** sectionlistcontroller size=' + ctrl.sectionContent.size());
		return ctrl.sectionContent;
	}
	
	public void setSectionContent(PartnerUtil.ContentPair[] c) {
	}
	
    @IsTest(SeeAllData=true) static void myUnitTest() {
    }
}