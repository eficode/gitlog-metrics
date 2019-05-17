
projectname="2git"
startdate="2017-01-01"
targetrepo="2git"

node('docker') {
  stage('checkout') {
    deleteDir()
    checkout scm
    sh "git clone https://github.com/Praqma/2git.git ${targetrepo}"
  }
  stage('gather stats') {
    sh "./getmetrics.sh ${projectname} ${startdate} ${targetrepo}"
  }
  stage('create plots') {
    withEnv(["DATA=${projectname}"]) {
      docker.image('drbosse/tidyverse-hashmap:0.1.1').inside {
        sh '''ls -l
        Rscript plot.r'''
      }
    }
  }
  stage('html') {
    sh "./html.sh ${projectname}"
  }
  stage('archive') {
    archiveArtifacts "out/**/*.*"
  }
}

