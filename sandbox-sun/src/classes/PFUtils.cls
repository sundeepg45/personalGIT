public class PFUtils {
	
	public static final Double KM_IN_ONE_LATITUDE_DEGREE = 111.132;
    public static final Double KILOMETERS_IN_ONE_MILE  = 1.609344;
	public static final Double MEAN_EARTH_RADIUS_KM = 6371;
	public static final Double PI = 3.1415926535897932384626433832795;


	static public Boolean isEmpty(String str) {
		return str == null || str.length() == 0;
	}
	
	static public Boolean isEmpty(String[] str) {
		return str == null || str.size() == 0;
	}
	
	static public Boolean isEmpty(SObject[] obj) {
		return obj == null || obj.size() == 0;
	}	

	static public String get(String field, String defaultIfEmpty) {
		if (PFUtils.isEmpty(field)) {
			return defaultIfEmpty;
		}
		return field;
	}
	
	static public String[] get(String multilist) {
		if (PFUtils.isEmpty(multilist)) {
			return new List<String>();
		}
		return multilist.split(';');
	}

	static public String getDefaultPicklistValue(Schema.PicklistEntry[] entries) {
		for (Schema.PicklistEntry entry : entries) {
			if (entry.isDefaultValue() == True) {
				return entry.getValue();
			}
		}
		return entries[0].getValue();
	}
	
	static public List<SelectOption> getSelectOptionsForPicklist(Schema.DescribeFieldResult pickList){
		List<SelectOption> options = new List<SelectOption>();
    	for (Schema.PicklistEntry v : pickList.getPickListValues()){
    		options.add(new SelectOption(v.getValue(), v.getLabel()));
    	}
    	return options;
	}
	
	static public String convertListToPicklist(List<String> values){
		String result = '';
		boolean isFirst = true;
		for (String v : values){			
			if (!isFirst){
				result += ';';
			}
			isFirst = false;
			result += v;
		}
		return result;
	}
	

	static public String joinStrings(List<String> parts, String delim) {
		if (parts == null || parts.size() == 0) {
			return '';
		}
		String buffer = parts[0];
		for (Integer i = 1; i < parts.size(); i++) {
			buffer = buffer + delim + parts.get(i);
		}
		return buffer;
	}
	
	//
	// Build a map where the key is a named field and the value is the object ID
	//
	static public Map<String,ID> buildFieldIDMap(String fieldName, SObject[] objects) {
		Map<String,ID> theMap = new Map<String,String>();
		for (SObject obj : objects) {
			String val = (String) obj.get(fieldName);
			ID theId = (ID) obj.get('ID');
			theMap.put(val, theId);
		}
		return theMap;
	}

	static public Partner_Location__c getPrimaryLocation(Account acct, Partner_Location__c[] locations){
		if (!isEmpty(locations)){
			for (Partner_Location__c loc : locations){
				if (loc.Is_Primary__c){
					return loc;
				}
			}
		}		
		/**
			Fallback if no location on the Account
		**/
		Partner_Location__c primLoc = new Partner_Location__c();
		primLoc.Name = 'Main';
		if (acct.ShippingStreet != null){
			primLoc.Street__c = acct.ShippingStreet;
			primLoc.City__c = acct.ShippingCity;
			primLoc.State_Province__c = acct.ShippingState;
			primLoc.Postal_Code__c = acct.ShippingPostalCode;
			primLoc.Country__c = acct.ShippingCountry;		
		} else {
			primLoc.Street__c = acct.BillingStreet;
			primLoc.City__c = acct.BillingCity;
			primLoc.State_Province__c = acct.BillingState;
			primLoc.Postal_Code__c = acct.BillingPostalCode;
			primLoc.Country__c = acct.BillingCountry;		
		}
		primLoc.Is_Primary__c = true;
		primLoc.Partner__c = acct.Id;
		primLoc.Phone__c = acct.Phone;
		return primLoc;
	}

	public static PFGeoBounds getBounds(PFGeoPoint point, Double distanceInKilometers) {
		Double distLatDeg = distanceInKilometers/KM_IN_ONE_LATITUDE_DEGREE;
		Double distLngDeg = distLatDeg/Math.cos((point.lat()*PI)/180);
		Double neLat = point.lat()+distLatDeg;
		Double neLng = point.lng()+distLngDeg;
		Double swLat = point.lat()-distLatDeg;
		Double swLng = point.lng()-distLngDeg;
		neLat = (neLat < -90 || neLat > 90) ? 90 : neLat;
		neLng = (neLng < -180 || neLng > 180) ? 180 : neLng;
		swLat = (swLat < -90 || swLat > 90) ? -90 : swLat;
		swLng = (swLng < -180 || swLng > 180) ? -180 : swLng;
		return new PFGeoBounds(new PFGeoPoint(neLat, neLng),new PFGeoPoint(swLat, swLng));
	}
	
	public static Double convertKilometersToMiles(Double distance) {
		return distance * (1/KILOMETERS_IN_ONE_MILE);
	}

	public static Double convertMilesToKilometers(Double distance) {
		return distance * KILOMETERS_IN_ONE_MILE;
	}

	public static Double distanceInKilometers(PFGeoPoint point1, PFGeoPoint point2) {
		if (point1 == null || point2 == null){
			throw new PFException('null argument(s)');
		}
		Double a = 
			Math.pow(Math.sin(((point2.lat() - point1.lat())*(PI/180))/2),2) + 
			Math.cos(point1.latRadians()) * 
			Math.cos(point2.latRadians()) * 
			Math.pow(Math.sin(((point2.lng() - point1.lng())*(PI/180))/2),2);
        System.debug('### a ' + a);
        System.debug('### Math.sqrt(a) ' + Math.sqrt(a));
        System.debug('### Math.sqrt(1-a) ' + Math.sqrt(1-a));
        System.debug('### Math.atan2(Math.sqrt(a), Math.sqrt(1-a)) ' + Math.atan2(Math.sqrt(a), Math.sqrt(1-a)));
		return MEAN_EARTH_RADIUS_KM * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a)); 
	} 


}