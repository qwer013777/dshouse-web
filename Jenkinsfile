def PROJECT_NAME = "dshouse-web"
def Namespace = "dshouse-web"
def gitUrl = "https://github.com/dslee1371/dshouse-web.git"
def imgRegistry = "172.10.30.11:5000"
def gitOpsUrl = "https://github.com/dslee1371/gitops"
def opsBranch = "main"
def GIT_TAG_MESSAGE

pipeline {
    agent {
        kubernetes {
            yaml """
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: kaniko
    image: gcr.io/kaniko-project/executor:debug
    command:
    - /busybox/cat
    tty: true
    volumeMounts:
    - name: kaniko-secret
      mountPath: /kaniko/.docker
      readOnly: true
  - name: git
    image: alpine/git:latest
    command:
    - cat
    tty: true
  volumes:
  - name: kaniko-secret
    secret:
      secretName: kaniko-secret
"""
        }
    }
    
    parameters {
        booleanParam(name: 'UPDATE_GITOPS', defaultValue: true, description: 'Update GitOps repository')
    }
    
    environment {
        DOCKER_CONFIG = '/kaniko/.docker'
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: "${params.TAG}"]],
                    doGenerateSubmoduleConfigurations: false,
                    extensions: [
                        [$class: 'CloneOption', depth: 1, shallow: true]
                    ],
                    gitTool: 'Default',
                    submoduleCfg: [],
                    userRemoteConfigs: [[
                        url: "${gitUrl}",
                        credentialsId: 'github-auth'
                    ]]
                ])
                
                script {
                    // Get git commit info for better tagging
                    GIT_TAG_MESSAGE = sh(
                        script: 'git log -1 --pretty=format:"%h - %s"',
                        returnStdout: true
                    ).trim()
                    
                    echo "Building commit: ${GIT_TAG_MESSAGE}"
                }
            }
        }
        
        stage('Build and Push Image') {
            steps {
                container('kaniko') {
                    script {
                        def imageTag = "${imgRegistry}/${Namespace}/${PROJECT_NAME}:${params.TAG}"
                        def latestTag = "${imgRegistry}/${Namespace}/${PROJECT_NAME}:latest"
                        
                        sh """
                            /kaniko/executor \\
                                --context=${WORKSPACE} \\
                                --dockerfile=${WORKSPACE}/Dockerfile \\
                                --destination=${imageTag} \\
                                --destination=${latestTag} \\
                                --insecure \\
                                --skip-tls-verify \\
                                --cache=true \\
                                --cache-ttl=24h
                        """
                        
                        echo "Successfully built and pushed:"
                        echo "- ${imageTag}"
                        echo "- ${latestTag}"
                    }
                }
            }
        }
        
        stage('Update GitOps Repository') {
            when {
                expression { params.UPDATE_GITOPS }
            }
            steps {
                container('git') {
                    script {
                        withCredentials([usernamePassword(
                            credentialsId: 'github-auth',
                            usernameVariable: 'GIT_USERNAME',
                            passwordVariable: 'GIT_PASSWORD'
                        )]) {
                            def escUser = env.GIT_USERNAME.replaceAll('@','%40')
                            sh """
                                # Configure git
                                git config --global user.email "dslee1371@gmail.com"
                                git config --global user.name "dslee"
                                
                                # Clone GitOps repository
                                git clone https://github.com/dslee1371/gitops.git gitops-repo
                                cd gitops-repo
                                
                                # Update kustomization.yaml or deployment files
                                # This is a template - adjust paths according to your GitOps structure
                                if [ -f "${Namespace}/kustomization.yaml" ]; then
                                    sed -i 's|newTag:.*|newTag: ${params.TAG}|g' ${Namespace}/kustomization.yaml
                                    echo "Updated kustomization.yaml with tag: ${params.TAG}"
                                elif [ -f "${Namespace}/deployment.yaml" ]; then
                                    sed -i 's|image:.*${PROJECT_NAME}:.*|image: ${imgRegistry}/${Namespace}/${PROJECT_NAME}:${params.TAG}|g' ${Namespace}/deployment.yaml
                                    echo "Updated deployment.yaml with new image tag: ${params.TAG}"
                                else
                                    echo "Warning: No kustomization.yaml or deployment.yaml found for ${PROJECT_NAME}"
                                    echo "Please update your GitOps repository structure"
                                fi
                                
                                # Commit and push changes
                                git add .
                                if git diff --staged --quiet; then
                                    echo "No changes to commit"
                                else
                                    git commit -m "Update ${PROJECT_NAME} image tag to ${params.TAG}
                                    
                                    Build info: ${GIT_TAG_MESSAGE}
                                    Jenkins Build: ${BUILD_NUMBER}"
                                    
                                    git push https://${escUser}:${GIT_PASSWORD}@github.com/dslee1371/gitops.git ${opsBranch}
                                    echo "Successfully pushed GitOps updates"
                                fi
                            """
                        }
                    }
                }
            }
        }
    }
    
    post {
        always {
            cleanWs()
        }
        success {
            echo "🎉 Pipeline completed successfully!"
            echo "Image: ${imgRegistry}/${Namespace}/${PROJECT_NAME}:${params.TAG}"
        }
        failure {
            echo "❌ Pipeline failed. Check the logs above for details."
        }
    }
}
