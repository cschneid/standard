require "test_helper"

class Standard::FormatterTest < UnitTest
  Offense = Struct.new(:corrected?, :line, :real_column, :message)

  def setup
    @some_path = path("Gemfile")

    @io = StringIO.new
    @subject = Standard::Formatter.new(@io)
  end

  def test_no_offenses_prints_nothing
    @subject.file_finished(@some_path, [])
    @subject.finished([@some_path])

    assert_empty @io.string
  end

  def test_no_uncorrected_offenses_prints_nothing
    @subject.file_finished(@some_path, [Offense.new(true)])
    @subject.finished([@some_path])

    assert_empty @io.string
  end

  def test_prints_uncorrected_offenses
    @subject.file_finished(@some_path, [Offense.new(false, 42, 13, "Neat")])
    @subject.finished([@some_path])

    assert_equal <<-MESSAGE.gsub(/^ {6}/, ""), @io.string
      standard: Use Ruby Standard Style (https://github.com/testdouble/standard)
      standard: Run `standardrb --fix` to automatically fix some problems.
        Gemfile:42:13: Neat

      #{call_to_action_message}
    MESSAGE
  end

  def test_prints_header_only_once
    @subject.file_finished(@some_path, [Offense.new(false, 42, 13, "Neat")])
    @subject.file_finished(@some_path, [Offense.new(false, 43, 14, "Super")])
    @subject.finished([@some_path])

    assert_equal <<-MESSAGE.gsub(/^ {6}/, ""), @io.string
      standard: Use Ruby Standard Style (https://github.com/testdouble/standard)
      standard: Run `standardrb --fix` to automatically fix some problems.
        Gemfile:42:13: Neat
        Gemfile:43:14: Super

      #{call_to_action_message}
    MESSAGE
  end

  def test_prints_rake_message
    og_name = $PROGRAM_NAME
    $PROGRAM_NAME = "/usr/bin/rake"

    @subject.file_finished(@some_path, [Offense.new(false, 42, 13, "Neat")])
    @subject.finished([@some_path])

    assert_equal <<-MESSAGE.gsub(/^ {6}/, ""), @io.string
      standard: Use Ruby Standard Style (https://github.com/testdouble/standard)
      standard: Run `rake standard:fix` to automatically fix some problems.
        Gemfile:42:13: Neat

      #{call_to_action_message}
    MESSAGE

    $PROGRAM_NAME = og_name
  end

  def test_prints_call_for_feedback
    @subject.file_finished(@some_path, [Offense.new(false, 42, 13, "Neat")])
    @subject.file_finished(@some_path, [Offense.new(false, 43, 14, "Super")])
    @subject.finished([@some_path])

    assert_equal <<-MESSAGE.gsub(/^ {6}/, ""), @io.string
      standard: Use Ruby Standard Style (https://github.com/testdouble/standard)
      standard: Run `standardrb --fix` to automatically fix some problems.
        Gemfile:42:13: Neat
        Gemfile:43:14: Super

      #{call_to_action_message}
    MESSAGE
  end

  private

  def call_to_action_message
    Standard::Formatter::CALL_TO_ACTION_MESSAGE.chomp
  end
end
