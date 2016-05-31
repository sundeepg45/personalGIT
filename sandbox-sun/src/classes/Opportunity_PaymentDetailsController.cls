/**
 * Controller extension for custom credit card capture page. Includes Cybersource integration.
 *
 * @version 2015-10-22
 * @author Scott Coleman <scoleman@redhat.com> 
 * 2015-07-27 - Created
 * 2015-07-31 - Moved keys to config and updated for testability
 * Bill C Riemers
 * 2015-10-22 - Added methods to redirect to the correct page, clearAndSave, and isTokenRequired check
 */
public without sharing class Opportunity_PaymentDetailsController {
    /** 
     * Regular expression list of operating units which should be tokenized.  If the 
     * list is not empty, then everything not in the list will not be tokenized.
     */
    public static final String TOKEN_PREFERRED_SETTING = 'Opp.CCTokenPreferred';
    /** 
     * Regular expression list of operating units which should not be tokenized.  Any 
     * operating unit in the list will not be tokenized, even if it is also in the
     * TOKEN_PREFERRED_SETTING list.
     */
    public static final String TOKEN_DISALLOWED_SETTING = 'Opp.CCTokenDisallowed';

	private String operatingUnit = null;

    public Integer pageNumber {get; set;}
    public String formAction {get; private set;}

    public Long timeStamp {
        get {
            if(timeStamp == null) {
                timeStamp = DateTime.now().getTime();
            }
            return timeStamp;
            //return 1437769866013L;
        }
        private set;
    }

    public String uuid {
        get {
            if(uuid == null) {
                uuid = CybersourceSecurity.newGuid();
            }
            return uuid;
            //return 'd1a7e30b-0796-4e27-92a0-58a942baa478';
        }
        private set;
    }

    public String now {
        get {
            if(now == null) {
                now = Datetime.now().format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'','GMT');
            }
            return now;
            //return '2015-07-24T20:31:06Z';
        }
        private set;
    }

    public Map<String,String> signedFields { 
        get {
            if(signedFields == null) {
                signedFields = new Map<String,String>();
            }
            return signedFields;
        }
        private set;
    }

    public Map<String,String> responseFields { 
        get {
            if(responseFields == null) {
                responseFields = new Map<String,String>();
            }
            return responseFields;
        }
        private set;
    }

    public Map<String,Cybersource_Config__c> cybersourceConfig {
        get {
            if(cybersourceConfig == null) {
                cybersourceConfig = Cybersource_Config__c.getAll();
            }
            return cybersourceConfig;
        }
        private set;
    }

    public List<Country__c> countries {
        get {
            if(countries == null) {
                countries = [
                    SELECT 
                        Id,
                        Name,
                        Iso3166Alpha2__c,
                        (SELECT
                            Id,
                            Abbreviation__c,
                            Name
                        FROM States__r
                        ORDER BY 
                            Country__r.Name, 
                            Name)
                    FROM Country__c 
                    WHERE Iso3166Alpha2__c != null 
                    ORDER BY Name
                ];
            }
            return countries;
        }
        private set;
    }

    public List<String> creditCardTypeCodes {
        get {
            if(creditCardTypeCodes == null) {
                creditCardTypeCodes = new List<String>(creditCardTypes.keySet());
                creditCardTypeCodes.sort();
            }
            return creditCardTypeCodes;
        }
        private set;
    }

    public Map<String,String> creditCardTypes {
        get {
            if(creditCardTypes == null) {
                creditCardTypes = new Map<String,String>{'001'=>'Visa', '002'=>'Mastercard', '003'=>'American Express'};
            }
            return creditCardTypes;
        }
        private set;
    }

    public List<String> expiryDateMonthCodes {
        get {
            if(expiryDateMonthCodes == null) {
                expiryDateMonthCodes = new List<String>(expiryDateMonths.keySet());
                expiryDateMonthCodes.sort();
            }
            return expiryDateMonthCodes;
        }
        private set;
    }

    public Map<String,String> expiryDateMonths {
        get {
            if(expiryDateMonths == null) {
                expiryDateMonths = new Map<String,String>{
                    '01'=>'January (01)',
                    '02'=>'February (02)',
                    '03'=>'March (03)',
                    '04'=>'April (04)',
                    '05'=>'May (05)',
                    '06'=>'June (06)',
                    '07'=>'July (07)',
                    '08'=>'August (08)',
                    '09'=>'September (09)',
                    '10'=>'October (10)',
                    '11'=>'November (11)',
                    '12'=>'December (12)'
                };
            }
            return expiryDateMonths;
        }
        private set;
    }

    public List<String> expiryDateYears {
        get{
            if(expiryDateYears == null) {
                Integer currentYear = Date.today().year();

                if(Date.today().dayOfYear() == 1) {
                    currentYear = currentYear - 1;
                }

                expiryDateYears = new List<String>();

                for(Integer i = 0; i <= 10; i++) {
                    expiryDateYears.add(String.valueOf(currentYear + i));
                }
            }
            return expiryDateYears;
        }
        private set;
    }

    public String signature {get; private set;}
    public String decision {get; private set;}
    public String message {get; private set;}

    private ApexPages.StandardController controller;

    public Opportunity opp {
        get {
           if(opp == null) {
               opp = (Opportunity)controller.getRecord();
               operatingUnit = opp.Operating_Unit__c;
           }
           return opp;
        }
        private set;
    }

    public Opportunity_PaymentDetailsController(ApexPages.StandardController controller) {
        this.controller = controller;
        if(!Test.isRunningTest()) {
            controller.addFields(new List<String>{
                'Credit_Card_First_Name__c',
                'Credit_Card_Last_Name__c',
                'Credit_Card_Email__c',
                'Credit_Card_Phone__c',
                'Credit_Card_Address__c',
                'Credit_Card_City__c',
                'Credit_Card_State__c',
                'Credit_Card_Country__c',
                'Credit_Card_Zip__c',
                'Credit_Card_Reference_Number__c',
                'Credit_Card_Transaction_UUID__c',
                'Credit_Card_Type__c',
                'Credit_Card_Expiration__c',
                'Credit_Card_Token__c',
                'Desired_Operating_Unit__c',
                'Operating_Unit__c',
                'NameOnCard__c',
                'CreditCardType__c',
                'Credit_Card_Number__c',
                'ExpirationDate__c',
                'CC_SpecialInstructions__c'
            });
        }

        Map<String, String> params = ApexPages.CurrentPage().getParameters();

        // postback from Cybersource
        if(params.containsKey('req_reference_number')) {
            ApexPages.currentPage().getParameters().put('id', params.get('req_reference_number')); 
            processCardDetails();
            pageNumber = 3;
            formAction = '';
        }
        // post from cardholder details form
        else if(params.containsKey('reference_number')) {
            processCardholderDetails();
            pageNumber = 2;
            formAction = cybersourceConfig.get('TokenCreationURL').Value__c; //https://testsecureacceptance.cybersource.com/silent/token/create';
        }
        // initial load of the page
        else {
            pageNumber = 1;
            formAction = '/apex/Opportunity_PaymentDetails?id=' + params.get('id');
        }
    }

    public PageReference saveOpp() {
        if(opp != null && (pageNumber == 2 || pageNumber == 3)) {
            opp.Operating_Unit__c = operatingUnit;
            Database.update(opp);
        }
        return redirect();
    }

    public static Boolean isTokenRequired(String operatingUnit) {
        Boolean retval = null;
        if(operatingUnit != null) {
            retval = true;
            operatingUnit = operatingUnit.toLowerCase();
            StringSetting__c preferred = StringSetting__c.getInstance(TOKEN_PREFERRED_SETTING);
            if(preferred != null && String.isNotBlank(preferred.Value__c) ) {
                String re = preferred.Value__c.replaceAll('\\s*[\\n,]+\\s*','|').toLowerCase();
                if(! (Pattern.matches('^('+re+')$',operatingUnit)
                    || Pattern.matches('^rh ('+re+') operating unit$',operatingUnit) ) )
                {
                    retval = false;
                }
            }
            StringSetting__c disallowed = StringSetting__c.getInstance(TOKEN_DISALLOWED_SETTING);
            if(disallowed != null && String.isNotBlank(disallowed.Value__c) ) {
                String re = disallowed.Value__c.replaceAll('\\s*[\\n,]+\\s*','|').toLowerCase();
                if(Pattern.matches('^('+re+')$',operatingUnit)
                    || Pattern.matches('^rh ('+re+') operating unit$',operatingUnit) )
                {
                    retval = false;
                }
            }
        }
        return retval;
    }

    public PageReference redirect() {
        PageReference retval = null;
        if(opp.Operating_Unit__c != null) {
            Boolean isRedirect = (''+ApexPages.currentPage()).toLowerCase().contains('redirect');
            Boolean isNoToken = (''+ApexPages.currentPage()).toLowerCase().contains('notoken');
            Boolean tokenRequired = isTokenRequired(opp.Operating_Unit__c);
//            if(tokenRequired == null) {
//                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, System.Label.Operating_Unit_Required));
//            }
            if(tokenRequired == true) {
                if(isRedirect || isNoToken) {
                    retval = Page.Opportunity_PaymentDetails;
                    retval.getParameters().putAll(ApexPages.currentPage().getParameters());
                    retval.setRedirect(true);
                    saveDesiredOperatingUnit();
                }
                else if(opp.Credit_Card_Number__c != null && opp.Credit_Card_Token__c == null) {
                   retval = clearAndSave();
               }
            }
            else if(isRedirect || ! isNoToken) {
                retval = Page.Opportunity_PaymentDetailsNoToken;
                retval.getParameters().putAll(ApexPages.currentPage().getParameters());
                retval.setRedirect(true);
                saveDesiredOperatingUnit();
            }
            else if(opp.Credit_Card_Token__c != null && tokenRequired == false) {
                retval = clearAndSave();
            }
        }
        else if(opp.Desired_Operating_Unit__c != null) {
            opp.Operating_Unit__c = opp.Desired_Operating_Unit__c;
        }
        System.debug(retval);
        return retval;
    }

    @TestVisible
    private void processCardholderDetails() {
        Map<String, String> params = ApexPages.CurrentPage().getParameters();

        List<String> signedFieldNames = params.get('signed_field_names').split(',');
        for(String signedFieldName : signedFieldNames) {
            signedFields.put(signedFieldName, params.get(signedFieldName));
        }

        signature = CybersourceSecurity.sign(signedFields, signedFieldNames);

        // Cybersource fields
        opp.Credit_Card_First_Name__c = params.get('bill_to_forename');
        opp.Credit_Card_Last_Name__c = params.get('bill_to_surname');
        opp.Credit_Card_Email__c = params.get('bill_to_email');
        opp.Credit_Card_Phone__c = params.get('bill_to_phone');
        opp.Credit_Card_Address__c = params.get('bill_to_address_line1');
        opp.Credit_Card_City__c = params.get('bill_to_address_city');
        opp.Credit_Card_State__c = params.get('bill_to_address_state');
        opp.Credit_Card_Country__c = params.get('bill_to_address_country');
        opp.Credit_Card_Zip__c = params.get('bill_to_address_postal_code');
        opp.Credit_Card_Reference_Number__c = params.get('reference_number');
        opp.Credit_Card_Transaction_UUID__c = params.get('transaction_uuid');
    }

    public PageReference clearAndSave() {
        opp.NameOnCard__c = null;
        opp.CreditCardType__c = null;
        opp.Credit_Card_Number__c = null;
        opp.CC_SpecialInstructions__c = null;
        opp.ExpirationDate__c = null;
        return saveOppNoToken();
    }

    private PageReference saveOppNoToken() {
        opp.Credit_Card_Type__c = null;
        opp.Credit_Card_Token__c = null;
        opp.Credit_Card_First_Name__c = null;
        opp.Credit_Card_Last_Name__c = null;
        opp.Credit_Card_Email__c = null;
        opp.Credit_Card_Phone__c = null;
        opp.Credit_Card_Address__c = null;
        opp.Credit_Card_City__c = null;
        opp.Credit_Card_State__c = null;
        opp.Credit_Card_Country__c = null;
        opp.Credit_Card_Zip__c = null;
        opp.Credit_Card_Reference_Number__c = null;
        opp.Credit_Card_Transaction_UUID__c = null;
        return saveNoToken();
    }

	private void saveDesiredOperatingUnit() {
		if(operatingUnit == null && opp.Operating_Unit__c != null && opp.Desired_Operating_Unit__c != opp.Operating_Unit__c) {
			saveNoToken();
		}
	}

	public PageReference saveNoToken() {
		try {
			if(opp != null) {
				if(opp.Operating_Unit__c != null) {
					opp.Desired_Operating_Unit__c = opp.Operating_Unit__c;
				}
				if(opp.Operating_Unit__c != operatingUnit) {
					opp.Operating_Unit__c = operatingUnit;
				}
				update opp;
			}
		}
		catch(Exception e) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,e.getMessage()));
		}
		return null;
	}

    @TestVisible
    private void processCardDetails() {
        Map<String, String> params = ApexPages.CurrentPage().getParameters();

        responseFields = params;

        decision = params.get('decision');

        if(params.containskey('message')) {
            message = params.get('message');

            if(params.containskey('invalid_fields')) {
                message = message + '. Invalid fields: ' + replaceFieldLabels(params.get('invalid_fields'));
            }

            if(params.containskey('required_fields')) {
                message = message + '. Required fields: ' + replaceFieldLabels(params.get('required_fields'));
            }
        }

        if(decision == 'ACCEPT') {
            // Cybersource fields
            opp.Credit_Card_Type__c = params.get('req_card_type');
            opp.Credit_Card_Expiration__c = params.get('req_card_expiry_date');
            opp.Credit_Card_Token__c = params.get('payment_token');

            // Legacy fields
            opp.NameOnCard__c = params.get('req_bill_to_forename') + ' ' + params.get('req_bill_to_surname');
            opp.CreditCardType__c = creditCardTypes.get(opp.Credit_Card_Type__c);
            opp.Credit_Card_Number__c = opp.Credit_Card_Token__c;
            opp.CC_SpecialInstructions__c = 'Captured in Cybersource';

            String[] expiryDateParts = opp.Credit_Card_Expiration__c.split('-');
            Integer month = Integer.valueOf(expiryDateParts[0]);
            Integer year = Integer.valueOf(expiryDateParts[1]);
            Integer day = Date.daysInMonth(year, month);
            opp.ExpirationDate__c = Date.newInstance(year, month, day);
        }
        else {
            // Cybersource fields
            opp.Credit_Card_Type__c = null;
            opp.Credit_Card_Expiration__c = null;
            opp.Credit_Card_Token__c = null;

            // Legacy fields
            opp.NameOnCard__c = null;
            opp.CreditCardType__c = null;
            opp.Credit_Card_Number__c = null;
            opp.CC_SpecialInstructions__c = null;
            opp.ExpirationDate__c = null;
        }
    }

    @TestVisible
    private static String replaceFieldLabels(String cybersourceFieldNames) {
        Map<String,String> fieldLabelMap = new Map<String,String>{
            'bill_to_forename'=>Label.CC_First_Name,
            'bill_to_surname'=>Label.CC_Last_Name,
            'bill_to_email'=>Label.CC_Email,
            'bill_to_phone'=>Label.CC_Phone,
            'bill_to_address_line1'=>Label.CC_Address,
            'bill_to_address_city'=>Label.CC_City,
            'bill_to_address_state'=>Label.CC_State_Province,
            'bill_to_address_country'=>Label.CC_Country,
            'bill_to_address_postal_code'=>Label.CC_Zip_Postal_Code,
            'card_type'=>Label.CC_Type,
            'card_number'=>Label.CC_Number,
            'card_expiry_date'=>Label.CC_Expiration_Date
        };

        String[] fieldNames = cybersourceFieldNames.split(',');
        String salesforceFieldNames = '';
        
        for(Integer i=0; i<fieldNames.size(); i++) {
            if(fieldLabelMap.containsKey(fieldNames[i])) {
                fieldNames[i] = fieldLabelMap.get(fieldNames[i]);
            }
            if(salesforceFieldNames == '') {
                salesforceFieldNames = fieldNames[i];
            }
            else {
                salesforceFieldNames = salesforceFieldNames + ', ' + fieldNames[i];
            }
        }
        
        return salesforceFieldNames;
    }
}