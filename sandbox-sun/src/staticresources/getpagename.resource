var surl = document.location.pathname.toLowerCase();
//alert('surl=' + surl);
var pagename = '';
if (surl == '/s' || surl == '/s/' || s == '/s/homepage') { pagename = 'Dashboard'}
else if (0 == surl.indexOf('/apex/'.toLowerCase())) { pagename = surl.substring(6,surl.length); }
else if (0 == surl.indexOf('/s/'.toLowerCase())) { pagename = surl.substring(3,surl.length); }
else if (0 == surl.indexOf('/a1e'.toLowerCase())) { pagename = 'Dynamic Group'; }
else if (0 == surl.indexOf('/a1f'.toLowerCase())) { pagename = 'Group Rule'; }
else if (0 == surl.indexOf('/a20'.toLowerCase())) { pagename = 'Headline Link Group Translation'; }
else if (0 == surl.indexOf('/a21'.toLowerCase())) { pagename = 'Headline Link Translation'; }
else if (0 == surl.indexOf('/a22'.toLowerCase())) { pagename = 'Headline Translation'; }
else if (0 == surl.indexOf('/a1G'.toLowerCase())) { pagename = 'Headline Link Group'; }
else if (0 == surl.indexOf('/a1H'.toLowerCase())) { pagename = 'Headline Link'; }
else if (0 == surl.indexOf('/a1I'.toLowerCase())) { pagename = 'Headline'; }
else if (0 == surl.indexOf('/a1J'.toLowerCase())) { pagename = 'Portal Publisher Settings'; }
else if (0 == surl.indexOf('/001'.toLowerCase())) { pagename = 'Account'; }
else if (0 == surl.indexOf('/a0G'.toLowerCase())) { pagename = 'AccountCatalogRelationship'; }
else if (0 == surl.indexOf('/a2T'.toLowerCase())) { pagename = 'Account Change Request Field'; }
else if (0 == surl.indexOf('/a2U'.toLowerCase())) { pagename = 'Account Change Request'; }
else if (0 == surl.indexOf('/1CA'.toLowerCase())) { pagename = 'Account Clean Info'; }
else if (0 == surl.indexOf('/02Z'.toLowerCase())) { pagename = 'Account Contact Role'; }
else if (0 == surl.indexOf('/a4j'.toLowerCase())) { pagename = 'Account Hierarchy'; }
else if (0 == surl.indexOf('/a3z'.toLowerCase())) { pagename = 'Account Profile Partner Status'; }
else if (0 == surl.indexOf('/a3m'.toLowerCase())) { pagename = 'Account (Read Only)'; }
else if (0 == surl.indexOf('/a1x'.toLowerCase())) { pagename = 'AccountRecordType'; }
else if (0 == surl.indexOf('/00r'.toLowerCase())) { pagename = 'Account Share'; }
else if (0 == surl.indexOf('/01M'.toLowerCase())) { pagename = 'Account Team Member'; }
else if (0 == surl.indexOf('/a1P'.toLowerCase())) { pagename = 'Account Team Rule'; }
else if (0 == surl.indexOf('/a40'.toLowerCase())) { pagename = 'Account Profile Other Partner'; }
else if (0 == surl.indexOf('/a41'.toLowerCase())) { pagename = 'Account Profile Power Map Entry'; }
else if (0 == surl.indexOf('/a42'.toLowerCase())) { pagename = 'Account Profile SWOT'; }
else if (0 == surl.indexOf('/a0N'.toLowerCase())) { pagename = 'Account Profile'; }
else if (0 == surl.indexOf('/a0S'.toLowerCase())) { pagename = 'Account SWOT Analysis'; }
else if (0 == surl.indexOf('/a3x'.toLowerCase())) { pagename = 'Account - Special Program'; }
else if (0 == surl.indexOf('/a1X'.toLowerCase())) { pagename = 'AcctPicklistSync'; }
else if (0 == surl.indexOf('/a2b'.toLowerCase())) { pagename = 'Action Item'; }
else if (0 == surl.indexOf('/04m'.toLowerCase())) { pagename = 'Additional Directory Number'; }
else if (0 == surl.indexOf('/a3R'.toLowerCase())) { pagename = 'Admin By Pass'; }
else if (0 == surl.indexOf('/a1Q'.toLowerCase())) { pagename = 'Agreement Country'; }
else if (0 == surl.indexOf('/a1R'.toLowerCase())) { pagename = 'Agreement'; }
else if (0 == surl.indexOf('/a3s'.toLowerCase())) { pagename = 'Anti-Corruption'; }
else if (0 == surl.indexOf('/01p'.toLowerCase())) { pagename = 'Apex Class'; }
else if (0 == surl.indexOf('/099'.toLowerCase())) { pagename = 'Visualforce Component'; }
else if (0 == surl.indexOf('/07L'.toLowerCase())) { pagename = 'Apex Debug Log'; }
else if (0 == surl.indexOf('/066'.toLowerCase())) { pagename = 'Visualforce Page'; }
else if (0 == surl.indexOf('/709'.toLowerCase())) { pagename = 'Apex Test Queue Item'; }
else if (0 == surl.indexOf('/07M'.toLowerCase())) { pagename = 'Apex Test Result'; }
else if (0 == surl.indexOf('/01q'.toLowerCase())) { pagename = 'Apex Trigger'; }
else if (0 == surl.indexOf('/0DS'.toLowerCase())) { pagename = 'AppMenuItem'; }
else if (0 == surl.indexOf('/806'.toLowerCase())) { pagename = 'Approval'; }
else if (0 == surl.indexOf('/a0M'.toLowerCase())) { pagename = 'Approval'; }
else if (0 == surl.indexOf('/a0U'.toLowerCase())) { pagename = 'Assessment Summary'; }
else if (0 == surl.indexOf('/02i'.toLowerCase())) { pagename = 'Asset'; }
else if (0 == surl.indexOf('/01Q'.toLowerCase())) { pagename = 'Assignment Rule'; }
else if (0 == surl.indexOf('/707'.toLowerCase())) { pagename = 'Apex Job'; }
else if (0 == surl.indexOf('/00P'.toLowerCase())) { pagename = 'Attachment'; }
else if (0 == surl.indexOf('/a2F'.toLowerCase())) { pagename = 'Audience'; }
else if (0 == surl.indexOf('/0Ak'.toLowerCase())) { pagename = 'Auth Session'; }
else if (0 == surl.indexOf('/a0k'.toLowerCase())) { pagename = 'DreamFactory Shared View'; }
else if (0 == surl.indexOf('/a0l'.toLowerCase())) { pagename = 'Carousel'; }
else if (0 == surl.indexOf('/a0m'.toLowerCase())) { pagename = 'Slide'; }
else if (0 == surl.indexOf('/a0n'.toLowerCase())) { pagename = 'DreamTeam Action Item'; }
else if (0 == surl.indexOf('/a0o'.toLowerCase())) { pagename = 'DreamTeam Discussion'; }
else if (0 == surl.indexOf('/a0p'.toLowerCase())) { pagename = 'DreamTeam Highlight'; }
else if (0 == surl.indexOf('/a0q'.toLowerCase())) { pagename = 'DreamTeam Issue'; }
else if (0 == surl.indexOf('/a0r'.toLowerCase())) { pagename = 'DreamTeam Linker'; }
else if (0 == surl.indexOf('/a0s'.toLowerCase())) { pagename = 'DreamTeam Project'; }
else if (0 == surl.indexOf('/a0t'.toLowerCase())) { pagename = 'DreamTeam Resource'; }
else if (0 == surl.indexOf('/a0u'.toLowerCase())) { pagename = 'DreamTeam Task'; }
else if (0 == surl.indexOf('/a0v'.toLowerCase())) { pagename = 'Form'; }
else if (0 == surl.indexOf('/a0w'.toLowerCase())) { pagename = 'Page'; }
else if (0 == surl.indexOf('/a0x'.toLowerCase())) { pagename = 'DreamTeam Expense'; }
else if (0 == surl.indexOf('/a0y'.toLowerCase())) { pagename = 'DreamTeam Time'; }
else if (0 == surl.indexOf('/a0z'.toLowerCase())) { pagename = 'TableTop Document'; }
else if (0 == surl.indexOf('/a10'.toLowerCase())) { pagename = 'TableTop Entity Info'; }
else if (0 == surl.indexOf('/a11'.toLowerCase())) { pagename = 'TableTop Folder'; }
else if (0 == surl.indexOf('/a34'.toLowerCase())) { pagename = 'BigMachines Commerce Settings'; }
else if (0 == surl.indexOf('/a35'.toLowerCase())) { pagename = 'BigMachines Site'; }
else if (0 == surl.indexOf('/a36'.toLowerCase())) { pagename = 'Field Mapping'; }
else if (0 == surl.indexOf('/a37'.toLowerCase())) { pagename = 'Quote Product'; }
else if (0 == surl.indexOf('/a38'.toLowerCase())) { pagename = 'Quote'; }
else if (0 == surl.indexOf('/a4X'.toLowerCase())) { pagename = 'Bill To Account'; }
else if (0 == surl.indexOf('/a1p'.toLowerCase())) { pagename = 'Boolean Setting'; }
else if (0 == surl.indexOf('/016'.toLowerCase())) { pagename = 'Letterhead'; }
else if (0 == surl.indexOf('/a4Y'.toLowerCase())) { pagename = 'Business Plan KPI'; }
else if (0 == surl.indexOf('/01m'.toLowerCase())) { pagename = 'Business Hours'; }
else if (0 == surl.indexOf('/a28'.toLowerCase())) { pagename = 'Business Plan Marketing Resource'; }
else if (0 == surl.indexOf('/019'.toLowerCase())) { pagename = 'Business Process'; }
else if (0 == surl.indexOf('/a29'.toLowerCase())) { pagename = 'Business Plan Customer'; }
else if (0 == surl.indexOf('/a0T'.toLowerCase())) { pagename = 'Potential Opportunity'; }
else if (0 == surl.indexOf('/a06'.toLowerCase())) { pagename = 'Change Control Event'; }
else if (0 == surl.indexOf('/a2x'.toLowerCase())) { pagename = 'Field Statistic'; }
else if (0 == surl.indexOf('/a2y'.toLowerCase())) { pagename = 'Object Statistic'; }
else if (0 == surl.indexOf('/04v'.toLowerCase())) { pagename = 'Call Center'; }
else if (0 == surl.indexOf('/701'.toLowerCase())) { pagename = 'Campaign'; }
else if (0 == surl.indexOf('/00v'.toLowerCase())) { pagename = 'Campaign Member'; }
else if (0 == surl.indexOf('/01Y'.toLowerCase())) { pagename = 'Campaign Member Status'; }
else if (0 == surl.indexOf('/08s'.toLowerCase())) { pagename = 'Campaign Share'; }
else if (0 == surl.indexOf('/a3n'.toLowerCase())) { pagename = 'Campaign Tag'; }
else if (0 == surl.indexOf('/a44'.toLowerCase())) { pagename = 'Campaign Hierarchy Details'; }
else if (0 == surl.indexOf('/a17'.toLowerCase())) { pagename = 'Campaign Plan'; }
else if (0 == surl.indexOf('/500'.toLowerCase())) { pagename = 'Case'; }
else if (0 == surl.indexOf('/00a'.toLowerCase())) { pagename = 'Case Comment'; }
else if (0 == surl.indexOf('/a3v'.toLowerCase())) { pagename = 'Case Comment Data'; }
else if (0 == surl.indexOf('/03j'.toLowerCase())) { pagename = 'Case Contact Role'; }
else if (0 == surl.indexOf('/a3q'.toLowerCase())) { pagename = 'Case Priority Totals'; }
else if (0 == surl.indexOf('/a3r'.toLowerCase())) { pagename = 'Case Priority'; }
else if (0 == surl.indexOf('/a3y'.toLowerCase())) { pagename = 'Case Record Type'; }
else if (0 == surl.indexOf('/01n'.toLowerCase())) { pagename = 'Case Share'; }
else if (0 == surl.indexOf('/010'.toLowerCase())) { pagename = 'Case Solution'; }
else if (0 == surl.indexOf('/02o'.toLowerCase())) { pagename = 'Category Data'; }
else if (0 == surl.indexOf('/02n'.toLowerCase())) { pagename = 'Category Node'; }
else if (0 == surl.indexOf('/a05'.toLowerCase())) { pagename = 'Change Control Board (CCB)'; }
else if (0 == surl.indexOf('/a01'.toLowerCase())) { pagename = 'Change Management'; }
else if (0 == surl.indexOf('/a07'.toLowerCase())) { pagename = 'Change Request Member'; }
else if (0 == surl.indexOf('/a04'.toLowerCase())) { pagename = 'Change Request'; }
else if (0 == surl.indexOf('/0ca'.toLowerCase())) { pagename = 'Chatter Activity'; }
else if (0 == surl.indexOf('/03M'.toLowerCase())) { pagename = 'Chatter Conversation'; }
else if (0 == surl.indexOf('/03N'.toLowerCase())) { pagename = 'Chatter Conversation Member'; }
else if (0 == surl.indexOf('/03J'.toLowerCase())) { pagename = 'Chatter Message'; }
else if (0 == surl.indexOf('/a2z'.toLowerCase())) { pagename = 'Chatter Group Name'; }
else if (0 == surl.indexOf('/a1S'.toLowerCase())) { pagename = 'Classification Translation'; }
else if (0 == surl.indexOf('/a1T'.toLowerCase())) { pagename = 'Classification'; }
else if (0 == surl.indexOf('/713'.toLowerCase())) { pagename = 'Client Browser'; }
else if (0 == surl.indexOf('/0F9'.toLowerCase())) { pagename = 'Group'; }
else if (0 == surl.indexOf('/0FB'.toLowerCase())) { pagename = 'Group Member'; }
else if (0 == surl.indexOf('/0I5'.toLowerCase())) { pagename = 'Group Member Request'; }
else if (0 == surl.indexOf('/0H1'.toLowerCase())) { pagename = 'Chatter Invitation'; }
else if (0 == surl.indexOf('/a2E'.toLowerCase())) { pagename = 'Communities Utils'; }
else if (0 == surl.indexOf('/a2J'.toLowerCase())) { pagename = 'Communities Navigation Item Label'; }
else if (0 == surl.indexOf('/a2K'.toLowerCase())) { pagename = 'Communities Navigation Item'; }
else if (0 == surl.indexOf('/a2G'.toLowerCase())) { pagename = 'Communities News Item Label'; }
else if (0 == surl.indexOf('/a2H'.toLowerCase())) { pagename = 'Communities News Item'; }
else if (0 == surl.indexOf('/09a'.toLowerCase())) { pagename = 'Zone'; }
else if (0 == surl.indexOf('/a0R'.toLowerCase())) { pagename = 'Competitor'; }
else if (0 == surl.indexOf('/a2f'.toLowerCase())) { pagename = 'Configuration'; }
else if (0 == surl.indexOf('/003'.toLowerCase())) { pagename = 'Contact'; }
else if (0 == surl.indexOf('/1CC'.toLowerCase())) { pagename = 'Contact Clean Info'; }
else if (0 == surl.indexOf('/03s'.toLowerCase())) { pagename = 'Contact Share'; }
else if (0 == surl.indexOf('/a1w'.toLowerCase())) { pagename = 'Contact Converter'; }
else if (0 == surl.indexOf('/a1K'.toLowerCase())) { pagename = 'Contact Reference Request'; }
else if (0 == surl.indexOf('/a4Z'.toLowerCase())) { pagename = 'Partner Track / Contact Association'; }
else if (0 == surl.indexOf('/069'.toLowerCase())) { pagename = 'Content'; }
else if (0 == surl.indexOf('/06A'.toLowerCase())) { pagename = 'Content Document Link'; }
else if (0 == surl.indexOf('/068'.toLowerCase())) { pagename = 'Content'; }
else if (0 == surl.indexOf('/058'.toLowerCase())) { pagename = 'Library'; }
else if (0 == surl.indexOf('/059'.toLowerCase())) { pagename = 'Library Document'; }
else if (0 == surl.indexOf('/800'.toLowerCase())) { pagename = 'Contract'; }
else if (0 == surl.indexOf('/02a'.toLowerCase())) { pagename = 'Contract Contact Role'; }
else if (0 == surl.indexOf('/a1Y'.toLowerCase())) { pagename = 'Country Translation'; }
else if (0 == surl.indexOf('/a1U'.toLowerCase())) { pagename = 'Country'; }
else if (0 == surl.indexOf('/a09'.toLowerCase())) { pagename = 'Credit Check'; }
else if (0 == surl.indexOf('/08a'.toLowerCase())) { pagename = 'Cron Job'; }
else if (0 == surl.indexOf('/08e'.toLowerCase())) { pagename = 'Scheduled Jobs'; }
else if (0 == surl.indexOf('/01L'.toLowerCase())) { pagename = 'Currency Type'; }
else if (0 == surl.indexOf('/07W'.toLowerCase())) { pagename = 'Custom Brand'; }
else if (0 == surl.indexOf('/07X'.toLowerCase())) { pagename = 'Custom Brand Asset'; }
else if (0 == surl.indexOf('/a1L'.toLowerCase())) { pagename = 'Customer Reference Product'; }
else if (0 == surl.indexOf('/a1M'.toLowerCase())) { pagename = 'Customer Reference'; }
else if (0 == surl.indexOf('/06E'.toLowerCase())) { pagename = 'D&B Company'; }
else if (0 == surl.indexOf('/01Z'.toLowerCase())) { pagename = 'Dashboard'; }
else if (0 == surl.indexOf('/01a'.toLowerCase())) { pagename = 'Dashboard Component'; }
else if (0 == surl.indexOf('/09O'.toLowerCase())) { pagename = 'Data.com Owned Entity'; }
else if (0 == surl.indexOf('/09F'.toLowerCase())) { pagename = 'Data.com Usage'; }
else if (0 == surl.indexOf('/a3o'.toLowerCase())) { pagename = 'DateTime Setting'; }
else if (0 == surl.indexOf('/04w'.toLowerCase())) { pagename = 'Dated Conversion Rate'; }
else if (0 == surl.indexOf('/a3S'.toLowerCase())) { pagename = 'Default Record Types'; }
else if (0 == surl.indexOf('/015'.toLowerCase())) { pagename = 'Document'; }
else if (0 == surl.indexOf('/05X'.toLowerCase())) { pagename = 'Document Entity Map'; }
else if (0 == surl.indexOf('/0I4'.toLowerCase())) { pagename = 'Domain'; }
else if (0 == surl.indexOf('/0Jf'.toLowerCase())) { pagename = 'Custom URL'; }
else if (0 == surl.indexOf('/a24'.toLowerCase())) { pagename = 'Campaigns Marketing Asset'; }
else if (0 == surl.indexOf('/a25'.toLowerCase())) { pagename = 'Marketing Activity'; }
else if (0 == surl.indexOf('/a26'.toLowerCase())) { pagename = 'Marketing Asset'; }
else if (0 == surl.indexOf('/02s'.toLowerCase())) { pagename = 'Email Message'; }
else if (0 == surl.indexOf('/093'.toLowerCase())) { pagename = 'Email Services Address'; }
else if (0 == surl.indexOf('/091'.toLowerCase())) { pagename = 'Email Service'; }
else if (0 == surl.indexOf('/018'.toLowerCase())) { pagename = 'Email Status'; }
else if (0 == surl.indexOf('/00X'.toLowerCase())) { pagename = 'Email Template'; }
else if (0 == surl.indexOf('/a4S'.toLowerCase())) { pagename = 'Embedded Override'; }
else if (0 == surl.indexOf('/a4T'.toLowerCase())) { pagename = 'Embedded SKU'; }
else if (0 == surl.indexOf('/0E8'.toLowerCase())) { pagename = 'Entity Subscription'; }
else if (0 == surl.indexOf('/a4A'.toLowerCase())) { pagename = 'Environment'; }
else if (0 == surl.indexOf('/a0L'.toLowerCase())) { pagename = 'Evaluation'; }
else if (0 == surl.indexOf('/00U'.toLowerCase())) { pagename = 'Event'; }
else if (0 == surl.indexOf('/0RE'.toLowerCase())) { pagename = 'Event Relation'; }
else if (0 == surl.indexOf('/a16'.toLowerCase())) { pagename = 'Executive Summary'; }
else if (0 == surl.indexOf('/a1z'.toLowerCase())) { pagename = 'Expiring Product'; }
else if (0 == surl.indexOf('/0D7'.toLowerCase())) { pagename = 'Feed Comment'; }
else if (0 == surl.indexOf('/0D5'.toLowerCase())) { pagename = 'Feed Item'; }
else if (0 == surl.indexOf('/0I0'.toLowerCase())) { pagename = 'Feed Like'; }
else if (0 == surl.indexOf('/09A'.toLowerCase())) { pagename = 'Feed Poll Choice'; }
else if (0 == surl.indexOf('/09B'.toLowerCase())) { pagename = 'Feed Poll Vote'; }
else if (0 == surl.indexOf('/0D6'.toLowerCase())) { pagename = 'Feed Tracked Change'; }
else if (0 == surl.indexOf('/a4B'.toLowerCase())) { pagename = 'Field Id'; }
else if (0 == surl.indexOf('/01k'.toLowerCase())) { pagename = 'Field Permissions'; }
else if (0 == surl.indexOf('/a0K'.toLowerCase())) { pagename = 'Fiscal Goals'; }
else if (0 == surl.indexOf('/022'.toLowerCase())) { pagename = 'Fiscal Year Settings'; }
else if (0 == surl.indexOf('/00l'.toLowerCase())) { pagename = 'Folder'; }
else if (0 == surl.indexOf('/608'.toLowerCase())) { pagename = 'Forecast Share'; }
else if (0 == surl.indexOf('/00G'.toLowerCase())) { pagename = 'Group'; }
else if (0 == surl.indexOf('/011'.toLowerCase())) { pagename = 'Group Member'; }
else if (0 == surl.indexOf('/a4Q'.toLowerCase())) { pagename = 'Group Setting'; }
else if (0 == surl.indexOf('/a4R'.toLowerCase())) { pagename = 'Hashes'; }
else if (0 == surl.indexOf('/0hd'.toLowerCase())) { pagename = 'Hashtag Definition'; }
else if (0 == surl.indexOf('/0C0'.toLowerCase())) { pagename = 'Holiday'; }
else if (0 == surl.indexOf('/087'.toLowerCase())) { pagename = 'Idea'; }
else if (0 == surl.indexOf('/00a'.toLowerCase())) { pagename = 'Idea Comment'; }
else if (0 == surl.indexOf('/a12'.toLowerCase())) { pagename = 'Key Joint Sales Engagement'; }
else if (0 == surl.indexOf('/a1d'.toLowerCase())) { pagename = 'LMS Training Request'; }
else if (0 == surl.indexOf('/00Q'.toLowerCase())) { pagename = 'Lead'; }
else if (0 == surl.indexOf('/a0e'.toLowerCase())) { pagename = 'LD Account Mapping'; }
else if (0 == surl.indexOf('/1CL'.toLowerCase())) { pagename = 'Lead Clean Info'; }
else if (0 == surl.indexOf('/a4k'.toLowerCase())) { pagename = 'Lead Convert Wizard Opp Default Amount'; }
else if (0 == surl.indexOf('/a4l'.toLowerCase())) { pagename = 'Lead Convert Wizard Opp Default Stage'; }
else if (0 == surl.indexOf('/a0h'.toLowerCase())) { pagename = 'LD Country Mapping'; }
else if (0 == surl.indexOf('/a2e'.toLowerCase())) { pagename = 'Lead Cron Routing Rule'; }
else if (0 == surl.indexOf('/a2C'.toLowerCase())) { pagename = 'Lead (For Reporting)'; }
else if (0 == surl.indexOf('/a2c'.toLowerCase())) { pagename = 'Lead Management History'; }
else if (0 == surl.indexOf('/a0i'.toLowerCase())) { pagename = 'LD Other Mapping'; }
else if (0 == surl.indexOf('/01o'.toLowerCase())) { pagename = 'Lead Share'; }
else if (0 == surl.indexOf('/a2r'.toLowerCase())) { pagename = 'LeadShareStaging'; }
else if (0 == surl.indexOf('/a0I'.toLowerCase())) { pagename = 'Lead Source Detail'; }
else if (0 == surl.indexOf('/a1F'.toLowerCase())) { pagename = 'Lead SuperRegion Mapping'; }
else if (0 == surl.indexOf('/029'.toLowerCase())) { pagename = 'Lineitem Override'; }
else if (0 == surl.indexOf('/a4U'.toLowerCase())) { pagename = 'Link to Paid Opportunity'; }
else if (0 == surl.indexOf('/0Ya'.toLowerCase())) { pagename = 'Login History'; }
else if (0 == surl.indexOf('/710'.toLowerCase())) { pagename = 'Login IP'; }
else if (0 == surl.indexOf('/a2Z'.toLowerCase())) { pagename = 'Long Setting'; }
else if (0 == surl.indexOf('/01H'.toLowerCase())) { pagename = 'Mail Merge Template'; }
else if (0 == surl.indexOf('/a0j'.toLowerCase())) { pagename = 'Marketing Activity'; }
else if (0 == surl.indexOf('/a19'.toLowerCase())) { pagename = 'Marketing Program'; }
else if (0 == surl.indexOf('/a0O'.toLowerCase())) { pagename = 'Messaging Strategy'; }
else if (0 == surl.indexOf('/0IG'.toLowerCase())) { pagename = 'Mobile Device Registrar'; }
else if (0 == surl.indexOf('/a3U'.toLowerCase())) { pagename = 'Monitored Activity'; }
else if (0 == surl.indexOf('/a1a'.toLowerCase())) { pagename = 'NFR Line Item'; }
else if (0 == surl.indexOf('/a1b'.toLowerCase())) { pagename = 'NFR'; }
else if (0 == surl.indexOf('/a1V'.toLowerCase())) { pagename = 'NFR SKU Matrix'; }
else if (0 == surl.indexOf('/0DB'.toLowerCase())) { pagename = 'Network'; }
else if (0 == surl.indexOf('/0DO'.toLowerCase())) { pagename = 'Network Member'; }
else if (0 == surl.indexOf('/0DL'.toLowerCase())) { pagename = 'Network Member Group'; }
else if (0 == surl.indexOf('/a03'.toLowerCase())) { pagename = 'Non-Primary Billing Address'; }
else if (0 == surl.indexOf('/a00'.toLowerCase())) { pagename = 'Non-Primary Shipping Address'; }
else if (0 == surl.indexOf('/002'.toLowerCase())) { pagename = 'Note'; }
else if (0 == surl.indexOf('/110'.toLowerCase())) { pagename = 'Object Permissions'; }
else if (0 == surl.indexOf('/a45'.toLowerCase())) { pagename = 'Opportunities - Special Program'; }
else if (0 == surl.indexOf('/006'.toLowerCase())) { pagename = 'Opportunity'; }
else if (0 == surl.indexOf('/00J'.toLowerCase())) { pagename = 'Opportunity: Competitor'; }
else if (0 == surl.indexOf('/00K'.toLowerCase())) { pagename = 'Opportunity Contact Role'; }
else if (0 == surl.indexOf('/008'.toLowerCase())) { pagename = 'Opportunity History'; }
else if (0 == surl.indexOf('/00k'.toLowerCase())) { pagename = 'Opportunity Product'; }
else if (0 == surl.indexOf('/00o'.toLowerCase())) { pagename = 'Line Item Schedule'; }
else if (0 == surl.indexOf('/028'.toLowerCase())) { pagename = 'Opportunity Override'; }
else if (0 == surl.indexOf('/a1y'.toLowerCase())) { pagename = 'Opportunity Partner'; }
else if (0 == surl.indexOf('/a4C'.toLowerCase())) { pagename = 'Opportunity Product Summary'; }
else if (0 == surl.indexOf('/00t'.toLowerCase())) { pagename = 'Opportunity Share'; }
else if (0 == surl.indexOf('/a3Y'.toLowerCase())) { pagename = 'Opportunity Snapshot'; }
else if (0 == surl.indexOf('/00q'.toLowerCase())) { pagename = 'Opportunity Team Member'; }
else if (0 == surl.indexOf('/a2A'.toLowerCase())) { pagename = 'Opportunity Team Member Clone'; }
else if (0 == surl.indexOf('/a0d'.toLowerCase())) { pagename = 'Opportunity History'; }
else if (0 == surl.indexOf('/0D2'.toLowerCase())) { pagename = 'Organization-wide From Email Address'; }
else if (0 == surl.indexOf('/00D'.toLowerCase())) { pagename = 'Organization'; }
else if (0 == surl.indexOf('/a2M'.toLowerCase())) { pagename = 'PAR MDF Allocations'; }
else if (0 == surl.indexOf('/a2L'.toLowerCase())) { pagename = 'PAR Pilot Account'; }
else if (0 == surl.indexOf('/a2V'.toLowerCase())) { pagename = 'Product Catalog Search Form'; }
else if (0 == surl.indexOf('/a2W'.toLowerCase())) { pagename = 'Partner Finder Search Form'; }
else if (0 == surl.indexOf('/a2B'.toLowerCase())) { pagename = 'POC Enabled'; }
else if (0 == surl.indexOf('/a3B'.toLowerCase())) { pagename = 'Partner Points: Account Points'; }
else if (0 == surl.indexOf('/a3C'.toLowerCase())) { pagename = 'Partner Points: Bulk Upload Score Item'; }
else if (0 == surl.indexOf('/a3D'.toLowerCase())) { pagename = 'Partner Points: Cap'; }
else if (0 == surl.indexOf('/a3E'.toLowerCase())) { pagename = 'Partner Points: Catalog Category'; }
else if (0 == surl.indexOf('/a3F'.toLowerCase())) { pagename = 'Partner Points: Content Batch Stage'; }
else if (0 == surl.indexOf('/a3G'.toLowerCase())) { pagename = 'Partner Points: Content Stage'; }
else if (0 == surl.indexOf('/a3H'.toLowerCase())) { pagename = 'Partner Points: Content Workspace'; }
else if (0 == surl.indexOf('/a3I'.toLowerCase())) { pagename = 'Partner Points: Content Score Item'; }
else if (0 == surl.indexOf('/a3J'.toLowerCase())) { pagename = 'Partner Points: Batch Inbound Item Stage'; }
else if (0 == surl.indexOf('/a3K'.toLowerCase())) { pagename = 'Partner Points: Batch Stage Inbound'; }
else if (0 == surl.indexOf('/a3L'.toLowerCase())) { pagename = 'Partner Points: Item Audit Record'; }
else if (0 == surl.indexOf('/a3M'.toLowerCase())) { pagename = 'Partner Points: LMS Stage'; }
else if (0 == surl.indexOf('/a3N'.toLowerCase())) { pagename = 'Partner Points: Score'; }
else if (0 == surl.indexOf('/a3O'.toLowerCase())) { pagename = 'Partner Points: User Points'; }
else if (0 == surl.indexOf('/00I'.toLowerCase())) { pagename = 'Partner'; }
else if (0 == surl.indexOf('/a1g'.toLowerCase())) { pagename = 'Partner Agreement'; }
else if (0 == surl.indexOf('/a1m'.toLowerCase())) { pagename = 'Partner Classification'; }
else if (0 == surl.indexOf('/a1n'.toLowerCase())) { pagename = 'Partner Logo'; }
else if (0 == surl.indexOf('/a1h'.toLowerCase())) { pagename = 'Partner Product Classification'; }
else if (0 == surl.indexOf('/a1q'.toLowerCase())) { pagename = 'Partner Product Language'; }
else if (0 == surl.indexOf('/a1i'.toLowerCase())) { pagename = 'Partner Product Logo'; }
else if (0 == surl.indexOf('/a1j'.toLowerCase())) { pagename = 'Partner Product Screenshot'; }
else if (0 == surl.indexOf('/a1k'.toLowerCase())) { pagename = 'Partner Product'; }
else if (0 == surl.indexOf('/a2O'.toLowerCase())) { pagename = 'Partner Requalification'; }
else if (0 == surl.indexOf('/a1c'.toLowerCase())) { pagename = 'Partner Status'; }
else if (0 == surl.indexOf('/a1o'.toLowerCase())) { pagename = 'Partner Top Customer'; }
else if (0 == surl.indexOf('/a4a'.toLowerCase())) { pagename = 'Partner Track'; }
else if (0 == surl.indexOf('/a1l'.toLowerCase())) { pagename = 'Partner Accreditation'; }
else if (0 == surl.indexOf('/a3t'.toLowerCase())) { pagename = 'Partner User Email Token'; }
else if (0 == surl.indexOf('/a18'.toLowerCase())) { pagename = 'Partner Attachment'; }
else if (0 == surl.indexOf('/a2X'.toLowerCase())) { pagename = 'Partner Location'; }
else if (0 == surl.indexOf('/a4b'.toLowerCase())) { pagename = 'Partner Point Requal Limits'; }
else if (0 == surl.indexOf('/a4c'.toLowerCase())) { pagename = 'Partner_Points_Course'; }
else if (0 == surl.indexOf('/a3P'.toLowerCase())) { pagename = 'Partner Points: LMS Score Item'; }
else if (0 == surl.indexOf('/a4d'.toLowerCase())) { pagename = 'Partner Points: Requal Requirement'; }
else if (0 == surl.indexOf('/a39'.toLowerCase())) { pagename = 'Partner Points'; }
else if (0 == surl.indexOf('/a0Z'.toLowerCase())) { pagename = 'Partner Profile'; }
else if (0 == surl.indexOf('/a0a'.toLowerCase())) { pagename = 'Partner Program Definition'; }
else if (0 == surl.indexOf('/a48'.toLowerCase())) { pagename = 'Partner Program Description'; }
else if (0 == surl.indexOf('/a49'.toLowerCase())) { pagename = 'Partner Program Product'; }
else if (0 == surl.indexOf('/a47'.toLowerCase())) { pagename = 'Partner Program'; }
else if (0 == surl.indexOf('/a4e'.toLowerCase())) { pagename = 'Partner Requal Points'; }
else if (0 == surl.indexOf('/a2P'.toLowerCase())) { pagename = 'Partner Requal Setup'; }
else if (0 == surl.indexOf('/a2Q'.toLowerCase())) { pagename = 'Partner Requalification Agreement'; }
else if (0 == surl.indexOf('/a2R'.toLowerCase())) { pagename = 'Partner Requalification Event Log'; }
else if (0 == surl.indexOf('/a2v'.toLowerCase())) { pagename = 'Partner User Invitation'; }
else if (0 == surl.indexOf('/a0X'.toLowerCase())) { pagename = 'Partners Assessment Summary'; }
else if (0 == surl.indexOf('/a0V'.toLowerCase())) { pagename = 'Partners Business Problem'; }
else if (0 == surl.indexOf('/a0W'.toLowerCase())) { pagename = 'Partners Competitor'; }
else if (0 == surl.indexOf('/a0Y'.toLowerCase())) { pagename = 'Partners Messaging Strategy'; }
else if (0 == surl.indexOf('/026'.toLowerCase())) { pagename = 'Period'; }
else if (0 == surl.indexOf('/0PS'.toLowerCase())) { pagename = 'Permission Set'; }
else if (0 == surl.indexOf('/0Pa'.toLowerCase())) { pagename = 'Permission Set Assignment'; }
else if (0 == surl.indexOf('/0PL'.toLowerCase())) { pagename = 'Permission Set License'; }
else if (0 == surl.indexOf('/2LA'.toLowerCase())) { pagename = 'Permission Set License Assignment'; }
else if (0 == surl.indexOf('/01s'.toLowerCase())) { pagename = 'Price Book'; }
else if (0 == surl.indexOf('/01u'.toLowerCase())) { pagename = 'Price Book Entry'; }
else if (0 == surl.indexOf('/a02'.toLowerCase())) { pagename = 'Priority'; }
else if (0 == surl.indexOf('/04g'.toLowerCase())) { pagename = 'Process Instance'; }
else if (0 == surl.indexOf('/04h'.toLowerCase())) { pagename = 'Process Instance Step'; }
else if (0 == surl.indexOf('/04i'.toLowerCase())) { pagename = 'Approval Request'; }
else if (0 == surl.indexOf('/01t'.toLowerCase())) { pagename = 'Product'; }
else if (0 == surl.indexOf('/00e'.toLowerCase())) { pagename = 'Profile'; }
else if (0 == surl.indexOf('/a0J'.toLowerCase())) { pagename = 'Project Status'; }
else if (0 == surl.indexOf('/a0f'.toLowerCase())) { pagename = 'Project Tracker'; }
else if (0 == surl.indexOf('/a3p'.toLowerCase())) { pagename = 'Proxy Approver'; }
else if (0 == surl.indexOf('/0IF'.toLowerCase())) { pagename = 'Push Topic'; }
else if (0 == surl.indexOf('/021'.toLowerCase())) { pagename = 'Quantity Forecast'; }
else if (0 == surl.indexOf('/04X'.toLowerCase())) { pagename = 'Quantity Forecast History'; }
else if (0 == surl.indexOf('/03g'.toLowerCase())) { pagename = 'Queue Sobject'; }
else if (0 == surl.indexOf('/a0F'.toLowerCase())) { pagename = 'Quote Line Item Schedule'; }
else if (0 == surl.indexOf('/a0E'.toLowerCase())) { pagename = 'Quote Line Item'; }
else if (0 == surl.indexOf('/a0C'.toLowerCase())) { pagename = 'Quote Payment Schedule'; }
else if (0 == surl.indexOf('/a0Q'.toLowerCase())) { pagename = 'Quote'; }
else if (0 == surl.indexOf('/a3V'.toLowerCase())) { pagename = 'RH Content'; }
else if (0 == surl.indexOf('/a3W'.toLowerCase())) { pagename = 'RH Microsite Page'; }
else if (0 == surl.indexOf('/a3X'.toLowerCase())) { pagename = 'RH Microsite'; }
else if (0 == surl.indexOf('/a3A'.toLowerCase())) { pagename = 'Rally User'; }
else if (0 == surl.indexOf('/a43'.toLowerCase())) { pagename = 'Record Lookup'; }
else if (0 == surl.indexOf('/012'.toLowerCase())) { pagename = 'Record Type'; }
else if (0 == surl.indexOf('/a3T'.toLowerCase())) { pagename = 'Record Type Assignment'; }
else if (0 == surl.indexOf('/a4D'.toLowerCase())) { pagename = 'RecordTypeLookup'; }
else if (0 == surl.indexOf('/a23'.toLowerCase())) { pagename = 'Cached Red Hat Object Ids'; }
else if (0 == surl.indexOf('/a1A'.toLowerCase())) { pagename = 'Red Hat Attachment'; }
else if (0 == surl.indexOf('/a1s'.toLowerCase())) { pagename = 'Account Reference Activity Detail'; }
else if (0 == surl.indexOf('/a1t'.toLowerCase())) { pagename = 'Account Reference Activity'; }
else if (0 == surl.indexOf('/a1u'.toLowerCase())) { pagename = 'Opportunity Reference Activity Detail'; }
else if (0 == surl.indexOf('/a1v'.toLowerCase())) { pagename = 'Opportunity Reference Activity'; }
else if (0 == surl.indexOf('/a1N'.toLowerCase())) { pagename = 'Reference Collateral'; }
else if (0 == surl.indexOf('/a1O'.toLowerCase())) { pagename = 'Reference Usage'; }
else if (0 == surl.indexOf('/a2D'.toLowerCase())) { pagename = 'Region (NA)'; }
else if (0 == surl.indexOf('/a0b'.toLowerCase())) { pagename = 'Region'; }
else if (0 == surl.indexOf('/a2d'.toLowerCase())) { pagename = 'Reject Lead Setup'; }
else if (0 == surl.indexOf('/a0B'.toLowerCase())) { pagename = 'Related Case'; }
else if (0 == surl.indexOf('/a4E'.toLowerCase())) { pagename = 'Remote Access'; }
else if (0 == surl.indexOf('/00O'.toLowerCase())) { pagename = 'Report'; }
else if (0 == surl.indexOf('/a0g'.toLowerCase())) { pagename = 'Presales Request Tracker'; }
else if (0 == surl.indexOf('/a0P'.toLowerCase())) { pagename = 'Reseller'; }
else if (0 == surl.indexOf('/a0D'.toLowerCase())) { pagename = 'Resource'; }
else if (0 == surl.indexOf('/027'.toLowerCase())) { pagename = 'Revenue Forecast'; }
else if (0 == surl.indexOf('/04W'.toLowerCase())) { pagename = 'Revenue Forecast History'; }
else if (0 == surl.indexOf('/a2S'.toLowerCase())) { pagename = 'Role/Interest Training Matrix'; }
else if (0 == surl.indexOf('/a3Z'.toLowerCase())) { pagename = 'Rush Order SKU'; }
else if (0 == surl.indexOf('/a1B'.toLowerCase())) { pagename = 'MDF'; }
else if (0 == surl.indexOf('/a13'.toLowerCase())) { pagename = 'Business Plan'; }
else if (0 == surl.indexOf('/a1C'.toLowerCase())) { pagename = 'Fund Claim'; }
else if (0 == surl.indexOf('/a1D'.toLowerCase())) { pagename = 'Fund Request'; }
else if (0 == surl.indexOf('/a14'.toLowerCase())) { pagename = 'Objective'; }
else if (0 == surl.indexOf('/a15'.toLowerCase())) { pagename = 'Red Hat & Partner Account Team'; }
else if (0 == surl.indexOf('/a2t'.toLowerCase())) { pagename = 'Sales Portal Content Mappings'; }
else if (0 == surl.indexOf('/a2g'.toLowerCase())) { pagename = 'Sales Operations'; }
else if (0 == surl.indexOf('/a2u'.toLowerCase())) { pagename = 'Sales Portal Content'; }
else if (0 == surl.indexOf('/a0H'.toLowerCase())) { pagename = 'Sales Comments'; }
else if (0 == surl.indexOf('/a2h'.toLowerCase())) { pagename = 'Schedule Exports'; }
else if (0 == surl.indexOf('/a2a'.toLowerCase())) { pagename = 'ScheduledApex'; }
else if (0 == surl.indexOf('/01N'.toLowerCase())) { pagename = 'Custom S-Control'; }
else if (0 == surl.indexOf('/035'.toLowerCase())) { pagename = 'CSS User'; }
else if (0 == surl.indexOf('/a4V'.toLowerCase())) { pagename = 'Services Allocation'; }
else if (0 == surl.indexOf('/a3u'.toLowerCase())) { pagename = 'Services SKU'; }
else if (0 == surl.indexOf('/0J0'.toLowerCase())) { pagename = 'Setup Entity Access'; }
else if (0 == surl.indexOf('/0DM'.toLowerCase())) { pagename = 'Site'; }
else if (0 == surl.indexOf('/501'.toLowerCase())) { pagename = 'Solution'; }
else if (0 == surl.indexOf('/a4F'.toLowerCase())) { pagename = 'Solution Product'; }
else if (0 == surl.indexOf('/a46'.toLowerCase())) { pagename = 'Special Program'; }
else if (0 == surl.indexOf('/a1Z'.toLowerCase())) { pagename = 'State/Province Translation'; }
else if (0 == surl.indexOf('/a1W'.toLowerCase())) { pagename = 'State/Province'; }
else if (0 == surl.indexOf('/081'.toLowerCase())) { pagename = 'Static Resource'; }
else if (0 == surl.indexOf('/a0A'.toLowerCase())) { pagename = 'Steering Committe'; }
else if (0 == surl.indexOf('/a2I'.toLowerCase())) { pagename = 'Storybook'; }
else if (0 == surl.indexOf('/a4G'.toLowerCase())) { pagename = 'Strategic Plan Action'; }
else if (0 == surl.indexOf('/a4H'.toLowerCase())) { pagename = 'Strategic Plan Opp Prod Summary'; }
else if (0 == surl.indexOf('/a4I'.toLowerCase())) { pagename = 'Strategic Plan Review History'; }
else if (0 == surl.indexOf('/a4J'.toLowerCase())) { pagename = 'Strategic Plan Review'; }
else if (0 == surl.indexOf('/a4K'.toLowerCase())) { pagename = 'Strategic Plan Solution Opportunity'; }
else if (0 == surl.indexOf('/a4L'.toLowerCase())) { pagename = 'Strategic Plan Solution'; }
else if (0 == surl.indexOf('/a4M'.toLowerCase())) { pagename = 'Strategic Plan Strategy'; }
else if (0 == surl.indexOf('/a4N'.toLowerCase())) { pagename = 'Strategic Plan'; }
else if (0 == surl.indexOf('/a30'.toLowerCase())) { pagename = 'String Setting'; }
else if (0 == surl.indexOf('/a4f'.toLowerCase())) { pagename = 'SumTotal Catalog'; }
else if (0 == surl.indexOf('/a4g'.toLowerCase())) { pagename = 'SumTotal Request'; }
else if (0 == surl.indexOf('/a4h'.toLowerCase())) { pagename = 'SumTotal Setting'; }
else if (0 == surl.indexOf('/a4i'.toLowerCase())) { pagename = 'SumTotal Training'; }
else if (0 == surl.indexOf('/a0c'.toLowerCase())) { pagename = 'Super Industry'; }
else if (0 == surl.indexOf('/0t0'.toLowerCase())) { pagename = 'Tag Definition'; }
else if (0 == surl.indexOf('/00T'.toLowerCase())) { pagename = 'Task'; }
else if (0 == surl.indexOf('/a2Y'.toLowerCase())) { pagename = 'Teaming Agreement'; }
else if (0 == surl.indexOf('/a2s'.toLowerCase())) { pagename = 'Contributed Content'; }
else if (0 == surl.indexOf('/a3Q'.toLowerCase())) { pagename = 'Testing Ids'; }
else if (0 == surl.indexOf('/0TO'.toLowerCase())) { pagename = 'Topic'; }
else if (0 == surl.indexOf('/0FT'.toLowerCase())) { pagename = 'Entity'; }
else if (0 == surl.indexOf('/a31'.toLowerCase())) { pagename = 'Tracking Event Log'; }
else if (0 == surl.indexOf('/a32'.toLowerCase())) { pagename = 'Tracking Event Summary'; }
else if (0 == surl.indexOf('/a33'.toLowerCase())) { pagename = 'Tracking Event'; }
else if (0 == surl.indexOf('/a4O'.toLowerCase())) { pagename = 'Trend Data Settings'; }
else if (0 == surl.indexOf('/a4P'.toLowerCase())) { pagename = 'Trend Data'; }
else if (0 == surl.indexOf('/005'.toLowerCase())) { pagename = 'User'; }
else if (0 == surl.indexOf('/01D'.toLowerCase())) { pagename = 'User Account Team Member'; }
else if (0 == surl.indexOf('/100'.toLowerCase())) { pagename = 'User License'; }
else if (0 == surl.indexOf('/0Yw'.toLowerCase())) { pagename = 'User Login'; }
else if (0 == surl.indexOf('/03u'.toLowerCase())) { pagename = 'User Preference'; }
else if (0 == surl.indexOf('/00E'.toLowerCase())) { pagename = 'Role'; }
else if (0 == surl.indexOf('/0N2'.toLowerCase())) { pagename = 'User Share'; }
else if (0 == surl.indexOf('/00p'.toLowerCase())) { pagename = 'User Team Member'; }
else if (0 == surl.indexOf('/a1r'.toLowerCase())) { pagename = 'Util'; }
else if (0 == surl.indexOf('/a08'.toLowerCase())) { pagename = 'VendorCatalog'; }
else if (0 == surl.indexOf('/a1E'.toLowerCase())) { pagename = 'Verifiable Outcome'; }
else if (0 == surl.indexOf('/083'.toLowerCase())) { pagename = 'Vote'; }
else if (0 == surl.indexOf('/00b'.toLowerCase())) { pagename = 'Custom Button or Link'; }
else if (0 == surl.indexOf('/a27'.toLowerCase())) { pagename = 'dupcert'; }
else if (0 == surl.indexOf('/a3b'.toLowerCase())) { pagename = 'Field'; }
else if (0 == surl.indexOf('/a3c'.toLowerCase())) { pagename = 'Hoopla Entity'; }
else if (0 == surl.indexOf('/a3d'.toLowerCase())) { pagename = 'Hoopla Error Log'; }
else if (0 == surl.indexOf('/a3e'.toLowerCase())) { pagename = 'Hoopla Trigger Settings'; }
else if (0 == surl.indexOf('/a3f'.toLowerCase())) { pagename = 'Hoopla User'; }
else if (0 == surl.indexOf('/a3g'.toLowerCase())) { pagename = 'Notification Queue'; }
else if (0 == surl.indexOf('/a3h'.toLowerCase())) { pagename = 'Object'; }
else if (0 == surl.indexOf('/a3i'.toLowerCase())) { pagename = 'Player'; }
else if (0 == surl.indexOf('/a3j'.toLowerCase())) { pagename = 'Position Role'; }
else if (0 == surl.indexOf('/a3k'.toLowerCase())) { pagename = 'Position'; }
else if (0 == surl.indexOf('/a3l'.toLowerCase())) { pagename = 'Scoreboard Role'; }
else {  pagename = surl.substring(1,surl.length); }
