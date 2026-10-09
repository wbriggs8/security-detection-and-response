# security-detection-and-response
'''
Containerized WordPress on AWS with automated threat detection and response (GuardDuty, EventBridge, Lambda). (FINAL IDEA)
'''

'''
Created Docker Compose file for the Wordpress image and MYSQL database image to be hosted onto a container (will change to RDS later). Ran test openeing http://localhost:8080 and confirmed container website accessbility. Used various docker commands in Powershell to assist the process. 

Next up: Build out the base infrastructure needed for the project to work (RDS, Security Groups, VPC, Route Tables etc.) OR Move container to ECR.

Future: EventBridge, Lambda, Guardduty and possibly Inspector. Need to establish rules for Eventbridge to trigger on (malicious activities)
