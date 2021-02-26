local json = require("cjson")
local http = require("resty.http")

local uri = ngx.var.uri
local uri_args = ngx.req.get_uri_args()
local scheme = ngx.var.scheme

local corp_id = ngx.var.corp_id
local agent_id = ngx.var.agent_id
local secret = ngx.var.secret
local callback_scheme = ngx.var.callback_scheme or scheme
local callback_host = ngx.var.callback_host
local callback_uri = ngx.var.callback_uri
local use_secure_cookie = ngx.var.use_secure_cookie == "true" or false
local callback_url = callback_scheme .. "://" .. callback_host .. callback_uri
local redirect_url = callback_scheme .. "://" .. callback_host .. ngx.var.request_uri
local logout_uri = ngx.var.logout_uri or "/logout"
local token_expires = ngx.var.token_expires or "7200"
token_expires = tonumber(token_expires)

local function request_access_token(code)
    local request = http.new()
    request:set_timeout(7000)
    local res, err = request:request_uri("https://qyapi.weixin.qq.com/cgi-bin/gettoken", {
        method = "GET",
        query = {
            corpid = corp_id,
            corpsecret = secret,
        },
        ssl_verify = true,
    })
    if not res then
        return nil, (err or "access token request failed: " .. (err or "unknown reason"))
    end
    if res.status ~= 200 then
        return nil, "received " .. res.status .. " from https://qyapi.weixin.qq.com/cgi-bin/gettoken: " .. res.body
    end
    local data = json.decode(res.body)
    if data["errcode"] ~= 0 then
        return nil, data["errmsg"]
    else
        return data["access_token"]
    end
end

local function request_user(access_token, code)
    local request = http.new()
    request:set_timeout(7000)
    local res, err = request:request_uri("https://qyapi.weixin.qq.com/cgi-bin/user/getuserinfo", {
        method = "GET",
        query = {
            access_token = access_token,
            code = code,
        },
        ssl_verify = true,
    })
    if not res then
        return nil, "get profile request failed: " .. (err or "unknown reason")
    end
    if res.status ~= 200 then
        return nil, "received " .. res.status .. " from https://qyapi.weixin.qq.com/cgi-bin/user/getuserinfo"
    end
    local userinfo = json.decode(res.body)
    if userinfo["errcode"] == 0 then
        if userinfo["UserId"] then
            res, err = request:request_uri("https://qyapi.weixin.qq.com/cgi-bin/user/get", {
                method = "GET",
                query = {
                    access_token = access_token,
                    userid = userinfo["UserId"],
                },
                ssl_verify = true,
            })
            if not res then
                return nil, "get user request failed: " .. (err or "unknown reason")
            end
            if res.status ~= 200 then
                return nil, "received " .. res.status .. " from https://qyapi.weixin.qq.com/cgi-bin/user/get"
            end
            local user = json.decode(res.body)
            if user["errcode"] == 0 then
                return user
            else
                return nil, user["errmsg"]
            end
        else
            return nil, "UserId not exists"
        end
    else
        return nil, userinfo["errmsg"]
    end
end

local function is_authorized()
    local headers = ngx.req.get_headers()
    local expires = tonumber(ngx.var.cookie_OauthExpires) or 0
    local user_id = ngx.unescape_uri(ngx.var.cookie_OauthUserID or "")
    local token = ngx.var.cookie_OauthAccessToken or ""
    if expires == 0 and headers["OauthExpires"] then
        expires = tonumber(headers["OauthExpires"])
    end
    if user_id:len() == 0 and headers["OauthUserID"] then
        user_id = headers["OauthUserID"]
    end
    if token:len() == 0 and headers["OauthAccessToken"] then
        token = headers["OauthAccessToken"]
    end
    local expect_token = callback_host .. user_id .. expires
    if token == expect_token and expires then
        if expires > ngx.time() then
            return true
        else
            return false
        end
    else
        return false
    end
end

local function redirect_to_auth()
    return ngx.redirect("https://open.work.weixin.qq.com/wwopen/sso/qrConnect?" .. ngx.encode_args({
        appid = corp_id,
        agentid = agent_id,
        redirect_uri = callback_url,
        state = redirect_url
    }))
end

local function authorize()
    if uri ~= callback_uri then
        return redirect_to_auth()
    end
    local code = uri_args["code"]
    if not code then
        ngx.log(ngx.ERR, "not received code from https://open.work.weixin.qq.com/wwopen/sso/qrConnect")
        return ngx.exit(ngx.HTTP_FORBIDDEN)
    end

    local access_token, request_access_token_err = request_access_token(code)
    if not access_token then
        ngx.log(ngx.ERR, "got error during access token request: " .. request_access_token_err)
        return ngx.exit(ngx.HTTP_FORBIDDEN)
    end

    local user, request_user_err = request_user(access_token, code)
    if not user then
        ngx.log(ngx.ERR, "got error during profile request: " .. request_user_err)
        return ngx.exit(ngx.HTTP_FORBIDDEN)
    end
    ngx.log(ngx.ERR, "user id: " .. user["userid"])

    local expires = ngx.time() + token_expires
    local cookie_tail = "; version=1; path=/; Max-Age=" .. expires
    if use_secure_cookie then
        cookie_tail = cookie_tail .. "; secure"
    end

    local user_id = user["userid"]
    local user_token = callback_host .. user_id .. expires

    ngx.header["Set-Cookie"] = {
        "OauthUserID=" .. ngx.escape_uri(user_id) .. cookie_tail,
        "OauthAccessToken=" .. ngx.escape_uri(user_token) .. cookie_tail,
        "OauthExpires=" .. expires .. cookie_tail,
    }
    return ngx.redirect(uri_args["state"])
end

local function handle_logout()
    if uri == logout_uri then
        ngx.header["Set-Cookie"] = "OauthAccessToken==deleted; path=/; expires=Thu, 01 Jan 1970 00:00:00 GMT"
        --return ngx.redirect("/")
    end
end

handle_logout()
if (not is_authorized()) then
    authorize()
end
