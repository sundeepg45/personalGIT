public with sharing class MSSectionController {

	private MSController	ctrl;
	private String			key;
	private	String			annotation;
	private	Boolean			loaded;
	public PartnerUtil.ContentPair[] sectionContent;


	public MSSectionController() {
		loaded = false;
		sectionContent = null;
	}


	public PartnerUtil.ContentPair[] getSectionContent() {
		if (sectionContent == null) {
			initData();
		}
		return sectionContent;
	}

	private void initData() {
		System.debug('****[debug]**** initData called');
		if (!loaded && ctrl != null) {
			if (key != null) {
				ctrl.setSectionKey(key);
			}
			if (annotation != null) {
				ctrl.setAnnotationFilter(annotation);
			}
			sectionContent = ctrl.sectionContent;
			if (sectionContent != null)
				System.debug('*****[debug]***** section controller content=' + sectionContent.size());
			else
				System.debug('*****[debug]***** section controller content is NULL');
			loaded = true;
		}
	}

	public void setAnnotation(String an) {
		annotation = an;
	}

	public String getAnnotation() {
		return annotation;
	}

	public void setSectionKey(String sk) {
		key = sk;
	}
	
	public String getSectionKey() {
		return key;
	}

	public MSController getCtrl() {
		return ctrl;
	}

	public void setCtrl(MSController c) {
		ctrl = c;
	}

	public Boolean canRender {
		get {
			getSectionContent();
			return !(sectionContent == null || sectionContent.size() == 0);
		}
	}

	
    @IsTest(SeeAllData=true) static void myUnitTest() {
    	MSSectionController ctrl = new MSSectionController();
    	Boolean b = ctrl.canRender;
    	//ctrl.pageContent = [select id,Section__c from RH_Content__c limit 2];
    }
}