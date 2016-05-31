/**
 * This class allows us to look up dated currency conversions for a given set of ISO codes and dates.
 * The current implemenation of the datedConversionRate table contains conversion rates for individual
 * dates as well as date ranges.
 *
 * This class does its best to find a conversion rate for all of the date ranges. If a conversion rate for
 * a given date and ISO code are not found the development team is notified.
 *
 * @version 2013-04-19
 * @author Bryan Bosely <bbosely@redhat.com>
 * Bill Riemers <briemers@redhat.com>
 * 2013-04-26 - Modified to virtual to allow more complete testing
 * 2013-04-19 - Modified to work for dates in the future
 * 2013-04-16 - Modified to limit e-mail messages and catch exceptions
 * 2013-04-16 - Use static values to reduce the number of queries
 * 2013-04-16 - Minor code clean-up
 * 2013-02-26 - Modified not to blow-up with too many statements
 */
public virtual class DatedCurrencyConversion
{
	/** Name of custom setting fast warnind date. */
	public static final String LAST_WARNING_KEY = 'DatedCurrency.LastWarning';

	/** How often (in hours) we should send the same warning. */
	public static final Integer WARNING_FREQUENCY = 1;

	protected Map<String, Map<Date, Double>> conversionMap = new Map<String, Map<Date, Double>>();

	/**
	 * Default Constructor
	 */
	public DatedCurrencyConversion() {}

	static List<Date> reverseSort(Set<Date> dates) {
		List<Date> sortedDates = new List<Date>(dates);
		sortedDates.sort();
		List<Date> retval = new List<Date>();
		for(Integer i=sortedDates.size();i > 0;) {
			retval.add(sortedDates.get(--i));
		}
		return retval;
	}

	/**
	 * retrieves a conversion rate map in the following format
	 *
	 * [ 
	 *		IsoCode => [ Date => Conversion Rate],
	 *	  IsoCode => [ Date => Conversion Rate]
	 * ]
	 *  
	 * @param	isoCodes
	 * @param	dates
	 * @return 	mapping of values
	 */
	public Map<String, Map<Date, Double>> getConversionRateMap( Set<String> isoCodes, Set<Date> dates) {
		// remove USD ISO if it is passed in this is not a valid scenario
		isoCodes.remove('USD');
		if(! (dates.isEmpty() || isoCodes.isEmpty()) ) {
			dates.addAll( maxStartDateMap.values() );
			List<Date> datesReverseSorted = reverseSort( dates );


			List<DatedConversionRate> conversionRates = queryConversionRates( isoCodes, datesReverseSorted);
			populateConversionMap( conversionRates, datesReverseSorted );

			// determine if we need to perform a date range based search for
			// currency conversions
			List<ConversionRate> noConversionRates = validateConversionRates( isoCodes, datesReverseSorted );
			if ( ! noConversionRates.isEmpty() ) {

				// perform a ranged based rate search if a date has no currency
				// conversion rate
				List<DatedConversionRate> rangedConversionRates = queryDateRangeConversionRates( noConversionRates );
				populateConversionMap( rangedConversionRates, datesReverseSorted);

				// if we can not find all of the conversion rates notify dev team
				noConversionRates = validateConversionRates( isoCodes, datesReverseSorted );
				if ( ! noConversionRates.isEmpty() ) {
					exceptionNotification( noConversionRates );	
				}
			}
		}
		return conversionMap;
	}

	static DateTimeSetting__c lastWarning {
		get {
			if(lastWarning == null) {
				lastWarning = DateTimeSetting__c.getInstance(LAST_WARNING_KEY);
				if(lastWarning == null) {
					lastWarning = new DateTimeSetting__c(Name=LAST_WARNING_KEY);
				}
			}
			return lastWarning;
		}
	}

	/**
	 * method for notifying the dev team of exceptional conditions
	 *
	 * @param	subjectText
	 * @param	bodyText
	 *
	 */
	public void notifyDevTeam( String subjectText, String bodyText )
	{
		if(lastWarning.Value__c == null || lastWarning.Value__c <= system.now().addHours(-WARNING_FREQUENCY)) {
			if(Limits.getEmailInvocations() < Limits.getLimitEmailInvocations()) {
				try {
					lastWarning.Value__c = system.now();
					Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
					String[] toAddresses = new String[] { 'sf-error-list@redhat.com' };
					mail.setToAddresses( toAddresses );
					mail.setSubject( subjectText );
					mail.setPlainTextBody( bodyText );
					Messaging.sendEmail( new Messaging.SingleEmailMessage[] { mail } );
					upsert lastWarning;
				}
				catch(Exception ignored) {}
			}
		}
	}

	/**
	 * method for querying dated conversion rates
	 *
	 * @param	isoCodes
	 * @param	dates
	 * @return	list of DatedConversionRate
	 */
	private List<DatedConversionRate> queryConversionRates( Set<String> isoCodes, List<Date> dates ) {
		// obtain the currency conversion rates
		List<DatedConversionRate> conversionRates = new List<DatedConversionRate>();
		conversionRates = [
			SELECT
				ConversionRate,
				IsoCode,
				StartDate,
				NextStartDate
			FROM DatedConversionRate 
			WHERE StartDate IN :dates
			AND IsoCode IN :isoCodes ];
		system.debug( '-- conversion rates returned: ' + conversionRates.size() );
		return conversionRates;
	}

	/**
	 * method to perform a date range search 
	 * on the dated conversion rate table
	 *
	 * @param noRates
	 * @return list of DatedConversionRate
	 */
	private List<DatedConversionRate> queryDateRangeConversionRates( List<ConversionRate> noRates ) {
		List<DatedConversionRate> retval = new List<DatedConversionRate>();
		if ( ! noRates.isEmpty() ) {
			// use a range based search to see if we can find a conversion rate
			String query = 'SELECT Id, ConversionRate, IsoCode, StartDate, NextStartDate ' +
				'FROM DatedConversionRate ' + 
				'WHERE '; 
			String sep = '';	
			for	( ConversionRate rate : noRates ) {
				query += sep + '(StartDate <= ' + String.valueOf( rate.startDate ) + ' AND NextStartDate > ' + String.valueOf( rate.startDate ) + ' AND IsoCode = \'' + rate.isoCode + '\' )';
				sep = ' OR ';
			}	
			system.debug ('-- query: ' + query);
			retval = Database.query( query );
		}
		return retval;
	}

	/**
	 * method for populating the conversion rate map
	 *
	 * @param conversionRates
	 * @param dates list in a desc order
	 */
	private void populateConversionMap( List<DatedConversionRate> conversionRates, List<Date> dates) {
		Integer datesSize = dates.size();
		// add the conversion rates to the conversion map
		for ( DatedConversionRate rate : conversionRates ) {
			Map<Date, Double> conversionRateMap = conversionMap.get( rate.IsoCode );
			if(conversionRateMap == null) {
				conversionRateMap = new Map<Date, Double>();
				conversionMap.put( rate.IsoCode, conversionRateMap );
			}

			// do not add the days between the startDate and the nextStartDate
			// for the minStartDate and the maxStart date to the conversion Map.
			// these ranges are way too large.
			//
			// just add the conversion rate
			if ( rate.NextStartDate == minStartDate ) {
				system.debug( ' -- nextStartDate = minStartDate' );
				conversionRateMap.put( rate.NextStartDate, rate.ConversionRate );
			}
			else {
				Integer daysBetween = null;
				if ( rate.startDate == maxStartDateMap.get( rate.IsoCode ) ) {
					system.debug( ' -- startDate = maxStartDate' );
					// we do this the code will work for dates in the future
					daysBetween = datesSize;
				}
				else {
					// add an entry to the conversion rate map for the days between the startDate and the NextStartDate
					daysBetween = ( rate.StartDate.daysBetween( rate.NextStartDate ) );
					system.debug( ' -- daysBetween: ' + daysBetween );
				}
				if(daysBetween < datesSize) {
					for (Integer i=0; i<daysBetween; i++) {
						conversionRateMap.put( rate.StartDate.addDays(i), rate.ConversionRate );
					}
					if(daysBetween > 1) {
						conversionRateMap.keySet().retainAll( dates );
					}
				}
				else {
					for (Date d : dates) {
						if(d < rate.NextStartDate) {
							if(d < rate.StartDate) {
								break;
							}
							conversionRateMap.put( d, rate.ConversionRate);
						}
					}
				}
			}
		}
		system.debug( '-- conversionRatesMap: ' + conversionMap );
	}

	/**
	 * method to ensure we have a conversion rate for all the close dates
	 *
	 * @param	Set<String> isoCodes
	 * @param 	Set<Date> dates
	 * return	List<ConversionRate>
	 */
	protected virtual List<ConversionRate> validateConversionRates( Set<String> isoCodes, List<Date> dates )
	{
		system.debug ( ' -- validate isoCodes: ' + isoCodes );
		system.debug ( ' -- validate dates: ' + dates );

		List<ConversionRate> noConversionRate = new LIst<ConversionRate>();

		// only validate non-empty maps
		if (! conversionMap.isEmpty() ) {
			// loop through the conversion map
			for (String isoCode : isoCodes) {
				system.debug( '-- validate isoCode: ' + isoCode );
				for (Date dt : dates) {
					system.debug( '-- validate date: ' + dt );

					// skip dates that are greater than the max start date
					if ( dt <= maxStartDateMap.get( isoCode ) ) {
						system.debug('-- validate conversionRateMap: ' + conversionMap);
						Map<Date, Double> conversionRateMap = conversionMap.get( isoCode );
						Double conversionRate = conversionRateMap.get( dt ); 

						if (conversionRate == null) {
							noConversionRate.add( new ConversionRate( isoCode, dt ));
						}
					}
				}
			}
			system.debug( ' -- noConversionRates: ' + noConversionRate );
		}
		return noConversionRate;
	}

	/**
	 * retrieves the minimum start date in the datedConversionRate table
	 */
	public Date minStartDate {
		get {
			return minStartDateStatic;
		}
	}

	/**
	 * retrieves the minimum start date in the datedConversionRate table
	 */
	public static Date minStartDateStatic {
		get {
			if(minStartDateStatic == null) {
				DatedConversionRate dcr = [
					SELECT
						NextStartDate 
					FROM DatedConversionRate
					ORDER BY NextStartDate Asc 
					LIMIT 1 ];
					system.debug( ' -- min start date ' + dcr.NextStartDate );
				minStartDateStatic = dcr.NextStartDate;
			}
			return minStartDateStatic;
		}
	}

	/**
	 * retrieves the maximum start date in the datedConversionRate table
	 */
	public Map<String, Date> maxStartDateMap {
		get {
			return maxStartDateMapStatic;
		}
	}

	/**
	 * retrieves the maximum start date in the datedConversionRate table
	 */
	public static Map<String, Date> maxStartDateMapStatic {
		get {
			if(maxStartDateMapStatic == null) {
				Map<String, Date> maxDates = new Map<String, Date>();

				// create a date filter to reduce our chance of hitting governor limits
				Date dt = system.today().addDays(-120);
				AggregateResult[] groupedResults = [
					SELECT
						Max(StartDate) maxStartDate,
						IsoCode 
					FROM DatedConversionRate
					WHERE IsoCode != 'USD'
					AND StartDate > :dt
					GROUP BY IsoCode ];
				for ( AggregateResult ar : groupedResults ) {
					maxDates.put( (String) ar.get( 'IsoCode' ), (Date) ar.get( 'maxStartDate' ) );
				}
				maxStartDateMapStatic = maxDates;
			}
			return maxStartDateMapStatic;
		}
	}

	/**
	 * this method notifies the dev team of opportunities were we can't locate
	 * a currency conversion
	 *
	 * @param List<>
	 *
	 */
	private void exceptionNotification( List<ConversionRate> noConversionRates ) {
		if ( ! noConversionRates.isEmpty() ) {
			String subject = 'SalesForce Notification: Currency Conversion Rate(s) ';
			String bodyText = 'DatedCurrencyConversion.cls - Unable to locate a currency conversion rate for the following dates:\n\n';
			for ( ConversionRate rate : noConversionRates )
			{
				bodyText += 'Date: ' + rate.startDate + ', Iso Code: ' + rate.isoCode +  '\n';
			}

			notifyDevTeam( subject, bodyText );
		}
	}

	/**
	 * Inner class to make quering conversion rates easier
	 * for the queryDateRangeConversionRates method
	 */
	public class ConversionRate {
		public String isoCode;
		public Date startDate;

		/**
		 * Constructor
		 * 
		 * @param isoCode currency iso code
		 * @param startDate for currency rate
		 */
		public ConversionRate( String isoCode, Date startDate )
		{
			this.isoCode = isoCode;
			this.startDate = startDate;
		}
	}
}