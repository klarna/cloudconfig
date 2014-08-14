class TestHelper

  def get_resource_cloud()
    resource_cloud = [
      { "name" => "Resource-01",
        "id" => 111,
        "displaytext" => "Description A",
        "tag" => "RES"
      },
      { "name" => "Resource-02",
        "id" => 222,
        "displaytext" => "Description B",
        "tag" => "RES"
      },
      { "name" => "Resource-03",
        "id" => 333,
        "displaytext" => "Description C",
        "tag" => "RAN"
      }
    ]
    return resource_cloud.to_a
  end

  def get_resource_file()
    resource_file = {
      "Resource-01" => {
        "displaytext" => "A different description",
        "tag" => "RES"
      },
      "Resource-02" => {
        "displaytext" => "Description B",
        "tag" => "RAN"
      },
      "Resource-04" => {
        "displaytext" => "Description D",
        "tag" => "RAN"
      }
    }
    return resource_file  
  end 

end
