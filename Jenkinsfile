void setBuildStatus(String message, String state, String repo ) {
  step([
      $class: "GitHubCommitStatusSetter",
      reposSource: [$class: "ManuallyEnteredRepositorySource", url: "https://github.com/$repo"],
      contextSource: [$class: "ManuallyEnteredCommitContextSource", context: "ci/jenkins/build-status"],
      errorHandlers: [[$class: "ChangingBuildStatusErrorHandler", result: "UNSTABLE"]],
      statusResultSource: [ $class: "ConditionalStatusResultSource", results: [[$class: "AnyBuildResult", message: message, state: state]] ]
  ]);
}

pipeline {

    agent {
        kubernetes {
            inheritFrom 'jenkins-agent'
            yamlFile 'KubernetesPod.yaml'
        }
    }

    environment {
        IMAGE_NAME = "scorm-h5p-wrapper"
        REPO_NAME = "fioru-software/$IMAGE_NAME"
        GITHUB_API_URL = "https://api.github.com/repos/$REPO_NAME"
        GITHUB_TOKEN = credentials('jenkins-github-personal-access-token')
        COMMIT_SHA = sh(script: "git log -1 --format=%H", returnStdout:true).trim()
        GCLOUD_KEYFILE = credentials('jenkins-gcloud-keyfile');
    }

    stages {

        stage('Build') {

            steps {
                container('gcloud') {
                    script {
                        sh 'gcloud auth activate-service-account jenkins-agent@veri-cluster.iam.gserviceaccount.com  --key-file=${GCLOUD_KEYFILE}'
                        env.GCLOUD_TOKEN = sh(script: "gcloud auth print-access-token", returnStdout: true).trim()
                    }
                }
                container('docker') {
                    script {
                        sh 'docker login -u oauth2accesstoken -p $GCLOUD_TOKEN https://eu.gcr.io'
                        sh 'docker build --tag ${IMAGE_NAME}:${COMMIT_SHA} .'
                        sh 'docker tag ${IMAGE_NAME}:${COMMIT_SHA} eu.gcr.io/veri-cluster/${IMAGE_NAME}:${COMMIT_SHA}'
                        sh 'docker tag ${IMAGE_NAME}:${COMMIT_SHA} eu.gcr.io/veri-cluster/${IMAGE_NAME}:latest'
                        sh 'docker push eu.gcr.io/veri-cluster/${IMAGE_NAME}:${COMMIT_SHA}'
                        sh 'docker push eu.gcr.io/veri-cluster/${IMAGE_NAME}:latest'
                    }
                }
            }
        }

    }
    post {
        success {
            setBuildStatus("Success", "SUCCESS", REPO_NAME)
        }
        failure {
            setBuildStatus("Failure", "FAILURE", REPO_NAME)
        }
    }
}
