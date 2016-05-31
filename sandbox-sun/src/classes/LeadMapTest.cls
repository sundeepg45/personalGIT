/**
* Class Name:LeadMapTest 
* Description:Test Class created for LeadMap business Class.
* Modificaton History:
* Modified By :Ratan Sharma
* Modified date :4/29/2011
* Reason for Modification:Separated test class from business class and created a new test class
* Modified By :Nitesh Dokania
* Modified date :46/8/2011
* Reason for Modification: Enhanced the test class coverage.
*/

@IsTest
private class LeadMapTest {
    public static testmethod void testLeadMap()
    {
	    LeadMap.dbbyPass = false;
	    Group obj_deploy=new Group();
	    obj_deploy.Name='APAC Delete Queue';
	    obj_deploy.Type='Queue';
	
	    insert obj_deploy;
		
		LeadMap.dbbyPass = false;
	    Group obj_deploy1=new Group();
	    obj_deploy1.Name='LATAM Delete Queue';
	    obj_deploy1.Type='Queue';
	
	    insert obj_deploy1;
	
	    test.startTest();
	    
	    new LeadMap().setMap();
	    new LeadMap().getQueueId('LATAM Delete Queue');
	    
	    new LeadMap().setMap();
	    new LeadMap().getQueueId('APAC Delete Queue');
	    
	    test.stopTest();
	    
	    System.assertEquals(obj_deploy.Id,new LeadMap().getQueueId('APAC Delete Queue'));
	    System.assertEquals(obj_deploy1.Id,new LeadMap().getQueueId('LATAM Delete Queue'));
	    
	    	    
    }
}