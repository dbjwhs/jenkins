#!/bin/bash
docker cp jenkins.yaml jenkins:/var/jenkins_home/
docker cp jobs.groovy jenkins:/var/jenkins_home/
docker exec jenkins jenkins-plugin-cli --plugins configuration-as-code job-dsl workflow-aggregator docker-workflow git
docker restart jenkins