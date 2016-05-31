		var openInfoWindow;

		function getElementByPartialId(tag, partialid, indx){
			var re= new RegExp(partialid,'g')
			var el = document.getElementsByTagName(tag);
			var idx = 0;			
			for(var i=0;i<el.length;i++){
				if(el[i].id.match(re)){
					if (indx == null || indx == idx){
						return el[i];
					}
					idx++;
				}
			}
		}

		function setSelectedIndex(s, v) {
		    for ( var i = 0; i < s.options.length; i++ ) {
		        if ( s.options[i].value == v ) {
		            s.options[i].selected = true;
		            return;
		        }
		    }
		}

		function createMap(lon, lat){
	    	jQuery('#map_canvas').show();
	    	jQuery('#map_note').show();
	    	geocoder = new google.maps.Geocoder();
	    	var latlng = new google.maps.LatLng(lat, lon);
	    	var myOptions = {
	      		zoom: 12,
	      		center: latlng,
	      		mapTypeId: google.maps.MapTypeId.ROADMAP
	    	}
	    	map = new google.maps.Map(document.getElementById("map_canvas"), myOptions);
		}

		function addMarker(lon, lat, name, infobox){
			if (!infobox)
			{
				infobox = name;
			}
			
			if (lon != null && lon != '' && lat != null && lat != ''){
				if (!map || map == null){
					createMap(lon, lat);
				}
			
				var infowindow = new google.maps.InfoWindow({
				    content: infobox,
					maxWidth: 390
				});
		    	var marker = new google.maps.Marker({
					map: map, 
					position: new google.maps.LatLng(lat, lon),
					title: name
		    	});
				google.maps.event.addListener(marker, "mousedown", function() {
				  if (openInfoWindow && openInfoWindow != null){
				 	openInfoWindow.close();
				  	openInfoWindow = null;
				  }
				  infowindow.open(map,marker);
				  openInfoWindow = infowindow;
				});
//				google.maps.event.addListener(marker, "mouseout", function() {
//				  infowindow.close();
//				});
			}
		}

		function toggleAdvancedSearch(){
			jQuery('#bottom').toggle();
			getElementByPartialId('input','.*hidAdvancedSearchOpen').value = jQuery('#bottom').is(":visible");
			
			if (jQuery('#bottom').is(":visible")){
				jQuery('#filterShowHideLink').html(hideAdvLink);
			} else {
				jQuery('#filterShowHideLink').html(showAdvLink);
			}
		} 		

		function trim(str) {
			if (str){
		    	return str.replace(/^\s\s*/, '').replace(/\s\s*$/, '');
		    }
		    return '';
		}


		function log(message){
			//if (window.console && window.console.firebug && trim(window.console.firebug) !== '') {
			//	console.log(message);
			//}
		}
		
		function startSearch(){
			jQuery('#searchButtons').hide(); 
			jQuery('#statusSearching').show();		
		}
		
