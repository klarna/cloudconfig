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
			r_updated, r_created, r_deleted = check_resource(resource_file, resource_cloud)
			feedback = ""
			if @dryrun
				feedback = "The following actions would be performed with this command:\n"
			else
				for r in r_updated
					r_diff = Hash[(r[0].to_a) - (r[1].to_a)]
					r_union = Hash[r[0].to_a | r_diff.to_a]
					update_resource(r_union)
				end
				r_created.each{ |r| create_resource(r) }
				r_deleted.each{ |r| delete_resource(r) }
			end
			for r in r_updated
				r_diff = Hash[(r[0].to_a) - (r[1].to_a)]
				feedback += "Some values has been changed in #{@resource} named #{r[0]["name"]}.\nOld values were:\n#{JSON.pretty_generate(r[1])}\nNew values are:\n#{JSON.pretty_generate(r_diff)}\n"
			end
			r_created.each{ |r| feedback += "#{@resource} named #{r["name"]} has been created\n" }
			r_deleted.each{ |r| feedback += "#{@resource} named #{r["name"]} has been deleted\n" }
			puts feedback
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
			if (@resource == "serviceofferings") || (@resource == "systemofferings")
				@client.delete_service_offering({"id" => "#{res["id"]}"})
				@client.create_service_offering(res)
			elsif @resource == "hosts"
				@client.update_host(res)
			elsif @resource == "storages"
				@client.update_storage_pool(res)
			elsif @resource == "diskofferings"
				@client.delete_disk_offering({"id" => "#{res["id"]}"})
				create_resource(res)
			end
		end


		def create_resource(res)
			if (@resource == "serviceofferings") || (@resource == "systemofferings")
				@client.create_service_offering(res)
			elsif (@resource == "diskofferings")
				# Parameter iscustomized has different name (customized) when creating resource, and parameter disksize create error if iscustomized is true.
				if res["iscustomized"] == true
					res.delete("disksize")
				end
				res = res.merge({"customized" => res["iscustomized"]})
				res.delete("iscustomized")
				@client.create_disk_offering(res)
			end
		end


		def delete_resource(res)
			if (@resource == "serviceofferings") || (@resource == "systemofferings")
				@client.delete_service_offering({"id" => "#{res["id"]}"})
			elsif (@resource == "diskofferings")
				@client.delete_disk_offering({"id" => "#{res["id"]}"})
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
end
