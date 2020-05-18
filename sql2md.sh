set -x
f=$1
mkdir -p ../doc/sphinx
mkdir -p ../doc/md
md_target=../doc/md/`basename $f .sql`.md
rst_target=../doc/sphinx/`basename $f .sql`.rst
sed -e "s/--%//" $f > $md_target
#html_target=`basename $f .sql`.html
pandoc $md_target -o $rst_target
