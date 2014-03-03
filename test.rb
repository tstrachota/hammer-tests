#! /usr/bin/env ruby

require 'open4'
require 'colorize'
require './loggers.rb'
require './output.rb'
require './utils.rb'



class CommandResult

  def initialize(code = nil, stdout = "", stderr = "")
    @code = code
    @stdout = stdout
    @stderr = stderr
  end

  attr_accessor :code, :stdout, :stderr

  def ok?
    code == 0
  end
end


class Statistics

  def initialize
    @failures = 0
    @successes = 0
  end

  def add_test(result)
    if result
      @successes += 1
    else
      @failures += 1
    end
  end

  def failure_count
    @failures
  end

  def success_count
    @successes
  end

  def total
    @failures + @successes
  end

end


def stats
  @stats ||= Statistics.new
  @stats
end

def logger
  time_prefix = Time.now.strftime("%Y%m%d_%H%M%S").to_s + "_"
  time_prefix = ""

  if @logger.nil?
    @logger = LoggerContainer.new
    @logger.loggers = [
      OutputLogger.new(),
      OutputLogger.new("./log/#{time_prefix}test.log"),
      LogCropper.new('~/.foreman/log/hammer.log', "./log/#{time_prefix}hammer.fail.log", true),
      LogCropper.new('~/.foreman/log/hammer.log', "./log/#{time_prefix}hammer.log"),
      LogCropper.new('~/foreman/log/development.log', "./log/#{time_prefix}foreman.fail.log", true),
      LogCropper.new('~/foreman/log/development.log', "./log/#{time_prefix}foreman.log")
    ]
  end
  @logger
end



def hammer(*args)

  if (args[-1].is_a? Hash)
    options = args.pop
    options.collect do |key, value|
      args << "--#{key.to_s.gsub('_', '-')}"
      args << "#{value}"
    end
  end

  #avoid passing nil values
  args = args.map{|a| a.to_s}

  @command_cnt ||= 0
  @command_cnt += 1

  result = CommandResult.new

  original_args = args.clone
  original_args.unshift("hammer")

  args.unshift(File.join(File.dirname(__FILE__)) + "/hammer")

  logger.log_before_command(original_args.join(" "), @command_cnt, @current_section)

  status = Open4.popen4(*args) do |pid, stdin, stdout, stderr|
    result.stdout = stdout.readlines.join("")
    result.stderr = stderr.readlines.join("")
  end
  result.code = status.exitstatus.to_i

  logger.log_command(original_args.join(" "), @command_cnt, result, @current_section)

  return result
end


def section(name, &block)
  @current_section ||= []
  @current_section << name

  logger.log_section(@current_section)
  yield
  @current_section.pop
end

def test(desc, &block)
  result = yield
  stats.add_test(result)
  logger.log_test(result, desc, @current_section)
end

def simple_test(*args)
  res = hammer *args
  out = ListOutput.new(res.stdout)

  test "returns ok" do
    res.ok?
  end
end

def test_has_columns(out, *column_names)
  column_names.each do |name|
    test "has column #{name}" do
      out.has_column? name
    end
  end
end

def test_column_value(out, column_name, value)
  test "#{column_name} value" do
    out.column(column_name) == value
  end
end

def test_result(res)
  test "returns ok" do
    res.ok?
  end
end


logger.put_header

Dir["#{File.join(File.dirname(__FILE__))}/tests/*.rb"].sort.each do |test|
  #load test
end

load './tests/000_fixtures.rb'
#load './tests/001_base.rb'
load './tests/002_proxy.rb'
#load './tests/009_deletions.rb'
#load './tests/010_listing.rb'

logger.log_statistics(stats)
