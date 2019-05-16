#!/bin/bash -x

project=$1

cd out/$project

html=plots.html

find img -name *.png | sort > files

cat > $html <<EOF
<html>
<body>
EOF

while read -r image; do
  p=$(echo $image | sed 's/.png//')
  echo "<div style=\"border-style:outset\" align=\"center\">" >> $html
  echo "<img src=$image width=\"90%\">" >> $html
  echo "${!p}" >> $html
  echo "</div>" >> $html
done < files

cat >> $html <<EOF
</body>
</html>
EOF
