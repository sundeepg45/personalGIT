public with sharing class RequalSchViewController {
    public ApexPages.StandardController controller {
        get;
        set;
    }
    public String dateParam {get; set; }
    public String status {get; set; }

    public RequalSchViewController() {
    }
	
    public RequalSchViewController(ApexPages.StandardController controller) {
        this.controller = controller;
    }

	public PageReference runJob() {   
		PartnerRequal_ActionsSchClass c = new PartnerRequal_ActionsSchClass();
		c.dateOverride = Date.parse(dateParam);
		c.run(); 
		status = 'done';
		return null;
	}
}