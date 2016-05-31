/*
* Name : NFRUtil
* Author : Rohit Mehta
* Date : 03222010
* Usage : Util class Used by the NFR Classes/Triggers
*/
public without sharing class NFRUtil {

	public static Boolean hasChanges(String field, SObject oldRecord, SObject newRecord) {
		if (oldRecord == null) {
			return true;
		}
		return (oldRecord.get(field) != newRecord.get(field));

	}

	public static Map<String, Map<Id, PricebookEntry>> getPricebookEntries(Set<Id> productIds,
		Id pricebookId, Set<String> currencyCodes)
	{
		Map<String, Map<Id, PricebookEntry>> pb_prod_pbe_Map = new Map<String, Map<Id, PricebookEntry>>();
		List<PricebookEntry> pricebookEntries = [Select p.Product2Id, p.CurrencyIsoCode, p.Pricebook2Id, p.IsActive, p.Id, p.UnitPrice
			From PricebookEntry p
			where p.IsActive = true and p.Product2Id In :productIds And p.Pricebook2Id = :pricebookId
			And CurrencyIsoCode In :currencyCodes]; //

		for (PricebookEntry pbe : pricebookEntries) {
			String currencyCode = pbe.CurrencyIsoCode;
			Map<Id, PricebookEntry> prod_pbeMap = pb_prod_pbe_Map.get(currencyCode);
			if (prod_pbeMap == null) {
				prod_pbeMap = new Map<Id, PricebookEntry>();
				pb_prod_pbe_Map.put(currencyCode, prod_pbeMap);
			}
			prod_pbeMap.put(pbe.Product2Id, pbe);
		}
		return pb_prod_pbe_Map;
	}

	public static Boolean compare(String a, String b) {
		if (a == null ||  b == null) {
			return false;
		}
		return (a.equalsIgnoreCase(b));
	}

	public static Id getNfrRT() {
		return [Select Id from RecordType where Name = 'NFR Opportunity' And SObjectType = 'Opportunity'].Id;
	}

	public static Id getDefaultPriceBook() {
		return [Select Id from Pricebook2 where Name = 'Global Price Book' limit 1].Id;
		//return [Select Id from Pricebook2 where Name = 'Standard Price Book' limit 1].Id;
	}

}