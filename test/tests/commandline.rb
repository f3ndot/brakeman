require 'brakeman/commandline'

class CLExit < StandardError
  attr_reader :exit_code

  def initialize exit_code, message
    super message

    @exit_code = exit_code
  end
end

class TestCommandline < Brakeman::Commandline
  def self.quit exit_code = 0, message = nil
    raise CLExit.new(exit_code, message)
  end
end

class CommandlineTests < Minitest::Test

  # Helper assertions

  def assert_exit exit_code = 0, message = nil
    begin
      yield
    rescue CLExit => e
      assert_equal exit_code, e.exit_code
      assert_equal message, e.message if message
    end
  end

  def assert_stdout message, exit_code = 0
    assert_output message, "" do
      assert_exit exit_code do
        yield
      end
    end
  end

  def assert_stderr message, exit_code = 0
    assert_output "", message do
      assert_exit exit_code do
        yield
      end
    end
  end

  # Helpers

  def cl_with_options *opts
    TestCommandline.start *TestCommandline.parse_options(opts)
  end

  def scan_app *opts
    opts << "#{TEST_PATH}/apps/rails4"
    assert_output do
      cl_with_options *opts 
    end
  end

  # Tests

  def test_nonexistent_scan_path
    assert_exit Brakeman::No_App_Found_Exit_Code do
      cl_with_options "/fake_brakeman_test_path"
    end
  end

  def test_default_scan_path
    options = {}
    
    TestCommandline.set_options options

    assert_equal ".", options[:app_path]
  end

  def test_list_checks
    assert_stderr /\AAvailable Checks:/ do
      cl_with_options "--checks"
    end
  end

  def test_bad_options
    assert_stderr /\Ainvalid option: --not-a-real-option\nPlease see `brakeman --help`/, -1 do
      cl_with_options "--not-a-real-option"
    end
  end

  def test_version
    assert_stdout "brakeman #{Brakeman::Version}\n" do
      cl_with_options "-v"
    end
  end

  def test_empty_config
    empty_config = "--- {}\n"

    assert_stderr empty_config do
      cl_with_options "-C"
    end
  end

  def test_show_help
    assert_stdout /\AUsage: brakeman \[options\] rails\/root\/path/ do
      cl_with_options "--help"
    end
  end

  def test_exit_on_warn
    assert_exit Brakeman::Warnings_Found_Exit_Code do
      scan_app "--exit-on-warn"
    end
  end
end
