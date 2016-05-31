public class SumTotal_UpdateUser {

	@future
    public static void doUpdate(ID[] changed) {
        if (!changed.isEmpty()) {
            //if (changed.size() > 1) {
                // batch mode
                STConnector.enqueue(changed, STConnector.ACTION_UPDATE_USER);
            //}
            //else {
            //    sendRequest(changed.get(0), STConnector.ACTION_UPDATE_USER);
            //}
        }
    }
    /*
    static private void sendRequest(ID userid, String action) {
        if (System.isFuture() || Test.isRunningTest()) {
            STConnector.enqueue(userid, action);
        }
        else {
            threadedSubmit(userid, action);
        }
    }
    
    @future(callout=True)
    static private void threadedSubmit(ID userid, String action) {
        STConnector stc = new STConnector();
        try {
            STConnector.JSONResponse rsp = stc.updateUser(userid);
            if (rsp == null) {
                STConnector.enqueue(userid, action);
            }
        }
        catch (Exception ex) {
            // need to log this somewhere
            STConnector.enqueue(userid, action);
        }
    }
*/
    @future(callout=True)
    public static void doInactivate(ID[] inactive) {
    	STConnector.enqueue(inactive, STConnector.ACTION_DEACTIVATE_USER);
    }
    
    @future(callout=True)
    public static void doActivate(ID[] active) {
	    STConnector.enqueue(active, STConnector.ACTION_ACTIVATE_USER);
    }

}