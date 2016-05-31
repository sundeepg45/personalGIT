/**
 * This just a collection of various methods used throughout the system.  Many of these now
 * have a better salesforce alternative.  As such use of this class is discouraged without first
 * examining the alternatives available.
 *
 * @version 2014-04-19
 * @author Bill Riemers <briemers@redhat.com>
 * 2014-04-19 - Updated the testing value to auto assign based on Test.isTesting()
 */
public class Util {
	public static final String SANDBOXES_DEFAULT = 'dev';
	// Feel free to add more explicity mappings, such as training boxes.
	public static final Map<String,String> SANDBOXES = new Map<String,String>{
		'com'=>'prod',
		'stage'=>'stage',
		'qa'=>'qa','fte1'=>'qa','fte2'=>'qa'};

	private static boolean testing = Test.isRunningTest();

	//added this variable for federationid future method
	public static boolean fedidUpdateInprogress = false;
	
	// For Deployment
	public static boolean isBusinessPlanUpdate=false;
	public static final Id ldAccount='0016000000IqtyrAAB';
	public static final Id ldUserId='00560000000m2EaAAI';
	public static final Id globalLeadRoutingQueue='00G600000016VAx';
	public static final Id naNewBusinessQueue='00G600000016V8w';
	public static final Id naSledSalesQueue='00G600000016V96';
	public static final Id naEduQueue='00G600000016rGb';
	public static final Id ldPartnerUser='00560000000mHDC';
	public static final Id deployOppId='0066000000ANON2';
	public static final Id opportunityBookedOppRecordTypeId='012600000004va3';
	// we are deliberately breaking any reference to this value
	public static Id apexDeployment { get { return ((String)null).toUpperCase();}}
//  public static final Id systemAdminProfileId='00e30000000ek2cAAA';
//  public static final Id apiProfileId='00e60000000unwUAAQ';
	public static final Id strategicRecordTypeId='012600000004vRLAAY';
	public static final Id taskRecordTypeId='012600000004yfLAAQ';
	public static final Id omCorrectionRequestRecordTypeId='012600000004yfpAAA';
	public static final Id omProcessingRecordTypeId='0126000000053JGAAY';
	public static final Id tandemRecordTypeId='01260000000574LAAQ';

	public static String sfdcUrl {
		get {
			List<User> userList = users.values();
			if( users.isEmpty() ) {
				userList = new List<User>{ currentUser() };
			}
			return userList[0].EnterpriseServerUrl__c;
		}
	}

	public static Set<String> TandemTask_Category=new Set<String> {'Goal','Tandem Review','Education (webinar, house fair, product presentation, workshops etc.)','Reporting (quarterly performance review, progress analysis, plain numbers)','Documentation (creation of account profile, account plan, account overview etc.)','Task (anything else)'};

	// added for Value Selling enhancement 19thDec Release -- 11/11/2011
	public static List<String> stageList = new List<String>{
		'Prepare','Engage','Qualify','Validate','Propose','Negotiate','Closed Lost','Closed Won','Closed Booked'};
		
	// added for Value Selling enhancement 19thDec Release -- 11/11/2011
	public static List<String> voList = new List<String>{
		'Territory/Account/Opportunity Plan Developed',
		'Meeting Confirmation Appointment Set',
		'Sponsor Communication Agreed Upon',
		'Power Sponsor & Evaluation Plan Modified or Agreed Upon',
		'T'+'\''+'s and C'+'\''+'s Agreed Upon',
		'Signed Documents Received'
	};
	
	// added for Value Selling enhancement 19thDec Release -- 11/11/2011
	public static Set<String> oppTypeSet = new Set<String>{
		'Eval','Royalty','Royalty - EMEA','REBOOK','OM Exception','DO NOT ADD TO ANY RECORD TYPE'};
		
	// added for Value Selling enhancement 19thDec Release -- 11/23/2011
	public static Set<String> oppTypeVOSet = new Set<String>{
		'Standard','Co-Term','Runtime','Hosting','Hosting - Initial'};
		
	// added for Value Selling enhancement 19th Dec Release -- 11/14/2011
	public static String dataCleanupUser = 'intadmin@redhat.com';
	
	public static String renewedOppId = '';
	public static boolean userFound = false;
	public static boolean leadAssigned=false;

	public static Map<Id,OpportunityLineItem[]> products = new Map<Id,OpportunityLineItem[]>();
	public static Map<Id,OpportunityTeamMember[]> sales_team = new Map<Id,OpportunityTeamMember[]>();
	public static Map<Id,AccountTeamMember[]> account_team = new Map<Id,AccountTeamMember[]>();
	public static Map<Id,Opportunity> Opp_data = new Map<Id,Opportunity>();
	public static Map<Id,User> users = new Map<Id,User>();
	public static Map<String,String> ownerUpdate = new Map<String,String>();

	public static String ENVIRONMENT {
		get {
			if(ENVIRONMENT == null)
			{
				String username = currentUser.UserName;
				if(! username.contains('@redhat.com')) {
					User u = [select UserName from User where UserName like 'intadmin@redhat.com%' limit 1];
					username = u.UserName;
				}
				ENVIRONMENT = SANDBOXES_DEFAULT;
				Integer i = username.lastIndexOf('.');
				if(i > 0) {
					final String s = SANDBOXES.get(username.substring(i+1));
					if(s != null) {
						ENVIRONMENT = s;
					}
				}
			}
			return ENVIRONMENT;
		}
		private set;
	}

	public static Boolean isProd() {
		return (ENVIRONMENT == 'prod');
	}

	public static Boolean isStage() {
		return (ENVIRONMENT == 'stage');
	}

	public static Boolean isQA() {
		return (ENVIRONMENT == 'qa');
	}

	public static Boolean isDev() {
		return (ENVIRONMENT == 'dev');
	}

	/***
	 *
	 **/
	public static boolean hasGPSGLSProducts(String oppid) {

		for(OpportunityLineItem product : products.get(oppid)) {
			String product_Name=product.PricebookEntry.Name;

			if(product_Name.startsWith('GPS') || product_Name.startsWith('GLS')) {
				return true;
			}
		}

		return false;
	}


	/***
	 *
	 **/
	public static boolean hasJbossProducts(String oppid){

		for(OpportunityLineItem product : products.get(oppid)) {
			String product_Name=product.PricebookEntry.Name;

			if(product_Name.startsWith('JBoss')) {
				return true;
			}
		}

		return false;
	}


	/***
	 * getOpportunity
	 *
	 **/
	public static Opportunity getOpportunityData(String oppid) {
		Opportunity opp=null;

		if(Util.Opp_data.get(oppid)!=null) {
			opp = Util.Opp_data.get(oppid);
		}

		else {
			opp = [SELECT
				account.RecordType.Name,
				account.Name,
				account.Account_Priority__c,
				account.AccountClassification__c,
				account.AccountRating__c,
				account.EMEA_SE_Required__c,
				account.OwnerId,
				OwnerId,CurrencyIsoCode,
				AccountId,
				Amount,
				BillingAddress__c,
				BillingCity__c,
				BillingCountry__c,
				CloseDate,
				Country_of_Order__c,
				EMEA_SE_Required__c,
				ForecastCategory,
				FulfillmentChannel__c,
				Id,
				Opportunity_Priority__c,
				OpportunityNumber__c,
				Primary_Partner__c,
				ProductsOfInterest__c,
				Region__c,
				Reseller__c,
				ShippingAddress__c,
				ShippingCity__c,
				ShippingCountry__c,
				StageName,
				LastModifiedById,
				Super_Region__c,
				name
				FROM Opportunity
				WHERE Id =:oppid ];
			Util.Opp_data.put(opp.id,opp);
		}

		return opp;
	}


	/***
	 * getUserProfile
	 *
	 **/
	public static User getUser(Id userid){

		User user = users.get(userid);
		if(user == null) {
			Set<Id> queryIds = new Set<Id>{userid,UserInfo.getUserId()};
			queryIds.removeAll(users.keySet());
			for(User u : [select Email,Name,UserName,UserRoleId,ProfileId,Profile.Name,EnterpriseServerUrl__c from User where Id in :queryIds ]) {
				users.put(u.Id,u);
			}
			user = users.get(userid);
		}
		return user;
	}

	/***
	 *
	 **/
	public static OpportunityTeamMember[] getSalesTeam(String oppid) {

		OpportunityTeamMember[] team=null;

		if(Util.sales_team.get(oppid)!=null){
			 team = Util.sales_team.get(oppid);
		}else{
			team=[Select OpportunityId, TeamMemberRole, UserId from OpportunityTeamMember where OpportunityId=:oppid And User.IsActive = true];
			Util.sales_team.put(oppid,team);
		}
		return team;
	}


	/***
	 *
	 **/
	public static AccountTeamMember[] getAccountTeam(String accid){
		AccountTeamMember[] team=null ;

		if(Util.account_team.get(accid)!=null){
			team = Util.account_team.get(accid);
		}
		else {
			team= [Select Id, UserId, User.Email from AccountTeamMember where AccountId =:accid ];
			Util.account_team.put(accid,team);
		}

		return team;
	}

	/***
	 *
	 **/
	public static OpportunityLineItem [] getProducts(String oppid){

		System.debug('oppid**'+oppid);
		System.debug(Util.products);
		OpportunityLineItem[] lineitems=null;
		if (Util.products.get(oppid)!=null && Util.products.get(oppid).size()>0) {
			System.debug('inside iff');
			lineitems=Util.products.get(oppid);
		}
		else {
			lineitems = [
		SELECT
			opportunityId,
			PricebookEntry.Name,
			PricebookEntry.CurrencyIsoCode,
			PricebookEntry.Product2.Family,
			PricebookEntry.Product2.ProductCode,
			Quantity,
			CurrencyIsoCode,
			UnitPrice,
			TotalPrice
		FROM OpportunityLineItem
		WHERE OpportunityId =:oppid ];

			Util.products.put(oppid,lineitems);
		}
		System.debug('lineItems'+lineitems);
		return lineitems;
	}


	public static User currentUser {
		get {
			if(currentUser == null) {
				// This will have most of the things we need.  For additional information a query is required.
				currentUser = new User(Id=UserInfo.getUserId(),UserName=UserInfo.getUserName(),UserRoleId=UserInfo.getUserRoleId(),ProfileId=UserInfo.getProfileId(),Profile=new Profile(Id=UserInfo.getProfileId()));
			}
			return currentUser;
		}
		set;
	}

	/***
	 * For Partner update trigger
	 *
	 **/
	public static User currentUser() {
		if(userFound == false) {
			userFound = true;
			currentUser = getUser(UserInfo.getUserId());
			System.debug('currentUser='+currentUser);
		}
		return currentUser;
	}



	public static Map<String,String> opportunityIds = new Map<String,String>();
	public static Map<String,String> gpsglsIds = new Map<String,String>();


	public static String nullCheck(String name)
	{
		return (name==null)?'':name;
	}



	public static Boolean isNill(Object value) {
		try {
			return (value == null)||(String.valueOf(value).length() == 0);
		}
		catch(Exception ignored) {}

		return false;
	}

	public static Double getConvertedAmount(String CurrencyIsoCode, Double amount ){
		if(CurrencyIsoCode== 'AUD') {
			return amount * 1.2;
		}
		else if(CurrencyIsoCode=='USD')
		{
			return amount;
		}

		else if(CurrencyIsoCode== 'BRL')
		{
			return amount * 1.95;
		}
		else if(CurrencyIsoCode== 'CAD')
		{
			return amount * 1.05;
		}
		else if(CurrencyIsoCode== 'CNY')
		{
			return amount * 7.56;
		}
		else if(CurrencyIsoCode== 'EUR')
		{
			return amount * 0.73;
		}
		else if(CurrencyIsoCode== 'GBP')
		{
			return amount * 0.5;
		}
		else if(CurrencyIsoCode== 'HKD')
		{
			return amount * 7.8;
		}
		else if(CurrencyIsoCode== 'INR')
		{
			return amount * 40;
		}
		else if(CurrencyIsoCode== 'JPY')
		{
			return  amount  * 120;
		}
		else if(CurrencyIsoCode== 'KRW')
		{
			return amount * 940;
		}
		else if(CurrencyIsoCode== 'MYR')
		{
			return amount * 3.48;
		}
		else if(CurrencyIsoCode== 'PHP')
		{
			return amount * 46;
		}
		else if(CurrencyIsoCode== 'SGD')
		{
			return amount * 1.52;
		}
		else if(CurrencyIsoCode== 'THB')
		{
			return amount *33;
		}
		else if(CurrencyIsoCode== 'NZD')
		{
			return amount * 1.32;
		}
		return amount;
	}



	public static String getUpperCaseValue(String value)
	{
		String upperValue;
		if(value==null)
		{
			return '';
		}
		else
		{
			upperValue=value.toUpperCase();
			return upperValue;
		}
	}

	public static boolean isTesting() {
		return testing;
	}

	public static void setTesting(boolean value) {
		testing=value;
	}

	/**
	 * By pass for admin based on the IsAdmin__c checkbox of the
	 * AdminByPass__c custom setting for the current user's profile.
	 *
	 * @param testingRetval value that should be returned when testing.
	 * @returns  testingRetval if isTesting() otherwise AdminByPass__c.getInstance().IsAdmin__c
	 */
	public static boolean adminByPass(boolean testingRetval) {
		Boolean retval = (AdminByPass__c.getInstance().IsAdmin__c == true);
		if(isTesting()) {
			retval = testingRetval;
		}
		return retval;
	}


	/**
	 * By pass for admin based on the IsAdmin__c checkbox of the
	 * AdminByPass__c custom setting for the current user's profile.
	 *
	 * @param testingRetval value that should be returned when testing.
	 * @returns  IsAdmin__c from AdminByPass__c
	 */
	public static boolean adminByPass()
	{
		return adminByPass(true);
	}

	/**
	 * By pass for admin based on the IsOppAdmin__c checkbox 
	 * of the AdminByPass__c custom setting for the current user's profile.
	 * Currently only used to prevent automatic update of Opportunity
	 * Department field for admin users.
	 *
	 * @param testingRetval value that should be returned when testing.
	 * @returns  testingRetval if isTesting() otherwise AdminByPass__c.getInstance().IsOppAdmin__c
	 */
	public static boolean adminByPassForOpportunity(boolean testingRetval)
	{
		Boolean retval = (AdminByPass__c.getInstance().IsOppAdmin__c == true);
		if(isTesting()) {
			retval = testingRetval;
		}
		return retval;
	}

	/**
	 * By pass for admin based on the IsOppAdmin__c checkbox 
	 * of the AdminByPass__c custom setting for the current user's profile.
	 *
	 * @returns  ture if isTesting() otherwise AdminByPass__c.getInstance().IsOppAdmin__c
	 */
	public static boolean adminByPassForOpportunity()
	{
		return adminByPassForOpportunity(true);
	}

	/**
	 * By pass for channel load operations based on the IsBulkAdmin__c checkbox 
	 * of the AdminByPass__c custom setting for the current user's profile.
	 *
	 * @param testingRetval value that should be returned when testing.
	 * @returns  testingRetval if isTesting() otherwise AdminByPass__c.getInstance().IsChannelLoad__c
	 */
	public static boolean channelLoadByPass(boolean testingRetval)
	{
		Boolean retval = (AdminByPass__c.getInstance().IsChannelLoad__c == true);
		if(isTesting()) {
			retval = testingRetval;
		}
		return retval;
	}

	/**
	 * By pass for channel load operations based on the IsBulkAdmin__c checkbox 
	 * of the AdminByPass__c custom setting for the current user's profile.
	 *
	 * @returns  false if isTesting() otherwise AdminByPass__c.getInstance().IsBulkAdmin__c
	 */
	public static boolean channelLoadByPass()
	{
		return channelLoadByPass(false);
	}

	public static Map<String,String> regionOpps= new Map<String,String>();


	/***
	 * Calculates the number of leap days in a given date range
	 * @param - startDate
	 * @param - endDate
	 *
	 * @return Integer
	 */
	 
	public static Integer leapDays(Date startDate, Date endDate) {

		Integer leapDays = 0;
		Date periodStart = startDate;
		Date periodEnd   = null;

		while (periodStart <= endDate)
		{
			Integer periodYear = periodStart.year ();
			Date february28 = Date.newInstance (periodYear, 2, 28);

			// Determine end of period
			if (periodYear != endDate.year ())
				periodEnd = Date.newInstance (periodYear, 12, 31);
			else
				periodEnd = endDate;

			System.debug ('- Starting period loop: ');
			System.debug ('- - periodStart = ' + periodStart);
			System.debug ('- - periodEnd = ' + periodEnd);
			System.debug ('- - periodYear = ' + periodYear);
			System.debug ('- - isLeapYear = ' + Date.isLeapYear (periodYear));
			System.debug ('- - february28 = ' + february28);

			// Check for leap year presence
			if (Date.isLeapYear (periodYear))
			{   
				if (periodStart <= february28 && periodEnd > february28)
					leapDays ++;
				
				Date february29 = Date.newInstance(periodYear, 2, 29);  
				if (periodStart == february29)
					leapDays ++;
			}

			// Stop looping?
			if (periodYear == endDate.year ())
				break;

			// Move the date
			periodStart = Date.newInstance (periodYear + 1, 1, 1);
		}

		return leapDays;
	}
}