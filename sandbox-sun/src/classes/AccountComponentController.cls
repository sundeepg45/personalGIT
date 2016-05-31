/**
 * This class is used by the various components of the account profile show summary
 * page.
 *
 * @author Bill C Riemers <briemers@redhat.com>
 * @version 2013-01-04
 * 2009 - created
 * 2013-01-04 - Updated so we can replace the scontrol with something callable from visual force.
 */
public with sharing class AccountComponentController {

	public static final Date closeDate;
	public static final Date previousFiscalYearStartDate;
	public static final Date previousFiscalYearEndDate;
	
	static {
		Date today = Date.today();
		Integer month = today.month();
		Integer year = today.year();
		Integer [] monthArray = new Integer [] { 3,3,6,6,6,9,9,9,12,12,12,3 };
		Integer [] yearOffsetArray = new Integer [] {1,1,1,1,1,1,1,1,1,1,1,0};
		closeDate = Date.newInstance(year-yearOffsetArray[month-1],monthArray[month-1],1);
		yearOffsetArray = new Integer [] {2,2,1,1,1,1,1,1,1,1,1,1};
		previousFiscalYearStartDate = Date.newInstance(year-yearOffsetArray[month-1],3,1);
		previousFiscalYearEndDate = Date.newInstance(previousFiscalYearStartDate.year()+1,3,1);
	}
	
	public AccountComponentController()
	{	
	}
	
	public AccountComponentController(ApexPages.StandardController stdController)
	{
		this.account = (Account)stdController.getRecord();
	}
	
	public Account account 
	{ 
		set;
		get;
	}
	
	public Boolean needProducts
	{
		set {
			 if(needProducts != value)
			 {
				needProducts = value;
				openOpportunityList = null;
			 }
		}
		get;
	}
	
	public Boolean needSalesTeam
	{
		set {
			if(needSalesTeam != value)
			{
				needSalesTeam = value;
				openOpportunityList = null;
				closedOpportunityList = null;
			}
		}
		get;
	}
	
	public List<Contact> contactList
	{
		set;
		get {
			if(contactList == null)
			{
				contactList = [
					select Email, Name, Phone, Title 
					from Contact 
					where AccountId=:account.Id ];
			}
			return contactList;
		}
	}
	
	public List<Opportunity> closedOpportunityList
	{
		set;
		get {
			if(closedOpportunityList == null)
			{
				if(needSalesTeam)
				{
					closedOpportunityList = [
					  select
						Id,
						Amount,
						CurrencyIsoCode,
						CloseDate,
						Name,
						StageName,
						(select TeamMemberRole, User.Name from OpportunityTeamMembers)
					  from Opportunity 
					  where AccountId=:account.Id and IsClosed=true and CloseDate >= :CloseDate
					  order by Amount desc ];
				}
				else
				{
					closedOpportunityList = [
					  select
						Id,
						Amount,
						CurrencyIsoCode,
						CloseDate,
						Name,
						StageName
					  from Opportunity 
					  where AccountId=:account.Id and IsClosed=true and CloseDate >= :CloseDate
					  order by Amount desc ];
				}
			}
			return closedOpportunityList;
		}
	}

	public List<Opportunity> openOpportunityList
	{
		set;
		get {
			if(openOpportunityList == null)
			{
				if(needProducts)
				{
					if(needSalesTeam)
					{
						openOpportunityList = [
						  select 
							Id,
							Amount, 
							CurrencyIsoCode,
							CloseDate,
							ForecastCategory,
							Name,
							StageName,
							(select TeamMemberRole, User.Name from OpportunityTeamMembers),
							(select 
							   NewOrRenewal__c,
							   PricebookEntryId,
							   Quantity,
							   TotalPrice,
							   UnitPrice,
							   CurrencyIsoCode,
							   PricebookEntry.Name,
							   PricebookEntry.ProductCode 
							 from OpportunityLineItems )
						  from Opportunity
						  where AccountId=:account.Id and IsClosed=false
						  order by Amount desc ];
					}
					else
					{
						openOpportunityList = [
						  select 
							Id,
							Amount, 
							CurrencyIsoCode,
							CloseDate,
							ForecastCategory,
							Name,
							StageName,
							(select 
							   NewOrRenewal__c,
							   PricebookEntryId,
							   Quantity,
							   TotalPrice,
							   UnitPrice,
							   CurrencyIsoCode,
							   PricebookEntry.Name,
							   PricebookEntry.ProductCode 
							 from OpportunityLineItems )
						  from Opportunity
						  where AccountId=:account.Id and IsClosed=false
						  order by Amount desc ];
					}
				}
				else if(needSalesTeam)
				{
					openOpportunityList = [
					  select 
						Id,
						Amount, 
						CurrencyIsoCode,
						CloseDate,
						ForecastCategory,
						Name,
						StageName,
						(select TeamMemberRole, User.Name from OpportunityTeamMembers)
					  from Opportunity
					  where AccountId=:account.Id and IsClosed=false
					  order by Amount desc ];
				}
				else
				{
					openOpportunityList = [
					  select 
						Id,
						Amount, 
						CurrencyIsoCode,
						CloseDate,
						ForecastCategory,
						Name,
						StageName
					  from Opportunity
					  where AccountId=:account.Id and IsClosed=false
					  order by Amount desc ];
				}
			}
			return openOpportunityList;
		}
	}
	
	public List<FiscalYearSummary> previousFiscalYearSummary
	{
		set;
		get {		
			if(previousFiscalYearSummary == null)
			{
				previousFiscalYearSummary = new List<FiscalYearSummary>();
				final List<Opportunity> oppList = [
				  select
					Amount,
					CurrencyIsoCode,
					CloseDate
				  from Opportunity 
				  where 
					AccountId=:account.Id and
					Amount != null and
					IsClosed = true and
					CloseDate >= :previousFiscalYearStartDate and
					CloseDate < :previousFiscalYearEndDate ];
				if(oppList.isEmpty())
				{
					previousFiscalYearSummary.add(new FiscalYearSummary(account.CurrencyIsoCode));
				}
				else
				{
					final Map<String,Integer> m = new Map<String,Integer>();
					for(Opportunity opp : oppList)
					{
						final String isoCode = opp.CurrencyIsoCode;
						final Integer i = m.get(isoCode);
						FiscalYearSummary s;
						if(i == null)
						{
							m.put(isoCode,previousFiscalYearSummary.size());
							previousFiscalYearSummary.add((s = new FiscalYearSummary(isoCode)));
						}
						else
						{
							s = previousFiscalYearSummary.get(i);
						}
						s.add(opp);
					}
				}
			}
			return previousFiscalYearSummary;
		}
	}
	
	public List<AccountTeamMember> accountTeamMemberList
	{
		set;
		get {
			if(accountTeamMemberList == null)
			{
				accountTeamMemberList = [
				  select TeamMemberRole, User.Name 
				  from AccountTeamMember 
				  where AccountId=:account.Id ];
			}
			return accountTeamMemberList;
		}
	}
	
	public Integer accountTeamMemberCount
	{
		get {
			return this.accountTeamMemberList.size();
		}
	}
	
	public class FiscalYearSummary
	{
		private List<Opportunity> oppList = new List<Opportunity>();
		private boolean needUsdTotal = true;
		public FiscalYearSummary(String isoCode)
		{
			currencyIsoCode = isoCode;
			total = 0;
		}
		public void add(Opportunity opp)
		{
			System.assertEquals(opp.CurrencyIsoCode,currencyIsoCode);
			total += opp.Amount;
			oppList.add(opp);
		}
		public Integer count { get { return oppList.size(); } }
		public Decimal total { set; get; }
		public Decimal usdTotal { 
			set; 
			get {
				/*
				 * For now USD totals are not required.
				 *
				if(needUsdTotal)
				{
					needUsdTotal = false;
					if(total == 0 || currencyIsoCode == 'USD')
					{
						usdTotal = total;
					}
					else
					{
						final Integer queriesLeft = Limits.getLimitQueries()-Limits.getQueries();
						if(count < (queriesLeft/2))
						{
							usdTotal = 0;
							final Map<Date,Decimal> m = new Map<Date,Decimal>();
							for(Opportunity opp : oppList)
							{
								Decimal cr = m.get(opp.CloseDate);
								if(cr ==  null)
								{
									List<DatedConversionRate> dcrList = [
									  select
										ConversionRate
									  from DatedConversionRate
									  where IsoCode = :isoCode and
										StartDate <= :opp.CloseDate
									  order by StartDate desc limit 1 ];
									if(! dcrList.isEmpty())
									{
										m.put(opp.CloseDate,(cr = dcrList.get(0).ConversionRate));
									}
								}
								if(cr == null)
								{
									usdTotal = null;
								}
								else
								{
									usdTotal += opp.Amount / cr ;
								}
							}
						}
					} 
				}
				 */
				return usdTotal;
			} 
		}
		public String currencyIsoCode { set; get; }
	}
}