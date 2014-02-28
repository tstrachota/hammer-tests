
#TODO: solve file deletion

class AbstractLogger

  def put_header
  end

  def log_command(command, command_no, result, section_chain)
  end

  def log_section(section_chain)
  end

  def log_test(status, desc, section_chain)
  end
end

class LoggerContainer < AbstractLogger

  def loggers=(loggers)
    @loggers = loggers
  end

  def loggers
    @loggers ||= []
    @loggers
  end

  def put_header
    loggers.each do |logger|
      logger.put_header
    end
  end

  def log_command(*args)
    loggers.each do |logger|
      logger.log_command(*args)
    end
  end

  def log_section(*args)
    loggers.each do |logger|
      logger.log_section(*args)
    end
  end

  def log_test(*args)
    loggers.each do |logger|
      logger.log_test(*args)
    end
  end

end


class FileLogger

  def put_header
  end

  def log_command(command, command_no, result, section_chain)
  end

  def log_section(section_chain)
  end

  def log_test(status, desc, section_chain)
  end

  protected

  def indent_puts(str, indent)
    str.split("\n").each do |line|
      puts indent+line.rstrip
    end
  end

  def target_file_path
    File.expand_path(@target_file)
  end

  def clear_target
    if !@target_file.nil?
      File.open(target_file_path, 'w') do |f|
      end
    end
  end

  def puts(*args)
    if @target_file.nil?
      $stdout.puts *args
    else
      File.open(target_file_path, "a") do |f|
        f.puts(*args)
      end
    end
  end

end


class OutputLogger < FileLogger

  INDENT = "   "

  def initialize(target_file=nil)
    @target_file = target_file
    clear_target
  end

  def log_command(command, command_no, result, section_chain)
    command = command[0, 60] + " ..." if command.length > 64
    indent = INDENT*section_chain.size

    indent_puts(command + colorize("    [command ##{command_no}]", :cyan), indent)
    indent_puts(colorize(result.stderr.rstrip, :blue), indent) unless result.ok?
  end

  def log_section(section_chain)
    indent = INDENT*(section_chain.size-1)
    indent_puts(section_chain[-1], indent)
  end

  def log_test(status, desc, section_chain)
    indent = INDENT*(section_chain.size)
    if status
      indent_puts(colorize("[ OK ] ", :green) + desc, indent)
    else
      indent_puts(colorize("[FAIL] ", :red) + desc, indent)
    end
  end

  protected

  def colorize(str, color)
    if @target_file.nil?
      str.send(color)
    else
      str
    end
  end

end


class LogCropper < FileLogger

  def initialize(log_file, target_file, only_fail=false)
    @log_file = log_file
    @target_file = target_file
    @only_fail = only_fail
    clear_log
    clear_target
  end

  def put_header
    put_line
    put_line "Tests started at: " + Time.now.strftime("%Y/%m/%d %H:%M:%S")
    put_line
  end

  def log_command(command, command_no, result, section_chain)
    return if @only_fail and result.ok?
    puts
    put_command_header(command, command_no, result)
    puts get_log
    puts
    clear_log
  end

  protected

  def put_command_header(command, command_no, result)
    put_line "command ##{command_no}"
    puts command
    puts result.stdout.split("\n")
    put_line
  end

  def put_line(text="")
    text = " #{text} " unless text.empty?
    length = 100 - text.length

    line = "--#{text}" + "-"*length
    puts line % text
  end

  def log_file_path
    File.expand_path(@log_file)
  end

  def get_log
    File.readlines(log_file_path)
  end

  def clear_log
    File.open(log_file_path, 'w') do |f|
    end
  end

end
