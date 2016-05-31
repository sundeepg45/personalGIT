public without sharing class PCSearchContext {

	private PCSearchForm__c	form;

	public PCSearchContext(PCSearchForm__c theForm) {
		form = theForm;
		if (form.PageSize__c == null) {
			form.PageSize__c = PFUtils.getDefaultPicklistValue(PCSearchForm__c.PageSize__c.getDescribe().getPicklistValues());
		}
		if (form.NameOrKeywords__c == null) {
			form.NameOrKeywords__c = '';
		}
		else {
			form.NameOrKeywords__c = form.NameOrKeywords__c.trim();
		}
	}

	public Integer pageSize {
		get {
			return Integer.valueOf(form.PageSize__c);
		}
	}

	public String keywords {
		get {
			return scrub(form.NameOrKeywords__c);
		}
	}

	public String partnerId {
		get {
			return form.PartnerId__c;
		}
	}

	public String softwareCategory {
		get {
			if (!PFUtils.isEmpty(form.Software_Category__c) && form.Software_Category__c == 'All') {
				return null;
			}
			return form.Software_Category__c;
		}
	}

    public String RHEL {
        get {
            if (!PFUtils.isEmpty(form.Red_Hat_Enterprise_Linux__c) && form.Red_Hat_Enterprise_Linux__c == 'All') {
                return null;
            }
            return form.Red_Hat_Enterprise_Linux__c;
        }
    }

	public String JBoss {
        get {
            if (!PFUtils.isEmpty(form.Red_Hat_JBoss_Middleware__c) && form.Red_Hat_JBoss_Middleware__c == 'All') {
                return null;
            }
            return form.Red_Hat_JBoss_Middleware__c;
        }
    }

	public String RHEV {
		get {
            if (!PFUtils.isEmpty(form.Red_Hat_Enterprise_Virtualization__c) && form.Red_Hat_Enterprise_Virtualization__c == 'All') {
                return null;
            }
            return form.Red_Hat_Enterprise_Virtualization__c;
        }
	}

	public String RHOS {
		get {
            if (form.OpenStack_Platform__c == 'All') {
                return null;
            }
            return form.OpenStack_Platform__c;
        }
	}

    public String globalRegion {
        get {
            if (!PFUtils.isEmpty(form.Global_Region__c) && form.Global_Region__c == 'All') {
                return null;
            }
            return form.Global_Region__c;
        }
    }

	static private String scrub(String str) {
		if (str == null) {
			return str;
		}
		return str.replaceAll('\\\\', '');
	}
}