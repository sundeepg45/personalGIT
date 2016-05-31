/**
 * A Schedulable wrapper for the TrendData class.
 *
 * @author Scott Coleman <scoleman@redhat.com>
 * @version 2013-04-17
 * 2013-04-17 - created
 */
global class TrendDataSchedulable implements Schedulable {
	global final String eName;

	global TrendDataSchedulable(String eventName) {
		eName=eventName;
	}

	/**
	 * execute() method implemented for Schedulable interface 
	 */
	global void execute(SchedulableContext SC) {
		TrendData.captureTrendData(eName);
	}
}