test -d mods || mkdir mods
set -x
for fn in fgdc/*.xml; do
  if [ ! -r mods/`basename $fn` ]; then
    xsltproc fgdc2mods.xsl $fn > mods/`basename $fn`
  fi
done
