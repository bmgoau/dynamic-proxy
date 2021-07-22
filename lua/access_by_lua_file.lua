local client = require("resty.dns.client") -- import kong dns client

local ctx = {} -- create a ctx we can reuse in other lua throughout the request lifecycle

assert(client.init({ -- http://kong.github.io/lua-resty-dns-client/modules/resty.dns.client.html#resolve
    order = { "A" , "CNAME" }
}))

local answers, err = client.resolve(ngx.var.sanitized_domain) -- lookup the domain
if not answers then
    ngx.say("failed to resolve: ", err)
end

ctx.answers = answers

ngx.ctx = ctx -- store the ctx in ngx for reuse elsewhere