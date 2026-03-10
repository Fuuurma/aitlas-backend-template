defmodule AitlasWeb.Controllers.HealthControllerTest do
  use AitlasWeb.ConnCase

  describe "GET /api/health" do
    test "returns ok status with db connected" do
      conn = get(build_conn(), "/api/health")

      assert %{
               "status" => "ok",
               "db" => "connected",
               "timestamp" => _
             } = json_response(conn, 200)
    end
  end
end
