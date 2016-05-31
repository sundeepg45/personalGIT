global class EmailResendService
{
	WebService static void resendEmail(ID tokenRowId) {

		PartnerEmailUtils.resendEmail((ID) tokenRowId);
	}
}