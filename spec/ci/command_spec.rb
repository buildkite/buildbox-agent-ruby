require "spec_helper"

describe CI::Command do
  let(:logger)  { Logger.new('/dev/null') }
  let(:command) { CI::Command.new(logger) }

  describe "#cd" do
    it "changes the directory of the command" do
      command.cd "~/" do
        result = command.run('pwd')

        result.should be_success
        result.output.should == File.expand_path("~/")
      end
    end
  end

  describe "#run" do
    it "successfully runs and returns the output from a simple comment" do
      result = command.run('echo hello world')

      result.should be_success
      result.output.should == 'hello world'
    end

    it "redirects stdout to stderr" do
      result = command.run('echo hello world 1>&2')

      result.should be_success
      result.output.should == 'hello world'
    end

    it "handles commands that fail and returns the correct status" do
      result = command.run('(exit 1)')

      result.should_not be_success
      result.output.should == ''
    end

    it "handles running malformed commands" do
      result = command.run('if (')

      result.should_not be_success
      # bash 3.2.48 prints "syntax error" in lowercase.
      # freebsd 9.1 /bin/sh prints "Syntax error" with capital S.
      # zsh 5.0.2 prints "parse error" which we do not handle.
      # localized systems will print the message in not English which
      # we do not handle either.
      result.output.should =~ /syntax error/
    end

    it "can collect output in chunks" do
      chunked_output = ''
      result = command.run('echo hello world') do |chunk|
        chunked_output += chunk
      end

      result.should be_success
      result.output.should == 'hello world'
      chunked_output.should == "hello world\n"
    end

    it "can collect chunks at paticular intervals" do
      command = CI::Command.new(logger, 0.1)

      chunked_output = ''
      result = command.run('sleep 0.5; echo hello world') do |chunk|
        chunked_output += chunk
      end

      result.should be_success
      result.output.should == 'hello world'
      chunked_output.should == "hello world\n"
    end

    it "can collect chunks from within a thread" do
      chunked_output = ''
      result = nil
      worker_thread = Thread.new do
        result = command.run('echo before sleep; sleep 1; echo after sleep') do |chunk|
          chunked_output += chunk
        end
      end

      worker_thread.run
      sleep(0.5)
      result.should be_nil
      chunked_output.should == "before sleep\n"

      worker_thread.join

      result.should_not be_nil
      result.should be_success
      result.output.should == "before sleep\nafter sleep"
      chunked_output.should == "before sleep\nafter sleep\n"
    end
  end
end
