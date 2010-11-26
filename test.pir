
# this is the test program for the forth implementation targeting parrot.
# this script can be passed the names of any number of test files. each test is
# a series of input/output pairs, with optional comments that start with #s.
#
# the first non-blank, non-comment line is considered the first input. the line
# immediately following that is the first output line. the output can be either
# the stack (where the elements are joined by a space) or the message of a
# thrown exception.

.loadlib 'io_ops'

.sub 'main' :main
    .param pmc args
    $S0  = shift args

    load_language 'forth'

    .local pmc it
    it = iter args
  next_file:
    unless it goto done
    $S0 = shift it
    test($S0)
    goto next_file
  done:
    end
.end

#
#   test(filename)
#
# Test a particular filename: read it, parse it, compare the input/output.
#
.sub 'test'
    .param string filename

    .local pmc file
    file = new 'FileHandle'
    file.'open'(filename)

    .local string input, expected
    .local int num_of_tests
    num_of_tests = 0
  next_test:
    input = next_line(file)
    if null input goto done
    if input == "" goto next_test

    expected = next_line(file)
    if null expected goto missing_output

    inc num_of_tests
    is(input, expected, num_of_tests)
    goto next_test

  done:
    print "1.."
    print num_of_tests
    print "\n"
    file.'close'()
    .return()

  missing_output:
    print "Missing test output for test #"
    inc num_of_tests
    print num_of_tests
    print "\n"
    exit 1
.end

.sub 'next_line' :anon
    .param pmc file
    .local string line
  next_line:
    line = file.'readline'()
    if line == '' goto end_of_file
    $S0 = substr line, 0, 1
    if $S0 == "\n" goto next_line
    if $S0 == "\r" goto next_line
    if $S0 == "#"  goto next_line
    line = chomp(line)
    .return (line)
  end_of_file:
    null line
    .return (line)
.end

.sub 'chomp' :anon
    .param string str
    $I0 = index str, "\r"
    if $I0 < 0 goto L1
    str = substr str, 0, $I0
  L1:
    $I1 = index str, "\n"
    if $I1 < 0 goto L2
    str = substr str, 0, $I1
  L2:
    .return (str)
.end

#
#   is(forth code, expected output, test number)
#
# An individual test. Execute the forth code and compare one of the following:
#   1) the first line of stdout
#   2) the stack
#   3) the exception message
#
.sub 'is'
    .param string input
    .param string expected
    .param int    test_num

    .local pmc forth
    forth = compreg 'forth'

    .local pmc interp, stdout
    stdout = getstdout

    .local pmc fh
    fh = new 'StringHandle'
    fh.'open'('dummy', 'wr')
    setstdout fh
    push_eh exception
      $P0   = forth(input)
      .local pmc stack
      stack = $P0()
    pop_eh
    setstdout stdout
    .local string output
    output = fh.'readline'()
    if output != "" goto compare
    output = join " ", stack
    goto compare

  exception:
    .local pmc except
    .get_results (except)
    setstdout stdout
    output = except

  compare:
    if output == expected goto ok
    print "not ok "
    print test_num
    print "\n"

    print "#     Failed test\n"
    print "#          got: '"
    print output
    print "'\n"
    print "#     expected: '"
    print expected
    print "'\n"
    .return()

  ok:
    print "ok "
    print test_num
    print "\n"
    .return()
.end

# Local Variables:
#   mode: pir
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4 ft=pir:
