/* ******************** Default styles ******************** */
body {
	margin: 0;
	padding: 0;
	color: #2f2f2f; 
	font-family: "Lucida Grande", "Luxi Sans", "Trebuchet MS", "Bitstream Vera Sans", helvetica, verdana, arial, sans-serif;
	font-size: small;
	background-color: #f3f3f3;
	text-align: left;
}

h1, h2, h3, h4, h5 {color: #000000;}

h1 {font-size: 180%; margin: 5px 0 10px 0; font-weight: normal;}
h2 {font-size: 145%; margin: 5px 0 7px 0; font-weight: normal;}
h3 {font-size: 120%; margin: 0px 0 5px 0; font-weight: normal;}
h4 {font-size: 110%; margin: 0px 0 5px 0; font-weight: bold;}
h5 {font-size: 100%; margin: 0px 0 5px 0; font-weight: bold;}

p {margin: 0 0 10px 0; font-weight: normal;}
	
img {border: 0;}

ul {
	list-style: disc;
	background: none;
	padding: 0 0 0 10pt;
	margin: 5pt 0 5pt 10pt;
	}

ul li {padding: 0 0 4pt 0;}

/*div { margin: 0; padding: 0;}*/
span { margin: 0; padding: 0;}


/* ******************** Misc styles ******************** */

*.indent {padding-left: 15px;}
*.unindent {padding: 0 !important;}
*.hide {display: none;}
*.note {font-size: 85%;}
*.note-small {font-size: 75%; font-weight: normal;}
*.note-light {font-size: 90%; color: #c1c1c1;}
*.note-large {font-size: 115%;}
*.italic {font-style: italic; }
*.notify {color: #b00000;}
*.link-notify {cursor: pointer; color: #b00000;}
*.link-faux {cursor: pointer; color: #0066CC;}
#oTags {display: none;}

*.error,
#errors {color: #b00000;}
#errors h1 {font-size: medium;}
#errors span {display: block;}

span.accentPipe {
	color: #b00000;
	padding: 0 10px;
}

ul.flush {list-style: none; padding-left: 0; margin-left: 0;}
ul.none {list-style: none; padding-left: 0; margin-left: 10px;}
ul.notify {
	list-style-type: none;
	padding-left: 10px;
	margin-left: 10px; /* for ie */
	}
	
a.linkage, 	
span.linkage {
	list-style-type: none;
	background-image:url(http://www.redhat.com/partner_center/g/chrome/content/bullet_arrowblue.png);
	background-position: 0 .3em;
	background-repeat:no-repeat;
	margin: 4pt 0 4pt 0pt;
	padding-left: 10px;
}
ul.linkage {
	list-style-type: none;
	background: none;
}
ul.linkage li {
	background-image:url(http://www.redhat.com/partner_center/g/chrome/content/bullet_arrowblue.png);
	background-position: 0 .3em;
	background-repeat:no-repeat;
	padding-left: 10pt;
	margin: 0 0 0 -13px;
}

a.link-out {
	background-image:url(http://www.redhat.com/partner_center/g/chrome/content/link_out.png);
	background-position: top right;
	background-repeat: no-repeat;
	padding-right: 18px;
	}


/* ******************** Content Styles ******************** */

.col-outline {border: 1px solid #B4D4E2; background-color: #ffffff;}

.col-light {background-color: #ffffff;}
.col-accent-light {background: url(http://www.redhat.com/partner_center/g/chrome/content/bluefade_light.png) repeat-x bottom left; background-color: #D5E8F0;}

.col-light .col2,
.col-light .col3,
.col-accent-light .col2,
.col-accent-light .col3 {border-left: 2px solid #ffffff;}

.col0 {padding: 10px 10px 10px 15px;}
.col1,
.col2,
.col3 {
	position: relative;
	display: block;
	padding: 10px 10px 10px 15px;
	}

.col1:after,
.col2:after,
.col3:after {
    content: "."; 
    display: block; 
    height: 1px;
    margin-top: -1px;
    overflow: hidden;
    clear: both; 
    visibility: hidden;
    }
    
.col2right {clear: both;}
.col2right .col1 {
	float: left;
	width: 64%;
	}
.col2right .col2 {
	padding-left: 10px;
	margin-left: 67%;
	height: auto;
	}
	
	* html .col2right .col2 {margin-left: 65%; padding-left: 10px;} /* Holly Hack Targets IE Win only */


.col3split {clear: both;}
.col3split .col1 {
	float: left;
	width: 30%;
	border-right: 2px solid #ffffff;
	}
.col3split .col2 {
	float: left;
	width: 31%;
	padding-right: 0;
	margin-left: -2px;
	}
.col3split .col3 {
	margin-left: 67%;
	}
	
	* html .col3split .col3 {margin-left: 65%;} /* Holly Hack Targets IE Win only */
    
.col2split {clear: right;}
.col2split .col1 {
	float: left;
	width: 47%;
	}
.col2split .col2 {
	margin-left: 50%;
	}
	
	* html .col2split .col2 {height: 1px;} /* Holly Hack Targets IE Win only */

.hbox {
    background: #ffffff url("http://www.redhat.com/partner_center/g/chrome/content/rbox_tl.png") top left no-repeat;
    text-align: left;
    width:100%;
    margin-bottom: 25px;
	}
.hbox h2.corner {
    background: url("http://www.redhat.com/partner_center/g/chrome/content/rbox_tr.png") top right no-repeat;
    padding: 15px 15px 10px;
    margin: 0;
}
/* if no h2 is needed */
.hbox h2.none {padding: 0;}
.hbox h2.none span {visibility: hidden;}

.hbox-body {
    background: url("http://www.redhat.com/partner_center/g/chrome/content/rbox_r.png") top right repeat-y;
    border-left: 1px solid #cccccc;
    padding: 0 15px 5px;
    margin: 0;
    position: relative;
    top: -8px;
}
.hbox-body h2 {background: none;}
.hbox-footer {
    background: url("http://www.redhat.com/partner_center/g/chrome/content/rbox_bl.png") bottom left no-repeat;
    min-height: .25em;
}
.hbox-footer div {
    background: url("http://www.redhat.com/partner_center/g/chrome/content/rbox_br.png") bottom right no-repeat;
    padding: 0 15px 15px;
    display: block;
    margin: -1em 0 0 0;
    min-height: .25em;
    }

/* Default clear works in IE7 as well */
.clearWrap:after {
	content:".";
	display: block;
	height: 0;
	clear:both;
	visibility:hidden;
}

.clearWrap {display: inline-block;} /* Hide from IE Mac */
.clearWrap {display: block;}


/* ******************** Navigation Layout styles ******************** */

#utility-links {
	font-size: 85%;
	text-align: right;
	padding: 0 0 10px 0;
	margin: 0 -10px 0 0;
}
#utility-links ul {
	list-style: none;
	margin: 0;
	padding: 5px 0 0 0;
}
#utility-links ul li {
	display: inline;
	padding: 0 10px;
	border-left: 1px solid #b00000;
}
#utility-links ul li.first {border-left: none;}

#utilityAccount {
	float: right;
	line-height: 1em;
	background: #eee url(/g/chrome/nav/utilBkgdRight.png) no-repeat bottom right;
	margin-right: 10px;
}

#utilityAccount p {
	margin: 0;
	background: url(/g/chrome/nav/utilBkgdLeft.png) no-repeat bottom left;
	display: block;
	padding: 6px 15px 8px 15px;
}

a#utilityCart {
	background: url(/g/chrome/nav/cart.gif) no-repeat top left;
	padding-left: 26px;
	padding-bottom: 4px;
	padding-top: 3px;
}


/* generic ul pipe seperated */
ul.separate {
	list-style: none;
	padding: 0;
	margin: 15px 0;
}

ul.separate li {
	display: inline;
	padding: 0 10px;
	border-left: 1px solid #555;
}

ul.separate li.first {border-left: none !important; padding-left: 0;}

#footer ul.separate {
	margin: 0;
}

#footer ul.separate li {
	border-left: 1px solid #ccc;
}
/* ******************** Form and Fieldset styles ******************** */
	
fieldset.fieldsetform {
	background-color: #FFF ;
	font-family: "Lucida Grande", "Luxi Sans", "Trebuchet MS", helvetica, verdana, arial, sans-serif;
	border:0;
	margin: 0 0 15px 0;
	padding:15px 0;
	}

fieldset.fieldsetform legend {
	background:#fff none repeat scroll 0% 50%;
	font-weight:bold;
	font-size: 115%;
	padding:0 7px;
	}
	
.rowform {padding:0 0 10px 0;}
	
.rowform:after {
    content: "."; 
    display: block; 
    height: 0; 
    clear: both; 
    visibility: hidden;}

.rowform {display:inline-block;}
/* Hide from IE6 \*/
.rowform {display:block;}
/* End */

.rowform span {
	margin-left: 185px;
	display: block; }
	
.rowform span+span {
	padding-top: 4px;}
	
.rowform span strong { 
	font-size: 120%;
	display: block; }
	
.rowform label {
	float:left;
	font-weight:bold;
	text-align:left;
	width:175px;
	font-size: 93%;
	}
	
fieldset.fieldsetform input.rowbutton {
	width: auto; 
	display: inline;
	margin: 10px;
	}

fieldset.fieldsetform select, fieldset.fieldsetform input, fieldset.fieldsetform textarea {
	margin-left:10px;
	font-size: 100%;
	padding: 1px;
	display: inline;
	font-family: "Lucida Grande", "Luxi Sans", "Trebuchet MS", helvetica, verdana, arial, sans-serif;
	}
	
fieldset.fieldsetform input[type=text],
fieldset.fieldsetform select,
fieldset.fieldsetform textarea {
	min-width: 375px;}

fieldset.fieldsetform .selectsize2 {width: 375px;}
fieldset.fieldsetform .selectsize1 {width: 160px;}
	
fieldset.fieldsetform .checkbox_radio {
	width: 13px;
	display: inline;
	}

#steps {
	margin: 0 0 5px;
	padding: 0;
	}
	
#steps ol {
	color:#999999;
	font-size:x-small;
	margin:0;
	padding:0;
	text-align:right;
	}

#steps ol li {
	display: inline;
	padding-left: 6px;
	}
	
#steps li strong {
	font-weight: bold;
	color: #c00; 
	}

input.button {
	padding: 1px 4px;
	border-top: 1px solid #8FC9E5;
	border-right: 1px solid #8FC9E5;
	border-left: 1px solid #4999D8;
	border-bottom: 1px solid #4999D8;
	background-color: #CBEAF7;
	color: #3D7FB1;
	}

a.button{
	font-size: 13px;
	font-weight:bold;
	text-decoration:none;
	padding:5px 0 8px 0;
	margin-right:.5em
	}

/* targets IE7 only */
*:first-child+html .buttonWrap a.button { padding:5px 0 5px 0
	}

* html a.button{
	padding:0 0 0 5px;
	margin:5px 0 0 0
	}

* html a.button span{
	line-height:26px
	}

a.button span{
	line-height:24px;
	color:#fff;
	margin:0 0 0 15px;
	padding:5px 20px 8px 5px
	}

/* targets IE7 only */
*:first-child+html .buttonWrap a.button span { padding:5px 20px 5px 5px
	}

a.button {background:url(/g/chrome/button-left.gif) no-repeat center left
	}
a.button span{background:url(/g/chrome/button-right.gif) no-repeat center right
	}
	
	
	
/**
	Partner Onboarding
	****************************************/	

.resourceDrawer {
	padding: 15px 10px;
	background-color: #eee;
	border: 1px solid #ccc;
	-moz-border-radius: 8px;
	-webkit-border-radius: 8px;}
	
#onboardSteps {margin:0 0 20px 0;padding: 0;}
#onboardSteps li {
	margin-left:0;
	padding: 2px 0 2px 25px;
	list-style-position: inside;}
	
#onboardSteps li.completed {
	background: transparent url("/g/icons/check-icon.png") no-repeat 5px 5px;}
	
#onboardSectionTitle {
	border-bottom: 2px solid #ddd;
	font-weight: bold;
	font-size: 150%;
	margin:12px 0;}
	
fieldset.noBorder {
	border: 0 !important;
	padding: 0; }

#onboardLogin {
	width: 64%;
	margin-bottom: 40px;}
	
#onboardLogin .panelLeft {
	float:left;width:49%;border-right:1px solid #ccc;padding-right: 10px;}

#onboardLogin .panelRight { 
	margin-left: 54%; padding-top: 1px;}


/** Table **/

table th, table td {
	padding:4px;
	vertical-align:top;
  text-align:left; }
	
table th {
	color:#555; }
	
table tr.even {
	background-color: #e6e6e6;}
	
table tr.odd {
	background-color: #e0e0e0;}
	
table.existingCompanyTable {
	margin: 3px 0 20px;
	border-left: 1px solid #bbb;
	border-right: 1px solid #bbb;
	width: 100%;
	clear:right;
	border-collapse: collapse; }


table.existingCompanyTable td {
	border: 1px solid #bbb;
	padding: 6px;
	text-align: left;
	vertical-align: top;
	background-color: #fff;
	color: #333; }
	
table.existingCompanyTable th {
	border-style: solid;
	border-width:1px;
	border-color: #999;
	padding: 5px;
	text-align: left;
	vertical-align: top;
	background-color: #c9c9c9;
	color: #333; }
	
table.existingCompanyTable tr {
	background-color: #fff;
	padding-bottom: 10px; }
	




