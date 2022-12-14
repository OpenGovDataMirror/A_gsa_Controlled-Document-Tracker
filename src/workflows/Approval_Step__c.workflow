<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
	<alerts>
        <fullName>Approval_Step_Due_Today</fullName>
        <description>Approval Step Due Today</description>
        <protected>false</protected>
        <recipients>
            <field>Assigned_Approver__c</field>
            <type>userLookup</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/Approval_Step_5_Day_Reminder</template>
    </alerts>
    <alerts>
        <fullName>Approval_Step_Overdue</fullName>
        <description>Approval Step Overdue</description>
        <protected>false</protected>
        <recipients>
            <field>Assigned_Approver__c</field>
            <type>userLookup</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/Approval_Step_Overdue_Reminder</template>
    </alerts>
    <alerts>
        <fullName>Notify_Controlled_Document_Owner_of_Approval_Step_Status</fullName>
        <description>Notify Controlled Document Owner of Approval Step Status</description>
        <protected>false</protected>
        <recipients>
            <type>owner</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/Approval_Step_Status_Update</template>
    </alerts>
    <fieldUpdates>
        <fullName>CDT_Set_Approval_Step_to_Approved</fullName>
        <description>This sets the Approval Step &quot;Approval Status&quot; to Approved.</description>
        <field>Approval_Status__c</field>
        <literalValue>Approved</literalValue>
        <name>CDT - Set Approval Step to Approved</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>CDT_Set_Approval_Step_to_Declined</fullName>
        <description>This sets the Approval Step &quot;Approval Status&quot; to Rejected.</description>
        <field>Approval_Status__c</field>
        <literalValue>Rejected</literalValue>
        <name>CDT - Set Approval Step to Declined</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>CDT_Set_Approval_Step_to_Initiated</fullName>
        <description>This sets the Approval Step &quot;Approval Status&quot; to Initiated.</description>
        <field>Approval_Status__c</field>
        <literalValue>Initiated</literalValue>
        <name>CDT - Set Approval Step to Initiated</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>CDT_Set_Approval_Step_to_Not_Initiated</fullName>
        <description>This sets the Approval Step &quot;Approval Status&quot; to &quot;Not Initiated&quot;.</description>
        <field>Approval_Status__c</field>
        <literalValue>Not Initiated</literalValue>
        <name>CDT - Set Approval Step to Not Initiated</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>CDT_clear_approval_step_start_date</fullName>
        <description>This clears the Approval Step &quot;Start Date&quot;.</description>
        <field>Start_Date__c</field>
        <name>CDT - clear approval step start date</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Null</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>CDT_set_approval_step_completed_date</fullName>
        <description>This sets the Approval Step completed date to today&apos;s date.</description>
        <field>Completed_Date__c</field>
        <formula>today()</formula>
        <name>CDT - set approval step completed date</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>CDT_set_approval_step_start_date</fullName>
        <description>This sets the Approval Step start date to today&apos;s date.</description>
        <field>Start_Date__c</field>
        <formula>today()</formula>
        <name>CDT - set approval step start date</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Clear_Days_Open</fullName>
        <description>When an approval step is recalled, the value of the Days Open field should be cleared.</description>
        <field>Days_Open__c</field>
        <name>Clear Days Open</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Null</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Notification_Hist_Trigger_Approval_Step</fullName>
        <field>Notification_History_Trigger__c</field>
        <literalValue>Approval Request</literalValue>
        <name>Notification Hist Trigger: Approval Step</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
	<fieldUpdates>
        <fullName>Notification_Hist_Trigger_Due_Today</fullName>
        <description>Field Update to provide to trigger the creation of a corresponding notification history record in the Controlled Documents activity history</description>
        <field>Notification_History_Trigger__c</field>
        <literalValue>Step Reminder Notification</literalValue>
        <name>Notification Hist Trigger: Due Today</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Notification_Hist_Trigger_Over_Due</fullName>
        <description>Field Update to provide to trigger the creation of a corresponding notification history record in the Controlled Documents activity history</description>
        <field>Notification_History_Trigger__c</field>
        <literalValue>Step Overdue Notifications</literalValue>
        <name>Notification Hist Trigger: Over Due</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Notification_Hist_Trigger_Status_Change</fullName>
        <description>Field Update to provide to trigger the creation of a corresponding notification history record in the Controlled Documents activity history</description>
        <field>Notification_History_Trigger__c</field>
        <literalValue>Status Change Notification</literalValue>
        <name>Notification Hist Trigger: Status Change</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
    <rules>
        <fullName>Approval Step Due Today v2</fullName>
        <active>true</active>
        <criteriaItems>
            <field>Approval_Step__c.Approval_Status__c</field>
            <operation>equals</operation>
            <value>Initiated</value>
        </criteriaItems>
        <criteriaItems>
            <field>Approval_Step__c.Due_Date__c</field>
            <operation>notEqual</operation>
            <value>TODAY</value>
        </criteriaItems>
        <criteriaItems>
            <field>Approval_Step__c.Due_Date__c</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <description>Email notification for approval step due today, but not if the initial approval step notification date is the same day as the due date, otherwise there would be redundant notifications.</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
        <workflowTimeTriggers>
            <actions>
                <name>Approval_Step_Due_Today</name>
                <type>Alert</type>
            </actions>
            <actions>
                <name>Notification_Hist_Trigger_Due_Today</name>
                <type>FieldUpdate</type>
            </actions>
            <offsetFromField>Approval_Step__c.Due_Date__c</offsetFromField>
            <timeLength>7</timeLength>
            <workflowTimeTriggerUnit>Hours</workflowTimeTriggerUnit>
        </workflowTimeTriggers>
    </rules>
    <rules>
        <fullName>Approval Step Overdue v2</fullName>
        <active>true</active>
        <criteriaItems>
            <field>Approval_Step__c.Approval_Status__c</field>
            <operation>equals</operation>
            <value>Initiated</value>
        </criteriaItems>
        <criteriaItems>
            <field>Approval_Step__c.Due_Date__c</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <description>Email notification for overdue approval step.</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
        <workflowTimeTriggers>
            <actions>
                <name>Approval_Step_Overdue</name>
                <type>Alert</type>
            </actions>
            <actions>
                <name>Notification_Hist_Trigger_Over_Due</name>
                <type>FieldUpdate</type>
            </actions>
            <offsetFromField>Approval_Step__c.Due_Date__c</offsetFromField>
            <timeLength>31</timeLength>
            <workflowTimeTriggerUnit>Hours</workflowTimeTriggerUnit>
        </workflowTimeTriggers>
    </rules>
</Workflow>
