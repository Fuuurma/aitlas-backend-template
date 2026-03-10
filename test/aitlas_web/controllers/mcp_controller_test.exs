defmodule AitlasWeb.Controllers.MCPControllerTest do
  use AitlasWeb.ConnCase

  @mcp_api_key "aitlas_mcp_dev_key_12345"

  describe "POST /api/mcp" do
    test "returns tools list for tools/list method" do
      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer #{@mcp_api_key}")
        |> post("/api/mcp", %{
          jsonrpc: "2.0",
          id: 1,
          method: "tools/list",
          params: %{}
        })

      assert %{"jsonrpc" => "2.0", "id" => 1, "result" => %{"tools" => tools}} =
               json_response(conn, 200)

      assert is_list(tools)
    end

    test "returns pong for ping method" do
      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer #{@mcp_api_key}")
        |> post("/api/mcp", %{
          jsonrpc: "2.0",
          id: 1,
          method: "ping",
          params: %{}
        })

      assert %{"jsonrpc" => "2.0", "id" => 1, "result" => %{}} = json_response(conn, 200)
    end

    test "returns initialize response for initialize method" do
      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer #{@mcp_api_key}")
        |> post("/api/mcp", %{
          jsonrpc: "2.0",
          id: 1,
          method: "initialize",
          params: %{}
        })

      assert %{"jsonrpc" => "2.0", "id" => 1, "result" => result} = json_response(conn, 200)
      assert %{"protocolVersion" => _, "serverInfo" => _, "capabilities" => _} = result
    end

    test "returns error for unknown method" do
      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer #{@mcp_api_key}")
        |> post("/api/mcp", %{
          jsonrpc: "2.0",
          id: 1,
          method: "unknown/method",
          params: %{}
        })

      assert %{"jsonrpc" => "2.0", "id" => 1, "error" => %{"code" => -32_601}} =
               json_response(conn, 200)
    end

    test "returns error for invalid request" do
      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer #{@mcp_api_key}")
        |> post("/api/mcp", %{})

      assert %{"jsonrpc" => "2.0", "error" => %{"code" => -32_600}} = json_response(conn, 200)
    end
  end
end
