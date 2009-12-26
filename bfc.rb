#!/usr/bin/env ruby192
require 'rubygems'

module BFC
  module_function

  def ruby(code)
    h = {
      ',' => '(a[i]=STDIN.getc.ord)==255&&exit',
      '.' => 'STDOUT.putc(a[i])',
      '-' => 'a[i]-=1',
      '+' => 'a[i]+=1',
      '<' => 'i-=1',
      '>' => 'i+=1',
      '[' => 'while a[i]!=0',
      ']' => 'end'
    }
    "a=Hash.new(0)\ni=0\n" + code.each_char.map {|c| h[c] }.compact.join("\n")
  end

  def c(code)
    h = {
      ',' => '*h=getchar();',
      '.' => 'putchar(*h);',
      '-' => '--*h;',
      '+' => '++*h;',
      '<' => '--h;',
      '>' => '++h;',
      '[' => 'while(*h){',
      ']' => '}'
    }
    # FIXME: 1024 is not enough
    return <<-EOF
    #include<stdlib.h>
    int main(int argc, char **argv) {
    char *h = (char *)malloc(sizeof(char) * 1024);
    #{code.each_char.map {|c| h[c] }.compact.join("\n")}
    return 0;
    }
    EOF
  end

  def c_without_while(code)
    counter = 0
    body = code.each_char.map {|c|
      case c
      when ','; '*h=getchar();'
      when '.'; 'putchar(*h);'
      when '-'; '--*h;'
      when '+'; '++*h;'
      when '<'; '--h;'
      when '>'; '++h;'
      when '['; "do#{counter += 1}:"
      when ']'
        "if (*h != 0) goto do#{counter}; else goto end#{counter};" <<
        "end#{counter}:"
      end
    }.compact.join("\n")

    return <<-EOF
    #include<stdlib.h>
    int main(int argc, char **argv) {
    char *h = (char *)malloc(sizeof(char) * 1024);
    #{body}
    return 0;
    }
    EOF
  end

  def haskell(code)
    h = {
      ',' => 'tmp <- getChar; h <- return $ update (\_ -> ord tmp) i h;',
      '.' => 'putChar $ chr $ h !! i;',
      '-' => 'h <- return $ update (subtract 1) i h;',
      '+' => 'h <- return $ update (+ 1) i h;',
      '<' => 'i <- return $ i - 1;',
      '>' => 'i <- return $ i + 1;',
      '[' => '(h, i) <- while (\(h, i) -> (h !! i) /= 0) (\(h, i) -> do {',
      ']' => 'return (h, i);}) (h, i);'
    }
    return <<-EOF
import Char
main = do {
  (h, i) <- return $ (repeat 0, 0);
  #{code.each_char.map {|c| h[c] }.compact.join("\n")}
  }

update :: (Int -> Int) -> Int -> [Int] -> [Int]
update op index a = zipWith f a [0..]
  where
    f = (\\e i -> if i == index then op e else e)

while cond action x
  | cond x    = action x >>= while cond action
  | otherwise = return x
    EOF
  end
end

case $0
when __FILE__
  require 'trollop'
  opts = Trollop.options do
    banner 'Brainf**k Compiler in Ruby'
    version '0.1'
    opt :ruby, 'output ruby', :type => String
    opt :c, 'output c', :type => String
    opt :without_while, 'No while statement in C'
    opt :llvm, 'output llvm', :type => String
    opt :haskell, 'output haskell', :type => String
    opt :run, 'run'
  end
  case
  when opts[:ruby]
    if !opts[:run]
      puts BFC.ruby(File.read(opts[:ruby]))
    else
      eval BFC.ruby(File.read(opts[:ruby]))
    end
  when opts[:c]
    c_code =
      if !opts[:without_while]
        BFC.c(File.read(opts[:c]))
      else
        BFC.c_without_while(File.read(opts[:c]))
      end
    if !opts[:run]
      puts c_code
    else
      require 'tempfile'
      name = Tempfile.new('bfc').path + '.c'
      File.open(name, 'w') {|io|
        io.puts c_code
      }
      Dir.chdir(File.dirname(name)) do
        system 'gcc', name
        system './a.out'
      end
    end
  when opts[:haskell]
    if !opts[:run]
      puts BFC.haskell(File.read(opts[:haskell]))
    else
      require 'tempfile'
      name = Tempfile.new('bfc').path + '.hs'
      File.open(name, 'w') {|io|
        io.puts BFC.haskell(File.read(opts[:haskell]))
      }
      Dir.chdir(File.dirname(name)) do
        system 'runghc', name
      end
    end
  when opts[:llvm]
    p 'not yet :('
  else
    p opts
  end
else
  # spec
  p :spec
end
