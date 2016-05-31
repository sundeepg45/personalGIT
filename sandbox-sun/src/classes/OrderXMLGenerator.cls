/*****************************************************************************************
    Name    : OrderXMLGenerator
    Desc    : The class that serializes an order into an OAGI XML message

    Modification Log :
---------------------------------------------------------------------------
    Developer              Date            Description
---------------------------------------------------------------------------
    Scott Coleman          31 Jul 2014     Created
    Scott Coleman          06 Nov 2014     Added payNow attribute to the order
    Scott Coleman          04 Dec 2014     Retired partnerType and partnerTier, added classificationCode
    Scott Coleman          09 Dec 2014     Added contractNumber
    Scott Coleman          15 Mar 2015     Added special handling for non-entitled end customer on order
    Scott Coleman          03 Sep 2015     Updating credit card data sent with order to meet tokenization requirements (US73120)
    Bill C Riemers         22 Oct 2015     Only put in token format if this is an operating unit that requires a token
    Bill C Riemers         23 Oct 2015     Try and access the original opportunity to see if we need the token format.
******************************************************************************************/
public class OrderXMLGenerator {
    private static XMLStreamWriter xml;

    public static String generateOrderXML(IntegrationObjects.Order order) {
        if(order == null) {
            order = new IntegrationObjects.Order();
        }

        if(order.orderLines == null || order.orderLines.isEmpty()) {
            order.orderLines = new List<IntegrationObjects.OrderLine>();
        }

        if(order.orderPartners == null || order.orderPartners.isEmpty()) {
            order.orderPartners = new List<IntegrationObjects.OrderPartner>();
        }

        if(order.nonEntitledEndcoCDHPartyName != null && order.nonEntitledEndcoCDHPartyNumber != null) {
            IntegrationObjects.OrderPartner nonEntitledEndCo = new IntegrationObjects.OrderPartner();
            nonEntitledEndCo.account = new IntegrationObjects.SalesAccount();
            nonEntitledEndCo.account.Name = order.nonEntitledEndcoCDHPartyName;
            nonEntitledEndCo.account.CDH_Party_Number = order.nonEntitledEndcoCDHPartyNumber;
            nonEntitledEndCo.transactionRole = 'Non Entitled Endco';
            order.orderPartners.add(nonEntitledEndCo);
        }

        Boolean isTokenRequired = Opportunity_PaymentDetailsController.isTokenRequired(order.operatingUnit);
        if(order.ID != null && String.isNotBlank(order.ID) && order.creditCardNumber != null && String.isNotBlank(order.creditCardNumber)) {
            try {
                Opportunity opp = IntegrationObjectConverter.oppMap.get(order.ID);
                if(opp == null) {
                    for(Opportunity o : [
                        select
                            Credit_Card_Number__c,
                            Credit_Card_Token__c
                        from Opportunity
                        where Id = :order.ID ] )
                    {
                        opp = o;
                    }
                }
                if(opp != null && opp.Credit_Card_Number__c != null) {
                    isTokenRequired = (opp.Credit_Card_Token__c != null);
                }
            }
            catch(Exception ex) {}
        }
        String cardType = null;
        if(order.creditCardType != null && String.isNotBlank(order.creditCardType)) {
            cardType = order.creditCardType;
            if(isTokenRequired) {
                cardType = 'UNKNOWN';
            }
        }

        xml = new XMLStreamWriter();

        writeStartDocument();
            writeStartElement('PROCESS_PO_007');
                writeStartElement('CNTROLAREA');
                    writeStartElement('BSR');
                        writeElement('VERB', 'PROCESS');
                        writeElement('NOUN', 'PO');
                        writeElement('REVISION', '007');
                    writeEndElement(); //BSR
                    writeStartElement('SENDER');
                        writeElement('LOGICALID', 'XXRHESB');
                        writeElement('COMPONENT', 'PURCHASING');
                        writeElement('TASK', 'POISSUE');
                        writeElement('REFERENCEID', order.opportunityId);
                        writeElement('CONFIRMATION', '0');
                        writeElement('LANGUAGE', 'US');
                        writeElement('CODEPAGE', 'UTF8');
                        writeElement('AUTHID', null);
                    writeEndElement(); //SENDER
                    writeDATETIME('CREATION', System.Now());
                writeEndElement(); //CNTROLAREA
                writeStartElement('DATAAREA');
                    writeStartElement('PROCESS_PO');
                        writeStartElement('POORDERHDR');
                            writeDATETIME('DOCUMENT', System.Now());
                            writeOPERAMT('EXTENDED', String.valueOf(order.amount), '2', '+', order.currencyIsoCode);
                            writeElement('POID', order.opportunityNumber);
                            writeElement('POTYPE', order.orderType);
                            writeElement('ACKREQUEST', null);
                            writeElement('CONTRACTB', null);
                            writeElement('CONTRACTS', null);
                            writeElement('DESCRIPTN', null);
                            writeElement('PORELEASE', null);
                            writeStartElement('USERAREA');
                                writeDATETIME('ACTSTART', null);
                                writeDATETIME('ACTEND', null);
                                writeStartElement('FOB');
                                    writeElement('DESCRIPTN', null);
                                    writeElement('TERMID', null);
                                writeEndElement(); //FOB
                                writeElement('TANDC', null);
                                writeStartElement('FTTERM');
                                    writeElement('DESCRIPTN', null);
                                    writeElement('TERMID', null);
                                writeEndElement(); //FTTERM
                                writeElement('EXCHRATE', null);
                                writeDATETIME('EXCHRATEDATE', null);
                                writeDATETIME('APPREQ', null);
                                writeElement('CONFIRM', 'N');
                                writeElement('SHIPPINGCONTROL', null);
                                writeStartElement('DFFPOHEADER');
                                    writeElement('ATTRIBUTE1', order.employeeNumber);
                                    writeElement('ATTRIBUTE2', order.operatingUnit);
                                    writeElement('ATTRIBUTE3', order.vatCode);
                                    writeElement('ATTRIBUTE4', order.orderNumber);
                                    writeElement('ATTRIBUTE5', order.orderId);
                                    writeElement('ATTRIBUTE6', null);
                                    writeElement('ATTRIBUTE7', null);
                                    writeElement('ATTRIBUTE8', null);
                                    writeElement('ATTRIBUTE9', null);
                                    writeElement('ATTRIBUTE10', order.fulfillmentChannel);
                                    writeElement('ATTRIBUTE11', order.purchaseOrderNumber);
                                    writeElement('ATTRIBUTE12', null);
                                    writeElement('ATTRIBUTE13', null);
                                    writeElement('ATTRIBUTE14', order.contractNumber);
                                    writeElement('ATTRIBUTE15', null);
                                    writeElement('ATTRIBUTE16', order.payNow);
                                writeEndElement(); //DFFPOHEADER 
                                writeStartElement('PCARDHDR');
                                    writeElement('MEMBERNAME', buildCardholderName(isTokenRequired, order.nameOnCard, order.creditCardType, order.creditCardNumber));
                                    writeElement('PCARDNUM', order.creditCardNumber);
                                    writeDATETIME('EXPIRATION', order.expirationDate);
                                    writeElement('PCARDBRAND', cardType);
                                writeEndElement(); //PCARDHDR
                            writeEndElement(); //USERAREA
                            writePARTNER('BILL_TO', order.billToAccount, order.billToAddress, order.billToContact);
                            writePARTNER('SHIP_TO', order.shipToAccount, order.shipToAddress, order.shipToContact);
                            writePARTNER('SOLD_TO', order.soldToAccount, order.soldToAddress, order.soldToContact);
                            writePARTNER('ENTITLE_TO', order.entitleToAccount, order.entitleToAddress, order.entitleToContact);
                            for(IntegrationObjects.OrderPartner orderPartner : order.orderPartners) {
                                writePARTNER(orderPartner);
                            }
                            writeStartElement('POTERM');
                                writeElement('DESCRIPTN', order.paymentType);
                                writeElement('TERMID', order.paymentTerms);
                                writeElement('DAYSNUM', null);
                                writeQUANTITY('PERCENT', null);
                            writeEndElement(); //POTERM
                        writeEndElement(); //POORDERHDR
                        Integer lineNumber = 1;
                        for(IntegrationObjects.OrderLine orderLine : order.orderLines) {
                            writePOORDERLIN(orderLine, lineNumber);
                            lineNumber = lineNumber + 1;
                        }
                    writeEndElement(); //PROCESS_PO
                writeEndElement(); //DATAAREA
            writeEndElement(); //PROCESS_PO_007
        writeEndDocument();

        system.debug(xml.getXmlString());
        return xml.getXmlString();
    }

    /* reusable generators for repeated document sections */

    private static void writeDATETIME(String qualifier, DateTime dateTimeValue) {
        String YEAR, MONTH, DAY, HOUR, MINUTE, SECOND, SUBSECOND, TIMEZONE;

        if(dateTimeValue != null) {
            YEAR = String.valueOf(dateTimeValue.yearGmt());
            MONTH = String.valueOf(dateTimeValue.monthGmt()).leftPad(2).replaceAll(' ','0');
            DAY = String.valueOf(dateTimeValue.dayGmt()).leftPad(2).replaceAll(' ','0');
            HOUR = String.valueOf(dateTimeValue.hourGmt()).leftPad(2).replaceAll(' ','0');
            MINUTE = String.valueOf(dateTimeValue.minuteGmt()).leftPad(2).replaceAll(' ','0');
            SECOND = String.valueOf(dateTimeValue.secondGmt()).leftPad(2).replaceAll(' ','0');
            SUBSECOND = '0000';
            TIMEZONE = '-0000';
        }

        writeStartElement('DATETIME', new Map<String,String>{'index'=>'1', 'qualifier'=>qualifier, 'type'=>'T'});
            writeElement('YEAR', YEAR);
            writeElement('MONTH', MONTH);
            writeElement('DAY', DAY);
            writeElement('HOUR', HOUR);
            writeElement('MINUTE', MINUTE);
            writeElement('SECOND', SECOND);
            writeElement('SUBSECOND', SUBSECOND);
            writeElement('TIMEZONE', TIMEZONE);
        writeEndElement(); //DATETIME
    }

    private static void writeOPERAMT(String qualifier, String value, String numOfDec, String sign, String currencyIsoCode) {
        writeStartElement('OPERAMT', new Map<String,String>{'qualifier'=>qualifier, 'type'=>'T'});
            writeElement('VALUE', value);
            writeElement('NUMOFDEC', numOfDec);
            writeElement('SIGN', sign);
            writeElement('CURRENCY', currencyIsoCode);
            writeElement('UOMVALUE', null);
            writeElement('UOMNUMDEC', null);
            writeElement('UOM', null);
        writeEndElement(); //OPERAMT
    }

    private static void writePARTNER(IntegrationObjects.OrderPartner orderPartner) {
        if(orderPartner == null) {
            orderPartner = new IntegrationObjects.OrderPartner();
        }

        if(orderPartner.account == null) {
            orderPartner.account = new IntegrationObjects.SalesAccount();
        }

        writeStartElement('PARTNER');
            writeElement('NAME', orderPartner.account.Name, new Map<String,String>{'index'=>'1'});
            writeElement('ONETIME', orderPartner.classificationCode);
            writeElement('PARTNRID', orderPartner.transactionRole);
            writeElement('PARTNRTYPE', 'ADDL_PARTY');
            writeElement('DESCRIPTN', null);
            writeElement('PARTNRIDX', orderPartner.account.CDH_Party_Number);
            writeElement('TAXID', null);
            writeElement('TERMID', null);
            writeAddress(null);
            writeContact(orderPartner.contact);
        writeEndElement(); //PARTNER
    }

    private static void writePARTNER(String partnerType, IntegrationObjects.TransactionalAccount account, IntegrationObjects.Address address, IntegrationObjects.Contact contact) {
        if(account == null) {
            account = new IntegrationObjects.TransactionalAccount();
        }

        writeStartElement('PARTNER');
            writeElement('NAME', null, new Map<String,String>{'index'=>'1'});
            writeElement('PARTNRID', account.Account_Number);
            writeElement('PARTNRTYPE', partnerType);
            writeElement('DESCRIPTN', null);
            writeElement('PARTNRIDX', account.EBS_Party_Number);
            writeElement('TAXID', null);
            writeElement('TERMID', null);
            writeAddress(address);
            writeContact(contact);
        writeEndElement(); //PARTNER
    }

    private static void writeADDRESS(IntegrationObjects.Address address) {
        if(address == null) {
            address = new IntegrationObjects.Address();
        }

        writeStartElement('ADDRESS');
            writeElement('ADDRLINE', address.Address_Line1, new Map<String,String>{'index'=>'1'});
            writeElement('ADDRLINE', address.Address_Line2, new Map<String,String>{'index'=>'2'});
            writeElement('ADDRLINE', address.Address_Line3, new Map<String,String>{'index'=>'3'});
            writeElement('ADDRLINE', address.Address_Line4, new Map<String,String>{'index'=>'4'});
            writeElement('CITY', address.City);
            writeElement('COUNTRY', address.Country);
            writeElement('COUNTY', address.County);
            writeElement('DESCRIPTN', address.CDH_Party_Site_Number);
            writeElement('POSTALCODE', address.Zip_Postal_Code);
            writeElement('STATEPROVN', address.State);
        writeEndElement(); //ADDRESS
    }

    private static void writeCONTACT(IntegrationObjects.Contact contact) {
        if(contact == null) {
            contact = new IntegrationObjects.Contact();
        }

        String contactName;
        if(contact.FirstName != null && contact.LastName != null) {
            contactName = contact.FirstName + ' ' + contact.LastName;
        }

        writeStartElement('CONTACT');
            writeElement('NAME', contactName, new Map<String,String>{'index'=>'1'});
            writeElement('CONTCTTYPE', contact.CDH_Party_Number);
            writeElement('EMAIL', contact.Email);
            writeElement('TELEPHONE', contact.Phone, new Map<String,String>{'index'=>'1'});
        writeEndElement(); //CONTACT
    }

    private static void writeQUANTITY(String qualifier, String value) {
        writeStartElement('QUANTITY', new Map<String,String>{'qualifier'=>qualifier});
            writeElement('VALUE', value);
            writeElement('NUMOFDEC', null);
            writeElement('SIGN', null);
            writeElement('UOM', null);
        writeEndElement(); //QUANTITY
    }

    private static void writePOORDERLIN(IntegrationObjects.OrderLine orderLine, Integer lineNumber) {
        if(orderLine == null) {
            orderLine = new IntegrationObjects.OrderLine();
        }

        writeStartElement('POORDERLIN');
            writeQUANTITY('ORDERED', String.valueOf(orderLine.quantity));
            writeOPERAMT('UNIT', String.valueOf(orderLine.salesPrice), '2', '+', orderLine.currencyIsoCode);
            writeElement('POLINENUM', String.valueOf(lineNumber));
            writeElement('HAZRDMATL', formatDate(orderLine.actualStartDate));
            writeElement('DESCRIPTN', null);
            writeElement('ITEM', orderLine.productCode);
            writeElement('ITEMX', formatDate(orderLine.actualEndDate));
            writeStartElement('USERAREA');
                writeElement('CONTRACTNUM', orderLine.contractNumbers);
                writeElement('CONFIGID', null);
                writeStartElement('DFFLINE');
                    writeElement('ATTRIBUTE1', orderLine.priceOverrideReason);
                    writeElement('ATTRIBUTE2', orderLine.opportunityLineId);
                    writeElement('ATTRIBUTE6', String.valueOf(orderLine.oneTimeDiscountedPrice));
                    writeElement('ATTRIBUTE7', String.valueOf(orderLine.discretionaryDiscountedPrice));
                    writeElement('ATTRIBUTE8', String.valueOf(orderLine.listPrice));
                    writeElement('ATTRIBUTE9', String.valueOf(orderLine.perUnitProratedPrice));
                writeEndElement(); //DFFLINE 
            writeEndElement(); //USERAREA
            writePARTNER('ENTITLE_TO', orderLine.entitleToAccount, orderLine.entitleToAddress, orderLine.entitleToContact);
        writeEndElement(); //POORDERLIN
    }

    /* helpers to clean up the generation code above */

    private static void writeStartDocument() {
        xml.writeStartDocument('UTF-8', '1.0');
    }

    private static void writeEndDocument() {
        xml.writeEndDocument();
    }

    private static void writeElement(String element, String value) {
        writeElement(element, value, null);
    }

    private static void writeElement(String element, String value, Map<String,String> attributes) {
        if(value==null) {
            xml.writeEmptyElement(null, element, null);
            writeAttributes(attributes);
        }
        else {
            xml.writeStartElement(null, element, null);
            writeAttributes(attributes);
            xml.writeCharacters(value);
            xml.writeEndElement();
        }
    }

    private static void writeStartElement(String element) {
        writeStartElement(element, null);
    }

    private static void writeStartElement(String element, Map<String,String> attributes) {
        xml.writeStartElement(null, element, null);
        writeAttributes(attributes);
    }

    private static void writeEndElement() {
        xml.writeEndElement();
    }

    private static void writeAttributes(Map<String,String> attributes) {
        if(attributes != null) {
            for(String attribute : attributes.keySet()) {
                xml.writeAttribute(null, null, attribute, attributes.get(attribute));
            }
        }
    }

    private static Map<Integer,String> monthMap = new Map<Integer,String>{1=>'JAN',2=>'FEB',3=>'MAR',4=>'APR',5=>'MAY',6=>'JUN',7=>'JUL',8=>'AUG',9=>'SEP',10=>'OCT',11=>'NOV',12=>'DEC'};

    private static String formatDate(Date dateValue) {
        String stringValue;
        if(dateValue != null) {
           stringValue = ('0' + dateValue.day()).right(2) + '-' + monthMap.get(dateValue.month()) + '-' + dateValue.year();
        }        
        return stringValue;
    }

    @TestVisible
    private static String mapCardType(String cardType) {
        String mappedCardType;

        if(cardType != null && !String.isBlank(cardType)) {
            //default value
            mappedCardType = cardType.rightPad(10).left(10).trim().toUpperCase();

            //mapping
            if (cardType.toUpperCase() == 'AMERICAN EXPRESS') {
                mappedCardType = 'AMEX';
            }
            else if (cardType.toUpperCase() == 'MASTERCARD') {
                mappedCardType = 'MC';
            }
            else if(cardType.toUpperCase() == 'VISA') {
                mappedCardType = 'VISA';
            }
        }

        return mappedCardType;
    }

    @TestVisible
    private static String buildCardholderName(Boolean isTokenRequired,String cardholderName, String cardType, String cardNumber) {
        String cardholderNameWithCardDetails;

        if(cardholderName != null && !String.isBlank(cardholderName)) {
            cardholderNameWithCardDetails = cardholderName;

            if(isTokenRequired) {
                if (cardType != null && !String.isBlank(cardType)) {
                    cardholderNameWithCardDetails = cardholderNameWithCardDetails + ' ' + mapCardType(cardType);
                }

                if (cardNumber != null && !String.isBlank(cardNumber)) {
                    cardholderNameWithCardDetails = cardholderNameWithCardDetails + ' ' + cardNumber.right(4);
                }
            }
        }

        return cardholderNameWithCardDetails;
    }
}