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
        <actions>
            <name>Joined_Reference_Program_Date</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <booleanFilter>1 AND (2 OR 3) AND 4</booleanFilter>
        <criteriaItems>
            <field>Reference_Basic_Information__c.Is_Referenceable__c</field>
            <operation>equals</operation>
            <value>True</value>
        </criteriaItems>
        <criteriaItems>
            <field>Reference_Basic_Information__c.Referenceability_Status__c</field>
            <operation>equals</operation>
            <value>Active</value>
        </criteriaItems>
        <criteriaItems>
            <field>Reference_Basic_Information__c.Referenceability_Status__c</field>
            <operation>equals</operation>
            <value>Caution</value>
        </criteriaItems>
        <criteriaItems>
            <field>Reference_Basic_Information__c.Joined_Reference_Program__c</field>
            <operation>equals</operation>
        </criteriaItems>
        <description>Depricated(Bound 8)</description>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
