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
      resource_file, resource_cloud = define_yamlfile_and_cloudresource()
      if (resource_file == nil) || (resource_cloud == nil)
        puts "Resource not supported."
      else
        r_updated, r_created, r_deleted = check_resource(resource_file, resource_cloud)
        if @dryrun
          puts "The following actions would be performed with this command:\n"
        end
        r_updated.each{ |r| update_resource(r) }
        r_created.each{ |r| create_resource(r, false) }
        r_deleted.each{ |r| delete_resource(r, false) }
      end
    end


    def create_cloudstack_client()
      client = CloudstackRubyClient::Client.new(@config_file["url"], @config_file["api_key"], @config_file["secret_key"], true)
      return client
    end


    # Save the current list of resources in resource_cloud, and the ones in the yaml file in resource_file
    def define_yamlfile_and_cloudresource()
      resource_exists = true
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
      else
        resource_exists = false
      end
      if resource_exists
        resource_file = YAML.load_file("#{@config_file["resource_directory"]}/#{@resource}.yaml")["#{resource_title}"]
        return resource_file, resource_cloud
      else
        return nil, nil
      end
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
      updated = false
      res_diff = Hash[(res[0].to_a) - (res[1].to_a)]
      res_union = Hash[res[1].to_a | res[0].to_a]
      changes_requiring_recreation = res_diff.clone
      # If the parameters that differs only contain the following keys, then the resource only needs an update. Otherwise, a recreation is required.
      only_update_parameters = ["displaytext", "sortkey", "displayoffering"]
      only_update_parameters.each { |searched_param| changes_requiring_recreation.delete_if { |actual_param| actual_param == searched_param } }
      for param, value in changes_requiring_recreation
        if (!res[1].has_key?(param) || (res[1][param] == "")) && (value == "")
          changes_requiring_recreation.delete(param)
          res_diff.delete(param)
        end
      end
      # All these resources could need recreation and are controlled, to see if all nedded requirements are met.
      if (@resource == "serviceofferings") || (@resource == "systemofferings") || (@resource == "diskofferings")
        if creation_is_error_free(res_union)
          updated = true
          if !@dryrun
            if !changes_requiring_recreation.empty?
              delete_resource(res_union, updated)
              create_resource(res_union, updated)
            else
              if (@resource == "serviceofferings") || (@resource == "systemofferings")
                @client.update_service_offering(res_union)
              elsif @resource == "diskofferings"
                @client.update_disk_offering(res_union)
              end
            end
          end
        end
        # All these resources can only be updated.
      elsif (@resource == "hosts") || (@resource == "storages")
        updated = true
        if !@dryrun
          if @resource == "hosts"
            @client.update_host(res_union)
          elsif @resource == "storages"
            @client.update_storage_pool(res_union)
          end
        end
      end
      # Update has been made, and feedback is given to the user.
      if updated
        if changes_requiring_recreation.empty?
          puts "Some values has been changed in the #{@resource} named #{res[0]["name"]}.\nOld values were:\n#{JSON.pretty_generate(res[1])}\nNew values are:\n#{JSON.pretty_generate(res_diff)}\n"
        else
          puts "The #{@resource} named #{res[0]["name"]} has been recreated.\nOld values were:\n#{JSON.pretty_generate(res[1])}\nNew values are:\n#{JSON.pretty_generate(res_diff)}\n"
        end
      end
    end


    def create_resource(res, feedback_given)
      created = false
      if creation_is_error_free(res)
        created = true
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
        else
          created = false
        end
      end
      if created && !feedback_given
        puts "The #{@resource} named #{res["name"]} has been created\n"
      end
    end


    def delete_resource(res, feedback_given)
      deleted = false
      if (@resource == "serviceofferings") || (@resource == "systemofferings")
        deleted = true
        if !@dryrun
          @client.delete_service_offering({"id" => "#{res["id"]}"})
        end
      elsif (@resource == "diskofferings")
        deleted = true
        if !@dryrun
          @client.delete_disk_offering({"id" => "#{res["id"]}"})
        end
      end
      if deleted && !feedback_given
        puts "The #{@resource} named #{res["name"]} has been deleted\n" 
      end
    end


    def creation_is_error_free(res)
      error_free = true
      if !res.has_key?("displaytext")
        error_free = false
        puts "Error: #{res["name"]} could not be created since 'displaytext' has not been specified in configuration file."
      end
      if @resource == "diskofferings"
        if (!res.has_key?("iscustomized") || (res["iscustomized"] == false)) && (!res.has_key?("disksize") || (res["disksize"] == 0))
          error_free = false
          puts "\nError: The #{@resource} named #{res["name"]} could not be created since 'iscustomized' is unspecified or set to false and 'disksize' has not been specified, or has been specified to a value of 0 or below."
        end
      elsif (@resource == "serviceofferings") || (@resource == "systemofferings")
        if !res.has_key?("cpunumber") || !res.has_key?("cpuspeed") || !res.has_key?("memory") || (res["cpunumber"] <= 0) || (res["cpuspeed"] <= 0) || (res["memory"] <= 0)
          error_free = false
          puts "\nError: The #{@resource} named #{res["name"]} could not be created since 'cpunumber', 'cpuspeed' and/or 'memory' has not been defined, or is defined as 0 or below."
        end
        if @resource == "systemofferings"
          approved_systemvmtype = ["domainrouter", "consoleproxy", "secondarystoragevm"]
          if !res.has_key?("systemvmtype") || approved_systemvmtype.include?(res["systemofferings"])
            error_free = false
            puts "\nError: The #{@resource} named #{res["name"]} could not be created since 'systemvmtype' is unspecified or set to an value not valid in Cloudconfig."	
          end
        end
      end
      return error_free
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
end
