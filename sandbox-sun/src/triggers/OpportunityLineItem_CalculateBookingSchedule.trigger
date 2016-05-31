/**
 * OpportunityLineItem_CalculateBookingSchedule
 *
 * This trigger replaces the previous SYBCalculator trigger and takes over responsibility
 * from Quote Builder for calculating the booking schedule.
 *
 * @package Single Year Bookings
 * @author Ian Zepp <izepp@redhat.com>
 * @version 1.0
 */

trigger OpportunityLineItem_CalculateBookingSchedule on OpportunityLineItem (before insert, before update) {
/*
	//
	// Loop through each opportunity line item (aka opportunity product)
	//
	for (OpportunityLineItem lineItem : Trigger.New) {
		System.debug ('Starting OpportunityLineItem: ' + lineItem.Id);

		//
		// Sanity checks
		//

		//System.assert (lineItem.OpportunityId != null);
		if(lineItem.OpportunityId == null)
		{
			lineItem.addError('No opportunity found');
			continue;
		}
		//System.assert (lineItem.OpportunityCloseDate__c != null);
		if(lineItem.OpportunityCloseDate__c == null)
		{
			lineItem.addError('No close date for Opportunity '+lineItem.OpportunityId);
			continue;
		}
		
		if (lineItem.Quantity == null)
			lineItem.Quantity = 0;
		
		if (lineItem.UnitPrice == null)
			lineItem.UnitPrice = 0;

		//
		// Zero out the booking schedule
		//
		System.debug ('- Zeroing existing scheduled amounts');

		lineItem.Year1Amount__c = 0.00; 
		lineItem.Year2Amount__c = 0.00;
		lineItem.Year3Amount__c = 0.00;
		lineItem.Year4Amount__c = 0.00;
		lineItem.Year5Amount__c = 0.00;
		lineItem.Year6Amount__c = 0.00;
		
		//
		// Calculate a total price. Because SF waits until after triggers to determine the 
		// total price, we need to do this up front.
		//
		
		Decimal totalPrice = lineItem.Quantity * lineItem.UnitPrice;
		
		System.debug ('- Using Total Price = ' + totalPrice);
		System.debug ('- Schedule Locked? = ' + lineItem.ScheduleLocked__c);	

		// 
		// Term is missing? 
		//	  
		
		if (lineItem.ActualTerm__c == null && lineItem.ProductDefaultTerm__c == null)
			lineItem.ActualTerm__c = 365;
		else if (lineItem.ActualTerm__c == null)
			lineItem.ActualTerm__c = lineItem.ProductDefaultTerm__c;
			
		// 
		// Start date is missing or the schedule isn't locked? Use the close date + 1.
		//
		
		if (lineItem.ActualStartDate__c == null || lineItem.ScheduleLocked__c == false)
			lineItem.ActualStartDate__c = lineItem.OpportunityCloseDate__c.AddDays (1); 

		System.debug ('- Actual Start Date = ' + lineItem.ActualStartDate__c);

		//
		// End date is missing or the schedule isn't locked?
		//
		
		if (lineItem.ActualEndDate__c == null || lineItem.ScheduleLocked__c == false) {
			//
			// If the term is 0 or null, set to default 365 day term
			//

			if (lineItem.ActualTerm__c == null || lineItem.ActualTerm__c == 0)
				lineItem.ActualTerm__c = 365;

			//
			// Determine the proper term
			//
			
			if (lineItem.ActualTerm__c == 30)
				lineItem.ActualEndDate__c = lineItem.ActualStartDate__c.AddMonths (1);
			else if (lineItem.ActualTerm__c == 60)
				lineItem.ActualEndDate__c = lineItem.ActualStartDate__c.AddMonths (2);
			else if (lineItem.ActualTerm__c == 90)
				lineItem.ActualEndDate__c = lineItem.ActualStartDate__c.AddMonths (3);
			else if (lineItem.ActualTerm__c == 1065)
				lineItem.ActualEndDate__c = lineItem.ActualStartDate__c.AddMonths (35);
			else if (lineItem.ActualTerm__c == 365)
				lineItem.ActualEndDate__c = lineItem.ActualStartDate__c.AddYears (1);
			else if (lineItem.ActualTerm__c == 730)
				lineItem.ActualEndDate__c = lineItem.ActualStartDate__c.AddYears (2);
			else if (lineItem.ActualTerm__c == 1095)
				lineItem.ActualEndDate__c = lineItem.ActualStartDate__c.AddYears (3);
			else if (lineItem.ActualTerm__c == 1099)
				lineItem.ActualEndDate__c = lineItem.ActualStartDate__c.AddYears (3).AddDays (4);
			else if (lineItem.ActualTerm__c == 1460)
				lineItem.ActualEndDate__c = lineItem.ActualStartDate__c.AddYears (4);
			else if (lineItem.ActualTerm__c == 1825)
				lineItem.ActualEndDate__c = lineItem.ActualStartDate__c.AddYears (5);
			else // simply add the specific number of days 
				 // this is so stupid, don't blame me, blame salesforce.
				lineItem.ActualEndDate__c = lineitem.ActualStartDate__c.addDays (Integer.valueOf (String.valueOf (lineItem.ActualTerm__c.round ())));
				
			//
			// Start to end dates are not inclusive, remove one day
			//
			
			lineItem.ActualEndDate__c -= 1;
		}
		
		System.debug ('- Actual End Date = ' + lineItem.ActualEndDate__c);

		// 
		// Calculate the number of leap days in the period
		//
		
		Integer leapDays = Util.leapDays(lineItem.ActualStartDate__c, lineItem.ActualEndDate__c);
		System.debug ('- Calculated Leap Days = ' + leapDays);
		
		//
		// Recalculate the term using using the true number of days then add an extra day to be inclusive.
		//

		lineItem.ActualTerm__c = lineItem.ActualStartDate__c.DaysBetween (lineItem.ActualEndDate__c);
		lineItem.ActualTerm__c ++;
		
		System.debug ('- Actual Term = ' + lineItem.ActualTerm__c);

		//
		// In order to amortize correct annual amounts, we need to try and match up the original
		// term with complete years. Otherwise, we get rounding errors that end up rolling a
		// (for example) 3-year contract into 3 years plus a few dollars in year 4. 
		//
		// This step only applies to true 1, 2, 3, 4, or 5 year terms.
		//
		
		// assigning perDiem value using divide method so that the precision can be set to match 
		// the calculations within the data warehouse.

		Decimal perDiem = totalPrice;
		
		//
		// throw a friendly error when the actual term is 0, otherwise a divide by 0
		// exception is thrown
		//
		
		if(lineItem.ActualTerm__c <= leapDays) {
			lineItem.addError('Actual Start Date must be less than Actual End Date');
			continue;
		}
		
		perDiem = perDiem.divide((lineItem.ActualTerm__c - leapDays), 10);
		
		Decimal perYear = null;

		if  (lineItem.ActualTerm__c == (365 + leapDays))
			perYear = totalPrice;
		else if (lineItem.ActualTerm__c == (730 + leapDays))
			perYear = totalPrice / 2;
		else if (lineItem.ActualTerm__c == (1095 + leapDays))
			perYear = totalPrice / 3;
		else if (lineItem.ActualTerm__c == (1460 + leapDays))
			perYear = totalPrice / 4;
		else if (lineItem.ActualTerm__c == (1825 + leapDays))
			perYear = totalPrice / 5;
		else // simply calculate perYear based on perDiem and exact days per year.
			perYear = perDiem * 365;

		System.debug ('- Total Price = ' + totalPrice);	
		System.debug ('- Per Year = ' + perYear);	
		System.debug ('- Per Diem = ' + perDiem);

		//
		// Start with the full total price and decrement from there
		//
		
		Decimal remainingAmount = totalPrice; 
		
		System.debug ('- Initial Remaining Amount = ' + remainingAmount);

		// 
		// Working amount requirements:
		//
		// - If the actual start date is earlier than the close date + 1, then we need to
		//   begin our first year allocation with the perDiem * extra days prior to the
		//   close date. This might happen if the data loader puts in a contract that is
		//   already in progress, even thought the deal wasn't technically closed until
		//   after the start date. Unusual, yes, but this scenario is the inverse of the
		//   delayed contract scenario below.
		//
		// - Otherwise (in the common case), the workingAmount starts at zero.
		//
		
		Decimal workingAmount = 0;
		System.debug (' - Opportunity Close Date = ' + lineItem.OpportunityCloseDate__c);	
   
	   
		if (lineItem.ActualStartDate__c < lineItem.OpportunityCloseDate__c.addDays(1)) {
			
			// NOTE: The daysBetween method is not inclusive, remove a day from actual start date.
			//	  Creating a new variable so the actual start date is not adjusted when the 
			//	  product is persisted.
			
			Date actualStartDate = lineItem.ActualStartDate__c;
			actualStartDate -= 1;
			
			//
			// Determine if the dates in a delayed contract (span between the actual start date, and the close date) contains any leap days. 
			// subtract the leap days from the working amount calculation
			// 
			//
			
			Integer delayedLeapDays = Util.leapDays(lineItem.ActualStartDate__c, lineItem.OpportunityCloseDate__c.addDays(1));
			System.debug ('- Delayed Contract Leap Days = ' + delayedLeapDays);
						
			workingAmount = perDiem * (actualStartDate.daysBetween(lineItem.OpportunityCloseDate__c) - delayedLeapDays);
		}
		
		System.debug ('- Initial Working Amount = ' + workingAmount);
		
		//
		// Working date requirements:
		//
		// - If the close date + 1 day is earlier than the start date, we have a delayed
		//   contract / line item, and we should start scheduling from the close date.
		//
		// - Otherwise, if the close date + 1 day is equal or later than the start date, we
		//   should use the actual start date to begin accounting.
		//
		
		Date workingDate = lineItem.ActualStartDate__c;

		if (lineItem.OpportunityCloseDate__c.addDays(1) < lineItem.ActualStartDate__c)
			workingDate = lineItem.OpportunityCloseDate__c.addDays(1);
			
		Integer startingYear = workingDate.year ();
			
		System.debug ('- Initial Working Date = ' + workingDate);
		System.debug ('- Starting Year = ' + startingYear);

		//
		// Keep looping as long as there are funds left to allocate
		//
		
		while (remainingAmount != 0) {
			//
			// Allocation of funds:
			//
			// - If the current working date + 1 year is past the deadline, then need to 
			//   allocate all of the remaining funds this cycle.
			// 

			if (workingDate.addYears (1) > lineItem.ActualEndDate__c) {
				workingAmount += remainingAmount;
				System.debug(' - Path 1 WorkingAmount ' + workingAmount);
			}

			// - If the current working year is the starting year plus 5, then we've arrived
			//   at the maximum of 6 scheduled booking years, and any remaining funds must
			//   be allocated in this cycle.
			//

			else if (workingDate.year () >= startingYear + 5) {
				workingAmount += remainingAmount;
				System.debug(' - Path 2 WorkingAmount ' + workingAmount);
			}

			// - If the current working date + 1 year is before the start date, then this is 
			//   a long-term delayed contract, and we shouldn't allocate any funds for this 
			//   schedule year.
			//

			else if (workingDate.addYears (1) < lineItem.ActualStartDate__c) {
				workingAmount += 0;
				System.debug(' - Path 3 WorkingAmount ' + workingAmount);
			}

			// - If the current working date is before the start date, but by less than a 
			//   full year, then only allocate the correct number of days between the actual
			//   start date and the working date + 1 year. 
			//

			else if (workingDate < lineItem.ActualStartDate__c) {
				 
				// NOTE: The daysBetween method is not inclusive, remove a day from actual start date.
				//	  Creating a new variable so the actual start date is not adjusted when the 
				//	  product is persisted.
			
				Date actualStartDate = lineItem.ActualStartDate__c;
				actualStartDate -= 1;
				
				// NOTE: There may be leap days in the date ranges we are comparing when calculating the working amount
				//	  We want to exclude any leap days
				//
				
				Integer delayedLeapDays = Util.leapDays(lineItem.ActualStartDate__c, workingDate.addYears(1));
				System.debug(' - Delayed leap Days ' + delayedLeapDays);
								
				workingAmount += perDiem * actualStartDate.daysBetween (workingDate.addYears(1) - delayedLeapDays);
				System.debug(' - Path 4 WorkingAmount ' + workingAmount);
			}	
		   
			// - Otherwise, since we have at least a full year and then some left, and westartDate
			//   are not at the last year 6 schedule, we allocate only a full year's worth of funds.
			//

			else {
				//
				// - In the first year we need to allocate funds for the close date + 1 day + 365 days, 
				//   The perYear calculation is based on 365 days. adding perDiem to the perYear amount
				//
				
				if (workingDate.year() == startingYear) {
					workingAmount += (perYear + perDiem);
					System.debug(' - Path 5 WorkingAmount ' + workingAmount);
				}
				else {
					workingAmount += perYear;
					System.debug(' - Path 6 WorkingAmount ' + workingAmount);
				}
			
			}
			// NOTE: Normally, the working amount is equal to 0, so the += of funds is equivilent
			//   to simply assigning the funds amount. However, in the case where the actual start
			//   start is earlier than the opportunity close date, the first year working amount 
			//   will be larger than 0 because we prepend the perDiem * days before the 
			//   opportunity close date.
			//
			// In addition (for that scenario) the last year amount will be less than normal as well.
			//
			
			// NOTE: Using the absolute value of remainingAmount and workingAmount so that the comparison below
			//   behaves as intended when dealing with a negative totalPrice
			
			if (math.abs(remainingAmount) < math.abs(workingAmount)) {
				workingAmount = remainingAmount;
				System.debug(' - Path 7 WorkingAmount ' + workingAmount);
			}
						 
			System.debug ('- Applying To Working Year = ' + workingDate.year ());
			System.debug ('- - Working Date = ' + workingDate);
			System.debug ('- - Working Amount = ' + workingAmount);			
			System.debug ('- - Remaining Amount = ' + remainingAmount);
			System.debug ('- - Year Number = ' + (workingDate.year () - startingYear + 1));
			
			//
			// Allocate to a schedule year
			//
			
			if (workingDate.year () == startingYear)
				lineItem.Year1Amount__c = workingAmount;
			else if (workingDate.year () == startingYear + 1)
				lineItem.Year2Amount__c = workingAmount;
			else if (workingDate.year () == startingYear + 2)
				lineItem.Year3Amount__c = workingAmount;
			else if (workingDate.year () == startingYear + 3)
				lineItem.Year4Amount__c = workingAmount;
			else if (workingDate.year () == startingYear + 4)
				lineItem.Year5Amount__c = workingAmount;
			else if (workingDate.year () == startingYear + 5)
				lineItem.Year6Amount__c = workingAmount;
			else
				System.assert (false); // Should have allocated all remaining funds for year 6.
				
			//
			// Reduce the remaining amount accordingly. 
			//
			
			remainingAmount -= workingAmount;
			
			System.debug ('- - Remaining Amount After Reduction = ' + remainingAmount);

			//
			// Increment the working year for the next sweep (if needed)
			//
			
			workingDate = workingDate.addYears (1);
			
			//
			// Reset the working amount to 0
			//
			
			workingAmount = 0;
		}
	}
*/
}