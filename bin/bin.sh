# edit & source this file
alias pant='vim ~/antcat/bin/bin.sh'
alias sant='source ~/antcat/bin/bin.sh'

default_database="antcat_development"

# execute a SQL statement
function sql {
  echo "$@" | mysql -u root -t "$default_database"
}

# describe a database table
function desc {
  mysql -u root -e "describe $1" "$default_database"
}

# describe references table
function descref {
  mysql -u root -e 'describe `references`' "$default_database"
}

function restart_solr {
  RAILS_ENV=test bundle exec rake sunspot:solr:stop
  RAILS_ENV=test bundle exec rake sunspot:solr:start
  RAILS_ENV=development bundle exec rake sunspot:solr:stop
  RAILS_ENV=development bundle exec rake sunspot:solr:start
}

# find a name in Bolton's HTML-converted files
function find_bolton {
  ack -i -A 1 "\b$@\b" ~/antcat/data/bolton/*
}

function find_name {
  x=$@
  mysql -u root -e "select taxa.id, names.name, taxa.type, status from taxa join names on taxa.name_id = names.id where names.name like '%$x%'" "$default_database"
}
alias find_taxon=find_name
alias show=find_name
function find_id {
  mysql -u root -e "select taxa.id, names.name, taxa.type, status from taxa join names on taxa.name_id = names.id where taxa.id = $1" "$default_database"
}
function find_where {
  mysql -u root -e "SELECT taxa.id, names.name, taxa.type, status FROM taxa JOIN names ON taxa.name_id = names.id WHERE $@" "$default_database"
}

##############################################################
# copying databases to and from local, preview, and production

alias dump_local_db='mysqldump antcat_development -u root > /tmp/dump.sql && head /tmp/dump.sql'

# Application master: ec2-184-72-234-231.compute-1.amazonaws.com

production_server='ec2-75-101-238-13.compute-1.amazonaws.com'
production_password='7AdbiWigyX'
preview_server='ec2-23-21-238-9.compute-1.amazonaws.com'
preview_password='ret63V5ApP'

function copy_production_db_to_preview {
  file_name="/tmp/antcat_production.sql"

  echo "Dumping production database..."
  ssh deploy@$production_server "mysqldump antcat -udeploy -p$production_password > $file_name"

  echo "Copying to local..."
  scp deploy@$production_server:$file_name /tmp

  echo "Copying to preview..."
  scp $file_name deploy@$preview_server:/tmp

  echo 'Importing into preview database...'
  ssh deploy@$preview_server "mysql antcat -udeploy -p$preview_password < $file_name"

  echo 'Done.'
}

function copy_local_db_to_production {
  file_name="local_antcat_development.sql"
  server="ec2-75-101-238-13.compute-1.amazonaws.com"
  echo Dumping $file_name
  mysqldump antcat_development -uroot > /tmp/$file_name
  echo "Copying to production ($server)"
  scp /tmp/$file_name deploy@$server:/tmp
  echo Importing into antcat database on production
  ssh deploy@$server "mysql antcat -udeploy -p7AdbiWigyX < /tmp/$file_name"
}

function copy_local_db_to_preview {
  file_name="local_antcat_development.sql"
  server="ec2-23-21-238-9.compute-1.amazonaws.com"
  echo Dumping $file_name
  mysqldump antcat_development -uroot > /tmp/$file_name
  echo "Copying to preview ($server)"
  scp /tmp/$file_name deploy@$server:/tmp
  echo Importing into antcat database on preview
  ssh deploy@$server "mysql antcat -udeploy -pret63V5ApP < /tmp/$file_name"
}

function copy_production_to_local_db {
  file_name="antcat_production.sql"
  server="ec2-75-101-238-13.compute-1.amazonaws.com"
  local_file_directory="/Users/mwilden/antcat/data/tmp"
  echo "Dumping production ($server)"
  ssh deploy@$server "mysqldump antcat -udeploy -p7AdbiWigyX > /tmp/$file_name"
  echo "Copying to local database"
  scp deploy@$server:/tmp/$file_name $local_file_directory
  echo "Dropping and recreating local databases"
  bundle exec rake db:drop:all db:create:all
  echo Importing into local database
  mysql antcat_development -uroot < $local_file_directory/$file_name
  echo Migrating
  bundle exec rake db:migrate db:test:prepare
}

export preview_server 
function copy_production_to_preview {
  # get production database
  file_name="antcat_production.sql"
  server="ec2-75-101-238-13.compute-1.amazonaws.com"
  local_file_directory="/Users/mwilden/antcat/data/tmp"
  echo "Dumping production ($server)"
  ssh deploy@$server "mysqldump antcat -udeploy -p7AdbiWigyX > /tmp/$file_name"

  # send it to preview
  echo "Copying to preview database"
  server="ec2-23-21-238-9.compute-1.amazonaws.com"
  scp /tmp/$file_name deploy@$server:/tmp

  # import it into preview
  echo Importing into antcat database on preview
  ssh deploy@$server "mysql antcat -udeploy -pret63V5ApP < /tmp/$file_name"
}

function import_db {
  if [ $# -lt 1 ]; then
    echo 'Usage: import_db <filename>'
    return
  fi
  local_file_directory="/Users/mwilden/antcat/data/tmp"
  file_name=$local_file_directory/$1
  echo Importing $file_name
  echo "Dropping and recreating local databases (ignore 'errors')"
  bundle exec rake db:drop:all db:create:all
  echo Importing into local database
  mysql antcat_development -uroot < $file_name
  echo Migrating
  bundle exec rake db:migrate db:test:prepare
}

function export_db {
  if [ $# -lt 1 ]; then
    echo 'Usage: export_db <filename>'
    return
  fi
  local_file_directory="/Users/mwilden/antcat/data/tmp"
  file_name=$local_file_directory/$1
  echo Exporting to $file_name
  mysqldump antcat_development -uroot > $file_name
  echo Migrating
  bundle exec rake db:migrate db:test:prepare
}

# getting the production database
alias get_prod_db=copy_production_to_local_db
function import_prod_db {
  import_db antcat_production.sql
}
alias gpdb=get_prod_db
alias impdb=import_prod_db
alias ipdb=import_prod_db

# getting the preview database
function import_preview_db {
  import_db antcat_preview.sql
}

# deploying
alias deploy='ey web disable --environment=antcat_production && git pull --rebase && git push origin master && ey deploy --branch master -m --environment=antcat_production && open http://antcat.org'
alias deploy_preview='ey web disable --environment=preview && git pull --rebase && git push origin master && ey deploy --branch master -m --environment=preview && open http://preview.antcat.org'
alias deploy_preview_with_data="deploy_preview && copy_local_db_to_preview && open http://preview.antcat.org"
alias deploy_both="deploy_preview && deploy"
alias deploy_if_green="bundle exec rake all && deploy"
alias dig=deploy_if_green
alias dbig=deploy_both_if_green
alias deploy_both_if_green="bundle exec rake all && deploy_both"
alias deploy_both_with_data="deploy && get_prod_db && deploy_preview_with_data"
alias dbwd=deploy_both_with_data
alias deploy_both_with_data_if_green="get_prod_db && bundle exec rake all && deploy_both_with_data"
alias dbig=deploy_both_if_green

alias disable='ey web disable --environment=antcat_production'
alias enable='ey web enable --environment=antcat_production && open http://antcat.org'

# running cucumber scenarios
alias cuke="cuc features/editing"
alias cucke=cuke
alias cukex="cuc features/editing/add_taxon.feature features/editing/edit_taxon.feature"
alias cuckex=cukex
alias test_widgets="cuc features/editing/widgets"
alias test_ref_widgets="cuc features/editing/widgets/reference_popup.feature features/editing/widgets/reference_field.feature"
alias test_taxon="cuc features/editing/{add,edit}_taxon.feature"
alias test_quick_taxon="cuc features/editing/workflow.feature features/catalog/catalog.feature features/editing/add_taxon.feature:16"

function menu {
  type cuke
  type cukex
  type test_widgets
  type test_ref_widgets
  type test_taxon
  type test_quick_taxon
  type deploy_both_if_green
}

# to restart an application, run this as root on production server
# /engineyard/bin/app_<appname> restart