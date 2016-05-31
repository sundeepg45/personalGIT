<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>Community_Invitation_Accepted_Mail</fullName>
        <description>Community Invitation Accepted Mail</description>
        <protected>false</protected>
        <recipients>
            <type>creator</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>POR_Email_Templates/Community_Invitation_Accepted</template>
    </alerts>
    <rules>
        <fullName>Community Invitation Accepted</fullName>
        <actions>
            <name>Community_Invitation_Accepted_Mail</name>
            <type>Alert</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Community_Invite_Contact__c.Response__c</field>
            <operation>equals</operation>
            <value>Yes</value>
        </criteriaItems>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
