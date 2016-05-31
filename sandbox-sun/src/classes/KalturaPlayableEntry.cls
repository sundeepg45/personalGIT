public abstract with sharing class KalturaPlayableEntry extends KalturaMediaBase {
    public String  duration {get; private set;}        // The duration in seconds
    public String  durationType {get; private set; }   // The duration type (short for 0-4 mins, medium for 4-20 mins, long for 20+ mins)
    public String  msDuration {get; private set; }     // The duration in miliseconds
    public String  plays {get; private set; }          // Number of plays
    public String  views {get; private set; }          // Number of views
    public String  height {get; private set; }         // The height in pixels
    public String  width {get; private set;}           // The width in pixels
    
    public KalturaPlayableEntry(Dom.XmlNode entry) {
    	super(entry);
        duration = text(entry, 'duration');
        durationType = text(entry, 'durationType');
        msDuration = text(entry, 'msDuration');
        plays = text(entry, 'plays');
        views = text(entry, 'views');
        height = text(entry, 'height');
        width = text(entry, 'width');
    }
    
    public KalturaPlayableEntry() {
    	super();
    }
}