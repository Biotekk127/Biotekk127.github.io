--[[
	Plays the idle animations of brainrot characters (and rarity orbit rings) locally.

	Models tagged CharacterKit.AnimatedTag carry Anim* attributes on animated parts and
	animated group Models (whose WorldPivot is the joint). Every frame each animated
	part is placed at:
	    Root * (O1 * A1(t) * O1^-1) * (O2 * A2(t) * O2^-1) * ... * Base * Apart(t)
	where O = a group's pivot relative to the root, A = its animation transform, and
	Base = the part's rest pose relative to the root. Groups nest naturally (a hand
	wiggling inside a waving arm inside a bobbing body).

	Only models near the camera (or inside a visible ViewportFrame) are animated.
	Rainbow-tagged parts/models cycle through hues.
]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local CharacterKit = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("CharacterKit"))

local Animator = {}

local ACTIVE_DISTANCE = 170
local CULL_INTERVAL = 0.5

type Node = { Origin: CFrame, OriginInverse: CFrame, Anim: CharacterKit.AnimParams }
type Entry = {
	Part: BasePart,
	Base: CFrame,
	BaseSize: Vector3,
	Chain: { Node },
	Own: CharacterKit.AnimParams?,
}
type Rig = {
	Model: Model,
	Root: BasePart,
	Entries: { Entry },
	Nodes: { Node },
	Active: boolean,
	InViewport: boolean,
}

local rigs: { [Model]: Rig } = {}

local function buildRig(model: Model): Rig?
	local root = model.PrimaryPart
	if not root then
		return nil
	end
	local rootInverse = root.CFrame:Inverse()
	local nodeCache: { [Instance]: Node } = {}
	local nodes: { Node } = {}

	local function nodeFor(group: Model): Node?
		local cached = nodeCache[group]
		if cached then
			return cached
		end
		local anim = CharacterKit.ReadAnim(group)
		if not anim then
			return nil
		end
		local origin = rootInverse * group.WorldPivot
		local node = { Origin = origin, OriginInverse = origin:Inverse(), Anim = anim }
		nodeCache[group] = node
		table.insert(nodes, node)
		return node
	end

	local entries: { Entry } = {}
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") and part ~= root then
			-- Collect animated ancestor groups, outermost first.
			local chain: { Node } = {}
			local ancestor = part.Parent
			while ancestor and ancestor ~= model do
				if ancestor:IsA("Model") then
					local node = nodeFor(ancestor)
					if node then
						table.insert(chain, 1, node)
					end
				end
				ancestor = ancestor.Parent
			end
			local own = CharacterKit.ReadAnim(part)
			if #chain > 0 or own then
				table.insert(entries, {
					Part = part,
					Base = rootInverse * part.CFrame,
					BaseSize = part.Size,
					Chain = chain,
					Own = own,
				})
			end
		end
	end
	if #entries == 0 then
		return nil
	end
	return {
		Model = model,
		Root = root,
		Entries = entries,
		Nodes = nodes,
		Active = false,
		InViewport = model:FindFirstAncestorOfClass("ViewportFrame") ~= nil,
	}
end

local function addModel(instance: Instance)
	if not instance:IsA("Model") or rigs[instance] then
		return
	end
	-- Wait a frame so every descendant has replicated / been parented.
	task.defer(function()
		if instance.Parent and not rigs[instance] then
			local rig = buildRig(instance)
			if rig then
				rigs[instance] = rig
			end
		end
	end)
end

local function removeModel(instance: Instance)
	rigs[instance :: Model] = nil
end

local function updateCulling()
	local camera = workspace.CurrentCamera
	local cameraPos = if camera then camera.CFrame.Position else Vector3.zero
	for model, rig in rigs do
		if not model.Parent or not rig.Root.Parent then
			rigs[model] = nil
		elseif rig.InViewport then
			local viewport = model:FindFirstAncestorOfClass("ViewportFrame")
			rig.Active = viewport ~= nil and viewport.Visible and viewport:IsDescendantOf(game)
		else
			rig.Active = (rig.Root.Position - cameraPos).Magnitude < ACTIVE_DISTANCE
		end
	end
end

local partsBuffer: { BasePart } = {}
local cframesBuffer: { CFrame } = {}

local function step()
	local t = os.clock()
	table.clear(partsBuffer)
	table.clear(cframesBuffer)
	for _, rig in rigs do
		if rig.Active then
			local rootCF = rig.Root.CFrame
			-- Each group's world-independent delta for this frame.
			local deltas: { [Node]: CFrame } = {}
			for _, node in rig.Nodes do
				deltas[node] = node.Origin * CharacterKit.AnimTransform(node.Anim, t) * node.OriginInverse
			end
			for _, entry in rig.Entries do
				local cf = rootCF
				for _, node in entry.Chain do
					cf *= deltas[node]
				end
				cf *= entry.Base
				local own = entry.Own
				if own then
					cf *= CharacterKit.AnimTransform(own, t)
					if own.Type == "Pulse" or own.Type == "Blink" then
						local size = entry.BaseSize * CharacterKit.AnimScale(own, t)
						if entry.Part.Size ~= size then
							entry.Part.Size = size
						end
					end
				end
				table.insert(partsBuffer, entry.Part)
				table.insert(cframesBuffer, cf)
			end
		end
	end
	if #partsBuffer > 0 then
		workspace:BulkMoveTo(partsBuffer, cframesBuffer, Enum.BulkMoveMode.FireCFrameChanged)
	end
end

----------------------------------------------------------------------------------------
-- Rainbow colour cycling (Rainbow mutation drops, Secret rarity pedestals)
----------------------------------------------------------------------------------------

local rainbowParts: { [BasePart]: number } = {}

local function addRainbow(instance: Instance)
	local function add(part: Instance)
		if part:IsA("BasePart") and part.Transparency < 1 then
			rainbowParts[part] = math.random()
		end
	end
	if instance:IsA("BasePart") then
		add(instance)
	end
	for _, descendant in instance:GetDescendants() do
		add(descendant)
	end
end

local function stepRainbow()
	local t = os.clock()
	for part, offset in rainbowParts do
		if part.Parent then
			part.Color = Color3.fromHSV((t * 0.25 + offset) % 1, 0.75, 1)
		else
			rainbowParts[part] = nil
		end
	end
end

----------------------------------------------------------------------------------------

function Animator.Start()
	for _, instance in CollectionService:GetTagged(CharacterKit.AnimatedTag) do
		addModel(instance)
	end
	CollectionService:GetInstanceAddedSignal(CharacterKit.AnimatedTag):Connect(addModel)
	CollectionService:GetInstanceRemovedSignal(CharacterKit.AnimatedTag):Connect(removeModel)

	for _, instance in CollectionService:GetTagged(CharacterKit.RainbowTag) do
		addRainbow(instance)
	end
	CollectionService:GetInstanceAddedSignal(CharacterKit.RainbowTag):Connect(function(instance)
		task.defer(addRainbow, instance)
	end)

	local sinceCull = math.huge
	local sinceRainbow = 0
	RunService.RenderStepped:Connect(function(dt)
		sinceCull += dt
		if sinceCull >= CULL_INTERVAL then
			sinceCull = 0
			updateCulling()
		end
		step()
		sinceRainbow += dt
		if sinceRainbow >= 0.1 then
			sinceRainbow = 0
			stepRainbow()
		end
	end)
end

-- For models created on the client (Index viewports), register immediately.
function Animator.Track(model: Model)
	local rig = buildRig(model)
	if rig then
		rigs[model] = rig
	end
end

return Animator
