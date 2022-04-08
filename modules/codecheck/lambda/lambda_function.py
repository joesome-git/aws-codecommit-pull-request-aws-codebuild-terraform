import json

from actions import action_codecommit, action_codebuild

def lambda_handler(event, context):
    print('[EVENT_LAMBDA] Lambda trigger event handler...')
    
    print(event)

    if(event['detail-type'] == 'CodeCommit Pull Request State Change'):
        return action_codecommit(event)

    if(event['detail-type'] == 'CodeBuild Build State Change'):
        return action_codebuild(event)
