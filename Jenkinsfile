pipeline{
    agent{
        label "centos"
    }
    stages{
        stage("Pull code from SCM"){
            steps{
                git branch: 'master',
                url: 'https://github.com/adrianiacob22/webapps-test.git'
            }
        }
        stage('Launch the environment'){
            steps{
                sh "make install && make start"
            }
        }
        stage('Test if environment is ready'){
            steps{
                sh "./test_env.sh"
            }
        }
    }
    post{
        always{
            echo "Build has been finished"
            archiveArtifacts artifacts: '**/*.txt',
                   allowEmptyArchive: true,
                   fingerprint: true,
                   onlyIfSuccessful: false
            echo "We are sending the archived output to email or publish"
            sh "cat outfile.txt"
        }
        success{
            echo "========pipeline executed successfully ========"

        }
        failure{
            echo "========pipeline execution failed========"
        }
    }
}