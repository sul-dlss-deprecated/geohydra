export PATH=../bin:$PATH
test -d mods || mkdir mods
set -x
for fn in fgdc/*.xml; do
  if [ ! -r mods/`basename $fn` ]; then
    xsltproc-saxon $fn fgdc2mods.xsl mods/`basename $fn`
  fi
done
