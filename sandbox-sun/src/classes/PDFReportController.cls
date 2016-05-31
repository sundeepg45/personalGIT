/**
 * PDFReportController.cls
 *
 * @version 2014-01-30
 * @author Scott Coleman <scoleman@redhat.com>
 * 2014-01-30 - Created
 */
public with sharing class PDFReportController {
	/** Name of a custom setting key. */
	public static final String REPORT_IMAGE_FOLDER_ID_KEY = 'ReportImageFolderId';

	public PDFReportController() {}

	// should be set by the page - this is the URL for the redirect target page that renders a pdf
	public String pdfPage {
		get;
		set;
	}
	
	// should be set by page - the HTML of the report
	public String innerHTML { 
		get;
		set;
	}

	public Event event {
		get {
			if(event == null) {
				event = new Event(ActivityDateTime=System.now());
			}
			return event;
		}
		set;
	}

	// modify the HTML of the report so the PDF generator can handle it and then redirect to the pdfPage
	public PageReference openPDF() {
		// get the report image from the HTML
		Blob reportImage = getReportImage();
		
		// store it as a document
		Id documentId = null;
		if(reportImage != null) {
			documentId = storeReportImage(reportImage);
		}

		// replace the inline image data with the URL of the stored document.
		// we're doing this becase the PDF generator does not handle inline image data.
		if(documentId != null) {
			replaceReportImageWithDocURL('/servlet/servlet.FileDownload?file=' + documentId);
		}

		return new PageReference(pdfPage);
	}

	// returns the value of the src attribute on the img tag containing the report chart
	@TestVisible
	private String reportImgSrc {
		get {
			if(reportImgSrc == null && innerHTML != null) {
				// build an xml document containing all the img elements found in innerHTML
				Integer imgBegin = 0;
				Integer imgEnd = 0;
				String imgs = '<imgs>';

				while(imgBegin != -1) {
					imgBegin = innerHTML.indexOfIgnoreCase('<img', imgEnd);
					
					if(imgBegin > 0) {
						imgEnd = innerHTML.indexOf('>', imgBegin);
					}
					
					if(imgBegin > 0 && imgEnd > 0) {
						imgs = imgs + innerHTML.substring(imgBegin, imgEnd+1);
					}
				}
				imgs = imgs + '</imgs>';

				// create a reader and iterate through the images looking for one with inline image data
				XmlStreamReader reader = new XmlStreamReader(imgs);
				String imgSrc;

				while(reader.hasNext()) {
					if(reader.getEventType() == XmlTag.START_ELEMENT) {
						if(reader.getLocalName() == 'img') {
							imgSrc = reader.getAttributeValue(null, 'src');
							if(imgSrc != null && imgSrc.contains('data:image') && imgSrc.contains('base64')) {
								break;
							}
						}
					}
					reader.next();
				}
						
				if(imgSrc != null) {
					reportImgSrc = imgSrc;
				}
			}
			return reportImgSrc;
		}
		set;
	}

	// returns the mime type of the report image
	@TestVisible
	private String reportImgMimeType {
		get {
			if(reportImgMimeType == null && reportImgSrc != null) {
				Integer typeBegin = reportImgSrc.indexOf(':');
				Integer typeEnd = reportImgSrc.indexOf(';');

				if(typeBegin > 0 && typeEnd > typeBegin) {
					reportImgMimeType = reportImgSrc.substring(typeBegin+1, typeEnd);
				}
			}
			return reportImgMimeType;
		}
		set;
	}

	// get the report image and return it as a blob
	@TestVisible
	private Blob getReportImage() {
		Blob image = null;
	
		// convert the base64 image data to blob
		if(innerHTML != null && reportImgSrc != null) {
			Integer base64ImageStart = reportImgSrc.indexOf(',');

			if(base64ImageStart > 0) {
				String base64Image = reportImgSrc.substring(base64ImageStart+1);
			
				if(base64Image != null) {
					image = EncodingUtil.base64Decode(base64Image);
				}
			}
		}
		return image;
	}

	// store the report image base64 string as a Document and return the id
	@TestVisible
	private Id storeReportImage(Blob reportImage) {
		// get document folder id
		Id reportImageFolderId = null;
		StringSetting__c folderSetting = StringSetting__c.getInstance(REPORT_IMAGE_FOLDER_ID_KEY);

		if(folderSetting != null) {
			reportImageFolderId = folderSetting.Value__c;
		}

		// store the image as a document
		Id reportImageDocId = null;
		DateTime n = Datetime.now();
		String nameBase = 'Image_' + UserInfo.getUserId()+'_';
		String name = nameBase+(n.minute()*60+n.second());
		String mimeType = reportImgMimeType;
		String type = mimeType.substring(mimeType.indexOf('/')+1);

		if(reportImageFolderId != null) {
			Document reportImageDoc = new Document(
				Body = reportImage,
				ContentType = mimeType,
				Description = 'Report Image',
				DeveloperName = name,
				FolderId = reportImageFolderId,
				Name = name,
				Type = type);

			Database.delete([
				select Id 
				from Document
				where DeveloperName like :(nameBase+'%') 
					and FolderId = :reportImageFolderId 
					and LastModifiedDate < :n.addMinutes(-10)],false);
			Database.SaveResult result = Database.insert(reportImageDoc,false);
			if(result.isSuccess()) {
				reportImageDocId = reportImageDoc.Id;
			}
		}
		return reportImageDocId;
	}

	// replace the value of the src attribute on the report img tag with the document URL
	@TestVisible
	private void replaceReportImageWithDocURL(String imageURL) {

		if(innerHTML != null && reportImgSrc != null) {
			innerHTML = innerHTML.replace(reportImgSrc, imageURL);
		}
	}
}