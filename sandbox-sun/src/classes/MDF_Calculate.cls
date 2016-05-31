public class MDF_Calculate {

 
SFDC_Channel_Account_Plan__c BPlan;
public final SFDC_Channel_Account_Plan__c BP; 
list<SFDC_Budget__c> MDFS= new list<SFDC_Budget__c>();
public User UserMDF=null;


String accId;

String fiscalYear;

String fiscalYear1;

Integer intFiscalYear;


String fiscalYearMDF;

String fiscalYearMDF1;

String FQ;

Integer intFiscalYearMDF;

 

Decimal allocatedBudget=0;
Decimal availableBudget=0;

Decimal totalAllocatedBudgetQ1=0;

Decimal totalAllocatedBudgetQ2=0;

Decimal totalAllocatedBudgetQ3=0;

Decimal totalAllocatedBudgetQ4=0;

Decimal totalAllocatedBudgetQ1User=0;
Decimal totalAllocatedBudgetQ2User=0;
Decimal totalAllocatedBudgetQ3User=0;
Decimal totalAllocatedBudgetQ4User=0;

String AllocatedBudget1='';
String AllocatedBudget2='';
String AllocatedBudget3='';
String AllocatedBudget4='';

String ExecutedBudget1='';
String ExecutedBudget2='';
String ExecutedBudget3='';
String ExecutedBudget4='';

Date startDate;

Integer month;

Integer year;

Decimal differenceQ1;

Decimal differenceQ2;

Decimal differenceQ3;

Decimal differenceQ4;
 

Decimal mDFExecutedQ1=0;

Decimal mDFExecutedQ2=0;

Decimal mDFExecutedQ3=0;

Decimal mDFExecutedQ4=0;


Decimal mDFExecutedQ1User=0;
Decimal mDFExecutedQ2User=0;
Decimal mDFExecutedQ3User=0;
Decimal mDFExecutedQ4User=0;

String RequestCurrency2;
String RequestCurrency1;
 

public MDF_Calculate(ApexPages.StandardController controller) 
{ 
this.BP = (SFDC_Channel_Account_Plan__c)controller.getRecord(); 
//BPlan=[Select Partner_Name__c, Fiscal_Year__c from SFDC_Channel_Account_Plan__c where Id =: BP.Id]; 
UserMDF = [Select Name, CurrencyIsoCode, DefaultCurrencyIsoCode from User where Id = :UserInfo.getUserId()];
RequestCurrency2=UserMDF.DefaultCurrencyIsoCode;
} 

public Decimal getConvertedCurrencyValue(Decimal Value,String RecordCurrency)
        {
            CurrencyType convertedValue=[Select Id,ConversionRate, IsoCode from CurrencyType where IsoCode=:RecordCurrency];
            Decimal latestValue=Value*(convertedValue.ConversionRate);
            System.Debug('value'+Value+'ConversionRate'+convertedValue.ConversionRate+'latestValue'+latestValue);
            return latestValue;
        }


public void totalAllocatedBudget() 

                {               

                                SFDC_Channel_Account_Plan__c[] businessPlan=[Select Partner_Name__c,Fiscal_Year__c from SFDC_Channel_Account_Plan__c where Id=:BP.Id];

                                for(SFDC_Channel_Account_Plan__c temp:businessPlan)

                                {

                                                accId=temp.Partner_Name__c;


                                               fiscalYear=temp.Fiscal_Year__c;

                                }

                //system.debug('Fiscal yearrrrrrrrrrrrrr'+fiscalYear);
                //system.debug('Account IDDDDDDDDDDD'+accId);

                if(fiscalYear!=null)
        {
                           fiscalYear1=fiscalYear.substring(2); 
                   intFiscalYear=Integer.valueOf(fiscalYear1);
                }
                
                //system.debug('intFiscalYear'+intFiscalYear);

 

                                MDFS=[Select Id,Allocated_Budget__c,Available_Budget__c, Start_Date__c, Fiscal_Year__c, Fiscal_Quarter__c,CurrencyIsoCode from SFDC_Budget__c where Account_master__c=:accId];
                
                //system.debug('MDFFFFFFFFFF'+MDFS);    
        
        if(MDFS.size()>0){
                
                
                                
                for(SFDC_Budget__c MDF:MDFS)

                                {
                        RequestCurrency1=MDF.CurrencyIsoCode ;
                                                Decimal amount=MDF.Allocated_Budget__c;
                                                Decimal amount2=MDF.Available_Budget__c;

                                                if(amount!=null)
                                                {
                                                    allocatedBudget=getConvertedCurrencyValue(amount,RequestCurrency1);
                            
                                                }
                                                
                                                if(amount2!=null)
                                                {
                                                    availableBudget=getConvertedCurrencyValue(amount2,RequestCurrency1);
                            
                                                }
                                                
                                                //allocatedBudget=MDF.Allocated_Budget__c;

                                                //availableBudget=MDF.Available_Budget__c;

                        FQ=MDF.Fiscal_Quarter__c;
                        fiscalYearMDF=MDF.Fiscal_Year__c;  
                                                
                        
                        //startDate=MDF.Start_Date__c;
                        
                        if(fiscalYearMDF!=null){
                        fiscalYearMDF1=fiscalYearMDF.substring(2);      
             
                        intFiscalYearMDF=Integer.valueOf(fiscalYearMDF1);       
                        }
                        
                        
                        //system.debug('MDFFFFFFFFFF'+MDFS);
                                                
                                                //month=startDate.month();

                                                //year=startDate.year();

 

                                                if(allocatedBudget!=null && availableBudget!=null)

                                                {

                                                                if(intFiscalYear==intFiscalYearMDF)

                                                                {
                                    if(FQ!=null)
                                      {
                                                                                if(FQ=='Q1')            //if(month==3||month==4||month==5)

                                                                                {
                                             
                                                                                                totalAllocatedBudgetQ1=totalAllocatedBudgetQ1+allocatedBudget;    //get this value
                                                
                                                                
                                                                                                differenceQ1=allocatedBudget-availableBudget;
                                                

                                                                                                MDFExecutedQ1=MDFExecutedQ1+differenceQ1;                       //get this value    
                                                
                                                

                                                                                }

                                                                                 if(FQ=='Q2')           //if(month==6||month==7||month==8)

                                                                                {

                                                                                                totalAllocatedBudgetQ2=totalAllocatedBudgetQ2+allocatedBudget;  //get this value
                                                

                                                                                                differenceQ2=allocatedBudget-availableBudget;
                                                
                                                                                                
                                                MDFExecutedQ2=MDFExecutedQ2+differenceQ2;  //get this value
                                                

                                                                                }

                                                                                 if(FQ=='Q3')           //if(month==9||month==10||month==11)

                                                                                {

                                                                                                totalAllocatedBudgetQ3=totalAllocatedBudgetQ3+allocatedBudget;  //get this value
                                                

                                                                                                differenceQ3=allocatedBudget-availableBudget;
                                                

                                                                                                MDFExecutedQ3=MDFExecutedQ3+differenceQ3;  //get this value
                                                


                                                                                }

                                                                                 if(FQ=='Q4')           //if(month==12||month==1||month==2)

                                                                                {

                                                                                                totalAllocatedBudgetQ4=totalAllocatedBudgetQ4+allocatedBudget;  //get this value

                                                                                                differenceQ4=allocatedBudget-availableBudget;

                                                                                                MDFExecutedQ4=MDFExecutedQ4+differenceQ4;  //get this value

                                                                                }
                                    }
                                                                }

                                                }

                                }

                }

 
}
 

//Getter methods for MDFExecuted and for totalAllocatedBudget

 
public Decimal Convert(Decimal a)
    {
                Decimal var=Math.round(a*Math.pow(10,2))/Math.pow(10,2);
                return var;
   }
 

public String getAllocatedBudget1()

    {

                                totalAllocatedBudget();
                totalAllocatedBudgetQ1User=getConvertedCurrencyValue(totalAllocatedBudgetQ1,RequestCurrency2);
                AllocatedBudget1='USD'+Convert(totalAllocatedBudgetQ1)+' ('+UserMDF.DefaultCurrencyIsoCode+Convert(totalAllocatedBudgetQ1User)+')';
                                return AllocatedBudget1;

                }

public String getAllocatedBudget2()

    {
               
                                totalAllocatedBudgetQ2User=getConvertedCurrencyValue(totalAllocatedBudgetQ2,RequestCurrency2);
                AllocatedBudget2='USD'+Convert(totalAllocatedBudgetQ2)+' ('+UserMDF.DefaultCurrencyIsoCode+Convert(totalAllocatedBudgetQ2User)+')';
                                return AllocatedBudget2;

                }

public String getAllocatedBudget3()

    {

                                totalAllocatedBudgetQ3User=getConvertedCurrencyValue(totalAllocatedBudgetQ3,RequestCurrency2);
                AllocatedBudget3='USD'+Convert(totalAllocatedBudgetQ3)+' ('+UserMDF.DefaultCurrencyIsoCode+Convert(totalAllocatedBudgetQ3User)+')';
                                return AllocatedBudget3;

                }

public String getAllocatedBudget4()

    {

                                totalAllocatedBudgetQ4User=getConvertedCurrencyValue(totalAllocatedBudgetQ4,RequestCurrency2);
                AllocatedBudget4='USD'+Convert(totalAllocatedBudgetQ4)+' ('+UserMDF.DefaultCurrencyIsoCode+Convert(totalAllocatedBudgetQ4User)+')';
                                return AllocatedBudget4;

                }

public String getExecutedBudget1()

    {
                MDFExecutedQ1User=getConvertedCurrencyValue(MDFExecutedQ1,RequestCurrency2);
                ExecutedBudget1='USD'+Convert(MDFExecutedQ1)+' ('+UserMDF.DefaultCurrencyIsoCode+Convert(MDFExecutedQ1User)+')';
                                return ExecutedBudget1;

                }

public String getExecutedBudget2()

    {
                MDFExecutedQ2User=getConvertedCurrencyValue(MDFExecutedQ2,RequestCurrency2);
                ExecutedBudget2='USD'+Convert(MDFExecutedQ2)+' ('+UserMDF.DefaultCurrencyIsoCode+ Convert(MDFExecutedQ2User)+')';
                                return ExecutedBudget2;
                                

                }

public String getExecutedBudget3()

    {
                MDFExecutedQ3User=getConvertedCurrencyValue(MDFExecutedQ3,RequestCurrency2);
                ExecutedBudget3='USD'+Convert(MDFExecutedQ3)+' ('+UserMDF.DefaultCurrencyIsoCode+Convert(MDFExecutedQ3User)+')';
                                return ExecutedBudget3;
                               

                }

public String getExecutedBudget4()

    {
                MDFExecutedQ4User=getConvertedCurrencyValue(MDFExecutedQ4,RequestCurrency2);
                ExecutedBudget4='USD'+Convert(MDFExecutedQ4)+' ('+UserMDF.DefaultCurrencyIsoCode+Convert(MDFExecutedQ4User)+')';
                                return ExecutedBudget4;
                                

                }

}