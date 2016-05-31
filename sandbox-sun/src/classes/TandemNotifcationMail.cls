public class TandemNotifcationMail
{
	public Boolean mailSent = false;
	String[] toAddresses =new String[0];
	String body='';
	String subject='';
	String AccountName='';


	public void sendMail(){

		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		//String[] ccAddresses =new String[] {'prasadkothawade@gmail.com'};

		// For some strange reason this was commented out, causing this 
		// method to ALWAYS fail.   As such, we are uncommenting this line
		// and instead disabling the trigger.
		mail.setToAddresses(toAddresses);
		//mail.setCcAddresses(ccAddresses);


		// Specify the name used as the display name.
		mail.setSenderDisplayName('SALES FORCE');

		// Specify the subject line for your email address.
		mail.setSubject(subject);

		// Set to True if you want to BCC yourself on the email.
		mail.setBccSender(false);
		// Optionally append the salesforce.com email signature to the email.
		// The email address of the user executing the Apex Code will be used.
		mail.setUseSignature(false);
		// Specify the text content of the email.
		mail.setPlainTextBody(body);

		Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail } );
		mailSent = true;
	}

	public void createMail(Opportunity TandemOpp)
	{
		try
		{

			getAccount(TandemOpp.accountid);
			createToAddress(TandemOpp.accountid);
			createBody(TandemOpp);
			createSubject(TandemOpp,'created');
			sendMail();

		}
		catch(Exception e)
		{
			System.debug('Exception is => + for opp ' + TandemOpp +'   ' +e.getMessage());
		}
	}

	public void createMailOnTandemOppUpdate(Opportunity oldTandemOpp,Opportunity newTandemOpp)
	{
		try
		{

			getAccount(newTandemOpp.accountid);
			createToAddress(newTandemOpp.accountid);
			createBody2(oldTandemOpp,newTandemOpp);
			createSubject(newTandemOpp,'updated');

			sendMail();

		}
		catch(Exception e)
		{
			System.debug('Exception is => ' + e.getMessage());
		}
	}

	void createToAddress(String accid){
		AccountTeamMember[] teammember= [Select Id, UserId, User.Email from AccountTeamMember where AccountId =:accid ];
		for(AccountTeamMember member:teammember ){
			toAddresses.add(member.User.Email);
		}
		System.debug(toAddresses);
		//toAddresses.add('prasad.s.kothawade@accenture.com') ;

	}

	void createBody(Opportunity opp){

		//String AccountName=AccountName;
		String OppName=opp.name;
		String Amount='' ;
		if( opp.amount==null) {
			Amount='0';
		}
		else{
			Amount=''+opp.amount;
		}

		String CloseDate=''+opp.closeDate;
		String Stage=opp.stageName;
		String sfdcURL=Util.sfdcurl+opp.id;

		body='A new Opportunity was created:\n'+
				'\n Account:'+ AccountName +
				'\n Name:'+ OppName +
				'\n Amount:'+ Amount +
				'\n CloseDate:'+ CloseDate +
				'\n Stage:' +Stage+
				'\n URL:'+ sfdcURL;



	}

	void createSubject(Opportunity opp,String operation){
		subject='Opportunity "'+Opp.Name +'" '+ operation +' for "'+ AccountName+'"';

	}

	void getAccount(String accid){
		Account acc= [Select name from Account where Id =:accid limit 1];
		AccountName=acc.name;
	}

	void createBody2(Opportunity oldOpp,Opportunity newOpp){


		String sfdcURL=Util.sfdcurl+newOpp.id;

		body ='\n The following opportunity was updated: \n' +
		'\n Account:' +AccountName+
		'\n Name:'+newOpp.name+
		'\n URL:' +sfdcURL+
		'\n Old Values \n ' +
		'Stage ' + oldOpp.StageName +'\n'+
		'Close Date ' + oldOpp.CloseDate+ ' \n '+
		'Amount ' + oldOpp.amount + ' \n '+
		'\n New Values \n ' +
		'Stage ' + newOpp.StageName +'\n'+
		'Close Date ' + newOpp.CloseDate+ ' \n '+
		'Amount ' + newOpp.amount + ' \n ';
	}


}