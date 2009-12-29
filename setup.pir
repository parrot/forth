#!/usr/bin/env parrot
# Copyright (C) 2009, Parrot Foundation.

=head1 NAME

setup.pir - Python distutils style

=head1 DESCRIPTION

No Configure step, no Makefile generated.

See <runtime/parrot/library/distutils.pir>.

=head1 USAGE

    $ parrot setup.pir build
    $ parrot setup.pir test
    $ sudo parrot setup.pir install

=cut

.sub 'main' :main
    .param pmc args
    $S0 = shift args
    load_bytecode 'distutils.pbc'

    $P0 = new 'Hash'
    $P0['name'] = 'Forth'
    $P0['abstract'] = 'Forth on Parrot'
    $P0['description'] = 'Forth on Parrot VM'
    $P1 = split ',', 'forth'
    $P0['keywords'] = $P1
    $P0['license_type'] = 'Artistic License 2.0'
    $P0['license_uri'] = 'http://www.perlfoundation.org/artistic_license_2_0'
    $P0['copyright_holder'] = 'Parrot Foundation'
    $P0['checkout_uri'] = 'https://svn.parrot.org/languages/forth/trunk'
    $P0['browser_uri'] = 'https://trac.parrot.org/languages/browser/forth'
    $P0['project_uri'] = 'https://trac.parrot.org/parrot/wiki/Languages'

    # build
    $P2 = new 'Hash'
    $P3 = split "\n", <<'SOURCES'
forth/forth.pir
forth/words.pir
SOURCES
    $S0 = pop $P3
    $P2['forth/forth.pbc'] = $P3
    $P2['forth/library/tokenstream.pbc'] = 'forth/library/tokenstream.pir'
    $P2['forth/library/variablestack.pbc'] = 'forth/library/variablestack.pir'
    $P2['forth/library/virtualstack.pbc'] = 'forth/library/virtualstack.pir'
    $P2['forth.pbc'] = 'forth.pir'
    $P0['pbc_pir'] = $P2

    $P4 = new 'Hash'
    $P4['parrot-forth'] = 'forth.pbc'
    $P0['installable_pbc'] = $P4

    # test
    $S0 = get_parrot()
    $S0 .= ' test.pir'
    $P0['prove_exec'] = $S0

    # install
    $P5 = split "\n", <<'LIBS'
forth/forth.pbc
forth/library/tokenstream.pbc
forth/library/variablestack.pbc
forth/library/virtualstack.pbc
LIBS
    $S0 = pop $P5
    $P0['inst_lang'] = $P5

    # dist
    $P0['manifest_includes'] = 'test.pir'
    $P0['doc_files'] = 'MAINTAINER'

    .tailcall setup(args :flat, $P0 :flat :named)
.end


# Local Variables:
#   mode: pir
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4 ft=pir:
