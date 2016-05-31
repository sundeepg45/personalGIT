public with sharing class TabUIControllerExtension {
    final ApexPages.StandardController controller;
    final SObject obj;
    
    //these hard-coded properties provided just to support our prototype
	public String strategyId {
		get {
			String retval;
			if(strategy != null) {
				retval = strategy.Id;
			}
			return retval;			
		}
	}
	public StrategicPlan_Strategy__c strategy {
		get {
			if(strategy == null) {
				List<SObject> objects = [SELECT Id FROM StrategicPlan_Strategy__c WHERE StrategicPlan__c = :obj.Id ORDER BY CreatedDate LIMIT 1];
				if(objects != null && objects.size() > 0) {
					strategy = (StrategicPlan_Strategy__c)objects[0];
				}
			}
			return strategy;		
		}
		set;	
	}
    public String solutionId {
        get {
            List<SObject> objects =[SELECT Id FROM StrategicPlan_Solution__c WHERE Strategy__r.StrategicPlan__c = :obj.Id ORDER BY CreatedDate LIMIT 1];
            String retval;
            if(objects != null && objects.size() > 0) {
                retval = objects[0].Id;
            }
            return retval;
        }
    }

    public TabUIControllerExtension(ApexPages.StandardController stdController) {
        controller = stdController;
        obj = stdController.getRecord();
    }
}