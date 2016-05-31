/**
 * Test class for Opportunity_PaymentDetailsController class
 *
 * @version 2015-10-23
 * @author Scott Coleman <scoleman@redhat.com>
 * 2015-07-31 - Created
 * Bill Riemers <briemers@redhat.com>
 * 2015-10-23 - Added test a method for redirect method
 */
@isTest
private class Opportunity_PaymentDetailsControllerTest {

    private static void initConfig() {
        List<Cybersource_Config__c> cybersourceConfig = new List<Cybersource_Config__c>{
            new Cybersource_Config__c(Name='SecretKey', Value__c='12345'),
            new Cybersource_Config__c(Name='TokenCreationURL', Value__c='https://www.example.com'),
            new Cybersource_Config__c(Name='AccessKey', Value__c='67890'),
            new Cybersource_Config__c(Name='ProfileId', Value__c='ABCDE')
        };
        insert cybersourceConfig;       
    }

    static Account acc {
        get {
            if(acc == null) {
                acc = new Account(Name='Testing');
                insert acc;
            }
            return acc;
        }
    }

    static Opportunity opp {
        get {
            if(opp == null) {
                opp = new Opportunity(
                    Name='Testing',
                    AccountId=acc.Id,
                    FulfillmentChannel__c = 'Direct End Customer',
                    Country_of_Order__c = 'United States',
                    CurrencyIsoCode = 'USD',
                    Pay_Now__c = 'Yes',
                    CloseDate=System.today(),
                    OpportunityType__c='Standard',
                    Operating_Unit__c = 'RH US Operating Unit',
                    StageName='Prepare',
                    Amount = 3000.00,
                    Credit_Card_First_Name__c = null,
                    Credit_Card_Last_Name__c = null,
                    Credit_Card_Email__c = null,
                    Credit_Card_Phone__c = null,
                    Credit_Card_Address__c = null,
                    Credit_Card_City__c = null,
                    Credit_Card_State__c = null,
                    Credit_Card_Country__c = null,
                    Credit_Card_Zip__c = null,
                    Credit_Card_Reference_Number__c = null,
                    Credit_Card_Transaction_UUID__c = null,
                    Credit_Card_Type__c = null,
                    Credit_Card_Expiration__c = null,
                    Credit_Card_Token__c = null,
                    NameOnCard__c = null,
                    CreditCardType__c = null,
                    Credit_Card_Number__c = null,
                    ExpirationDate__c = null,
                    CC_SpecialInstructions__c = null );
                insert opp;
            }
            return opp;
        }
    }

    @isTest static void propertiesTest() {
        initConfig();

        PageReference pageRef = Page.Opportunity_PaymentDetails;
        Test.setCurrentPage(pageRef);

        Map<String,String> paramMap = new Map<String,String>{
            'id'=>opp.Id
        };
        ApexPages.currentPage().getParameters().putAll(paramMap);    

        ApexPages.StandardController stdController = new ApexPages.StandardController(opp);

        Test.startTest();

        Opportunity_PaymentDetailsController controller = new Opportunity_PaymentDetailsController(stdController);
        Long timeStamp = controller.timeStamp;
        String uuid = controller.uuid;
        String now = controller.now;
        Map<String,String> signedFields = controller.signedFields;
        Map<String,String> responseFields = controller.responseFields;
        Map<String,Cybersource_Config__c> cybersourceConfig = controller.cybersourceConfig;
        List<Country__c> countries = controller.countries;
        List<String> creditCardTypeCodes = controller.creditCardTypeCodes;
        Map<String,String> creditCardTypes = controller.creditCardTypes;
        List<String> expiryDateMonthCodes = controller.expiryDateMonthCodes;
        Map<String,String> expiryDateMonths = controller.expiryDateMonths;
        List<String> expiryDateYears = controller.expiryDateYears;
        String signature = controller.signature;
        String decision = controller.decision;
        String message = controller.message;
        Opportunity fetchedOpp = controller.opp;

        Test.stopTest();

        System.assertEquals(opp.Name, fetchedOpp.Name);
    }

    @isTest static void saveOppTest() {
        initConfig();

        PageReference pageRef = Page.Opportunity_PaymentDetails;
        Test.setCurrentPage(pageRef);

        Map<String,String> paramMap = new Map<String,String>{
            'id'=>opp.Id
        };
        ApexPages.currentPage().getParameters().putAll(paramMap);    

        ApexPages.StandardController stdController = new ApexPages.StandardController(opp);
        Opportunity_PaymentDetailsController controller = new Opportunity_PaymentDetailsController(stdController);
        controller.pageNumber = 2;
        controller.opp.Credit_Card_First_Name__c = 'Test';

        Test.startTest();

        controller.saveOpp();

        Test.stopTest();

        Opportunity fetchedOpp = [SELECT Id, Credit_Card_First_Name__c FROM Opportunity WHERE Id = :opp.Id LIMIT 1];
        System.assertEquals('Test', fetchedOpp.Credit_Card_First_Name__c);
    }

    @isTest static void processCardholderDetailsTest() {
        initConfig();

        PageReference pageRef = Page.Opportunity_PaymentDetails;
        Test.setCurrentPage(pageRef);

        Map<String,String> paramMap = new Map<String,String>{
            'id'=>opp.Id,
            'access_key'=>'67890',
            'profile_id'=>'ABCDE',
            'transaction_uuid'=>'d1a7e30b-0796-4e27-92a0-58a942baa478',
            'signed_field_names'=>'access_key,profile_id,transaction_uuid,signed_field_names,unsigned_field_names,signed_date_time,locale,transaction_type,reference_number,amount,currency,payment_method,bill_to_forename,bill_to_surname,bill_to_email,bill_to_phone,bill_to_address_line1,bill_to_address_city,bill_to_address_state,bill_to_address_country,bill_to_address_postal_code',
            'unsigned_field_names'=>'card_type,card_number,card_expiry_date',
            'signed_date_time'=>'2015-07-31T22:29:28Z',
            'locale'=>'en',
            'transaction_type'=>'create_payment_token',
            'reference_number'=>opp.Id,
            'payment_method'=>'card',
            'amount'=>'0',
            'currency'=>'USD',
            'bill_to_forename'=>'Test',
            'bill_to_surname'=>'Smith',
            'bill_to_email'=>'test@example.com',
            'bill_to_phone'=>'123-456-7890',
            'bill_to_address_line1'=>'123 Main St',
            'bill_to_address_city'=>'Anywhere',
            'bill_to_address_state'=>'NC',
            'bill_to_address_country'=>'US',
            'bill_to_address_postal_code'=>'27601'
        };
        ApexPages.currentPage().getParameters().putAll(paramMap);    

        ApexPages.StandardController stdController = new ApexPages.StandardController(opp);

        Test.startTest();

        Opportunity_PaymentDetailsController controller = new Opportunity_PaymentDetailsController(stdController);

        Test.stopTest();

        System.assertEquals(2, controller.pageNumber);
        System.assertEquals('Test', controller.opp.Credit_Card_First_Name__c);
        System.assertEquals(opp.Id, controller.opp.Credit_Card_Reference_Number__c);
    }

    @isTest static void processCardDetailsTest() {
        initConfig();

        PageReference pageRef = Page.Opportunity_PaymentDetails;
        Test.setCurrentPage(pageRef);

        Map<String,String> paramMap = new Map<String,String>{
            'auth_amount'=>'0.00',
            'auth_avs_code'=>'X',
            'auth_avs_code_raw'=>'I1',
            'auth_code'=>'888888',
            'auth_response'=>'100',
            'auth_time'=>'2015-07-31T222928Z',
            'auth_trans_ref_no'=>'13256468OCRD1ENK',
            'decision'=>'ACCEPT',
            'id'=>opp.Id,
            'inst'=>'Z',
            'message'=>'Request was processed successfully.',
            'originalRequestIsPost'=>'1',
            'payment_token'=>'9903000037048880',
            'reason_code'=>'100',
            'req_access_key'=>'67890',
            'req_amount'=>'0',
            'req_bill_to_address_city'=>'Anywhere',
            'req_bill_to_address_country'=>'US',
            'req_bill_to_address_line1'=>'123 Main St',
            'req_bill_to_address_postal_code'=>'27601',
            'req_bill_to_address_state'=>'NC',
            'req_bill_to_email'=>'test@example.com',
            'req_bill_to_forename'=>'Test',
            'req_bill_to_phone'=>'123-456-7890',
            'req_bill_to_surname'=>'Smith',
            'req_card_expiry_date'=>'08-2023',
            'req_card_number'=>'xxxxxxxxxxxx1111',
            'req_card_type'=>'001',
            'req_currency'=>'USD',
            'req_locale'=>'en',
            'req_payment_method'=>'card',
            'req_profile_id'=>'ABCDE',
            'req_reference_number'=>opp.Id,
            'req_transaction_type'=>'create_payment_token',
            'req_transaction_uuid'=>'d1a7e30b-0796-4e27-92a0-58a942baa478',
            'signature'=>'YFqa0WFydeLyb+TCaxmgSx7WXcUQwuPT8gaGnFVC/cE=',
            'signed_date_time'=>'2015-07-31T22:29:28Z',
            'signed_field_names'=>'transaction_id,decision,req_access_key,req_profile_id,req_transaction_uuid,req_transaction_type,req_reference_number,req_amount,req_currency,req_locale,req_payment_method,req_bill_to_forename,req_bill_to_surname,req_bill_to_email,req_bill_to_phone,req_bill_to_address_line1,req_bill_to_address_city,req_bill_to_address_state,req_bill_to_address_country,req_bill_to_address_postal_code,req_card_number,req_card_type,req_card_expiry_date,message,reason_code,auth_avs_code,auth_avs_code_raw,auth_response,auth_amount,auth_code,auth_trans_ref_no,auth_time,request_token,payment_token,signed_field_names,signed_date_time',
            'transaction_id'=>'4383817674425000001518'
        };
        ApexPages.currentPage().getParameters().putAll(paramMap);    

        ApexPages.StandardController stdController = new ApexPages.StandardController(opp);

        Test.startTest();

        Opportunity_PaymentDetailsController controller = new Opportunity_PaymentDetailsController(stdController);

        Test.stopTest();

        System.assertEquals(3, controller.pageNumber);
        System.assertEquals('9903000037048880', controller.opp.Credit_Card_Number__c);
        System.assertEquals(Date.newInstance(2023,8,31), controller.opp.ExpirationDate__c);
    }

    @isTest static void processCardDetailsErrorTest() {
        initConfig();

        PageReference pageRef = Page.Opportunity_PaymentDetails;
        Test.setCurrentPage(pageRef);

        Map<String,String> paramMap = new Map<String,String>{
            'decision'=>'ERROR',
            'id'=>opp.Id,
            'inst'=>'Z',
            'invalid_fields'=>'card_number',
            'message'=>'Request parameters are invalid or missing',
            'originalRequestIsPost'=>'1',
            'reason_code'=>'102',
            'req_access_key'=>'67890',
            'req_amount'=>'0',
            'req_bill_to_address_city'=>'Anywhere',
            'req_bill_to_address_country'=>'US',
            'req_bill_to_address_line1'=>'123 Main St',
            'req_bill_to_address_postal_code'=>'27601',
            'req_bill_to_address_state'=>'NC',
            'req_bill_to_forename'=>'Test',
            'req_bill_to_phone'=>'123-456-7890',
            'req_bill_to_surname'=>'Smith',
            'req_card_expiry_date'=>'08-2023',
            'req_card_number'=>'xxxxxxxxxxxx1111',
            'req_card_type'=>'001',
            'req_currency'=>'USD',
            'req_locale'=>'en',
            'req_payment_method'=>'card',
            'req_profile_id'=>'ABCDE',
            'req_reference_number'=>opp.Id,
            'req_transaction_type'=>'create_payment_token',
            'req_transaction_uuid'=>'d1a7e30b-0796-4e27-92a0-58a942baa478',
            'required_fields'=>'bill_to_email',
            'retURL'=>'https://c.cs17.visual.force.com/apex/Opportunity_PaymentDetails',
            'signature'=>'09rFFb2tbVh0xN6ijYxFsadSU9ip+9rc6hk1zgHFjk0=',
            'signed_date_time'=>'2015-07-31T22:29:28Z',
            'signed_field_names'=>'decision,req_access_key,req_profile_id,req_transaction_uuid,req_transaction_type,req_reference_number,req_amount,req_currency,req_locale,req_payment_method,req_bill_to_forename,req_bill_to_surname,req_bill_to_phone,req_bill_to_address_line1,req_bill_to_address_city,req_bill_to_address_state,req_bill_to_address_country,req_bill_to_address_postal_code,req_card_number,req_card_type,req_card_expiry_date,required_fields,invalid_fields,reason_code,message,signed_field_names,signed_date_time'
        };
        ApexPages.currentPage().getParameters().putAll(paramMap);    

        ApexPages.StandardController stdController = new ApexPages.StandardController(opp);

        Test.startTest();

        Opportunity_PaymentDetailsController controller = new Opportunity_PaymentDetailsController(stdController);

        Test.stopTest();

        System.assertEquals(3, controller.pageNumber);
        System.assertEquals(null, controller.opp.Credit_Card_Number__c);
        System.assertEquals(null, controller.opp.ExpirationDate__c);
        System.assertEquals('ERROR', controller.decision);
        System.assertEquals('Request parameters are invalid or missing. Invalid fields: ' + Label.CC_Number + '. Required fields: ' + Label.CC_Email, controller.message);
    }

	@IsTest
	static void redirectTest() {
		List<StringSetting__c> stringSettings = new List<StringSetting__c>{
			new StringSetting__c(Name=Opportunity_PaymentDetailsController.TOKEN_PREFERRED_SETTING,Value__c='US,Ca.*'),
			new StringSetting__c(Name=Opportunity_PaymentDetailsController.TOKEN_DISALLOWED_SETTING,Value__c='Cambodia') };
		insert stringSettings;
		PageReference pageRef = Page.Opportunity_PaymentDetails;
		pageRef.getParameters().put('id',opp.Id);
		Test.setCurrentPage(pageRef);
		ApexPages.StandardController stdController = new ApexPages.StandardController(opp);
		Opportunity_PaymentDetailsController controller = new Opportunity_PaymentDetailsController(stdController);
		Test.startTest();
		System.assertEquals(null,Opportunity_PaymentDetailsController.isTokenRequired(null));
		System.assertEquals(true,Opportunity_PaymentDetailsController.isTokenRequired('RH US Operating Unit'));
		System.assertEquals(true,Opportunity_PaymentDetailsController.isTokenRequired('RH Canada Operating Unit'));
		System.assertEquals(false,Opportunity_PaymentDetailsController.isTokenRequired('RH China Operating Unit'));
		System.assertEquals(false,Opportunity_PaymentDetailsController.isTokenRequired('RH Cambodia Operating Unit'));
		System.assertEquals(null,controller.redirect());
		controller.opp.Operating_Unit__c = 'RH China Operating Unit';
		PageReference noTokenPage = controller.redirect();
		System.assertNotEquals(null,noTokenPage);
		Test.setCurrentPage(noTokenPage);
		System.assertEquals(null,controller.redirect());
		controller.opp.Operating_Unit__c = 'RH Canada Operating Unit';
		System.assertNotEquals(null,controller.redirect());
		controller.clearAndSave();
		Test.stopTest();
	}

	@IsTest
	static void clearAndSaveTest() {
		ApexPages.StandardController stdController = new ApexPages.StandardController(opp);
		opp.NameOnCard__c = 'Anything';
		Opportunity_PaymentDetailsController controller = new Opportunity_PaymentDetailsController(stdController);
		Test.startTest();
		controller.clearAndSave();
		System.assertEquals(null,controller.opp.NameOnCard__c);
		Test.stopTest();
	}
}