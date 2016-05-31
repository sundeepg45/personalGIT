/**
 * Web service wrapper for Quoting.cls
 *
 * @author  Bryan Bosely <bbosely@redhat.com>
 * @date    01/11/11
 */

global class QuotingServices 
{
    
    global class QuotingServicesResponse 
    {
        webservice boolean status;
        webservice String message;
    }
    
    
    webservice static QuotingServices.QuotingServicesResponse syncQuoteWithOpp( Id quoteId ) 
    {       
        QuotingServices.QuotingServicesResponse response = new QuotingServicesResponse();
        response.status = true;
       
        try 
        { 
            Quoting quoting = new Quoting();
            quoting.syncQuoteWithOpp( quoteId );
        }
        catch( Exception e ) 
        {
            response.status = false;
            response.message = e.getMessage();
        }
       
        return response;
    }
    
    
    webservice static QuotingServices.QuotingServicesResponse calculate( Id quoteId )
    {
        QuotingServices.QuotingServicesResponse response = new QuotingServicesResponse();
        response.status = true;
       
        try 
        { 
            Quoting quoting = new Quoting();
            quoting.calculate( quoteId );
        }
        catch( Exception e ) 
        {
            response.status = false;
            response.message = e.getMessage();
        }
       
        return response;
    }
    
    
    webservice static QuotingServices.QuotingServicesResponse calculateXml( String xml ) 
    {  
        QuotingServices.QuotingServicesResponse response = new QuotingServicesResponse();
        response.status = true;
       
        try 
        { 
            Quoting quoting = new Quoting();
            response.message = quoting.calculateXml( xml );
        }
        catch (Exception e) 
        {
            response.status = false;
            response.message = e.getMessage();
        }
       
        return response;
    }
}