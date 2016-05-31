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
    Bill C Riemers         2015-10-15      Changed PARTNRIDX and ONETIME to strings.
******************************************************************************************/

public class IntegrationObjectsDeserializer2 {
    
    public static IntegrationObjects.TransactionalAccount parseTransactionalAccount(String json) {
        IntegrationObjects.TransactionalAccount account = null;
        
        JSONParser parser = System.JSON.createParser(json);
        
        while (parser.nextToken() != null) {
            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME)) {
                String fieldName = parser.getText();
                parser.nextToken();
                
                if ('TransactionalAccount'.equals(fieldName)) {
                    IntegrationObjects.SimpleTransactionalAccount simpleAccount = (IntegrationObjects.SimpleTransactionalAccount) parser.readValueAs(IntegrationObjects.SimpleTransactionalAccount.class);
                    //downcast from SimpleTransactionalAccount to TransactionalAccount
                    String simpleAccountJSON = System.JSON.serialize(simpleAccount);
                    account = (IntegrationObjects.TransactionalAccount) System.JSON.deserialize(simpleAccountJSON, IntegrationObjects.TransactionalAccount.class); 
                }  
            }
        }
        
        //second pass to get Sales_Account
        if(account != null) {
            parser = System.JSON.createParser(json);
            
            while (parser.nextToken() != null) {
                if ((parser.getCurrentToken() == JSONToken.FIELD_NAME)) {
                    String fieldName = parser.getText();
                    parser.nextToken();

                    if ('Sales_Account'.equals(fieldName)) {
                        if (parser.getCurrentToken() == JSONToken.START_ARRAY) {
                            List<Integer> salesAccounts = (List<Integer>) parser.readValueAs(List<Integer>.class);
                            if(salesAccounts != null && !salesAccounts.isEmpty()) {
                                //TODO: examine whether we need to support multiple Sales Account values on the integration object
                                account.Sales_Account = String.valueOf(salesAccounts[0]);
                            }
                        } else {
                            Integer salesAccount = (Integer) parser.readValueAs(Integer.class);
                            if(salesAccount != null) {
                                account.Sales_Account = String.valueOf(salesAccount);
                            }
                        }
                    }
                }
            }
        }
        return account;        
    }

    public static IntegrationObjects.SalesAccount parseSalesAccount(String json) {
        IntegrationObjects.SalesAccount account = null;
        List<IntegrationObjects.Contact> contacts = null;
        List<IntegrationObjects.Address> addresses = null;
        
        JSONParser parser = System.JSON.createParser(replaceIdArray(json));
        
        while (parser.nextToken() != null) {
            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME)) {
                String fieldName = parser.getText();
                parser.nextToken();
                
                if ('SalesAccount'.equals(fieldName)) {
                    IntegrationObjects.SimpleSalesAccount simpleAccount = (IntegrationObjects.SimpleSalesAccount) parser.readValueAs(IntegrationObjects.SimpleSalesAccount.class);
                    //downcast from SimpleSalesAccount to SalesAccount
                    String simpleAccountJSON = System.JSON.serialize(simpleAccount);
                    account = (IntegrationObjects.SalesAccount) System.JSON.deserialize(simpleAccountJSON, IntegrationObjects.SalesAccount.class);
                }  
            }
        }

        //second pass to get the Addresses
        if(account != null) {
            parser = System.JSON.createParser(replaceIdArray(json));

            while (parser.nextToken() != null) {
                if ((parser.getCurrentToken() == JSONToken.FIELD_NAME)) {
                    String fieldName = parser.getText();
                    parser.nextToken();

                    if ('Addresses'.equals(fieldName)) {
                        if (parser.getCurrentToken() == JSONToken.START_ARRAY) {
                            addresses = (List<IntegrationObjects.Address>) parser.readValueAs(List<IntegrationObjects.Address>.class); 
                        } else {
                            addresses = new List<IntegrationObjects.Address>();
                            addresses.add((IntegrationObjects.Address) parser.readValueAs(IntegrationObjects.Address.class));
                        }
                        
                        account.Addresses = addresses;
                    }
                    
                    if ('Contacts'.equals(fieldName)) {
                        if (parser.getCurrentToken() == JSONToken.START_ARRAY) {
                            contacts = (List<IntegrationObjects.Contact>) parser.readValueAs(List<IntegrationObjects.Contact>.class);
                        } else {
                            contacts = new List<IntegrationObjects.Contact>();
                            contacts.add((IntegrationObjects.Contact) parser.readValueAs(IntegrationObjects.Contact.class));
                        }
                        
                        account.Contacts = contacts;
                    }  
                }
            }
        } 
        
        return account;
    }
    
    public static IntegrationObjects.Contact parseContact(String json) {
        IntegrationObjects.Contact contact = null;
        
        JSONParser parser = System.JSON.createParser(replaceIdArray(json));
        
        while (parser.nextToken() != null) {
            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME)) {
                String fieldName = parser.getText();
                parser.nextToken();
                
                if ('Contacts'.equals(fieldName)) {
                    contact = new IntegrationObjects.Contact();
                    contact = (IntegrationObjects.Contact) parser.readValueAs(IntegrationObjects.Contact.class);
                }  
            }
        }
        
        return contact;
    }
    
    public static IntegrationObjects.Address parseAddress(String json) {
        IntegrationObjects.Address address = null;
        
        JSONParser parser = System.JSON.createParser(replaceIdArray(json));
        
        while (parser.nextToken() != null) {
            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME)) {
                String fieldName = parser.getText();
                parser.nextToken();
                
                if ('Address'.equals(fieldName)) {
                    address = new IntegrationObjects.Address();
                    address = (IntegrationObjects.Address) parser.readValueAs(IntegrationObjects.Address.class);
                }  
            }
        }
        
        return address;
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
    
    public static String replaceIdArray(String json) {
        String newJson = json;

        List<String> oldMessageText = new List<String>();
        List<String> newMessageText = new List<String>();

        JSONParser parser = System.JSON.createParser(json);
        
        while (parser.nextToken() != null) {
            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME)) {
                String fieldName = parser.getText();
                parser.nextToken();

                if ('IDs'.equals(fieldName)) {
                    if (parser.getCurrentToken() == JSONToken.START_ARRAY) {
                        List<String> ids = (List<String>) parser.readValueAs(List<String>.class);
                        
                        String oldText = '"IDs":[';
                        for(String idValue : ids) {
                            oldText += '"' + idValue + '",';
                        }
                        oldText = oldText.left(oldText.length() - 1);
                        oldText += ']';

                        String newText = '"IDs":"' + ids[0] + '"';

                        oldMessageText.add(oldText);
                        system.debug('****** oldText: ' + oldText);
                        newMessageText.add(newText);
                        system.debug('****** newText: ' + newText);
                    }
                }

                if ('SalesAccount_Id'.equals(fieldName)) {
                    if (parser.getCurrentToken() == JSONToken.START_ARRAY) {
                        List<String> ids = (List<String>) parser.readValueAs(List<String>.class);
                        
                        String oldText = '"SalesAccount_Id":[';
                        for(String idValue : ids) {
                            oldText += '"' + idValue + '",';
                        }
                        oldText = oldText.left(oldText.length() - 1);
                        oldText += ']';

                        String newText = '"SalesAccount_Id":"' + ids[0] + '"';

                        oldMessageText.add(oldText);
                        system.debug('****** oldText: ' + oldText);
                        newMessageText.add(newText);
                        system.debug('****** newText: ' + newText);
                    }
                }

            }
        }

        if(!oldMessageText.isEmpty()) {
            Integer i = 0;
            for (String oldText : oldMessageText) {
                system.debug('****** replace ' + oldText + ' with ' + newMessageText[i]);
                newJson = newJson.replace(oldText,newMessageText[i]);
                i = i + 1;
            }
        }

        return newJson;
    }

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

            if(dateParts.size() == 3) {
                Integer day = Integer.valueOf(dateParts[0]);
                Integer month = monthMap.get(dateParts[1]);
                if(dateParts[2].length() == 2) {
                    dateParts[2] = '20' + dateParts[2];
                }
                Integer year = Integer.valueOf(dateParts[2]);
                dateValue = System.Date.newInstance(year, month, day);
            }
        }
        catch(Exception ex) { /*return null if date can't be parsed */ }

        return dateValue;
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
        
       /*
        *
        * replace Salesforce reserved word CURRENCY with CURRENCYISOCODE
        *
        */

        json = json.replaceAll('CURRENCY', 'CURRENCYISOCODE');
        json = json.replaceAll('""', 'null');
        
       /*
        *
        * create the JSON parser
        *
        */
        
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
                        order.amount = Decimal.valueOf(operamt.VALUE.replaceAll(',',''));
                    }
                    order.currencyIsoCode = operamt.CURRENCYISOCODE;
                }
                                
               /*
                *
                * process the PARTNER section of the document
                *
                */
                                
                if ('PARTNER'.equals(fieldName)) {
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
                                
                                IntegrationObjects.OrderPartner orderPartner = new IntegrationObjects.OrderPartner();
                                orderPartner.partnerType = partner.TAXID;
                                orderPartner.partnerTier = partner.TERMID;
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
                                
                            } else {
                            
                                IntegrationObjects.TransactionalAccount account = new IntegrationObjects.TransactionalAccount();
                                account.Name = partner.NAME.content;
                                account.Account_Number = String.valueOf(partner.PARTNRID);
                                account.EBS_Party_Number = partner.PARTNRIDX;
                                account.PartyType = partner.DUNSNUMBER;
                            
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
                            
                                IntegrationObjects.Contact contact = new IntegrationObjects.Contact();
                                contact.CDH_Party_Number = partner.CONTACT.CONTCTTYPE;
                                contact.FirstName = partner.CONTACT.NAME[0].content;
                                contact.LastName = partner.CONTACT.NAME[1].content;
                                contact.Email = partner.CONTACT.EMAIL;
                                contact.Phone = partner.CONTACT.TELEPHONE.content;
                            
                                if ('BILL-TO'.equals(partner.PARTNRTYPE)) {
                                    order.billToAccount = account;
                                    order.billToAddress = address;
                                    order.billToContact = contact;
                                }
                            
                                if ('SHIP-TO'.equals(partner.PARTNRTYPE)) {
                                    order.shipToAccount = account;  
                                    order.shipToAddress = address;
                                    order.shipToContact = contact;
                                }
                            
                                if ('SOLD-TO'.equals(partner.PARTNRTYPE)) {
                                    order.soldToAccount = account;
                                    order.soldToAddress = address;
                                    order.soldToContact = contact;
                                }
                            
                                if ('ENTITLE-TO'.equals(partner.PARTNRTYPE)) {
                                    order.entitleToAccount = account;
                                    order.entitleToAddress = address;
                                    order.entitleToContact = contact;
                                }                            
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
                        for (OAGIObjects.SOORDERLIN salesOrderLine : salesOrderLines) {
                            IntegrationObjects.OrderLine orderLine = new IntegrationObjects.OrderLine();
                            orderLine.productCode = salesOrderLine.ITEM;
                            orderLine.actualStartDate = parseDate(salesOrderLine.HAZRDMATL);
                            orderLine.actualEndDate = parseDate(salesOrderLine.ITEMX);
                            orderLine.quantity = Decimal.valueOf(salesOrderLine.QUANTITY.VALUE);
                            orderLine.unitOfMeasure = salesOrderLine.QUANTITY.UOM;
                            if(salesOrderLine.OPERAMT.VALUE != null) {
                               orderLine.salesPrice = Decimal.valueOf(salesOrderLine.OPERAMT.VALUE.replaceAll(',',''));
                            }
                            orderLine.currencyIsoCode = salesOrderLine.OPERAMT.CURRENCYISOCODE;
                            if(salesOrderLine.USERAREA.LISTPRICE != null) {
                                orderLine.listPrice = Decimal.valueOf(salesOrderLine.USERAREA.LISTPRICE.replaceAll(',',''));
                            }
                            orderLine.contractNumbers = salesOrderLine.USERAREA.CONTRACTNUM;
                            orderLine.priceOverrideReason = salesOrderLine.USERAREA.DFFLINE.ATTRIBUTE1;
                            orderLine.opportunityLineId = salesOrderLine.USERAREA.DFFLINE.ATTRIBUTE2;
                            if(salesOrderLine.USERAREA.DFFLINE.ATTRIBUTE6 != null) {
                               orderLine.oneTimeDiscountedPrice = Decimal.valueOf(salesOrderLine.USERAREA.DFFLINE.ATTRIBUTE6.replaceAll(',',''));
                            }
                            if(salesOrderLine.USERAREA.DFFLINE.ATTRIBUTE7 != null) {
                               orderLine.discretionaryDiscountedPrice = Decimal.valueOf(salesOrderLine.USERAREA.DFFLINE.ATTRIBUTE7.replaceAll(',',''));
                            }
                            orderLine.installBaseNumber = salesOrderLine.USERAREA.CONFIGID;
                            
                           /**
                            *
                            * add the entitleTo partner, address and contact for each line
                            *
                            */
                            
                            OAGIObjects.PARTNER partner = salesOrderLine.SOLINESCHD.USERAREA.PARTNER;
                            
                            IntegrationObjects.TransactionalAccount account = new IntegrationObjects.TransactionalAccount();
                            account.Name = partner.NAME.content;
                            account.Account_Number = String.valueOf(partner.PARTNRID);
                            account.EBS_Party_Number = partner.PARTNRIDX;
                            account.PartyType = partner.DUNSNUMBER;
                            
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
                            
                            IntegrationObjects.Contact contact = new IntegrationObjects.Contact();
                            contact.CDH_Party_Number = partner.CONTACT.CONTCTTYPE;
                            contact.FirstName = partner.CONTACT.NAME[0].content;
                            contact.LastName = partner.CONTACT.NAME[1].content;
                            contact.Email = partner.CONTACT.EMAIL;
                            contact.Phone = partner.CONTACT.TELEPHONE.content;
                            
                            orderLine.entitleToAccount = account;
                            orderLine.entitleToAddress = address;
                            orderLine.entitleToContact = contact;
                            
                            orderLines.add(orderLine);
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
}