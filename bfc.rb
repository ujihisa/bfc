#!/usr/bin/env ruby
module BFC
  module_function

  def ruby(code)
    h = {
      ',' => 'a[i]=STDIN.getc.ord',
      '.' => 'STDOUT.putc(a[i])',
      '-' => 'a[i]-=1',
      '+' => 'a[i]+=1',
      '<' => 'i-=1',
      '>' => 'i+=1',
      '[' => 'while a[i]!=0',
      ']' => 'end'
    }
    "a=Array.new(1024){0}\ni=0\n" <<
    code.each_char.map {|c| h[c] }.compact.join("\n")
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
    return <<-EOF
    #include<stdio.h>
    #include<stdlib.h>
    int main(int argc, char **argv) {
    int t[1024] = {0};
    int *h = t;
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
    #include<stdio.h>
    #include<stdlib.h>
    int main(int argc, char **argv) {
    int t[1024] = {0};
    int *h = t;
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
    lcs = []
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
        lcs.push lc
        "br label %cond#{lc}\n" <<
        "cond#{lc}:\n" <<
        "%tmp#{a} = load i32* %i, align 4\n" <<
        "%tmp#{b} = getelementptr [1024 x i8]* %h, i32 0, i32 %tmp#{a}\n" <<
        "%tmp#{c} = load i8* %tmp#{b}, align 1\n" <<
        "%tmp#{d} = icmp ne i8 %tmp#{c}, 0\n" <<
        "br i1 %tmp#{d}, label %while#{lc}, label %end#{lc}\n" <<
        "while#{lc}:\n"
      when ']'
        _lc = lcs.pop
        "br label %cond#{_lc}\n" <<
        "end#{_lc}:\n"
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

  def scheme(code)
    h = {
      ',' => '(vector-set! h i (char->integer (read-char)))',
      '.' => '(write-char (integer->char (vector-ref h i)))',
      '-' => '(vector-set! h i (- (vector-ref h i) 1))',
      '+' => '(vector-set! h i (+ (vector-ref h i) 1))',
      '<' => '(set! i (- i 1))',
      '>' => '(set! i (+ i 1))',
      '[' => '(while (not (zero? (vector-ref h i))) (begin',
      ']' => '))'
    }
    return <<-EOF
    (define h (make-vector 1024 0))
    (define i 0)
    #{code.each_char.map {|c| h[c] }.compact.join("\n")}
    EOF
  end
end

case $0
when __FILE__
  require 'tempfile'
  require 'rubygems'
  require 'trollop'
  opts = Trollop.options do
    banner 'Brainf**k Compiler in Ruby'
    version '1.0'
    opt :ruby, 'output ruby'
    opt :c, 'output c'
    opt :llvm, 'output llvm'
    opt :haskell, 'output haskell'
    opt :scheme, 'output scheme'
    opt :run, 'run'
    opt :without_while, 'No while statement in C'
  end
  case
  when opts[:ruby]
    send(opts[:run] ? :eval : :puts, BFC.ruby(ARGF.read))
  when opts[:c]
    c_code = BFC.send(opts[:without_while] ? :c_without_while : :c, ARGF.read)
    if !opts[:run]
      puts c_code
    else
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
      puts BFC.haskell(ARGF.read)
    else
      name = Tempfile.new('bfc').path + '.hs'
      File.open(name, 'w') {|io|
        io.puts BFC.haskell(ARGF.read)
      }
      Dir.chdir(File.dirname(name)) do
        system 'runghc', name
      end
    end
  when opts[:llvm]
    if !opts[:run]
      puts BFC.llvm(ARGF.read)
    else
      name = Tempfile.new('bfc').path + '.ll'
      File.open(name, 'w') {|io|
        io.puts BFC.llvm(ARGF.read)
      }
      Dir.chdir(File.dirname(name)) do
        system 'llvm-as', name
        system 'lli', name.sub(/\.ll$/, '.bc')
      end
    end
  when opts[:scheme]
    code = BFC.scheme ARGF.read
    if opts[:run]
      name = Tempfile.new('bfc').path + '.hs'
      File.open(name, 'w') {|io|
        io.puts code
      }
      Dir.chdir(File.dirname(name)) do
        system 'gosh', name
      end
    else
      puts code
    end
  else
    abort "Specify a language."
  end
else
  require 'tempfile'
  describe 'Hello, World!' do
    before :all do
      @tmp = Tempfile.new('bfcspec').tap(&:close).path
      @hw = 'Hello World!'
    end

    it 'by Ruby' do
      system "#{File.expand_path __FILE__} -r helloworld.bf --run > '#{@tmp}'"
      File.read(@tmp).should == @hw

      system "#{File.expand_path __FILE__} -r helloworld.bf > '#{@tmp}'"
      File.read(@tmp).should_not == ''
      File.read(@tmp).should_not == @hw
    end

    it 'by C' do
      system "#{File.expand_path __FILE__} -c helloworld.bf --run > '#{@tmp}'"
      File.read(@tmp).should == @hw

      system "#{File.expand_path __FILE__} -c helloworld.bf > '#{@tmp}'"
      File.read(@tmp).should_not == ''
      File.read(@tmp).should_not == @hw
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

    it 'by Scheme' do
      system "#{File.expand_path __FILE__} -s helloworld.bf --run > '#{@tmp}'"
      File.read(@tmp).should == @hw
    end
  end
end
