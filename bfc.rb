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

  def llvm(code)
    lc, tc = 0, 0 # label counter and tmp counter
    body = code.each_char.map {|char|
      case char
      when ','
        a = tc += 1; b = tc += 1; c = tc += 1
        "%tmp#{a} = load i32* %i, align 4\n" <<
        "%tmp#{b} = getelementptr [1024 x i8]* %h, i32 0, i32 %tmp#{a}\n" <<
        "%tmp#{c} = call i8 @getchar()\n" <<
        "store i8 %tmp#{c}, i8* %tmp#{b}, align 1\n"
      when '.'
        a = tc += 1; b = tc += 1; c = tc += 1
        "%tmp#{a} = load i32* %i, align 4\n" <<
        "%tmp#{b} = getelementptr [1024 x i8]* %h, i32 0, i32 %tmp#{a}\n" <<
        "%tmp#{c} = load i8* %tmp#{b}, align 1\n" <<
        "call i32 @putchar(i8 %tmp#{c})\n"
      when '-'
        a = tc += 1; b = tc += 1; c = tc += 1; d = tc += 1
        "%tmp#{a} = load i32* %i, align 4\n" <<
        "%tmp#{b} = getelementptr [1024 x i8]* %h, i32 0, i32 %tmp#{a}\n" <<
        "%tmp#{c} = load i8* %tmp#{b}, align 1\n" <<
        "%tmp#{d} = sub i8 %tmp#{c}, 1\n" <<
        "store i8 %tmp#{d}, i8* %tmp#{b}, align 1\n"
      when '+'
        a = tc += 1; b = tc += 1; c = tc += 1; d = tc += 1
        "%tmp#{a} = load i32* %i, align 4\n" <<
        "%tmp#{b} = getelementptr [1024 x i8]* %h, i32 0, i32 %tmp#{a}\n" <<
        "%tmp#{c} = load i8* %tmp#{b}, align 1\n" <<
        "%tmp#{d} = add i8 1, %tmp#{c}\n" <<
        "store i8 %tmp#{d}, i8* %tmp#{b}, align 1\n"
      when '<'
        a = tc += 1; b = tc += 1
        "%tmp#{a} = load i32* %i, align 4\n" <<
        "%tmp#{b} = sub i32 %tmp#{a}, 1\n" <<
        "store i32 %tmp#{b}, i32* %i, align 4\n"
      when '>'
        a = tc += 1; b = tc += 1
        "%tmp#{a} = load i32* %i, align 4\n" <<
        "%tmp#{b} = add i32 1, %tmp#{a}\n" <<
        "store i32 %tmp#{b}, i32* %i, align 4\n"
      when '['
        a = tc += 1; b = tc += 1; c = tc += 1; d = tc += 1
        lc += 1
        "br label %cond#{lc}\n" <<
        "cond#{lc}:\n" <<
        "%tmp#{a} = load i32* %i, align 4\n" <<
        "%tmp#{b} = getelementptr [1024 x i8]* %h, i32 0, i32 %tmp#{a}\n" <<
        "%tmp#{c} = load i8* %tmp#{b}, align 1\n" <<
        "%tmp#{d} = icmp ne i8 %tmp#{c}, 0\n" <<
        "br i1 %tmp#{d}, label %while#{lc}, label %end#{lc}\n" <<
        "while#{lc}:\n"
      when ']'
        "br label %cond#{lc}\n" <<
        "end#{lc}:\n"
      end
    }.compact.join("\n")
    initialize_h = (0...1024).map {|i|
      "%initialize#{i} = getelementptr [1024 x i8]* %h, i32 0, i32 #{i}\n" <<
      "store i8 0, i8* %initialize#{i}, align 1"
    }.join("\n")
    return <<-EOF
define void @main() nounwind {
init:
  %h = alloca [1024 x i8]
  %i = alloca i32
  store i32 0, i32* %i, align 4
  ;initialize %h
  #{initialize_h}
  ;body
  #{body}
  ret void
}
declare i32 @putchar(i8) nounwind
declare i8 @getchar() nounwind

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
    if !opts[:run]
      puts BFC.llvm(File.read(opts[:llvm]))
    else
      require 'tempfile'
      name = Tempfile.new('bfc').path + '.ll'
      File.open(name, 'w') {|io|
        io.puts BFC.llvm(File.read(opts[:llvm]))
      }
      Dir.chdir(File.dirname(name)) do
        system 'llvm-as', name
        system 'lli', name.sub(/\.ll$/, '.bc')
      end
    end
  else
    p opts
  end
else
  describe 'Hello, World!' do
    require 'tempfile'
    before :all do
      @tmp = Tempfile.new('bfcspec').tap(&:close).path
      @hw = 'Hello World!'
    end

    it 'by Ruby' do
      system "#{File.expand_path __FILE__} -r helloworld.bf --run > '#{@tmp}'"
      File.read(@tmp).should == @hw
    end

    it 'by C' do
      system "#{File.expand_path __FILE__} -c helloworld.bf --run > '#{@tmp}'"
      File.read(@tmp).should == @hw
    end

    it 'by C without while statements' do
      system "#{File.expand_path __FILE__} -c helloworld.bf -w --run > '#{@tmp}'"
      File.read(@tmp).should == @hw
    end

    it 'by Haskell' do
      system "#{File.expand_path __FILE__} -h helloworld.bf --run > '#{@tmp}'"
      File.read(@tmp).should == @hw
    end

    it 'by LLVM' do
      system "#{File.expand_path __FILE__} -l helloworld.bf --run > '#{@tmp}'"
      File.read(@tmp).should == @hw
    end
  end
end
