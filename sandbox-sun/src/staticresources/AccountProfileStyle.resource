a.anchor:link {text-decoration:none; }
a.anchor:visited {text-decoration:none; }
a.anchor:hover {text-decoration:none; }
a.anchor:active {text-decoration:none; }
@page {
	@bottom-right {
		content: "Page " counter(page);
	}
}
@media print {
	.hideforprint {
		display: none;
	}
	a.anchor { page-break-before:auto; page-break-inside:avoid; }
	div.anchor { page-break-before:auto; page-break-inside:avoid; }
	input { display: none; }
}

