public abstract with sharing class KalturaMediaBase {
    public String  accessControlId {get; private set;}     // The Access Control ID assigned to this entry (null when not set, send -1 to remove) 
    public String  adminTags {get; private set; }          // Entry admin tags can be updated only by administrators
    public String  categories {get; private set; }   
    public String  categoriesIds {get; private set; }   
    public DateTime created {get; private set; }
    public String  description {get; set; }
    public String  downloadUrl {get; set; }
    public String  endDate {get; set; }                    //  Entry scheduling end date (null when not set, send -1 to remove)
    public String  groupId {get; set; }   
    public String  id {get; set;}
    public String  name {get; set; }
    public double  rank {get; private set; }               //  Calculated rank
    public String  startDate {get; set;}                   //  Entry scheduling start date (null when not set, send -1 to remove)
    public String  status {get; set; }      
    public String  tags {get; set; }
    public String  thumbnailUrl {get; set; }
    public integer totalRank {get; private set; }          // The total (sum) of all votes
    public integer votes {get; private set; }              // Number of votes
    
    public KalturaMediaBase() {
    }

    public KalturaMediaBase(Dom.XmlNode entry) {
    	accessControlId = text(entry, 'accessControlId');
    	adminTags =    text(entry, 'adminTags');
    	categories =   text(entry, 'categories');
    	categoriesIds =text(entry, 'categoriesIds');
    	created =      DateTime.newinstance(Long.valueOf(text(entry, 'createdAt')) * 1000);
    	description =  text(entry, 'description');
    	downloadUrl =  text(entry, 'downloadUrl');
    	endDate =      text(entry, 'endDate');
    	groupId =      text(entry, 'groupId');
    	id =           text(entry, 'id');
    	name =         text(entry, 'name');
    	Dom.XmlNode rankNode = entry.getChildElement('rank', null);
    	if (rankNode != null) {
    	   rank = Decimal.valueOf(rankNode.getText());
    	}
    	startDate =    text(entry, 'startDate');
    	status =       text(entry, 'status');
    	tags =         text(entry, 'tags');
    	thumbnailUrl = text(entry, 'thumbnailUrl');
    	Dom.XmlNode totalRankNode = entry.getChildElement('totalRank', null);
    	if (totalRankNode != null) {
    	   totalRank = Integer.valueOf(totalRankNode.getText());
    	}
    	Dom.XmlNode votesNode = entry.getChildElement('votes', null);
    	if (votesNode != null) {
            votes = Integer.valueOf(votesNode.getText());
    	}
    }

    protected String text(Dom.XmlNode parent, String childName) {
        Dom.XmlNode n = parent.getChildElement(childName, null);
        if (n != null) {
        	return n.getText();
        }
        return null;
    }
}