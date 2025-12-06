-- Simple HTTP server to catch OAuth callbacks
local M = {}

-- Parse HTTP request to extract query parameters
local function parse_request(data)
  -- Extract the request line (first line)
  local request_line = data:match("^([^\r\n]*)")
  if not request_line then
    return nil
  end

  -- Extract path with query string
  local path = request_line:match("GET%s+([^%s]+)")
  if not path then
    return nil
  end

  -- Extract query string
  local query_string = path:match("%?(.+)$")
  if not query_string then
    return {}
  end

  -- Parse query parameters
  local params = {}
  for key, value in query_string:gmatch("([^&=]+)=([^&=]+)") do
    -- URL decode: replace + with space and %XX with character
    value = value:gsub("+", " "):gsub("%%(%x%x)", function(hex)
      return string.char(tonumber(hex, 16))
    end)
    params[key] = value
  end

  return params
end

-- Send HTTP response
local function send_response(client, status, body)
  local response = string.format(
    "HTTP/1.1 %s\r\n" ..
    "Content-Type: text/html; charset=utf-8\r\n" ..
    "Content-Length: %d\r\n" ..
    "Connection: close\r\n" ..
    "\r\n" ..
    "%s",
    status,
    #body,
    body
  )
  client:write(response)
end

-- Start temporary HTTP server to catch OAuth callback
-- Calls callback(code, state, error) when authorization completes
function M.start_callback_server(port, expected_state, callback)
  local server = vim.loop.new_tcp()
  local addr = "127.0.0.1"

  -- Bind to port
  server:bind(addr, port)

  -- Listen for connections
  server:listen(128, function(err)
    if err then
      vim.schedule(function()
        callback(nil, nil, "Server listen error: " .. err)
      end)
      return
    end

    -- Accept client connection
    local client = vim.loop.new_tcp()
    server:accept(client)

    -- Read request
    client:read_start(function(read_err, data)
      if read_err then
        vim.schedule(function()
          callback(nil, nil, "Read error: " .. read_err)
        end)
        client:close()
        server:close()
        return
      end

      if data then
        -- Parse request
        local params = parse_request(data)

        if params and params.code then
          -- Success! Got authorization code
          local success_html = [[
<!DOCTYPE html>
<html>
<head>
  <title>Spotify Authorization</title>
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
      display: flex;
      justify-content: center;
      align-items: center;
      height: 100vh;
      margin: 0;
      background: linear-gradient(135deg, #1DB954 0%, #191414 100%);
    }
    .container {
      background: white;
      padding: 40px;
      border-radius: 12px;
      box-shadow: 0 4px 20px rgba(0,0,0,0.3);
      text-align: center;
      max-width: 400px;
    }
    h1 { color: #1DB954; margin-top: 0; }
    p { color: #666; }
    .success { font-size: 48px; margin-bottom: 20px; }
  </style>
</head>
<body>
  <div class="container">
    <div class="success">✓</div>
    <h1>Authorization Successful!</h1>
    <p>You can close this window and return to Neovim.</p>
  </div>
</body>
</html>
]]
          send_response(client, "200 OK", success_html)

          -- Close connections
          vim.schedule(function()
            client:shutdown()
            client:close()
            server:close()

            -- Call callback with authorization code
            callback(params.code, params.state, nil)
          end)
        elseif params and params.error then
          -- Error in authorization
          local error_html = string.format([[
<!DOCTYPE html>
<html>
<head>
  <title>Authorization Error</title>
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
      display: flex;
      justify-content: center;
      align-items: center;
      height: 100vh;
      margin: 0;
      background: linear-gradient(135deg, #ff4444 0%, #191414 100%);
    }
    .container {
      background: white;
      padding: 40px;
      border-radius: 12px;
      box-shadow: 0 4px 20px rgba(0,0,0,0.3);
      text-align: center;
      max-width: 400px;
    }
    h1 { color: #ff4444; margin-top: 0; }
    p { color: #666; }
    .error { font-size: 48px; margin-bottom: 20px; }
  </style>
</head>
<body>
  <div class="container">
    <div class="error">✗</div>
    <h1>Authorization Failed</h1>
    <p>Error: %s</p>
    <p>You can close this window.</p>
  </div>
</body>
</html>
]], params.error)
          send_response(client, "400 Bad Request", error_html)

          vim.schedule(function()
            client:shutdown()
            client:close()
            server:close()
            callback(nil, nil, "Authorization error: " .. params.error)
          end)
        else
          -- Invalid request
          send_response(client, "400 Bad Request", "Invalid request")
          client:shutdown()
          client:close()
        end
      end
    end)
  end)

  return server
end

return M
