# prefix Inc.
# DevOps Team Lead / Martin Jakobsson Team Senior/ Pushpa Nyaupane
# Design by / Abdallah kenawy
###################################################################
# AWS Inspector Remediation Lambda function
###################################################################

# python Modules ##
import boto3
import time
import os
import json

############################################ Lambda Env ##
account_id = os.environ['ACCOUNT_ID']
env = os.environ['ENV']
rpt = os.environ['RPT']
rpt_control = os.environ['RPT_CONTROL']
sns_topic = os.environ['SNS_TOPIC']
cve_days_age = os.environ['CVE_DAYS_AGE']
title = os.environ['TITLE_START_WITH']
remediation_assumerole = os.environ['REMEDIATION_ASSUMEROLE']
remediation_bucket = os.environ['REMEDIATION_BUCKET']
remediation_runbook = os.environ['REMEDIATION_RUNBOOK']
remediation_slack_info = os.environ['REMEDIATION_SLACK_INFO']
remediation_slack_alarm = os.environ['REMEDIATION_SLACK_ALARM']
remediation_reboot_tag_key = os.environ['REMEDIATION_REBOOT_TAG_KEY']
remediation_reboot_tag_value = os.environ['REMEDIATION_REBOOT_TAG_VALUE']
remediation_scan_tag_key = os.environ['REMEDIATION_SCAN_TAG_KEY']
remediation_scan_tag_value = os.environ['REMEDIATION_SCAN_TAG_VALUE']
next_token = ""
next_token_execution_id = ""
#########################################################################################
# get Security HUB finding with filter
def get_findings():
    client = boto3.client('securityhub')
    response = client.get_findings(
        Filters={
            'AwsAccountId': [
                {
                    'Value': account_id,
                    'Comparison': 'EQUALS'
                },
            ],
            'CreatedAt': [
                {
                    'DateRange': {
                        'Value': int(cve_days_age),
                        'Unit': 'DAYS'
                    }
                },
            ],
            'Title': [
                {
                    'Value': title,
                    'Comparison': 'PREFIX'
                },
            ],
            'ProductName': [
                {
                    'Value': 'Inspector',
                    'Comparison': 'EQUALS'
                },
            ],
            'ResourceType': [
                {
                    'Value': 'AwsEc2Instance',
                    'Comparison': 'EQUALS'
                },
            ],
            'ResourceTags': [
                {
                    'Key': remediation_scan_tag_key,
                    'Value': remediation_scan_tag_value,
                    'Comparison': 'EQUALS'
                },
            ],
            'WorkflowStatus': [
                {
                    'Value': 'NEW',
                    'Comparison': 'EQUALS'
                },
                {
                    'Value': 'NOTIFIED',
                    'Comparison': 'EQUALS'
                },
            ],
            'RecordState': [
                {
                    'Value': 'ACTIVE',
                    'Comparison': 'EQUALS'
                },
            ],
        },
        SortCriteria=[
            {
                'Field': 'CreatedAt',
                'SortOrder': 'desc'
            },
        ],
        NextToken=next_token,
        MaxResults=2
    )
    return response
findings = get_findings()

# reboot_option = 'NoReboot | RebootIfNeeded'
def start_automation_execution(remediation_runbook, remediation_assumerole, finding_id, reboot_option, finding_product_instance_id, finding_resource_region):
    client = boto3.client('ssm')
    response = client.start_automation_execution(
        DocumentName=remediation_runbook,
        DocumentVersion='1',
        Parameters={
            'AutomationAssumeRole': [
                remediation_assumerole
            ],
            'InspectorFindingArn': [
                finding_id
            ],
            'RebootOption': [
                reboot_option
            ],
            'InstanceIds': [
                finding_product_instance_id
            ],
            'Source': [
                'aws.ssm.automation'
            ],
            'SeverityFilter': [
                'NONE'
            ],
            'Operation': [
                'Install'
            ],
            'IncludeKernelUpdates': [
                'true'
            ],
            'S3BucketName': [
                remediation_bucket
            ],
            'S3BucketKey': [
                'inspector/installOverrideList/'
            ]
        },
        # ClientToken= client_token,
        # Mode='Auto',
        TargetParameterName='InstanceIds',
        Targets=[
            {
                'Key': 'ParameterValues',
                'Values': [
                    finding_product_instance_id,
                ]
            },
        ],
        # TargetMaps=[
        #     {
        #         'string': [
        #             'string',
        #         ]
        #     },
        # ],
        MaxConcurrency='20',
        MaxErrors='10',
        TargetLocations=[
            {
                'Accounts': [
                    account_id,
                ],
                'Regions': [
                    finding_resource_region
                ],
                'TargetLocationMaxConcurrency': '20',
                'TargetLocationMaxErrors': '10',
                'ExecutionRoleName': 'resolveInspectorExecutionRole'
            },
        ],
        # Tags=[
        #     {
        #         'Key': 'string',
        #         'Value': 'string'
        #     },
        # ],
        # AlarmConfiguration={
        #     'IgnorePollAlarmFailure': True | False,
        #     'Alarms': [
        #         {
        #             'Name': 'string'
        #         },
        #     ]
        # }
    )
    return response
    # return response['AutomationExecutionId']



def describe_automation_executions(execution_id):
    client = boto3.client('ssm')
    response = client.describe_automation_executions(
        Filters=[
            {
                'Key': 'ExecutionId',
                'Values': [
                    execution_id,
                ]
            },
        ],
        MaxResults=50
        # NextToken=next_token
    )
    return response['AutomationExecutionMetadataList'][0]['AutomationExecutionStatus']

def get_automation_execution(execution_id):
    client = boto3.client('ssm')
    response = client.get_automation_execution(
        AutomationExecutionId=execution_id
    )
    return response['AutomationExecution']['StepExecutions'][0]['StepStatus']

def publish(message_sns, subject_sns):
    client = boto3.client('sns')
    response = client.publish(
        TopicArn=sns_topic,
        Message=message_sns,
        Subject=subject_sns
    )

def remediation_execution_status(execution_id):
    global execution_status
    overall_status = describe_automation_executions(execution_id)
    step_status = get_automation_execution(execution_id)
    # print(f' Overall_status for execution ID {execution_id} is {overall_status}')
    # print(f' Step_status for execution ID {execution_id} is {step_status}')
    if overall_status and step_status == 'Success':
        execution_status = 'Success'
    elif overall_status == 'Success' and step_status == 'Failed':
        execution_status = 'Failed'
    elif overall_status and step_status == 'Failed':
        execution_status = 'Failed'
    else:
        execution_status = 'Failed'
    return execution_status


def reboot_instances(instance_id):
    client = boto3.client('ec2')
    response = client.reboot_instances(
        InstanceIds=[
            instance_id,
        ]
    )

def check_execution_status(execution_id):
    count_down = 0
    fresh_execution_status = describe_automation_executions(execution_id)
    while fresh_execution_status == "InProgress":
        fresh_execution_status = describe_automation_executions(execution_id)
        if count_down < 20:
            count_down += 1
            print(f'execution_status still InProgress for execution Id {execution_id} count check is {count_down}')
            time.sleep(20)
            continue
    else:
        if remediation_execution_status(execution_id) == "Success":
            print(f'execution_status has successfully completed for execution Id {execution_id} count check is {count_down}')
            subject_sns = "AWS Inspector Remediation Info"
            message_sns = (f'execution_status has successfully completed for execution Id {execution_id}, count check is {count_down}, resource Id is {finding_resources_id}, resource Region is {finding_resource_region}, Inspector Finding Id is {finding_id}, Inspector description Id is {finding_description}')
            if remediation_slack_info == "yes":
                publish(message_sns, subject_sns)
            else:
                pass
        else:
            print(f'execution_status is >>>> ', remediation_execution_status(execution_id))
            print(f'execution_status has unknown value for execution Id {execution_id}  count check is {count_down}')
            subject_sns = "AWS Inspector Remediation Alarm"
            message_sns = (f'execution_status has unknown value for execution Id {execution_id}, count check is {count_down}, resource Id is {finding_resources_id}, resource Region is {finding_resource_region}, Inspector Finding Id is {finding_id}, Inspector description Id is {finding_description}')
            if remediation_slack_alarm == "yes":
                publish(message_sns, subject_sns)
            else:
                pass


def actions_on_failure(failure_execution_status, failure_execution_id):
    if failure_execution_status != "Success":
        print(f' check if RPT remediation is allowed Or Not, current failure execution Id {failure_execution_id } is {failure_execution_status}')
        if rpt == "yes":
            if rpt_control == "yes":
                # if finding_resource_tags.get(remediation_reboot_tag_key) is not None:
                if (remediation_reboot_tag_key, remediation_reboot_tag_value) in finding_resource_tags.items():
                    reboot_option = 'RebootIfNeeded'
                    retrying_execution_id = start_automation_execution(remediation_runbook, remediation_assumerole, finding_id, reboot_option, finding_product_instance_id, finding_resource_region)['AutomationExecutionId']
                    print(f'New Execution Id on trying ')
                    check_execution_status(retrying_execution_id)
                    if remediation_execution_status(retrying_execution_id) != "Success":
                        print(f'reboot instance will be initiate', finding_resources_id)
                        reboot_instances(finding_product_instance_id)
                        subject_sns = "AWS Inspector Remediation Alarm - Reboot instance Alarm"
                        message_sns = (f'reboot instance will be initiate on instance Id {finding_product_instance_id}')
                        publish(message_sns, subject_sns)
                        print(f'please HOLD until reboot instance', finding_resources_id)
                        time.sleep(300)
                    else:
                        pass
                else:
                    subject_sns = "AWS Inspector Remediation Alarm - RPT Remediation on Resource Tags is NOT ALLOWED"
                    print(f'execution status for current failure execution Id {failure_execution_id} is {failure_execution_status}')
                    message_sns = (f'RPT Tags on Resource is NOT ALLOWED for Remediation with reboot action , execution status for current failure execution Id {failure_execution_id} is {failure_execution_status} , CVE Title is {finding_title} , Resource Id is {finding_resources_id} , finding description >>{finding_description}' )
                    print(message_sns)
                    publish(message_sns, subject_sns)
                    pass
            else:
                reboot_option = 'RebootIfNeeded'
                retrying_execution_id = start_automation_execution(remediation_runbook, remediation_assumerole, finding_id, reboot_option, finding_product_instance_id, finding_resource_region)['AutomationExecutionId']
                print(f'New Execution Id on trying ')
                check_execution_status(retrying_execution_id)
                if remediation_execution_status(retrying_execution_id) != "Success":
                    print(f'reboot instance will be initiate', finding_resources_id)
                    reboot_instances(finding_product_instance_id)
                    subject_sns = "AWS Inspector Remediation Alarm - Reboot instance Alarm"
                    message_sns = (f'reboot instance will be initiate on instance Id {finding_product_instance_id}')
                    publish(message_sns, subject_sns)
                    print(f'please HOLD until reboot instance', finding_resources_id)
                    time.sleep(300)
                else:
                    pass
        else:
            subject_sns = "AWS Inspector Remediation Alarm - RPT remediation is NOT ALLOWED"
            print(f'execution status for current failure execution Id {failure_execution_id} is {failure_execution_status}')
            message_sns = (f'RPT remediation is NOT ALLOWED , execution status for current failure execution Id {failure_execution_id} is {failure_execution_status} , CVE Title is {finding_title} , Resource Id is {finding_resources_id} , finding description >>{finding_description}' )
            print(message_sns)
            publish(message_sns, subject_sns)
            pass
    else:
        pass

def findings_operation_info():
    global finding_title, finding_id, finding_resources_id, finding_resource_region, finding_schema_version, finding_product_arn
    global finding_generator_id, finding_created_at, finding_updated_at, finding_description, finding_product_fields
    global finding_resources, finding_vulnerabilities, finding_resource_tags, finding_resources_type, finding_severity
    global finding_provider, finding_product_id, finding_json, finding_product_instance_id
    for i in findings['Findings']:
        finding_json = i
        finding_title = (i['Title'])
        print(f'finding_title is >>>> ', finding_title)
        finding_id = (i['Id'])
        print(f'finding_id is >>>> ', finding_id)
        finding_resources_id = (i['Resources'][0]['Id'])
        print(f'finding_resources_id is >>>> ', finding_resources_id)
        finding_resource_region = (i['Resources'][0]['Region'])
        print(f'finding_resource_region is >>>> ', finding_resource_region)
        finding_resource_tags = (i['Resources'][0]['Tags'])
        print(f'finding_resource_tags is >>>> ', finding_resource_tags)
        finding_schema_version = (i['SchemaVersion'])
        print(f'finding_schema_version is >>>> ', finding_schema_version)
        finding_product_arn = 'arn:aws:securityhub:' + 'us-east-1' + ':' + account_id + ':product/' + account_id + '/default'
        print(f'finding_product_arn is >>>> ', finding_product_arn)
        finding_generator_id = (i['GeneratorId'])
        print(f'finding_generator_id is >>>> ', finding_generator_id)
        finding_created_at = (i['CreatedAt'])
        print(f'finding_created_at is >>>> ', finding_created_at)
        finding_updated_at = (i['UpdatedAt'])
        print(f'finding_updated_at is >>>> ', finding_updated_at)
        finding_description = (i['Description'])
        print(f'finding_description is >>>> ', finding_description)
        finding_product_fields = (i['ProductFields'])
        print(f'finding_product_fields is >>>> ', finding_product_fields)
        finding_resources = (i['Resources'][0])
        # print(f'finding_resources is >>>> ', finding_resources)
        finding_vulnerabilities = (i['Vulnerabilities'][0])
        print(f'finding_vulnerabilities is >>>> ', finding_vulnerabilities)
        finding_resources_type = (i['Resources'][0]['Type'])
        print(f'finding_resources_type is >>>> ', finding_resources_type)
        finding_severity = (i['Severity'])
        print(f'finding_severity is >>>> ', finding_severity)
        finding_provider = (i['FindingProviderFields'])
        print(f'finding_provider is >>>> ', finding_provider)
        finding_product_id = (i['ProductFields']['aws/securityhub/FindingId'])
        print(f'finding_product_id is >>>> ', finding_product_id)
        finding_product_instance_id = (i['ProductFields']['aws/inspector/instanceId'])
        print(f'finding_product_instance_id is >>>> ', finding_product_instance_id)
        reboot_option = 'NoReboot'
        execution_id = start_automation_execution(remediation_runbook, remediation_assumerole, finding_id, reboot_option, finding_product_instance_id, finding_resource_region)['AutomationExecutionId']
        time.sleep(10)
        print(f'execution_id is >>>> ', execution_id)
        check_execution_status(execution_id)
        remediation_execution_status(execution_id)
        if execution_status != "Success":
            failure_execution_id = execution_id
            failure_execution_status = remediation_execution_status(execution_id)
            actions_on_failure(failure_execution_status, failure_execution_id)
        else:
            pass
        print("Remediation Operation has been finished, Next Security HUB Finding >>> ...")
        time.sleep(30)
        
    
def main(event=None, context=None):
    print("start AWS Inspector Remediation")
    print(f'Scan findings list >>> ', get_findings())
    print(findings_operation_info())

main()


