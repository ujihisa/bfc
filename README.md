# BFC: Brainf**k Compilers

`bfc.rb` is a compiler written in Ruby, which can compile BF code to Ruby, C, and LLVM.

## USAGE

    $ ./bfc.rb [-h|--help]
    $ ./bfc.rb [-v|--version]

    $ ./bfc.rb -r helloworld.bf > helloworld.rb
    $ ./bfc.rb -c helloworld.bf > helloworld.c
    $ ./bfc.rb -l helloworld.bf > helloworld.ll

    $ cat helloworld.bf | ./bfc.rb -c | less

    $ ./bfc.rb [-c|-r|-l] --run helloworld.bf
