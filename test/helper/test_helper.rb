class TestHelper

  def get_resource_cloud()
    resource_cloud = [
      { "name" => "Resource-01",
        "id" => 111,
        "tag" => "RES"
      },
      { "name" => "Resource-02",
        "id" => 222,
        "tag" => "RES"
      },
      { "name" => "Resource-03",
        "id" => 333,
        "tag" => "RAN"
      }
    ]
    return resource_cloud.to_a
  end

  def get_resource_file()
    resource_file = {
      "Resource-01" => {
        "id" => 111,
        "tag" => "RES"
      },
      "Resource-02" => {
        "id" => 222,
        "tag" => "RAN"
      },
      "Resource-04" => {
        "id" => 444,
        "tag" => "RAN"
      }
    }
    return resource_file  
  end 

end
