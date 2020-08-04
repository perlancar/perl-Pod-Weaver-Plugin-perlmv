package Pod::Weaver::Plugin::perlmv;

# AUTHORITY
# DATE
# DIST
# VERSION

use 5.010001;
use Moose;
with 'Pod::Weaver::Role::AddTextToSection';
with 'Pod::Weaver::Role::Section';

sub _md2pod {
    require Markdown::To::POD;

    my ($self, $md) = @_;
    my $pod = Markdown::To::POD::markdown_to_pod($md);
    # make sure we add a couple of blank lines in the end
    $pod =~ s/\s+\z//s;
    $pod . "\n\n\n";
}

sub _process_module {
    no strict 'refs';

    my ($self, $document, $input, $package) = @_;

    my $filename = $input->{filename};

    # XXX handle dynamically generated module (if there is such thing in the
    # future)
    local @INC = ("lib", @INC);

    {
        my $package_pm = $package;
        $package_pm =~ s!::!/!g;
        $package_pm .= ".pm";
        require $package_pm;
    }

    my $scriptlet = ${"$package\::SCRIPTLET"};

    (my $scriptlet_name = $package) =~ s/\AApp::perlmv::scriptlet:://;
    $scriptlet_name =~ s!::!/!g;
    $scriptlet_name =~ s!_!-!g;

    if (defined $scriptlet->{description}) {
        $self->add_text_to_section(
            $document, $self->_md2pod($scriptlet->{description}), 'DESCRIPTION',
        );
    }

    # XXX don't add if current See Also already mentions it
    my @pod = (
        "L<perlmv> (from L<App::perlmv>)\n\n",
    );
    $self->add_text_to_section(
        $document, join('', @pod), 'SEE ALSO',
        {after_section => ['DESCRIPTION']
     },
    );

    $self->log(["Generated POD for '%s'", $filename]);
}

sub weave_section {
    my ($self, $document, $input) = @_;

    my $filename = $input->{filename};

    return unless $filename =~ m!^lib/(.+)\.pm$!;
    my $package = $1;
    $package =~ s!/!::!g;
    return unless $package =~ /\AApp::perlmv::scriptlet::/;
    $self->_process_module($document, $input, $package);
}

1;
# ABSTRACT: Plugin to use when building App::perlmv and App::perlmv::scriptlet::* distribution

=for Pod::Coverage .*

=head1 SYNOPSIS

In your F<weaver.ini>:

 [-perlmv]


=head1 DESCRIPTION

This plugin is to be used when building L<App::perlmv> and
C<App::perlmv::scriptlet::*> distribution. Currently it does the following for
each F<lib/App/perlmv/scriptlet/*> pm file:

=over

=item * Fill Description section from scriptlet's description

=item * Mention some scripts/modules in the See Also section, including perlmv and App::perlmv

=back


=head1 CONFIGURATION


=head1 SEE ALSO

L<App::perlmv>

L<Dist::Zilla::Plugin::perlmv>
