public class GeocodingUtil {

	static private final String GOOGLE_API_PK = 'P+KBR1ah2PJUOwGGRvRjRIbZ/vs=';
	static private final String GOOGLE_CLIENTID = 'gme-redhatinc';

	private static String nn(String arg) {
		if (arg == null) {
			return '';
		}
		return arg;
	}

	private static String ue(String arg) {
		if (arg == null) {
			return '';
		}
		return System.EncodingUtil.urlEncode(arg, 'UTF-8');
	}

	@future(callout=True)
	public static void geocodeLocation(Id locId) {
		Partner_Location__c loc;
		try {
			loc = [
			  select	Id,
						longitude__c,
						latitude__c,
						Country__c,
						Street__c,
						City__c,
						State_Province__c,
						Postal_Code__c,
						Validated__c,
						PartnerValidated__c
				from	Partner_Location__c
			   where	Id = :locId
			];
		} catch (System.QueryException ex) {
			// Location is gone already, race condition
			return;
		}
		String countryName = '';
		if (!PFUtils.isEmpty(loc.Country__c) && loc.Country__c.length() == 2) {
			try {
				Country__c country = [select Id, Name from Country__c where Abbreviation__c = :loc.Country__c];
				countryName = country.Name;
			}
			catch (System.QueryException ex) {
				// not found, skip
			}
		}
	    Http agent = new Http();
	    HttpRequest request = new HttpRequest();
	    request.setMethod('GET');
	    String host = 'http://maps.googleapis.com';
	    String url = '/maps/api/geocode/xml';
	    //request.setHeader('Host', 'www.redhat.com');
	    request.setHeader('Content-type', 'application/x-www-form-urlencoded');
	    request.setHeader('User-Agent', 'Mozilla/5.0 Firefox/3.6.13');
	    request.setHeader('Referer', 'http://redhat.force.com');
	    request.setHeader('Cache-Control', 'no-cache, no-store');

		String address = ue(loc.Street__c) + ',' + ue(loc.City__c) + ',' + ue(nn(loc.State_Province__c)) + ',' + ue(countryName) + ',' + ue(nn(loc.Postal_Code__c));
        String params = '?address=' + address + '&sensor=false' + '&client=' + GOOGLE_CLIENTID;
//        System.debug('[debug]------------------ address=' + params);

		Blob pkBlob = EncodingUtil.base64Decode(GOOGLE_API_PK);
		Blob sigBlob = Crypto.generateMac('hmacSHA1', Blob.valueOf(url + params), pkBlob);
		String sig = EncodingUtil.base64Encode(sigBlob);

		sig = sig.replace('/', '_').replace('+','-');
        request.setEndpoint(host + url + params + '&signature=' + sig);
//		System.debug('[debug]----------- endpoint=' + request.getEndpoint());
		if (!System.Test.isRunningTest()){
	        HttpResponse rsp = agent.send(request);
	        String body = rsp.getBody();

			if (body != null) {
	//			System.debug('[debug]----- body=' + body);
		        Dom.Document doc = rsp.getBodyDocument();
		        Dom.XmlNode[] results = doc.getRootElement().getChildElements();
		        if (results != null && results.size() > 1) {
		        	Dom.XmlNode result = results.get(1);
					Dom.XmlNode geometry = result.getChildElement('geometry', null);
		        	Dom.XmlNode latlng = geometry.getChildElement('location', null);
		        	if (latlng != null) {
		        		String lat = latlng.getChildElement('lat', null).getText();
		        		String lng = latlng.getChildElement('lng', null).getText();
	//	        		System.debug('[debug]------------------ lat=' + lat);
	//	        		System.debug('[debug]------------------ lng=' + lng);
		        		loc.latitude__c = Double.valueOf(lat);
		        		loc.longitude__c = Double.valueOf(lng);
		        		loc.validated__c = True;
	//	        		System.debug('[debug]----------------- validated and updated with ' + loc.latitude__c + ',' + loc.longitude__c);
		        	}
		        	else {
		        		System.debug('[debug]------- latlng element missing');
		        	}
		        }
			}
		}
		else {
			System.debug('[debug]------- api response body missing');
		}
        loc.Convert__c = False;
   		update loc;
	}
}