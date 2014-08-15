class TestHelper

  def get_resource_cloud()
    resource_cloud = [
      { "name" => "Resource-01",
        "id" => 111,
        "displaytext" => "Description A",
        "tag" => "RES",
        "cpunumber" => 1,
        "cpuspeed" => 1,
        "memory" => 1,
        "systemvmtype" => "domainrouter",
        "iscustomized" => false,
        "disksize" => 1
      },
      { "name" => "Resource-02",
        "id" => 222,
        "displaytext" => "Description B",
        "tag" => "RES",
        "cpunumber" => 1,
        "cpuspeed" => 1,
        "memory" => 1,
        "systemvmtype" => "domainrouter",
        "iscustomized" => false,
        "disksize" => 1
      },
      { "name" => "Resource-03",
        "id" => 333,
        "displaytext" => "Description C",
        "tag" => "RAN",
      }
    ]
    return resource_cloud.to_a
  end

  def get_resource_file()
    resource_file = {
        # Displaytext has changed in Resource-01
      "Resource-01" => {
        "displaytext" => "A different description",
        "tag" => "RES",
        "cpunumber" => 1,
        "cpuspeed" => 1,
        "memory" => 1,
        "systemvmtype" => "domainrouter",
        "iscustomized" => false,
        "disksize" => 1
      },
        # Tags has changed in Resource-02
      "Resource-02" => {
        "displaytext" => "Description B",
        "tag" => "RAN",
        "cpunumber" => 1,
        "cpuspeed" => 1,
        "memory" => 1,
        "systemvmtype" => "domainrouter",
        "iscustomized" => false,
        "disksize" => 1
      },
        # Resource-03 has been deleted
        # The resources below should be up for creation
        # serviceofferings, systemofferings and diskofferings: Resource-04 should be created
      "Resource-04" => {
        "displaytext" => "Description D",
        "cpunumber" => 1,
        "cpuspeed" => 1,
        "memory" => 1,
        "systemvmtype" => "domainrouter",
        "iscustomized" => false,
        "disksize" => 1
      },
        # serviceofferings, systemofferings and diskofferings: Resouce-05 does not have 'displaytext' and should not be created
      "Resource-05" => {
        "cpunumber" => 1,
        "cpuspeed" => 1,
        "memory" => 1,
        "systemvmtype" => "consoleproxy",
        "iscustomized" => true
      },
        # serviceofferings and systemofferings: Resource-06 doas not have 'cpunumber' and should not be created
        # diskofferings: Resource-06 should be created
      "Resource-06" => {
        "displaytext" => "Description F",
        "cpuspeed" => 1,
        "memory" => 1,
        "systemvmtype" => "secondarystoragevm",
        "iscustomized" => true
      },
        # serviceofferings and systemofferings: Resource-07 does not have valid 'cpuspeed' value and can not be created
        # diskofferings: Resource-07 has 'iscustomized' = false but does not have 'disksize' and should not be created
      "Resource-07" => {
        "displaytext" => "Description G",
        "cpunumber" => 1,
        "cpuspeed" => 0,
        "memory" => 1,
        "systemvmtype" => "domainrouter",
        "iscustomized" => false
      },
        # serviceofferings: Resource-08 should be created
        # systemofferings: Resource-08 does not have a valid 'systemvmtype' and can not be created
        # diskofferings: Resource-08 does not have a valid 'disksize'i and should not be created
      "Resource-08" => {
        "displaytext" => "Description H",
        "cpunumber" => 1,
        "cpuspeed" => 1,
        "memory" => 1,
        "systemvmtype" => "invalidsystemvmtype",
        "iscustomized" => false,
        "disksize" => 0
      }
    }
    return resource_file  
  end 

end
