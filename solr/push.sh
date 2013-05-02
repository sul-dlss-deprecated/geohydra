for d in dlss-dev-drh-geo; do
  rsync -avL $d/ sul-solr-a:$d/
done
