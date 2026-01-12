pipeline {
    agent {
        /* Runs on a remote agent. Change 'remote-agent' to your agent's label. */
        label 'remote-agent'
    }

    parameters {
        string(name: 'NOTIFY_EMAIL', defaultValue: 'admin@example.com', description: 'Email to notify on failure')
    }

    stages {
        stage('Initialize') {
            steps {
                echo "Starting Disk Monitor Pipeline on node: ${env.NODE_NAME}"
                checkout scm
            }
        }

        stage('Run Monitor & Cleanup') {
            steps {
                script {
                    // Ensure the script is executable
                    sh "chmod +x monitor_disk.sh"
                    
                    // Execute the script. 
                    // Script returns 0 if healthy/cleaned, 1 if critical.
                    def exitCode = sh(script: "./monitor_disk.sh", returnStatus: true)
                    
                    if (exitCode != 0) {
                        error "CRITICAL: Disk space is still critical after cleanup attempts."
                    }
                }
            }
        }
    }

    post {
        success {
            echo "Pipeline finished successfully. Disk space is under control."
        }
        failure {
            echo "Pipeline failed! Sending email notification to ${params.NOTIFY_EMAIL}..."
            mail to: "${params.NOTIFY_EMAIL}",
                 subject: "CRITICAL: Disk Space Alert - Agent ${env.NODE_NAME}",
                 body: """
                    Disk space monitor failed on ${env.NODE_NAME}.
                    
                    The automated cleanup script was unable to reduce disk usage below the 80% threshold.
                    
                    Please login to the agent and perform manual cleanup immediately.
                    
                    Build: ${env.JOB_NAME} #${env.BUILD_NUMBER}
                    URL: ${env.BUILD_URL}
                 """
        }
    }
}
