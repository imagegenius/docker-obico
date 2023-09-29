pipeline {
  agent {
    label 'X86-BUILDER-1'
  }
  options {
    buildDiscarder(logRotator(numToKeepStr: '10', daysToKeepStr: '60'))
    parallelsAlwaysFailFast()
  }
  environment {
    BUILDS_DISCORD=credentials('build_webhook_url')
    GITHUB_TOKEN=credentials('github_token')
    IG_USER = 'imagegenius'
    IG_REPO = 'obico'
  }
  stages {
    stage("Set ENV Variables"){
      steps{
        script{
          env.GITHUBIMAGE = 'ghcr.io/' + env.IG_USER + '/' + env.IG_REPO + '-darknet'
        }
      }
    }
    stage('Build') {
      environment {
        BUILDX_CONTAINER = "${sh(script: "head /dev/urandom | tr -dc 'a-z' | head -c12", returnStdout: true).trim()}"
      }
      steps {
        echo 'Logging into Github'
        sh '''#!/bin/bash
              echo $GITHUB_TOKEN | docker login ghcr.io -u ImageGenius-CI --password-stdin
           '''
        echo 'Build'
        sh '''#!/bin/bash
              docker buildx create --driver=docker-container --name=${BUILDX_CONTAINER}
              set -e
              docker buildx build \
                --no-cache --pull -t ${GITHUBIMAGE}:latest \
                --platform=linux/amd64 \
                --builder=${BUILDX_CONTAINER} --load .
           '''
        echo 'Push'
        sh '''#!/bin/bash
              docker push ${GITHUBIMAGE}:latest
              docker rmi \
                ${GITHUBIMAGE}:latest || :
              docker buildx rm ${BUILDX_CONTAINER}
           '''
      }
    }

  }
  post {
    always {
      script{
        if (currentBuild.currentResult == "SUCCESS"){
          sh ''' curl -X POST -H "Content-Type: application/json" --data '{"avatar_url": "https://wiki.jenkins.io/JENKINS/attachments/2916393/57409617.png","embeds": [{"color": 1681177,\
                 "description": "**'${IG_REPO}' build '${BUILD_NUMBER}'**\\n**Job:** '${RUN_DISPLAY_URL}'\\n"}],\
                 "username": "Jenkins"}' ${BUILDS_DISCORD} '''
        }
        else {
          sh ''' curl -X POST -H "Content-Type: application/json" --data '{"avatar_url": "https://wiki.jenkins.io/JENKINS/attachments/2916393/57409617.png","embeds": [{"color": 16711680,\
                 "description": "**'${IG_REPO}' build '${BUILD_NUMBER}' Failed!**\\n**Job:** '${RUN_DISPLAY_URL}'\\n"}],\
                 "username": "Jenkins"}' ${BUILDS_DISCORD} '''
        }
      }
    }
    cleanup {
      cleanWs()
    }
  }
}
