/**
 * PDFReportControllerTest.cls
 *
 * @version 2014-01-30
 * @author Scott Coleman <scoleman@redhat.com>
 * 2014-01-30 - Created
 */
@isTest
private class PDFReportControllerTest {

	public static String pdfPage = '/apex/PDFTest';
	public static String base64image = 'iVBORw0KGgoAAAANSUhEUgAAABoAAAAaCAYAAACpSkzOAAADRElEQVRIia2Vv48bRRTHv292Z/' + 
		'zzfLbPnI6j4Q5FDkIiFEZIFEj8CEhIoYiupkK0KBRAQUNNQZOCfwHSWUmTAihBMg2iIFIE0gEruPAj5/' + 
		'XGO7sz71HY51zsOF6Le9Xq7e73M+87780QCkS4p5XZ1wogFhFwwoAXCMDZwBaRQFjkI72n65WLtQYAljHD/' + 
		'eX4FOjozEAQbJOifUCYGZBJlqdvvzo7kEIHAc5Pn6cAAiB8piDS1KYynYMDiMAkMl/' + 
		'V2YCCStDUm+ZJn+TslQdoVk3hKAaqhnXdMjvCDCgPkfUghUGkVTWsBZ08CQAlmO4P8H+sq7xSfdNsmRfCeggK1STXq' +
		'76IkLZVQAAIRLPOQ6lX+mRO4o4d2KsLi51P6D2ttj7YvtZ8rnlZNzRAQJ46ZMcW9k6K9HaK7PcM8DIVeEDih6Q/' + 
		'uuQjfzivG8wn+C7L6Eb8JT2ubLgTvuYdwyU58jiDu+fBxw4cMyA0D/' + 
		'om6Y9e8pH/' + 
		'Z17zoaD7pWGAJv7l3L/' + 
		'hrQenDHjAxwweepCcWEIAcNNF7iAb2GSZ3FJQ/' + 
		'kvuslv2OwnkW7WhLlNIGgLw0MPHHpAZ5HM7SN9Ovx4vhTy6IkxstN+ntyWV63pfX1IhNXjEMxCAD5P+6OP8Vu4epbMSdKq6P7Of7BfmQvlVGfMOj5gheD/' + 
		'pjz7zkV97plaG3tem9VH7WvWt2rvBbqDW+bfYoXo/' + 
		'HAifgnCENYYVKGgdAOindLl1Zet5sDQBdEzXOBe5uxLLyn8Lg6oXa/' + 
		'XmO61ng42gxDE7P/' + 
		'QOQNN0DbvIxRLLStpKUOu9dqP2cr0b1AIQUe6Pfe6H3gNwADZM1wQucsNVsIUj6CQaB021ebDZRoBdUQBnHvCA/' + 
		'dUiO7SKhCCQk1ka2kF6aAd2aZsvbYZar9asPFFpQ1Pq7uXIYoFLPGS6cAFOd50p9cq7LnK/' + 
		'LWv3BetKT5fx2JXtTvv1rZpplVxQDh2FyoHFcSbO/' + 
		'+1O9igH4AnkMLGRTNdUXOTGEi/' + 
		'eVwsVmXO6nP44To9+/' + 
		'iOlcHIfVHpVY54phaQmdp0OO0jTBwR3w7KP/' + 
		'GglKO7H6XyulXdMu2uMeAFkHmQXRB8WhQZWcnYu8czp7HpY61QAgP8A9Y+ezPROtxMAAAAASUVORK5CYII=';
	public static String type = 'png';
	public static String mimeType = 'image/' + type;
	public static String imgSrc = 'data:' + mimeType + ';base64,' + base64image;
	public static String innerHTML = '<html><body><img src="' + imgSrc + '" /></body></html>';
	public static String documentURL = '/servlet/servlet.FileDownload?file=015g0000000BTIG';
	public static String modifiedInnerHTML = '<html><body><img src="' + documentURL + '" /></body></html>';

	@isTest 
	static void reportImgSrcTest() {
		PDFReportController controller = new PDFReportController();
		controller.innerHTML = innerHTML;
		System.assertEquals(innerHTML.length(), controller.innerHTML.length());
		System.assertEquals(innerHTML, controller.innerHTML);
		System.assertEquals(imgSrc.length(), controller.reportImgSrc.length());
		System.assertEquals(imgSrc, controller.reportImgSrc);
	}

	@isTest
	static void reportImgMimeTypeTest() {
		PDFReportController controller = new PDFReportController();
		controller.innerHTML = innerHTML;
		System.assertEquals(mimeType, controller.reportImgMimeType);
	}	

	@isTest
	static void getReportImageTest() {
		PDFReportController controller = new PDFReportController();
		controller.innerHTML = innerHTML;
		Blob reportImage = controller.getReportImage();
		System.assertNotEquals(null, reportImage);
		System.assertEquals(base64image, EncodingUtil.base64Encode(reportImage));
	}

	@isTest
	static void storeReportImageTest() {
		StringSetting__c folderSetting = new StringSetting__c(
				Name = PDFReportController.REPORT_IMAGE_FOLDER_ID_KEY, 
				Value__c = UserInfo.getUserId());
		insert folderSetting;
		PDFReportController controller = new PDFReportController();
		controller.innerHTML = innerHTML;
		Blob reportImage = controller.getReportImage();
		Id documentId = controller.storeReportImage(reportImage);
		System.assertNotEquals(null, documentId);
		Document doc = [SELECT ContentType, DeveloperName, Type FROM Document WHERE Id = :documentId LIMIT 1];
		System.assertNotEquals(null, doc);
		System.assertEquals(mimeType, doc.ContentType);
		System.assertEquals(type, doc.Type);
		System.assert(doc.DeveloperName.length() > 0);
	}

	@isTest 
	static void replaceReportImageWithDocURLTest() {
		PDFReportController controller = new PDFReportController();
		controller.innerHTML = innerHTML;
		controller.replaceReportImageWithDocURL(documentURL);
		System.assertEquals(modifiedInnerHTML.length(), controller.innerHTML.length());
		System.assertEquals(modifiedInnerHTML, controller.innerHTML);
	}	
}