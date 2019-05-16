#!/bin/bash

projectname=$1
startdate=$2
targetrepo=$3
codemaatfolder=$4

if [ "$targetrepo" == "" ] ; then
  echo "Error: not enough parameters, usage: $0 <project name> <start date> <path to repo> <code-maat path>"
  exit
fi

# Setup
METRICFOLDER=$(pwd)
TARGET=$METRICFOLDER/out/$projectname
DATA=$TARGET/data
CODESPACE=$METRICFOLDER/$targetrepo
CODEMAAT=$METRICFOLDER/$codemaatfolder

# Clean up previous runs
rm $CODESPACE/logfile.log
rm -rf $DATA
mkdir -p $DATA

# Start
cd $CODESPACE
git pull -pr
echo "./-\. Gathering metrics from $CODESPACE (after $startdate)"
git log --all --numstat --date=short --pretty=format:'--%h--%ad--%aN' --no-renames --no-merges --after=$startdate > $CODESPACE/logfile.log

echo "./-\. Building CODE-MAAT"
cd $CODEMAAT && docker build -t code-maat-app .

echo "./-\. Generating authors-per-module.csv"
docker run -v $CODESPACE:/data code-maat-app -l /data/logfile.log -c git2 > $DATA/authors-per-module.csv
for i in "coupling" "age" "abs-churn" "author-churn" "entity-churn" "entity-ownership" "entity-effort"; do
  echo "./-\. Generating $i.csv"
  docker run -v $CODESPACE:/data code-maat-app -l /data/logfile.log -c git2 -a $i > $DATA/$i.csv
done

# post processing
cd $METRICFOLDER
rm $TARGET/img/*.png
DATA=$projectname Rscript plot.r
./html.sh $projectname
