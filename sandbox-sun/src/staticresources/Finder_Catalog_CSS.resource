html, body, div, span, applet, object, iframe, h1, h2, h3, h4, h5, h6, p, blockquote, pre, a, abbr, acronym, address, big, cite, code, del, dfn, em, img, ins, kbd, q, s, samp, small, strike, strong, sub, tt, var, b, u, i, center, dl, dt, dd, ol, ul, li, fieldset, form, label, legend, table, caption, tbody, tfoot, thead, tr, th, td, article, aside, canvas, details, embed, figure, figcaption, footer, header, hgroup, menu, nav, output, ruby, section, summary, time, mark, audio, video {
    border: 0 none;
    font-size: 100%;
    margin: 0;
    padding: 0;
    vertical-align: baseline;
}
article, aside, details, figcaption, figure, footer, header, hgroup, menu, nav, section {
    display: block;
}
ol, ul {
    list-style: none outside none;
    margin-left: 3px;
}
svg {
    overflow: hidden;
}
body {
    background-color: #F3F3F3;
    color: #333333;
    font-family: 'Liberation Sans',Helvetica,Arial,sans-serif;
    font-size: small;
    line-height: 1.4;
}
input, select, textarea {
    display: block;
    font-size: inherit;
    margin-bottom: 15px;
    padding: 2px;
    width: 96%;
}
.checkList input {
    display: inline;
    margin-bottom: 0;
    width: auto;
}
.checkList td {
    padding: 0;
}
.checkList label {
    font-weight: normal;
    text-transform: none;
    vertical-align: text-bottom;
}
input.partner-search {
    background: none repeat scroll 0 0 #D7DAD6;
    border: 1px solid #ABB2A9;
    border-radius: 2px 2px 2px 2px;
    cursor: pointer;
    font-size: 95%;
    font-weight: bold;
    margin: 0;
    padding: 3px 13px;
    text-transform: uppercase;
    width: auto;
}
#statusSearching {
    margin-left: 35px;
    margin-top: 3px;
    width: 200px;
}
#locationBasedSearch select.option {
    text-transform: capitalize;
}
h1, h2, h3, h4 {
    margin: 0 0 0.15em;
}
h1 {
    color: #CC0000;
    font-size: 144%;
    line-height: 1.1em;
    margin-bottom: 0.75em;
    text-transform: uppercase;
}
h2 {
    font-size: 132%;
    line-height: 1.1em;
    text-transform: uppercase;
}
h3 {
    font-size: 118%;
    line-height: 1.1em;
    text-transform: uppercase;
}
h4 {
    font-size: 100%;
    text-transform: uppercase;
}
h5 {
    font-size: 90%;
}
* + h2, * + h3, * + h4, * + h5, * + h6 {
    margin-top: 1.75em;
}
h1 + h2 {
    margin-top: 0;
}
h2 + h3, h3 + h4, h4 + h5 {
    margin-top: 0.5em;
}
label {
    font-weight: bold;
    text-transform: uppercase;
}
ol {
    list-style: decimal outside none;
}
ul {
    list-style: disc outside none;
    margin-bottom: 1.65em;
}
li {
    margin: 0 0 6px 21px;
}
ul ul, ol ul, ul ul ul {
    display: block;
}
p, dl, hr, pre, table, address, fieldset, figure {
    margin-bottom: 0.65em;
}
ul + p {
    margin-top: 0.75em;
}
p {
    margin: 0.375em 0 1.3em;
}
hr {
    background-color: #DCDCDC;
    border: 0 none;
    height: 1px;
    margin: 21px 0;
}
.goleft {
    float: left;
}
.goright {
    float: right;
}
.center {
    text-align: center;
}
.smaller {
    font-size: 88%;
}
.smallest {
    font-size: 77%;
}
.larger {
    font-size: 118%;
}
.largest {
    font-size: 138%;
}
.italics {
    font-style: italic;
}
.hide {
    display: none;
}
.invisible {
    visibility: hidden;
}
.block {
    display: block;
}
.inline {
    display: inline;
}
.nowrap {
    white-space: nowrap;
}
.clear {
    clear: both;
    display: block;
    height: 0;
    overflow: hidden;
    visibility: hidden;
    width: 0;
}
.clearfix:before, .clearfix:after {
    content: " ";
    display: block;
    height: 0;
    overflow: hidden;
    visibility: hidden;
    width: 0;
}
.clearfix:after {
    clear: both;
}
.clearfix {
}}

/**
* Product Details with Apps
 *************************************/


#partnerAppList {
	width: 100%;
	padding: 0 0 15px 0; }
	
.partnerApp {
	border: 1px solid #B4B4B4;
	-moz-border-radius: 5px;
	-webkit-border-radius: 5px;
	padding: 10px 0 0;
	margin: 15px 1px 0 0;
	background-color: #fff;
	/*overflow: hidden; so cardAssets tab doesn't have a bottom when on*/ }
	
.partnerApp:first-child {margin-top: 0;}
	
.partnerAppTitle {
	margin:0 0 15px 10px;
	font-weight: bold;
	font-size:105%; }
	
.appCertificationTitle {
	float:left; }
	
.partnerApp .appCertificationRhel, .partnerApp .appCertificationRhel {
	float:left;
	margin: 0 18px; }
	
.appCertificationRhel, .appCertificationRhelDisabled {
	float:left;
	margin: 0 18px 0 0; }
	
.appCertificationJboss, .appCertificationJbossDisabled {
	float:left; }
	
.appCertificationJbossDisabled, .appCertificationRhelDisabled {
  	filter:alpha(opacity=25); /* for IE */
  	opacity:0.25; /* CSS3 standard */ }
	
.appDetailsLink {
	padding:0 10px 4px 0;
	text-align:right; }


/**
* Product Card
 *************************************/
 
/*.cardAssets .cardApplicationTab { margin: 0 2px -1px 0; }*/

.cardColFull {
	margin-bottom:10px;
	overflow:hidden; }



/**
* Modal View
 *************************************/

.modalViewer { 
	background: #fff;
	width:475px; }
	
.modalViewer .modalTop {
	font-weight: bold; }
	
.modalViewer .modalMiddle {
	min-height:250px;
	padding:10px 15px;
	max-height: 450px;
	overflow-y: auto;
	overflow-x: hidden;
	}
	
.modalViewer .modalBottom {
    text-align: center; 
    font-weight: bold; }
		
.shadow-one { position: absolute; padding-top: 100px; padding-left: 100px; }
.corner-a { position: absolute; right: 0; top: 0; width: 100px; height: 100px; background: url(http://www.redhat.com/g/chrome/dropshadow4side.png) right top no-repeat; }
.corner-b { position: absolute; left: 0; bottom: 0; width: 100px; height: 100px; background: url(http://www.redhat.com/g/chrome/dropshadow4side.png) left bottom no-repeat; }
.shadow-two { background: url(http://www.redhat.com/g/chrome/dropshadow4side.png) right bottom no-repeat; }
.shadow-three { position: relative; left: -100px; top: -100px; background: url(http://www.redhat.com/g/chrome/dropshadow4side.png) left top no-repeat; }
.shadow-four { position: relative; left: 50px; top: 50px; } 

#modalViewerbg {
	height: 100%; 
	width: 100%; 
	position: fixed; 
	left: 0pt; 
	top: 0pt; 
	z-index: 2999;
	background-color:#CCC; 
	opacity: 0.5; }
	
		
/* jqModal */

/* The Window's CSS z-index value is respected (takes priority). If none is supplied,
  the Window's z-index value will be set to 3000 by default (in jqModal.js). You
  can change this value by either;
    a) supplying one via CSS
    b) passing the "zIndex" parameter. E.g.  (window).jqm({zIndex: 500}); */
  
.jqmWindow {
    display: none;
    position: fixed;
    top: 0;
    left: 50%;
    margin-left: -300px;
    color: #333;
    padding: 6px; }

#closeModalButton {
	background:transparent url(http://www.redhat.com/g/chrome/modalClose.png) repeat scroll 0 0;
	display:block;
	height:36px;
	position:absolute;
	z-index: 9999;
	width:36px; }

.jqmOverlay { background-color: #777; }

/* Fixed posistioning emulation for IE6
     Star selector used to hide definition from browsers other than IE6 */
* html .jqmWindow {
     position: absolute;
     top: expression((document.documentElement.scrollTop || document.body.scrollTop) + Math.round(17 * (document.documentElement.offsetHeight || document.body.clientHeight) / 100) + 'px'); }



/**
* Details
 *************************************/
 
	
#productDetailsInner, #partnerDetailsInner {
	margin: 15px 25px; }

#firstSection, #secondSection, #thirdSection {
	margin: 0 0 20px 0; }
	
#firstSection #partnerLogo, #firstSection #partnerLogoNotPresent, #firstSection #uploadPartnerLogo {
	float:right; }
	
#firstSection #partnerTop {
	display: block; 
	margin-bottom: 15px;
	padding-bottom: 15px;
	border-bottom:1px solid #B4B4B4; }
	
#firstSection #partnerHead {
	width: 67%;
	float: left; }
	
#productDetails h2.partnerName, #partnerDetails h2.partnerName {
	font-size: 175%;
	float: left;
	margin-bottom:10px; }

#productDetails .cardLogo,
#partnerDetails .cardLogo {
	margin-left: 0;
	background-color: #fff;
	font-size: 90%;
	border: 1px dashed #B4B4B4;
	padding: 7px;
	text-align: center;
	vertical-align: middle;
	color: #B4B4B4; }

	
#partnerDetailsType, #partnerDetailsLevel,
#productDetailsType, #productDetailsLevel { clear: both; }
	
#partnerDetails h3.sectionHeading, #productInformationSectionHeader {
	background-color: #d0d0d0;
	padding: 4px 6px;
	margin: 0 0 15px 0;
	font-size: 125%;
	clear: both; }

#productDetails h3.sectionHeading, #productInformationSectionHeader {
	background-color: #d0d0d0;
	padding: 4px 6px;
	margin: 0 0 15px 0;
	font-size: 125%;
	clear: both; }
	
#partnerDetailsType, #partnerDetailsLevel {
	font-size: 110%; }

.partnerDetailsList {
	border-collapse: collapse;
	width: 100%;
	font-size: 100%;
	margin: 0 0 10px 0; }
		
.partnerDetailsList  th, .partnerDetailsList  td  {
	padding: 0 0 15px 0; }

.partnerDetailsList  td {
	width:auto; }

.partnerResources {
	border-right:1px solid #B4B4B4;
	margin: 0 15px 15px 0;
	padding:5px;
	width:148px;
	float: left; }
	
table.profile_table {
	margin: 15px 0;
	width: 100%; }

table.profile_table td {
	border-bottom: 1px solid #ddd;
	padding: 8px;
	text-align: left;
	vertical-align: top; }

table.profile_table tr {
	background-color: #fff;
	padding-bottom: 10px; }	
	
#partnerDetails h4 {
	font-size: 110%;
	font-weight: bold; }
	
.sectionBlock {
	margin: 0 0 20px 0; }
	
.partnerHeadSub {
	clear:both; }
	

/**
* Partner and Product  Card
 *************************************/

.card,
#partnerDetails,
#productDetails {
	position:relative;
	border: 1px solid #B4B4B4;
	width: inherit;
	-width: 465px; /* needed for IE6 */ 
	padding:5px 0 0 0;
	min-height: 70px;
	margin-top: 12px;
	text-align: left;
	font-size: 92%; }
	
#partnerDetails,
#productDetails { width: 100%; /* needed for IE6 */ }

.card .corner_topleft, .card .corner_topright, .card .corner_bottomleft, .card .corner_bottomright,
#partnerDetails .corner_topleft, #partnerDetails .corner_topright, #partnerDetails .corner_bottomleft, #partnerDetails .corner_bottomright,
#productDetails .corner_topleft, #productDetails .corner_topright, #productDetails .corner_bottomleft, #productDetails .corner_bottomright {
	position:absolute;
	width:10px;
	height:10px;
	overflow:hidden;
	z-index:2; }
	
.card .corner_topleft, .card .corner_topright, .card .corner_bottomleft, .card .corner_bottomright,
#partnerDetails .corner_topleft, #partnerDetails .corner_topright, #partnerDetails .corner_bottomleft, #partnerDetails .corner_bottomright,
#productDetails .corner_topleft, #productDetails .corner_topright, #productDetails .corner_bottomleft, #productDetails .corner_bottomright,
.corner_tabs_topleft, .corner_tabs_topright, .corner_tabs_bottomleft, .corner_tabs_bottomright {
	background:url('http://www.redhat.com/partner_center/g/chrome/white-circle.png'); }

.card .corner_topleft,
#partnerDetails .corner_topleft,
#productDetails .corner_topleft {
	top:-1px;
	left:-1px; }

.card .corner_topright,
#partnerDetails .corner_topright,
#productDetails .corner_topright {
	top:-1px;
	right:-1px;
	background-position:10px 0; }

.card .corner_bottomleft,
#partnerDetails .corner_bottomleft,
#productDetails .corner_bottomleft {
	bottom:-1px;
	left:-1px;
	background-position:0 10px; }

.card .corner_bottomright,
#partnerDetails .corner_bottomright,
#productDetails .corner_bottomright {
	bottom:-1px;
	right:-1px;
	background-position:10px 10px; }
	
.card h3 {
	width:285px;
 	float: left;
	font-size:110%; }
	
.cardLogo {
	float:right;
	margin-right:10px;
	margin-top:5px;
	 }

.cardLogo img {
	max-height: 50px;
	max-width: 200px;
	 }
	
.cardPhone {
	margin-top:3px;
	margin-bottom:3px;	
}	

.cardWebsite {
	margin-top:3px;
	margin-bottom:3px;	
}	
	
.noCardLogo, .updateCardLogo {
	background-color: #fff;
	font-size: 90%;
	border: 1px dashed #B4B4B4;
	padding: 7px 0;
	margin:0 0 0 288px; /* should be same as cardLogo */
	text-align: center;
	vertical-align: middle;
	color: #B4B4B4; }
	
.updateCardLogo {
	background-color: #FFFfe0; }
		
.cardMain {
	padding:3px 10px 8px 10px;
	min-height:20px;
	font-size: 120%;
}
	

.assetsCol1 { 
	width:180px;
	float: left; 
}

.assetsCol2 { 
	/*min-height:72px;*/
	margin-left: 220px;
	width:350px; }

.cardCol1 {
	padding: 5px 20px;
	display:table-cell;
	min-width:120px; 
	width:34%;
}

.cardCol2 { 
	padding: 5px 20px;
	display:table-cell;
	min-width:120px; 
	width:33%;
}

.cardCol3 { 
	padding: 5px 20px;
	display:table-cell;
	min-width:120px; 
	width:33%;
}
	
.prodCardCol1 {
	min-height:40px;
	display:table-cell;
	min-width:400px; 
	width:50%;
}

.prodCardCol2 { 
	display:table-cell;
	min-width:120px; 
	width:50%;
	}
	
.cardPartnerType, .cardPartnerLocation, .cardPartnerLevel, .cardPartnerSpecialization {
	margin: 0 0 7px 0; }
	
.cardPartnerLevel, .cardPartnerSpecialization { }
	
.cardPartnerSpecialization strong, .cardPartnerLocation strong {
	display: block; }
	
.cardBody {
    -display:inline-block; /* needed for IE6 */
    overflow:hidden;
    width:100%;    
    padding: 0 10px 5px;
    display: table; }

.cardAssets {
	padding: 0 10px;
	/*position: relative; remove to fix ie7 contact tab bug */
	bottom: 0;
	left: 0; }
	
.cardAssets div {
	border:1px solid #B4B4B4;
	-moz-border-radius: 5px 5px 0 0;
	-webkit-border-top-right-radius:5px;
	-webkit-border-top-left-radius:5px;
	float:left;
	margin:0 1px -1px 0;
	padding:0;
	width:auto; }

.cardAssets div.highlight {
	background-color: #FFFfe0; }
			
.card .more {
	margin:0 0 0 330px;
	padding:0 15px 4px 0;
	text-align:right; }
	
.cardAssets div a {
	display:block;
	padding:2px 10px;
	margin-bottom:-1px;
	text-decoration:none;
	white-space: nowrap;
	border-bottom: none; }
	
.cardAssets div:hover {
	background-color: #f6f6f6; }
	
.cardAssets div a.on {
	border-bottom: 0;
	background-color: #f6f6f6;
	-moz-border-radius: 5px 5px 0 0;
	-webkit-border-top-right-radius:5px;
	-webkit-border-top-left-radius:5px; }
	
.cardAssets div a.highlight {
	background-color:#F6F6F6;
	border-bottom:0 none;
	-moz-border-radius: 5px 5px 0 0;
	-webkit-border-top-right-radius:5px;
	-webkit-border-top-left-radius:5px; }
	
.cardAssets div.cardApplicationTab a {	
	/*padding-bottom:3px;  causes issue on my card view*/
	 }
	
.cardAssets div.cardApplicationTab a.on {
	background-color:#F6F6F6;
	border-bottom:none;
	padding-bottom:3px; }
	
.cardAssetsOn {
	border: 1px solid #B4B4B4;
	background-color: #f6f6f6;
	border-top: none;
	padding:7px 3px 12px 20px;
	/*width:85%;*/
	width:50%;
	margin-left: 11px;
	font-size: 10px;
	display:inline-block;
	min-height: 45px; /* Needed for IE6 */ }
	
.cardAssetsOn strong { display: block; }
	
.cardAssetsOn .cardAssets1 {
	margin-right:4px;
	padding-bottom: 5px;
	width:49%;
	float: left; }
	
.cardAssetsOn .cardAssets2 {
	width: 50%;
	padding-bottom: 5px;
	float: left; }
	
.cardAssetsOn .cardAssets1App {
	margin-right:4px;
	padding-bottom: 5px;
	width:44%;
	float: left; }
	
.cardAssetsOn .cardAssets2App {
	width: 54%;
	padding-bottom: 5px;
	float: left; }
	
.cardAssetsOn .cardAssetsTop { padding: 0 0 12px 0; }
.cardAssetsOn ul { margin: 0; padding: 0; }
.cardAssetsOn ul li { margin: 0; list-style-type:none; }
	
/*.cardAssetsOn .cardAssets3 {
	width: 31%;
	float: left; }
*/	
.cardAssetsOff {
	display: none; }
	

/*
* Partner Locator layout
 *************************************/

#onethirdColumn { float:left; width:235px; }

#twothirdsColRight { margin-left:250px; }

#locatorResults { min-height: 300px;}
	
#locatorResults a:link, #locatorResults a:visited, #locatorResults a:hover, #locatorResults a:active,
.locationCrumbs a,
#partnerDetails, #productDetails a { text-decoration: none; }
	

/*
* Tabs
 *************************************/

#tabWrap {
    padding: 15px 0 0 0;
    z-index: 10;
    position: relative;
    font-size: 90%;
    height: 22px; }
	
#tabWrap div { height: 1%; } /* Needed for IE6 */

#tabWrap ul.whiteBox_nav li.selected a {
    background-image: url("http://www.redhat.com/g/chrome/graytab_left_on.gif");
    background-repeat: no-repeat;
    background-position: top left;
    color: #333;
    border-bottom: 0;
    height:23px; }
	
#tabWrap ul.whiteBox_nav li.selected {
	background-image:url(/g/chrome/graytab_right_on.gif);
	background-position:right top;
	background-repeat:no-repeat;
	border-bottom:0 none; }

.tabContentWrap {
	margin:0;
	padding: 5px 10px 15px 10px;
	border:1px solid #B4B4B4;
	font-size:88%;	}
	
.tabContentWrap select {
	font-size: 9px;
	padding: 2px 0; }

.tabContentWrap input, .tabContentWrap button.tabSearchInput {
	background:#eee;
	border:1px solid #999;
	padding:2px; }
	
.tabContentWrap input[type=checkbox] {
	border: none;
	background: none;
	margin-left:6px; }
	
.tabContentWrap div.last {
	padding: 0;
	border-bottom: 0; }
	
.tabContentWrap a {
	text-decoration: none;
	font-size: 90%; }

.tabs{ position:relative; }
	
.tabs .corner_tabs_topleft {
	top:0px;
	left:0;
	background-position:top left; }
	
.tabs .corner_tabs_topright {
	top:0px;
	right:0;
	-right:-1px; /* needed for IE6 */ 
	background-position:top right; }

.tabs .corner_tabs_bottomleft {
	left:0;
	bottom:0;
	background-position:bottom left;
-background-position:0 10px; }
	
.tabs .corner_tabs_bottomright {
	bottom:0;
	right:0;
-right:-1px; /* needed for IE6 */ 
	background-position:bottom right;
-background-position:10px 10px; /* needed for IE6 */  }

.corner_tabs_topleft,.corner_tabs_topright,.corner_tabs_bottomleft,.corner_tabs_bottomright {
	position:absolute;
	width:10px;
	height:10px;
	z-index:2;
-overflow:hidden; /* needed for IE6 */  }

#tabSearch, #tabBrowse { display:block }

.tabSearchFooter {
	text-align: right; 
	padding-top: 5px;	
}


/*
* Search Form Area
 *************************************/

input.partnerKeyword {
	width: 85%;
	margin-top: 5px;
	margin-bottom: 5px;
}

#keywords-helpButton img {
	margin-top: 3px;
}
	
#searchPartnerFilters label {
	font-weight: normal; }
	
#searchPartnerFilters div, #searchLocationFilters div {
	padding: 2px 0 10px;
	margin-bottom:5px;
	border-bottom: 1px solid #ccc; }


.paginationBlock {
	display:table;
	width:100%;
}

.pageIndicator {
	display:table-cell;
}

/*
* Pagination
 *************************************/

.pagination {
    padding:3px;
    text-align:right;
    font-family:Arial, Helvetica, sans-serif;
    font-size:12px;
	display:block;
	width:100%;
    margin-right: 10px; }
    
.paginationBottom {
    margin-top: 10px; 
}

.pagination a {
    padding: 2px 5px 2px 5px;
    margin-right: 2px;
    border: 1px solid #333333;
    text-decoration: none;
}
    
.pagination a:hover, .pagination a:active {
    border: 1px solid #333333;
    color: #FFFFFF;
    background-color: #CC0000;
    cursor:pointer; 
}

.current {
    padding: 2px 5px 2px 5px;
    margin-right: 2px;
    font-weight: bold;
    background-color: #FFFFFF;
    border: 1px solid #FFFFFF;
}
    
.disabled {
    padding: 2px 5px 2px 5px;
    margin-right: 2px;
    border: 1px solid #CCCCCC;
    color: #CCCCCC; }

.updatingResults {
	margin: 0 auto;
	padding: 2px; }

.updatingResults span {
	padding: 15px 25px;
	border: 1px solid #C0DAE7;
	text-align: center;
	background-color: #E5F0F5;
	display: block; 
}
	
	
/*
* Products or Partners results sets
 ************************************ */
	
.locatorHideCounts { display: none; }

#displaySet {
	padding: 0 0 7px;
	margin:0;
	border-bottom: 1px solid #B4B4B4; }
	 
#displaySet span.activeSet {
	font-weight: bold;
	padding:3px 0;
	-moz-border-radius: 5px 5px 0 0;
	-webkit-border-top-right-radius:5px;
	-webkit-border-top-left-radius:5px;
	-webkit-border-bottom-right-radius:0;
	-webkit-border-bottom-left-radius:0;
	border: 1px solid #B4B4B4;
	border-bottom: 0;
	background-color: #fff;
	display: block; }
	
#displaySet span#partnersFoundTabLink, #displaySet span#productsFoundTabLink {
	display: block;
	padding: 3px 0;}
	
#displaySet span#numberPartnersFound, #displaySet span#numberProductsFound {
	display: inline; }
	
#displaySet .on {
	background: url('/g/activeSetArrow.gif') 50% 23px no-repeat; }
	
.off {
	border: none;
	color: #cccccc;
	padding-top: 3px;
}	
	
#displaySetOne {
	width: 49%;
	padding: 0 0 12px;
	margin-left: 5px;
	float: left;
	text-align: center; }

#displaySetTwo {
	width: 49%;
	padding: 0 0 12px;
	float: left;
	text-align: center; }
	
.partnerTypeOnly {
    background:#DDDDDD 95% 50% no-repeat;
	color:#000000;
	font-size: 87%;
	margin:10px -10px;
	border-top: 1px solid #333333;
	padding: 5px;
	
}

.partnerTypeOnly label {
   display:block;
   margin-left:25px;
   margin-top:4px;
   margin-right:4px; }

.partnerTypeOnly input {
   float:left; } 

.partnerTypeOnlyDisabled {
    background:#CCCCCC 95% 50% no-repeat;
	color:#666666;
	font-size: 87%;
	margin:10px -10px;
	border-top: 1px solid #333333;
}

.partnerTypeOnlyDisabled label {
   display:block;
   margin-left:25px;
   margin-top:4px; }

.partnerTypeOnlyDisabled input {
   float:left; }

.partnerTypeFilters {
	margin-left: 15px;
}

.sectionOptions {
	background: #EEEEEE;
	margin:-5px -10px;
	padding: 5px 25px !important;
	border-bottom: 1px solid #333333 !important;
}

.sectionOptionsDisabled {
	background: #EEEEEE;
	color: #666666;
	margin:-5px -10px;
	padding: 5px 25px !important;
	border-bottom: 1px solid #333333 !important;
}



#resetButton {
	float: left;
}

.map_canvas
{
	height:300px; 
	width: 300px;
	margin: 20px 0px 5px 20px;
}

.map_note 
{
	text-align:center;
	margin: 0px 0px 20px 20px;
}

.resultsTable 
{
	display:table;
	width: 100%;	
}

.resultsBlock 
{
	display:table-cell; 
	width: 100%;
	vertical-align:top;
}

.map_container
{
	display:table-cell; 
	width: 400px;
	vertical-align:top;
}

.productPartnerName {
	display:table;
}

.partnerName {
	display:table-cell;
	padding-left: 10px; 
}

.productName {
	display:table-cell; 
	width: 390px;
}

/* Default clear works in IE7 as well */
.clearWrap:after {
	content:".";
	display: block;
	height: 0;
	clear:both;
	visibility:hidden;
}

.right-side-link {
    border: 1px solid #CCCCCC;
    float: right;
    margin-right: 15px;
    padding: 2px 13px;
    width: auto;
}

#container {
	min-width: 500px;
}

#top {
	padding: 8px 0 20px;
}
	
#bottom {
	border-top: 1px solid #ccc;
	padding: 20px 0 8px;
}

.finder-links {
	margin-top: -16px;
	margin-left: 115px;
}
	
.vertical {
	display: inline;
	float: left;
	margin-left: 8px;
  width: 275px;
}
	
.vertical.span2 {
	width: 550px;
}
	
.specializations {
	list-style: none;
}
	
.specializations li {
	margin: 0;
	padding: 0;
	clear: left;
}
	
.specializations input {
	width: auto;
	float: left;
	margin: 0 10px 4px 0;
}
		
.detailsLogo {
	display:inline;
}

		