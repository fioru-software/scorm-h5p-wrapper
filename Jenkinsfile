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

    parameters {
        booleanParam(name: 'DEPLOY', defaultValue: false, description: "Deploy To Kubernetes")
    }

    agent {
        kubernetes {
            inheritFrom 'jenkins-agent'
            yamlFile 'KubernetesPod.yaml'
        }
    }

    environment {
		DOCKER_REGISTRY = 'europe-west1-docker.pkg.dev/veri-cluster/docker-belgium'
        IMAGE_NAME = "scorm-h5p-wrapper"
        REPO_NAME = "fioru-software/$IMAGE_NAME"
        GITHUB_API_URL = "https://api.github.com/repos/$REPO_NAME"
        GITHUB_TOKEN = credentials('jenkins-github-personal-access-token')
        GCLOUD_KEYFILE = credentials('jenkins-gcloud-keyfile');
    }

    stages {

        stage('Build') {

            when {
                beforeAgent true;
                allOf {
                    expression {return params.DEPLOY}
                    anyOf {
                        branch 'master';    
                    }    
                }    
            }
            steps {
                container('cloud-sdk') {
                    script {
                        sh 'gcloud auth activate-service-account jenkins-agent@veri-cluster.iam.gserviceaccount.com  --key-file=${GCLOUD_KEYFILE}'
                        env.GCLOUD_TOKEN = sh(script: "gcloud auth print-access-token", returnStdout: true).trim()
                    }
                }
                container('docker') {
                    script {
                        sh 'docker login -u oauth2accesstoken -p $GCLOUD_TOKEN https://$DOCKER_REGISTRY'
                        sh 'docker build --tag ${IMAGE_NAME}:${GIT_COMMIT} .'
                        sh 'docker tag ${IMAGE_NAME}:${GIT_COMMIT} ${DOCKER_REGISTRY}/${IMAGE_NAME}:${GIT_COMMIT}'
                        sh 'docker tag ${IMAGE_NAME}:${GIT_COMMIT} ${DOCKER_REGISTRY}/${IMAGE_NAME}:latest'
                        sh 'docker push ${DOCKER_REGISTRY}/${IMAGE_NAME}:${GIT_COMMIT}'
                        sh 'docker push ${DOCKER_REGISTRY}/${IMAGE_NAME}:latest'
                    }
                }
            }
        }

        stage ('Deploy') {    
            when {    
                beforeAgent true;    
                allOf {    
                    expression {return params.DEPLOY}    
                    anyOf {    
                        branch 'master';    
                    }    
                }
            }
            steps {
                container('cloud-sdk') {
                    script {
                        sh "kubectl --token=$GCLOUD_TOKEN apply -k deployment/k8s/overlays/staging"
                        sh "kubectl --token=$GCLOUD_TOKEN rollout restart deployment staging-${IMAGE_NAME}"
                        sh "kubectl --token=$GCLOUD_TOKEN rollout status deployment staging-${IMAGE_NAME}"
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
