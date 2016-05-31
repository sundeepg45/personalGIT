<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Update_Show_New_Link_to_False</fullName>
        <description>Updates the &quot;Show New&quot; link to false</description>
        <field>Show_New__c</field>
        <literalValue>0</literalValue>
        <name>Update &quot;Show New&quot; Link to False</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Set %22Show New%22 Link to False</fullName>
        <active>true</active>
        <criteriaItems>
            <field>Headline_Link__c.Show_New__c</field>
            <operation>equals</operation>
            <value>True</value>
        </criteriaItems>
        <criteriaItems>
            <field>Headline_Link__c.Publish__c</field>
            <operation>equals</operation>
            <value>1</value>
        </criteriaItems>
        <description>Set the &quot;Show New&quot; property to false after a determined period of time using a time based workflow field update</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
</Workflow>
