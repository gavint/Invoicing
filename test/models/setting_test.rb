require "test_helper"

class SettingTest < ActiveSupport::TestCase
  test "instance always returns the same singleton record" do
    first = Setting.instance
    second = Setting.instance
    assert_equal first.id, second.id
  end
end
