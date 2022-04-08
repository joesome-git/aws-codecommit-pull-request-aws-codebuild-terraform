import datetime
import boto3
import json
import os

sns_client = boto3.client('sns')
codebuild_client = boto3.client('codebuild')
codecommit_client = boto3.client('codecommit')

def action_codecommit(notification):

    print('[EVENT_CODECOMMIT] CodeCommit event handler...')

    if notification['detail']['event'] == 'pullRequestCreated':
        
        pullRequestId = notification['detail']['pullRequestId']
        repositoryName = notification['detail']['repositoryNames'][0]
        sourceCommit = notification['detail']['sourceCommit']
        destinationCommit = notification['detail']['destinationCommit']
        branch = notification['detail']['destinationReference'].split('/')[2]

        region = notification['region']
        sourceReference = notification['detail']['sourceReference']
        
        print('[EVENT_CODECOMMIT] CodeCommit triggering code build...')

        codebuild_client.start_build(
            projectName=os.getenv('CODEBUILD_PROJECT'),
            sourceVersion=sourceReference,
            sourceTypeOverride='CODECOMMIT',
            gitCloneDepthOverride=1,
            sourceLocationOverride='https://git-codecommit.{0}.amazonaws.com/v1/repos/{1}'.format(region, repositoryName),
            buildspecOverride=os.getenv('CODEBUILD_BUILDSPEC'),
            environmentVariablesOverride=[
                {
                    'name': 'pullRequestId',
                    'value': pullRequestId,
                    'type': 'PLAINTEXT'
                },
                {
                    'name': 'branch',
                    'value': branch,
                    'type': 'PLAINTEXT'
                },
                {
                    'name': 'repositoryName',
                    'value': repositoryName,
                    'type': 'PLAINTEXT'
                },
                {
                    'name': 'sourceCommit',
                    'value': sourceCommit,
                    'type': 'PLAINTEXT'
                },
                {
                    'name': 'destinationCommit',
                    'value': destinationCommit,
                    'type': 'PLAINTEXT'
                },
            ],
        )

    return {
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/json"
        },
        "body": json.dumps({
            "Message": "EVENT_CODECOMMIT"
        })
    }

def action_codebuild(notification):
    
    print('[EVENT_CODEBUILD] Codebuild event handler...')

    response = {
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/json"
        },
        "body": json.dumps({
            "Message": "EVENT_CODEBUILD"
        })
    }

    time = datetime.datetime.utcnow().time()

    for environmentVariable in notification['detail']['additional-information']['environment']['environment-variables']:
        if environmentVariable['name'] == 'pullRequestId':
            pullRequestId = environmentVariable['value']
        if environmentVariable['name'] == 'repositoryName':
            repositoryName = environmentVariable['value']
        if environmentVariable['name'] == 'sourceCommit':
            sourceCommit = environmentVariable['value']
        if environmentVariable['name'] == 'destinationCommit':
            destinationCommit = environmentVariable['value']
        if environmentVariable['name'] == 'branch':
            branch = environmentVariable['value']
    
    if branch in ['main', 'master']: branch = 'prod'
    
    pullRequestUrl = " https://{0}.console.aws.amazon.com/codesuite/codecommit/repositories/{1}/pull-requests/{2}/activity".format(os.getenv('ARN_REGION'), repositoryName, pullRequestId)
    
    sns_email = {
        "subject": 'New Pull Request [{}]'.format(repositoryName), 
        "message": 'Pull request for {0} branch on {1} service: \n\n- {2}'.format(branch, repositoryName, pullRequestUrl),
        "topicArn": 'arn:aws:sns:{0}:{1}:{2}-{3}'.format(os.getenv('ARN_REGION'), os.getenv('ARN_ACCOUNT_ID'), os.getenv('NOTIFICATION_PREFIX'), branch),
        "pullRequestUrl": pullRequestUrl,
    }

    if notification['detail']['build-status'] == 'IN_PROGRESS':
        content='![Unknown][Badge] \r\n\n**Build started at {0}**\r\n\n[Badge]: {1} "Unknown"'.format(time, os.getenv('BADGE_UNKNOWN'))
        event_sns(sns_email)

    elif notification['detail']['build-status'] == 'SUCCEEDED':
        content = '![Passing][Badge] \r\n\n **Build passed at {0}** [View Logs]({2})\r\n[Badge]: {1} "Passing"'.format(time, os.getenv('BADGE_PASSING'), notification['detail']['additional-information']['logs']['deep-link'])
        
    elif notification['detail']['build-status'] == 'FAILED':
        content = '![Failing][Badge] \r\n\n **Build failed at {0}** [View Logs]({2})\r\n[Badge]: {1} "Failing"'.format(time, os.getenv('BADGE_FAILING'), notification['detail']['additional-information']['logs']['deep-link'])
    
    codecommit_client.post_comment_for_pull_request(
        pullRequestId=pullRequestId,
        repositoryName=repositoryName,
        beforeCommitId=sourceCommit,
        afterCommitId=destinationCommit,
        content=content
    )

    print('[EVENT_CODEBUILD] Codebuild {}...'.format(notification['detail']['build-status']))

    return response

def event_sns(sns_email):
    
    print('[EVENT_SNS] SNS notification event handler...')
    
    print(sns_email)
    
    print('[EVENT_SNS] SNS TopicArn: ', sns_email['topicArn'])
    print('[EVENT_SNS] SNS PullRequestUrl: ', sns_email['pullRequestUrl'])

    return sns_client.publish(
        Subject=sns_email['subject'],
        Message=sns_email['message'],
        TopicArn=sns_email['topicArn'],
    )
