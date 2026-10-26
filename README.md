# Security Detection and Response on AWS
Containerized WordPress on AWS Fargate with automated threat detection and response (GuardDuty, EventBridge, Lambda).

## Before the Project
Practiced with Docker, created Docker Compose file for the Wordpress image and MYSQL database image to be hosted onto a container (will change to RDS later). Ran test opening http://localhost:8080 and confirmed container website accessbility. Used various docker commands in Powershell to assist the process. THIS PROCESS IS TO FAMILIARIZE MYSELF MORE WITH CONTAINERIZATION AND TO FIRST RUN THE CONTAINERS LOCALLY BEFORE SHIFTING TO BUILDING IN A PRODUCTION ENVIRONMENT.

## Overview
This project is built of a modified version of my HA scalable project, from a EC2-based WordPress setup to a immutable, scanned container image running on ECS Fargate in a private network. The point is not WordPress itself. WordPress is the workload being defended, and the focus is what happens around it: scanning the image before it runs, limiting what the task can reach, detecting suspicious activity, and responding automatically. Using the knowledge I learned learning Python and Docker to understand automated and containerized environments. 

## Architecture



# STILL WORKING ON IT

 


