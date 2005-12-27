echo "# Please do not modify this unless you know what you are doing."
echo "# created by setup.sid_local.pm script of ACIS package."
echo
echo 'package ACIS::ShortIDs;'
echo
echo 'use vars qw( $home_dir $db_name $db_user $db_pass );'
echo
echo "\$home_dir = \"$sid_home\";"
echo

echo '### database parameters'
echo "\$db_name = \"$sid_db_name\";"
echo "\$db_user = \"$db_user\";"
echo "\$db_pass = \"$db_pass\";"
echo

echo
echo '1;'

