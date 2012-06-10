require 'test/unit'
require 'ebayr'
require 'ebayr/test_helper'

class TestEbayr < Test::Unit::TestCase
  include Ebayr::TestHelper

  # If this passes without an exception, then we're ok.
  def test_sanity
    t = Time.now.to_s
    stub_ebay_call!(:GeteBayOfficialTime, :Timestamp => t) do
      result = Ebayr.call(:GeteBayOfficialTime)
      assert_equal t, result['Timestamp']
    end
  end

  def test_sandbox_reports_accurately
    Ebayr.sandbox = false
    assert !Ebayr.sandbox?
    Ebayr.sandbox = true
    assert Ebayr.sandbox?
  end

  def test_ebayr_uris
    Ebayr.sandbox = true
    assert_equal "https://api.sandbox.ebay.com/ws", Ebayr.uri_prefix
    assert_equal "https://blah.sandbox.ebay.com/ws", Ebayr.uri_prefix("blah")
    assert_equal "https://api.sandbox.ebay.com/ws/api.dll", Ebayr.uri.to_s
  end

  def test_times_are_converted
    original = {
      :time => Time.now,
      :date => Date.today,
      :string => "Hello"
    }
    converted = Ebayr.process_args(original)
    assert_equal original[:time].utc.iso8601, converted[:time]
    assert_equal original[:date].to_time.utc.iso8601, converted[:date]
  end

  def test_pagination_args_processing
    no_page_given = {}
    page_given = { 'Pagination' => { 'PageNumber' => 5 }} 
    converted_no_page_given = Ebayr.process_args(no_page_given)
    converted_page_given    = Ebayr.process_args(page_given)
    assert_equal converted_no_page_given['Pagination']['PageNumber'], 1
    assert_equal converted_page_given['Pagination']['PageNumber'], 5
  end

  def test_pagination_response
    response = { :HasMoreOrders => true }
    stub_ebay_call!(:GetOrders, response) do
      @result = Ebayr.call(:GetOrders)
    end
      assert_equal @result['Pagination']['PageNumber'], 2
  end
end
