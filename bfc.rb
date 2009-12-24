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
end

case $0
when __FILE__
  require 'trollop'
  opts = Trollop.options do
    banner 'Brainf**k Compiler in Ruby'
    version '0.1'
    opt :ruby, 'output ruby', :type => String
    opt :c, 'output c', :type => String
    opt :llvm, 'output llvm', :type => String
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
    if !opts[:run]
      puts BFC.c(File.read(opts[:c]))
    else
      require 'tempfile'
      name = Tempfile.new('bfc').path + '.c'
      File.open(name, 'w') {|io|
        io.puts BFC.c(File.read(opts[:c]))
      }
      Dir.chdir(File.dirname(name)) do
        system 'gcc', name
        system './a.out'
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
