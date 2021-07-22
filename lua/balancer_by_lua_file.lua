local balancer = require("ngx.balancer")

local answers = ngx.ctx.answers
local server_address = nil

-- This block will only trigger if ngx.ctx.retry is not true or is
-- unset.
-- We set this to true during the initial request so future
-- requests within this context will not go down this path.
if not ngx.ctx.retry then
    ngx.ctx.retry = true

    --create a context table we dump tried backends to.
    ngx.ctx.tried = {}

    -- Pick a random backend to start with
    server_address = answers[math.random(#answers)].address
    
    -- Since we're going to try this address mark it as tried
    ngx.ctx.tried[server_address] = true

    -- set up more tries using the length of the server list minus 1.
    local ok, err = balancer.set_more_tries(#answers - 1)
    if not ok then
        ngx.log(ngx.ERR, "set_more_tries failed: ", err)
    end
else
    -- This block will trigger on a retry
    -- Here we'll run through the backends and pick one we haven't
    -- tried yet.
    for answer in answers do
        ip = answer.address
        in_ctx = ngx.ctx.tried[ip] ~= nil
        if in_ctx == false then
            ngx.ctx.tried[ip] = true
            server_address = ip
            break
        end
    end
end


local ok, err = balancer.set_current_peer(server_address, 443)
if not ok then
    ngx.log(ngx.ERR, "set_current_peer failed: ", err)
    return ngx.exit(500)
end