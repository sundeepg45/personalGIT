global class EmailConfirmationURLController {
	public String userid { get; set; }
	public String email { get; set; }

	public String getEmailConfirmationURL() {
		String token = PartnerEmailUtils.generateEmailToken(userid, email);
		System.debug('*****[debug]***** token=' + token);
		return PartnerEmailUtils.getEmailConfirmationFullURL(token);
	}
}