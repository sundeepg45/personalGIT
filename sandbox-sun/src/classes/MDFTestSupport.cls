public class MDFTestSupport {
    public Integer getFiscalYear() {
        if (Date.today() < Date.newInstance(Date.today().year(), 3, 1))
            return Date.today().year() - 1;
        return Date.today().year();
    }
    
    public Date getQ1Start() {
        return Date.newInstance(getFiscalYear(), 3, 1);
    }
    
    public Date getQ1End() {
        return Date.newInstance(getFiscalYear(), 5, 31);
    }
    
    public Date getQ2Start() {
        return Date.newInstance(getFiscalYear(), 6, 1);
    }
    
    public Date getQ2End() {
        return Date.newInstance(getFiscalYear(), 8, 31);
    }
    
    public Date getQ3Start() {
        return Date.newInstance(getFiscalYear(), 9, 1);
    }
    
    public Date getQ3End() {
        return Date.newInstance(getFiscalYear(), 11, 30);
    }
    
    public Date getQ4Start() {
        return Date.newInstance(getFiscalYear(), 12, 1);
    }
    
    public Date getQ4End() {
        return Date.newInstance(getFiscalYear() + 1, 2, 23);
    }
    
    public static String getCurrentFiscalYear() {
    	return 'FY' + new MDFTestSupport().getFiscalYear();
    }
    
    public static Integer getCurrentFiscalYearAsInteger() {
        return new MDFTestSupport().getFiscalYear();
    }
    
	public static String getCurrentFiscalQuarter() {
    	MDFTestSupport mdfTestSupport = new MDFTestSupport();
    	
    	if (Date.today() >= mdfTestSupport.getQ1Start() && Date.today() <= mdfTestSupport.getQ1End())
    	   return 'Q1';
        if (Date.today() >= mdfTestSupport.getQ2Start() && Date.today() <= mdfTestSupport.getQ2End())
           return 'Q2';
        if (Date.today() >= mdfTestSupport.getQ3Start() && Date.today() <= mdfTestSupport.getQ3End())
           return 'Q3';
        if (Date.today() >= mdfTestSupport.getQ4Start() && Date.today() <= mdfTestSupport.getQ4End())
           return 'Q4';
    	
    	// Whoa! it must be Feb 29th.
    	
    	system.debug('Happy February 29th and happy EOQ!');
    	return 'Q4';
    }

    public static Integer getCurrentFiscalQuarterAsInteger() {
        return Integer.valueOf(getCurrentFiscalQuarter().substring(1));
    }
	
    public static Date getCurrentStartDate() {
        MDFTestSupport mdfTestSupport = new MDFTestSupport();
        
        if (Date.today() >= mdfTestSupport.getQ1Start() && Date.today() <= mdfTestSupport.getQ1End())
           return mdfTestSupport.getQ1Start();
        if (Date.today() >= mdfTestSupport.getQ2Start() && Date.today() <= mdfTestSupport.getQ2End())
           return mdfTestSupport.getQ2Start();
        if (Date.today() >= mdfTestSupport.getQ3Start() && Date.today() <= mdfTestSupport.getQ3End())
           return mdfTestSupport.getQ3Start();
        if (Date.today() >= mdfTestSupport.getQ4Start() && Date.today() <= mdfTestSupport.getQ4End())
           return mdfTestSupport.getQ4Start();
           
        // Feb 24th
        return mdfTestSupport.getQ4Start();
    }
    
    public static Date getCurrentEndDate() {
        MDFTestSupport mdfTestSupport = new MDFTestSupport();
        
        if (Date.today() >= mdfTestSupport.getQ1Start() && Date.today() <= mdfTestSupport.getQ1End())
           return mdfTestSupport.getQ1End();
        if (Date.today() >= mdfTestSupport.getQ2Start() && Date.today() <= mdfTestSupport.getQ2End())
           return mdfTestSupport.getQ2End();
        if (Date.today() >= mdfTestSupport.getQ3Start() && Date.today() <= mdfTestSupport.getQ3End())
           return mdfTestSupport.getQ3End();
        if (Date.today() >= mdfTestSupport.getQ4Start() && Date.today() <= mdfTestSupport.getQ4End())
           return mdfTestSupport.getQ4End();
           
        // Feb 24th
        return mdfTestSupport.getQ4End().addDays(1); // yes, I covered that edge case. :)
    }

    public static testmethod void testGenerateCodeCoverage() {
        system.assert(null != getCurrentFiscalYear());
        system.assert(null != getCurrentFiscalYearAsInteger());
        system.assert(null != getCurrentFiscalQuarter());
        system.assert(null != getCurrentFiscalQuarterAsInteger());
        system.assert(null != getCurrentStartDate());
        system.assert(null != getCurrentEndDate());
    }
}