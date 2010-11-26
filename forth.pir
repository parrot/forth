
.sub 'main' :main
    .param pmc args
    $S0 = shift args

    load_language 'forth'

    .local int argc
    argc = elements args

    if argc == 0 goto prompt
    $S0 = shift args
    compile_file($S0)
    end

  prompt:
    prompt()
    end
.end

.sub 'compile_file'
    .param string filename

    .local string source
    $P0 = new 'FileHandle'
    $P0.'open'(filename)
    source = $P0.'readall'()
    $P0.'close'()

    .local pmc forth
    forth  = compreg 'forth'

    $P0 = forth(source)
    $P0()
.end

.sub 'prompt'
    .local pmc stdin, forth
    stdin  = getstdin
    forth  = compreg 'forth'

    print "Parrot Forth\n"

  loop:
    print "> "
    $S0 = stdin.'readline'()
    unless stdin goto end

    push_eh exception
      $P0 = forth($S0)
      $P0()
    pop_eh

    print " ok\n"
    goto loop
  end:
    .return()

  exception:
    .get_results ($P0)
    $S0 = $P0
    print $S0
    print "\n"
    goto loop
.end

# Local Variables:
#   mode: pir
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4 ft=pir:
