import boto3
import json
import logging

ecs_client = boto3.client("ecs") 
logger = logging.getLogger()
logger.setLevel(logging.INFO)


# allows lambda to communicate and access ecs
# NEED TO OPEN AND PULL THE EVENT
def lambda_handler(event, context):
    detail = event.get("detail", {})
    ecs_details = detail.get("resource", {}).get("ecsClusterDetails", {})
    
    logger.info("Received EventBridge event:")
    logger.info(json.dumps(event, default=str))

    severity = detail.get("severity", 0.0)
    cluster_name = ecs_details.get("name")
    cluster_arn = ecs_details.get("arn")
    task_arn = ecs_details.get("taskDetails", {}).get("arn")
    threat_type = detail.get("type", "Unknown Threat")

    try:
        if not cluster_name or not task_arn or not cluster_arn:
            logger.error("Missing ECS details in the event.")
            return {
                "status": "Error",
                "message": "Missing ECS details in the event."
            }
        elif severity >= 5.0:
            response = ecs_client.stop_task(
                task=task_arn,
                cluster=cluster_arn,
                reason=(f"Automated remediation: {threat_type} detected.")
            )
            logger.info(f"Stopped ECS task {task_arn} in cluster {cluster_name} due to threat: {threat_type}.")
            return {
                "status": "Remediation triggered",
                "message": (f"Stopped ECS task {task_arn} in cluster {cluster_name} due to threat: {threat_type}."),
                }
        
        else: 
            logger.info(f"Severity {severity} is below threshold. No action taken for ECS task {task_arn} in cluster {cluster_name}.")
            return {
            "status": "No action taken",
            "message": (f"Severity {severity} is below threshold.")
            }
    except Exception as error:
        logger.error(f"Failed to stop ECS task {task_arn} in cluster {cluster_name}: {error}")
        return {
            "status": "Error",
            "message": "An unexpected error occurred during remediation."
        }
    
