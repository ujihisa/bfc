# BFC: Brainf**k Compilers

`bfc.rb` is a compiler written in Ruby, which can compile BF code to Ruby, C, Haskell and LLVM.

## USAGE

    $ ./bfc.rb --help
    $ ./bfc.rb [-v|--version]

    $ ./bfc.rb -r helloworld.bf > helloworld.rb
    $ ./bfc.rb -c helloworld.bf > helloworld.c
    $ ./bfc.rb -h helloworld.bf > helloworld.hs
    $ ./bfc.rb -l helloworld.bf > helloworld.ll

    $ cat helloworld.bf | ./bfc.rb -c | less

    $ ./bfc.rb [-c|-r|-h|-l] helloworld.bf --run
