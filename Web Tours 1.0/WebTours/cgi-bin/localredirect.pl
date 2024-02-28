#!perl
# $Id: localredirect.pl,v 1.1 2004-10-26 12:18:01 evgenyk Exp $ [MISCCSID]

use CGI qw (:standard);

#
# Little file that will redirect a user through itself 'iter' iterations.
# After 'iter' iterations, the user will be redirected to the URL specified
# by 'dest'.  If 'dest' doesn't exist, the user will be redirected to index.html.
#


$iterations = param('iter');
$iterations--;
param('iter', $iterations);

$url = self_url();

if ($iterations < 0) {
	$url =~ s/localredirect.pl/index.html/;

	if (param('dest')) {	
		$dest = param('dest');
		$url =~ s/index.html/$dest/;
	}
}

print redirect(-method=>'GET',
	-location=>$url);

