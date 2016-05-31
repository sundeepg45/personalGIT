<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>POR_Nomination_Accepted_for_Account</fullName>
        <description>POR Nomination Accepted for Account</description>
        <protected>false</protected>
        <recipients>
            <type>creator</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>POR_Email_Templates/POR_Nomination_Accepted_for_Account</template>
    </alerts>
    <alerts>
        <fullName>POR_Nomination_Accepted_for_Contact</fullName>
        <description>POR Nomination Accepted for Contact</description>
        <protected>false</protected>
        <recipients>
            <type>creator</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>POR_Email_Templates/POR_Nomination_Accepted_for_Contact</template>
    </alerts>
    <alerts>
        <fullName>POR_Nomination_Rejected_for_Account</fullName>
        <description>POR Nomination Rejected for Account</description>
        <protected>false</protected>
        <recipients>
            <type>creator</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>POR_Email_Templates/POR_Nomination_Rejected_for_Account</template>
    </alerts>
    <alerts>
        <fullName>POR_Nomination_Rejected_for_Contact</fullName>
        <description>POR Nomination Rejected for Contact</description>
        <protected>false</protected>
        <recipients>
            <type>creator</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>POR_Email_Templates/POR_Nomination_Rejected_for_Contact</template>
    </alerts>
    <alerts>
        <fullName>POR_Nomination_for_Account</fullName>
        <description>POR Nomination for Account</description>
        <protected>false</protected>
        <recipients>
            <recipient>Customer_Reference_Team</recipient>
            <type>group</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>POR_Email_Templates/POR_Nomination_for_Account</template>
    </alerts>
    <alerts>
        <fullName>POR_Nomination_for_Contact</fullName>
        <description>POR Nomination for Contact</description>
        <protected>false</protected>
        <recipients>
            <recipient>Customer_Reference_Team</recipient>
            <type>group</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>POR_Email_Templates/POR_Nomination_for_Contact</template>
    </alerts>
    <rules>
        <fullName>Nominate Account</fullName>
        <actions>
            <name>POR_Nomination_for_Account</name>
            <type>Alert</type>
        </actions>
        <active>true</active>
        <formula>Email_Enabled__c = true &amp;&amp; Account__c &lt;&gt; null &amp;&amp; Contact__c = null &amp;&amp;  ISPICKVAL( Status__c , &apos;Not Started&apos;)</formula>
        <triggerType>onCreateOnly</triggerType>
    </rules>
    <rules>
        <fullName>Nominate Contact</fullName>
        <actions>
            <name>POR_Nomination_for_Contact</name>
            <type>Alert</type>
        </actions>
        <active>true</active>
        <formula>Email_Enabled__c = true &amp;&amp; Account__c &lt;&gt; null &amp;&amp; Contact__c &lt;&gt; null &amp;&amp; ISPICKVAL( Status__c , &apos;Not Started&apos;)</formula>
        <triggerType>onCreateOnly</triggerType>
    </rules>
    <rules>
        <fullName>POR Nomination Accepted for Account</fullName>
        <actions>
            <name>POR_Nomination_Accepted_for_Account</name>
            <type>Alert</type>
        </actions>
        <active>true</active>
        <formula>Email_Enabled__c = true &amp;&amp; Account__c &lt;&gt; null &amp;&amp; Contact__c = null &amp;&amp; ISPICKVAL( Status__c , &apos;Completed&apos;) &amp;&amp; ISPICKVAL(  Disposition__c , &apos;Approved&apos;)</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>POR Nomination Accepted for Contact</fullName>
        <actions>
            <name>POR_Nomination_Accepted_for_Contact</name>
            <type>Alert</type>
        </actions>
        <active>true</active>
        <formula>Email_Enabled__c = true &amp;&amp; Account__c &lt;&gt; null &amp;&amp; Contact__c &lt;&gt; null &amp;&amp; ISPICKVAL( Status__c , &apos;Completed&apos;) &amp;&amp; ISPICKVAL( Disposition__c , &apos;Approved&apos;)</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>POR Nomination Rejected for Account</fullName>
        <actions>
            <name>POR_Nomination_Rejected_for_Account</name>
            <type>Alert</type>
        </actions>
        <active>true</active>
        <formula>Email_Enabled__c = true &amp;&amp; Account__c &lt;&gt; null &amp;&amp; Contact__c = null &amp;&amp; ISPICKVAL( Status__c , &apos;Completed&apos;) &amp;&amp; ISPICKVAL( Disposition__c , &apos;Declined&apos;)</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>POR Nomination Rejected for Contact</fullName>
        <actions>
            <name>POR_Nomination_Rejected_for_Contact</name>
            <type>Alert</type>
        </actions>
        <active>true</active>
        <formula>Email_Enabled__c = true &amp;&amp; Account__c &lt;&gt; null &amp;&amp; Contact__c &lt;&gt; null &amp;&amp; ISPICKVAL( Status__c , &apos;Completed&apos;) &amp;&amp; ISPICKVAL( Disposition__c , &apos;Declined&apos;)</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
