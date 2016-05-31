/*!
 * Bootstrap v3.1.1 (http://getbootstrap.com)
 * Copyright 2011-2014 Twitter, Inc.
 * Licensed under MIT (https://github.com/twbs/bootstrap/blob/master/LICENSE)
 */

/*! normalize.css v3.0.0 | MIT License | git.io/normalize */
html {
  font-family: sans-serif;
  -webkit-text-size-adjust: 100%;
      -ms-text-size-adjust: 100%;
}
body {
  margin: 0;
}
article,
aside,
details,
figcaption,
figure,
footer,
header,
hgroup,
main,
nav,
section,
summary {
  display: block;
}
audio,
canvas,
progress,
video {
  display: inline-block;
  vertical-align: baseline;
}
audio:not([controls]) {
  display: none;
  height: 0;
}
[hidden],
template {
  display: none;
}
.red-hat-content a {
  background: transparent;
}
.red-hat-content a:active,
.red-hat-content a:hover {
  outline: 0;
}
.red-hat-content abbr[title] {
  border-bottom: 1px dotted;
}
.red-hat-content b,
.red-hat-content strong {
  font-weight: bold;
}
.red-hat-content dfn {
  font-style: italic;
}
.red-hat-content h1 {
  margin: .67em 0;
  font-size: 2em;
}
.red-hat-content mark {
  color: #000;
  background: #ff0;
}
.red-hat-content small {
  font-size: 80%;
}
.red-hat-content sub,
.red-hat-content sup {
  position: relative;
  font-size: 75%;
  line-height: 0;
  vertical-align: baseline;
}
.red-hat-content sup {
  top: -.5em;
}
.red-hat-content sub {
  bottom: -.25em;
}
.red-hat-content img {
  border: 0;
}
.red-hat-content svg:not(:root) {
  overflow: hidden;
}
.red-hat-content figure {
  margin: 1em 40px;
}
.red-hat-content hr {
  height: 0;
  -moz-box-sizing: content-box;
       box-sizing: content-box;
}
.red-hat-content pre {
  overflow: auto;
}
.red-hat-content code,
.red-hat-content kbd,
.red-hat-content pre,
.red-hat-content samp {
  font-family: monospace, monospace;
  font-size: 1em;
}
.red-hat-content button,
.red-hat-content input,
.red-hat-content optgroup,
.red-hat-content select,
.red-hat-content textarea {
  margin: 0;
  font: inherit;
  color: inherit;
}
.red-hat-content button {
  overflow: visible;
}
.red-hat-content button,
.red-hat-content select {
  text-transform: none;
}
.red-hat-content button,
.red-hat-content html input[type="button"],
.red-hat-content input[type="reset"],
.red-hat-content input[type="submit"] {
  -webkit-appearance: button;
  cursor: pointer;
}
.red-hat-content button[disabled],
.red-hat-content html input[disabled] {
  cursor: default;
}
.red-hat-content button::-moz-focus-inner,
.red-hat-content input::-moz-focus-inner {
  padding: 0;
  border: 0;
}
.red-hat-content input {
  line-height: normal;
}
.red-hat-content input[type="checkbox"],
.red-hat-content input[type="radio"] {
  box-sizing: border-box;
  padding: 0;
}
.red-hat-content input[type="number"]::-webkit-inner-spin-button,
.red-hat-content input[type="number"]::-webkit-outer-spin-button {
  height: auto;
}
.red-hat-content input[type="search"] {
  -webkit-box-sizing: content-box;
     -moz-box-sizing: content-box;
          box-sizing: content-box;
  -webkit-appearance: textfield;
}
.red-hat-content input[type="search"]::-webkit-search-cancel-button,
.red-hat-content input[type="search"]::-webkit-search-decoration {
  -webkit-appearance: none;
}
.red-hat-content fieldset {
  padding: .35em .625em .75em;
  margin: 0 2px;
  border: 1px solid #c0c0c0;
}
.red-hat-content legend {
  padding: 0;
  border: 0;
}
.red-hat-content textarea {
  overflow: auto;
}
.red-hat-content optgroup {
  font-weight: bold;
}
.red-hat-content table {
  border-spacing: 0;
  border-collapse: collapse;
}
.red-hat-content td,
.red-hat-content th {
  padding: 0;
}
@media print {
  .red-hat-content * {
    color: #000 !important;
    text-shadow: none !important;
    background: transparent !important;
    box-shadow: none !important;
  }
  .red-hat-content a,
  .red-hat-content a:visited {
    text-decoration: underline;
  }
  .red-hat-content a[href]:after {
    content: " (" attr(href) ")";
  }
  .red-hat-content abbr[title]:after {
    content: " (" attr(title) ")";
  }
  .red-hat-content a[href^="javascript:"]:after,
  .red-hat-content a[href^="#"]:after {
    content: "";
  }
  .red-hat-content pre,
  .red-hat-content blockquote {
    border: 1px solid #999;

    page-break-inside: avoid;
  }
  .red-hat-content thead {
    display: table-header-group;
  }
  .red-hat-content tr,
  .red-hat-content img {
    page-break-inside: avoid;
  }
  .red-hat-content img {
    max-width: 100% !important;
  }
  .red-hat-content p,
  .red-hat-content h2,
  .red-hat-content h3 {
    orphans: 3;
    widows: 3;
  }
  .red-hat-content h2,
  .red-hat-content h3 {
    page-break-after: avoid;
  }
  .red-hat-content select {
    background: #fff !important;
  }
  .red-hat-content .navbar {
    display: none;
  }
  .red-hat-content .table td,
  .red-hat-content .table th {
    background-color: #fff !important;
  }
  .red-hat-content .btn > .caret,
  .red-hat-content .dropup > .btn > .caret {
    border-top-color: #000 !important;
  }
  .red-hat-content .label {
    border: 1px solid #000;
  }
  .red-hat-content .table {
    border-collapse: collapse !important;
  }
  .red-hat-content .table-bordered th,
  .red-hat-content .table-bordered td {
    border: 1px solid #ddd !important;
  }
}
.red-hat-content * {
  -webkit-box-sizing: border-box;
     -moz-box-sizing: border-box;
          box-sizing: border-box;
}
.red-hat-content *:before,
.red-hat-content *:after {
  -webkit-box-sizing: border-box;
     -moz-box-sizing: border-box;
          box-sizing: border-box;
}
html {
  font-size: 62.5%;

  -webkit-tap-highlight-color: rgba(0, 0, 0, 0);
}
body {
  font-family: "Helvetica Neue", Helvetica, Arial, sans-serif;
  font-size: 14px;
  line-height: 1.42857143;
  color: #333;
  background-color: #fff;
}
.red-hat-content input,
.red-hat-content button,
.red-hat-content select,
.red-hat-content textarea {
  font-family: inherit;
  font-size: inherit;
  line-height: inherit;
}
.red-hat-content a {
  color: #08C0FC;
  text-decoration: none;
}
.red-hat-content a:hover,
.red-hat-content a:focus {
  text-decoration: underline;
}
.red-hat-content a:focus {
  outline: thin dotted;
  outline: 5px auto -webkit-focus-ring-color;
  outline-offset: -2px;
}
.red-hat-content figure {
  margin: 0;
}
.red-hat-content img {
  vertical-align: middle;
}
.red-hat-content .img-responsive,
.red-hat-content .thumbnail > img,
.red-hat-content .thumbnail a > img,
.red-hat-content .carousel-inner > .item > img,
.red-hat-content .carousel-inner > .item > a > img {
  display: block;
  max-width: 100%;
  height: auto;
}
.red-hat-content .img-rounded {
  border-radius: 6px;
}
.red-hat-content .img-thumbnail {
  display: inline-block;
  max-width: 100%;
  height: auto;
  padding: 4px;
  line-height: 1.42857143;
  background-color: #fff;
  border: 1px solid #ddd;
  border-radius: 4px;
  -webkit-transition: all .2s ease-in-out;
          transition: all .2s ease-in-out;
}
.red-hat-content .img-circle {
  border-radius: 50%;
}
.red-hat-content hr {
  margin-top: 20px;
  margin-bottom: 20px;
  border: 0;
  border-top: 1px solid #eee;
}
.red-hat-content .sr-only {
  position: absolute;
  width: 1px;
  height: 1px;
  padding: 0;
  margin: -1px;
  overflow: hidden;
  clip: rect(0, 0, 0, 0);
  border: 0;
}
.red-hat-content h1,
.red-hat-content h2,
.red-hat-content h3,
.red-hat-content h4,
.red-hat-content h5,
.red-hat-content h6,
.red-hat-content .h1,
.red-hat-content .h2,
.red-hat-content .h3,
.red-hat-content .h4,
.red-hat-content .h5,
.red-hat-content .h6 {
  font-family: inherit;
  font-weight: 500;
  line-height: 1.1;
  color: inherit;
}
.red-hat-content h1 small,
.red-hat-content h2 small,
.red-hat-content h3 small,
.red-hat-content h4 small,
.red-hat-content h5 small,
.red-hat-content h6 small,
.red-hat-content .h1 small,
.red-hat-content .h2 small,
.red-hat-content .h3 small,
.red-hat-content .h4 small,
.red-hat-content .h5 small,
.red-hat-content .h6 small,
.red-hat-content h1 .small,
.red-hat-content h2 .small,
.red-hat-content h3 .small,
.red-hat-content h4 .small,
.red-hat-content h5 .small,
.red-hat-content h6 .small,
.red-hat-content .h1 .small,
.red-hat-content .h2 .small,
.red-hat-content .h3 .small,
.red-hat-content .h4 .small,
.red-hat-content .h5 .small,
.red-hat-content .h6 .small {
  font-weight: normal;
  line-height: 1;
  color: #999;
}
.red-hat-content h1,
.red-hat-content .h1,
.red-hat-content h2,
.red-hat-content .h2,
.red-hat-content h3,
.red-hat-content .h3 {
  margin-top: 20px;
  margin-bottom: 10px;
}
.red-hat-content h1 small,
.red-hat-content .h1 small,
.red-hat-content h2 small,
.red-hat-content .h2 small,
.red-hat-content h3 small,
.red-hat-content .h3 small,
.red-hat-content h1 .small,
.red-hat-content .h1 .small,
.red-hat-content h2 .small,
.red-hat-content .h2 .small,
.red-hat-content h3 .small,
.red-hat-content .h3 .small {
  font-size: 65%;
}
.red-hat-content h4,
.red-hat-content .h4,
.red-hat-content h5,
.red-hat-content .h5,
.red-hat-content h6,
.red-hat-content .h6 {
  margin-top: 10px;
  margin-bottom: 10px;
}
.red-hat-content h4 small,
.red-hat-content .h4 small,
.red-hat-content h5 small,
.red-hat-content .h5 small,
.red-hat-content h6 small,
.red-hat-content .h6 small,
.red-hat-content h4 .small,
.red-hat-content .h4 .small,
.red-hat-content h5 .small,
.red-hat-content .h5 .small,
.red-hat-content h6 .small,
.red-hat-content .h6 .small {
  font-size: 75%;
}
.red-hat-content h1,
.red-hat-content .h1 {
  font-size: 36px;
}
.red-hat-content h2,
.red-hat-content .h2 {
  font-size: 30px;
}
.red-hat-content h3,
.red-hat-content .h3 {
  font-size: 24px;
}
.red-hat-content h4,
.red-hat-content .h4 {
  font-size: 18px;
}
.red-hat-content h5,
.red-hat-content .h5 {
  font-size: 14px;
}
.red-hat-content h6,
.red-hat-content .h6 {
  font-size: 12px;
}
.red-hat-content p {
  margin: 0 0 10px;
}
.red-hat-content .lead {
  margin-bottom: 20px;
  font-size: 16px;
  font-weight: 200;
  line-height: 1.4;
}
@media (min-width: 768px) {
  .red-hat-content .lead {
    font-size: 21px;
  }
}
.red-hat-content small,
.red-hat-content .small {
  font-size: 85%;
}
.red-hat-content cite {
  font-style: normal;
}
.red-hat-content .text-left {
  text-align: left;
}
.red-hat-content .text-right {
  text-align: right;
}
.red-hat-content .text-center {
  text-align: center;
}
.red-hat-content .text-justify {
  text-align: justify;
}
.red-hat-content .text-muted {
  color: #999;
}
.red-hat-content .text-primary {
  color: #428bca;
}
.red-hat-content a.text-primary:hover {
  color: #3071a9;
}
.red-hat-content .text-success {
  color: #3c763d;
}
.red-hat-content a.text-success:hover {
  color: #2b542c;
}
.red-hat-content .text-info {
  color: #31708f;
}
.red-hat-content a.text-info:hover {
  color: #245269;
}
.red-hat-content .text-warning {
  color: #8a6d3b;
}
.red-hat-content a.text-warning:hover {
  color: #66512c;
}
.red-hat-content .text-danger {
  color: #a94442;
}
.red-hat-content a.text-danger:hover {
  color: #843534;
}
.red-hat-content .bg-primary {
  color: #fff;
  background-color: #428bca;
}
.red-hat-content a.bg-primary:hover {
  background-color: #3071a9;
}
.red-hat-content .bg-success {
  background-color: #dff0d8;
}
.red-hat-content a.bg-success:hover {
  background-color: #c1e2b3;
}
.red-hat-content .bg-info {
  background-color: #d9edf7;
}
.red-hat-content a.bg-info:hover {
  background-color: #afd9ee;
}
.red-hat-content .bg-warning {
  background-color: #fcf8e3;
}
.red-hat-content a.bg-warning:hover {
  background-color: #f7ecb5;
}
.red-hat-content .bg-danger {
  background-color: #f2dede;
}
.red-hat-content a.bg-danger:hover {
  background-color: #e4b9b9;
}
.red-hat-content .page-header {
  padding-bottom: 9px;
  margin: 40px 0 20px;
  border-bottom: 1px solid #eee;
}
.red-hat-content ul,
.red-hat-content ol {
  margin-top: 0;
  margin-bottom: 10px;
}
.red-hat-content ul ul,
.red-hat-content ol ul,
.red-hat-content ul ol,
.red-hat-content ol ol {
  margin-bottom: 0;
}
.red-hat-content .list-unstyled {
  padding-left: 0;
  list-style: none;
}
.red-hat-content .list-inline {
  padding-left: 0;
  margin-left: -5px;
  list-style: none;
}
.red-hat-content .list-inline > li {
  display: inline-block;
  padding-right: 5px;
  padding-left: 5px;
}
.red-hat-content dl {
  margin-top: 0;
  margin-bottom: 20px;
}
.red-hat-content dt,
.red-hat-content dd {
  line-height: 1.42857143;
}
.red-hat-content dt {
  font-weight: bold;
}
.red-hat-content dd {
  margin-left: 0;
}
@media (min-width: 768px) {
  .red-hat-content .dl-horizontal dt {
    float: left;
    width: 160px;
    overflow: hidden;
    clear: left;
    text-align: right;
    text-overflow: ellipsis;
    white-space: nowrap;
  }
  .red-hat-content .dl-horizontal dd {
    margin-left: 180px;
  }
}
.red-hat-content abbr[title],
.red-hat-content abbr[data-original-title] {
  cursor: help;
  border-bottom: 1px dotted #999;
}
.red-hat-content .initialism {
  font-size: 90%;
  text-transform: uppercase;
}
.red-hat-content blockquote {
  padding: 10px 20px;
  margin: 0 0 20px;
  font-size: 17.5px;
  border-left: 5px solid #eee;
}
.red-hat-content blockquote p:last-child,
.red-hat-content blockquote ul:last-child,
.red-hat-content blockquote ol:last-child {
  margin-bottom: 0;
}
.red-hat-content blockquote footer,
.red-hat-content blockquote small,
.red-hat-content blockquote .small {
  display: block;
  font-size: 80%;
  line-height: 1.42857143;
  color: #999;
}
.red-hat-content blockquote footer:before,
.red-hat-content blockquote small:before,
.red-hat-content blockquote .small:before {
  content: '\2014 \00A0';
}
.red-hat-content .blockquote-reverse,
.red-hat-content blockquote.pull-right {
  padding-right: 15px;
  padding-left: 0;
  text-align: right;
  border-right: 5px solid #eee;
  border-left: 0;
}
.red-hat-content .blockquote-reverse footer:before,
.red-hat-content blockquote.pull-right footer:before,
.red-hat-content .blockquote-reverse small:before,
.red-hat-content blockquote.pull-right small:before,
.red-hat-content .blockquote-reverse .small:before,
.red-hat-content blockquote.pull-right .small:before {
  content: '';
}
.red-hat-content .blockquote-reverse footer:after,
.red-hat-content blockquote.pull-right footer:after,
.red-hat-content .blockquote-reverse small:after,
.red-hat-content blockquote.pull-right small:after,
.red-hat-content .blockquote-reverse .small:after,
.red-hat-content blockquote.pull-right .small:after {
  content: '\00A0 \2014';
}
.red-hat-content blockquote:before,
.red-hat-content blockquote:after {
  content: "";
}
.red-hat-content address {
  margin-bottom: 20px;
  font-style: normal;
  line-height: 1.42857143;
}
.red-hat-content code,
.red-hat-content kbd,
.red-hat-content pre,
.red-hat-content samp {
  font-family: Menlo, Monaco, Consolas, "Courier New", monospace;
}
.red-hat-content code {
  padding: 2px 4px;
  font-size: 90%;
  color: #c7254e;
  white-space: nowrap;
  background-color: #f9f2f4;
  border-radius: 4px;
}
.red-hat-content kbd {
  padding: 2px 4px;
  font-size: 90%;
  color: #fff;
  background-color: #333;
  border-radius: 3px;
  box-shadow: inset 0 -1px 0 rgba(0, 0, 0, .25);
}
.red-hat-content pre {
  display: block;
  padding: 9.5px;
  margin: 0 0 10px;
  font-size: 13px;
  line-height: 1.42857143;
  color: #333;
  word-break: break-all;
  word-wrap: break-word;
  background-color: #f5f5f5;
  border: 1px solid #ccc;
  border-radius: 4px;
}
.red-hat-content pre code {
  padding: 0;
  font-size: inherit;
  color: inherit;
  white-space: pre-wrap;
  background-color: transparent;
  border-radius: 0;
}
.red-hat-content .pre-scrollable {
  max-height: 340px;
  overflow-y: scroll;
}
.red-hat-content .container {
  padding-right: 15px;
  padding-left: 15px;
  margin-right: auto;
  margin-left: auto;
}
@media (min-width: 768px) {
  .red-hat-content .container {
    width: 750px;
  }
}
@media (min-width: 992px) {
  .red-hat-content .container {
    width: 970px;
  }
}
@media (min-width: 1200px) {
  .red-hat-content .container {
    width: 1170px;
  }
}
.red-hat-content .container-fluid {
  padding-right: 15px;
  padding-left: 15px;
  margin-right: auto;
  margin-left: auto;
}
.red-hat-content .row {
  margin-right: -15px;
  margin-left: -15px;
}
.col-xs-1, .col-sm-1, .col-md-1, .col-lg-1, .col-xs-2, .col-sm-2, .col-md-2, .col-lg-2, .col-xs-3, .col-sm-3, .col-md-3, .col-lg-3, .col-xs-4, .col-sm-4, .col-md-4, .col-lg-4, .col-xs-5, .col-sm-5, .col-md-5, .col-lg-5, .col-xs-6, .col-sm-6, .col-md-6, .col-lg-6, .col-xs-7, .col-sm-7, .col-md-7, .col-lg-7, .col-xs-8, .col-sm-8, .col-md-8, .col-lg-8, .col-xs-9, .col-sm-9, .col-md-9, .col-lg-9, .col-xs-10, .col-sm-10, .col-md-10, .col-lg-10, .col-xs-11, .col-sm-11, .col-md-11, .col-lg-11, .col-xs-12, .col-sm-12, .col-md-12, .col-lg-12 {
  position: relative;
  min-height: 1px;
  padding-right: 15px;
  padding-left: 15px;
}
.col-xs-1, .col-xs-2, .col-xs-3, .col-xs-4, .col-xs-5, .col-xs-6, .col-xs-7, .col-xs-8, .col-xs-9, .col-xs-10, .col-xs-11, .col-xs-12 {
  float: left;
}
.col-xs-12 {
  width: 100%;
}
.col-xs-11 {
  width: 91.66666667%;
}
.col-xs-10 {
  width: 83.33333333%;
}
.col-xs-9 {
  width: 75%;
}
.col-xs-8 {
  width: 66.66666667%;
}
.col-xs-7 {
  width: 58.33333333%;
}
.col-xs-6 {
  width: 50%;
}
.col-xs-5 {
  width: 41.66666667%;
}
.col-xs-4 {
  width: 33.33333333%;
}
.col-xs-3 {
  width: 25%;
}
.col-xs-2 {
  width: 16.66666667%;
}
.col-xs-1 {
  width: 8.33333333%;
}
.col-xs-pull-12 {
  right: 100%;
}
.col-xs-pull-11 {
  right: 91.66666667%;
}
.col-xs-pull-10 {
  right: 83.33333333%;
}
.col-xs-pull-9 {
  right: 75%;
}
.col-xs-pull-8 {
  right: 66.66666667%;
}
.col-xs-pull-7 {
  right: 58.33333333%;
}
.col-xs-pull-6 {
  right: 50%;
}
.col-xs-pull-5 {
  right: 41.66666667%;
}
.col-xs-pull-4 {
  right: 33.33333333%;
}
.col-xs-pull-3 {
  right: 25%;
}
.col-xs-pull-2 {
  right: 16.66666667%;
}
.col-xs-pull-1 {
  right: 8.33333333%;
}
.col-xs-pull-0 {
  right: 0;
}
.col-xs-push-12 {
  left: 100%;
}
.col-xs-push-11 {
  left: 91.66666667%;
}
.col-xs-push-10 {
  left: 83.33333333%;
}
.col-xs-push-9 {
  left: 75%;
}
.col-xs-push-8 {
  left: 66.66666667%;
}
.col-xs-push-7 {
  left: 58.33333333%;
}
.col-xs-push-6 {
  left: 50%;
}
.col-xs-push-5 {
  left: 41.66666667%;
}
.col-xs-push-4 {
  left: 33.33333333%;
}
.col-xs-push-3 {
  left: 25%;
}
.col-xs-push-2 {
  left: 16.66666667%;
}
.col-xs-push-1 {
  left: 8.33333333%;
}
.col-xs-push-0 {
  left: 0;
}
.col-xs-offset-12 {
  margin-left: 100%;
}
.col-xs-offset-11 {
  margin-left: 91.66666667%;
}
.col-xs-offset-10 {
  margin-left: 83.33333333%;
}
.col-xs-offset-9 {
  margin-left: 75%;
}
.col-xs-offset-8 {
  margin-left: 66.66666667%;
}
.col-xs-offset-7 {
  margin-left: 58.33333333%;
}
.col-xs-offset-6 {
  margin-left: 50%;
}
.col-xs-offset-5 {
  margin-left: 41.66666667%;
}
.col-xs-offset-4 {
  margin-left: 33.33333333%;
}
.col-xs-offset-3 {
  margin-left: 25%;
}
.col-xs-offset-2 {
  margin-left: 16.66666667%;
}
.col-xs-offset-1 {
  margin-left: 8.33333333%;
}
.col-xs-offset-0 {
  margin-left: 0;
}
@media (min-width: 768px) {
  .col-sm-1, .col-sm-2, .col-sm-3, .col-sm-4, .col-sm-5, .col-sm-6, .col-sm-7, .col-sm-8, .col-sm-9, .col-sm-10, .col-sm-11, .col-sm-12 {
    float: left;
  }
  .col-sm-12 {
    width: 100%;
  }
  .col-sm-11 {
    width: 91.66666667%;
  }
  .col-sm-10 {
    width: 83.33333333%;
  }
  .col-sm-9 {
    width: 75%;
  }
  .col-sm-8 {
    width: 66.66666667%;
  }
  .col-sm-7 {
    width: 58.33333333%;
  }
  .col-sm-6 {
    width: 50%;
  }
  .col-sm-5 {
    width: 41.66666667%;
  }
  .col-sm-4 {
    width: 33.33333333%;
  }
  .col-sm-3 {
    width: 25%;
  }
  .col-sm-2 {
    width: 16.66666667%;
  }
  .col-sm-1 {
    width: 8.33333333%;
  }
  .col-sm-pull-12 {
    right: 100%;
  }
  .col-sm-pull-11 {
    right: 91.66666667%;
  }
  .col-sm-pull-10 {
    right: 83.33333333%;
  }
  .col-sm-pull-9 {
    right: 75%;
  }
  .col-sm-pull-8 {
    right: 66.66666667%;
  }
  .col-sm-pull-7 {
    right: 58.33333333%;
  }
  .col-sm-pull-6 {
    right: 50%;
  }
  .col-sm-pull-5 {
    right: 41.66666667%;
  }
  .col-sm-pull-4 {
    right: 33.33333333%;
  }
  .col-sm-pull-3 {
    right: 25%;
  }
  .col-sm-pull-2 {
    right: 16.66666667%;
  }
  .col-sm-pull-1 {
    right: 8.33333333%;
  }
  .col-sm-pull-0 {
    right: 0;
  }
  .col-sm-push-12 {
    left: 100%;
  }
  .col-sm-push-11 {
    left: 91.66666667%;
  }
  .col-sm-push-10 {
    left: 83.33333333%;
  }
  .col-sm-push-9 {
    left: 75%;
  }
  .col-sm-push-8 {
    left: 66.66666667%;
  }
  .col-sm-push-7 {
    left: 58.33333333%;
  }
  .col-sm-push-6 {
    left: 50%;
  }
  .col-sm-push-5 {
    left: 41.66666667%;
  }
  .col-sm-push-4 {
    left: 33.33333333%;
  }
  .col-sm-push-3 {
    left: 25%;
  }
  .col-sm-push-2 {
    left: 16.66666667%;
  }
  .col-sm-push-1 {
    left: 8.33333333%;
  }
  .col-sm-push-0 {
    left: 0;
  }
  .col-sm-offset-12 {
    margin-left: 100%;
  }
  .col-sm-offset-11 {
    margin-left: 91.66666667%;
  }
  .col-sm-offset-10 {
    margin-left: 83.33333333%;
  }
  .col-sm-offset-9 {
    margin-left: 75%;
  }
  .col-sm-offset-8 {
    margin-left: 66.66666667%;
  }
  .col-sm-offset-7 {
    margin-left: 58.33333333%;
  }
  .col-sm-offset-6 {
    margin-left: 50%;
  }
  .col-sm-offset-5 {
    margin-left: 41.66666667%;
  }
  .col-sm-offset-4 {
    margin-left: 33.33333333%;
  }
  .col-sm-offset-3 {
    margin-left: 25%;
  }
  .col-sm-offset-2 {
    margin-left: 16.66666667%;
  }
  .col-sm-offset-1 {
    margin-left: 8.33333333%;
  }
  .col-sm-offset-0 {
    margin-left: 0;
  }
}
@media (min-width: 992px) {
  .col-md-1, .col-md-2, .col-md-3, .col-md-4, .col-md-5, .col-md-6, .col-md-7, .col-md-8, .col-md-9, .col-md-10, .col-md-11, .col-md-12 {
    float: left;
  }
  .col-md-12 {
    width: 100%;
  }
  .col-md-11 {
    width: 91.66666667%;
  }
  .col-md-10 {
    width: 83.33333333%;
  }
  .col-md-9 {
    width: 75%;
  }
  .col-md-8 {
    width: 66.66666667%;
  }
  .col-md-7 {
    width: 58.33333333%;
  }
  .col-md-6 {
    width: 50%;
  }
  .col-md-5 {
    width: 41.66666667%;
  }
  .col-md-4 {
    width: 33.33333333%;
  }
  .col-md-3 {
    width: 25%;
  }
  .col-md-2 {
    width: 16.66666667%;
  }
  .col-md-1 {
    width: 8.33333333%;
  }
  .col-md-pull-12 {
    right: 100%;
  }
  .col-md-pull-11 {
    right: 91.66666667%;
  }
  .col-md-pull-10 {
    right: 83.33333333%;
  }
  .col-md-pull-9 {
    right: 75%;
  }
  .col-md-pull-8 {
    right: 66.66666667%;
  }
  .col-md-pull-7 {
    right: 58.33333333%;
  }
  .col-md-pull-6 {
    right: 50%;
  }
  .col-md-pull-5 {
    right: 41.66666667%;
  }
  .col-md-pull-4 {
    right: 33.33333333%;
  }
  .col-md-pull-3 {
    right: 25%;
  }
  .col-md-pull-2 {
    right: 16.66666667%;
  }
  .col-md-pull-1 {
    right: 8.33333333%;
  }
  .col-md-pull-0 {
    right: 0;
  }
  .col-md-push-12 {
    left: 100%;
  }
  .col-md-push-11 {
    left: 91.66666667%;
  }
  .col-md-push-10 {
    left: 83.33333333%;
  }
  .col-md-push-9 {
    left: 75%;
  }
  .col-md-push-8 {
    left: 66.66666667%;
  }
  .col-md-push-7 {
    left: 58.33333333%;
  }
  .col-md-push-6 {
    left: 50%;
  }
  .col-md-push-5 {
    left: 41.66666667%;
  }
  .col-md-push-4 {
    left: 33.33333333%;
  }
  .col-md-push-3 {
    left: 25%;
  }
  .col-md-push-2 {
    left: 16.66666667%;
  }
  .col-md-push-1 {
    left: 8.33333333%;
  }
  .col-md-push-0 {
    left: 0;
  }
  .col-md-offset-12 {
    margin-left: 100%;
  }
  .col-md-offset-11 {
    margin-left: 91.66666667%;
  }
  .col-md-offset-10 {
    margin-left: 83.33333333%;
  }
  .col-md-offset-9 {
    margin-left: 75%;
  }
  .col-md-offset-8 {
    margin-left: 66.66666667%;
  }
  .col-md-offset-7 {
    margin-left: 58.33333333%;
  }
  .col-md-offset-6 {
    margin-left: 50%;
  }
  .col-md-offset-5 {
    margin-left: 41.66666667%;
  }
  .col-md-offset-4 {
    margin-left: 33.33333333%;
  }
  .col-md-offset-3 {
    margin-left: 25%;
  }
  .col-md-offset-2 {
    margin-left: 16.66666667%;
  }
  .col-md-offset-1 {
    margin-left: 8.33333333%;
  }
  .col-md-offset-0 {
    margin-left: 0;
  }
}
@media (min-width: 1200px) {
  .col-lg-1, .col-lg-2, .col-lg-3, .col-lg-4, .col-lg-5, .col-lg-6, .col-lg-7, .col-lg-8, .col-lg-9, .col-lg-10, .col-lg-11, .col-lg-12 {
    float: left;
  }
  .col-lg-12 {
    width: 100%;
  }
  .col-lg-11 {
    width: 91.66666667%;
  }
  .col-lg-10 {
    width: 83.33333333%;
  }
  .col-lg-9 {
    width: 75%;
  }
  .col-lg-8 {
    width: 66.66666667%;
  }
  .col-lg-7 {
    width: 58.33333333%;
  }
  .col-lg-6 {
    width: 50%;
  }
  .col-lg-5 {
    width: 41.66666667%;
  }
  .col-lg-4 {
    width: 33.33333333%;
  }
  .col-lg-3 {
    width: 25%;
  }
  .col-lg-2 {
    width: 16.66666667%;
  }
  .col-lg-1 {
    width: 8.33333333%;
  }
  .col-lg-pull-12 {
    right: 100%;
  }
  .col-lg-pull-11 {
    right: 91.66666667%;
  }
  .col-lg-pull-10 {
    right: 83.33333333%;
  }
  .col-lg-pull-9 {
    right: 75%;
  }
  .col-lg-pull-8 {
    right: 66.66666667%;
  }
  .col-lg-pull-7 {
    right: 58.33333333%;
  }
  .col-lg-pull-6 {
    right: 50%;
  }
  .col-lg-pull-5 {
    right: 41.66666667%;
  }
  .col-lg-pull-4 {
    right: 33.33333333%;
  }
  .col-lg-pull-3 {
    right: 25%;
  }
  .col-lg-pull-2 {
    right: 16.66666667%;
  }
  .col-lg-pull-1 {
    right: 8.33333333%;
  }
  .col-lg-pull-0 {
    right: 0;
  }
  .col-lg-push-12 {
    left: 100%;
  }
  .col-lg-push-11 {
    left: 91.66666667%;
  }
  .col-lg-push-10 {
    left: 83.33333333%;
  }
  .col-lg-push-9 {
    left: 75%;
  }
  .col-lg-push-8 {
    left: 66.66666667%;
  }
  .col-lg-push-7 {
    left: 58.33333333%;
  }
  .col-lg-push-6 {
    left: 50%;
  }
  .col-lg-push-5 {
    left: 41.66666667%;
  }
  .col-lg-push-4 {
    left: 33.33333333%;
  }
  .col-lg-push-3 {
    left: 25%;
  }
  .col-lg-push-2 {
    left: 16.66666667%;
  }
  .col-lg-push-1 {
    left: 8.33333333%;
  }
  .col-lg-push-0 {
    left: 0;
  }
  .col-lg-offset-12 {
    margin-left: 100%;
  }
  .col-lg-offset-11 {
    margin-left: 91.66666667%;
  }
  .col-lg-offset-10 {
    margin-left: 83.33333333%;
  }
  .col-lg-offset-9 {
    margin-left: 75%;
  }
  .col-lg-offset-8 {
    margin-left: 66.66666667%;
  }
  .col-lg-offset-7 {
    margin-left: 58.33333333%;
  }
  .col-lg-offset-6 {
    margin-left: 50%;
  }
  .col-lg-offset-5 {
    margin-left: 41.66666667%;
  }
  .col-lg-offset-4 {
    margin-left: 33.33333333%;
  }
  .col-lg-offset-3 {
    margin-left: 25%;
  }
  .col-lg-offset-2 {
    margin-left: 16.66666667%;
  }
  .col-lg-offset-1 {
    margin-left: 8.33333333%;
  }
  .col-lg-offset-0 {
    margin-left: 0;
  }
}
.red-hat-content table {
  max-width: 100%;
  background-color: transparent;
}
.red-hat-content th {
  text-align: left;
}
.red-hat-content .table {
  width: 100%;
  margin-bottom: 20px;
}
.red-hat-content .table > thead > tr > th,
.red-hat-content .table > tbody > tr > th,
.red-hat-content .table > tfoot > tr > th,
.red-hat-content .table > thead > tr > td,
.red-hat-content .table > tbody > tr > td,
.red-hat-content .table > tfoot > tr > td {
  padding: 8px;
  line-height: 1.42857143;
  vertical-align: top;
  border-top: 1px solid #ddd;
}
.red-hat-content .table > thead > tr > th {
  vertical-align: bottom;
  border-bottom: 2px solid #ddd;
}
.red-hat-content .table > caption + thead > tr:first-child > th,
.red-hat-content .table > colgroup + thead > tr:first-child > th,
.red-hat-content .table > thead:first-child > tr:first-child > th,
.red-hat-content .table > caption + thead > tr:first-child > td,
.red-hat-content .table > colgroup + thead > tr:first-child > td,
.red-hat-content .table > thead:first-child > tr:first-child > td {
  border-top: 0;
}
.red-hat-content .table > tbody + tbody {
  border-top: 2px solid #ddd;
}
.red-hat-content .table .table {
  background-color: #fff;
}
.red-hat-content .table-condensed > thead > tr > th,
.red-hat-content .table-condensed > tbody > tr > th,
.red-hat-content .table-condensed > tfoot > tr > th,
.red-hat-content .table-condensed > thead > tr > td,
.red-hat-content .table-condensed > tbody > tr > td,
.red-hat-content .table-condensed > tfoot > tr > td {
  padding: 5px;
}
.red-hat-content .table-bordered {
  border: 1px solid #ddd;
}
.red-hat-content .table-bordered > thead > tr > th,
.red-hat-content .table-bordered > tbody > tr > th,
.red-hat-content .table-bordered > tfoot > tr > th,
.red-hat-content .table-bordered > thead > tr > td,
.red-hat-content .table-bordered > tbody > tr > td,
.red-hat-content .table-bordered > tfoot > tr > td {
  border: 1px solid #ddd;
}
.red-hat-content .table-bordered > thead > tr > th,
.red-hat-content .table-bordered > thead > tr > td {
  border-bottom-width: 2px;
}
.red-hat-content .table-striped > tbody > tr:nth-child(odd) > td,
.red-hat-content .table-striped > tbody > tr:nth-child(odd) > th {
  background-color: #f9f9f9;
}
.red-hat-content .table-hover > tbody > tr:hover > td,
.red-hat-content .table-hover > tbody > tr:hover > th {
  background-color: #f5f5f5;
}
.red-hat-content table col[class*="col-"] {
  position: static;
  display: table-column;
  float: none;
}
.red-hat-content table td[class*="col-"],
.red-hat-content table th[class*="col-"] {
  position: static;
  display: table-cell;
  float: none;
}
.red-hat-content .table > thead > tr > td.active,
.red-hat-content .table > tbody > tr > td.active,
.red-hat-content .table > tfoot > tr > td.active,
.red-hat-content .table > thead > tr > th.active,
.red-hat-content .table > tbody > tr > th.active,
.red-hat-content .table > tfoot > tr > th.active,
.red-hat-content .table > thead > tr.active > td,
.red-hat-content .table > tbody > tr.active > td,
.red-hat-content .table > tfoot > tr.active > td,
.red-hat-content .table > thead > tr.active > th,
.red-hat-content .table > tbody > tr.active > th,
.red-hat-content .table > tfoot > tr.active > th {
  background-color: #f5f5f5;
}
.red-hat-content .table-hover > tbody > tr > td.active:hover,
.red-hat-content .table-hover > tbody > tr > th.active:hover,
.red-hat-content .table-hover > tbody > tr.active:hover > td,
.red-hat-content .table-hover > tbody > tr.active:hover > th {
  background-color: #e8e8e8;
}
.red-hat-content .table > thead > tr > td.success,
.red-hat-content .table > tbody > tr > td.success,
.red-hat-content .table > tfoot > tr > td.success,
.red-hat-content .table > thead > tr > th.success,
.red-hat-content .table > tbody > tr > th.success,
.red-hat-content .table > tfoot > tr > th.success,
.red-hat-content .table > thead > tr.success > td,
.red-hat-content .table > tbody > tr.success > td,
.red-hat-content .table > tfoot > tr.success > td,
.red-hat-content .table > thead > tr.success > th,
.red-hat-content .table > tbody > tr.success > th,
.red-hat-content .table > tfoot > tr.success > th {
  background-color: #dff0d8;
}
.red-hat-content .table-hover > tbody > tr > td.success:hover,
.red-hat-content .table-hover > tbody > tr > th.success:hover,
.red-hat-content .table-hover > tbody > tr.success:hover > td,
.red-hat-content .table-hover > tbody > tr.success:hover > th {
  background-color: #d0e9c6;
}
.red-hat-content .table > thead > tr > td.info,
.red-hat-content .table > tbody > tr > td.info,
.red-hat-content .table > tfoot > tr > td.info,
.red-hat-content .table > thead > tr > th.info,
.red-hat-content .table > tbody > tr > th.info,
.red-hat-content .table > tfoot > tr > th.info,
.red-hat-content .table > thead > tr.info > td,
.red-hat-content .table > tbody > tr.info > td,
.red-hat-content .table > tfoot > tr.info > td,
.red-hat-content .table > thead > tr.info > th,
.red-hat-content .table > tbody > tr.info > th,
.red-hat-content .table > tfoot > tr.info > th {
  background-color: #d9edf7;
}
.red-hat-content .table-hover > tbody > tr > td.info:hover,
.red-hat-content .table-hover > tbody > tr > th.info:hover,
.red-hat-content .table-hover > tbody > tr.info:hover > td,
.red-hat-content .table-hover > tbody > tr.info:hover > th {
  background-color: #c4e3f3;
}
.red-hat-content .table > thead > tr > td.warning,
.red-hat-content .table > tbody > tr > td.warning,
.red-hat-content .table > tfoot > tr > td.warning,
.red-hat-content .table > thead > tr > th.warning,
.red-hat-content .table > tbody > tr > th.warning,
.red-hat-content .table > tfoot > tr > th.warning,
.red-hat-content .table > thead > tr.warning > td,
.red-hat-content .table > tbody > tr.warning > td,
.red-hat-content .table > tfoot > tr.warning > td,
.red-hat-content .table > thead > tr.warning > th,
.red-hat-content .table > tbody > tr.warning > th,
.red-hat-content .table > tfoot > tr.warning > th {
  background-color: #fcf8e3;
}
.red-hat-content .table-hover > tbody > tr > td.warning:hover,
.red-hat-content .table-hover > tbody > tr > th.warning:hover,
.red-hat-content .table-hover > tbody > tr.warning:hover > td,
.red-hat-content .table-hover > tbody > tr.warning:hover > th {
  background-color: #faf2cc;
}
.red-hat-content .table > thead > tr > td.danger,
.red-hat-content .table > tbody > tr > td.danger,
.red-hat-content .table > tfoot > tr > td.danger,
.red-hat-content .table > thead > tr > th.danger,
.red-hat-content .table > tbody > tr > th.danger,
.red-hat-content .table > tfoot > tr > th.danger,
.red-hat-content .table > thead > tr.danger > td,
.red-hat-content .table > tbody > tr.danger > td,
.red-hat-content .table > tfoot > tr.danger > td,
.red-hat-content .table > thead > tr.danger > th,
.red-hat-content .table > tbody > tr.danger > th,
.red-hat-content .table > tfoot > tr.danger > th {
  background-color: #f2dede;
}
.red-hat-content .table-hover > tbody > tr > td.danger:hover,
.red-hat-content .table-hover > tbody > tr > th.danger:hover,
.red-hat-content .table-hover > tbody > tr.danger:hover > td,
.red-hat-content .table-hover > tbody > tr.danger:hover > th {
  background-color: #ebcccc;
}
@media (max-width: 767px) {
  .red-hat-content .table-responsive {
    width: 100%;
    margin-bottom: 15px;
    overflow-x: scroll;
    overflow-y: hidden;
    -webkit-overflow-scrolling: touch;
    -ms-overflow-style: -ms-autohiding-scrollbar;
    border: 1px solid #ddd;
  }
  .red-hat-content .table-responsive > .table {
    margin-bottom: 0;
  }
  .red-hat-content .table-responsive > .table > thead > tr > th,
  .red-hat-content .table-responsive > .table > tbody > tr > th,
  .red-hat-content .table-responsive > .table > tfoot > tr > th,
  .red-hat-content .table-responsive > .table > thead > tr > td,
  .red-hat-content .table-responsive > .table > tbody > tr > td,
  .red-hat-content .table-responsive > .table > tfoot > tr > td {
    white-space: nowrap;
  }
  .red-hat-content .table-responsive > .table-bordered {
    border: 0;
  }
  .red-hat-content .table-responsive > .table-bordered > thead > tr > th:first-child,
  .red-hat-content .table-responsive > .table-bordered > tbody > tr > th:first-child,
  .red-hat-content .table-responsive > .table-bordered > tfoot > tr > th:first-child,
  .red-hat-content .table-responsive > .table-bordered > thead > tr > td:first-child,
  .red-hat-content .table-responsive > .table-bordered > tbody > tr > td:first-child,
  .red-hat-content .table-responsive > .table-bordered > tfoot > tr > td:first-child {
    border-left: 0;
  }
  .red-hat-content .table-responsive > .table-bordered > thead > tr > th:last-child,
  .red-hat-content .table-responsive > .table-bordered > tbody > tr > th:last-child,
  .red-hat-content .table-responsive > .table-bordered > tfoot > tr > th:last-child,
  .red-hat-content .table-responsive > .table-bordered > thead > tr > td:last-child,
  .red-hat-content .table-responsive > .table-bordered > tbody > tr > td:last-child,
  .red-hat-content .table-responsive > .table-bordered > tfoot > tr > td:last-child {
    border-right: 0;
  }
  .red-hat-content .table-responsive > .table-bordered > tbody > tr:last-child > th,
  .red-hat-content .table-responsive > .table-bordered > tfoot > tr:last-child > th,
  .red-hat-content .table-responsive > .table-bordered > tbody > tr:last-child > td,
  .red-hat-content .table-responsive > .table-bordered > tfoot > tr:last-child > td {
    border-bottom: 0;
  }
}
.red-hat-content fieldset {
  min-width: 0;
  padding: 0;
  margin: 0;
  border: 0;
}
.red-hat-content legend {
  display: block;
  width: 100%;
  padding: 0;
  margin-bottom: 20px;
  font-size: 21px;
  line-height: inherit;
  color: #333;
  border: 0;
  border-bottom: 1px solid #e5e5e5;
}
.red-hat-content label {
  display: inline-block;
  margin-bottom: 5px;
  font-weight: bold;
}
.red-hat-content input[type="search"] {
  -webkit-box-sizing: border-box;
     -moz-box-sizing: border-box;
          box-sizing: border-box;
}
.red-hat-content input[type="radio"],
.red-hat-content input[type="checkbox"] {
  margin: 4px 0 0;
  margin-top: 1px \9;
  /* IE8-9 */
  line-height: normal;
}
.red-hat-content input[type="file"] {
  display: block;
}
.red-hat-content input[type="range"] {
  display: block;
  width: 100%;
}
.red-hat-content select[multiple],
.red-hat-content select[size] {
  height: auto;
}
.red-hat-content input[type="file"]:focus,
.red-hat-content input[type="radio"]:focus,
.red-hat-content input[type="checkbox"]:focus {
  outline: thin dotted;
  outline: 5px auto -webkit-focus-ring-color;
  outline-offset: -2px;
}
.red-hat-content output {
  display: block;
  padding-top: 7px;
  font-size: 14px;
  line-height: 1.42857143;
  color: #555;
}
.red-hat-content .form-control {
  display: block;
  width: 100%;
  height: 34px;
  padding: 6px 12px;
  font-size: 14px;
  line-height: 1.42857143;
  color: #555;
  background-color: #fff;
  background-image: none;
  border: 1px solid #ccc;
  border-radius: 4px;
  -webkit-box-shadow: inset 0 1px 1px rgba(0, 0, 0, .075);
          box-shadow: inset 0 1px 1px rgba(0, 0, 0, .075);
  -webkit-transition: border-color ease-in-out .15s, box-shadow ease-in-out .15s;
          transition: border-color ease-in-out .15s, box-shadow ease-in-out .15s;
}
.red-hat-content .form-control:focus {
  border-color: #66afe9;
  outline: 0;
  -webkit-box-shadow: inset 0 1px 1px rgba(0,0,0,.075), 0 0 8px rgba(102, 175, 233, .6);
          box-shadow: inset 0 1px 1px rgba(0,0,0,.075), 0 0 8px rgba(102, 175, 233, .6);
}
.red-hat-content .form-control::-moz-placeholder {
  color: #999;
  opacity: 1;
}
.red-hat-content .form-control:-ms-input-placeholder {
  color: #999;
}
.red-hat-content .form-control::-webkit-input-placeholder {
  color: #999;
}
.red-hat-content .form-control[disabled],
.red-hat-content .form-control[readonly],
fieldset[disabled] .red-hat-content .form-control {
  cursor: not-allowed;
  background-color: #eee;
  opacity: 1;
}
.red-hat-content textarea.form-control {
  height: auto;
}
.red-hat-content input[type="search"] {
  -webkit-appearance: none;
}
.red-hat-content input[type="date"] {
  line-height: 34px;
}
.red-hat-content .form-group {
  margin-bottom: 15px;
}
.red-hat-content .radio,
.red-hat-content .checkbox {
  display: block;
  min-height: 20px;
  padding-left: 20px;
  margin-top: 10px;
  margin-bottom: 10px;
}
.red-hat-content .radio label,
.red-hat-content .checkbox label {
  display: inline;
  font-weight: normal;
  cursor: pointer;
}
.red-hat-content .radio input[type="radio"],
.red-hat-content .radio-inline input[type="radio"],
.red-hat-content .checkbox input[type="checkbox"],
.red-hat-content .checkbox-inline input[type="checkbox"] {
  float: left;
  margin-left: -20px;
}
.radio + .radio,
.checkbox + .checkbox {
  margin-top: -5px;
}
.red-hat-content .radio-inline,
.red-hat-content .checkbox-inline {
  display: inline-block;
  padding-left: 20px;
  margin-bottom: 0;
  font-weight: normal;
  vertical-align: middle;
  cursor: pointer;
}
.radio-inline + .radio-inline,
.checkbox-inline + .checkbox-inline {
  margin-top: 0;
  margin-left: 10px;
}
input[type="radio"][disabled],
input[type="checkbox"][disabled],
.radio[disabled],
.radio-inline[disabled],
.checkbox[disabled],
.checkbox-inline[disabled],
fieldset[disabled] input[type="radio"],
fieldset[disabled] input[type="checkbox"],
fieldset[disabled] .radio,
fieldset[disabled] .radio-inline,
fieldset[disabled] .checkbox,
fieldset[disabled] .checkbox-inline {
  cursor: not-allowed;
}
.red-hat-content .input-sm {
  height: 30px;
  padding: 5px 10px;
  font-size: 12px;
  line-height: 1.5;
  border-radius: 3px;
}
.red-hat-content select.input-sm {
  height: 30px;
  line-height: 30px;
}
.red-hat-content textarea.input-sm,
.red-hat-content select[multiple].input-sm {
  height: auto;
}
.red-hat-content .input-lg {
  height: 46px;
  padding: 10px 16px;
  font-size: 18px;
  line-height: 1.33;
  border-radius: 6px;
}
.red-hat-content select.input-lg {
  height: 46px;
  line-height: 46px;
}
.red-hat-content textarea.input-lg,
.red-hat-content select[multiple].input-lg {
  height: auto;
}
.red-hat-content .has-feedback {
  position: relative;
}
.red-hat-content .has-feedback .form-control {
  padding-right: 42.5px;
}
.red-hat-content .has-feedback .form-control-feedback {
  position: absolute;
  top: 25px;
  right: 0;
  display: block;
  width: 34px;
  height: 34px;
  line-height: 34px;
  text-align: center;
}
.red-hat-content .has-success .help-block,
.red-hat-content .has-success .control-label,
.red-hat-content .has-success .radio,
.red-hat-content .has-success .checkbox,
.red-hat-content .has-success .radio-inline,
.red-hat-content .has-success .checkbox-inline {
  color: #3c763d;
}
.red-hat-content .has-success .form-control {
  border-color: #3c763d;
  -webkit-box-shadow: inset 0 1px 1px rgba(0, 0, 0, .075);
          box-shadow: inset 0 1px 1px rgba(0, 0, 0, .075);
}
.red-hat-content .has-success .form-control:focus {
  border-color: #2b542c;
  -webkit-box-shadow: inset 0 1px 1px rgba(0, 0, 0, .075), 0 0 6px #67b168;
          box-shadow: inset 0 1px 1px rgba(0, 0, 0, .075), 0 0 6px #67b168;
}
.red-hat-content .has-success .input-group-addon {
  color: #3c763d;
  background-color: #dff0d8;
  border-color: #3c763d;
}
.red-hat-content .has-success .form-control-feedback {
  color: #3c763d;
}
.red-hat-content .has-warning .help-block,
.red-hat-content .has-warning .control-label,
.red-hat-content .has-warning .radio,
.red-hat-content .has-warning .checkbox,
.red-hat-content .has-warning .radio-inline,
.red-hat-content .has-warning .checkbox-inline {
  color: #8a6d3b;
}
.red-hat-content .has-warning .form-control {
  border-color: #8a6d3b;
  -webkit-box-shadow: inset 0 1px 1px rgba(0, 0, 0, .075);
          box-shadow: inset 0 1px 1px rgba(0, 0, 0, .075);
}
.red-hat-content .has-warning .form-control:focus {
  border-color: #66512c;
  -webkit-box-shadow: inset 0 1px 1px rgba(0, 0, 0, .075), 0 0 6px #c0a16b;
          box-shadow: inset 0 1px 1px rgba(0, 0, 0, .075), 0 0 6px #c0a16b;
}
.red-hat-content .has-warning .input-group-addon {
  color: #8a6d3b;
  background-color: #fcf8e3;
  border-color: #8a6d3b;
}
.red-hat-content .has-warning .form-control-feedback {
  color: #8a6d3b;
}
.red-hat-content .has-error .help-block,
.red-hat-content .has-error .control-label,
.red-hat-content .has-error .radio,
.red-hat-content .has-error .checkbox,
.red-hat-content .has-error .radio-inline,
.red-hat-content .has-error .checkbox-inline {
  color: #a94442;
}
.red-hat-content .has-error .form-control {
  border-color: #a94442;
  -webkit-box-shadow: inset 0 1px 1px rgba(0, 0, 0, .075);
          box-shadow: inset 0 1px 1px rgba(0, 0, 0, .075);
}
.red-hat-content .has-error .form-control:focus {
  border-color: #843534;
  -webkit-box-shadow: inset 0 1px 1px rgba(0, 0, 0, .075), 0 0 6px #ce8483;
          box-shadow: inset 0 1px 1px rgba(0, 0, 0, .075), 0 0 6px #ce8483;
}
.red-hat-content .has-error .input-group-addon {
  color: #a94442;
  background-color: #f2dede;
  border-color: #a94442;
}
.red-hat-content .has-error .form-control-feedback {
  color: #a94442;
}
.red-hat-content .form-control-static {
  margin-bottom: 0;
}
.red-hat-content .help-block {
  display: block;
  margin-top: 5px;
  margin-bottom: 10px;
  color: #737373;
}
@media (min-width: 768px) {
  .red-hat-content .form-inline .form-group {
    display: inline-block;
    margin-bottom: 0;
    vertical-align: middle;
  }
  .red-hat-content .form-inline .form-control {
    display: inline-block;
    width: auto;
    vertical-align: middle;
  }
  .red-hat-content .form-inline .input-group > .form-control {
    width: 100%;
  }
  .red-hat-content .form-inline .control-label {
    margin-bottom: 0;
    vertical-align: middle;
  }
  .red-hat-content .form-inline .radio,
  .red-hat-content .form-inline .checkbox {
    display: inline-block;
    padding-left: 0;
    margin-top: 0;
    margin-bottom: 0;
    vertical-align: middle;
  }
  .red-hat-content .form-inline .radio input[type="radio"],
  .red-hat-content .form-inline .checkbox input[type="checkbox"] {
    float: none;
    margin-left: 0;
  }
  .red-hat-content .form-inline .has-feedback .form-control-feedback {
    top: 0;
  }
}
.red-hat-content .form-horizontal .control-label,
.red-hat-content .form-horizontal .radio,
.red-hat-content .form-horizontal .checkbox,
.red-hat-content .form-horizontal .radio-inline,
.red-hat-content .form-horizontal .checkbox-inline {
  padding-top: 7px;
  margin-top: 0;
  margin-bottom: 0;
}
.red-hat-content .form-horizontal .radio,
.red-hat-content .form-horizontal .checkbox {
  min-height: 27px;
}
.red-hat-content .form-horizontal .form-group {
  margin-right: -15px;
  margin-left: -15px;
}
.red-hat-content .form-horizontal .form-control-static {
  padding-top: 7px;
}
@media (min-width: 768px) {
  .red-hat-content .form-horizontal .control-label {
    text-align: right;
  }
}
.red-hat-content .form-horizontal .has-feedback .form-control-feedback {
  top: 0;
  right: 15px;
}
.red-hat-content .btn {
  display: inline-block;
  padding: 6px 12px;
  margin-bottom: 0;
  font-size: 14px;
  font-weight: normal;
  line-height: 1.42857143;
  text-align: center;
  white-space: nowrap;
  vertical-align: middle;
  cursor: pointer;
  -webkit-user-select: none;
     -moz-user-select: none;
      -ms-user-select: none;
          user-select: none;
  background-image: none;
  border: 1px solid transparent;
  border-radius: 4px;
}
.red-hat-content .btn:focus,
.red-hat-content .btn:active:focus,
.red-hat-content .btn.active:focus {
  outline: thin dotted;
  outline: 5px auto -webkit-focus-ring-color;
  outline-offset: -2px;
}
.red-hat-content .btn:hover,
.red-hat-content .btn:focus {
  color: #333;
  text-decoration: none;
}
.red-hat-content .btn:active,
.red-hat-content .btn.active {
  background-image: none;
  outline: 0;
  -webkit-box-shadow: inset 0 3px 5px rgba(0, 0, 0, .125);
          box-shadow: inset 0 3px 5px rgba(0, 0, 0, .125);
}
.red-hat-content .btn.disabled,
.red-hat-content .btn[disabled],
.red-hat-content fieldset[disabled] .btn {
  pointer-events: none;
  cursor: not-allowed;
  filter: alpha(opacity=65);
  -webkit-box-shadow: none;
          box-shadow: none;
  opacity: .65;
}
.red-hat-content .btn-default {
  color: #333;
  background-color: #fff;
  border-color: #ccc;
}
.red-hat-content .btn-default:hover,
.red-hat-content .btn-default:focus,
.red-hat-content .btn-default:active,
.red-hat-content .btn-default.active,
.red-hat-content .open .dropdown-toggle.btn-default {
  color: #333;
  background-color: #ebebeb;
  border-color: #adadad;
}
.red-hat-content .btn-default:active,
.red-hat-content .btn-default.active,
.red-hat-content .open .dropdown-toggle.btn-default {
  background-image: none;
}
.red-hat-content .btn-default.disabled,
.red-hat-content .btn-default[disabled],
.red-hat-content fieldset[disabled] .btn-default,
.red-hat-content .btn-default.disabled:hover,
.red-hat-content .btn-default[disabled]:hover,
.red-hat-content fieldset[disabled] .btn-default:hover,
.red-hat-content .btn-default.disabled:focus,
.red-hat-content .btn-default[disabled]:focus,
.red-hat-content fieldset[disabled] .btn-default:focus,
.red-hat-content .btn-default.disabled:active,
.red-hat-content .btn-default[disabled]:active,
.red-hat-content fieldset[disabled] .btn-default:active,
.red-hat-content .btn-default.disabled.active,
.red-hat-content .btn-default[disabled].active,
.red-hat-content fieldset[disabled] .btn-default.active {
  background-color: #fff;
  border-color: #ccc;
}
.red-hat-content .btn-default .badge {
  color: #fff;
  background-color: #333;
}
.red-hat-content .btn-primary {
  color: #fff;
  background-color: #428bca;
  border-color: #357ebd;
}
.red-hat-content .btn-primary:hover,
.red-hat-content .btn-primary:focus,
.red-hat-content .btn-primary:active,
.red-hat-content .btn-primary.active,
.red-hat-content .open .dropdown-toggle.btn-primary {
  color: #fff;
  background-color: #3276b1;
  border-color: #285e8e;
}
.red-hat-content .btn-primary:active,
.red-hat-content .btn-primary.active,
.red-hat-content .open .dropdown-toggle.btn-primary {
  background-image: none;
}
.red-hat-content .btn-primary.disabled,
.red-hat-content .btn-primary[disabled],
.red-hat-content fieldset[disabled] .btn-primary,
.red-hat-content .btn-primary.disabled:hover,
.red-hat-content .btn-primary[disabled]:hover,
.red-hat-content fieldset[disabled] .btn-primary:hover,
.red-hat-content .btn-primary.disabled:focus,
.red-hat-content .btn-primary[disabled]:focus,
.red-hat-content fieldset[disabled] .btn-primary:focus,
.red-hat-content .btn-primary.disabled:active,
.red-hat-content .btn-primary[disabled]:active,
.red-hat-content fieldset[disabled] .btn-primary:active,
.red-hat-content .btn-primary.disabled.active,
.red-hat-content .btn-primary[disabled].active,
.red-hat-content fieldset[disabled] .btn-primary.active {
  background-color: #428bca;
  border-color: #357ebd;
}
.red-hat-content .btn-primary .badge {
  color: #428bca;
  background-color: #fff;
}
.red-hat-content .btn-success {
  color: #fff;
  background-color: #5cb85c;
  border-color: #4cae4c;
}
.red-hat-content .btn-success:hover,
.red-hat-content .btn-success:focus,
.red-hat-content .btn-success:active,
.red-hat-content .btn-success.active,
.red-hat-content .open .dropdown-toggle.btn-success {
  color: #fff;
  background-color: #47a447;
  border-color: #398439;
}
.red-hat-content .btn-success:active,
.red-hat-content .btn-success.active,
.red-hat-content .open .dropdown-toggle.btn-success {
  background-image: none;
}
.red-hat-content .btn-success.disabled,
.red-hat-content .btn-success[disabled],
.red-hat-content fieldset[disabled] .btn-success,
.red-hat-content .btn-success.disabled:hover,
.red-hat-content .btn-success[disabled]:hover,
.red-hat-content fieldset[disabled] .btn-success:hover,
.red-hat-content .btn-success.disabled:focus,
.red-hat-content .btn-success[disabled]:focus,
.red-hat-content fieldset[disabled] .btn-success:focus,
.red-hat-content .btn-success.disabled:active,
.red-hat-content .btn-success[disabled]:active,
.red-hat-content fieldset[disabled] .btn-success:active,
.red-hat-content .btn-success.disabled.active,
.red-hat-content .btn-success[disabled].active,
.red-hat-content fieldset[disabled] .btn-success.active {
  background-color: #5cb85c;
  border-color: #4cae4c;
}
.red-hat-content .btn-success .badge {
  color: #5cb85c;
  background-color: #fff;
}
.red-hat-content .btn-info {
  color: #fff;
  background-color: #5bc0de;
  border-color: #46b8da;
}
.red-hat-content .btn-info:hover,
.red-hat-content .btn-info:focus,
.red-hat-content .btn-info:active,
.red-hat-content .btn-info.active,
.red-hat-content .open .dropdown-toggle.btn-info {
  color: #fff;
  background-color: #39b3d7;
  border-color: #269abc;
}
.red-hat-content .btn-info:active,
.red-hat-content .btn-info.active,
.red-hat-content .open .dropdown-toggle.btn-info {
  background-image: none;
}
.red-hat-content .btn-info.disabled,
.red-hat-content .btn-info[disabled],
.red-hat-content fieldset[disabled] .btn-info,
.red-hat-content .btn-info.disabled:hover,
.red-hat-content .btn-info[disabled]:hover,
.red-hat-content fieldset[disabled] .btn-info:hover,
.red-hat-content .btn-info.disabled:focus,
.red-hat-content .btn-info[disabled]:focus,
.red-hat-content fieldset[disabled] .btn-info:focus,
.red-hat-content .btn-info.disabled:active,
.red-hat-content .btn-info[disabled]:active,
.red-hat-content fieldset[disabled] .btn-info:active,
.red-hat-content .btn-info.disabled.active,
.btn-info[disabled].active,
.red-hat-content fieldset[disabled] .btn-info.active {
  background-color: #5bc0de;
  border-color: #46b8da;
}
.red-hat-content .btn-info .badge {
  color: #5bc0de;
  background-color: #fff;
}
.red-hat-content .btn-warning {
  color: #fff;
  background-color: #f0ad4e;
  border-color: #eea236;
}
.red-hat-content .btn-warning:hover,
.red-hat-content .btn-warning:focus,
.red-hat-content .btn-warning:active,
.red-hat-content .btn-warning.active,
.red-hat-content .open .dropdown-toggle.btn-warning {
  color: #fff;
  background-color: #ed9c28;
  border-color: #d58512;
}
.red-hat-content .btn-warning:active,
.red-hat-content .btn-warning.active,
.red-hat-content .open .dropdown-toggle.btn-warning {
  background-image: none;
}
.btn-warning.disabled,
.red-hat-content .btn-warning[disabled],
.red-hat-content fieldset[disabled] .btn-warning,
.red-hat-content .btn-warning.disabled:hover,
.red-hat-content .btn-warning[disabled]:hover,
.red-hat-content fieldset[disabled] .btn-warning:hover,
.red-hat-content .btn-warning.disabled:focus,
.red-hat-content .btn-warning[disabled]:focus,
.red-hat-content fieldset[disabled] .btn-warning:focus,
.red-hat-content .btn-warning.disabled:active,
.red-hat-content .btn-warning[disabled]:active,
.red-hat-content fieldset[disabled] .btn-warning:active,
.red-hat-content .btn-warning.disabled.active,
.red-hat-content .btn-warning[disabled].active,
.red-hat-content fieldset[disabled] .btn-warning.active {
  background-color: #f0ad4e;
  border-color: #eea236;
}
.red-hat-content .btn-warning .badge {
  color: #f0ad4e;
  background-color: #fff;
}
.red-hat-content .btn-danger {
  color: #fff;
  background-color: #d9534f;
  border-color: #d43f3a;
}
.red-hat-content .btn-danger:hover,
.red-hat-content .btn-danger:focus,
.red-hat-content .btn-danger:active,
.red-hat-content .btn-danger.active,
.red-hat-content .open .dropdown-toggle.btn-danger {
  color: #fff;
  background-color: #d2322d;
  border-color: #ac2925;
}
.red-hat-content .btn-danger:active,
.red-hat-content .btn-danger.active,
.red-hat-content .open .dropdown-toggle.btn-danger {
  background-image: none;
}
.red-hat-content .btn-danger.disabled,
.red-hat-content .btn-danger[disabled],
.red-hat-content fieldset[disabled] .btn-danger,
.red-hat-content .btn-danger.disabled:hover,
.red-hat-content .btn-danger[disabled]:hover,
.red-hat-content fieldset[disabled] .btn-danger:hover,
.red-hat-content .btn-danger.disabled:focus,
.red-hat-content .btn-danger[disabled]:focus,
.red-hat-content fieldset[disabled] .btn-danger:focus,
.red-hat-content .btn-danger.disabled:active,
.red-hat-content .btn-danger[disabled]:active,
.red-hat-content fieldset[disabled] .btn-danger:active,
.red-hat-content .btn-danger.disabled.active,
.red-hat-content .btn-danger[disabled].active,
.red-hat-content fieldset[disabled] .btn-danger.active {
  background-color: #d9534f;
  border-color: #d43f3a;
}
.red-hat-content .btn-danger .badge {
  color: #d9534f;
  background-color: #fff;
}
.red-hat-content .btn-link {
  font-weight: normal;
  color: #428bca;
  cursor: pointer;
  border-radius: 0;
}
.red-hat-content .btn-link,
.red-hat-content .btn-link:active,
.red-hat-content .btn-link[disabled],
.red-hat-content fieldset[disabled] .btn-link {
  background-color: transparent;
  -webkit-box-shadow: none;
          box-shadow: none;
}
.red-hat-content .btn-link,
.red-hat-content .btn-link:hover,
.red-hat-content .btn-link:focus,
.red-hat-content .btn-link:active {
  border-color: transparent;
}
.red-hat-content .btn-link:hover,
.red-hat-content .btn-link:focus {
  color: #2a6496;
  text-decoration: underline;
  background-color: transparent;
}
.red-hat-content .btn-link[disabled]:hover,
.red-hat-content fieldset[disabled] .btn-link:hover,
.red-hat-content .btn-link[disabled]:focus,
.red-hat-content fieldset[disabled] .btn-link:focus {
  color: #999;
  text-decoration: none;
}
.red-hat-content .btn-lg,
.red-hat-content .btn-group-lg > .btn {
  padding: 10px 16px;
  font-size: 18px;
  line-height: 1.33;
  border-radius: 6px;
}
.red-hat-content .btn-sm,
.red-hat-content .btn-group-sm > .btn {
  padding: 5px 10px;
  font-size: 12px;
  line-height: 1.5;
  border-radius: 3px;
}
.red-hat-content .btn-xs,
.red-hat-content .btn-group-xs > .btn {
  padding: 1px 5px;
  font-size: 12px;
  line-height: 1.5;
  border-radius: 3px;
}
.red-hat-content .btn-block {
  display: block;
  width: 100%;
  padding-right: 0;
  padding-left: 0;
}
.red-hat-content .btn-block + .btn-block {
  margin-top: 5px;
}
.red-hat-content input[type="submit"].btn-block,
.red-hat-content input[type="reset"].btn-block,
.red-hat-content input[type="button"].btn-block {
  width: 100%;
}
.red-hat-content .fade {
  opacity: 0;
  -webkit-transition: opacity .15s linear;
          transition: opacity .15s linear;
}
.red-hat-content .red-hat-content .fade.in {
  opacity: 1;
}
.red-hat-content .collapse {
  display: none;
}
.red-hat-content .collapse.in {
  display: block;
}
.red-hat-content .collapsing {
  position: relative;
  height: 0;
  overflow: hidden;
  -webkit-transition: height .35s ease;
          transition: height .35s ease;
}
@font-face {
  font-family: 'Glyphicons Halflings';

  src: url('../fonts/glyphicons-halflings-regular.eot');
  src: url('../fonts/glyphicons-halflings-regular.eot?#iefix') format('embedded-opentype'), url('../fonts/glyphicons-halflings-regular.woff') format('woff'), url('../fonts/glyphicons-halflings-regular.ttf') format('truetype'), url('../fonts/glyphicons-halflings-regular.svg#glyphicons_halflingsregular') format('svg');
}
.red-hat-content .glyphicon {
  position: relative;
  top: 1px;
  display: inline-block;
  font-family: 'Glyphicons Halflings';
  font-style: normal;
  font-weight: normal;
  line-height: 1;

  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}
.red-hat-content .glyphicon-asterisk:before {
  content: "\2a";
}
.red-hat-content .glyphicon-plus:before {
  content: "\2b";
}
.red-hat-content .glyphicon-euro:before {
  content: "\20ac";
}
.red-hat-content .glyphicon-minus:before {
  content: "\2212";
}
.red-hat-content .glyphicon-cloud:before {
  content: "\2601";
}
.red-hat-content .glyphicon-envelope:before {
  content: "\2709";
}
.red-hat-content .glyphicon-pencil:before {
  content: "\270f";
}
.red-hat-content .glyphicon-glass:before {
  content: "\e001";
}
.red-hat-content .glyphicon-music:before {
  content: "\e002";
}
.red-hat-content .glyphicon-search:before {
  content: "\e003";
}
.red-hat-content .glyphicon-heart:before {
  content: "\e005";
}
.red-hat-content .glyphicon-star:before {
  content: "\e006";
}
.red-hat-content .glyphicon-star-empty:before {
  content: "\e007";
}
.red-hat-content .glyphicon-user:before {
  content: "\e008";
}
.red-hat-content .glyphicon-film:before {
  content: "\e009";
}
.red-hat-content .glyphicon-th-large:before {
  content: "\e010";
}
.red-hat-content .glyphicon-th:before {
  content: "\e011";
}
.red-hat-content .glyphicon-th-list:before {
  content: "\e012";
}
.red-hat-content .glyphicon-ok:before {
  content: "\e013";
}
.red-hat-content .glyphicon-remove:before {
  content: "\e014";
}
.red-hat-content .glyphicon-zoom-in:before {
  content: "\e015";
}
.red-hat-content .glyphicon-zoom-out:before {
  content: "\e016";
}
.red-hat-content .glyphicon-off:before {
  content: "\e017";
}
.red-hat-content .glyphicon-signal:before {
  content: "\e018";
}
.red-hat-content .glyphicon-cog:before {
  content: "\e019";
}
.red-hat-content .glyphicon-trash:before {
  content: "\e020";
}
.red-hat-content .glyphicon-home:before {
  content: "\e021";
}
.red-hat-content .glyphicon-file:before {
  content: "\e022";
}
.red-hat-content .glyphicon-time:before {
  content: "\e023";
}
.red-hat-content .glyphicon-road:before {
  content: "\e024";
}
.red-hat-content .glyphicon-download-alt:before {
  content: "\e025";
}
.red-hat-content .glyphicon-download:before {
  content: "\e026";
}
.red-hat-content .glyphicon-upload:before {
  content: "\e027";
}
.red-hat-content .glyphicon-inbox:before {
  content: "\e028";
}
.red-hat-content .glyphicon-play-circle:before {
  content: "\e029";
}
.red-hat-content .glyphicon-repeat:before {
  content: "\e030";
}
.red-hat-content .glyphicon-refresh:before {
  content: "\e031";
}
.red-hat-content .glyphicon-list-alt:before {
  content: "\e032";
}
.red-hat-content .glyphicon-lock:before {
  content: "\e033";
}
.red-hat-content .glyphicon-flag:before {
  content: "\e034";
}
.red-hat-content .glyphicon-headphones:before {
  content: "\e035";
}
.red-hat-content .glyphicon-volume-off:before {
  content: "\e036";
}
.red-hat-content .glyphicon-volume-down:before {
  content: "\e037";
}
.red-hat-content .glyphicon-volume-up:before {
  content: "\e038";
}
.red-hat-content .glyphicon-qrcode:before {
  content: "\e039";
}
.red-hat-content .glyphicon-barcode:before {
  content: "\e040";
}
.red-hat-content .glyphicon-tag:before {
  content: "\e041";
}
.red-hat-content .glyphicon-tags:before {
  content: "\e042";
}
.red-hat-content .glyphicon-book:before {
  content: "\e043";
}
.red-hat-content .glyphicon-bookmark:before {
  content: "\e044";
}
.red-hat-content .glyphicon-print:before {
  content: "\e045";
}
.red-hat-content .glyphicon-camera:before {
  content: "\e046";
}
.red-hat-content .glyphicon-font:before {
  content: "\e047";
}
.red-hat-content .glyphicon-bold:before {
  content: "\e048";
}
.red-hat-content .glyphicon-italic:before {
  content: "\e049";
}
.red-hat-content .glyphicon-text-height:before {
  content: "\e050";
}
.red-hat-content .glyphicon-text-width:before {
  content: "\e051";
}
.red-hat-content .glyphicon-align-left:before {
  content: "\e052";
}
.red-hat-content .glyphicon-align-center:before {
  content: "\e053";
}
.red-hat-content .glyphicon-align-right:before {
  content: "\e054";
}
.red-hat-content .glyphicon-align-justify:before {
  content: "\e055";
}
.red-hat-content .glyphicon-list:before {
  content: "\e056";
}
.red-hat-content .glyphicon-indent-left:before {
  content: "\e057";
}
.red-hat-content .glyphicon-indent-right:before {
  content: "\e058";
}
.red-hat-content .glyphicon-facetime-video:before {
  content: "\e059";
}
.red-hat-content .glyphicon-picture:before {
  content: "\e060";
}
.red-hat-content .glyphicon-map-marker:before {
  content: "\e062";
}
.red-hat-content .glyphicon-adjust:before {
  content: "\e063";
}
.red-hat-content .glyphicon-tint:before {
  content: "\e064";
}
.red-hat-content .glyphicon-edit:before {
  content: "\e065";
}
.red-hat-content .glyphicon-share:before {
  content: "\e066";
}
.red-hat-content .glyphicon-check:before {
  content: "\e067";
}
.red-hat-content .glyphicon-move:before {
  content: "\e068";
}
.red-hat-content .glyphicon-step-backward:before {
  content: "\e069";
}
.red-hat-content .glyphicon-fast-backward:before {
  content: "\e070";
}
.red-hat-content .glyphicon-backward:before {
  content: "\e071";
}
.red-hat-content .glyphicon-play:before {
  content: "\e072";
}
.red-hat-content .glyphicon-pause:before {
  content: "\e073";
}
.red-hat-content .glyphicon-stop:before {
  content: "\e074";
}
.red-hat-content .glyphicon-forward:before {
  content: "\e075";
}
.red-hat-content .glyphicon-fast-forward:before {
  content: "\e076";
}
.red-hat-content .glyphicon-step-forward:before {
  content: "\e077";
}
.red-hat-content .glyphicon-eject:before {
  content: "\e078";
}
.red-hat-content .glyphicon-chevron-left:before {
  content: "\e079";
}
.red-hat-content .glyphicon-chevron-right:before {
  content: "\e080";
}
.red-hat-content .glyphicon-plus-sign:before {
  content: "\e081";
}
.red-hat-content .glyphicon-minus-sign:before {
  content: "\e082";
}
.red-hat-content .glyphicon-remove-sign:before {
  content: "\e083";
}
.red-hat-content .glyphicon-ok-sign:before {
  content: "\e084";
}
.red-hat-content .glyphicon-question-sign:before {
  content: "\e085";
}
.red-hat-content .glyphicon-info-sign:before {
  content: "\e086";
}
.red-hat-content .glyphicon-screenshot:before {
  content: "\e087";
}
.red-hat-content .glyphicon-remove-circle:before {
  content: "\e088";
}
.red-hat-content .glyphicon-ok-circle:before {
  content: "\e089";
}
.red-hat-content .glyphicon-ban-circle:before {
  content: "\e090";
}
.red-hat-content .glyphicon-arrow-left:before {
  content: "\e091";
}
.red-hat-content .glyphicon-arrow-right:before {
  content: "\e092";
}
.red-hat-content .glyphicon-arrow-up:before {
  content: "\e093";
}
.red-hat-content .glyphicon-arrow-down:before {
  content: "\e094";
}
.red-hat-content .glyphicon-share-alt:before {
  content: "\e095";
}
.red-hat-content .glyphicon-resize-full:before {
  content: "\e096";
}
.red-hat-content .glyphicon-resize-small:before {
  content: "\e097";
}
.red-hat-content .glyphicon-exclamation-sign:before {
  content: "\e101";
}
.red-hat-content .glyphicon-gift:before {
  content: "\e102";
}
.red-hat-content .glyphicon-leaf:before {
  content: "\e103";
}
.red-hat-content .glyphicon-fire:before {
  content: "\e104";
}
.red-hat-content .glyphicon-eye-open:before {
  content: "\e105";
}
.red-hat-content .glyphicon-eye-close:before {
  content: "\e106";
}
.red-hat-content .glyphicon-warning-sign:before {
  content: "\e107";
}
.red-hat-content .glyphicon-plane:before {
  content: "\e108";
}
.red-hat-content .glyphicon-calendar:before {
  content: "\e109";
}
.red-hat-content .glyphicon-random:before {
  content: "\e110";
}
.red-hat-content .glyphicon-comment:before {
  content: "\e111";
}
.red-hat-content .glyphicon-magnet:before {
  content: "\e112";
}
.red-hat-content .glyphicon-chevron-up:before {
  content: "\e113";
}
.red-hat-content .glyphicon-chevron-down:before {
  content: "\e114";
}
.red-hat-content .glyphicon-retweet:before {
  content: "\e115";
}
.red-hat-content .glyphicon-shopping-cart:before {
  content: "\e116";
}
.red-hat-content .glyphicon-folder-close:before {
  content: "\e117";
}
.red-hat-content .glyphicon-folder-open:before {
  content: "\e118";
}
.red-hat-content .glyphicon-resize-vertical:before {
  content: "\e119";
}
.red-hat-content .glyphicon-resize-horizontal:before {
  content: "\e120";
}
.red-hat-content .glyphicon-hdd:before {
  content: "\e121";
}
.red-hat-content .glyphicon-bullhorn:before {
  content: "\e122";
}
.red-hat-content .glyphicon-bell:before {
  content: "\e123";
}
.red-hat-content .glyphicon-certificate:before {
  content: "\e124";
}
.red-hat-content .glyphicon-thumbs-up:before {
  content: "\e125";
}
.red-hat-content .glyphicon-thumbs-down:before {
  content: "\e126";
}
.red-hat-content .glyphicon-hand-right:before {
  content: "\e127";
}
.red-hat-content .glyphicon-hand-left:before {
  content: "\e128";
}
.red-hat-content .glyphicon-hand-up:before {
  content: "\e129";
}
.red-hat-content .glyphicon-hand-down:before {
  content: "\e130";
}
.red-hat-content .glyphicon-circle-arrow-right:before {
  content: "\e131";
}
.red-hat-content .glyphicon-circle-arrow-left:before {
  content: "\e132";
}
.red-hat-content .glyphicon-circle-arrow-up:before {
  content: "\e133";
}
.red-hat-content .glyphicon-circle-arrow-down:before {
  content: "\e134";
}
.red-hat-content .glyphicon-globe:before {
  content: "\e135";
}
.red-hat-content .glyphicon-wrench:before {
  content: "\e136";
}
.red-hat-content .glyphicon-tasks:before {
  content: "\e137";
}
.red-hat-content .glyphicon-filter:before {
  content: "\e138";
}
.red-hat-content .glyphicon-briefcase:before {
  content: "\e139";
}
.red-hat-content .glyphicon-fullscreen:before {
  content: "\e140";
}
.red-hat-content .glyphicon-dashboard:before {
  content: "\e141";
}
.red-hat-content .glyphicon-paperclip:before {
  content: "\e142";
}
.red-hat-content .glyphicon-heart-empty:before {
  content: "\e143";
}
.red-hat-content .glyphicon-link:before {
  content: "\e144";
}
.red-hat-content .glyphicon-phone:before {
  content: "\e145";
}
.red-hat-content .glyphicon-pushpin:before {
  content: "\e146";
}
.red-hat-content .glyphicon-usd:before {
  content: "\e148";
}
.red-hat-content .glyphicon-gbp:before {
  content: "\e149";
}
.red-hat-content .glyphicon-sort:before {
  content: "\e150";
}
.red-hat-content .glyphicon-sort-by-alphabet:before {
  content: "\e151";
}
.red-hat-content .glyphicon-sort-by-alphabet-alt:before {
  content: "\e152";
}
.red-hat-content .glyphicon-sort-by-order:before {
  content: "\e153";
}
.red-hat-content .glyphicon-sort-by-order-alt:before {
  content: "\e154";
}
.red-hat-content .glyphicon-sort-by-attributes:before {
  content: "\e155";
}
.red-hat-content .glyphicon-sort-by-attributes-alt:before {
  content: "\e156";
}
.red-hat-content .glyphicon-unchecked:before {
  content: "\e157";
}
.red-hat-content .glyphicon-expand:before {
  content: "\e158";
}
.red-hat-content .glyphicon-collapse-down:before {
  content: "\e159";
}
.red-hat-content .glyphicon-collapse-up:before {
  content: "\e160";
}
.red-hat-content .glyphicon-log-in:before {
  content: "\e161";
}
.red-hat-content .glyphicon-flash:before {
  content: "\e162";
}
.red-hat-content .glyphicon-log-out:before {
  content: "\e163";
}
.red-hat-content .glyphicon-new-window:before {
  content: "\e164";
}
.red-hat-content .glyphicon-record:before {
  content: "\e165";
}
.red-hat-content .glyphicon-save:before {
  content: "\e166";
}
.red-hat-content .glyphicon-open:before {
  content: "\e167";
}
.red-hat-content .glyphicon-saved:before {
  content: "\e168";
}
.red-hat-content .glyphicon-import:before {
  content: "\e169";
}
.red-hat-content .glyphicon-export:before {
  content: "\e170";
}
.red-hat-content .glyphicon-send:before {
  content: "\e171";
}
.red-hat-content .glyphicon-floppy-disk:before {
  content: "\e172";
}
.red-hat-content .glyphicon-floppy-saved:before {
  content: "\e173";
}
.red-hat-content .glyphicon-floppy-remove:before {
  content: "\e174";
}
.red-hat-content .glyphicon-floppy-save:before {
  content: "\e175";
}
.red-hat-content .glyphicon-floppy-open:before {
  content: "\e176";
}
.red-hat-content .glyphicon-credit-card:before {
  content: "\e177";
}
.red-hat-content .glyphicon-transfer:before {
  content: "\e178";
}
.red-hat-content .glyphicon-cutlery:before {
  content: "\e179";
}
.red-hat-content .glyphicon-header:before {
  content: "\e180";
}
.red-hat-content .glyphicon-compressed:before {
  content: "\e181";
}
.red-hat-content .glyphicon-earphone:before {
  content: "\e182";
}
.red-hat-content .glyphicon-phone-alt:before {
  content: "\e183";
}
.red-hat-content .glyphicon-tower:before {
  content: "\e184";
}
.red-hat-content .glyphicon-stats:before {
  content: "\e185";
}
.red-hat-content .glyphicon-sd-video:before {
  content: "\e186";
}
.red-hat-content .glyphicon-hd-video:before {
  content: "\e187";
}
.red-hat-content .glyphicon-subtitles:before {
  content: "\e188";
}
.red-hat-content .glyphicon-sound-stereo:before {
  content: "\e189";
}
.red-hat-content .glyphicon-sound-dolby:before {
  content: "\e190";
}
.red-hat-content .glyphicon-sound-5-1:before {
  content: "\e191";
}
.red-hat-content .glyphicon-sound-6-1:before {
  content: "\e192";
}
.red-hat-content .glyphicon-sound-7-1:before {
  content: "\e193";
}
.red-hat-content .glyphicon-copyright-mark:before {
  content: "\e194";
}
.red-hat-content .glyphicon-registration-mark:before {
  content: "\e195";
}
.red-hat-content .glyphicon-cloud-download:before {
  content: "\e197";
}
.red-hat-content .glyphicon-cloud-upload:before {
  content: "\e198";
}
.red-hat-content .glyphicon-tree-conifer:before {
  content: "\e199";
}
.red-hat-content .glyphicon-tree-deciduous:before {
  content: "\e200";
}
.red-hat-content .caret {
  display: inline-block;
  width: 0;
  height: 0;
  margin-left: 2px;
  vertical-align: middle;
  border-top: 4px solid;
  border-right: 4px solid transparent;
  border-left: 4px solid transparent;
}
.red-hat-content .dropdown {
  position: relative;
}
.red-hat-content .dropdown-toggle:focus {
  outline: 0;
}
.red-hat-content .dropdown-menu {
  position: absolute;
  top: 100%;
  left: 0;
  z-index: 1000;
  display: none;
  float: left;
  min-width: 160px;
  padding: 5px 0;
  margin: 2px 0 0;
  font-size: 14px;
  list-style: none;
  background-color: #fff;
  background-clip: padding-box;
  border: 1px solid #ccc;
  border: 1px solid rgba(0, 0, 0, .15);
  border-radius: 4px;
  -webkit-box-shadow: 0 6px 12px rgba(0, 0, 0, .175);
          box-shadow: 0 6px 12px rgba(0, 0, 0, .175);
}
.red-hat-content .dropdown-menu.pull-right {
  right: 0;
  left: auto;
}
.red-hat-content .dropdown-menu .divider {
  height: 1px;
  margin: 9px 0;
  overflow: hidden;
  background-color: #e5e5e5;
}
.red-hat-content .dropdown-menu > li > a {
  display: block;
  padding: 3px 20px;
  clear: both;
  font-weight: normal;
  line-height: 1.42857143;
  color: #333;
  white-space: nowrap;
}
.red-hat-content .dropdown-menu > li > a:hover,
.red-hat-content .dropdown-menu > li > a:focus {
  color: #262626;
  text-decoration: none;
  background-color: #f5f5f5;
}
.red-hat-content .dropdown-menu > .active > a,
.red-hat-content .dropdown-menu > .active > a:hover,
.red-hat-content .dropdown-menu > .active > a:focus {
  color: #fff;
  text-decoration: none;
  background-color: #428bca;
  outline: 0;
}
.red-hat-content .dropdown-menu > .disabled > a,
.red-hat-content .dropdown-menu > .disabled > a:hover,
.red-hat-content .dropdown-menu > .disabled > a:focus {
  color: #999;
}
.red-hat-content .dropdown-menu > .disabled > a:hover,
.red-hat-content .dropdown-menu > .disabled > a:focus {
  text-decoration: none;
  cursor: not-allowed;
  background-color: transparent;
  background-image: none;
  filter: progid:DXImageTransform.Microsoft.gradient(enabled = false);
}
.red-hat-content .open > .dropdown-menu {
  display: block;
}
.red-hat-content .open > a {
  outline: 0;
}
.red-hat-content .dropdown-menu-right {
  right: 0;
  left: auto;
}
.red-hat-content .dropdown-menu-left {
  right: auto;
  left: 0;
}
.red-hat-content .dropdown-header {
  display: block;
  padding: 3px 20px;
  font-size: 12px;
  line-height: 1.42857143;
  color: #999;
}
.red-hat-content .dropdown-backdrop {
  position: fixed;
  top: 0;
  right: 0;
  bottom: 0;
  left: 0;
  z-index: 990;
}
.red-hat-content .pull-right > .dropdown-menu {
  right: 0;
  left: auto;
}
.red-hat-content .dropup .caret,
.red-hat-content .navbar-fixed-bottom .dropdown .caret {
  content: "";
  border-top: 0;
  border-bottom: 4px solid;
}
.red-hat-content .dropup .dropdown-menu,
.red-hat-content .navbar-fixed-bottom .dropdown .dropdown-menu {
  top: auto;
  bottom: 100%;
  margin-bottom: 1px;
}
@media (min-width: 768px) {
  .red-hat-content .navbar-right .dropdown-menu {
    right: 0;
    left: auto;
  }
  .red-hat-content .navbar-right .dropdown-menu-left {
    right: auto;
    left: 0;
  }
}
.red-hat-content .btn-group,
.red-hat-content .btn-group-vertical {
  position: relative;
  display: inline-block;
  vertical-align: middle;
}
.red-hat-content .btn-group > .btn,
.red-hat-content .btn-group-vertical > .btn {
  position: relative;
  float: left;
}
.red-hat-content .btn-group > .btn:hover,
.red-hat-content .btn-group-vertical > .btn:hover,
.red-hat-content .btn-group > .btn:focus,
.red-hat-content .btn-group-vertical > .btn:focus,
.red-hat-content .btn-group > .btn:active,
.red-hat-content .btn-group-vertical > .btn:active,
.red-hat-content .btn-group > .btn.active,
.red-hat-content .btn-group-vertical > .btn.active {
  z-index: 2;
}
.red-hat-content .btn-group > .btn:focus,
.red-hat-content .btn-group-vertical > .btn:focus {
  outline: none;
}
.red-hat-content .btn-group .btn + .btn,
.red-hat-content .btn-group .btn + .btn-group,
.red-hat-content .btn-group .btn-group + .btn,
.red-hat-content .btn-group .btn-group + .btn-group {
  margin-left: -1px;
}
.red-hat-content .btn-toolbar {
  margin-left: -5px;
}
.red-hat-content .btn-toolbar .btn-group,
.red-hat-content .btn-toolbar .input-group {
  float: left;
}
.red-hat-content .btn-toolbar > .btn,
.red-hat-content .btn-toolbar > .btn-group,
.red-hat-content .btn-toolbar > .input-group {
  margin-left: 5px;
}
.red-hat-content .btn-group > .btn:not(:first-child):not(:last-child):not(.dropdown-toggle) {
  border-radius: 0;
}
.red-hat-content .btn-group > .btn:first-child {
  margin-left: 0;
}
.red-hat-content .btn-group > .btn:first-child:not(:last-child):not(.dropdown-toggle) {
  border-top-right-radius: 0;
  border-bottom-right-radius: 0;
}
.red-hat-content .btn-group > .btn:last-child:not(:first-child),
.red-hat-content .btn-group > .dropdown-toggle:not(:first-child) {
  border-top-left-radius: 0;
  border-bottom-left-radius: 0;
}
.red-hat-content .btn-group > .btn-group {
  float: left;
}
.red-hat-content .btn-group > .btn-group:not(:first-child):not(:last-child) > .btn {
  border-radius: 0;
}
.red-hat-content .btn-group > .btn-group:first-child > .btn:last-child,
.red-hat-content .btn-group > .btn-group:first-child > .dropdown-toggle {
  border-top-right-radius: 0;
  border-bottom-right-radius: 0;
}
.red-hat-content .btn-group > .btn-group:last-child > .btn:first-child {
  border-top-left-radius: 0;
  border-bottom-left-radius: 0;
}
.red-hat-content .btn-group .dropdown-toggle:active,
.red-hat-content .btn-group.open .dropdown-toggle {
  outline: 0;
}
.red-hat-content .btn-group > .btn + .dropdown-toggle {
  padding-right: 8px;
  padding-left: 8px;
}
.red-hat-content .btn-group > .btn-lg + .dropdown-toggle {
  padding-right: 12px;
  padding-left: 12px;
}
.red-hat-content .btn-group.open .dropdown-toggle {
  -webkit-box-shadow: inset 0 3px 5px rgba(0, 0, 0, .125);
          box-shadow: inset 0 3px 5px rgba(0, 0, 0, .125);
}
.red-hat-content .btn-group.open .dropdown-toggle.btn-link {
  -webkit-box-shadow: none;
          box-shadow: none;
}
.red-hat-content .btn .caret {
  margin-left: 0;
}
.red-hat-content .btn-lg .caret {
  border-width: 5px 5px 0;
  border-bottom-width: 0;
}
.red-hat-content .dropup .btn-lg .caret {
  border-width: 0 5px 5px;
}
.red-hat-content .btn-group-vertical > .btn,
.red-hat-content .btn-group-vertical > .btn-group,
.red-hat-content .btn-group-vertical > .btn-group > .btn {
  display: block;
  float: none;
  width: 100%;
  max-width: 100%;
}
.red-hat-content .btn-group-vertical > .btn-group > .btn {
  float: none;
}
.red-hat-content .btn-group-vertical > .btn + .btn,
.red-hat-content .btn-group-vertical > .btn + .btn-group,
.red-hat-content .btn-group-vertical > .btn-group + .btn,
.red-hat-content .btn-group-vertical > .btn-group + .btn-group {
  margin-top: -1px;
  margin-left: 0;
}
.red-hat-content .btn-group-vertical > .btn:not(:first-child):not(:last-child) {
  border-radius: 0;
}
.red-hat-content .btn-group-vertical > .btn:first-child:not(:last-child) {
  border-top-right-radius: 4px;
  border-bottom-right-radius: 0;
  border-bottom-left-radius: 0;
}
.red-hat-content .btn-group-vertical > .btn:last-child:not(:first-child) {
  border-top-left-radius: 0;
  border-top-right-radius: 0;
  border-bottom-left-radius: 4px;
}
.red-hat-content .btn-group-vertical > .btn-group:not(:first-child):not(:last-child) > .btn {
  border-radius: 0;
}
.red-hat-content .btn-group-vertical > .btn-group:first-child:not(:last-child) > .btn:last-child,
.red-hat-content .btn-group-vertical > .btn-group:first-child:not(:last-child) > .dropdown-toggle {
  border-bottom-right-radius: 0;
  border-bottom-left-radius: 0;
}
.red-hat-content .btn-group-vertical > .btn-group:last-child:not(:first-child) > .btn:first-child {
  border-top-left-radius: 0;
  border-top-right-radius: 0;
}
.red-hat-content .btn-group-justified {
  display: table;
  width: 100%;
  table-layout: fixed;
  border-collapse: separate;
}
.red-hat-content .btn-group-justified > .btn,
.red-hat-content .btn-group-justified > .btn-group {
  display: table-cell;
  float: none;
  width: 1%;
}
.red-hat-content .btn-group-justified > .btn-group .btn {
  width: 100%;
}
[data-toggle="buttons"] > .btn > input[type="radio"],
[data-toggle="buttons"] > .btn > input[type="checkbox"] {
  display: none;
}
.red-hat-content .input-group {
  position: relative;
  display: table;
  border-collapse: separate;
}
.red-hat-content .input-group[class*="col-"] {
  float: none;
  padding-right: 0;
  padding-left: 0;
}
.red-hat-content .input-group .form-control {
  position: relative;
  z-index: 2;
  float: left;
  width: 100%;
  margin-bottom: 0;
}
.red-hat-content .input-group-lg > .form-control,
.red-hat-content .input-group-lg > .input-group-addon,
.red-hat-content .input-group-lg > .input-group-btn > .btn {
  height: 46px;
  padding: 10px 16px;
  font-size: 18px;
  line-height: 1.33;
  border-radius: 6px;
}
.red-hat-content select.input-group-lg > .form-control,
.red-hat-content select.input-group-lg > .input-group-addon,
.red-hat-content select.input-group-lg > .input-group-btn > .btn {
  height: 46px;
  line-height: 46px;
}
.red-hat-content textarea.input-group-lg > .form-control,
.red-hat-content textarea.input-group-lg > .input-group-addon,
.red-hat-content textarea.input-group-lg > .input-group-btn > .btn,
.red-hat-content select[multiple].input-group-lg > .form-control,
.red-hat-content select[multiple].input-group-lg > .input-group-addon,
.red-hat-content select[multiple].input-group-lg > .input-group-btn > .btn {
  height: auto;
}
.red-hat-content .input-group-sm > .form-control,
.red-hat-content .input-group-sm > .input-group-addon,
.red-hat-content .input-group-sm > .input-group-btn > .btn {
  height: 30px;
  padding: 5px 10px;
  font-size: 12px;
  line-height: 1.5;
  border-radius: 3px;
}
.red-hat-content select.input-group-sm > .form-control,
.red-hat-content select.input-group-sm > .input-group-addon,
.red-hat-content select.input-group-sm > .input-group-btn > .btn {
  height: 30px;
  line-height: 30px;
}
.red-hat-content textarea.input-group-sm > .form-control,
.red-hat-content textarea.input-group-sm > .input-group-addon,
.red-hat-content textarea.input-group-sm > .input-group-btn > .btn,
.red-hat-content select[multiple].input-group-sm > .form-control,
.red-hat-content select[multiple].input-group-sm > .input-group-addon,
.red-hat-content select[multiple].input-group-sm > .input-group-btn > .btn {
  height: auto;
}
.red-hat-content .input-group-addon,
.red-hat-content .input-group-btn,
.red-hat-content .input-group .form-control {
  display: table-cell;
}
.red-hat-content .input-group-addon:not(:first-child):not(:last-child),
.red-hat-content .input-group-btn:not(:first-child):not(:last-child),
.red-hat-content .input-group .form-control:not(:first-child):not(:last-child) {
  border-radius: 0;
}
.red-hat-content .input-group-addon,
.red-hat-content .input-group-btn {
  width: 1%;
  white-space: nowrap;
  vertical-align: middle;
}
.red-hat-content .input-group-addon {
  padding: 6px 12px;
  font-size: 14px;
  font-weight: normal;
  line-height: 1;
  color: #555;
  text-align: center;
  background-color: #eee;
  border: 1px solid #ccc;
  border-radius: 4px;
}
.red-hat-content .input-group-addon.input-sm {
  padding: 5px 10px;
  font-size: 12px;
  border-radius: 3px;
}
.red-hat-content .input-group-addon.input-lg {
  padding: 10px 16px;
  font-size: 18px;
  border-radius: 6px;
}
.red-hat-content .input-group-addon input[type="radio"],
.red-hat-content .input-group-addon input[type="checkbox"] {
  margin-top: 0;
}
.red-hat-content .input-group .form-control:first-child,
.red-hat-content .input-group-addon:first-child,
.red-hat-content .input-group-btn:first-child > .btn,
.red-hat-content .input-group-btn:first-child > .btn-group > .btn,
.red-hat-content .input-group-btn:first-child > .dropdown-toggle,
.red-hat-content .input-group-btn:last-child > .btn:not(:last-child):not(.dropdown-toggle),
.red-hat-content .input-group-btn:last-child > .btn-group:not(:last-child) > .btn {
  border-top-right-radius: 0;
  border-bottom-right-radius: 0;
}
.red-hat-content .input-group-addon:first-child {
  border-right: 0;
}
.red-hat-content .input-group .form-control:last-child,
.red-hat-content .input-group-addon:last-child,
.red-hat-content .input-group-btn:last-child > .btn,
.red-hat-content .input-group-btn:last-child > .btn-group > .btn,
.red-hat-content .input-group-btn:last-child > .dropdown-toggle,
.red-hat-content .input-group-btn:first-child > .btn:not(:first-child),
.red-hat-content .input-group-btn:first-child > .btn-group:not(:first-child) > .btn {
  border-top-left-radius: 0;
  border-bottom-left-radius: 0;
}
.red-hat-content .input-group-addon:last-child {
  border-left: 0;
}
.red-hat-content .input-group-btn {
  position: relative;
  font-size: 0;
  white-space: nowrap;
}
.red-hat-content .input-group-btn > .btn {
  position: relative;
}
.red-hat-content .input-group-btn > .btn + .btn {
  margin-left: -1px;
}
.red-hat-content .input-group-btn > .btn:hover,
.red-hat-content .input-group-btn > .btn:focus,
.red-hat-content .input-group-btn > .btn:active {
  z-index: 2;
}
.red-hat-content .input-group-btn:first-child > .btn,
.red-hat-content .input-group-btn:first-child > .btn-group {
  margin-right: -1px;
}
.red-hat-content .input-group-btn:last-child > .btn,
.red-hat-content .input-group-btn:last-child > .btn-group {
  margin-left: -1px;
}
.red-hat-content .nav {
  padding-left: 0;
  margin-bottom: 0;
  list-style: none;
}
.red-hat-content .nav > li {
  position: relative;
  display: block;
}
.red-hat-content .nav > li > a {
  position: relative;
  display: block;
  padding: 10px 15px;
}
.red-hat-content .nav > li > a:hover,
.red-hat-content .nav > li > a:focus {
  text-decoration: none;
  background-color: #eee;
}
.red-hat-content .nav > li.disabled > a {
  color: #999;
}
.red-hat-content .nav > li.disabled > a:hover,
.red-hat-content .nav > li.disabled > a:focus {
  color: #999;
  text-decoration: none;
  cursor: not-allowed;
  background-color: transparent;
}
.red-hat-content .nav .open > a,
.red-hat-content .nav .open > a:hover,
.red-hat-content .nav .open > a:focus {
  background-color: #eee;
  border-color: #428bca;
}
.red-hat-content .nav .nav-divider {
  height: 1px;
  margin: 9px 0;
  overflow: hidden;
  background-color: #e5e5e5;
}
.red-hat-content .nav > li > a > img {
  max-width: none;
}
.red-hat-content .nav-tabs {
  border-bottom: 1px solid #ddd;
}
.red-hat-content .nav-tabs > li {
  float: left;
  margin-bottom: -1px;
}
.red-hat-content .nav-tabs > li > a {
  margin-right: 2px;
  line-height: 1.42857143;
  border: 1px solid transparent;
  border-radius: 4px 4px 0 0;
}
.red-hat-content .nav-tabs > li > a:hover {
  border-color: #eee #eee #ddd;
}
.red-hat-content .nav-tabs > li.active > a,
.red-hat-content .nav-tabs > li.active > a:hover,
.red-hat-content .nav-tabs > li.active > a:focus {
  color: #555;
  cursor: default;
  background-color: #fff;
  border: 1px solid #ddd;
  border-bottom-color: transparent;
}
.red-hat-content .nav-tabs.nav-justified {
  width: 100%;
  border-bottom: 0;
}
.red-hat-content .nav-tabs.nav-justified > li {
  float: none;
}
.red-hat-content .nav-tabs.nav-justified > li > a {
  margin-bottom: 5px;
  text-align: center;
}
.red-hat-content .nav-tabs.nav-justified > .dropdown .dropdown-menu {
  top: auto;
  left: auto;
}
@media (min-width: 768px) {
  .red-hat-content .nav-tabs.nav-justified > li {
    display: table-cell;
    width: 1%;
  }
  .red-hat-content .nav-tabs.nav-justified > li > a {
    margin-bottom: 0;
  }
}
.red-hat-content .nav-tabs.nav-justified > li > a {
  margin-right: 0;
  border-radius: 4px;
}
.red-hat-content .nav-tabs.nav-justified > .active > a,
.red-hat-content .nav-tabs.nav-justified > .active > a:hover,
.red-hat-content .nav-tabs.nav-justified > .active > a:focus {
  border: 1px solid #ddd;
}
@media (min-width: 768px) {
  .red-hat-content .nav-tabs.nav-justified > li > a {
    border-bottom: 1px solid #ddd;
    border-radius: 4px 4px 0 0;
  }
  .red-hat-content .nav-tabs.nav-justified > .active > a,
  .red-hat-content .nav-tabs.nav-justified > .active > a:hover,
  .red-hat-content .nav-tabs.nav-justified > .active > a:focus {
    border-bottom-color: #fff;
  }
}
.red-hat-content .nav-pills > li {
  float: left;
}
.red-hat-content .nav-pills > li > a {
  border-radius: 4px;
}
.red-hat-content .nav-pills > li + li {
  margin-left: 2px;
}
.red-hat-content .nav-pills > li.active > a,
.red-hat-content .nav-pills > li.active > a:hover,
.red-hat-content .nav-pills > li.active > a:focus {
  color: #fff;
  background-color: #428bca;
}
.red-hat-content .nav-stacked > li {
  float: none;
}
.red-hat-content .nav-stacked > li + li {
  margin-top: 2px;
  margin-left: 0;
}
.red-hat-content .nav-justified {
  width: 100%;
}
.red-hat-content .nav-justified > li {
  float: none;
}
.red-hat-content .nav-justified > li > a {
  margin-bottom: 5px;
  text-align: center;
}
.red-hat-content .nav-justified > .dropdown .dropdown-menu {
  top: auto;
  left: auto;
}
@media (min-width: 768px) {
  .red-hat-content .nav-justified > li {
    display: table-cell;
    width: 1%;
  }
  .red-hat-content .nav-justified > li > a {
    margin-bottom: 0;
  }
}
.red-hat-content .nav-tabs-justified {
  border-bottom: 0;
}
.red-hat-content .nav-tabs-justified > li > a {
  margin-right: 0;
  border-radius: 4px;
}
.red-hat-content .nav-tabs-justified > .active > a,
.red-hat-content .nav-tabs-justified > .active > a:hover,
.red-hat-content .nav-tabs-justified > .active > a:focus {
  border: 1px solid #ddd;
}
@media (min-width: 768px) {
  .red-hat-content .nav-tabs-justified > li > a {
    border-bottom: 1px solid #ddd;
    border-radius: 4px 4px 0 0;
  }
  .red-hat-content .nav-tabs-justified > .active > a,
  .red-hat-content .nav-tabs-justified > .active > a:hover,
  .red-hat-content .nav-tabs-justified > .active > a:focus {
    border-bottom-color: #fff;
  }
}
.red-hat-content .tab-content > .tab-pane {
  display: none;
}
.red-hat-content .tab-content > .active {
  display: block;
}
.red-hat-content .nav-tabs .dropdown-menu {
  margin-top: -1px;
  border-top-left-radius: 0;
  border-top-right-radius: 0;
}
.red-hat-content .navbar {
  position: relative;
  min-height: 50px;
  margin-bottom: 20px;
  border: 1px solid transparent;
}
@media (min-width: 768px) {
  .red-hat-content .navbar {
    border-radius: 4px;
  }
}
@media (min-width: 768px) {
  .red-hat-content .navbar-header {
    float: left;
  }
}
.red-hat-content .navbar-collapse {
  max-height: 340px;
  padding-right: 15px;
  padding-left: 15px;
  overflow-x: visible;
  -webkit-overflow-scrolling: touch;
  border-top: 1px solid transparent;
  box-shadow: inset 0 1px 0 rgba(255, 255, 255, .1);
}
.red-hat-content .navbar-collapse.in {
  overflow-y: auto;
}
@media (min-width: 768px) {
  .red-hat-content .navbar-collapse {
    width: auto;
    border-top: 0;
    box-shadow: none;
  }
  .red-hat-content .navbar-collapse.collapse {
    display: block !important;
    height: auto !important;
    padding-bottom: 0;
    overflow: visible !important;
  }
  .red-hat-content .navbar-collapse.in {
    overflow-y: visible;
  }
  .red-hat-content .navbar-fixed-top .navbar-collapse,
  .red-hat-content .navbar-static-top .navbar-collapse,
  .red-hat-content .navbar-fixed-bottom .navbar-collapse {
    padding-right: 0;
    padding-left: 0;
  }
}
.red-hat-content .container > .navbar-header,
.red-hat-content .container-fluid > .navbar-header,
.red-hat-content .container > .navbar-collapse,
.red-hat-content .container-fluid > .navbar-collapse {
  margin-right: -15px;
  margin-left: -15px;
}
@media (min-width: 768px) {
  .red-hat-content .container > .navbar-header,
  .red-hat-content .container-fluid > .navbar-header,
  .red-hat-content .container > .navbar-collapse,
  .red-hat-content .container-fluid > .navbar-collapse {
    margin-right: 0;
    margin-left: 0;
  }
}
.red-hat-content .navbar-static-top {
  z-index: 1000;
  border-width: 0 0 1px;
}
@media (min-width: 768px) {
  .red-hat-content .navbar-static-top {
    border-radius: 0;
  }
}
.red-hat-content .navbar-fixed-top,
.red-hat-content .navbar-fixed-bottom {
  position: fixed;
  right: 0;
  left: 0;
  z-index: 1030;
}
@media (min-width: 768px) {
  .red-hat-content .navbar-fixed-top,
  .red-hat-content .navbar-fixed-bottom {
    border-radius: 0;
  }
}
.red-hat-content .navbar-fixed-top {
  top: 0;
  border-width: 0 0 1px;
}
.red-hat-content .navbar-fixed-bottom {
  bottom: 0;
  margin-bottom: 0;
  border-width: 1px 0 0;
}
.red-hat-content .navbar-brand {
  float: left;
  height: 50px;
  padding: 15px 15px;
  font-size: 18px;
  line-height: 20px;
}
.red-hat-content .navbar-brand:hover,
.red-hat-content .navbar-brand:focus {
  text-decoration: none;
}
@media (min-width: 768px) {
  .red-hat-content .navbar > .container .navbar-brand,
  .red-hat-content .navbar > .container-fluid .navbar-brand {
    margin-left: -15px;
  }
}
.red-hat-content .navbar-toggle {
  position: relative;
  float: right;
  padding: 9px 10px;
  margin-top: 8px;
  margin-right: 15px;
  margin-bottom: 8px;
  background-color: transparent;
  background-image: none;
  border: 1px solid transparent;
  border-radius: 4px;
}
.red-hat-content .navbar-toggle:focus {
  outline: none;
}
.red-hat-content .navbar-toggle .icon-bar {
  display: block;
  width: 22px;
  height: 2px;
  border-radius: 1px;
}
.red-hat-content .navbar-toggle .icon-bar + .icon-bar {
  margin-top: 4px;
}
@media (min-width: 768px) {
  .red-hat-content .navbar-toggle {
    display: none;
  }
}
.red-hat-content .navbar-nav {
  margin: 7.5px -15px;
}
.red-hat-content .navbar-nav > li > a {
  padding-top: 10px;
  padding-bottom: 10px;
  line-height: 20px;
}
@media (max-width: 767px) {
  .red-hat-content .navbar-nav .open .dropdown-menu {
    position: static;
    float: none;
    width: auto;
    margin-top: 0;
    background-color: transparent;
    border: 0;
    box-shadow: none;
  }
  .red-hat-content .navbar-nav .open .dropdown-menu > li > a,
  .red-hat-content .navbar-nav .open .dropdown-menu .dropdown-header {
    padding: 5px 15px 5px 25px;
  }
  .red-hat-content .navbar-nav .open .dropdown-menu > li > a {
    line-height: 20px;
  }
  .red-hat-content .navbar-nav .open .dropdown-menu > li > a:hover,
  .red-hat-content .navbar-nav .open .dropdown-menu > li > a:focus {
    background-image: none;
  }
}
@media (min-width: 768px) {
  .red-hat-content .navbar-nav {
    float: left;
    margin: 0;
  }
  .red-hat-content .navbar-nav > li {
    float: left;
  }
  .red-hat-content .navbar-nav > li > a {
    padding-top: 15px;
    padding-bottom: 15px;
  }
  .red-hat-content .navbar-nav.navbar-right:last-child {
    margin-right: -15px;
  }
}
@media (min-width: 768px) {
  .red-hat-content .navbar-left {
    float: left !important;
  }
  .red-hat-content .navbar-right {
    float: right !important;
  }
}
.red-hat-content .navbar-form {
  padding: 10px 15px;
  margin-top: 8px;
  margin-right: -15px;
  margin-bottom: 8px;
  margin-left: -15px;
  border-top: 1px solid transparent;
  border-bottom: 1px solid transparent;
  -webkit-box-shadow: inset 0 1px 0 rgba(255, 255, 255, .1), 0 1px 0 rgba(255, 255, 255, .1);
          box-shadow: inset 0 1px 0 rgba(255, 255, 255, .1), 0 1px 0 rgba(255, 255, 255, .1);
}
@media (min-width: 768px) {
  .red-hat-content .navbar-form .form-group {
    display: inline-block;
    margin-bottom: 0;
    vertical-align: middle;
  }
  .red-hat-content .navbar-form .form-control {
    display: inline-block;
    width: auto;
    vertical-align: middle;
  }
  .red-hat-content .navbar-form .input-group > .form-control {
    width: 100%;
  }
  .red-hat-content .navbar-form .control-label {
    margin-bottom: 0;
    vertical-align: middle;
  }
  .red-hat-content .navbar-form .radio,
  .red-hat-content .navbar-form .checkbox {
    display: inline-block;
    padding-left: 0;
    margin-top: 0;
    margin-bottom: 0;
    vertical-align: middle;
  }
  .red-hat-content .navbar-form .radio input[type="radio"],
  .red-hat-content .navbar-form .checkbox input[type="checkbox"] {
    float: none;
    margin-left: 0;
  }
  .red-hat-content .navbar-form .has-feedback .form-control-feedback {
    top: 0;
  }
}
@media (max-width: 767px) {
  .red-hat-content .navbar-form .form-group {
    margin-bottom: 5px;
  }
}
@media (min-width: 768px) {
  .red-hat-content .navbar-form {
    width: auto;
    padding-top: 0;
    padding-bottom: 0;
    margin-right: 0;
    margin-left: 0;
    border: 0;
    -webkit-box-shadow: none;
            box-shadow: none;
  }
  .red-hat-content .navbar-form.navbar-right:last-child {
    margin-right: -15px;
  }
}
.red-hat-content .navbar-nav > li > .dropdown-menu {
  margin-top: 0;
  border-top-left-radius: 0;
  border-top-right-radius: 0;
}
.red-hat-content .navbar-fixed-bottom .navbar-nav > li > .dropdown-menu {
  border-bottom-right-radius: 0;
  border-bottom-left-radius: 0;
}
.red-hat-content .navbar-btn {
  margin-top: 8px;
  margin-bottom: 8px;
}
.red-hat-content .navbar-btn.btn-sm {
  margin-top: 10px;
  margin-bottom: 10px;
}
.red-hat-content .navbar-btn.btn-xs {
  margin-top: 14px;
  margin-bottom: 14px;
}
.red-hat-content .navbar-text {
  margin-top: 15px;
  margin-bottom: 15px;
}
@media (min-width: 768px) {
  .red-hat-content .navbar-text {
    float: left;
    margin-right: 15px;
    margin-left: 15px;
  }
  .red-hat-content .navbar-text.navbar-right:last-child {
    margin-right: 0;
  }
}
.red-hat-content .navbar-default {
  background-color: #f8f8f8;
  border-color: #e7e7e7;
}
.red-hat-content .navbar-default .navbar-brand {
  color: #777;
}
.red-hat-content .navbar-default .navbar-brand:hover,
.red-hat-content .navbar-default .navbar-brand:focus {
  color: #5e5e5e;
  background-color: transparent;
}
.red-hat-content .navbar-default .navbar-text {
  color: #777;
}
.red-hat-content .navbar-default .navbar-nav > li > a {
  color: #777;
}
.red-hat-content .navbar-default .navbar-nav > li > a:hover,
.red-hat-content .navbar-default .navbar-nav > li > a:focus {
  color: #333;
  background-color: transparent;
}
.red-hat-content .navbar-default .navbar-nav > .active > a,
.red-hat-content .navbar-default .navbar-nav > .active > a:hover,
.red-hat-content .navbar-default .navbar-nav > .active > a:focus {
  color: #555;
  background-color: #e7e7e7;
}
.red-hat-content .navbar-default .navbar-nav > .disabled > a,
.red-hat-content .navbar-default .navbar-nav > .disabled > a:hover,
.red-hat-content .navbar-default .navbar-nav > .disabled > a:focus {
  color: #ccc;
  background-color: transparent;
}
.red-hat-content .navbar-default .navbar-toggle {
  border-color: #ddd;
}
.red-hat-content .navbar-default .navbar-toggle:hover,
.red-hat-content .navbar-default .navbar-toggle:focus {
  background-color: #ddd;
}
.red-hat-content .navbar-default .navbar-toggle .icon-bar {
  background-color: #888;
}
.red-hat-content .navbar-default .navbar-collapse,
.red-hat-content .navbar-default .navbar-form {
  border-color: #e7e7e7;
}
.red-hat-content .navbar-default .navbar-nav > .open > a,
.red-hat-content .navbar-default .navbar-nav > .open > a:hover,
.red-hat-content .navbar-default .navbar-nav > .open > a:focus {
  color: #555;
  background-color: #e7e7e7;
}
@media (max-width: 767px) {
  .red-hat-content .navbar-default .navbar-nav .open .dropdown-menu > li > a {
    color: #777;
  }
  .red-hat-content .navbar-default .navbar-nav .open .dropdown-menu > li > a:hover,
  .red-hat-content .navbar-default .navbar-nav .open .dropdown-menu > li > a:focus {
    color: #333;
    background-color: transparent;
  }
  .red-hat-content .navbar-default .navbar-nav .open .dropdown-menu > .active > a,
  .red-hat-content .navbar-default .navbar-nav .open .dropdown-menu > .active > a:hover,
  .red-hat-content .navbar-default .navbar-nav .open .dropdown-menu > .active > a:focus {
    color: #555;
    background-color: #e7e7e7;
  }
  .red-hat-content .navbar-default .navbar-nav .open .dropdown-menu > .disabled > a,
  .red-hat-content .navbar-default .navbar-nav .open .dropdown-menu > .disabled > a:hover,
  .red-hat-content .navbar-default .navbar-nav .open .dropdown-menu > .disabled > a:focus {
    color: #ccc;
    background-color: transparent;
  }
}
.red-hat-content .navbar-default .navbar-link {
  color: #777;
}
.red-hat-content .navbar-default .navbar-link:hover {
  color: #333;
}
.red-hat-content .navbar-inverse {
  background-color: #222;
  border-color: #080808;
}
.red-hat-content .navbar-inverse .navbar-brand {
  color: #999;
}
.red-hat-content .navbar-inverse .navbar-brand:hover,
.red-hat-content .navbar-inverse .navbar-brand:focus {
  color: #fff;
  background-color: transparent;
}
.red-hat-content .navbar-inverse .navbar-text {
  color: #999;
}
.red-hat-content .navbar-inverse .navbar-nav > li > a {
  color: #999;
}
.red-hat-content .navbar-inverse .navbar-nav > li > a:hover,
.red-hat-content .navbar-inverse .navbar-nav > li > a:focus {
  color: #fff;
  background-color: transparent;
}
.red-hat-content .navbar-inverse .navbar-nav > .active > a,
.red-hat-content .navbar-inverse .navbar-nav > .active > a:hover,
.red-hat-content .navbar-inverse .navbar-nav > .active > a:focus {
  color: #fff;
  background-color: #080808;
}
.red-hat-content .navbar-inverse .navbar-nav > .disabled > a,
.red-hat-content .navbar-inverse .navbar-nav > .disabled > a:hover,
.red-hat-content .navbar-inverse .navbar-nav > .disabled > a:focus {
  color: #444;
  background-color: transparent;
}
.red-hat-content .navbar-inverse .navbar-toggle {
  border-color: #333;
}
.red-hat-content .navbar-inverse .navbar-toggle:hover,
.red-hat-content .navbar-inverse .navbar-toggle:focus {
  background-color: #333;
}
.red-hat-content .navbar-inverse .navbar-toggle .icon-bar {
  background-color: #fff;
}
.red-hat-content .navbar-inverse .navbar-collapse,
.red-hat-content .navbar-inverse .navbar-form {
  border-color: #101010;
}
.red-hat-content .navbar-inverse .navbar-nav > .open > a,
.red-hat-content .navbar-inverse .navbar-nav > .open > a:hover,
.red-hat-content .navbar-inverse .navbar-nav > .open > a:focus {
  color: #fff;
  background-color: #080808;
}
@media (max-width: 767px) {
  .red-hat-content .navbar-inverse .navbar-nav .open .dropdown-menu > .dropdown-header {
    border-color: #080808;
  }
  .red-hat-content .navbar-inverse .navbar-nav .open .dropdown-menu .divider {
    background-color: #080808;
  }
  .red-hat-content .navbar-inverse .navbar-nav .open .dropdown-menu > li > a {
    color: #999;
  }
  .red-hat-content .navbar-inverse .navbar-nav .open .dropdown-menu > li > a:hover,
  .red-hat-content .navbar-inverse .navbar-nav .open .dropdown-menu > li > a:focus {
    color: #fff;
    background-color: transparent;
  }
  .red-hat-content .navbar-inverse .navbar-nav .open .dropdown-menu > .active > a,
  .red-hat-content .navbar-inverse .navbar-nav .open .dropdown-menu > .active > a:hover,
  .red-hat-content .navbar-inverse .navbar-nav .open .dropdown-menu > .active > a:focus {
    color: #fff;
    background-color: #080808;
  }
  .red-hat-content .navbar-inverse .navbar-nav .open .dropdown-menu > .disabled > a,
  .red-hat-content .navbar-inverse .navbar-nav .open .dropdown-menu > .disabled > a:hover,
  .red-hat-content .navbar-inverse .navbar-nav .open .dropdown-menu > .disabled > a:focus {
    color: #444;
    background-color: transparent;
  }
}
.red-hat-content .navbar-inverse .navbar-link {
  color: #999;
}
.red-hat-content .navbar-inverse .navbar-link:hover {
  color: #fff;
}
.red-hat-content .breadcrumb {
  padding: 8px 15px;
  margin-bottom: 20px;
  list-style: none;
  background-color: #f5f5f5;
  border-radius: 4px;
}
.red-hat-content .breadcrumb > li {
  display: inline-block;
}
.red-hat-content .breadcrumb > li + li:before {
  padding: 0 5px;
  color: #ccc;
  content: "/\00a0";
}
.red-hat-content .breadcrumb > .active {
  color: #999;
}
.red-hat-content .pagination {
  display: inline-block;
  padding-left: 0;
  margin: 20px 0;
  border-radius: 4px;
}
.red-hat-content .pagination > li {
  display: inline;
}
.red-hat-content .pagination > li > a,
.red-hat-content .pagination > li > span {
  position: relative;
  float: left;
  padding: 6px 12px;
  margin-left: -1px;
  line-height: 1.42857143;
  color: #428bca;
  text-decoration: none;
  background-color: #fff;
  border: 1px solid #ddd;
}
.red-hat-content .pagination > li:first-child > a,
.red-hat-content .pagination > li:first-child > span {
  margin-left: 0;
  border-top-left-radius: 4px;
  border-bottom-left-radius: 4px;
}
.red-hat-content .pagination > li:last-child > a,
.red-hat-content .pagination > li:last-child > span {
  border-top-right-radius: 4px;
  border-bottom-right-radius: 4px;
}
.red-hat-content .pagination > li > a:hover,
.red-hat-content .pagination > li > span:hover,
.red-hat-content .pagination > li > a:focus,
.red-hat-content .pagination > li > span:focus {
  color: #2a6496;
  background-color: #eee;
  border-color: #ddd;
}
.red-hat-content .pagination > .active > a,
.red-hat-content .pagination > .active > span,
.red-hat-content .pagination > .active > a:hover,
.red-hat-content .pagination > .active > span:hover,
.red-hat-content .pagination > .active > a:focus,
.red-hat-content .pagination > .active > span:focus {
  z-index: 2;
  color: #fff;
  cursor: default;
  background-color: #428bca;
  border-color: #428bca;
}
.red-hat-content .pagination > .disabled > span,
.red-hat-content .pagination > .disabled > span:hover,
.red-hat-content .pagination > .disabled > span:focus,
.red-hat-content .pagination > .disabled > a,
.red-hat-content .pagination > .disabled > a:hover,
.red-hat-content .pagination > .disabled > a:focus {
  color: #999;
  cursor: not-allowed;
  background-color: #fff;
  border-color: #ddd;
}
.red-hat-content .pagination-lg > li > a,
.red-hat-content .pagination-lg > li > span {
  padding: 10px 16px;
  font-size: 18px;
}
.red-hat-content .pagination-lg > li:first-child > a,
.red-hat-content .pagination-lg > li:first-child > span {
  border-top-left-radius: 6px;
  border-bottom-left-radius: 6px;
}
.red-hat-content .pagination-lg > li:last-child > a,
.red-hat-content .pagination-lg > li:last-child > span {
  border-top-right-radius: 6px;
  border-bottom-right-radius: 6px;
}
.red-hat-content .pagination-sm > li > a,
.red-hat-content .pagination-sm > li > span {
  padding: 5px 10px;
  font-size: 12px;
}
.red-hat-content .pagination-sm > li:first-child > a,
.red-hat-content .pagination-sm > li:first-child > span {
  border-top-left-radius: 3px;
  border-bottom-left-radius: 3px;
}
.red-hat-content .pagination-sm > li:last-child > a,
.red-hat-content .pagination-sm > li:last-child > span {
  border-top-right-radius: 3px;
  border-bottom-right-radius: 3px;
}
.red-hat-content .pager {
  padding-left: 0;
  margin: 20px 0;
  text-align: center;
  list-style: none;
}
.red-hat-content .pager li {
  display: inline;
}
.red-hat-content .pager li > a,
.red-hat-content .pager li > span {
  display: inline-block;
  padding: 5px 14px;
  background-color: #fff;
  border: 1px solid #ddd;
  border-radius: 15px;
}
.red-hat-content .pager li > a:hover,
.red-hat-content .pager li > a:focus {
  text-decoration: none;
  background-color: #eee;
}
.red-hat-content .pager .next > a,
.red-hat-content .pager .next > span {
  float: right;
}
.red-hat-content .pager .previous > a,
.red-hat-content .pager .previous > span {
  float: left;
}
.red-hat-content .pager .disabled > a,
.red-hat-content .pager .disabled > a:hover,
.red-hat-content .pager .disabled > a:focus,
.red-hat-content .pager .disabled > span {
  color: #999;
  cursor: not-allowed;
  background-color: #fff;
}
.red-hat-content .label {
  display: inline;
  padding: .2em .6em .3em;
  font-size: 75%;
  font-weight: bold;
  line-height: 1;
  color: #fff;
  text-align: center;
  white-space: nowrap;
  vertical-align: baseline;
  border-radius: .25em;
}
.red-hat-content .label[href]:hover,
.red-hat-content .label[href]:focus {
  color: #fff;
  text-decoration: none;
  cursor: pointer;
}
.red-hat-content .label:empty {
  display: none;
}
.red-hat-content .btn .label {
  position: relative;
  top: -1px;
}
.red-hat-content .label-default {
  background-color: #999;
}
.red-hat-content .label-default[href]:hover,
.red-hat-content .label-default[href]:focus {
  background-color: #808080;
}
.red-hat-content .label-primary {
  background-color: #428bca;
}
.red-hat-content .label-primary[href]:hover,
.red-hat-content .label-primary[href]:focus {
  background-color: #3071a9;
}
.red-hat-content .label-success {
  background-color: #5cb85c;
}
.red-hat-content .label-success[href]:hover,
.red-hat-content .label-success[href]:focus {
  background-color: #449d44;
}
.red-hat-content .label-info {
  background-color: #5bc0de;
}
.red-hat-content .label-info[href]:hover,
.red-hat-content .label-info[href]:focus {
  background-color: #31b0d5;
}
.red-hat-content .label-warning {
  background-color: #f0ad4e;
}
.red-hat-content .label-warning[href]:hover,
.red-hat-content .label-warning[href]:focus {
  background-color: #ec971f;
}
.red-hat-content .label-danger {
  background-color: #d9534f;
}
.red-hat-content .label-danger[href]:hover,
.red-hat-content .label-danger[href]:focus {
  background-color: #c9302c;
}
.red-hat-content .badge {
  display: inline-block;
  min-width: 10px;
  padding: 3px 7px;
  font-size: 12px;
  font-weight: bold;
  line-height: 1;
  color: #fff;
  text-align: center;
  white-space: nowrap;
  vertical-align: baseline;
  background-color: #999;
  border-radius: 10px;
}
.red-hat-content .badge:empty {
  display: none;
}
.red-hat-content .btn .badge {
  position: relative;
  top: -1px;
}
.red-hat-content .btn-xs .badge {
  top: 0;
  padding: 1px 5px;
}
.red-hat-content a.badge:hover,
.red-hat-content a.badge:focus {
  color: #fff;
  text-decoration: none;
  cursor: pointer;
}
.red-hat-content a.list-group-item.active > .badge,
.red-hat-content .nav-pills > .active > a > .badge {
  color: #428bca;
  background-color: #fff;
}
.red-hat-content .nav-pills > li > a > .badge {
  margin-left: 3px;
}
.red-hat-content .jumbotron {
  padding: 30px;
  margin-bottom: 30px;
  color: inherit;
  background-color: #eee;
}
.red-hat-content .jumbotron h1,
.red-hat-content .jumbotron .h1 {
  color: inherit;
}
.red-hat-content .jumbotron p {
  margin-bottom: 15px;
  font-size: 21px;
  font-weight: 200;
}
.red-hat-content .container .jumbotron {
  border-radius: 6px;
}
.red-hat-content .jumbotron .container {
  max-width: 100%;
}
@media screen and (min-width: 768px) {
  .red-hat-content .jumbotron {
    padding-top: 48px;
    padding-bottom: 48px;
  }
  .red-hat-content .container .jumbotron {
    padding-right: 60px;
    padding-left: 60px;
  }
  .red-hat-content .jumbotron h1,
  .red-hat-content .jumbotron .h1 {
    font-size: 63px;
  }
}
.red-hat-content .thumbnail {
  display: block;
  padding: 4px;
  margin-bottom: 20px;
  line-height: 1.42857143;
  background-color: #fff;
  border: 1px solid #ddd;
  border-radius: 4px;
  -webkit-transition: all .2s ease-in-out;
          transition: all .2s ease-in-out;
}
.red-hat-content .thumbnail > img,
.red-hat-content .thumbnail a > img {
  margin-right: auto;
  margin-left: auto;
}
.red-hat-content a.thumbnail:hover,
.red-hat-content a.thumbnail:focus,
.red-hat-content a.thumbnail.active {
  border-color: #428bca;
}
.red-hat-content .thumbnail .caption {
  padding: 9px;
  color: #333;
}
.red-hat-content .alert {
  padding: 15px;
  margin-bottom: 20px;
  border: 1px solid transparent;
  border-radius: 4px;
}
.red-hat-content .alert h4 {
  margin-top: 0;
  color: inherit;
}
.red-hat-content .alert .alert-link {
  font-weight: bold;
}
.red-hat-content .alert > p,
.red-hat-content .alert > ul {
  margin-bottom: 0;
}
.red-hat-content .alert > p + p {
  margin-top: 5px;
}
.red-hat-content .alert-dismissable {
  padding-right: 35px;
}
.red-hat-content .alert-dismissable .close {
  position: relative;
  top: -2px;
  right: -21px;
  color: inherit;
}
.red-hat-content .alert-success {
  color: #3c763d;
  background-color: #dff0d8;
  border-color: #d6e9c6;
}
.red-hat-content .alert-success hr {
  border-top-color: #c9e2b3;
}
.red-hat-content .alert-success .alert-link {
  color: #2b542c;
}
.red-hat-content .alert-info {
  color: #31708f;
  background-color: #d9edf7;
  border-color: #bce8f1;
}
.red-hat-content .alert-info hr {
  border-top-color: #a6e1ec;
}
.red-hat-content .alert-info .alert-link {
  color: #245269;
}
.red-hat-content .alert-warning {
  color: #8a6d3b;
  background-color: #fcf8e3;
  border-color: #faebcc;
}
.red-hat-content .alert-warning hr {
  border-top-color: #f7e1b5;
}
.red-hat-content .alert-warning .alert-link {
  color: #66512c;
}
.red-hat-content .alert-danger {
  color: #a94442;
  background-color: #f2dede;
  border-color: #ebccd1;
}
.red-hat-content .alert-danger hr {
  border-top-color: #e4b9c0;
}
.red-hat-content .alert-danger .alert-link {
  color: #843534;
}
@-webkit-keyframes progress-bar-stripes {
  from {
    background-position: 40px 0;
  }
  to {
    background-position: 0 0;
  }
}
@keyframes progress-bar-stripes {
  from {
    background-position: 40px 0;
  }
  to {
    background-position: 0 0;
  }
}
.red-hat-content .progress {
  height: 20px;
  margin-bottom: 20px;
  overflow: hidden;
  background-color: #f5f5f5;
  border-radius: 4px;
  -webkit-box-shadow: inset 0 1px 2px rgba(0, 0, 0, .1);
          box-shadow: inset 0 1px 2px rgba(0, 0, 0, .1);
}
.red-hat-content .progress-bar {
  float: left;
  width: 0;
  height: 100%;
  font-size: 12px;
  line-height: 20px;
  color: #fff;
  text-align: center;
  background-color: #428bca;
  -webkit-box-shadow: inset 0 -1px 0 rgba(0, 0, 0, .15);
          box-shadow: inset 0 -1px 0 rgba(0, 0, 0, .15);
  -webkit-transition: width .6s ease;
          transition: width .6s ease;
}
.red-hat-content .progress-striped .progress-bar {
  background-image: -webkit-linear-gradient(45deg, rgba(255, 255, 255, .15) 25%, transparent 25%, transparent 50%, rgba(255, 255, 255, .15) 50%, rgba(255, 255, 255, .15) 75%, transparent 75%, transparent);
  background-image:         linear-gradient(45deg, rgba(255, 255, 255, .15) 25%, transparent 25%, transparent 50%, rgba(255, 255, 255, .15) 50%, rgba(255, 255, 255, .15) 75%, transparent 75%, transparent);
  background-size: 40px 40px;
}
.red-hat-content .progress.active .progress-bar {
  -webkit-animation: progress-bar-stripes 2s linear infinite;
          animation: progress-bar-stripes 2s linear infinite;
}
.red-hat-content .progress-bar-success {
  background-color: #5cb85c;
}
.red-hat-content .progress-striped .progress-bar-success {
  background-image: -webkit-linear-gradient(45deg, rgba(255, 255, 255, .15) 25%, transparent 25%, transparent 50%, rgba(255, 255, 255, .15) 50%, rgba(255, 255, 255, .15) 75%, transparent 75%, transparent);
  background-image:         linear-gradient(45deg, rgba(255, 255, 255, .15) 25%, transparent 25%, transparent 50%, rgba(255, 255, 255, .15) 50%, rgba(255, 255, 255, .15) 75%, transparent 75%, transparent);
}
.red-hat-content .progress-bar-info {
  background-color: #5bc0de;
}
.red-hat-content .progress-striped .progress-bar-info {
  background-image: -webkit-linear-gradient(45deg, rgba(255, 255, 255, .15) 25%, transparent 25%, transparent 50%, rgba(255, 255, 255, .15) 50%, rgba(255, 255, 255, .15) 75%, transparent 75%, transparent);
  background-image:         linear-gradient(45deg, rgba(255, 255, 255, .15) 25%, transparent 25%, transparent 50%, rgba(255, 255, 255, .15) 50%, rgba(255, 255, 255, .15) 75%, transparent 75%, transparent);
}
.red-hat-content .progress-bar-warning {
  background-color: #f0ad4e;
}
.red-hat-content .progress-striped .progress-bar-warning {
  background-image: -webkit-linear-gradient(45deg, rgba(255, 255, 255, .15) 25%, transparent 25%, transparent 50%, rgba(255, 255, 255, .15) 50%, rgba(255, 255, 255, .15) 75%, transparent 75%, transparent);
  background-image:         linear-gradient(45deg, rgba(255, 255, 255, .15) 25%, transparent 25%, transparent 50%, rgba(255, 255, 255, .15) 50%, rgba(255, 255, 255, .15) 75%, transparent 75%, transparent);
}
.red-hat-content .progress-bar-danger {
  background-color: #d9534f;
}
.red-hat-content .progress-striped .progress-bar-danger {
  background-image: -webkit-linear-gradient(45deg, rgba(255, 255, 255, .15) 25%, transparent 25%, transparent 50%, rgba(255, 255, 255, .15) 50%, rgba(255, 255, 255, .15) 75%, transparent 75%, transparent);
  background-image:         linear-gradient(45deg, rgba(255, 255, 255, .15) 25%, transparent 25%, transparent 50%, rgba(255, 255, 255, .15) 50%, rgba(255, 255, 255, .15) 75%, transparent 75%, transparent);
}
.red-hat-content .media,
.red-hat-content .media-body {
  overflow: hidden;
  zoom: 1;
}
.red-hat-content .media,
.red-hat-content .media .media {
  margin-top: 15px;
}
.red-hat-content .media:first-child {
  margin-top: 0;
}
.red-hat-content .media-object {
  display: block;
}
.red-hat-content .media-heading {
  margin: 0 0 5px;
}
.red-hat-content .media > .pull-left {
  margin-right: 10px;
}
.red-hat-content .media > .pull-right {
  margin-left: 10px;
}
.red-hat-content .media-list {
  padding-left: 0;
  list-style: none;
}
.red-hat-content .list-group {
  padding-left: 0;
  margin-bottom: 20px;
}
.red-hat-content .list-group-item {
  position: relative;
  display: block;
  padding: 10px 15px;
  margin-bottom: -1px;
  background-color: #fff;
  border: 1px solid #ddd;
}
.red-hat-content .list-group-item:first-child {
  border-top-left-radius: 4px;
  border-top-right-radius: 4px;
}
.red-hat-content .list-group-item:last-child {
  margin-bottom: 0;
  border-bottom-right-radius: 4px;
  border-bottom-left-radius: 4px;
}
.red-hat-content .list-group-item > .badge {
  float: right;
}
.red-hat-content .list-group-item > .badge + .badge {
  margin-right: 5px;
}
.red-hat-content a.list-group-item {
  color: #555;
}
.red-hat-content a.list-group-item .list-group-item-heading {
  color: #333;
}
.red-hat-content a.list-group-item:hover,
.red-hat-content a.list-group-item:focus {
  text-decoration: none;
  background-color: #f5f5f5;
}
.red-hat-content a.list-group-item.active,
.red-hat-content a.list-group-item.active:hover,
.red-hat-content a.list-group-item.active:focus {
  z-index: 2;
  color: #fff;
  background-color: #428bca;
  border-color: #428bca;
}
.red-hat-content a.list-group-item.active .list-group-item-heading,
.red-hat-content a.list-group-item.active:hover .list-group-item-heading,
.red-hat-content a.list-group-item.active:focus .list-group-item-heading {
  color: inherit;
}
.red-hat-content a.list-group-item.active .list-group-item-text,
.red-hat-content a.list-group-item.active:hover .list-group-item-text,
.red-hat-content a.list-group-item.active:focus .list-group-item-text {
  color: #e1edf7;
}
.red-hat-content .list-group-item-success {
  color: #3c763d;
  background-color: #dff0d8;
}
.red-hat-content a.list-group-item-success {
  color: #3c763d;
}
.red-hat-content a.list-group-item-success .list-group-item-heading {
  color: inherit;
}
.red-hat-content a.list-group-item-success:hover,
.red-hat-content a.list-group-item-success:focus {
  color: #3c763d;
  background-color: #d0e9c6;
}
.red-hat-content a.list-group-item-success.active,
.red-hat-content a.list-group-item-success.active:hover,
.red-hat-content a.list-group-item-success.active:focus {
  color: #fff;
  background-color: #3c763d;
  border-color: #3c763d;
}
.red-hat-content .list-group-item-info {
  color: #31708f;
  background-color: #d9edf7;
}
.red-hat-content a.list-group-item-info {
  color: #31708f;
}
.red-hat-content a.list-group-item-info .list-group-item-heading {
  color: inherit;
}
.red-hat-content a.list-group-item-info:hover,
.red-hat-content a.list-group-item-info:focus {
  color: #31708f;
  background-color: #c4e3f3;
}
.red-hat-content a.list-group-item-info.active,
.red-hat-content a.list-group-item-info.active:hover,
.red-hat-content a.list-group-item-info.active:focus {
  color: #fff;
  background-color: #31708f;
  border-color: #31708f;
}
.red-hat-content .list-group-item-warning {
  color: #8a6d3b;
  background-color: #fcf8e3;
}
.red-hat-content a.list-group-item-warning {
  color: #8a6d3b;
}
.red-hat-content a.list-group-item-warning .list-group-item-heading {
  color: inherit;
}
.red-hat-content a.list-group-item-warning:hover,
.red-hat-content a.list-group-item-warning:focus {
  color: #8a6d3b;
  background-color: #faf2cc;
}
.red-hat-content a.list-group-item-warning.active,
.red-hat-content a.list-group-item-warning.active:hover,
.red-hat-content a.list-group-item-warning.active:focus {
  color: #fff;
  background-color: #8a6d3b;
  border-color: #8a6d3b;
}
.red-hat-content .list-group-item-danger {
  color: #a94442;
  background-color: #f2dede;
}
.red-hat-content a.list-group-item-danger {
  color: #a94442;
}
.red-hat-content a.list-group-item-danger .list-group-item-heading {
  color: inherit;
}
.red-hat-content a.list-group-item-danger:hover,
.red-hat-content a.list-group-item-danger:focus {
  color: #a94442;
  background-color: #ebcccc;
}
.red-hat-content a.list-group-item-danger.active,
.red-hat-content a.list-group-item-danger.active:hover,
.red-hat-content a.list-group-item-danger.active:focus {
  color: #fff;
  background-color: #a94442;
  border-color: #a94442;
}
.red-hat-content .list-group-item-heading {
  margin-top: 0;
  margin-bottom: 5px;
}
.red-hat-content .list-group-item-text {
  margin-bottom: 0;
  line-height: 1.3;
}
.red-hat-content .panel {
  margin-bottom: 20px;
  background-color: #fff;
  border: 1px solid transparent;
  border-radius: 4px;
  -webkit-box-shadow: 0 1px 1px rgba(0, 0, 0, .05);
          box-shadow: 0 1px 1px rgba(0, 0, 0, .05);
}
.red-hat-content .panel-body {
  padding: 15px;
}
.red-hat-content .panel-heading {
  padding: 10px 15px;
  border-bottom: 1px solid transparent;
  border-top-left-radius: 3px;
  border-top-right-radius: 3px;
}
.red-hat-content .panel-heading > .dropdown .dropdown-toggle {
  color: inherit;
}
.red-hat-content .panel-title {
  margin-top: 0;
  margin-bottom: 0;
  font-size: 16px;
  color: inherit;
}
.red-hat-content .panel-title > a {
  color: inherit;
}
.red-hat-content .panel-footer {
  padding: 10px 15px;
  background-color: #f5f5f5;
  border-top: 1px solid #ddd;
  border-bottom-right-radius: 3px;
  border-bottom-left-radius: 3px;
}
.red-hat-content .panel > .list-group {
  margin-bottom: 0;
}
.red-hat-content .panel > .list-group .list-group-item {
  border-width: 1px 0;
  border-radius: 0;
}
.red-hat-content .panel > .list-group:first-child .list-group-item:first-child {
  border-top: 0;
  border-top-left-radius: 3px;
  border-top-right-radius: 3px;
}
.red-hat-content .panel > .list-group:last-child .list-group-item:last-child {
  border-bottom: 0;
  border-bottom-right-radius: 3px;
  border-bottom-left-radius: 3px;
}
.red-hat-content .panel-heading + .list-group .list-group-item:first-child {
  border-top-width: 0;
}
.red-hat-content .panel > .table,
.red-hat-content .panel > .table-responsive > .table {
  margin-bottom: 0;
}
.red-hat-content .panel > .table:first-child,
.red-hat-content .panel > .table-responsive:first-child > .table:first-child {
  border-top-left-radius: 3px;
  border-top-right-radius: 3px;
}
.red-hat-content .panel > .table:first-child > thead:first-child > tr:first-child td:first-child,
.red-hat-content .panel > .table-responsive:first-child > .table:first-child > thead:first-child > tr:first-child td:first-child,
.red-hat-content .panel > .table:first-child > tbody:first-child > tr:first-child td:first-child,
.red-hat-content .panel > .table-responsive:first-child > .table:first-child > tbody:first-child > tr:first-child td:first-child,
.red-hat-content .panel > .table:first-child > thead:first-child > tr:first-child th:first-child,
.red-hat-content .panel > .table-responsive:first-child > .table:first-child > thead:first-child > tr:first-child th:first-child,
.red-hat-content .panel > .table:first-child > tbody:first-child > tr:first-child th:first-child,
.red-hat-content .panel > .table-responsive:first-child > .table:first-child > tbody:first-child > tr:first-child th:first-child {
  border-top-left-radius: 3px;
}
.red-hat-content .panel > .table:first-child > thead:first-child > tr:first-child td:last-child,
.red-hat-content .panel > .table-responsive:first-child > .table:first-child > thead:first-child > tr:first-child td:last-child,
.red-hat-content .panel > .table:first-child > tbody:first-child > tr:first-child td:last-child,
.red-hat-content .panel > .table-responsive:first-child > .table:first-child > tbody:first-child > tr:first-child td:last-child,
.red-hat-content .panel > .table:first-child > thead:first-child > tr:first-child th:last-child,
.red-hat-content .panel > .table-responsive:first-child > .table:first-child > thead:first-child > tr:first-child th:last-child,
.red-hat-content .panel > .table:first-child > tbody:first-child > tr:first-child th:last-child,
.red-hat-content .panel > .table-responsive:first-child > .table:first-child > tbody:first-child > tr:first-child th:last-child {
  border-top-right-radius: 3px;
}
.red-hat-content .panel > .table:last-child,
.red-hat-content .panel > .table-responsive:last-child > .table:last-child {
  border-bottom-right-radius: 3px;
  border-bottom-left-radius: 3px;
}
.red-hat-content .panel > .table:last-child > tbody:last-child > tr:last-child td:first-child,
.red-hat-content .panel > .table-responsive:last-child > .table:last-child > tbody:last-child > tr:last-child td:first-child,
.red-hat-content .panel > .table:last-child > tfoot:last-child > tr:last-child td:first-child,
.red-hat-content .panel > .table-responsive:last-child > .table:last-child > tfoot:last-child > tr:last-child td:first-child,
.red-hat-content .panel > .table:last-child > tbody:last-child > tr:last-child th:first-child,
.red-hat-content .panel > .table-responsive:last-child > .table:last-child > tbody:last-child > tr:last-child th:first-child,
.red-hat-content .panel > .table:last-child > tfoot:last-child > tr:last-child th:first-child,
.red-hat-content .panel > .table-responsive:last-child > .table:last-child > tfoot:last-child > tr:last-child th:first-child {
  border-bottom-left-radius: 3px;
}
.red-hat-content .panel > .table:last-child > tbody:last-child > tr:last-child td:last-child,
.red-hat-content .panel > .table-responsive:last-child > .table:last-child > tbody:last-child > tr:last-child td:last-child,
.red-hat-content .panel > .table:last-child > tfoot:last-child > tr:last-child td:last-child,
.red-hat-content .panel > .table-responsive:last-child > .table:last-child > tfoot:last-child > tr:last-child td:last-child,
.red-hat-content .panel > .table:last-child > tbody:last-child > tr:last-child th:last-child,
.red-hat-content .panel > .table-responsive:last-child > .table:last-child > tbody:last-child > tr:last-child th:last-child,
.red-hat-content .panel > .table:last-child > tfoot:last-child > tr:last-child th:last-child,
.red-hat-content .panel > .table-responsive:last-child > .table:last-child > tfoot:last-child > tr:last-child th:last-child {
  border-bottom-right-radius: 3px;
}
.red-hat-content .panel > .panel-body + .table,
.red-hat-content .panel > .panel-body + .table-responsive {
  border-top: 1px solid #ddd;
}
.red-hat-content .panel > .table > tbody:first-child > tr:first-child th,
.red-hat-content .panel > .table > tbody:first-child > tr:first-child td {
  border-top: 0;
}
.red-hat-content .panel > .table-bordered,
.red-hat-content .panel > .table-responsive > .table-bordered {
  border: 0;
}
.red-hat-content .panel > .table-bordered > thead > tr > th:first-child,
.red-hat-content .panel > .table-responsive > .table-bordered > thead > tr > th:first-child,
.red-hat-content .panel > .table-bordered > tbody > tr > th:first-child,
.red-hat-content .panel > .table-responsive > .table-bordered > tbody > tr > th:first-child,
.red-hat-content .panel > .table-bordered > tfoot > tr > th:first-child,
.red-hat-content .panel > .table-responsive > .table-bordered > tfoot > tr > th:first-child,
.red-hat-content .panel > .table-bordered > thead > tr > td:first-child,
.red-hat-content .panel > .table-responsive > .table-bordered > thead > tr > td:first-child,
.red-hat-content .panel > .table-bordered > tbody > tr > td:first-child,
.red-hat-content .panel > .table-responsive > .table-bordered > tbody > tr > td:first-child,
.red-hat-content .panel > .table-bordered > tfoot > tr > td:first-child,
.red-hat-content .panel > .table-responsive > .table-bordered > tfoot > tr > td:first-child {
  border-left: 0;
}
.red-hat-content .panel > .table-bordered > thead > tr > th:last-child,
.red-hat-content .panel > .table-responsive > .table-bordered > thead > tr > th:last-child,
.red-hat-content .panel > .table-bordered > tbody > tr > th:last-child,
.red-hat-content .panel > .table-responsive > .table-bordered > tbody > tr > th:last-child,
.red-hat-content .panel > .table-bordered > tfoot > tr > th:last-child,
.red-hat-content .panel > .table-responsive > .table-bordered > tfoot > tr > th:last-child,
.red-hat-content .panel > .table-bordered > thead > tr > td:last-child,
.red-hat-content .panel > .table-responsive > .table-bordered > thead > tr > td:last-child,
.red-hat-content .panel > .table-bordered > tbody > tr > td:last-child,
.red-hat-content .panel > .table-responsive > .table-bordered > tbody > tr > td:last-child,
.red-hat-content .panel > .table-bordered > tfoot > tr > td:last-child,
.red-hat-content .panel > .table-responsive > .table-bordered > tfoot > tr > td:last-child {
  border-right: 0;
}
.red-hat-content .panel > .table-bordered > thead > tr:first-child > td,
.red-hat-content .panel > .table-responsive > .table-bordered > thead > tr:first-child > td,
.red-hat-content .panel > .table-bordered > tbody > tr:first-child > td,
.red-hat-content .panel > .table-responsive > .table-bordered > tbody > tr:first-child > td,
.red-hat-content .panel > .table-bordered > thead > tr:first-child > th,
.red-hat-content .panel > .table-responsive > .table-bordered > thead > tr:first-child > th,
.red-hat-content .panel > .table-bordered > tbody > tr:first-child > th,
.red-hat-content .panel > .table-responsive > .table-bordered > tbody > tr:first-child > th {
  border-bottom: 0;
}
.red-hat-content .panel > .table-bordered > tbody > tr:last-child > td,
.red-hat-content .panel > .table-responsive > .table-bordered > tbody > tr:last-child > td,
.red-hat-content .panel > .table-bordered > tfoot > tr:last-child > td,
.red-hat-content .panel > .table-responsive > .table-bordered > tfoot > tr:last-child > td,
.red-hat-content .panel > .table-bordered > tbody > tr:last-child > th,
.red-hat-content .panel > .table-responsive > .table-bordered > tbody > tr:last-child > th,
.red-hat-content .panel > .table-bordered > tfoot > tr:last-child > th,
.red-hat-content .panel > .table-responsive > .table-bordered > tfoot > tr:last-child > th {
  border-bottom: 0;
}
.red-hat-content .panel > .table-responsive {
  margin-bottom: 0;
  border: 0;
}
.red-hat-content .panel-group {
  margin-bottom: 20px;
}
.red-hat-content .panel-group .panel {
  margin-bottom: 0;
  overflow: hidden;
  border-radius: 4px;
}
.red-hat-content .panel-group .panel + .panel {
  margin-top: 5px;
}
.red-hat-content .panel-group .panel-heading {
  border-bottom: 0;
}
.red-hat-content .panel-group .panel-heading + .panel-collapse .panel-body {
  border-top: 1px solid #ddd;
}
.red-hat-content .panel-group .panel-footer {
  border-top: 0;
}
.red-hat-content .panel-group .panel-footer + .panel-collapse .panel-body {
  border-bottom: 1px solid #ddd;
}
.red-hat-content .panel-default {
  border-color: #ddd;
}
.red-hat-content .panel-default > .panel-heading {
  color: #333;
  background-color: #f5f5f5;
  border-color: #ddd;
}
.red-hat-content .panel-default > .panel-heading + .panel-collapse .panel-body {
  border-top-color: #ddd;
}
.red-hat-content .panel-default > .panel-footer + .panel-collapse .panel-body {
  border-bottom-color: #ddd;
}
.red-hat-content .panel-primary {
  border-color: #428bca;
}
.red-hat-content .panel-primary > .panel-heading {
  color: #fff;
  background-color: #428bca;
  border-color: #428bca;
}
.red-hat-content .panel-primary > .panel-heading + .panel-collapse .panel-body {
  border-top-color: #428bca;
}
.red-hat-content .panel-primary > .panel-footer + .panel-collapse .panel-body {
  border-bottom-color: #428bca;
}
.red-hat-content .panel-success {
  border-color: #d6e9c6;
}
.red-hat-content .panel-success > .panel-heading {
  color: #3c763d;
  background-color: #dff0d8;
  border-color: #d6e9c6;
}
.red-hat-content .panel-success > .panel-heading + .panel-collapse .panel-body {
  border-top-color: #d6e9c6;
}
.red-hat-content .panel-success > .panel-footer + .panel-collapse .panel-body {
  border-bottom-color: #d6e9c6;
}
.red-hat-content .panel-info {
  border-color: #bce8f1;
}
.red-hat-content .panel-info > .panel-heading {
  color: #31708f;
  background-color: #d9edf7;
  border-color: #bce8f1;
}
.red-hat-content .panel-info > .panel-heading + .panel-collapse .panel-body {
  border-top-color: #bce8f1;
}
.red-hat-content .panel-info > .panel-footer + .panel-collapse .panel-body {
  border-bottom-color: #bce8f1;
}
.red-hat-content .panel-warning {
  border-color: #faebcc;
}
.red-hat-content .panel-warning > .panel-heading {
  color: #8a6d3b;
  background-color: #fcf8e3;
  border-color: #faebcc;
}
.red-hat-content .panel-warning > .panel-heading + .panel-collapse .panel-body {
  border-top-color: #faebcc;
}
.red-hat-content .panel-warning > .panel-footer + .panel-collapse .panel-body {
  border-bottom-color: #faebcc;
}
.red-hat-content .panel-danger {
  border-color: #ebccd1;
}
.red-hat-content .panel-danger > .panel-heading {
  color: #a94442;
  background-color: #f2dede;
  border-color: #ebccd1;
}
.red-hat-content .panel-danger > .panel-heading + .panel-collapse .panel-body {
  border-top-color: #ebccd1;
}
.red-hat-content .panel-danger > .panel-footer + .panel-collapse .panel-body {
  border-bottom-color: #ebccd1;
}
.red-hat-content .well {
  min-height: 20px;
  padding: 19px;
  margin-bottom: 20px;
  background-color: #f5f5f5;
  border: 1px solid #e3e3e3;
  border-radius: 4px;
  -webkit-box-shadow: inset 0 1px 1px rgba(0, 0, 0, .05);
          box-shadow: inset 0 1px 1px rgba(0, 0, 0, .05);
}
.red-hat-content .well blockquote {
  border-color: #ddd;
  border-color: rgba(0, 0, 0, .15);
}
.red-hat-content .well-lg {
  padding: 24px;
  border-radius: 6px;
}
.red-hat-content .well-sm {
  padding: 9px;
  border-radius: 3px;
}
.red-hat-content .close {
  float: right;
  font-size: 21px;
  font-weight: bold;
  line-height: 1;
  color: #000;
  text-shadow: 0 1px 0 #fff;
  filter: alpha(opacity=20);
  opacity: .2;
}
.red-hat-content .close:hover,
.red-hat-content .close:focus {
  color: #000;
  text-decoration: none;
  cursor: pointer;
  filter: alpha(opacity=50);
  opacity: .5;
}
.red-hat-content button.close {
  -webkit-appearance: none;
  padding: 0;
  cursor: pointer;
  background: transparent;
  border: 0;
}
.red-hat-content .modal-open {
  overflow: hidden;
}
.red-hat-content .modal {
  position: fixed;
  top: 0;
  right: 0;
  bottom: 0;
  left: 0;
  z-index: 1050;
  display: none;
  overflow: auto;
  overflow-y: scroll;
  -webkit-overflow-scrolling: touch;
  outline: 0;
}
.red-hat-content .modal.fade .modal-dialog {
  -webkit-transition: -webkit-transform .3s ease-out;
     -moz-transition:    -moz-transform .3s ease-out;
       -o-transition:      -o-transform .3s ease-out;
          transition:         transform .3s ease-out;
  -webkit-transform: translate(0, -25%);
      -ms-transform: translate(0, -25%);
          transform: translate(0, -25%);
}
.red-hat-content .modal.in .modal-dialog {
  -webkit-transform: translate(0, 0);
      -ms-transform: translate(0, 0);
          transform: translate(0, 0);
}
.red-hat-content .modal-dialog {
  position: relative;
  width: auto;
  margin: 10px;
}
.red-hat-content .modal-content {
  position: relative;
  background-color: #fff;
  background-clip: padding-box;
  border: 1px solid #999;
  border: 1px solid rgba(0, 0, 0, .2);
  border-radius: 6px;
  outline: none;
  -webkit-box-shadow: 0 3px 9px rgba(0, 0, 0, .5);
          box-shadow: 0 3px 9px rgba(0, 0, 0, .5);
}
.red-hat-content .modal-backdrop {
  position: fixed;
  top: 0;
  right: 0;
  bottom: 0;
  left: 0;
  z-index: 1040;
  background-color: #000;
}
.red-hat-content .modal-backdrop.fade {
  filter: alpha(opacity=0);
  opacity: 0;
}
.red-hat-content .modal-backdrop.in {
  filter: alpha(opacity=50);
  opacity: .5;
}
.red-hat-content .modal-header {
  min-height: 16.42857143px;
  padding: 15px;
  border-bottom: 1px solid #e5e5e5;
}
.red-hat-content .modal-header .close {
  margin-top: -2px;
}
.red-hat-content .modal-title {
  margin: 0;
  line-height: 1.42857143;
}
.red-hat-content .modal-body {
  position: relative;
  padding: 20px;
}
.red-hat-content .modal-footer {
  padding: 19px 20px 20px;
  margin-top: 15px;
  text-align: right;
  border-top: 1px solid #e5e5e5;
}
.red-hat-content .modal-footer .btn + .btn {
  margin-bottom: 0;
  margin-left: 5px;
}
.red-hat-content .modal-footer .btn-group .btn + .btn {
  margin-left: -1px;
}
.red-hat-content .modal-footer .btn-block + .btn-block {
  margin-left: 0;
}
@media (min-width: 768px) {
  .red-hat-content .modal-dialog {
    width: 600px;
    margin: 30px auto;
  }
  .red-hat-content .modal-content {
    -webkit-box-shadow: 0 5px 15px rgba(0, 0, 0, .5);
            box-shadow: 0 5px 15px rgba(0, 0, 0, .5);
  }
  .red-hat-content .modal-sm {
    width: 300px;
  }
}
@media (min-width: 992px) {
  .red-hat-content .modal-lg {
    width: 900px;
  }
}
.red-hat-content .tooltip {
  position: absolute;
  z-index: 1030;
  display: block;
  font-size: 12px;
  line-height: 1.4;
  visibility: visible;
  filter: alpha(opacity=0);
  opacity: 0;
}
..red-hat-content tooltip.in {
  filter: alpha(opacity=90);
  opacity: .9;
}
.red-hat-content .tooltip.top {
  padding: 5px 0;
  margin-top: -3px;
}
.red-hat-content .tooltip.right {
  padding: 0 5px;
  margin-left: 3px;
}
.red-hat-content .tooltip.bottom {
  padding: 5px 0;
  margin-top: 3px;
}
.red-hat-content .tooltip.left {
  padding: 0 5px;
  margin-left: -3px;
}
.red-hat-content .tooltip-inner {
  max-width: 200px;
  padding: 3px 8px;
  color: #fff;
  text-align: center;
  text-decoration: none;
  background-color: #000;
  border-radius: 4px;
}
.red-hat-content .tooltip-arrow {
  position: absolute;
  width: 0;
  height: 0;
  border-color: transparent;
  border-style: solid;
}
.red-hat-content .tooltip.top .tooltip-arrow {
  bottom: 0;
  left: 50%;
  margin-left: -5px;
  border-width: 5px 5px 0;
  border-top-color: #000;
}
.red-hat-content .tooltip.top-left .tooltip-arrow {
  bottom: 0;
  left: 5px;
  border-width: 5px 5px 0;
  border-top-color: #000;
}
.red-hat-content .tooltip.top-right .tooltip-arrow {
  right: 5px;
  bottom: 0;
  border-width: 5px 5px 0;
  border-top-color: #000;
}
.red-hat-content .tooltip.right .tooltip-arrow {
  top: 50%;
  left: 0;
  margin-top: -5px;
  border-width: 5px 5px 5px 0;
  border-right-color: #000;
}
.red-hat-content .tooltip.left .tooltip-arrow {
  top: 50%;
  right: 0;
  margin-top: -5px;
  border-width: 5px 0 5px 5px;
  border-left-color: #000;
}
.red-hat-content .tooltip.bottom .tooltip-arrow {
  top: 0;
  left: 50%;
  margin-left: -5px;
  border-width: 0 5px 5px;
  border-bottom-color: #000;
}
.red-hat-content .tooltip.bottom-left .tooltip-arrow {
  top: 0;
  left: 5px;
  border-width: 0 5px 5px;
  border-bottom-color: #000;
}
.red-hat-content .tooltip.bottom-right .tooltip-arrow {
  top: 0;
  right: 5px;
  border-width: 0 5px 5px;
  border-bottom-color: #000;
}
.red-hat-content .popover {
  position: absolute;
  top: 0;
  left: 0;
  z-index: 1010;
  display: none;
  max-width: 276px;
  padding: 1px;
  text-align: left;
  white-space: normal;
  background-color: #fff;
  background-clip: padding-box;
  border: 1px solid #ccc;
  border: 1px solid rgba(0, 0, 0, .2);
  border-radius: 6px;
  -webkit-box-shadow: 0 5px 10px rgba(0, 0, 0, .2);
          box-shadow: 0 5px 10px rgba(0, 0, 0, .2);
}
.red-hat-content .popover.top {
  margin-top: -10px;
}
.red-hat-content .popover.right {
  margin-left: 10px;
}
.red-hat-content .popover.bottom {
  margin-top: 10px;
}
.red-hat-content .popover.left {
  margin-left: -10px;
}
.red-hat-content .popover-title {
  padding: 8px 14px;
  margin: 0;
  font-size: 14px;
  font-weight: normal;
  line-height: 18px;
  background-color: #f7f7f7;
  border-bottom: 1px solid #ebebeb;
  border-radius: 5px 5px 0 0;
}
.red-hat-content .popover-content {
  padding: 9px 14px;
}
.red-hat-content .popover > .arrow,
.red-hat-content .popover > .arrow:after {
  position: absolute;
  display: block;
  width: 0;
  height: 0;
  border-color: transparent;
  border-style: solid;
}
.red-hat-content .popover > .arrow {
  border-width: 11px;
}
.red-hat-content .popover > .arrow:after {
  content: "";
  border-width: 10px;
}
.red-hat-content .popover.top > .arrow {
  bottom: -11px;
  left: 50%;
  margin-left: -11px;
  border-top-color: #999;
  border-top-color: rgba(0, 0, 0, .25);
  border-bottom-width: 0;
}
.red-hat-content .popover.top > .arrow:after {
  bottom: 1px;
  margin-left: -10px;
  content: " ";
  border-top-color: #fff;
  border-bottom-width: 0;
}
.red-hat-content .popover.right > .arrow {
  top: 50%;
  left: -11px;
  margin-top: -11px;
  border-right-color: #999;
  border-right-color: rgba(0, 0, 0, .25);
  border-left-width: 0;
}
.red-hat-content .popover.right > .arrow:after {
  bottom: -10px;
  left: 1px;
  content: " ";
  border-right-color: #fff;
  border-left-width: 0;
}
.red-hat-content .popover.bottom > .arrow {
  top: -11px;
  left: 50%;
  margin-left: -11px;
  border-top-width: 0;
  border-bottom-color: #999;
  border-bottom-color: rgba(0, 0, 0, .25);
}
.red-hat-content .popover.bottom > .arrow:after {
  top: 1px;
  margin-left: -10px;
  content: " ";
  border-top-width: 0;
  border-bottom-color: #fff;
}
.red-hat-content .popover.left > .arrow {
  top: 50%;
  right: -11px;
  margin-top: -11px;
  border-right-width: 0;
  border-left-color: #999;
  border-left-color: rgba(0, 0, 0, .25);
}
.red-hat-content .popover.left > .arrow:after {
  right: 1px;
  bottom: -10px;
  content: " ";
  border-right-width: 0;
  border-left-color: #fff;
}
.carousel {
  position: relative;
}
.carousel-inner {
  position: relative;
  width: 100%;
  overflow: hidden;
}
.carousel-inner > .item {
  position: relative;
  display: none;
  -webkit-transition: .6s ease-in-out left;
          transition: .6s ease-in-out left;
}
.carousel-inner > .item > img,
.carousel-inner > .item > a > img {
  line-height: 1;
}
.carousel-inner > .active,
.carousel-inner > .next,
.carousel-inner > .prev {
  display: block;
}
.carousel-inner > .active {
  left: 0;
}
.carousel-inner > .next,
.carousel-inner > .prev {
  position: absolute;
  top: 0;
  width: 100%;
}
.carousel-inner > .next {
  left: 100%;
}
.carousel-inner > .prev {
  left: -100%;
}
.carousel-inner > .next.left,
.carousel-inner > .prev.right {
  left: 0;
}
.carousel-inner > .active.left {
  left: -100%;
}
.carousel-inner > .active.right {
  left: 100%;
}
.carousel-control {
  position: absolute;
  top: 0;
  bottom: 0;
  left: 0;
  width: 15%;
  font-size: 20px;
  color: #fff;
  text-align: center;
  text-shadow: 0 1px 2px rgba(0, 0, 0, .6);
  filter: alpha(opacity=50);
  opacity: .5;
}
.carousel-control.left {
  background-image: -webkit-linear-gradient(left, color-stop(rgba(0, 0, 0, .5) 0%), color-stop(rgba(0, 0, 0, .0001) 100%));
  background-image:         linear-gradient(to right, rgba(0, 0, 0, .5) 0%, rgba(0, 0, 0, .0001) 100%);
  filter: progid:DXImageTransform.Microsoft.gradient(startColorstr='#80000000', endColorstr='#00000000', GradientType=1);
  background-repeat: repeat-x;
}
.carousel-control.right {
  right: 0;
  left: auto;
  background-image: -webkit-linear-gradient(left, color-stop(rgba(0, 0, 0, .0001) 0%), color-stop(rgba(0, 0, 0, .5) 100%));
  background-image:         linear-gradient(to right, rgba(0, 0, 0, .0001) 0%, rgba(0, 0, 0, .5) 100%);
  filter: progid:DXImageTransform.Microsoft.gradient(startColorstr='#00000000', endColorstr='#80000000', GradientType=1);
  background-repeat: repeat-x;
}
.carousel-control:hover,
.carousel-control:focus {
  color: #fff;
  text-decoration: none;
  filter: alpha(opacity=90);
  outline: none;
  opacity: .9;
}
.carousel-control .icon-prev,
.carousel-control .icon-next,
.carousel-control .glyphicon-chevron-left,
.carousel-control .glyphicon-chevron-right {
  position: absolute;
  top: 50%;
  z-index: 5;
  display: inline-block;
}
.carousel-control .icon-prev,
.carousel-control .glyphicon-chevron-left {
  left: 50%;
}
.carousel-control .icon-next,
.carousel-control .glyphicon-chevron-right {
  right: 50%;
}
.carousel-control .icon-prev,
.carousel-control .icon-next {
  width: 20px;
  height: 20px;
  margin-top: -10px;
  margin-left: -10px;
  font-family: serif;
}
.carousel-control .icon-prev:before {
  content: '\2039';
}
.carousel-control .icon-next:before {
  content: '\203a';
}
.carousel-indicators {
  position: absolute;
  bottom: 10px;
  left: 50%;
  z-index: 15;
  width: 60%;
  padding-left: 0;
  margin-left: -30%;
  text-align: center;
  list-style: none;
}
.carousel-indicators li {
  display: inline-block;
  width: 10px;
  height: 10px;
  margin: 1px;
  text-indent: -999px;
  cursor: pointer;
  background-color: #000 \9;
  background-color: rgba(0, 0, 0, 0);
  border: 1px solid #fff;
  border-radius: 10px;
}
.carousel-indicators .active {
  width: 12px;
  height: 12px;
  margin: 0;
  background-color: #fff;
}
.carousel-caption {
  position: absolute;
  right: 15%;
  bottom: 20px;
  left: 15%;
  z-index: 10;
  padding-top: 20px;
  padding-bottom: 20px;
  color: #fff;
  text-align: center;
  text-shadow: 0 1px 2px rgba(0, 0, 0, .6);
}
.carousel-caption .btn {
  text-shadow: none;
}
@media screen and (min-width: 768px) {
  .carousel-control .glyphicon-chevron-left,
  .carousel-control .glyphicon-chevron-right,
  .carousel-control .icon-prev,
  .carousel-control .icon-next {
    width: 30px;
    height: 30px;
    margin-top: -15px;
    margin-left: -15px;
    font-size: 30px;
  }
  .carousel-caption {
    right: 20%;
    left: 20%;
    padding-bottom: 30px;
  }
  .carousel-indicators {
    bottom: 20px;
  }
}
.red-hat-content .clearfix:before,
.red-hat-content .clearfix:after,
.red-hat-content .container:before,
.red-hat-content .container:after,
.red-hat-content .container-fluid:before,
.red-hat-content .container-fluid:after,
.red-hat-content .row:before,
.red-hat-content .row:after,
.red-hat-content .form-horizontal .form-group:before,
.red-hat-content .form-horizontal .form-group:after,
.red-hat-content .btn-toolbar:before,
.red-hat-content .btn-toolbar:after,
.red-hat-content .btn-group-vertical > .btn-group:before,
.red-hat-content .btn-group-vertical > .btn-group:after,
.red-hat-content .nav:before,
.red-hat-content .nav:after,
.red-hat-content .navbar:before,
.red-hat-content .navbar:after,
.red-hat-content .navbar-header:before,
.red-hat-content .navbar-header:after,
.red-hat-content .navbar-collapse:before,
.red-hat-content .navbar-collapse:after,
.red-hat-content .pager:before,
.red-hat-content .pager:after,
.red-hat-content .panel-body:before,
.red-hat-content .panel-body:after,
.red-hat-content .modal-footer:before,
.red-hat-content .modal-footer:after {
  display: table;
  content: " ";
}
.red-hat-content .clearfix:after,
.red-hat-content .container:after,
.red-hat-content .container-fluid:after,
.red-hat-content .row:after,
.red-hat-content .form-horizontal .form-group:after,
.red-hat-content .btn-toolbar:after,
.red-hat-content .btn-group-vertical > .btn-group:after,
.red-hat-content .nav:after,
.red-hat-content .navbar:after,
.red-hat-content .navbar-header:after,
.red-hat-content .navbar-collapse:after,
.red-hat-content .pager:after,
.red-hat-content .panel-body:after,
.red-hat-content .modal-footer:after {
  clear: both;
}
.red-hat-content .center-block {
  display: block;
  margin-right: auto;
  margin-left: auto;
}
.red-hat-content .pull-right {
  float: right !important;
}
.red-hat-content .pull-left {
  float: left !important;
}
.red-hat-content .hide {
  display: none !important;
}
.red-hat-content .show {
  display: block !important;
}
.red-hat-content .invisible {
  visibility: hidden;
}
.red-hat-content .text-hide {
  font: 0/0 a;
  color: transparent;
  text-shadow: none;
  background-color: transparent;
  border: 0;
}
.red-hat-content .hidden {
  display: none !important;
  visibility: hidden !important;
}
.red-hat-content .affix {
  position: fixed;
}
@-ms-viewport {
  width: device-width;
}
.red-hat-content .visible-xs,
.red-hat-content .visible-sm,
.red-hat-content .visible-md,
.red-hat-content .visible-lg {
  display: none !important;
}
@media (max-width: 767px) {
  .red-hat-content .visible-xs {
    display: block !important;
  }
  .red-hat-content table.visible-xs {
    display: table;
  }
  .red-hat-content tr.visible-xs {
    display: table-row !important;
  }
  .red-hat-content th.visible-xs,
  .red-hat-content td.visible-xs {
    display: table-cell !important;
  }
}
@media (min-width: 768px) and (max-width: 991px) {
  .red-hat-content .visible-sm {
    display: block !important;
  }
  .red-hat-content table.visible-sm {
    display: table;
  }
  .red-hat-content tr.visible-sm {
    display: table-row !important;
  }
  .red-hat-content th.visible-sm,
  .red-hat-content td.visible-sm {
    display: table-cell !important;
  }
}
@media (min-width: 992px) and (max-width: 1199px) {
  .red-hat-content .visible-md {
    display: block !important;
  }
  .red-hat-content table.visible-md {
    display: table;
  }
  .red-hat-content tr.visible-md {
    display: table-row !important;
  }
  .red-hat-content th.visible-md,
  .red-hat-content td.visible-md {
    display: table-cell !important;
  }
}
@media (min-width: 1200px) {
  .red-hat-content .visible-lg {
    display: block !important;
  }
  .red-hat-content table.visible-lg {
    display: table;
  }
  .red-hat-content tr.visible-lg {
    display: table-row !important;
  }
  .red-hat-content th.visible-lg,
  .red-hat-content td.visible-lg {
    display: table-cell !important;
  }
}
@media (max-width: 767px) {
  .red-hat-content .hidden-xs {
    display: none !important;
  }
}
@media (min-width: 768px) and (max-width: 991px) {
  .red-hat-content .hidden-sm {
    display: none !important;
  }
}
@media (min-width: 992px) and (max-width: 1199px) {
  .red-hat-content .hidden-md {
    display: none !important;
  }
}
@media (min-width: 1200px) {
  .red-hat-content .hidden-lg {
    display: none !important;
  }
}
.red-hat-content .visible-print {
  display: none !important;
}
@media print {
  .red-hat-content .visible-print {
    display: block !important;
  }
  .red-hat-content table.visible-print {
    display: table;
  }
  .red-hat-content tr.visible-print {
    display: table-row !important;
  }
  .red-hat-content th.visible-print,
  .red-hat-content td.visible-print {
    display: table-cell !important;
  }
}
@media print {
  .red-hat-content .hidden-print {
    display: none !important;
  }
}
/*# sourceMappingURL=bootstrap.css.map */
