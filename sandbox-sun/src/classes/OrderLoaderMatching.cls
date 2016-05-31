/**
 * Matching logic for Opportunity Staging records created by the Order Loader tool.
 *
 * @version 2015-03-14
 * @author Scott Coleman <scoleman@redhat.com>
 * 2015-03-14 - Created
 */
public without sharing class OrderLoaderMatching {
    public static void processOrders(Set<Id> headerIds) {
        // get header records with lines and partners
        List<Opportunity_Header_Staging__c> headers = Order_Opportunity_Matching.queryOrders(headerIds);

        // get CDH party numbers to help find matching Salesforce accounts
        Set<String> cdhAccountPartyNumbers = getCDHAccountPartyNumbers(headers);

        // build account maps. exclude accounts if more than one is found for a given CDH party.
        Map<String, Account> accountMap = new Map<String, Account>();
        String cdhPartyNumber = '';
        String cdhPartyNumberPartner = '';
        for(Account account : [
            SELECT 
                Id, 
                CDHPartyNumber__c, 
                RecordType.Name 
            FROM Account 
            WHERE CDHPartyNumber__c IN :cdhAccountPartyNumbers 
            ORDER BY CDHPartyNumber__c, RecordType.Name]) {

            if(account.RecordType.Name.contains('Partner')) {
                if(account.CDHPartyNumber__c == cdhPartyNumberPartner) {
                    accountMap.remove(account.CDHPartyNumber__c + 'P');
                }
                else {
                    accountMap.put(account.CDHPartyNumber__c + 'P', account);
                }
                cdhPartyNumberPartner = account.CDHPartyNumber__c;
            }
            else {                
                if(account.CDHPartyNumber__c == cdhPartyNumber) {
                    accountMap.remove(account.CDHPartyNumber__c);
                }
                else {
                    accountMap.put(account.CDHPartyNumber__c, account);
                }
                cdhPartyNumber = account.CDHPartyNumber__c;
            }
        }

        // where we found a single matching account, add it to the header
        List<Opportunity_Header_Staging__c> updatedHeaders = new List<Opportunity_Header_Staging__c>();
        List<Opportunity_Line_Staging__c> updatedLines = new List<Opportunity_Line_Staging__c>();
        List<Opportunity_Partner_Staging__c> updatedPartners = new List<Opportunity_Partner_Staging__c>();
        Set<Id> accountIds = new Set<Id>();

        for(Opportunity_Header_Staging__c header : headers) {
            Boolean updateHeader = false;

            if(accountMap.keySet().contains(header.Bill_To_CDH_Party_Number_Account__c)) {
                header.Bill_To_Sales_Account__c = accountMap.get(header.Bill_To_CDH_Party_Number_Account__c).Id;
                header.Bill_To_Sales_Account__r = accountMap.get(header.Bill_To_CDH_Party_Number_Account__c);
                accountIds.add(header.Bill_To_Sales_Account__c);
                updateHeader = true;
            }

            if(accountMap.keySet().contains(header.Ship_To_CDH_Party_Number_Account__c)) {
                header.Ship_To_Sales_Account__c = accountMap.get(header.Ship_To_CDH_Party_Number_Account__c).Id;
                header.Ship_To_Sales_Account__r = accountMap.get(header.Ship_To_CDH_Party_Number_Account__c);
                accountIds.add(header.Ship_To_Sales_Account__c);
                updateHeader = true;
            }

            if(accountMap.keySet().contains(header.Sold_To_CDH_Party_Number_Account__c)) {
                header.Sold_To_Sales_Account__c = accountMap.get(header.Sold_To_CDH_Party_Number_Account__c).Id;
                header.Sold_To_Sales_Account__r = accountMap.get(header.Sold_To_CDH_Party_Number_Account__c);
                accountIds.add(header.Sold_To_Sales_Account__c);
                updateHeader = true;
            }

            if(accountMap.keySet().contains(header.Entitle_To_CDH_Party_Number_Account__c)) {
                header.Entitle_To_Sales_Account__c = accountMap.get(header.Entitle_To_CDH_Party_Number_Account__c).Id;
                header.Entitle_To_Sales_Account__r = accountMap.get(header.Entitle_To_CDH_Party_Number_Account__c);
                accountIds.add(header.Entitle_To_Sales_Account__c);
                updateHeader = true;
            }

            for(Opportunity_Line_Staging__c line : header.Opportunities_Line_Staging__r) {
                if(accountMap.keySet().contains(line.Entitle_To_CDH_Party_Number_Account__c)) {
                    line.Entitle_To_Sales_Account__c = accountMap.get(line.Entitle_To_CDH_Party_Number_Account__c).Id;
                    line.Entitle_To_Sales_Account__r = accountMap.get(line.Entitle_To_CDH_Party_Number_Account__c);
                    accountIds.add(line.Entitle_To_Sales_Account__c);
                    updatedLines.add(line);
                    updateHeader = true;
                }
            }

            for(Opportunity_Partner_Staging__c partner : header.Opportunities_Partner_Staging__r) {
                if(accountMap.keySet().contains(partner.CDH_Party_Number__c + 'P')) {
                    partner.Partner_Sales_Account__c = accountMap.get(partner.CDH_Party_Number__c + 'P').Id;
                    partner.Partner_Sales_Account__r = accountMap.get(partner.CDH_Party_Number__c + 'P');
                    accountIds.add(partner.Partner_Sales_Account__c);
                    updatedPartners.add(partner);
                    updateHeader = true;
                }
            }

            if(updateHeader) {
                updatedHeaders.add(header);
            }

        }

        // where we were able to find a single matching sales account, attempt to set Address, Contact, and EBS Account references as well
        // get key sets
        Set<String> cdhPartySiteNumbers = getCDHPartySiteNumbers(updatedHeaders);
        Set<String> cdhContactPartyNumbers = getCDHContactPartyNumbers(updatedHeaders);
        Set<String> ebsAccountNumbers = getEBSAccountNumbers(updatedHeaders);

        // build maps
        Map<Id, Map<String, Address__c>> addressMap = new Map<Id, Map<String, Address__c>>();
        Map<Id, Map<String, Contact>> contactMap = new Map<Id, Map<String, Contact>>();
        Map<Id, Map<String, EBS_Account__c>> ebsAccountMap = new Map<Id, Map<String, EBS_Account__c>>();
        for(Account account : [
            SELECT 
                Id,
                (SELECT Id, CDH_Party_Site_Number__c FROM Addresses__r WHERE CDH_Party_Site_Number__c IN :cdhPartySiteNumbers),
                (SELECT Id, CDH_Party__r.Name FROM Contacts WHERE CDH_Party__r.Name IN :cdhContactPartyNumbers),
                (SELECT Id, EBS_Party_Number__c FROM EBS_Account__r WHERE EBS_Party_Number__c IN :ebsAccountNumbers)
            FROM Account 
            WHERE Id IN :accountIds]) {

            for(Address__c address : account.Addresses__r) {
                if(!addressMap.keySet().contains(account.Id)) {
                    addressMap.put(account.Id, new Map<String, Address__c>{address.CDH_Party_Site_Number__c => address});
                }
                else {
                    addressMap.get(account.Id).put(address.CDH_Party_Site_Number__c, address);
                }
            }

            for(Contact contact : account.Contacts) {
                if(!contactMap.keySet().contains(account.Id)) {
                    contactMap.put(account.Id, new Map<String, Contact>{contact.CDH_Party__r.Name => contact});
                }
                else {
                    contactMap.get(account.Id).put(contact.CDH_Party__r.Name, contact);
                }
            }

            for(EBS_Account__c ebsAccount : account.EBS_Account__r) {
                if(!ebsAccountMap.keySet().contains(account.Id)) {
                    ebsAccountMap.put(account.Id, new Map<String, EBS_Account__c>{ebsAccount.EBS_Party_Number__c => ebsAccount});
                }
                else {
                    ebsAccountMap.get(account.Id).put(ebsAccount.EBS_Party_Number__c, ebsAccount);
                }
            }
        }

        // set Address, Contact, and EBS Account references
        for(Opportunity_Header_Staging__c header : updatedHeaders) {
            if(header.Bill_To_Sales_Account__c != null) {
                if(addressMap.keySet().contains(header.Bill_To_Sales_Account__c)) {
                    Address__c address = addressMap.get(header.Bill_To_Sales_Account__c).get(header.Bill_To_Address_CDH_Party_Site_Number__c);
                    if(address != null) {
                        header.Bill_To_Address__c = address.Id;
                    }
                }
                if(contactMap.keySet().contains(header.Bill_To_Sales_Account__c)) {
                    Contact contact = contactMap.get(header.Bill_To_Sales_Account__c).get(header.Bill_To_CDH_Party_Number__c);
                    if(contact != null) {
                        header.Bill_To_Contact__c = contact.Id;
                    }
                }
                if(ebsAccountMap.keySet().contains(header.Bill_To_Sales_Account__c)) {
                    EBS_Account__c account = ebsAccountMap.get(header.Bill_To_Sales_Account__c).get(header.Bill_To_Account_Number__c);
                    if(account != null) {
                        header.Bill_To_Account__c = account.Id;
                    }
                }
            }

            if(header.Ship_To_Sales_Account__c != null) {
                if(addressMap.keySet().contains(header.Ship_To_Sales_Account__c)) {
                    Address__c address = addressMap.get(header.Ship_To_Sales_Account__c).get(header.Ship_To_Address_CDH_Party_Site_Number__c);
                    if(address != null) {
                        header.Ship_To_Address__c = address.Id;
                    }
                }
                if(contactMap.keySet().contains(header.Ship_To_Sales_Account__c)) {
                    Contact contact = contactMap.get(header.Ship_To_Sales_Account__c).get(header.Ship_To_CDH_Party_Number__c);
                    if(contact != null) {
                        header.Ship_To_Contact__c = contact.Id;
                    }
                }
                if(ebsAccountMap.keySet().contains(header.Ship_To_Sales_Account__c)) {
                    EBS_Account__c account = ebsAccountMap.get(header.Ship_To_Sales_Account__c).get(header.Ship_To_Account_Number__c);
                    if(account != null) {
                        header.Ship_To_Account__c = account.Id;
                    }
                }
            }

            if(header.Sold_To_Sales_Account__c != null) {
                if(addressMap.keySet().contains(header.Sold_To_Sales_Account__c)) {
                    Address__c address = addressMap.get(header.Sold_To_Sales_Account__c).get(header.Sold_To_Address_CDH_Party_Site_Number__c);
                    if(address != null) {
                        header.Sold_To_Address__c = address.Id;
                    }
                }
                if(contactMap.keySet().contains(header.Sold_To_Sales_Account__c)) {
                    Contact contact = contactMap.get(header.Sold_To_Sales_Account__c).get(header.Sold_To_CDH_Party_Number__c);
                    if(contact != null) {
                        header.Sold_To_Contact__c = contact.Id;
                    }
                }
                if(ebsAccountMap.keySet().contains(header.Sold_To_Sales_Account__c)) {
                    EBS_Account__c account = ebsAccountMap.get(header.Sold_To_Sales_Account__c).get(header.Sold_To_Account_Number__c);
                    if(account != null) {
                        header.Sold_To_Account__c = account.Id;
                    }
                }
            }

            if(header.Entitle_To_Sales_Account__c != null) {
                if(addressMap.keySet().contains(header.Entitle_To_Sales_Account__c)) {
                    Address__c address = addressMap.get(header.Entitle_To_Sales_Account__c).get(header.Entitle_To_Address_CDH_Party_Site_Number__c);
                    if(address != null) {
                        header.Entitle_To_Address__c = address.Id;
                    }
                }
                if(contactMap.keySet().contains(header.Entitle_To_Sales_Account__c)) {
                    Contact contact = contactMap.get(header.Entitle_To_Sales_Account__c).get(header.Entitle_To_CDH_Party_Number__c);
                    if(contact != null) {
                        header.Entitle_To_Contact__c = contact.Id;
                    }
                }
                if(ebsAccountMap.keySet().contains(header.Entitle_To_Sales_Account__c)) {
                    EBS_Account__c account = ebsAccountMap.get(header.Entitle_To_Sales_Account__c).get(header.Entitle_To_Account_Number__c);
                    if(account != null) {
                        header.Entitle_To_Account__c = account.Id;
                    }
                }
            }

            for(Opportunity_Line_Staging__c line : header.Opportunities_Line_Staging__r) {
                if(line.Entitle_To_Sales_Account__c != null) {
                    if(addressMap.keySet().contains(line.Entitle_To_Sales_Account__c)) {
                        Address__c address = addressMap.get(line.Entitle_To_Sales_Account__c).get(line.Entitle_To_CDH_Party_Site_Number__c);
                        if(address != null) {
                            line.Entitle_To_Address__c = address.Id;
                        }
                    }
                    if(contactMap.keySet().contains(line.Entitle_To_Sales_Account__c)) {
                        Contact contact = contactMap.get(line.Entitle_To_Sales_Account__c).get(line.Entitle_To_CDH_Party_Number__c);
                        if(contact != null) {
                            line.Entitle_To_Contact__c = contact.Id;
                        }
                    }
                    if(ebsAccountMap.keySet().contains(line.Entitle_To_Sales_Account__c)) {
                        EBS_Account__c account = ebsAccountMap.get(line.Entitle_To_Sales_Account__c).get(line.Entitle_To_Account_Number__c);
                        if(account != null) {
                            line.Entitle_To_Account__c = account.Id;
                        }
                    }
                }
            }

            for(Opportunity_Partner_Staging__c partner : header.Opportunities_Partner_Staging__r) {
                if(partner.Partner_Sales_Account__c != null) {
                    if(contactMap.keySet().contains(partner.Partner_Sales_Account__c)) {
                        Contact contact = contactMap.get(partner.Partner_Sales_Account__c).get(partner.Partner_Contact_CDH_Party_Number__c);
                        if(contact != null) {
                            partner.Partner_Contact__c = contact.Id;
                        }
                    }
                }
            }
        }

        if(!updatedHeaders.isEmpty()) {
            Database.update(updatedHeaders, false);
        }

        if(!updatedLines.isEmpty()) {
            Database.update(updatedLines, false);
        }

        if(!updatedPartners.isEmpty()) {
            Database.update(updatedPartners, false);
        }
    }

    private static Set<String> getCDHAccountPartyNumbers(List<Opportunity_Header_Staging__c> headers) {
        Set<String> cdhPartyNumbers = new Set<String>();

        for(Opportunity_Header_Staging__c header : headers) {
            cdhPartyNumbers.addAll(new Set<String>{
                header.Bill_To_CDH_Party_Number_Account__c,
                header.Ship_To_CDH_Party_Number_Account__c,
                header.Sold_To_CDH_Party_Number_Account__c,
                header.Entitle_To_CDH_Party_Number_Account__c});

            for(Opportunity_Line_Staging__c line : header.Opportunities_Line_Staging__r) {
                cdhPartyNumbers.add(line.Entitle_To_CDH_Party_Number_Account__c);
            }

            for(Opportunity_Partner_Staging__c partner : header.Opportunities_Partner_Staging__r) {
                cdhPartyNumbers.add(partner.CDH_Party_Number__c);
            }
        }

        cdhPartyNumbers.remove(null);
        return cdhPartyNumbers;
    }

    private static Set<String> getCDHContactPartyNumbers(List<Opportunity_Header_Staging__c> headers) {
        Set<String> cdhPartyNumbers = new Set<String>();

        for(Opportunity_Header_Staging__c header : headers) {
            cdhPartyNumbers.addAll(new Set<String>{
                header.Bill_To_CDH_Party_Number__c,
                header.Ship_To_CDH_Party_Number__c,
                header.Sold_To_CDH_Party_Number__c,
                header.Entitle_To_CDH_Party_Number__c});

            for(Opportunity_Line_Staging__c line : header.Opportunities_Line_Staging__r) {
                cdhPartyNumbers.add(line.Entitle_To_CDH_Party_Number__c);
            }

            for(Opportunity_Partner_Staging__c partner : header.Opportunities_Partner_Staging__r) {
                cdhPartyNumbers.add(partner.Partner_Contact_CDH_Party_Number__c);
            }
        }

        cdhPartyNumbers.remove(null);
        return cdhPartyNumbers;
    }

    private static Set<String> getCDHPartySiteNumbers(List<Opportunity_Header_Staging__c> headers) {
        Set<String> cdhPartySiteNumbers = new Set<String>();

        for(Opportunity_Header_Staging__c header : headers) {
            cdhPartySiteNumbers.addAll(new Set<String>{
                header.Bill_To_Address_CDH_Party_Site_Number__c,
                header.Ship_To_Address_CDH_Party_Site_Number__c,
                header.Sold_To_Address_CDH_Party_Site_Number__c,
                header.Entitle_To_Address_CDH_Party_Site_Number__c});

            for(Opportunity_Line_Staging__c line : header.Opportunities_Line_Staging__r) {
                cdhPartySiteNumbers.add(line.Entitle_To_CDH_Party_Site_Number__c);
            }
        }

        cdhPartySiteNumbers.remove(null);
        return cdhPartySiteNumbers;
    }

    private static Set<String> getEBSAccountNumbers(List<Opportunity_Header_Staging__c> headers) {
        Set<String> ebsAccountNumbers = new Set<String>();

        for(Opportunity_Header_Staging__c header : headers) {
            ebsAccountNumbers.addAll(new Set<String>{
                header.Bill_To_Account_Number__c,
                header.Ship_To_Account_Number__c,
                header.Sold_To_Account_Number__c,
                header.Entitle_To_Account_Number__c});

            for(Opportunity_Line_Staging__c line : header.Opportunities_Line_Staging__r) {
                ebsAccountNumbers.add(line.Entitle_To_Account_Number__c);
            }
        }

        ebsAccountNumbers.remove(null);
        return ebsAccountNumbers;
    }
}