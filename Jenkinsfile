
projectname="2git"
startdate="2017-01-01"
targetrepo="2git"
codemaatfolder="code-maat"

node('docker') {
  stage('checkout') {
    deleteDir()
    checkout scm
    bash "git clone git@github.com:adamtornhill/code-maat.git ${codemaatfolder}"
    bash "git clone git@github.com:Praqma/2git.git ${targetrepo}"
  }
  stage('create plots') {
    bash "./getmetrics.sh ${projectname} ${startdate} ${targetrepo} ${codemaatfolder}"
  }
  stage('archive') {
    archiveArtifacts "out/**/*.*"
  }
}

