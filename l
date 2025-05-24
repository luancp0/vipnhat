local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

-- Chờ nhân vật của người chơi load
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:FindFirstChildOfClass("Humanoid")

local infiniteJumpEnabled = false -- Biến để theo dõi trạng thái Infinite Jump

-- ### CÀI ĐẶT THỜI GIAN TỰ ĐỘNG ###
local AUTO_JUMP_INTERVAL = 19 * 60 -- Khoảng thời gian giữa các lần tự động bật (19 phút)
-- local AUTO_JUMP_INTERVAL = 10 -- Dành cho TEST: 10 giây
local AUTO_JUMP_ACTIVE_DURATION = 1 -- Thời gian Infinite Jump được bật (1 giây)
------------------------------------

local timeUntilNextAutoJump = AUTO_JUMP_INTERVAL

-- Hàm xử lý Infinite Jump
local function handleInfiniteJump()
    -- Luôn đặt Humanoid.Jump = true khi chức năng được bật
    if infiniteJumpEnabled and humanoid and humanoid.Health > 0 then
        humanoid.Jump = true
    end
end

-- Kết nối hàm handleInfiniteJump với RenderStepped để nhảy liên tục
local jumpConnection = nil

local function enableInfiniteJump()
    if infiniteJumpEnabled then return end -- Tránh bật lại nếu đã bật
    if not humanoid then return end -- Đảm bảo humanoid tồn tại
    infiniteJumpEnabled = true
    -- Sử dụng RenderStepped để nhảy mượt mà nhất
    if jumpConnection then jumpConnection:Disconnect() end -- Ngắt kết nối cũ nếu có
    jumpConnection = RunService.RenderStepped:Connect(handleInfiniteJump)
    print("Infinite Jump: ENABLED (Tự động)")
end

local function disableInfiniteJump()
    if not infiniteJumpEnabled then return end -- Tránh tắt lại nếu đã tắt
    infiniteJumpEnabled = false
    if jumpConnection then
        jumpConnection:Disconnect()
        jumpConnection = nil
    end
    -- Đặt Humanoid.Jump = false để dừng nhảy khi tắt chức năng
    if humanoid then
        humanoid.Jump = false
    end
    print("Infinite Jump: DISABLED (Tự động)")
end

-- Cập nhật Humanoid nếu nhân vật Respawn
player.CharacterAdded:Connect(function(newCharacter)
    character = newCharacter
    humanoid = character:FindFirstChildOfClass("Humanoid")
    -- Nếu Infinite Jump đang bật (bởi hệ thống tự động chẳng hạn), cần kết nối lại
    -- Tuy nhiên, hệ thống tự động sẽ tự quản lý việc bật/tắt.
    -- Quan trọng là humanoid được cập nhật.
    -- Nếu trước đó đang trong trạng thái nhảy tự động và nhân vật chết,
    -- khi hồi sinh, lần nhảy tự động tiếp theo sẽ hoạt động bình thường.
    -- Đảm bảo trạng thái nhảy bị tắt khi nhân vật mới xuất hiện nếu không trong chu kỳ active.
    if infiniteJumpEnabled then
        -- Nếu đang trong 1s active mà chết, thì khi hồi sinh có thể nó vẫn đang true
        -- disableInfiniteJump() -- Tạm thời disable để tránh lỗi, logic tự động sẽ bật lại nếu cần
        -- Hoặc tốt hơn là để logic tự động tự xử lý, chỉ cập nhật humanoid
    end
    print("Nhân vật mới đã được load. Humanoid cập nhật.")
end)

-- GUI
local screenGui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
screenGui.Name = "InfiniteJumpGUI"
screenGui.ResetOnSpawn = false -- Để GUI không bị reset khi nhân vật chết

local frame = Instance.new("Frame", screenGui)
frame.Size = UDim2.new(0, 250, 0, 130) -- Tăng kích thước để chứa thêm label
frame.Position = UDim2.new(0, 20, 0, 150)
frame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
frame.Active = true
frame.Draggable = true

local titleLabel = Instance.new("TextLabel", frame)
titleLabel.Text = "Auto Infinite Jump"
titleLabel.Size = UDim2.new(1, 0, 0, 30)
titleLabel.Position = UDim2.new(0, 0, 0, 0)
titleLabel.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
titleLabel.TextColor3 = Color3.new(1, 1, 1)
titleLabel.TextScaled = true
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Center

local statusLabel = Instance.new("TextLabel", frame)
statusLabel.Text = "Trạng thái: Chờ..."
statusLabel.Size = UDim2.new(1, -20, 0, 30)
statusLabel.Position = UDim2.new(0, 10, 0, 40)
statusLabel.BackgroundColor3 = Color3.fromRGB(170, 0, 0) -- Đỏ (mặc định là Tắt/Cooldown)
statusLabel.TextColor3 = Color3.new(1, 1, 1)
statusLabel.Font = Enum.Font.SourceSans
statusLabel.TextScaled = true
statusLabel.TextXAlignment = Enum.TextXAlignment.Center

local timerDisplayLabel = Instance.new("TextLabel", frame)
timerDisplayLabel.Text = "Bật tiếp theo trong: --:--"
timerDisplayLabel.Size = UDim2.new(1, -20, 0, 40)
timerDisplayLabel.Position = UDim2.new(0, 10, 0, 80)
timerDisplayLabel.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
timerDisplayLabel.TextColor3 = Color3.new(1, 1, 1)
timerDisplayLabel.Font = Enum.Font.SourceSansSemibold
timerDisplayLabel.TextScaled = true
timerDisplayLabel.TextXAlignment = Enum.TextXAlignment.Center

-- Logic tự động bật/tắt và cập nhật GUI
task.spawn(function()
    while true do
        if not player or not player.Parent then break end -- Thoát nếu người chơi rời đi

        if timeUntilNextAutoJump <= 0 then
            -- KÍCH HOẠT INFINITE JUMP
            if humanoid and humanoid.Health > 0 then -- Chỉ kích hoạt nếu humanoid hợp lệ và còn sống
                enableInfiniteJump()
                statusLabel.Text = "Trạng thái: ĐANG BẬT"
                statusLabel.BackgroundColor3 = Color3.fromRGB(0, 170, 0) -- Xanh lá khi Bật
                timerDisplayLabel.Text = "Đang bật trong: " .. AUTO_JUMP_ACTIVE_DURATION .. "s"

                -- Chờ hết thời gian bật
                local activeTimePassed = 0
                while activeTimePassed < AUTO_JUMP_ACTIVE_DURATION do
                    if not infiniteJumpEnabled then break end -- Nếu bị tắt bởi lý do khác thì dừng
                    task.wait(0.1)
                    activeTimePassed = activeTimePassed + 0.1
                    if humanoid and humanoid.Health > 0 and infiniteJumpEnabled then -- Kiểm tra lại humanoid
                         timerDisplayLabel.Text = string.format("Đang bật trong: %.1fs", AUTO_JUMP_ACTIVE_DURATION - activeTimePassed)
                    else
                        break -- Dừng nếu humanoid không hợp lệ hoặc jump đã bị tắt
                    end
                end
                
                disableInfiniteJump()
            else
                print("Không thể kích hoạt Infinite Jump: Humanoid không hợp lệ hoặc đã chết.")
            end
            
            -- Đặt lại trạng thái và bộ đếm
            statusLabel.Text = "Trạng thái: Đang chờ..."
            statusLabel.BackgroundColor3 = Color3.fromRGB(170, 0, 0) -- Đỏ khi Tắt/Cooldown
            timeUntilNextAutoJump = AUTO_JUMP_INTERVAL
        end

        -- Cập nhật hiển thị thời gian đếm ngược
        if not infiniteJumpEnabled then -- Chỉ cập nhật đếm ngược nếu không đang trong trạng thái bật
            local minutes = math.floor(timeUntilNextAutoJump / 60)
            local seconds = timeUntilNextAutoJump % 60
            timerDisplayLabel.Text = string.format("Bật tiếp theo trong: %02d:%02d", minutes, seconds)
        end

        task.wait(1)
        if not infiniteJumpEnabled then -- Chỉ giảm bộ đếm nếu không đang trong trạng thái bật (để tránh giảm kép khi đang active)
             timeUntilNextAutoJump = timeUntilNextAutoJump - 1
        end
    end
end)

-- Đảm bảo trạng thái ban đầu là tắt
disableInfiniteJump()

print("Script Auto Infinite Jump đã được load với chu kỳ " .. AUTO_JUMP_INTERVAL .. "s, hoạt động trong " .. AUTO_JUMP_ACTIVE_DURATION .. "s.")

