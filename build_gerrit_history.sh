#/bin/bash

PROJECT=$1
DIRECTORY="results/$1"
DATA_DIRECTORY="$DIRECTORY/data"
GRAPHS_DIRECTORY="$DIRECTORY/graphs"

mkdir -p $DATA_DIRECTORY
mkdir -p $GRAPHS_DIRECTORY

# grab comments
PATCHES="$DATA_DIRECTORY/gerrit_history.patches"
QUERY="project:openstack/$1 branch:master --comments"
ssh -p29418 thingee@review.openstack.org gerrit query --format JSON $QUERY >$PATCHES
LAST=`tail -20 $PATCHES | sed -e 's/[{}]/''/g' | awk -v k="text" '{n=split($0,a,","); for (i=1; i<=n; i++) print a[i]}' | grep sortKey | cut -d: -f2 | cut -d: -f2 | sed 's/"//g' | tail -1`
OLDLAST=''
while [[ $OLDLAST != $LAST ]]; do
    OLDLAST=$LAST
    ssh -p29418 thingee@review.openstack.org gerrit query --format JSON $QUERY resume_sortkey:$LAST >>$PATCHES
    LAST=`tail -20 $PATCHES | sed -e 's/[{}]/''/g' | awk -v k="text" '{n=split($0,a,","); for (i=1; i<=n; i++) print a[i]}' | grep sortKey | cut -d: -f2 | cut -d: -f2 | sed 's/"//g' | tail -1`
done

# grab open patches (that aren't WIP)
PATCHES="$DATA_DIRECTORY/open.patches"
QUERY="project:openstack/$PROJECT branch:master status:open NOT label:Workflow\<=-1"
ssh -p29418 thingee@review.openstack.org gerrit query --format JSON $QUERY >$PATCHES
LAST=`tail -20 $PATCHES | sed -e 's/[{}]/''/g' | awk -v k="text" '{n=split($0,a,","); for (i=1; i<=n; i++) print a[i]}' | grep sortKey | cut -d: -f2 | cut -d: -f2 | sed 's/"//g' | tail -1`
OLDLAST=''
while [[ $OLDLAST != $LAST ]]; do
    OLDLAST=$LAST
    ssh -p29418 thingee@review.openstack.org gerrit query --format JSON $QUERY resume_sortkey:$LAST >>$PATCHES
    LAST=`tail -20 $PATCHES | sed -e 's/[{}]/''/g' | awk -v k="text" '{n=split($0,a,","); for (i=1; i<=n; i++) print a[i]}' | grep sortKey | cut -d: -f2 | cut -d: -f2 | sed 's/"//g' | tail -1`
done

# grab closed patches
PATCHES="$DATA_DIRECTORY/closed.patches"
QUERY="project:openstack/$PROJECT branch:master status:closed NOT label:Workflow\<=-1"
ssh -p29418 thingee@review.openstack.org gerrit query --format JSON $QUERY >$PATCHES
LAST=`tail -20 $PATCHES | sed -e 's/[{}]/''/g' | awk -v k="text" '{n=split($0,a,","); for (i=1; i<=n; i++) print a[i]}' | grep sortKey | cut -d: -f2 | cut -d: -f2 | sed 's/"//g' | tail -1`
OLDLAST=''
while [[ $OLDLAST != $LAST ]]; do
    OLDLAST=$LAST
    ssh -p29418 thingee@review.openstack.org gerrit query --format JSON $QUERY resume_sortkey:$LAST >>$PATCHES
    LAST=`tail -20 $PATCHES | sed -e 's/[{}]/''/g' | awk -v k="text" '{n=split($0,a,","); for (i=1; i<=n; i++) print a[i]}' | grep sortKey | cut -d: -f2 | cut -d: -f2 | sed 's/"//g' | tail -1`
done

python contrib_stats.py $PROJECT
