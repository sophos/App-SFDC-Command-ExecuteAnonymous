package App::SFDC::Command::ExecuteAnonymous;
# ABSTRACT: Use the apex API to execute anonymous apex code

use strict;
use warnings;

use Log::Log4perl ':easy';
use Data::Dumper;

use Moo;
use MooX::Options;
with 'App::SFDC::Role::Logging',
    'App::SFDC::Role::Credentials';

option 'expression',
    is => 'ro',
    format => 's',
    short => 'E',
    lazy => 1,
    builder => sub {
        my $self = shift;
        local $/;
        if ($self->file) {
            INFO "Reading apex code from ".$self->file;
            open my $FH, '<', $self->file;
            return <$FH>;
        } else {
            INFO "Reading apex code from STDIN";
            return <STDIN>;
        }
    };

option 'file',
    is => 'ro',
    format => 's',
    short => 'f',
    isa => sub {
        LOGDIE "The given file, $_[0], does not exist!" unless -e $_[0];
    };

has '_result',
    is => 'ro',
    lazy => 1,
    builder => sub {
        my $self = shift;
        DEBUG "Expression:\t".$self->expression;
        $self->_session->Apex->executeAnonymous(
            $self->expression,
            debug => 1
        )
    };

=method execute()

Executes the anonymous code against the target sandbox, printing the debug log
to STDOUT and returning truth or falsehood depending on whether the code
executed successfully.

=cut

sub execute {
    my $self = shift;

    print $self->_result->log;
    return $self->_result->success;
}

1;

__END__

=head1 SYNOPSIS

    SFDC executeAnonymous [options] -E "system.debug(1);" > anonymous.log
    SFDC executeAnonymous [options] -f anonymous.apex > anonymous.log
    SFDC executeAnonymous [options] > anonymous.apex > anonymous.log

=head1 DESCRIPTION

executeAnonymous provides a command-line interface to the Salesforce.com
apex API's executeAnonymous function. Diagnostics are printed to STDERR
and any logs are printed to STDOUT.

=head1 PROVIDING APEX CODE

Code can be specified in three ways (as demonstrated in the synopsis), in order
of priority:

In the command invocation using -E;
Read from a file, specified using -f;
Read from STDIN.
