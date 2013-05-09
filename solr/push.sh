for d in dlss-dev-drh-geo; do
  rsync -avL $d/ dlss-dev-drh:$d/
done
