/**
 * Web rest service wrapper for Opportunity_RenewalAccountMatching
 * 
 * @version 2015-01-27
 * @author Bill Riemers <briemers@redhat.com>
 * 2015-01-27 - Depreciated CREATE OPPORTUNITY
 * 2012-05-30 - Created
 */
@RestResource(urlMapping='/v24.0/RenewalRestService/*') 
global class Opportunity_RenewalRestService {
	global static final String URL_MAPPING = '/v24.0/RenewalRestService/';
	// append this to the URI when creating an opportunity
	global static final String CREATE_OPPORTUNITY = 'createOpportunity';
	// append this to the URI when querying an account
	global static final String QUERY_ACCOUNT = 'queryAccount';

	// special CGI_BIN parameter to enable testMode
	global static final String TESTING = 'testing';

	/**
	 * Parse the requestBody and return just the xml.
	 * For some strange reason, salesforce is not always setting
	 * the requestBody.  In that case we can still get the request
	 * from the params...
	 */
	global static String requestBody {
		get {
			String retval = requestBody;
			try {
				retval = RestContext.request.requestBody.toString();
			}
			catch(NullPointerException e) {}
			if(retval == null || retval == '') {
				try {
					retval = ''+RestContext.request.params;
				}
				catch(NullPointerException e) {}
			}
			return retval.substring(retval.indexOf('<'),retval.lastIndexOf('>')+1);
		}
		set; // used in test methods only
	}

	/**
	 * Set the response body.
	 */
	global static Blob responseBody {
		get; // used in test methods only
		set {
			responseBody = value;
			try {
				RestContext.response.responseBody = value; 
			}
			catch(NullPointerException e) {}
		}
	}

	/**
	 * Return the tail end of th requestURI
	 */
	global static String requestURI {
		get {
			String retval = requestURI;
			try {
				retval = RestContext.request.requestURI;
			}
			catch(NullPointerException e) {}
			return retval.substring(retval.indexOf(URL_MAPPING)+URL_MAPPING.length());
		}
		set; // used in test methods only
	}

	/**
	 * Set the response status code
	 */
	global static Integer statusCode {
		get; // used in test methods only
		set {
			statusCode = value;
			try {
				RestContext.response.statusCode = value;
			}
			catch(Exception e) {}
		}
	}

	/**
	 * Called to actually process the requests.
	 */
	@HttpPost
	global static void doPost() {
		try {
			System.debug(RestContext.request);
			statusCode = 200;
//depreciated			if(requestURI.startsWith(CREATE_OPPORTUNITY) ) {
//depreciated				Opportunity_Renewal oppRenewal = new Opportunity_Renewal();
//depreciated				PageReference pr = new PageReference(requestURI);
//depreciated				oppRenewal.isTestMode = 'true'.equalsIgnoreCase(pr.getParameters().get(TESTING));
//depreciated				responseBody = Blob.valueOf(
//depreciated					oppRenewal.createRenewalOpportunity( requestBody ) );
//depreciated				if(! oppRenewal.isSuccess) {
//depreciated					statusCode = 400;
//depreciated				}
//depreciated				else if (! oppRenewal.isTestMode) {
//depreciated					statusCode = 201;
//depreciated				}
//depreciated			}
//depreciated			else
			if(requestURI.startsWith(QUERY_ACCOUNT) ) {
				responseBody = Blob.valueOf(
					new Opportunity_RenewalAccountMatching().queryAccount( requestBody ) );
			}
			else {
				statusCode = 404;
				responseBody = Blob.valueOf('Unrecognized command');
			}
		}
		catch(Exception e) {
			statusCode = 500;
			System.debug('Exception: '+e+'\n'+e.getStackTraceString());
			responseBody = Blob.valueOf(''+e.getMessage());
		}
	}
}