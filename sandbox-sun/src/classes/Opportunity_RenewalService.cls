/**
 * Web service wrapper for Opportunity_Renewals.cls
 * 
 * @version 2015-01-27 
 * @author John Herson <jherson@redhat.com>
 * 2011-01-13 - Created
 * Bill Riemers <briemers@redhat.com>
 * 2015-01-27 - Depreciated
 * 2012-05-31 - Use new isSuccess property
 */
global class Opportunity_RenewalService {

//depreciated	global class Opportunity_RenewalServiceResponse
//depreciated	{
//depreciated		webservice boolean status;
//depreciated		webservice String message;
//depreciated	}

//depreciated	webservice static Opportunity_RenewalService.Opportunity_RenewalServiceResponse createRenewalOpportunity( String xml )
//depreciated	{
//depreciated		Opportunity_RenewalService.Opportunity_RenewalServiceResponse response = new Opportunity_RenewalServiceResponse();
//depreciated		Opportunity_Renewal oppRenewal = new Opportunity_Renewal();
//depreciated		try {
//depreciated			response.message = oppRenewal.createRenewalOpportunity( xml );
//depreciated		}
//depreciated		catch (Exception e) {
//depreciated			response.message = e.getMessage();
//depreciated		}
//depreciated		response.status = oppRenewal.isSuccess;
//depreciated		
//depreciated		return response;
//depreciated	}

//depreciated	webservice static Opportunity_RenewalService.Opportunity_RenewalServiceResponse queryAccount( String xml )
//depreciated	{
//depreciated		Opportunity_RenewalService.Opportunity_RenewalServiceResponse response = new Opportunity_RenewalServiceResponse();
//depreciated		response.status = true;
//depreciated		
//depreciated		try {
//depreciated			Opportunity_RenewalAccountMatching accountMatching = new Opportunity_RenewalAccountMatching();
//depreciated			response.message = accountMatching.queryAccount( xml );
//depreciated		}
//depreciated		catch (Exception e) {
//depreciated			response.status = false;
//depreciated			response.message = e.getMessage();
//depreciated		}
//depreciated		
//depreciated		return response;
//depreciated	}
}