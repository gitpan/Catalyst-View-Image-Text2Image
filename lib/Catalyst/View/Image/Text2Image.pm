package Catalyst::View::Image::Text2Image;

use warnings;
use strict;
use parent 'Catalyst::View';
use GD::Simple;

=head1 NAME

Catalyst::View::Image::Text2Image - Catalyst view to create text into image using GD::Simple;

=head1 DESCRIPTION

Catalyst::View::Image::Text2Image is a view that creates images using GD::Simple.
You can set $c->stash->{Text2Image} to several options that will define your output.

=head1 SYNOPSIS

=over

=item Create a Text2Image view:

 script/myapp_create.pl view Image::Text2Image Image::Text2Image

=item text2image example:

  Your controller:

	sub Text2Image :Local {
		my ( $self, $c) = @_;
		
		$c->stash->{Text2Image}->{x} = 100;
		$c->stash->{Text2Image}->{y} = 45;
		$c->stash->{Text2Image}->{string} ||= 'Done with Catalyst::View::Image::Text2Image';
		$c->stash->{Text2Image}->{morph} = 1; # Should the x value be adapted when text is too long?
		$c->stash->{Text2Image}->{font} = 'Times New Roman';
		$c->stash->{Text2Image}->{fontsize} = '15';
		$c->stash->{Text2Image}->{bgcolor} = 'black';
		$c->stash->{Text2Image}->{fgcolor} = 'green';
		$c->stash->{Text2Image}->{moveTo} = [0,45];
		$c->stash->{Text2Image}->{angle} = -5;
		$c->detach('View::Image::Text2Image');
	}
	
=item example to process a pre-created image with GD::Simple:

  (this leaves you all the possibilities of GD::Simple)

  Your controller:
  
	sub Text2Image :Local {
		my ( $self, $c) = @_;
		my $img = GD::Simple->new(640, 480); 
		$img->fgcolor('black');
		$img->bgcolor('green'); 
		$img->rectangle(10, 10, 150, 150);
		$img->ellipse(50, 50);
		$img->moveTo(0,25);
		$img->font('Times New Roman');
		$img->fontsize(18);
		$img->string('Image processed by Catalyst::View::Image::Text2Image'); 
		$c->stash->{Text2Image}->{'img'} = $img;
		$c->detach('View::Image::Text2Image');
	}

=back	
	
=head2 Options

The view is controlled by setting the following values in the stash:

=over

=item $c->stash->{Text2Image}->{img}

(optional) Can contain a GD::Image object. If set, the view will not create an image but try to process this object. 
If not set, you need at least to provide x,y,string, font and fontsize.

=item $c->stash->{Text2Image}->{x}

The width (in pixels) of the image.
Mandatory if not $c->stash->{Text2Image}->{img}

=item $c->stash->{Text2Image}->{y}

The height (in pixels) of the image.
Mandatory if not $c->stash->{Text2Image}->{img}

=item $c->stash->{Text2Image}->{string}

The Text of the image.
Only one line supported in this early version.
Mandatory if not $c->stash->{Text2Image}->{img}

=item $c->stash->{Text2Image}->{morph}

(optional) Bool. Should the width of the image be adapted to the width of $c->stash->{Text2Image}->{string}? Note: The option "angle" isn't working with "morph" in this early version. 
Only possible if not $c->stash->{Text2Image}->{img}

=item $c->stash->{Text2Image}->{font}

The font to use for the text.
Mandatory if not $c->stash->{Text2Image}->{img}

=item $c->stash->{Text2Image}->{fontsize}

The font to use for the text.
Mandatory if not $c->stash->{Text2Image}->{img}

=item more...

More GD::Simple Options are just applied by values in the stash.
Tested in this version are: bgcolor, fgcolor, moveTo, turn and angle. 
See example for more informations.

=back

=head2 Image format

The generated images will always be produced in the PNG-Format in this version.

=head1 SEE ALSO

GD::Simple

=head1 AUTHOR

Martin Gillmaier (MG), C<< <gillmaus at cpan.org> >>

=head1 SUPPORT

Critic, requests, commercial support and training for this module is available:
Contact L<gillmaus at cpan.org> for details.

=head1 COPYRIGHT & LICENSE

Copyright (C) 2012 Martin Gillmaier (GILLMAUS).

This module is free software; you
can redistribute it and/or modify it under the same terms
as Perl 5.10.0. For more details, see the full text of the
licenses in the directory LICENSES.

This module is distributed in the hope that it will be
useful, but it is provided "as is" and without any express
or implied warranties. 

=cut

our $VERSION = '0.01';

=head1 METHODS

=head2 process
	
	main method af the view
	
=cut

sub process {
  my ($self, $c) = @_;
  
  # Is there an pre-created image already?
  unless (defined($c->stash->{Text2Image}->{'img'})) {
	  # No? Create one:
	  $c->stash->{'Text2Image'}->{'img'} = $self->text2image($c->stash->{'Text2Image'});
  }
  
  # Set content:
  $c->response->content_type('image/png');
  $c->response->body($c->stash->{'Text2Image'}->{'img'}->png); 
}


=head2 text2image

	Converts a texts into a png-image using GD::Simple;
	
	param: Hash-Ref of GD::Simple options (meaning function=>value), for example: 
			{
				### MUST-values:
				x => 100,
				y => 20, 
				font => 'Times New Roman',
				fontsize => 18,
				string => 'Huhu..its me..your pic!',
				### OPTIONAL Values:
				morph => 1, # optional, will adapt x to string-width 
				### other optional, GD::Simple Values:
				fgcolor => 'black',
				bgcolor => 'green',
				turn => 90,
				moveTo => [0,25]
			}
			
	return: GD image-Object
=cut

sub text2image {
  my ($self, $options) = @_;
  my %opts = %{$options};
  
  # check: 
  return 'x value missing' if $opts{y}<1; # height not negative
  return 'y value missing' if $opts{x}<1; # width not negative
  return 'string value missing' unless $opts{string}<1; # width not negative
  
  # Create image:
  my $img = GD::Simple->new($opts{x}, $opts{y});
   
  # Morph image?
  $img->font($opts{font});
  $img->fontsize($opts{fontsize});
  my $size = $img->stringWidth($opts{'string'});
  if ($size > $opts{y} && $opts{morph}) {
	$img = GD::Simple->new($size, $opts{y});
  }

  # Try to apply all other options:
  eval {
	foreach my $opt (keys %opts) {
	  next if ($opt eq 'x' || $opt eq 'y' || $opt eq 'morph' || $opt eq 'string');
	  if (ref($opts{$opt}) eq 'ARRAY') {
		$img->$opt( @{$opts{$opt}} );
	  } else {
		$img->$opt( $opts{$opt} );
	  }
	}
  };
  return $@ if ($@);
  
  # Now apply string:
  $img->string($opts{string});
  
  #~ die ($img);
  return $img;
}

1; # End of Catalyst::View::Image::Text2Image

