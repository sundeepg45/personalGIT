trigger Classification_SetDefaultReferenceKey on Classification__c (before insert, before update) {
    for(Classification__c classification : Trigger.new) {
        String referenceKey = null;

    	if (classification.ReferenceKey__c == null) {
    		referenceKey = classification.Name;
	    	referenceKey = referenceKey.replaceAll('[^a-zA-Z0-9 ]', '');
	        referenceKey = referenceKey.replaceAll(' ', '_');
    	} else {
            referenceKey = classification.ReferenceKey__c;
    	}

        referenceKey = referenceKey.toUpperCase();
        
        // Validation
        if (Pattern.matches('[^a-zA-Z0-9 ]', referenceKey)) {
            classification.addError('The Reference Key can only contain alphanumeric (A-Z, 0-9) characters and/or the underscore (_) character.');
        } else {
            classification.ReferenceKey__c = referenceKey;
        }
    }
}