test -d mods || mkdir mods
set -x
for fn in fgdc/*.xml; do
  xsltproc fgdc2mods.xsl $fn > mods/`basename $fn`
done
