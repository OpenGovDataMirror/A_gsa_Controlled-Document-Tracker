<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>CDT_Update_ExecSec_End_Date</fullName>
        <description>Updating the ExecSec End Date while the user has Awaiting Signature selected on the Controlled Document record.</description>
        <field>ExecSec_End_Date__c</field>
        <formula>IF (  AND(
  NOT(ISPICKVAL(PRIORVALUE(Stage__c), &quot;Awaiting Signature&quot;)), 
  ISPICKVAL(Stage__c, &quot;Awaiting Signature&quot;)),
TODAY(),
IF( 
  AND(
    ISPICKVAL(PRIORVALUE(Stage__c), &quot;Awaiting Signature&quot;),
    NOT(
    OR(
    (ISPICKVAL(Stage__c, &quot;Awaiting Signature&quot;)),
    (ISPICKVAL(Stage__c, &quot;Awaiting Closure&quot;)),
    (ISPICKVAL(Stage__c, &quot;Closed&quot;)),
    (ISPICKVAL(Stage__c, &quot;External Review&quot;))
    )
    )
    ),
null,  ExecSec_End_Date__c ))</formula>
        <name>CDT - Update ExecSec End Date</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>CDT_set_Controlled_Document_Date_Close</fullName>
        <description>This sets the Date Closed to today&apos;s date.</description>
        <field>Date_Closed__c</field>
        <formula>today()</formula>
        <name>CDT - set Controlled Document Date Close</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>CDT - Update ExecSec End Date</fullName>
        <actions>
            <name>CDT_Update_ExecSec_End_Date</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>Updates the ExecSec End Date if the ExecSec Start Date is not blank, and the Stage is set to Awaiting Signature. The End Date will be wiped if the Stage is changed from Awaiting Signature to any value besides Awaiting Closure, Closed or External Review.</description>
        <formula>AND( NOT( ISBLANK( ExecSec_Start_Date__c ) ) , NOT( ISBLANK (  Assignee__c ) ) )</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>CDT - set Controlled Document Date Closed</fullName>
        <actions>
            <name>CDT_set_Controlled_Document_Date_Close</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Controlled_Document__c.Stage__c</field>
            <operation>equals</operation>
            <value>Closed</value>
        </criteriaItems>
        <description>This workflow sets the Date Closed to today when Controlled Document stage = closed.</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
</Workflow>
