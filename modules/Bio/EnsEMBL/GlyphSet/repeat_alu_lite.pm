package Bio::EnsEMBL::GlyphSet::repeat_alu_lite;
use strict;
use vars qw(@ISA);
use Bio::EnsEMBL::GlyphSet_simple_hash;

@ISA = qw( Bio::EnsEMBL::GlyphSet_simple_hash );

sub my_label { return "Repeats (Alu)"; }

sub features {
    my $self = shift;
    
    my $max_length = $self->{'config'}->get( 'repeat_alu_lite', 'threshold' ) || 2000;
    return @{$self->{'container'}->get_all_RepeatFeatures_lite( 'Alu', $self->glob_bp() )};
}

sub zmenu {
    my( $self, $f ) = @_;
    return {
        'caption' 											=> $f->{'hid'},
		"bp: $f->{'chr_start'}-$f->{'chr_end'}" 			=> '',
		"length: ".($f->{'chr_end'}-$f->{'chr_start'}+1) 	=> ''
    }
}

1;
