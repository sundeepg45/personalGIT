<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>EA_Invitation_contact_recipient</fullName>
        <description>Invitation contact recipient</description>
        <protected>false</protected>
        <recipients>
            <field>Contact__c</field>
            <type>contactLookup</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>POR_Email_Templates/Invitation_Email_Template</template>
    </alerts>
    <alerts>
        <fullName>EA_Invitation_user_recipient</fullName>
        <description>Invitation user recipient</description>
        <protected>false</protected>
        <recipients>
            <field>User__c</field>
            <type>userLookup</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>POR_Email_Templates/Invitation_Email_Template</template>
    </alerts>
    <rules>
        <fullName>WR _InvitationContactRecipient</fullName>
        <actions>
            <name>EA_Invitation_contact_recipient</name>
            <type>Alert</type>
        </actions>
        <active>true</active>
        <formula>NOT(ISNULL(Contact__c))</formula>
        <triggerType>onCreateOnly</triggerType>
    </rules>
    <rules>
        <fullName>WR _InvitationUserRecipient</fullName>
        <actions>
            <name>EA_Invitation_user_recipient</name>
            <type>Alert</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Invitee__c.User__c</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <triggerType>onCreateOnly</triggerType>
    </rules>
</Workflow>
