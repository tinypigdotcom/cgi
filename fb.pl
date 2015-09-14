#!"C:\strawberry\perl\bin\perl.exe"

use strict;
use warnings;

package API;

use CGI;
use JSON;
use Data::Dumper;
use DBI;
use Tie::IxHash;
use Try::Tiny;

sub new {
    my ( $class, $greeting ) = @_;

    my $dbh = DBI->connect("DBI:mysql:database=cdcol;host=localhost",
                            "root", undef,
                            {'RaiseError' => 1});

    my $cgi = CGI->new;
    my $vars = $cgi->Vars();

    my $self = {
        dbh      => $dbh,
        cgi      => $cgi,
        vars     => $vars,
        messages => [],
        status   => 'OK',
    };

    bless $self, $class;

    return $self;
}

sub check_command {
    my ( $self ) = @_;
    my $vars = $self->{vars};
}

sub add_messages {
    my ( $self, @messages ) = @_;
    if ( @messages ) {
        push @{$self->{messages}}, @messages;
    }
    return;
}

sub get_error_string {
    my ( $self ) = @_;
    my $error_string = join ', ', @{$self->{errors}};
    return $error_string;
}

sub add_errors {
    my ( $self, @errors ) = @_;
    if ( @errors ) {
        push @{$self->{errors}}, @errors;
        $self->{status} = 'ERROR';
    }
    return;
}

sub in_error_state {
    my ( $self ) = @_;
    if ( ref $self->{errors} eq 'ARRAY' && @{$self->{errors}} ) {
        return 1;
    }
    else {
        return 0;
    }
}

sub add_album {
    my ( $self, $artist, $title, $year) = @_;
    my $dbh = $self->{dbh};
    try {
        $dbh->do("INSERT INTO cds (jahr,titel,interpret) VALUES (?,?,?)",undef,$year,$title,$artist);
    }
    catch {
        push @{$self->{errors}}, $_;
    };
    return;
}

sub delete_album_by_id {
    my ( $self, $id ) = @_;
    my $dbh = $self->{dbh};
    try {
        $dbh->do("DELETE FROM cds WHERE id=?",undef,$id);
    }
    catch {
        push @{$self->{errors}}, $_;
    };
    return;
}

sub get_all_data {
    my ( $self, $id ) = @_;
    my $dbh = $self->{dbh};
    my $sth = $dbh->prepare("SELECT * FROM cds");
    $sth->execute();
    while (my $ref = $sth->fetchrow_hashref()) {
        my $album = {
            id     => $ref->{id},
            year   => $ref->{jahr},
            title  => $ref->{titel},
            artist => $ref->{interpret},
        };
        push @{$self->{results}}, $album;
    }
    $sth->finish();
    return;
}

sub disconnect {
    my ( $self, $id ) = @_;
    my $dbh = $self->{dbh};
    $dbh->disconnect();
    return;
}

sub render_fb {
    my ( $self, $id ) = @_;

    my $cgi = $self->{cgi};

    print $cgi->header();

print <<'EOF';
<!DOCTYPE html>
<html>
<head>
<title>Facebook Login JavaScript Example</title>
<meta charset="UTF-8">
</head>
<body>
<script>
// ===================================================================
// Author: Matt Kruse <matt@mattkruse.com>
// WWW: http://www.mattkruse.com/
//
// NOTICE: You may use this code for any purpose, commercial or
// private, without any further permission from the author. You may
// remove this notice from your final code if you wish, however it is
// appreciated by the author if at least my web site address is kept.
//
// You may *NOT* re-distribute this code in any way except through its
// use. That means, you can include it in your product, or your web
// site, or any other form where the code is actually being used. You
// may not put the plain javascript up on your site for download or
// include it in your javascript libraries for download.
// If you wish to share this code with others, please just point them
// to the URL instead.
// Please DO NOT link directly to my .js files from your site. Copy
// the files to your server and use them there. Thank you.
// ===================================================================

// HISTORY
// ------------------------------------------------------------------
// March 18, 2004: Updated to include max depth limit, ignoring standard
//    objects, ignoring references to itself, and following only
//    certain object properties.
// March 17, 2004: Created
/*
DESCRIPTION: These functions let you easily and quickly view the data
structure of javascript objects and variables

COMPATABILITY: Will work in any javascript-enabled browser

USAGE:

// Return the output as a string, and you can do with it whatever you want
var out = Dumper(obj);

// When starting to traverse through the object, only follow certain top-
// level properties. Ignore the others
var out = Dumper(obj,'value','text');

// Sometimes the object you are dumping has a huge number of properties, like
// form fields. If you are only interested in certain properties of certain
// types of tags, you can restrict that like Below. Then if DataDumper finds
// an object that is a tag of type "OPTION" it will only examine the properties
// of that object that are specified.
DumperTagProperties["OPTION"] = [ 'text','value','defaultSelected' ]

// View the structure of an object in a window alert
DumperAlert(obj);

// Popup a new window and write the Dumper output to that window
DumperPopup(obj);

// Write the Dumper output to a document using document.write()
DumperWrite(obj);
// Optionall, give it a different document to write to
DumperWrite(obj,documentObject);

NOTES: Be Careful! Some objects hold references to their parent nodes, other
objects, etc. Data Dumper will keep traversing these nodes as well, until you
have a really, really huge tree built up. If the object you are passing in has
references to other document objects, you should either:
    1) Set the maximum depth that Data Dumper will search (set DumperMaxDepth)
or
    2) Pass in only certain object properties to traverse
or
    3) Set the object properties to traverse for each type of tag

*/
var DumperIndent = 1;
var DumperIndentText = " ";
var DumperNewline = "\n";
var DumperObject = null; // Keeps track of the root object passed in
var DumperMaxDepth = -1; // Max depth that Dumper will traverse in object
var DumperIgnoreStandardObjects = true; // Ignore top-level objects like window, document
var DumperProperties = null; // Holds properties of top-level object to traverse - others are igonred
var DumperTagProperties = new Object(); // Holds properties to traverse for certain HTML tags
function DumperGetArgs(a,index) {
    var args = new Array();
    // This is kind of ugly, but I don't want to use js1.2 functions, just in case...
    for (var i=index; i<a.length; i++) {
        args[args.length] = a[i];
    }
    return args;
}
function DumperPopup(o) {
    var w = window.open("about:blank");
    w.document.open();
    w.document.writeln("<HTML><BODY><PRE>");
    w.document.writeln(Dumper(o,DumperGetArgs(arguments,1)));
    w.document.writeln("</PRE></BODY></HTML>");
    w.document.close();
}
function DumperAlert(o) {
    alert(Dumper(o,DumperGetArgs(arguments,1)));
}
function DumperWrite(o) {
    var argumentsIndex = 1;
    var d = document;
    if (arguments.length>1 && arguments[1]==window.document) {
        d = arguments[1];
        argumentsIndex = 2;
    }
    var temp = DumperIndentText;
    var args = DumperGetArgs(arguments,argumentsIndex)
    DumperIndentText = "&nbsp;";
    d.write(Dumper(o,args));
    DumperIndentText = temp;
}
function DumperPad(len) {
    var ret = "";
    for (var i=0; i<len; i++) {
        ret += DumperIndentText;
    }
    return ret;
}
function Dumper(o) {
    var level = 1;
    var indentLevel = DumperIndent;
    var ret = "";
    if (arguments.length>1 && typeof(arguments[1])=="number") {
        level = arguments[1];
        indentLevel = arguments[2];
        if (o == DumperObject) {
            return "[original object]";
        }
    }
    else {
        DumperObject = o;
        // If a list of properties are passed in
        if (arguments.length>1) {
            var list = arguments;
            var listIndex = 1;
            if (typeof(arguments[1])=="object") {
                list = arguments[1];
                listIndex = 0;
            }
            for (var i=listIndex; i<list.length; i++) {
                if (DumperProperties == null) { DumperProperties = new Object(); }
                DumperProperties[list[i]]=1;
            }
        }
    }
    if (DumperMaxDepth != -1 && level > DumperMaxDepth) {
        return "...";
    }
    if (DumperIgnoreStandardObjects) {
        if (o==window || o==window.document) {
            return "[Ignored Object]";
        }
    }
    // NULL
    if (o==null) {
        ret = "[null]";
        return ret;
    }
    // FUNCTION
    if (typeof(o)=="function") {
        ret = "[function]";
        return ret;
    }
    // BOOLEAN
    if (typeof(o)=="boolean") {
        ret = (o)?"true":"false";
        return ret;
    }
    // STRING
    if (typeof(o)=="string") {
        ret = "'" + o + "'";
        return ret;
    }
    // NUMBER
    if (typeof(o)=="number") {
        ret = o;
        return ret;
    }
    if (typeof(o)=="object") {
        if (typeof(o.length)=="number" ) {
            // ARRAY
            ret = "[";
            for (var i=0; i<o.length;i++) {
                if (i>0) {
                    ret += "," + DumperNewline + DumperPad(indentLevel);
                }
                else {
                    ret += DumperNewline + DumperPad(indentLevel);
                }
                ret += Dumper(o[i],level+1,indentLevel-0+DumperIndent);
            }
            if (i > 0) {
                ret += DumperNewline + DumperPad(indentLevel-DumperIndent);
            }
            ret += "]";
            return ret;
        }
        else {
            // OBJECT
            ret = "{";
            var count = 0;
            for (i in o) {
                if (o==DumperObject && DumperProperties!=null && DumperProperties[i]!=1) {
                    // do nothing with this node
                }
                else {
                    if (typeof(o[i]) != "unknown") {
                        var processAttribute = true;
                        // Check if this is a tag object, and if so, if we have to limit properties to look at
                        if (typeof(o.tagName)!="undefined") {
                            if (typeof(DumperTagProperties[o.tagName])!="undefined") {
                                processAttribute = false;
                                for (var p=0; p<DumperTagProperties[o.tagName].length; p++) {
                                    if (DumperTagProperties[o.tagName][p]==i) {
                                        processAttribute = true;
                                        break;
                                    }
                                }
                            }
                        }
                        if (processAttribute) {
                            if (count++>0) {
                                ret += "," + DumperNewline + DumperPad(indentLevel);
                            }
                            else {
                                ret += DumperNewline + DumperPad(indentLevel);
                            }
                            ret += "'" + i + "' => " + Dumper(o[i],level+1,indentLevel-0+i.length+6+DumperIndent);
                        }
                    }
                }
            }
            if (count > 0) {
                ret += DumperNewline + DumperPad(indentLevel-DumperIndent);
            }
            ret += "}";
            return ret;
        }
    }
}
  // This is called with the results from from FB.getLoginStatus().
  function statusChangeCallback(response) {
    console.log('statusChangeCallback');
    console.log(response);
    // The response object is returned with a status field that lets the
    // app know the current login status of the person.
    // Full docs on the response object can be found in the documentation
    // for FB.getLoginStatus().
    if (response.status === 'connected') {
      // Logged into your app and Facebook.
      testAPI();
    } else if (response.status === 'not_authorized') {
      // The person is logged into Facebook, but not your app.
      document.getElementById('status').innerHTML = 'Please log ' +
        'into this app.';
    } else {
      // The person is not logged into Facebook, so we're not sure if
      // they are logged into this app or not.
      document.getElementById('status').innerHTML = 'Please log ' +
        'into Facebook.';
    }
  }

  // This function is called when someone finishes with the Login
  // Button.  See the onlogin handler attached to it in the sample
  // code below.
  function checkLoginState() {
    FB.getLoginStatus(function(response) {
      statusChangeCallback(response);
    });
  }

  window.fbAsyncInit = function() {
  FB.init({
    appId      : '711962825604395',
    cookie     : true,  // enable cookies to allow the server to access
                        // the session
    xfbml      : true,  // parse social plugins on this page
    version    : 'v2.2' // use version 2.2
  });

  // Now that we've initialized the JavaScript SDK, we call
  // FB.getLoginStatus().  This function gets the state of the
  // person visiting this page and can return one of three states to
  // the callback you provide.  They can be:
  //
  // 1. Logged into your app ('connected')
  // 2. Logged into Facebook, but not your app ('not_authorized')
  // 3. Not logged into Facebook and can't tell if they are logged into
  //    your app or not.
  //
  // These three cases are handled in the callback function.

  FB.getLoginStatus(function(response) {
    statusChangeCallback(response);
  });

  };

  // Load the SDK asynchronously
  (function(d, s, id) {
    var js, fjs = d.getElementsByTagName(s)[0];
    if (d.getElementById(id)) return;
    js = d.createElement(s); js.id = id;
    js.src = "//connect.facebook.net/en_US/sdk.js";
    fjs.parentNode.insertBefore(js, fjs);
  }(document, 'script', 'facebook-jssdk'));

  // Here we run a very simple test of the Graph API after login is
  // successful.  See statusChangeCallback() for when this call is made.
  function testAPI() {
    console.log('Welcome!  Fetching your information.... ');
    FB.api('/me', function(response) {
      console.log('Successful login for: ' + response.name);
      document.getElementById('status').innerHTML =
        'Thanks for logging in, ' + response.name + '!';
      DumperTagProperties["OPTION"] = ['text','value','defaultSelected'];
      console.log(Dumper(response));
    });
    FB.api('/me/permissions', function(response) {
        console.log(JSON.stringify(response));
    });
    FB.api('/me', {fields: 'email,first_name,last_name'}, function(response) {
        console.log(JSON.stringify(response));
    });
  }
</script>

<!--
  Below we include the Login Button social plugin. This button uses
  the JavaScript SDK to present a graphical Login button that triggers
  the FB.login() function when clicked.
-->

<fb:login-button scope="public_profile,email" onlogin="checkLoginState();">
</fb:login-button>

<div id="status">
</div>

</body>
</html>
EOF
    return;
}

package main;

my $api = API->new();

$api->render_fb();

