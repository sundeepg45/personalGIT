public with sharing class PartnerPointsCatalogLMSItem {
	public String	ppLMSId {get; set; }
	public String	courseId {get; set; }
	public String	title {get; set; }
	public Integer	points {get; set; }
	public Boolean	isActive {get; set; }
	public String   language {get; set; }
	public Boolean	isExam {get; set; }
	public String	trackId {get; set; }
	public String	subcategory {get; set; }
	public Boolean	isWebinar {get; set; }
    public ID		catalogId {get; set; }
}