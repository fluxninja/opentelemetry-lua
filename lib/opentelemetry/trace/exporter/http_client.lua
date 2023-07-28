local http = require("socket.http")

local _M = {
}

local mt = {
    __index = _M
}

------------------------------------------------------------------
-- create a http client used by exporter.
--
-- @address             opentelemetry collector: host:port
-- @timeout             export request timeout second
-- @headers             export request headers
-- @return              http client
------------------------------------------------------------------
function _M.new(address, timeout, headers)
    headers = headers or {}
    headers["Content-Type"] = "application/json"

    local uri = address .. "/v1/traces"
    if address:find("http", 1, true) ~= 1 then
        uri = "http://" .. uri
    end

    local self = {
        uri = uri,
        timeout = timeout,
        headers = headers,
    }
    return setmetatable(self, mt)
end

function _M.do_request(self, body)
    http.TIMEOUT = self.timeout * 1000

    local response_body = {}
    local response, code, response_headers = http.request{
        url = self.uri,
        method = "POST",
        headers = self.headers,
        source = ltn12.source.string(body),
        sink = ltn12.sink.table(response_body),
    }

    if not response then
        ngx.log(ngx.ERR, "request failed: ", code)
        return nil, err
    end

    if code ~= ngx.HTTP_OK  then
        ngx.log(ngx.ERR, "request failed: ", response_body[1])
        return nil, "request failed: " .. code
    end

    return response_body[1], nil
end

return _M
