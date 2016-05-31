trigger PartnerProduct_UpdateKeywords on PartnerProduct__c (before insert, before update) {

	for (PartnerProduct__c prod : Trigger.new) {
		String buf = '';

		if (prod.Software_Category__c != null) {
			buf += ';' + prod.Software_Category__c;
		}

		if (prod.Platforms__c != null) {
			buf += ';' + prod.Platforms__c;
		}

		if (prod.Industry_Focus__c != null) {
			buf += ';' + prod.Industry_Focus__c;
		}

		if (prod.JBoss_Platform__c != null) {
			buf += ';' + prod.JBoss_Platform__c;
		}

		if (buf.length() > 255) {
			buf = buf.substring(0, 254);
		}

		prod.Internal_Keywords__c = buf;
	}
}