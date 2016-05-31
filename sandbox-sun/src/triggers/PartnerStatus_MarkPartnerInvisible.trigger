trigger PartnerStatus_MarkPartnerInvisible on PartnerStatus__c (before insert, before update) {
    for (PartnerStatus__c ps : Trigger.new) {
        if (!(
                ((RedHatObjectReferences__c.getInstance('PARTNER_TYPE.ISV') != null && ps.PartnerType__c == RedHatObjectReferences__c.getInstance('PARTNER_TYPE.ISV').ObjectId__c)
              || (RedHatObjectReferences__c.getInstance('PARTNER_TYPE.RESELLER') != null && ps.PartnerType__c == RedHatObjectReferences__c.getInstance('PARTNER_TYPE.RESELLER').ObjectId__c)
              || (RedHatObjectReferences__c.getInstance('PARTNER_TYPE.CORPORATE_RESELLER') != null && ps.PartnerType__c == RedHatObjectReferences__c.getInstance('PARTNER_TYPE.CORPORATE_RESELLER').ObjectId__c)
              || (RedHatObjectReferences__c.getInstance('PARTNER_TYPE.OEM') != null && ps.PartnerType__c == RedHatObjectReferences__c.getInstance('PARTNER_TYPE.OEM').ObjectId__c)
              || (RedHatObjectReferences__c.getInstance('PARTNER_TYPE.DISTRIBUTOR') != null && ps.PartnerType__c == RedHatObjectReferences__c.getInstance('PARTNER_TYPE.DISTRIBUTOR').ObjectId__c)
              || (RedHatObjectReferences__c.getInstance('PARTNER_TYPE.SI') != null && ps.PartnerType__c == RedHatObjectReferences__c.getInstance('PARTNER_TYPE.SI').ObjectId__c)
              || (RedHatObjectReferences__c.getInstance('PARTNER_TYPE.SERVICECLOUD_PROVIDER') != null && ps.PartnerType__c == RedHatObjectReferences__c.getInstance('PARTNER_TYPE.SERVICECLOUD_PROVIDER').ObjectId__c)
              || (RedHatObjectReferences__c.getInstance('PARTNER_TYPE.HOSTING') != null && ps.PartnerType__c == RedHatObjectReferences__c.getInstance('PARTNER_TYPE.HOSTING').ObjectId__c)
              || (RedHatObjectReferences__c.getInstance('PARTNER_TYPE.CLOUD_VIRTUALIZATION') != null && ps.PartnerType__c == RedHatObjectReferences__c.getInstance('PARTNER_TYPE.CLOUD_VIRTUALIZATION').ObjectId__c)
              || (RedHatObjectReferences__c.getInstance('PARTNER_TYPE.TRAINING') != null && ps.PartnerType__c == RedHatObjectReferences__c.getInstance('PARTNER_TYPE.TRAINING').ObjectId__c))
                && ( (RedHatObjectReferences__c.getInstance('PARTNER_TIER.ADVANCED') != null && ps.PartnerTier__c == RedHatObjectReferences__c.getInstance('PARTNER_TIER.ADVANCED').ObjectId__c)
                  || (RedHatObjectReferences__c.getInstance('PARTNER_TIER.PREMIER') != null && ps.PartnerTier__c == RedHatObjectReferences__c.getInstance('PARTNER_TIER.PREMIER').ObjectId__c)
                  || (RedHatObjectReferences__c.getInstance('PARTNER_TIER.AFFILIATED') != null && ps.PartnerTier__c == RedHatObjectReferences__c.getInstance('PARTNER_TIER.AFFILIATED').ObjectId__c)
                  || (RedHatObjectReferences__c.getInstance('PARTNER_TIER.READY') != null && ps.PartnerTier__c == RedHatObjectReferences__c.getInstance('PARTNER_TIER.READY').ObjectId__c))
              )
        ) {
            ps.IsVisible__c = false;
        }
    }
}