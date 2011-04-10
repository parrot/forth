
.HLL 'Forth'
.namespace []

.include 'forth/words.pir'

.sub '' :load
    # load the libraries we depend on
    load_bytecode 'tokenstream.pbc'
    load_bytecode 'variablestack.pbc'
    load_bytecode 'virtualstack.pbc'
    load_bytecode 'PGE.pbc'

    # initialize the rstack
    .local pmc stack
    stack = new 'ResizablePMCArray'
    set_hll_global ' stack', stack

    # word dictionary - used for compilation
    .local pmc dict
    dict = new 'Hash'
    set_hll_global ' dict', dict

    .local pmc vars, vstack
    vars   = new 'Hash'
    vstack = new 'VariableStack'
    set_hll_global ' variables', vars
    set_hll_global ' vstack', vstack

    # register the actual compiler
    .local pmc compiler
    compiler = get_hll_global ' compile'
    compreg 'forth', compiler
.end

.sub ' compile'
    .param string input

    .local pmc code, stream, stack
    code   = new 'StringBuilder'
    stream = new 'TokenStream'
    set stream, input
    stack  = new 'VirtualStack'

    push code, <<'END_PIR'
.sub code :anon
    .local pmc stack
    stack = get_hll_global " stack"
END_PIR

    .local pmc token
next_token:
    unless stream goto done
    token = shift stream

    ' dispatch'(code, stream, stack, token)

    goto next_token

done:
    $S0 = stack.'consolidate_to_cstack'()
    push code, $S0
    push code, <<'END_PIR'
    .return(stack)
.end
END_PIR

    $P0 = compreg "PIR"

    # Workaround for -tailcall problem after imcc_compreg_pmc merge
    #.tailcall $P0(code)
    $P99 = $P0(code)
    .return($P99)
.end

.sub ' dispatch'
    .param pmc code
    .param pmc stream
    .param pmc stack
    .param pmc token

    $I0 = isa token, 'Integer'
    if $I0 goto numeric

    .local pmc dict, vars
    dict = get_hll_global ' dict'
    vars = get_hll_global ' variables'

    $S0 = token
    $I0 = exists dict[$S0]
    if $I0 goto user_word
    $I0 = exists vars[$S0]
    if $I0 goto user_var

    $P0 = get_hll_global $S0
    if null $P0 goto undefined
    $P0(code, stream, stack)
    .return()

user_word:
    $S1 = stack.'consolidate_to_cstack'()
    push code, $S1
    $S0 = dict[$S0]
    code.'append_format'(<<'END_PIR', $S0)
    '%0'(stack)
END_PIR
    .return()

user_var:
    $I0 = vars[$S0]
    $P0 = get_root_global ['parrot';'PGE';'Util'], 'unique'
    $S0 = $P0('$P')
    code.'append_format'(<<'END_PIR', $S0, $I0)
    %0 = new 'Integer'
    %0 = %1
END_PIR
    push stack, $S0
    .return()

undefined:
    $S0 = token
    $S0 = "undefined symbol: " . $S0
    $P0 = new 'Exception'
    $P0['message'] = $S0
    throw $P0

numeric:
    $P0 = get_root_global ['parrot';'PGE';'Util'], 'unique'
    $S0 = $P0('$P')
    code.'append_format'(<<'END_PIR', $S0, token)
    %0 = new 'Integer'
    %0 = %1
END_PIR
    push stack, $S0
    .return()
.end

# Local Variables:
#   mode: pir
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4 ft=pir:
