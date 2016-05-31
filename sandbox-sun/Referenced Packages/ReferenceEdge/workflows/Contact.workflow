<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Joined_Reference_Program_Date</fullName>
        <description>Update date is written here when &apos;reference program member&apos; flag is first set to checked</description>
        <field>Joined_Reference_Program__c</field>
        <formula>Today()</formula>
        <name>Joined Reference Program Date</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>WR_InsertJoinedReferenceProgramDate</fullName>
        <active>false</active>
        <criteriaItems>
            <field>Contact.AccountName</field>
            <operation>equals</operation>
        </criteriaItems>
        <description>Depricated(Bound 8)</description>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
