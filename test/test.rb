require "test/unit"
require "cloudstack_ruby_client"
require_relative "../lib/cloudconfig/resources"
require_relative "helper/test_helper"



class TestResources < Test::Unit::TestCase

  def setup
    @res = [Cloudconfig::Resources.new("serviceofferings"),
            Cloudconfig::Resources.new("hosts"),
            Cloudconfig::Resources.new("storages"),
            Cloudconfig::Resources.new("diskofferings")]

    for r in @res
      r.delete = false
      r.dryrun = true
    end

    @r_test_file = TestHelper.new().get_resource_file()
    @r_test_cloud = TestHelper.new().get_resource_cloud()
  end

  def test_update_serviceofferings_delete_is_false
    # Test array and hash in test_helper.rb, with delete option set to false in setup
    upd, cre, del = @res[0].check_resource(@r_test_file, @r_test_cloud)
    assert_equal(1, upd.length)
    assert_equal("Resource-02", "#{upd[0][0]["name"]}")
    assert_equal(1, cre.length)
    assert_equal("Resource-04", "#{cre[0]["name"]}")
    assert_equal(0, del.length)
  end

  # Same test, with delete set to true
  def test_update_serviceofferings_delete_is_true
    @res[0].delete = true
    upd, cre, del = @res[0].check_resource(@r_test_file, @r_test_cloud)
    assert_equal(1, upd.length)
    assert_equal("Resource-02", "#{upd[0][0]["name"]}")
    assert_equal(1, cre.length)
    assert_equal("Resource-04", "#{cre[0]["name"]}")
    assert_equal(1, del.length)
    assert_equal("Resource-03", "#{del[0]["name"]}")
  end

  def test_update_hosts_delete_is_false
    # Test array and hash in test_helper.rb, with delete option set to false in setup
    upd, cre, del = @res[1].check_resource(@r_test_file, @r_test_cloud)
    assert_equal(1, upd.length)
    assert_equal("Resource-02", "#{upd[0][0]["name"]}")
    assert_equal(0, cre.length)
    assert_equal(0, del.length)
  end

  # Same test, with delete set to true
  def test_update_hosts_delete_is_true
    @res[1].delete = true
    upd, cre, del = @res[1].check_resource(@r_test_file, @r_test_cloud)
    assert_equal(1, upd.length)
    assert_equal("Resource-02", "#{upd[0][0]["name"]}")
    assert_equal(0, cre.length)
    assert_equal(0, del.length)
  end

  def test_update_storages_delete_is_false
    # Test array and hash in test_helper.rb, with delete option set to false in setup
    upd, cre, del = @res[2].check_resource(@r_test_file, @r_test_cloud)
    assert_equal(1, upd.length)
    assert_equal("Resource-02", "#{upd[0][0]["name"]}")
    assert_equal(0, cre.length)
    assert_equal(0, del.length)
  end

  # Same test, with delete set to true
  def test_update_storages_delete_is_true
    @res[2].delete = true
    upd, cre, del = @res[2].check_resource(@r_test_file, @r_test_cloud)
    assert_equal(1, upd.length)
    assert_equal("Resource-02", "#{upd[0][0]["name"]}")
    assert_equal(0, cre.length)
    assert_equal(0, del.length)
  end

  def test_update_diskofferings_delete_is_false
    # Test array and hash in test_helper.rb, with delete option set to false in setup
    upd, cre, del = @res[3].check_resource(@r_test_file, @r_test_cloud)
    assert_equal(1, upd.length)
    assert_equal("Resource-02", "#{upd[0][0]["name"]}")
    assert_equal(0, cre.length)
    assert_equal(0, del.length)
  end

  # Same test, with delete set to true
  def test_update_diskofferings_delete_is_true
    @res[3].delete = true
    upd, cre, del = @res[3].check_resource(@r_test_file, @r_test_cloud)
    assert_equal(1, upd.length)
    assert_equal("Resource-02", "#{upd[0][0]["name"]}")
    assert_equal(0, cre.length)
    assert_equal(0, del.length)
  end

end
