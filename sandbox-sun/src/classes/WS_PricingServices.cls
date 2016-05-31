/**
 * Conversion of class generated by wsdl2apex.  This is badly in need of refactoring.
 *
 * @author unknown
 * @version 2012-07-12
 *
 * Bill Riemers <briemers@redhat.com>
 * 2012-07-12 - Added support for a custom setting.
 * 2012-07-12 - Marked webservice callouts to only invoke when not testing
 */
public class WS_PricingServices {
	/**
	 * Default pricing service URL.  We use stage as the default.
	 * Normally this should be overriden with a custom setting.
	 */
	public static final String PRICING_SERVICE_URL_DEFAULT = 'https://extsvc.stage.redhat.com/ext/PricingFacade';

	/**
	 * The pricing service URL, as determined by the custom setting or default.
	 */
	public static String pricingServiceUrl {
		get {
			if(pricingServiceUrl == null) {
				pricingServiceUrl = PRICING_SERVICE_URL_DEFAULT;
				StringSetting__c ss = StringSetting__c.getInstance('Pricing Service');
				if(ss != null) {
					pricingServiceUrl = ss.Value__c;
				}
				System.debug('Using Pricing Service Url: '+pricingServiceURL);
			}
			return pricingServiceUrl;
		}
	}

	public Interface Response {}
	public Interface Request {}
	
	private static void invoke(
		PricingFacadePort fascade,
		Request request,
		Map<String,Response> responseMap,
		String [] values,
		Response testResponse)
	{
		if(Test.isRunningTest()) {
			responseMap.put('response_x',testResponse);
		}
		else {
			WebServiceCallout.invoke(
				fascade,
				request,
				responseMap,
				values);
		}
	}

	
	/** Class with for the response. */
	public class getProductInfoResponse implements Response {
		public String response;
		private String[] response_type_info = new String[]{'response','http://www.w3.org/2001/XMLSchema','string','0','1','false'};
		private String[] apex_schema_type_info = new String[]{'http://ws.pricing.services.redhat.com/','false','false'};
		private String[] field_order_type_info = new String[]{'response'};
	}

	/** Class for the calculated price */
	public class calculatePrice implements Request {
		public String request;
		private String[] request_type_info = new String[]{'request','http://www.w3.org/2001/XMLSchema','string','0','1','false'};
		private String[] apex_schema_type_info = new String[]{'http://ws.pricing.services.redhat.com/','false','false'};
		private String[] field_order_type_info = new String[]{'request'};
	}

	/** Fascade port class. */
	public class PricingFacadePort {
		public String endpoint_x = pricingServiceUrl;
		public Map<String,String> inputHttpHeaders_x;
		public Map<String,String> outputHttpHeaders_x;
		public String clientCertName_x;
		public String clientCert_x;
		public String clientCertPasswd_x;
		public Integer timeout_x;
		private String[] ns_map_type_info = new String[]{'http://ws.pricing.services.redhat.com/', 'WS_PricingServices'};
		public String calculatePrice(String request) {
			WS_PricingServices.calculatePrice request_x = new WS_PricingServices.calculatePrice();
			request_x.request = request;
			Map<String, WS_PricingServices.calculatePriceResponse> response_map_x = new Map<String, WS_PricingServices.calculatePriceResponse>{'response_x'=>null};
			invoke(
				this,
				request_x,
				response_map_x,
				new String[]{endpoint_x,
					'',
					'http://ws.pricing.services.redhat.com/',
					'calculatePrice',
					'http://ws.pricing.services.redhat.com/',
					'calculatePriceResponse',
					'WS_PricingServices.calculatePriceResponse'},
				new WS_PricingServices.calculatePriceResponse() );
			return response_map_x.get('response_x').response;
		}
		public String getQuotePrice(String request) {
			WS_PricingServices.getQuotePrice request_x = new WS_PricingServices.getQuotePrice();
			request_x.request = request;
			Map<String, WS_PricingServices.getQuotePriceResponse> response_map_x = new Map<String, WS_PricingServices.getQuotePriceResponse>{'response_x'=>null};
			invoke(
				this,
				request_x,
				response_map_x,
				new String[]{endpoint_x,
					'',
					'http://ws.pricing.services.redhat.com/',
					'getQuotePrice',
					'http://ws.pricing.services.redhat.com/',
					'getQuotePriceResponse',
					'WS_PricingServices.getQuotePriceResponse'},
				new WS_PricingServices.getQuotePriceResponse() );
			return response_map_x.get('response_x').response;
		}
		public String calculatePriceTest(String request) {
			WS_PricingServices.calculatePriceTest request_x = new WS_PricingServices.calculatePriceTest();
			request_x.request = request;
			Map<String, WS_PricingServices.calculatePriceTestResponse> response_map_x = new Map<String, WS_PricingServices.calculatePriceTestResponse>{'response_x'=>null};
			invoke(
				this,
				request_x,
				response_map_x,
				new String[]{
					endpoint_x,
					'',
					'http://ws.pricing.services.redhat.com/',
					'calculatePriceTest',
					'http://ws.pricing.services.redhat.com/',
					'calculatePriceTestResponse',
					'WS_PricingServices.calculatePriceTestResponse'},
				new WS_PricingServices.calculatePriceTestResponse() );
			return response_map_x.get('response_x').response;
		}
		public String getProductInfo(String request) {
			WS_PricingServices.getProductInfo request_x = new WS_PricingServices.getProductInfo();
			request_x.request = request;
			Map<String, WS_PricingServices.getProductInfoResponse> response_map_x = new Map<String, WS_PricingServices.getProductInfoResponse>{'response_x'=>null};
			invoke(
				this,
				request_x,
				response_map_x,
				new String[]{
					endpoint_x,
					'',
					'http://ws.pricing.services.redhat.com/',
					'getProductInfo',
					'http://ws.pricing.services.redhat.com/',
					'getProductInfoResponse',
					'WS_PricingServices.getProductInfoResponse'},
				new WS_PricingServices.getProductInfoResponse() );
			return response_map_x.get('response_x').response;
		}
	}
	/** Test response data... */
	public class calculatePriceTestResponse implements Response{
		public String response;
		private String[] response_type_info = new String[]{'response','http://www.w3.org/2001/XMLSchema','string','0','1','false'};
		private String[] apex_schema_type_info = new String[]{'http://ws.pricing.services.redhat.com/','false','false'};
		private String[] field_order_type_info = new String[]{'response'};
	}

	/** An exception class. */
	public class PricingWSException extends Exception {
		public String message;
		private String[] message_type_info = new String[]{'message','http://www.w3.org/2001/XMLSchema','string','0','1','false'};
		private String[] apex_schema_type_info = new String[]{'http://ws.pricing.services.redhat.com/','false','false'};
		private String[] field_order_type_info = new String[]{'message'};
	}

	/** Class for the the quote price response. */
	public class getQuotePriceResponse implements Response {
		public String response;
		private String[] response_type_info = new String[]{'response','http://www.w3.org/2001/XMLSchema','string','0','1','false'};
		private String[] apex_schema_type_info = new String[]{'http://ws.pricing.services.redhat.com/','false','false'};
		private String[] field_order_type_info = new String[]{'response'};
	}

	/** Class for calculated price test data. */
	public class calculatePriceTest implements Request {
		public String request;
		private String[] request_type_info = new String[]{'request','http://www.w3.org/2001/XMLSchema','string','0','1','false'};
		private String[] apex_schema_type_info = new String[]{'http://ws.pricing.services.redhat.com/','false','false'};
		private String[] field_order_type_info = new String[]{'request'};
	}

	/** Class for the calculated price response. */
	public class calculatePriceResponse implements Response {
		public String response;
		private String[] response_type_info = new String[]{'response','http://www.w3.org/2001/XMLSchema','string','0','1','false'};
		private String[] apex_schema_type_info = new String[]{'http://ws.pricing.services.redhat.com/','false','false'};
		private String[] field_order_type_info = new String[]{'response'};
	}

	/** Class to get the quote price. */
	public class getQuotePrice implements Request {
		public String request;
		private String[] request_type_info = new String[]{'request','http://www.w3.org/2001/XMLSchema','string','0','1','false'};
		private String[] apex_schema_type_info = new String[]{'http://ws.pricing.services.redhat.com/','false','false'};
		private String[] field_order_type_info = new String[]{'request'};
	}

	/** Class with the product info response. */
	public class getProductInfo implements Request {
		public String request;
		private String[] request_type_info = new String[]{'request','http://www.w3.org/2001/XMLSchema','string','0','1','false'};
		private String[] apex_schema_type_info = new String[]{'http://ws.pricing.services.redhat.com/','false','false'};
		private String[] field_order_type_info = new String[]{'request'};
	}
}