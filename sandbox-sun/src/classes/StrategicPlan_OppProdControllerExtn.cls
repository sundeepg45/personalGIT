/**
 * Test the controller extension used for the StrategicPlan_OppProdChartTab page.
 *
 * @author Bill C Riemers <briemers@redhat.com>
 * 2013-04-22 - created
 */
public with sharing class StrategicPlan_OppProdControllerExtn  extends TabUIController.Extension {
	/** The name of this tab. */
	private static final String TAB_NAME='StrategicPlan_OppProdSummary__c';
	/** Used it indicate daily report frequency. */
	public static final String DAILY = 'Daily';
	/** Used it indicate weekly report frequency. */
	public static final String WEEKLY = 'Weekly';
	/** Used it indicate monthly report frequency. */
	public static final String MONTHLY = 'Monthly';
	/** Indicates we should include a product. */
	public static final String INCLUDE_OPTION = 'Equals';
	/** Indicates we should exclude a product. */
	public static final String EXCLUDE_OPTION = 'Not Equals';
	/** Day of the week used for weekly reporting */
	public static final Integer DAY_OF_WEEK = 1;
	/** Day of the month used for weekly reporting */
	public static final Integer DAY_OF_MONTH = 1;

	private final TabUIController tabUIController;

	/**
	 * Construct using a TabUIController.
	 * 
	 * @param tabUIController
	 */
	public StrategicPlan_OppProdControllerExtn(TabUIController tabUIController) {
		super(TAB_NAME,tabUIController);
		getRecord();
		this.tabUIController = tabUIController;
		this.frequency = WEEKLY;
		this.productOperator = EXCLUDE_OPTION;
		this.productCode = '';
	}

	/**
	 * Get the id of the strategic plan.
	 * 
	 * @return id
	 */
	public Id getStrategicPlanId() {
		return tabUIController.getTabId('StrategicPlan__c');
	}

	/**
	 * Get an action object, used strictly for start and end dates.
	 */
	public StrategicPlan_Action__c dateRange {
		get {
			if(dateRange == null) {
				Date t = system.today();
				dateRange = new StrategicPlan_Action__c(
					End__c = t, Start__c = t.addMonths(-3) );
			}
			return dateRange;
		}
		set;
	}

	/**
	 * Options available for reporting frequency.
	 * 
	 * @return freqency SelectOption list
	 */
	public List<SelectOption> frequencyOptions {
		get {
			if(frequencyOptions == null) {
				frequencyOptions = new List<SelectOption>{
					new SelectOption(DAILY,DAILY),
					new SelectOption(WEEKLY,WEEKLY),
					new SelectOption(MONTHLY,MONTHLY) };
			}
			return frequencyOptions;
		}
		set;
	}

	/** Reporting frequency */
	public String frequency { get; set; }

	/**
	 * Options available for forecastCategoryName.
	 * 
	 * @return foregcastCategoryName SelectOption list
	 */
	public List<SelectOption> forecastCategoryNameOptions {
		get {
			if(forecastCategoryNameOptions == null) {
				forecastCategoryNameOptions = new List<SelectOption>();
				for(Schema.PicklistEntry ple : Schema.SObjectType.Opportunity.fields.ForecastCategoryName.getPicklistValues()) {
					forecastCategoryNameOptions.add(new SelectOption(ple.getValue(),ple.getLabel()));
				}
			}
			return forecastCategoryNameOptions;
		}
		set;
	}

	/** List of forecastCategoryNames */
	public List<String> forecastCategoryNames {
		get {
			if(forecastCategoryNames == null) {
				forecastCategoryNames = new List<String>();
				for(SelectOption so : forecastCategoryNameOptions) {
					forecastCategoryNames.add(so.getValue());
				}
			}
			return forecastCategoryNames;
		}
		set;
	}

	/**
	 * Options available for forecastCategoryName.
	 * 
	 * @return foregcastCategoryName SelectOption list
	 */
	public List<SelectOption> productOperatorOptions {
		get {
			if(productOperatorOptions == null) {
				productOperatorOptions = new List<SelectOption>{
					new SelectOption(INCLUDE_OPTION,INCLUDE_OPTION),
					new SelectOption(EXCLUDE_OPTION,EXCLUDE_OPTION) };
			}
			return productOperatorOptions;
		}
		set;
	}

	/** productOperator to determine how we use the productCode field */
	public String productOperator {get; set;}

	/** productCode to include or exclude */
	public String productCode {get; set;}

	/**
	 * Options available for productFamily.
	 * 
	 * @return productFamily SelectOption list
	 */
	public List<SelectOption> productFamilyOptions {
		get {
			if(productFamilyOptions == null) {
				productFamilyOptions = new List<SelectOption>{
					new SelectOption('','<No Products>') };
				for(Schema.PicklistEntry ple : Schema.SObjectType.Product2.fields.Family.getPicklistValues()) {
					productFamilyOptions.add(new SelectOption(ple.getValue(),ple.getLabel()));
				}
			}
			return productFamilyOptions;
		}
		set;
	}

	/** List of product families to include or exclude */
	public List<String> productFamilies {
		get {
			if(productFamilies == null) {
				productFamilies = new List<String>();
				for(SelectOption so : productFamilyOptions) {
					productFamilies.add(so.getValue());
				}
			}
			return productFamilies;
		}
		set;
	}

	/**
	 * Options available for stageNameOptions.
	 * 
	 * @return productFamily SelectOption list
	 */
	public List<SelectOption> stageNameOptions {
		get {
			if(stageNameOptions == null) {
				stageNameOptions = new List<SelectOption>();
				for(Schema.PicklistEntry ple : Schema.SObjectType.Opportunity.fields.StageName.getPicklistValues()) {
					stageNameOptions.add(new SelectOption(ple.getValue(),ple.getLabel()));
				}
			}
			return stageNameOptions;
		}
		set;
	}

	/** List of stageNames to include */
	public List<String> stageNames {
		get {
			if(stageNames == null) {
				stageNames = new List<String>();
				for(SelectOption so : stageNameOptions) {
					stageNames.add(so.getValue());
				}
			}
			return stageNames;
		}
		set;
	}

	/** The list of time series date */
	public List<AggregateResult> timeData {
		get {
			Id strategicPlanId = getStrategicPlanId();
			if(timeData == null && strategicPlanId != null) {
				Set<Integer> daysOfWeek = new Set<Integer>();
				daysOfWeek.add(DAY_OF_WEEK);
				if(frequency == DAILY || frequency == MONTHLY) {
					daysOfWeek.addAll(new List<Integer>{1,2,3,4,5,6,7});
				}
				Set<Integer> daysOfMonth = new Set<Integer>();
				daysOfMonth.add(DAY_OF_MONTH);
				if(frequency == DAILY || frequency == WEEKLY) {
					daysOfMonth.addAll(new List<Integer>{
						1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,
						16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31});
				}
				Date d1 = dateRange.Start__c;
				Date d2 = dateRange.End__c.addDays(-1);
				String pc = productCode;
				if(productOperator == EXCLUDE_OPTION) {
					Date d = d2;
					d2 = d1;
					d1 = d;
					if(pc == null || pc == '') {
						pc = '<dummy value>';
					}
				}
				timeData = [
					select 
						sum(AmountUSD__c) totalUSD, 
						min(DateCapturedFormatted__c) dateCaptured
					from StrategicPlan_OppProdSummary__c
					where StrategicPlan__c = :strategicPlanId
						and DateCaptured__c >= :dateRange.Start__c
						and DateCaptured__c <= :dateRange.End__c
						and DayOfWeekCaptured__c in :daysOfWeek
						and DayOfMonthCaptured__c in :daysOfMonth
						and Forecast_Category__c in :forecastCategoryNames
						and Product__r.Family in :productFamilies
						and Stage__c in :stageNames
						and (ProductCode__c <> :pc or DateCaptured__c >= :d1)
						and (ProductCode__c = :pc or DateCaptured__c >= :d2)
					group by DateCaptured__c
					order by DateCaptured__c ];
			}
			return timeData;
		}
		set;
	}

	/** The currentDate is the most recent DateCaptured__c of the data. */
	public Date currentDate {
		get {
			Id strategicPlanId = getStrategicPlanId();
			if(currentDate == null && strategicPlanId != null) {
				currentDate = System.today();
				for(StrategicPlan_OppProdSummary__c ops : [
					select
						DateCaptured__c
					from StrategicPlan_OppProdSummary__c
					where StrategicPlan__c = :strategicPlanId
					order by DateCaptured__c desc
					limit 1])
				{
					currentDate = ops.DateCaptured__c;
				}
			}
			return currentDate;
		}
		set;
	}

	/** List of currentValues */
	public List<AggregateResult> currentValues {
		get {
			Id strategicPlanId = getStrategicPlanId();
			if(currentValues == null && strategicPlanId != null) {
				currentValues = [
					select
						Forecast_Category__c forecastCategory,
						sum(AmountUSD__c) totalUSD,
						min(ProductCode__c) productCode,
						Product__r.Family productFamily,
						Product__r.Name productName,
						Stage__c stageName
					from StrategicPlan_OppProdSummary__c
					where StrategicPlan__c = :strategicPlanId
						and DateCaptured__c = :currentDate
					group by
						Forecast_Category__c,
						Stage__c,
						Product__r.Family,
						Product__r.Name
					order by
						Forecast_Category__c,
						Stage__c,
						Product__r.Family,
						Product__r.Name ];
			}
			return currentValues;
		}
		set;
	}

	/**
	 * Called to regenerate the data used in the time chart.
	 * 
	 * @return null
	 */
	public PageReference refreshTimeData() {
		tabUIController.activeTab = TAB_NAME;
		timeData = null;
		return null;
	}
}