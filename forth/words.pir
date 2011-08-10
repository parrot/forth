
.HLL 'Forth'
.namespace []

.sub 'variable'
    .param pmc code
    .param pmc stream
    .param pmc stack

    .local pmc    token
    .local string name
    token = shift stream
    name  = token

    .local pmc variables, vstack
    variables = get_hll_global ' variables'
    vstack    = get_hll_global ' vstack'

    $P0 = new 'Integer'
    $I0 = vstack
    $P0 = $I0

    variables[name] = $P0
.end

.sub ':'
    .param pmc code
    .param pmc stream
    .param pmc stack

    .local string name, subname
    .local pmc    token, dict, nstack, nword
    token = shift stream
    name  = token
    dict  = get_hll_global ' dict'
    nstack = new 'VirtualStack'
    nword  = new 'StringBuilder'

    subname = ' ' . name
    $P0 = get_root_global ['parrot';'PGE';'Util'], 'unique'
    subname = $P0(subname)
    nword.'append_format'(<<'END_PIR', subname)
.sub '%0'
    .param pmc stack
END_PIR

loop:
    unless stream goto done
    token = shift stream

    $S0 = token
    if $S0 == ";" goto done

    ' dispatch'(nword, stream, nstack, token)
    goto loop

done:
    $S0 = nstack.'consolidate_to_cstack'()
    push nword, $S0
    push nword, <<'END_PIR'
    .return()
.end
END_PIR

    $P0 = compreg "PIR"
    $P0(nword)

    dict[name] = subname
    .return()
.end

# print the last element on the stack (destructive)
.sub '.'
    .param pmc code
    .param pmc stream
    .param pmc stack

    $S0 = pop stack
    code.'append_format'(<<'END_PIR', $S0)
    $P0 = %0
    print $P0
    print " "
END_PIR

    .return()
.end

# print the stack (non-destructive)
.sub '.s'
    .param pmc code
    .param pmc stream
    .param pmc stack

    if stack goto compiletime

    push code, <<'END_PIR'
    print "<"
    $I0 = elements stack
    print $I0
    print "> "

    $S0 = join " ", stack
    print $S0
    print " "
END_PIR
    .return()

compiletime:
    $I0 = elements stack
    $S0 = $I0
    $S1 = join "\nprint ' '\nprint ", stack
    $P0 = get_root_global ['parrot';'PGE';'Util'], 'unique'
    $S2 = $P0('empty')

    code.'append_format'(<<'END_PIR', $S0, $S1, $S2)
    print "<"
    $I0 = elements stack
    $I1 = $I0 + %0
    print $I1
    print "> "

    unless $I0 goto %2
    $S0 = join " ", stack
    print $S0
    print " "
%2:
    print %1
    print " "
END_PIR

    .return()
.end

# clear the stack
.sub '0sp'
    .param pmc code
    .param pmc stream
    .param pmc stack

loop:
    unless stack goto done
    $S0 = pop stack
    goto loop
done:

    $P0 = get_root_global ['parrot';'PGE';'Util'], 'unique'
    $S0 = $P0('loop')
    $S1 = $P0('done')
    code.'append_format'(<<'END_PIR', $S0, $S1)
%0:
    unless stack goto %1
    $S0 = pop stack
    goto %0
%1:
END_PIR
.end

# print what's on the stream upto the next "
.sub '."'
    .param pmc code
    .param pmc stream
    .param pmc stack

    $S0 = stream.'remove_upto'('"')
    $P0 = get_root_global ['parrot';'PGE';'Util'], 'pir_str_escape'
    $S0 = $P0($S0)
    code.'append_format'(<<'END_PIR', $S0)
    print %0
END_PIR

    .return()
.end

# remove the top element
.sub 'drop'
    .param pmc code
    .param pmc stream
    .param pmc stack

    if stack goto compiletime

    push code, <<'END_PIR'
    $P0 = pop stack
END_PIR
    .return()

compiletime:
    $P0 = pop stack
    .return()
.end

# copy the item below the top
.sub 'over'
    .param pmc code
    .param pmc stream
    .param pmc stack

    push code, <<'END_PIR'
    $P0 = stack[-2]
    push stack, $P0
END_PIR

    .return()
.end

# swap the top 2 elements
.sub 'swap'
    .param pmc code
    .param pmc stream
    .param pmc stack

    push code, <<'END_PIR'
    $P0 = pop stack
    $P1 = pop stack
    push stack, $P0
    push stack, $P1
END_PIR

    .return()
.end

# copy the top element
.sub 'dup'
    .param pmc code
    .param pmc stream
    .param pmc stack

    if stack goto compiletime

    push code, <<'END_PIR'
    $P0 = stack[-1]
    push stack, $P0
END_PIR
    .return()

compiletime:
    $I0 = elements stack
    $S0 = stack[-1]
    push stack, $S0
    .return()
.end

# move top - 2 to top
.sub 'rot'
    .param pmc code
    .param pmc stream
    .param pmc stack

    .local string a, b, c
    c = pop stack
    b = pop stack
    a = pop stack

    $P0 = get_root_global ['parrot';'PGE';'Util'], 'unique'
    $S0 = $P0('$P')
    $S1 = $P0('$P')
    $S2 = $P0('$P')

    code.'append_format'(<<'END_PIR', a, b, c, $S0, $S1, $S2)
    %3 = %0
    %4 = %1
    %5 = %2
END_PIR
    push stack, $S1
    push stack, $S2
    push stack, $S0

    .return()
.end

.sub 'begin'
    .param pmc code
    .param pmc stream
    .param pmc stack

    $S0 = stack.'consolidate_to_cstack'()
    push code, $S0

    .local string label
    $P0 = get_root_global ['parrot';'PGE';'Util'], 'unique'
    label = $P0('loop')
    code.'append_format'(<<'END_PIR', label)
%0:
END_PIR

    .local pmc token
next_token:
    unless stream goto error
    token = shift stream

    $S0 = token
    if $S0 == "until" goto until

    ' dispatch'(code, stream, stack, token)

    goto next_token

until:
    $S1 = pop stack
    $P0 = get_root_global ['parrot';'PGE';'Util'], 'unique'
    $S2 = $P0('$P')
    $S0 = stack.'consolidate_to_cstack'()
    push code, $S0
    code.'append_format'(<<'END_PIR', label, $S1, $S2)
    %2 = %1
    unless %2 goto %0
END_PIR

    .return()

error:
    say "error in BEGIN"
    exit 0
.end

.sub 'if'
    .param pmc code
    .param pmc stream
    .param pmc stack

    $S4 = pop stack
    $P0 = get_root_global ['parrot';'PGE';'Util'], 'unique'
    $S1 = $P0('$P')
    $S2 = $P0('else')
    $S3 = $P0('done')

    $S0 = stack.'consolidate_to_cstack'()
    push code, $S0
    code.'append_format'(<<'END_PIR', $S4, $S1, $S2, $S3)
    %1 = %0
    unless %1 goto %2
END_PIR

    .local pmc token
if_loop:
    unless stream goto error
    token = shift stream

    $S0 = token
    if $S0 == "else" goto else
    if $S0 == "then" goto done
    ' dispatch'(code, stream, stack, token)

    goto if_loop

else:
    $S0 = stack.'consolidate_to_cstack'()
    push code, $S0
    code.'append_format'(<<'END_PIR', $S2, $S3)
    goto %1
%0:
END_PIR

else_loop:
    unless stream goto error
    token = shift stream

    $S0 = token
    if $S0 == "then" goto done
    ' dispatch'(code, stream, stack, token)

    goto else_loop

if_done:
    code.'append_format'(<<'END_PIR', $S2)
%0:
END_PIR
done:
    code.'append_format'(<<'END_PIR', $S3)
%0:
END_PIR
    $S0 = stack.'consolidate_to_cstack'()
    push code, $S0
    .return()

error:
    print "error in IF!"
    exit 0
.end

# print a carriage-return
.sub 'cr'
    .param pmc code
    .param pmc stream
    .param pmc stack

    push code, <<'END_PIR'
    print "\n"
END_PIR

    .return()
.end

# is less than 0?
.sub '0<'
    .param pmc code
    .param pmc stream
    .param pmc stack

    .local string a
    a   = pop stack
    $P0 = get_root_global ['parrot';'PGE';'Util'], 'unique'
    $S0 = $P0('$P')

    code.'append_format'(<<'END_PIR', a, $S0)
    $I0 = %0
    $I0 = islt $I0, 0
    %1  = new 'Integer'
    %1  = $I0
END_PIR
    push stack, $S0

    .return()
.end

# addition
.sub '+'
    .param pmc code
    .param pmc stream
    .param pmc stack

    .local string a, b
    b = pop stack
    a = pop stack
    $P0 = get_root_global ['parrot';'PGE';'Util'], 'unique'
    $S0 = $P0('$P')
    $S1 = $P0('$P')
    $S2 = $P0('$P')

    code.'append_format'(<<'END_PIR', b, a, $S0, $S1, $S2)
    %2 = %0
    %3 = %1
    %4 = new 'Float'
    %4 = %3 + %2
END_PIR
    push stack, $S2

    .return()
.end

# subtraction
.sub '-'
    .param pmc code
    .param pmc stream
    .param pmc stack

    .local string a, b
    b = pop stack
    a = pop stack
    $P0 = get_root_global ['parrot';'PGE';'Util'], 'unique'
    $S0 = $P0('$P')
    $S1 = $P0('$P')
    $S2 = $P0('$P')

    code.'append_format'(<<'END_PIR', b, a, $S0, $S1, $S2)
    %2 = %0
    %3 = %1
    %4 = new 'Float'
    %4 = %3 - %2
END_PIR
    push stack, $S2

    .return()
.end

# multiplication
.sub '*'
    .param pmc code
    .param pmc stream
    .param pmc stack

    .local string a, b
    b = pop stack
    a = pop stack
    $P0 = get_root_global ['parrot';'PGE';'Util'], 'unique'
    $S0 = $P0('$P')
    $S1 = $P0('$P')
    $S2 = $P0('$P')

    code.'append_format'(<<'END_PIR', b, a, $S0, $S1, $S2)
    %2 = %0
    %3 = %1
    %4 = new 'Float'
    %4 = %3 * %2
END_PIR
    push stack, $S2

    .return()
.end

# Local Variables:
#   mode: pir
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4 ft=pir:
