--[[
	FishingStateMachine (ModuleScript)
	FISH!TUNE — Fishing Finite State Machine (FISH-008)

	Sistem Manajemen Status & Siklus Hidup Memancing Terpusat:
	1. State Enums Formal (IDLE, CHARGING_CAST, CASTING, WAITING_FOR_BITE, BITING, MINIGAME, REELING_SUCCESS, REELING_FAIL).
	2. Validasi Transisi Legal (Mencegah perpindahan status ilegal / stuck state).
	3. Lifecycle Event Hooks (OnEnter, OnExit, OnStateChanged).
	4. Force Reset & Graceful Cleanup (Menghindari character freeze & memory leak saat unequip / respawn).
]]

local FishingStateMachine = {}
FishingStateMachine.__index = FishingStateMachine

-- ============ STATE ENUMS ============
FishingStateMachine.States = {
	IDLE = "IDLE",
	CHARGING_CAST = "CHARGING_CAST",
	CASTING = "CASTING",
	WAITING_FOR_BITE = "WAITING_FOR_BITE",
	BITING = "BITING",
	MINIGAME = "MINIGAME",
	REELING_SUCCESS = "REELING_SUCCESS",
	REELING_FAIL = "REELING_FAIL",
}

-- ============ LEGAL TRANSITION GRAPH ============
local LEGAL_TRANSITIONS = {
	[FishingStateMachine.States.IDLE] = {
		[FishingStateMachine.States.CHARGING_CAST] = true,
		[FishingStateMachine.States.CASTING] = true,
	},
	[FishingStateMachine.States.CHARGING_CAST] = {
		[FishingStateMachine.States.CASTING] = true,
		[FishingStateMachine.States.IDLE] = true, -- Cancelled
	},
	[FishingStateMachine.States.CASTING] = {
		[FishingStateMachine.States.WAITING_FOR_BITE] = true,
		[FishingStateMachine.States.IDLE] = true, -- Cancelled / interrupted
	},
	[FishingStateMachine.States.WAITING_FOR_BITE] = {
		[FishingStateMachine.States.BITING] = true,
		[FishingStateMachine.States.IDLE] = true, -- Cancelled / unequipped
	},
	[FishingStateMachine.States.BITING] = {
		[FishingStateMachine.States.MINIGAME] = true,
		[FishingStateMachine.States.IDLE] = true, -- Missed / timed out
	},
	[FishingStateMachine.States.MINIGAME] = {
		[FishingStateMachine.States.REELING_SUCCESS] = true,
		[FishingStateMachine.States.REELING_FAIL] = true,
		[FishingStateMachine.States.IDLE] = true, -- Interrupted / cancelled
	},
	[FishingStateMachine.States.REELING_SUCCESS] = {
		[FishingStateMachine.States.IDLE] = true,
	},
	[FishingStateMachine.States.REELING_FAIL] = {
		[FishingStateMachine.States.IDLE] = true,
	},
}

-- ============ CONSTRUCTOR ============
function FishingStateMachine.new(initialState)
	local self = setmetatable({}, FishingStateMachine)
	self.CurrentState = initialState or FishingStateMachine.States.IDLE
	self.PreviousState = nil
	self.StatePayload = nil
	self.StateTimestamp = os.clock()

	self._listeners = {} -- array of callbacks (newState, oldState, payload)
	self._enterHooks = {} -- [state] = array of callbacks(payload)
	self._exitHooks = {} -- [state] = array of callbacks()

	return self
end

-- ============ STATE QUERIES ============
function FishingStateMachine:GetState()
	return self.CurrentState
end

function FishingStateMachine:GetPreviousState()
	return self.PreviousState
end

function FishingStateMachine:GetTimeInState()
	return os.clock() - self.StateTimestamp
end

function FishingStateMachine:Is(state)
	return self.CurrentState == state
end

function FishingStateMachine:IsBusy()
	return self.CurrentState ~= FishingStateMachine.States.IDLE
end

function FishingStateMachine:CanTransitionTo(targetState)
	if targetState == FishingStateMachine.States.IDLE then
		return true -- Selalu diizinkan reset kembali ke IDLE
	end
	local allowed = LEGAL_TRANSITIONS[self.CurrentState]
	return allowed and allowed[targetState] == true
end

-- ============ TRANSITION DISPATCHER ============
function FishingStateMachine:Transition(targetState, payload)
	if not FishingStateMachine.States[targetState] then
		warn(string.format("[FishingStateMachine] Target state '%s' tidak terdaftar!", tostring(targetState)))
		return false
	end

	if self.CurrentState == targetState then
		return true
	end

	if not self:CanTransitionTo(targetState) then
		warn(string.format("[FishingStateMachine] Transisi ilegal dari '%s' ke '%s'!", self.CurrentState, targetState))
		return false
	end

	local oldState = self.CurrentState

	-- 1. Execute Exit Hooks
	local exitList = self._exitHooks[oldState]
	if exitList then
		for _, hook in ipairs(exitList) do
			task.spawn(hook)
		end
	end

	-- 2. Update Internal State
	self.PreviousState = oldState
	self.CurrentState = targetState
	self.StatePayload = payload
	self.StateTimestamp = os.clock()

	-- 3. Execute Enter Hooks
	local enterList = self._enterHooks[targetState]
	if enterList then
		for _, hook in ipairs(enterList) do
			task.spawn(hook, payload)
		end
	end

	-- 4. Notify General Observers
	for _, cb in ipairs(self._listeners) do
		task.spawn(cb, targetState, oldState, payload)
	end

	return true
end

-- ============ FORCE RESET ============
function FishingStateMachine:ForceReset(reason)
	if self.CurrentState == FishingStateMachine.States.IDLE then return end
	print(string.format("[FishingStateMachine] Force reset dari '%s' ke IDLE. Alasan: %s", self.CurrentState, tostring(reason or "Manual Reset")))
	self:Transition(FishingStateMachine.States.IDLE, { reason = reason or "ForceReset" })
end

-- ============ SUBSCRIPTION HOOKS ============
function FishingStateMachine:OnStateChanged(callback)
	table.insert(self._listeners, callback)
	return function()
		for i, cb in ipairs(self._listeners) do
			if cb == callback then
				table.remove(self._listeners, i)
				break
			end
		end
	end
end

function FishingStateMachine:OnEnter(state, callback)
	if not self._enterHooks[state] then
		self._enterHooks[state] = {}
	end
	table.insert(self._enterHooks[state], callback)
	return function()
		local list = self._enterHooks[state]
		if list then
			for i, cb in ipairs(list) do
				if cb == callback then
					table.remove(list, i)
					break
				end
			end
		end
	end
end

function FishingStateMachine:OnExit(state, callback)
	if not self._exitHooks[state] then
		self._exitHooks[state] = {}
	end
	table.insert(self._exitHooks[state], callback)
	return function()
		local list = self._exitHooks[state]
		if list then
			for i, cb in ipairs(list) do
				if cb == callback then
					table.remove(list, i)
					break
				end
			end
		end
	end
end

return FishingStateMachine
