# encoding: UTF-8

require "spec_helper"

describe Buildbox::Command do
  describe "#run" do
    it "is run within a tty" do
      result = Buildbox::Command.command(%{ruby -e "puts STDOUT.tty?"})

      result.output.should == "true"
    end

    it "successfully runs and returns the output from a simple comment" do
      result = Buildbox::Command.command('echo hello world')

      result.exit_status.should == 0
      result.output.should == "hello world"
    end

    it "redirects stdout to stderr" do
      result = Buildbox::Command.command('echo hello world 1>&2')

      result.exit_status.should == 0
      result.output.should == "hello world"
    end

    it "handles commands that fail and returns the correct status" do
      result = Buildbox::Command.command('(exit 1)')

      result.exit_status.should_not == 0
      result.output.should == ''
    end

    it "handles running malformed commands" do
      result = Buildbox::Command.command('if (')

      result.exit_status.should_not == 0
      # bash 3.2.48 prints "syntax error" in lowercase.
      # freebsd 9.1 /bin/sh prints "Syntax error" with capital S.
      # zsh 5.0.2 prints "parse error" which we do not handle.
      # localized systems will print the message in not English which
      # we do not handle either.
      result.output.should =~ /(syntax|parse) error/i
    end

    it "can collect output in chunks" do
      chunked_output = ''
      result = Buildbox::Command.command('echo hello world') do |chunk|
        unless chunk.nil?
          chunked_output += chunk
        end
      end

      result.exit_status.should == 0
      result.output.should == "hello world"
      chunked_output.should == "hello world\r\n"
    end

    it 'returns a result when running an invalid command in a thread' do
      result = nil
      second_result = nil
      thread = Thread.new do
        result = Buildbox::Command.command('sillycommandlololol')
        second_result = Buildbox::Command.command('export FOO=bar; doesntexist.rb')
      end
      thread.join

      result.exit_status.should_not == 0
      result.output.should =~ /sillycommandlololol.+not found/

      second_result.exit_status.should_not == 0
      # osx: `sh: doesntexist.rb: command not found`
      # ubuntu: `sh: 1: doesntexist.rb: not found`
      second_result.output.should =~ /doesntexist.rb:.+not found/
    end

    it "captures color'd output from a command" do
      chunked_output = ''
      result = Buildbox::Command.command("rspec #{FIXTURES_PATH.join('rspec', 'test_spec.rb')}") do |chunk|
        chunked_output += chunk unless chunk.nil?
      end

      result.exit_status.should == 0
      result.output.should include("32m")
      chunked_output.should include("32m")
    end

    it "runs scripts in a tty" do
      chunked_output = ''
      result = Buildbox::Command.script(FIXTURES_PATH.join('tty_script')) do |chunk|
        chunked_output += chunk unless chunk.nil?
      end

      result.output.should == "true"
      result.exit_status.should == 123
    end

    it "still runs even if pty isn't available" do
      PTY.should_receive(:spawn).and_raise(RuntimeError.new)
      result = Buildbox::Command.command('echo hello world')

      result.exit_status.should == 0
      result.output.should == "hello world"
    end

    it "supports utf8 characters" do
      result = Buildbox::Command.command('echo "hello"; echo "\xE2\x98\xA0"')

      result.exit_status.should == 0
      # just trying to interact with the string that has utf8 in it to make sure that it
      # doesn't blow up like it doesn on osx. this is hacky - need a better test.
      added = result.output + "hello"
    end
  end
end
