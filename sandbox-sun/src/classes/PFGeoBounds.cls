global class PFGeoBounds {

    global static final PFGeoBounds MAX = new PFGeoBounds(
        new PFGeoPoint(-90,-180)
        ,new PFGeoPoint(90,180)
    ); 
    
	global PFGeoPoint northeast {get;set;}
	global PFGeoPoint southwest {get;set;}

	global PFGeoBounds(List<PFGeoPoint> points){
		initialize(points);
	}
	
	global PFGeoBounds(PFGeoPoint southwest, PFGeoPoint northeast){
		initialize(new PFGeoPoint[]{southwest,northeast});
	}
	
	private void initialize(List<PFGeoPoint> points){
		if (points != null && points.size() > 0){
			Double minLat = 90; 
			Double maxLat = -90; 
			Double minLng = 180; 
			Double maxLng = -180;
			for(PFGeoPoint point : points){
				minLat = point.lat() < minLat ? point.lat() : minLat;
				maxLat = point.lat() > maxLat ? point.lat() : maxLat;
				minLng = point.lng() < minLng ? point.lng() : minLng;
				maxLng = point.lng() > maxLng ? point.lng() : maxLng;
			} 
			this.northeast = new PFGeoPoint(maxLat,maxLng);
			this.southwest = new PFGeoPoint(minLat,minLng);
		}
	}
	
	global Boolean contains(PFGeoPoint point){
		if(point == null || northeast == null || southwest == null){
			return false;
		}
		return 
				this.northeast.lat() > point.lat()
			&& 	this.southwest.lat() < point.lat()
			&& 	this.northeast.lng() > point.lng()
			&& 	this.southwest.lng() < point.lng()
		;
	}

	global String toStr(){
		return '<#GeoBounds(northeast=' + (northeast==null ? null : northeast.toStr()) 
			+ ',southwest=' + (southwest==null ? null : southwest.toStr()) + ')>';
	}
}