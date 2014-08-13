require 'yaml'
require 'json'
require 'net/http'
require 'cloudstack_ruby_client'
require 'user_config'

module Cloudconfig
  class Resources


    attr_accessor :config, :delete, :dryrun, :resource, :client, :config_file


    def initialize(resource)
      @delete = false
      @dryrun = false
      @resource = resource
      uconfig = UserConfig.new('.cloudconfig')
      @config_file = uconfig['config.yaml']
    end


    def update()
      @client = create_cloudstack_client()
      begin
        resource_file, resource_cloud = define_yamlfile_and_cloudresource()
      rescue Exception => error_msg
        raise error_msg, "Resource could not be loaded from configuration file and/or the cloud."
      end
      r_updated, r_created, r_deleted = check_resource(resource_file, resource_cloud)
      if @dryrun
        puts "The following actions would be performed with this command:"
      end
      for updated in r_updated
        begin
          updated_resource, only_updated = update_resource(updated)
          if !updated_resource.empty?
            if only_updated
              puts "Some values have been changed in the #{@resource} named #{updated_resource[0]}.\nOld values were:\n#{JSON.pretty_generate(updated_resource[1])}\nNew values are:\n#{JSON.pretty_generate(updated_resource[2])}"
            else
              puts "The #{@resource} named #{updated_resource[0]} has been recreated.\nOld values were:\n#{JSON.pretty_generate(updated_resource[1])}\nNew values are:\n#{JSON.pretty_generate(updated_resource[2])}"
            end
          end
        rescue Exception => error_msg
          puts "#{updated[0]["name"]} could not be updated since: #{error_msg}"
        end
      end
      for created in r_created
        begin
          created_resource = create_resource(created)
          if !created_resource.empty?
            puts "The #{@resource} named #{created_resource[0]} has been created"
          end
        rescue Exception => error_msg
          puts "#{created["name"]} could not be created since: #{error_msg}"
        end
      end
      for deleted in r_deleted
        deleted_resource = delete_resource(deleted)
        if !deleted_resource.empty?
          puts "The #{@resource} named #{deleted_resource[0]} has been deleted"
        end
      end
    end


    def create_cloudstack_client()
      client = CloudstackRubyClient::Client.new(@config_file["url"], @config_file["api_key"], @config_file["secret_key"], true)
      return client
    end


    # Save the current list of resources in resource_cloud, and the ones in the yaml file in resource_file
    def define_yamlfile_and_cloudresource()
      if @resource == "serviceofferings"
        resource_title = "ServiceOfferings"
        resource_cloud = @client.list_service_offerings()["serviceoffering"]
      elsif @resource == "hosts"
        resource_title = "Hosts"
        resource_cloud = @client.list_hosts()["host"]
      elsif @resource == "storages"
        resource_title = "Storages"
        resource_cloud = @client.list_storage_pools()["storagepool"]
      elsif @resource == "diskofferings"
        resource_title = "DiskOfferings"
        resource_cloud = @client.list_disk_offerings()["diskoffering"]
      elsif @resource == "systemofferings"
        resource_title = "SystemOfferings"
        resource_cloud = @client.list_service_offerings({"issystem" => true})["serviceoffering"]
      end
      resource_file = YAML.load_file("#{@config_file["resource_directory"]}/#{@resource}.yaml")["#{resource_title}"]
      return resource_file, resource_cloud
    end


    # Compare resources in cloud and yaml file
    def check_resource(resource_file, resource_cloud)
      updated = Array.new
      created = Array.new
      deleted = Array.new
      for r in resource_file
        r_total = r[1].merge({"name" => "#{r[0]}"})
        found = false
        i = 0
        # If the resource has not yet been found, compare names and update resource if names match but other parameters don't
        while !found && i < resource_cloud.length
          if resource_cloud[i]["name"] == r[0]
            new_resource = resource_cloud[i].merge(r[1])
            if resource_cloud[i] != new_resource
              r_total = r_total.merge({"id" => "#{resource_cloud[i]["id"]}"})
              # Update resource with new values, in first parameter, and send old values in second parameter
              updated.push([r_total, resource_cloud[i]])
            end
            resource_cloud.delete_at(i)
            found = true
          else
            i += 1
          end
        end
        if (!found) && ((@resource == "serviceofferings") || (@resource == "diskofferings") || (@resource == "systemofferings"))
          # Create resources
          created.push(r_total)
        end
      end
      if delete && (resource_cloud.length > 0) && ((@resource == "serviceofferings") || (@resource == "diskofferings") || (@resource == "systemofferings"))
        # Remove all resources that are not included in yaml file. (Only works for service offerings at the moment)
        for r in resource_cloud
          deleted.push(r)
        end
      end
      # Return resources that should be updated, created and deleted
      return updated, created, deleted
    end


    def update_resource(res)
      updated = true
      updated_resource = Array.new
      res_diff = Hash[(res[0].to_a) - (res[1].to_a)]
      res_union = Hash[res[1].to_a | res[0].to_a]
      # If the parameters that differs only contain the following keys, then the resource only needs an update. Otherwise, a recreation is required.
      changes = res_diff.clone
      only_update_parameters = ["displaytext", "sortkey", "displayoffering"]
      only_update_parameters.each { |searched_param| changes.delete_if { |actual_param| actual_param == searched_param } }
      for param, value in changes
        if (!res[1].has_key?(param) || (res[1][param] == "")) && (value == "")
          changes.delete(param)
          res_diff.delete(param)
        end
      end
      if !res_diff.empty?
        # All these resources could need recreation and are controlled, to see if all nedded requirements are met.
        if (@resource == "serviceofferings") || (@resource == "systemofferings") || (@resource == "diskofferings")
          if !changes.empty?
            # Recreation is needed
            updated = false
            actual_dryrun = @dryrun
            @dryrun = true
            created = create_resource(res_union)
            if !created.empty?
              @dryrun = actual_dryrun
              deleted = delete_resource(res_union)
              created = create_resource(res_union)
              updated_resource.push(res[0]["name"], res[1], res_diff)
            end
            @dryrun = actual_dryrun
          else
            # Only an update is nedded
            if (@resource == "serviceofferings") || (@resource == "systemofferings")
              if !@dryrun
                @client.update_service_offering(res_union)
              end
            elsif @resource == "diskofferings"
              if !@dryrun
                @client.update_disk_offering(res_union)
              end
            else
              updated = false
            end
          end
          # All these resources can only be updated.
        elsif (@resource == "hosts") || (@resource == "storages")
          if @resource == "hosts"
            if !@dryrun
              @client.update_host(res_union)
            end
          elsif @resource == "storages"
            if !@dryrun
              @client.update_storage_pool(res_union)
            end
          else
            updated = false
          end
        end
      else
        updated = false
      end
      if updated
        updated_resource.push(res[0]["name"], res[1], res_diff)
      end
      return updated_resource, updated
    end


    def create_resource(res)
      check_for_creation_errors(res)
      created = Array.new
      created.push(res["name"])
      if (@resource == "serviceofferings") || (@resource == "systemofferings")
        if @resource == "systemofferings"
          res["issystem"] = true
        end
        if !@dryrun
          @client.create_service_offering(res)
        end
      elsif (@resource == "diskofferings")
        # Parameter iscustomized has different name (customized) when creating resource, and parameter disksize create error if iscustomized is true.
        if res.has_key?("iscustomized") && res["iscustomized"] == true
          res.delete("disksize")
        end
        res = res.merge({"customized" => res["iscustomized"]})
        res.delete("iscustomized")
        if !@dryrun
          @client.create_disk_offering(res)
        end
      end
      created
    end


    def delete_resource(res)
      deleted = Array.new
      if (@resource == "serviceofferings") || (@resource == "systemofferings")
        deleted.push(res["name"])
        if !@dryrun
          @client.delete_service_offering({"id" => "#{res["id"]}"})
        end
      elsif (@resource == "diskofferings")
        deleted.push(res["name"])
        if !@dryrun
          @client.delete_disk_offering({"id" => "#{res["id"]}"})
        end
      end
      deleted
    end


    def check_for_creation_errors(res)
      errors = Array.new
      if !res.has_key?("displaytext")
        errors.push("'displaytext' has not been specified in configuration file.")
      end
      if @resource == "diskofferings"
        if (!res.has_key?("iscustomized") || (res["iscustomized"] == false)) && (!res.has_key?("disksize") || (res["disksize"] == 0))
          errors.push("'iscustomized' is unspecified or set to false and 'disksize' has not been specified, or has been specified to a value of 0 or below.")
        end
      elsif (@resource == "serviceofferings") || (@resource == "systemofferings")
        if !res.has_key?("cpunumber") || !res.has_key?("cpuspeed") || !res.has_key?("memory") || (res["cpunumber"] <= 0) || (res["cpuspeed"] <= 0) || (res["memory"] <= 0)
          errors.push("'cpunumber', 'cpuspeed' and/or 'memory' has not been defined, or is defined as 0 or below.")
        end
        if @resource == "systemofferings"
          approved_systemvmtype = ["domainrouter", "consoleproxy", "secondarystoragevm"]
          if !res.has_key?("systemvmtype") || !approved_systemvmtype.include?(res["systemvmtype"])
              errors.push("'systemvmtype' is unspecified or set to a value not valid in Cloudconfig.")
          end
        end
      end
      if !errors.empty?
        raise CreationError, errors
      end
    end


    def list_resources()
      @client = create_cloudstack_client()
      resource_file, resource_cloud = define_yamlfile_and_cloudresource()
      puts JSON.pretty_generate(resource_cloud)
    end

    def compare_resources()
      @delete = true
      @client = create_cloudstack_client()
      resources = ["serviceofferings", "hosts", "storages", "diskofferings", "systemofferings"]
      for r in resources
        @res = r
        resource_file, resource_cloud = define_yamlfile_and_cloudresource()
        r_updated, r_created, r_deleted = check_resource(resource_file, resource_cloud)
        puts "The following #{r} will be updated:"
        r_updated.each{ |re| puts "\n#{re[0]["name"]}" }
        puts "The following #{r} will be created:"
        r_created.each{ |re| puts "\n#{re["name"]}" }
        puts "The following #{r} will be deleted:"
        r_deleted.each{ |re| puts "\n#{re["name"]}" }
      end
    end

  end

  class CreationError < Exception
  end
end
