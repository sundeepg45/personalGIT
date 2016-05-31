@charset "UTF-8";

/* PORTAL PUBLISHER CSS  - Styles the page area containing the
custom messages and wrapper elements
 ----------------------------------------------------------*/


body { 
	font-size: x-small; /* for IE 5 Win */
	voice-family: "\"}\"";
	voice-family: inherit;
	font-size: small; /* for compliant browsers */
	margin: 0px;
	padding: 0px;
	font-family:Arial, Helvetica, sans-serif;
}
html>body { /* be nice to Opera */
	font-size: small;
}

#topRowWrapper{
    background-color:#fff;
    border: 1px none #ccc;
    height:233px;
    width:936px;
    padding:0px; 
    margin-bottom:20px;
}

/* PORTLET CSS - styles the portlet
 ----------------------------------------------------------*/
#portletWrapper{
    margin-top:0px;
    margin-left:0px;
    width:440px;
    float:left;
    margin-right:13px;
    position:relative;
    margin-bottom:20px;
	border: 1px solid #ccc;
	-moz-border-radius: 8px;
	-webkit-border-radius: 8px;
	border-radius: 8px;        
}


#portletContent{
    height:186px;
    width:440px;
}
#portletContent form{
    margin:0px;
}


#portletHeader {
	width: 440px;
	height: 39px;
	position: relative;
	font-family: Arial, Helvetica, sans-serif;
	font-size: 13px;
	font-weight: bold;
	color: #A41B1B;
}




#leftColumnWrapper{
	float:left;
	height:176px;
	margin-top:10px;
	overflow:hidden;
	width:200px;
}


#portletLeftNav{
    width:200px;
    margin:0px;
    padding:0px;
    

}
#leftSideBG{
    width:199px;
    background-color:#f5f5f5;
    height:100%;
    border-right: 1px solid #c9c9c9;
    
	
}

#portletRightNav{
	width:210px;
    margin:0px;
	margin-top:0px;
	margin-right: 0px;
    padding:0px;
    float:right;
    height: 167px;
    overflow: auto;
    padding-top: 20px;

}


#portletLeftNav li {
	font-size:95%;
	
	
}

#portletLeftNav li a {
	color: #A41B1B;
	width:189px;
	padding-left:10px;
	padding-top:5px;
	padding-bottom:5px;
	display:block;
	text-decoration:none;
	border-right: 1px solid #cccccc;
	border-bottom: 1px solid #b4b4b4;
	border-top: 1px solid #f5f5f5;
	background-color: #CBCBCB;
	
}

#portletLeftNav #selectedNav a {
	background-image:none;
	color:#FF0000;
	background-color:#FFF;
	border-right:none;
	border-top:none;
	
	
}


#portletLeftNav li a:hover {
	color:#FFFFFF;
	text-decoration:none;
	background-color:#FF0000;
}


#portletRightNav li {
list-style-type: none;
padding-bottom:6px;
margin-right: 10px;
color:#A41B1B;
}

#portletRightNav li a {
	color:#A41B1B;
}



#portletClearBoth{
    clear:both;

}

#portletFooter{
	width: 442px;
	height: 0px;
	border-bottom: 1px solid #c9c9c9;
}




#leftTitle{
	width:50%;
	position: relative;
	float: left;
	height: 37px;
	border-bottom:2px solid #8A8A8A;
}
#rightTitle{
	width:50%;
	position: relative;
	float: right;
	height: 37px;
	border-bottom:2px solid #8A8A8A;
}

#leftTitle h1 {
	padding-top: 10px;
	padding-left: 10px;
	font-size:13px;
	font-weight:bold;
	margin: 0px;
}

#rightTitle h1 {
	padding-top: 10px;
	font-size:13px;
	font-weight:bold;
	margin: 0px;
}

/* uiBOX CSS - styles the non portlet custom message boxes
 ----------------------------------------------------------*/

/* wrappers */

#uiBoxWrapper{
    font-family: Arial, Helvetica, sans-serif;
    float:left;
	border: 1px solid #ccc;
	-moz-border-radius: 8px;
	-webkit-border-radius: 8px;
	border-radius: 8px;    
	margin-bottom:20px;
	height:231px;
    position:relative;
    width:300px;
    margin-right:0px;    
}

#uiBoxWrappervst{
    font-family: Arial, Helvetica, sans-serif;
    float:left;
    border: 1px solid #C9C9C9;
	margin-bottom:20px;
	height:231px;
    position:relative;
    width:300px;
    margin-right:0px;
    background-color: #ffffff;
    clear:both;
}


#uiEndBoxWrapper{
    font-family: Arial, Helvetica, sans-serif;
    float:left;
    border: 1px solid #C9C9C9;
    margin-right:0px;
	margin-bottom:20px;
	background-color: #ffffff;
}

#uiBoxWrapper .endBox {
	margin-right:0px;
	background-color: #ffffff;
}

/* headers */
 

#uiBoxHeader{
    height:39px;
    width:100%;
	border-bottom: 4px solid #A41B1B;
}
#uiBoxHeader h1{
    border-bottom:2px solid #8A8A8A;
	color:#A41B1B;
	height:27px;
	margin:0;
	padding-bottom:0;
	padding-left:10px;
	padding-top:10px;
	width:290px;
	font-size: 13px;
	font-weight: bold;
}

/* content areas */ 
 
 
#uiBoxContent{
   	color:#000000;
	font-size:85%;
	line-height:120%;
	margin-top:0;
	height: 175px;
	width:100%;
    padding-left:0px;
}
 
#uiBoxContent p {
	margin:0px;
	padding:0px;
	height:2px;
}

#uiBoxContent a {
    display: block;
    height: 28px;
   	color:#A41B1B;
	font-size:12px;
	text-decoration:none;
}

#uiBoxContent a:hover {
	color:#A41B1B;
	text-decoration:underline;
}


#uiBoxContent p, #uiBoxContent a {
    padding-left:10px;
    padding-right:10px;
}

#uiBoxImage{
     width:300px;
     height:70px;
     display: inline;
}


#uiBoxContent sup {
	margin-left: -10px;
	font-style: italic;
}

/* footers */

#uiFooter {
	height:17px;
    position:absolute;
    bottom:0px;
	width:100%;
}




img {
    margin-right:0px;
    margin-bottom:0px;
    float:left;
}



/* COLUMNS AND ROWS LAYOUT GRID */


#uiColWrapper:after {
    content: "."; 
    display: block; 
    height: 0; 
    clear: both; 
    visibility: hidden;
}
 
#uiColWrapper{
    float:left;
    margin-right:13px;
    border: 0px none #fff;    
}

#uiRowWrapper {
    clear:both;
    border: 0px none #fff; 
}


/* IE7 FIX FOR MARGINS*/
*+html #uiRowWrapper  { 
	min-height: 256px;
	}
	
	

/* SINGLE TEXT BOX */

#textBoxWrapper{
    width:100%;
    border:1px solid #C9C9C9;
    float:left;
    margin-bottom:13px;
    margin-right:0px;
    position:relative;

}

#textBoxWrappervst{
    width:100%;
    border:1px solid #C9C9C9;
    float:left;
    margin-bottom:13px;
    margin-right:0px;
    position:relative;
     clear:both;
}
#textBoxWrapper #uiFooter{
    width:100%;
}

/* SINGLE IMAGE */

#imageBoxWrapper {
    width:240px;
    float:left;
    margin-bottom:13px;
    margin-right:0px;
}
#imageBoxWrapperimgvst{
    width:240px;
    float:left;
    margin-bottom:13px;
    margin-right:0px;
    clear:both;
}

#uiSingleImage {
    margin-right:0px;
    margin-bottom:0px;
    float:left;
}

#uiSingleText {
    margin:10px;
    margin-bottom:20px;
}

#uiSingleImage img {
    border: none;
}


#uiSingleText a {
	color:#A41B1B;
	font-size:12px;
	text-decoration:none;
	
}

#uiSingleText a:hover {
	text-decoration:underline;
}


.twoBox {
    height:262px;
    float:left;
}

/* CLEARING MANAGEMENT do not change or delete */

.vst {
    clear:both;
}
.imgvst {
    clear:both;
}
/*--SELF CLEARING DO NOT REMOVE--*/
#uiRowWrapper:after {
    content: "."; 
    display: block; 
    height: 0; 
    clear: both; 
    visibility: hidden;
}


