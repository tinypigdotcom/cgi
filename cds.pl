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

sub render {
    my ( $self, $id ) = @_;

    my $cgi = $self->{cgi};
    my %header_args = (
        -type   => 'application/json',
    );
    my %response;
    tie %response, 'Tie::IxHash';
    %response = (
        status   => $self->{status},
        messages => $self->{messages},
    );

    if ($self->in_error_state()) {
        $header_args{'-status'} = '400 Bad Request';
        $response{errors} = $self->{errors};
    }
    $response{vars}    = $self->{vars};
    $response{results} = $self->{results};

    print $cgi->header(%header_args);

    my $json_text = to_json({response => \%response});
    print $json_text;
    return;
}

package main;

my $api = API->new();
$api->get_all_data();
$api->add_errors("WTF");

#$api->delete_album_by_id(1);
#$api->add_album("Foo Fighters", "Foo Fighters", "1995");

$api->render();

__END__

  # Drop table 'foo'. This may fail, if 'foo' doesn't exist
  # Thus we put an eval around it.
  eval { $dbh->do("DROP TABLE foo") };
  print "Dropping foo failed: $@\n" if $@;

  # Create a new table 'foo'. This must not fail, thus we don't
  # catch errors.
  $dbh->do("CREATE TABLE foo (id INTEGER, name VARCHAR(20))");

  # INSERT some data into 'foo'. We are using $dbh->quote() for
  # quoting the name.
  $dbh->do("INSERT INTO foo VALUES (1, " . $dbh->quote("Tim") . ")");

  # same thing, but using placeholders (recommended!)
  $dbh->do("INSERT INTO foo VALUES (?, ?)", undef, 2, "Jochen");

print <<'EOF';

<?xml version="1.0" encoding="utf-8"?>
  <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
      "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
  <html xmlns="http://www.w3.org/1999/xhtml">
      <head>
          <title>Conforming XHTML 1.0 Strict Template</title>
          <style type="text/css">
              p {
                  position: relative;
                  top: 100px;
                  left: 100px;
              }
          </style>
          <script  type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/jquery/1.11.2/jquery.min.js"></script>
          <script type="text/javascript">
              $(document).ready(function(){
                  $("#one").click(function(){
                      $(".valid").toggle();
                  });
              });
          </script>
      </head>
      <body>
          <p id="one">[TOGGLE]</p>
          <p class="valid">Watch Me</p>
      </body>
  </html>
EOF

