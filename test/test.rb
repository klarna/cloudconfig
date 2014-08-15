require "test/unit"
require "cloudstack_ruby_client"
require_relative "../lib/cloudconfig/resources"
require_relative "helper/test_helper"



class TestResources < Test::Unit::TestCase

  def setup
    @res = [Cloudconfig::Resources.new("serviceofferings"),
            Cloudconfig::Resources.new("hosts"),
            Cloudconfig::Resources.new("storages"),
            Cloudconfig::Resources.new("diskofferings"),
            Cloudconfig::Resources.new("systemofferings")]

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
    assert_equal(1, cre.length)
    assert_equal("Resource-04", "#{cre[0]["name"]}")
    assert_equal(0, del.length)
    resource = @res[0]
    control_updates(upd, resource)
  end

  # Same test, with delete set to true
  def test_update_serviceofferings_delete_is_true
    @res[0].delete = true
    upd, cre, del = @res[0].check_resource(@r_test_file, @r_test_cloud)
    assert_equal(1, cre.length)
    assert_equal("Resource-04", "#{cre[0]["name"]}")
    assert_equal(1, del.length)
    assert_equal("Resource-03", "#{del[0]["name"]}")
    resource = @res[0]
    control_updates(upd, resource)
  end

  def test_update_systemofferings_delete_is_false
    upd, cre, del = @res[4].check_resource(@r_test_file, @r_test_cloud)
    assert_equal(1, cre.length)
    assert_equal("Resource-04", "#{cre[0]["name"]}")
    assert_equal(0, del.length)
    resource = @res[4]
    control_updates(upd, resource)
  end

  def test_update_systemofferings_delete_is_true
    @res[4].delete = true
    upd, cre, del = @res[4].check_resource(@r_test_file, @r_test_cloud)
    assert_equal(1, cre.length)
    assert_equal("Resource-04", "#{cre[0]["name"]}")
    assert_equal(1, del.length)
    assert_equal("Resource-03", "#{del[0]["name"]}")
    resource = @res[4]
    control_updates(upd, resource)
  end

  def test_update_hosts_delete_is_false
    upd, cre, del = @res[1].check_resource(@r_test_file, @r_test_cloud)
    assert_equal(0, cre.length)
    assert_equal(0, del.length)
    resource = @res[1]
    control_updates(upd, resource)
  end

  def test_update_hosts_delete_is_true
    @res[1].delete = true
    upd, cre, del = @res[1].check_resource(@r_test_file, @r_test_cloud)
    assert_equal(0, cre.length)
    assert_equal(0, del.length)
    resource = @res[1]
    control_updates(upd, resource)
  end

  def test_update_storages_delete_is_false
    upd, cre, del = @res[2].check_resource(@r_test_file, @r_test_cloud)
    assert_equal(0, cre.length)
    assert_equal(0, del.length)
    resource = @res[2]
    control_updates(upd, resource)
  end

  def test_update_storages_delete_is_true
    @res[2].delete = true
    upd, cre, del = @res[2].check_resource(@r_test_file, @r_test_cloud)
    assert_equal(0, cre.length)
    assert_equal(0, del.length)
    resource = @res[2]
    control_updates(upd, resource)
  end

  def test_update_diskofferings_delete_is_false
    upd, cre, del = @res[3].check_resource(@r_test_file, @r_test_cloud)
    assert_equal(1, cre.length)
    assert_equal("Resource-04", "#{cre[0]["name"]}") 
    assert_equal(0, del.length)
    resource = @res[3]
    control_updates(upd, resource)
  end

  def test_update_diskofferings_delete_is_true
    @res[3].delete = true
    upd, cre, del = @res[3].check_resource(@r_test_file, @r_test_cloud)
    assert_equal(1, cre.length)
    assert_equal("Resource-04", "#{cre[0]["name"]}")
    assert_equal(1, del.length)
    assert_equal("Resource-03", "#{del[0]["name"]}")
    resource = @res[3]
    control_updates(upd, resource)
  end

  def control_updates(updated_resources, resource)
    assert_equal(2, updated_resources.length, "Two resources should be checked for updation")
    updated_resources.each { |r| assert(["Resource-01", "Resource-02"].include?(r[0]["name"])) }
    recreatable = false
    # if resource is serviceofferings, diskofferings or systemofferings
    if (resource == @res[0]) || (resource == @res[3]) || (resource == @res[4])
      recreatable = true
    end
    for updated in updated_resources
      r, only_updated = resource.update_resource(updated)
      assert(!r.empty?, "A call to the update_resource method did not return an updated #{resource}")
      if recreatable
        if r[0] == "Resource-01"
          assert(only_updated, "#{r[0]} should only be updated")
        elsif r[0] == "Resource-02"
          assert(!only_updated, "#{r[0]} should be recreated")
        else
          assert(false, "#{r[0]} should not be updated")
        end
      else
        assert(only_updated, "#{resource} should only be updated")
      end
    end
  end

  end

end
