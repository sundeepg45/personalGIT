/*****************************************************************************************
    Name    : IntegrationObjectsDeserializer
    Desc    : The class that deserializes an inbound JSON message and builds domain objects

    Modification Log :
---------------------------------------------------------------------------
    Developer              Date            Description
---------------------------------------------------------------------------
    John Herson            2014-07-11      Created
    Scott Coleman          2014-07-24      Updates to parseSalesAccount()
    Scott Coleman          2014-07-27      Adding Ids array workaround
    Scott Coleman          2014-07-29      Updating order parser
    John Herson            2014-08-01      Added an ID parser to validate Opportunity ID
    John Herson            2014-08-01      Updated some mappings to resolve integration issues
    Scott Coleman          2014-08-01      Updateing transactional account parser
    John Herson            2014-08-02      Added Entitle To Contact and CDH Party Site Number at the Line Level 
    John Herson            2014-08-02      Added Unit Of Measure
    Scott Coleman          2014-09-16      Added support for updated message property naming convention
    Scott Coleman          2014-10-02      Added CDH party number for partners on order and lines
    Scott Coleman          2014-10-09      Added support for PartnerClassifications
    Scott Coleman          2014-10-18      Added support for Product messages
    Scott Coleman          2014-12-11      Mapping partner classification code
    Scott Coleman          2015-03-15      Adding special handling for non-entitled end customers on orders
    Scott Coleman          2015-03-15      Mapping order line id
    Scott Coleman          2015-03-17      Removed hierachy fields from top level of SalesAccount, added new relationships object
    Bill C Riemers         2015-05-01      Modified to parse multiple partner values
    Bill C Riemers         2015-05-06      Change Date Parser to be case insensitive
    Scott Coleman          2015-05-19      Ignore duplicate order lines (lines with same SOLINENUM value)
    Scott Coleman          2015-08-26      US69276 Support for ID arrays (parsing layer only) for CDH Party Merge
    Bill C Riemers         2015-10-15      Changed PARTNRIDX and ONETIME to strings
    Bill C Riemers         2015-10-16      Correct nill string substitution
******************************************************************************************/

public class IntegrationObjectsDeserializer {
    
    public static IntegrationObjects.TransactionalAccount parseTransactionalAccount(String json) {
        MessageIntegrationObjects.TransactionalAccount account = null;

        JSONParser parser = System.JSON.createParser(json);
        
        while (parser.nextToken() != null) {
            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME)) {
                String fieldName = parser.getText();
                parser.nextToken();
                
                if ('TransactionalAccount'.equals(fieldName)) {
                    MessageIntegrationObjects.SimpleTransactionalAccount simpleAccount = (MessageIntegrationObjects.SimpleTransactionalAccount) parser.readValueAs(MessageIntegrationObjects.SimpleTransactionalAccount.class);
                    //downcast from SimpleTransactionalAccount to TransactionalAccount
                    String simpleAccountJSON = System.JSON.serialize(simpleAccount);
                    account = (MessageIntegrationObjects.TransactionalAccount) System.JSON.deserialize(simpleAccountJSON, MessageIntegrationObjects.TransactionalAccount.class); 
                }  
            }
        }
        
        //second pass to get SalesAccount
        if(account != null) {
            parser = System.JSON.createParser(json);
            
            while (parser.nextToken() != null) {
                if ((parser.getCurrentToken() == JSONToken.FIELD_NAME)) {
                    String fieldName = parser.getText();
                    parser.nextToken();

                    if ('SalesAccount'.equals(fieldName)) {
                        if (parser.getCurrentToken() == JSONToken.START_ARRAY) {
                            List<Integer> salesAccounts = (List<Integer>) parser.readValueAs(List<Integer>.class);
                            if(salesAccounts != null && !salesAccounts.isEmpty()) {
                                //TODO: examine whether we need to support multiple Sales Account values on the integration object
                                account.SalesAccount = String.valueOf(salesAccounts[0]);
                            }
                        } else {
                            Integer salesAccount = (Integer) parser.readValueAs(Integer.class);
                            if(salesAccount != null) {
                                account.SalesAccount = String.valueOf(salesAccount);
                            }
                        }
                    }
                }
            }
        }

        IntegrationObjects.TransactionalAccount ioAccount;
        if(account != null) {
            ioAccount = account.getIOTransactionalAccount();
        }
        return ioAccount;        
    }

    public static IntegrationObjects.SalesAccount parseSalesAccount(String json) {
        MessageIntegrationObjects.SalesAccount account = null;
        List<MessageIntegrationObjects.Contact> contacts = null;
        List<MessageIntegrationObjects.Address> addresses = null;
        List<IntegrationObjects.Classification> classifications = null;
        
        JSONParser parser = System.JSON.createParser(replaceIds(json));
        
        while (parser.nextToken() != null) {
            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME)) {
                String fieldName = parser.getText();
                parser.nextToken();
                
                if ('SalesAccount'.equals(fieldName)) {
                    MessageIntegrationObjects.SimpleSalesAccount simpleAccount = (MessageIntegrationObjects.SimpleSalesAccount) parser.readValueAs(MessageIntegrationObjects.SimpleSalesAccount.class);
                    //downcast from SimpleSalesAccount to SalesAccount
                    String simpleAccountJSON = System.JSON.serialize(simpleAccount);
                    account = (MessageIntegrationObjects.SalesAccount) System.JSON.deserialize(simpleAccountJSON, MessageIntegrationObjects.SalesAccount.class);
                }  
            }
        }

        //second pass to get the Addresses
        if(account != null) {
            parser = System.JSON.createParser(replaceIds(json));

            while (parser.nextToken() != null) {
                if ((parser.getCurrentToken() == JSONToken.FIELD_NAME)) {
                    String fieldName = parser.getText();
                    parser.nextToken();

                    if ('Addresses'.equals(fieldName)) {
                        if (parser.getCurrentToken() == JSONToken.START_ARRAY) {
                            addresses = (List<MessageIntegrationObjects.Address>) parser.readValueAs(List<MessageIntegrationObjects.Address>.class); 
                        } else {
                            addresses = new List<MessageIntegrationObjects.Address>();
                            addresses.add((MessageIntegrationObjects.Address) parser.readValueAs(MessageIntegrationObjects.Address.class));
                        }
                        
                        account.Addresses = addresses;
                    }
                    
                    if ('Contacts'.equals(fieldName)) {
                        if (parser.getCurrentToken() == JSONToken.START_ARRAY) {
                            contacts = (List<MessageIntegrationObjects.Contact>) parser.readValueAs(List<MessageIntegrationObjects.Contact>.class);
                        } else {
                            contacts = new List<MessageIntegrationObjects.Contact>();
                            contacts.add((MessageIntegrationObjects.Contact) parser.readValueAs(MessageIntegrationObjects.Contact.class));
                        }
                        
                        account.Contacts = contacts;
                    }

                    if ('PartnerClassifications'.equals(fieldName)) {
                        if (parser.getCurrentToken() == JSONToken.START_ARRAY) {
                            classifications = (List<IntegrationObjects.Classification>) parser.readValueAs(List<IntegrationObjects.Classification>.class);
                        } else {
                            classifications = new List<IntegrationObjects.Classification>();
                            classifications.add((IntegrationObjects.Classification) parser.readValueAs(IntegrationObjects.Classification.class));
                        }

                        account.PartnerClassifications = classifications;
                    }

                    if ('CorporateRelationships'.equals(fieldName)) {
                        account.CorporateRelationships = (MessageIntegrationObjects.Relationships) parser.readValueAs(MessageIntegrationObjects.Relationships.class);
                    }
                }
            }
        }

        IntegrationObjects.SalesAccount ioAccount;
        if(account != null) {
            ioAccount = account.getIOSalesAccount();
        }
        return ioAccount;
    }
    
    public static IntegrationObjects.Contact parseContact(String json) {
        MessageIntegrationObjects.Contact contact = null;
        
        JSONParser parser = System.JSON.createParser(replaceIds(replaceSalesAccountIdArray(json)));
        
        while (parser.nextToken() != null) {
            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME)) {
                String fieldName = parser.getText();
                parser.nextToken();
                
                if ('Contacts'.equals(fieldName)) {
                    contact = new MessageIntegrationObjects.Contact();
                    contact = (MessageIntegrationObjects.Contact) parser.readValueAs(MessageIntegrationObjects.Contact.class);
                }  
            }
        }
        
        IntegrationObjects.Contact ioContact;
        if(contact != null) {
            ioContact = contact.getIOContact();
        }
        return ioContact;
    }
    
    public static IntegrationObjects.Address parseAddress(String json) {
        MessageIntegrationObjects.Address address = null;
        
        JSONParser parser = System.JSON.createParser(replaceIds(json));
        
        while (parser.nextToken() != null) {
            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME)) {
                String fieldName = parser.getText();
                parser.nextToken();
                
                if ('Address'.equals(fieldName)) {
                    address = new MessageIntegrationObjects.Address();
                    address = (MessageIntegrationObjects.Address) parser.readValueAs(MessageIntegrationObjects.Address.class);
                }  
            }
        }
        
        IntegrationObjects.Address ioAddress;
        if(address != null) {
            ioAddress = address.getIOAddress();
        }
        return ioAddress;
    }

    public static IntegrationObjects.Product parseProduct(String json) {
        IntegrationObjects.Product product = null;
        
        JSONParser parser = System.JSON.createParser(json);

        while (parser.nextToken() != null) {
            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME)) {
                String fieldName = parser.getText();
                parser.nextToken();
                
                if ('Product'.equals(fieldName)) {
                    IntegrationObjects.SimpleProduct simpleProduct = (IntegrationObjects.SimpleProduct) parser.readValueAs(IntegrationObjects.SimpleProduct.class);
                    //downcast from SimpleProduct to Product
                    String simpleProductJSON = System.JSON.serialize(simpleProduct);
                    product = (IntegrationObjects.Product) System.JSON.deserialize(simpleProductJSON, IntegrationObjects.Product.class);
                }  
            }
        }

        String debugJSON = System.JSON.serialize(product);
        Map<String, Object> debugMap = (Map<String, Object>)System.JSON.deserializeUntyped(debugJSON);
        for(String key : debugMap.keySet()) {
            System.debug('Product (Field, Value): ' + key + ',' + debugMap.get(key));
        }

        // get attributes array
        List<ProductAttribute> attributes = new List<ProductAttribute>();

        parser = System.JSON.createParser(json);

        while (parser.nextToken() != null) {
            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME)) {
                String fieldName = parser.getText();
                parser.nextToken();        
                if ('Attribute'.equals(fieldName)) {
                    attributes = (List<ProductAttribute>) parser.readValueAs(List<ProductAttribute>.class);
                }
            }
        }

        product.Attribute = new Map<String, String>();
        for(ProductAttribute attribute : attributes) {
            product.Attribute.put(attribute.Code, attribute.Value);
        }

        return product;
    }

    public class ProductAttribute {
        public String Code;
        public String Value;
    }


    
    public static IntegrationObjects.Header parseHeader(String json) {
        IntegrationObjects.Header header = null;
        
        JSONParser parser = System.JSON.createParser(json);
        
        while (parser.nextToken() != null) {
            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME)) {
                String fieldName = parser.getText();
                parser.nextToken();
                
                if ('Header'.equals(fieldName)) {
                    header = new IntegrationObjects.Header();
                    header = (IntegrationObjects.Header) parser.readValueAs(IntegrationObjects.Header.class);
                }  
            }
        }
        
        return header;
    }
    
    @TestVisible
    private static String replaceIds(String json) {
        String regex = '\\"IDs\\"\\s*?\\:\\s*?\\"(.*?)\\"';
        Pattern p = Pattern.compile(regex);
        Matcher m = p.matcher(json);
        while (m.find())
        {
            System.debug(m.group(0));
            System.debug(m.group(1));
            json = json.replaceFirst(regex, '"IDs":["' + m.group(1) + '"]');
        }
        return json;
    }

    @TestVisible
    private static String replaceSalesAccountIdArray(String json) {
        String regex = '\\"SalesAccountId\\"\\s*?\\:\\s*?\\[(.*?)\\]';
        Pattern p = Pattern.compile(regex);
        Matcher m = p.matcher(json);
        while (m.find())
        {
            json = json.replaceFirst(regex, '"SalesAccountId":' + m.group(1).split(',')[0]);
        }
        return json;   
    }

    //public static String replaceIdArray(String json) {
    //    String newJson = json;

    //    List<String> oldMessageText = new List<String>();
    //    List<String> newMessageText = new List<String>();

    //    JSONParser parser = System.JSON.createParser(json);
        
    //    while (parser.nextToken() != null) {
    //        if ((parser.getCurrentToken() == JSONToken.FIELD_NAME)) {
    //            String fieldName = parser.getText();
    //            parser.nextToken();

    //            if ('IDs'.equals(fieldName)) {
    //                if (parser.getCurrentToken() == JSONToken.START_ARRAY) {
    //                    List<String> ids = (List<String>) parser.readValueAs(List<String>.class);
                        
    //                    String oldText = '"IDs":[';
    //                    for(String idValue : ids) {
    //                        if(idValue == null) {
    //                            oldText += 'null,';
    //                        }
    //                        else {
    //                            oldText += '"' + idValue + '",';
    //                        }
    //                    }
    //                    oldText = oldText.left(oldText.length() - 1);
    //                    oldText += ']';

    //                    String newText = '"IDs":';
    //                    if(ids[0] == null) {
    //                        newText += 'null';
    //                    }
    //                    else {
    //                        newText += '"' + ids[0] + '"';
    //                    }

    //                    oldMessageText.add(oldText);
    //                    system.debug('****** oldText: ' + oldText);
    //                    newMessageText.add(newText);
    //                    system.debug('****** newText: ' + newText);
    //                }
    //            }

    //            if ('SalesAccountId'.equals(fieldName)) {
    //                if (parser.getCurrentToken() == JSONToken.START_ARRAY) {
    //                    List<String> ids = (List<String>) parser.readValueAs(List<String>.class);
                        
    //                    String oldText = '"SalesAccountId":[';
    //                    for(String idValue : ids) {
    //                        if(idValue == null) {
    //                            oldText += 'null,';
    //                        }
    //                        else {
    //                            oldText += '"' + idValue + '",';
    //                        }
    //                    }
    //                    oldText = oldText.left(oldText.length() - 1);
    //                    oldText += ']';

    //                    String newText = '"SalesAccountId":';
    //                    if(ids[0] == null) {
    //                        newText += 'null';
    //                    }
    //                    else {
    //                        newText += '"' + ids[0] + '"';
    //                    }

    //                    oldMessageText.add(oldText);
    //                    system.debug('****** oldText: ' + oldText);
    //                    newMessageText.add(newText);
    //                    system.debug('****** newText: ' + newText);
    //                }
    //            }

    //        }
    //    }

    //    if(!oldMessageText.isEmpty()) {
    //        Integer i = 0;
    //        for (String oldText : oldMessageText) {
    //            system.debug('****** replace ' + oldText + ' with ' + newMessageText[i]);
    //            newJson = newJson.replace(oldText,newMessageText[i]);
    //            i = i + 1;
    //        }
    //    }

    //    return newJson;
    //}

    @TestVisible
    private static Date parseDate(String dateText) {
        Date dateValue = null;

        Map<String,Integer> monthMap = new Map<String,Integer>{
            'JAN'=>1,
            'FEB'=>2,
            'MAR'=>3,
            'APR'=>4,
            'MAY'=>5,
            'JUN'=>6,
            'JUL'=>7,
            'AUG'=>8,
            'SEP'=>9,
            'OCT'=>10,
            'NOV'=>11,
            'DEC'=>12};

        try {
            String[] dateParts = dateText.split('-');

            if(dateParts.size() >= 3) {
                Integer day = Integer.valueOf(dateParts[0]);
                Integer month = monthMap.get(dateParts[1].substring(0,3).toUpperCase());
                if(dateParts[2].length() == 2) {
                    dateParts[2] = '20' + dateParts[2];
                }
                Integer year = Integer.valueOf(dateParts[2]);
                dateValue = Date.newInstance(year, month, day);
            }
        }
        catch(Exception ignored) {
           // return null if date can't be parsed
        }
        return dateValue;
    }

    public static String parseId(String idText) {
        if(idText != null) {
            String id = String.escapeSingleQuotes(idText);
            if((id.length() == 15 || id.length() == 18) && Pattern.matches('^[a-zA-Z0-9]*$', id)) {
                return id;
            }
        }
        return null;
    } 

    @TestVisible
    private static void compareTransactionalAccount(
        IntegrationObjects.TransactionalAccount account,
        IntegrationObjects.TransactionalAccount oldValue )
    {
        if(account != null && oldValue != null && (account.Name != oldValue.Name
            || account.Account_Number != oldValue.Account_Number
            || account.EBS_Party_Number != oldValue.EBS_Party_Number
            || account.PartyType != oldValue.partyType
            || account.CDH_Party_Number != oldValue.CDH_Party_Number) )
        {
            throw new PartnerParseException(System.Label.C360_Multiple_Partners);
        }
    }

    private static IntegrationObjects.TransactionalAccount createTransactionalAccount(
        OAGIObjects.PARTNER partner,
        IntegrationObjects.TransactionalAccount oldValue )
    {
        IntegrationObjects.TransactionalAccount account = new IntegrationObjects.TransactionalAccount();
        account.Name = partner.NAME.content;
        account.Account_Number = String.valueOf(partner.PARTNRID);
        account.EBS_Party_Number = partner.PARTNRIDX;
        account.PartyType = partner.DUNSNUMBER;
        account.CDH_Party_Number = partner.ONETIME;
        compareTransactionalAccount(account,oldValue);
        return account;
    }

    @TestVisible
    private static void compareAddress(
        IntegrationObjects.Address address,
        IntegrationObjects.Address oldValue )
    {
        if(address != null && oldValue != null && (address.Zip_Postal_Code != oldValue.Zip_Postal_Code
            || address.Country != oldValue.Country
            || address.County != oldValue.County
            || address.State != oldValue.State
            || address.City != oldValue.City
            || address.Address_Line1 != oldValue.Address_Line1
            || address.Address_Line2 != oldValue.Address_Line2
            || address.Address_Line3 != oldValue.Address_Line3
            || address.Address_Line4 != oldValue.Address_Line4 ) )
        {
            throw new PartnerParseException(System.Label.C360_Multiple_Partners);
        }
    }

    @TestVisible
    private static IntegrationObjects.Address createAddress(
        OAGIObjects.PARTNER partner,
        IntegrationObjects.Address oldValue )
    {
        IntegrationObjects.Address address = new IntegrationObjects.Address();
        address.CDH_Party_Site_Number = partner.CURRENCYISOCODE;
        address.Zip_Postal_Code = String.valueOf(partner.ADDRESS.POSTALCODE);
        address.Country = partner.ADDRESS.COUNTRY;
        address.County = partner.ADDRESS.COUNTY;
        address.State = partner.ADDRESS.STATEPROVN;
        address.City = partner.ADDRESS.CITY;
        address.Address_Line1 = partner.ADDRESS.ADDRLINE[0].content; 
        address.Address_Line2 = partner.ADDRESS.ADDRLINE[1].content; 
        address.Address_Line3 = partner.ADDRESS.ADDRLINE[2].content; 
        address.Address_Line4 = partner.ADDRESS.ADDRLINE[3].content; 
        compareAddress(address,oldValue);
        return address;
    }

    @TestVisible
    private static void compareContact(
        IntegrationObjects.Contact contact,
        IntegrationObjects.Contact oldValue )
    {
        if(contact != null && oldValue != null && (contact.CDH_Party_Number != oldValue.CDH_Party_Number
            || contact.FirstName != oldValue.FirstName
            || contact.LastName != oldValue.LastName
            || contact.Email != oldValue.Email
            || contact.Phone != oldValue.Phone ) )
        {
            throw new PartnerParseException(System.Label.C360_Multiple_Partners);
        }
    }

    private static IntegrationObjects.Contact createContact(
        OAGIObjects.PARTNER partner,
        IntegrationObjects.Contact oldValue )
    {
        IntegrationObjects.Contact contact = new IntegrationObjects.Contact();
        contact.CDH_Party_Number = partner.CONTACT.CONTCTTYPE;
        contact.FirstName = partner.CONTACT.NAME[0].content;
        contact.LastName = partner.CONTACT.NAME[1].content;
        contact.Email = partner.CONTACT.EMAIL;
        contact.Phone = partner.CONTACT.TELEPHONE.content;
        compareContact(contact,oldValue);
        return contact;
    }

    public static IntegrationObjects.Order parseOrder(String json) {
        
       /*
        *
        * initialize order and related objects
        *
        */
        
        IntegrationObjects.Order order = new IntegrationObjects.Order();
        List<IntegrationObjects.OrderLine> orderLines = new List<IntegrationObjects.OrderLine>();
        List<IntegrationObjects.OrderPartner> orderPartners = new List<IntegrationObjects.OrderPartner>();
        
        // replace Salesforce reserved word CURRENCY with CURRENCYISOCODE
        // hack alert.  The following should probably be quoted, at minimum...
        json = json.replace('CURRENCY', 'CURRENCYISOCODE');
        json = json.replace(':""', ':null');
        // hack alert.  It would be possible for white spaces to break the following code.
        // Unfortunately, replaceAll cannot be used with a regular express due to the length of
        // the string.
        json = json.replace('"PARTNER":[','"PARTNERS":[');
        
        // create the JSON parser
        JSONParser parser = System.JSON.createParser(json);
        
       /*
        *
        * start walking through the document
        *
        */ 
        
        while (parser.nextToken() != null) {
            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME)) {
                String fieldName = parser.getText();
                parser.nextToken();
                
               /*
                *
                * process the SENDER of CNTROLAREA section of the document
                *
                */
                
                if ('SENDER'.equals(fieldName)) {
                    OAGIObjects.SENDER sender = (OAGIObjects.SENDER) parser.readValueAs(OAGIObjects.SENDER.class);
                    /*
                    *
                    * parse the REFERENCEID field to see if it is a valid Salesforce ID
                    *
                    */
                    try {
                        order.opportunityId = ID.valueOf(sender.REFERENCEID);
                    } catch (Exception e) {
                        // leave opportunityId null since it is not a valid Salesforce Id
                    }
                }
                
               /*
                *
                * process the POID of SOHEADER section of the document
                *
                */
                
                if ('POID'.equals(fieldName)) {
                    order.opportunityNumber = parser.getText();
                    if(order.opportunityNumber == 'null') {
                        order.opportunityNumber = null;
                    }
                }
                
               /*
                *
                * process the POTYPE of SOHEADER section of the document
                *
                **/
                
                if ('POTYPE'.equals(fieldName)) {
                    order.orderType = parser.getText();
                }
                
               /*
                *
                * process the DESCRIPTN of SOHEADER section of the document
                *
                **/

                if ('DESCRIPTN'.equals(fieldName)) {
                    order.paymentType = parser.getText();
                }

               /*
                *
                * process the PORELEASE of SOHEADER section of the document
                *
                **/
 
                if ('PORELEASE'.equals(fieldName)) {
                    order.orderSource = parser.getText();
                }                

               /*
                *
                * process the OPERAMT of SOHEADER section of the document
                *
                */
                
                if ('OPERAMT'.equals(fieldName)) {
                    OAGIObjects.OPERAMT operamt = (OAGIObjects.OPERAMT) parser.readValueAs(OAGIObjects.OPERAMT.class);
                    if(operamt.VALUE != null) {
                        order.amount = Decimal.valueOf(operamt.VALUE.replace(',',''));
                    }
                    order.currencyIsoCode = operamt.CURRENCYISOCODE;
                }
                                
               /*
                *
                * process the PARTNER section of the document
                *
                */
                                
                if ('PARTNER'.equals(fieldName)||'PARTNERS'.equals(fieldName)) {
                    List<OAGIObjects.PARTNER> partners = null;
                    if (parser.getCurrentToken() == JSONToken.START_ARRAY) {
                        partners = (List<OAGIObjects.PARTNER>) parser.readValueAs(List<OAGIObjects.PARTNER>.class);
                    } else {
                        partners = new List<OAGIObjects.PARTNER>();
                        partners.add((OAGIObjects.PARTNER) parser.readValueAs(OAGIObjects.PARTNER.class));
                    }
                    
                    if (partners != null) {
                        for (OAGIObjects.PARTNER partner : partners) {
                            
                            if ('ADDL_PARTY'.equals(partner.PARTNRTYPE)) {
                                
                                if(partner.DUNSNUMBER == 'Non Entitled Endco') {

                                    order.nonEntitledEndcoCDHPartyName = partner.NAME.content;
                                    order.nonEntitledEndcoCDHPartyNumber = partner.PARTNRIDX;

                                } else {

                                    IntegrationObjects.OrderPartner orderPartner = new IntegrationObjects.OrderPartner();
                                    orderPartner.classificationCode = partner.TERMID;
                                    orderPartner.transactionRole = partner.DUNSNUMBER;
                                    
                                    IntegrationObjects.SalesAccount account = new IntegrationObjects.SalesAccount();
                                    account.Name = partner.NAME.content;
                                    account.CDH_Party_Number = partner.PARTNRIDX;
                                    
                                    orderPartner.account = account;
                                    
                                    IntegrationObjects.Contact contact = new IntegrationObjects.Contact();
                                    contact.CDH_Party_Number = partner.CONTACT.CONTCTTYPE;
                                    contact.FirstName = partner.CONTACT.NAME[0].content;
                                    contact.LastName = partner.CONTACT.NAME[1].content;
                                    contact.Email = partner.CONTACT.EMAIL;
                                    contact.Phone = partner.CONTACT.TELEPHONE.content;
                                    
                                    orderPartner.contact = contact;
                                    
                                    orderPartners.add(orderPartner);

                                }
                                
                            } else if ('BILL-TO'.equals(partner.PARTNRTYPE)) {
                                order.billToAccount = createTransactionalAccount(partner,order.billToAccount);
                                order.billToAddress = createAddress(partner,order.billToAddress);
                                order.billToContact = createContact(partner,order.billToContact);
                            } else if ('SHIP-TO'.equals(partner.PARTNRTYPE)) {
                                order.shipToAccount = createTransactionalAccount(partner,order.shipToAccount);  
                                order.shipToAddress = createAddress(partner,order.shipToAddress);
                                order.shipToContact = createContact(partner,order.shipToContact);
                            } else if ('SOLD-TO'.equals(partner.PARTNRTYPE)) {
                                order.soldToAccount = createTransactionalAccount(partner,order.soldToAccount);
                                order.soldToAddress = createAddress(partner,order.soldToAddress);
                                order.soldToContact = createContact(partner,order.soldToContact);
                            } else if ('ENTITLE-TO'.equals(partner.PARTNRTYPE)) {
                                order.entitleToAccount = createTransactionalAccount(partner,order.entitleToAccount);
                                order.entitleToAddress = createAddress(partner,order.entitleToAddress);
                                order.entitleToContact = createContact(partner,order.entitleToContact);
                            }
                        }
                    }
                }
                
               /*
                *
                * process the POTERM section of the document
                *
                */
                                
                if ('POTERM'.equals(fieldName)) {
                    OAGIObjects.POTERM poterm = (OAGIObjects.POTERM) parser.readValueAs(OAGIObjects.POTERM.class);
                    order.paymentTerms = poterm.TERMID;
                }
                
               /*
                *
                * process the USERAREA of SOHEADER section of the document
                *
                */
                                
                if ('USERAREA'.equals(fieldName)) {
                    OAGIObjects.USERAREA userarea = (OAGIObjects.USERAREA) parser.readValueAs(OAGIObjects.USERAREA.class);
                    order.employeeNumber = userarea.DFFPOHEADER.ATTRIBUTE1;
                    order.operatingUnit = userarea.DFFPOHEADER.ATTRIBUTE2;
                    order.vatCode = userarea.DFFPOHEADER.ATTRIBUTE3;
                    order.orderNumber = userarea.DFFPOHEADER.ATTRIBUTE4;
                    order.orderId = userarea.DFFPOHEADER.ATTRIBUTE5;
                    order.orderStatus = userarea.DFFPOHEADER.ATTRIBUTE6;
                    order.bookedDate = parseDate(userarea.DFFPOHEADER.ATTRIBUTE7);
                    order.orderedDate = parseDate(userarea.DFFPOHEADER.ATTRIBUTE8);
                    order.lastUpdateDate = parseDate(userarea.DFFPOHEADER.ATTRIBUTE9);
                    order.fulfillmentChannel = userarea.DFFPOHEADER.ATTRIBUTE10;
                    order.purchaseOrderNumber = userarea.DFFPOHEADER.ATTRIBUTE11;
                }

               /*
                *
                * process the SOORDERLIN section of the document
                *
                */
                                
                if ('SOORDERLIN'.equals(fieldName)) {
                    List<OAGIObjects.SOORDERLIN> salesOrderLines = null;
                    if (parser.getCurrentToken() == JSONToken.START_ARRAY) {
                        salesOrderLines = (List<OAGIObjects.SOORDERLIN>) parser.readValueAs(List<OAGIObjects.SOORDERLIN>.class);
                    } else {
                        salesOrderLines = new List<OAGIObjects.SOORDERLIN>();
                        salesOrderLines.add((OAGIObjects.SOORDERLIN) parser.readValueAs(OAGIObjects.SOORDERLIN.class));
                    }
                    
                    if (salesOrderLines != null) {
                        Set<Integer> lineNums = new Set<Integer>();
                        for (OAGIObjects.SOORDERLIN salesOrderLine : salesOrderLines) {
                            if(!lineNums.contains(salesOrderLine.SOLINENUM)) {
                                lineNums.add(salesOrderLine.SOLINENUM);
                                IntegrationObjects.OrderLine orderLine = new IntegrationObjects.OrderLine();
                                orderLine.opportunityLineId = parseId(salesOrderLine.USERAREA.VENDORQUOTENUM);
                                orderLine.productCode = salesOrderLine.ITEM;
                                orderLine.actualStartDate = parseDate(salesOrderLine.HAZRDMATL);
                                orderLine.actualEndDate = parseDate(salesOrderLine.ITEMX);
                                if(salesOrderLine.QUANTITY.VALUE != null) {
                                    orderLine.quantity = Decimal.valueOf(salesOrderLine.QUANTITY.VALUE.replace(',',''));
                                }
                                orderLine.unitOfMeasure = salesOrderLine.QUANTITY.UOM;
                                if(salesOrderLine.OPERAMT.VALUE != null) {
                                   orderLine.salesPrice = Decimal.valueOf(salesOrderLine.OPERAMT.VALUE.replace(',',''));
                                }
                                orderLine.currencyIsoCode = salesOrderLine.OPERAMT.CURRENCYISOCODE;
                                if(salesOrderLine.USERAREA.LISTPRICE != null) {
                                    orderLine.listPrice = Decimal.valueOf(salesOrderLine.USERAREA.LISTPRICE.replace(',',''));
                                }
                                orderLine.contractNumbers = salesOrderLine.USERAREA.CONTRACTNUM;
                                orderLine.priceOverrideReason = salesOrderLine.USERAREA.DFFLINE.ATTRIBUTE1;
                                if(salesOrderLine.USERAREA.DFFLINE.ATTRIBUTE6 != null) {
                                   orderLine.oneTimeDiscountedPrice = Decimal.valueOf(salesOrderLine.USERAREA.DFFLINE.ATTRIBUTE6.replace(',',''));
                                }
                                if(salesOrderLine.USERAREA.DFFLINE.ATTRIBUTE7 != null) {
                                   orderLine.discretionaryDiscountedPrice = Decimal.valueOf(salesOrderLine.USERAREA.DFFLINE.ATTRIBUTE7.replace(',',''));
                                }
                                if(salesOrderLine.USERAREA.DFFLINE.ATTRIBUTE9 != null) {
                                   orderLine.perUnitProratedPrice = Decimal.valueOf(salesOrderLine.USERAREA.DFFLINE.ATTRIBUTE9.replace(',',''));
                                }                      
                                orderLine.installBaseNumber = salesOrderLine.USERAREA.CONFIGID;
                                
                               /**
                                *
                                * add the entitleTo partner, address and contact for each line
                                *
                                */
                                
                                for(OAGIObjects.PARTNER partner : salesOrderLine.SOLINESCHD.USERAREA.PARTNERS) {
                                    orderLine.entitleToAccount = createTransactionalAccount(partner,orderLine.entitleToAccount);
                                    orderLine.entitleToAddress = createAddress(partner,orderLine.entitleToAddress);
                                    orderLine.entitleToContact = createContact(partner,orderLine.entitleToContact);
                                }
                                orderLines.add(orderLine);
                            }
                        }
                    }
                }
            }
        }
        
       /*
        *
        * add order partners list to the order
        *
        */
        
        if (orderPartners != null) {
            order.orderPartners = orderPartners;
        }
        
       /*
        *
        * add order lines list to the order
        *
        */
                
        if (orderLines != null) {
            order.orderLines = orderLines;
        }
        
        return order;
    }

    public class PartnerParseException extends IntegrationException {}
}