-- NETWORKING

-- A Pipe class is responsible for, somehow or other, connecting to the internet
-- and funnelling data between driver objects on different machines.

class.Pipe()

function Pipe:_init()
	self.buffer = ""
end

function Pipe:debugPrint(...)
	if pipeDebug then
		local res = {}
		for i, v in ipairs({...}) do res[i] = tostring(v) end
		print("DEBUG: " .. table.concat(res, " "))
	end
end

function Pipe:wake(server)
	self:debugPrint("Connected")
	statusMessage("Logging in to server...") -- This creates an unfortunate implicit contract where the driver needs to statusMessage(nil)
	self.server = server
	self.server:settimeout(0)

	emu.registerexit(function()
		self:exit()
	end)

	self:childWake()

	gui.register(function()
		if not self.dead then self:tick() end
		printMessage()
	end)
end

function Pipe:exit()
	if self.dead then return end
	self:debugPrint("Disconnecting")
	self.dead = true
	self.server:close()
	self:childExit()
end

function Pipe:fail(err)
	self:exit()
end

function Pipe:send(s)
	if self.dead then return false end
	self:debugPrint("SEND: " .. s)

	local res, err = self.server:send(s .. "\r\n")
	if not res then
		errorMessage("Connection died: " .. tostring(err))
		self:exit()
		return false
	end
	return true
end

function Pipe:receivePump()
	while not self.dead do -- Loop until no data left
		local result, err, partial = self.server:receive("*l")
		if not result then
			if partial and partial ~= "" then self.buffer = self.buffer .. partial end
			if err ~= "timeout" then
				errorMessage("Connection died: " .. tostring(err))
				self:exit()
			end
			return
		end

		local line = self.buffer .. result
		self.buffer = ""
		self:handle((line:gsub("\r$", "")))
	end
end

function Pipe:tick()
	self:receivePump()
	if not self.dead then self:childTick() end
end

function Pipe:childWake() end
function Pipe:childExit() end
function Pipe:childTick() end
function Pipe:handle() end

-- IRC

-- Everyone who joins the same IRC room (channel) with a compatible script plays together.
-- Each other player in the room is a "peer". Peers go through a short handshake:
--   1. "@@ <pipe version>" is sent to the room on join, and answered once by each player who
--      has not seen us yet. A peer with an incompatible version is ignored (not fatal).
--   2. Once versions match, each side sends a "hello" table (game mode guid and options).
--      A peer whose hello matches ours becomes "ready". Its game data is accepted from then on,
--      and we send it our full state so late joiners catch up.

-- Outgoing room messages are throttled so a full state sync does not get us kicked for flooding.
IRC_BURST = IRC_BURST or 5                     -- Lines that can be sent back to back
IRC_FRAMES_PER_LINE = IRC_FRAMES_PER_LINE or 20 -- After the burst, one line per this many frames (~3/sec at 60fps)

local IrcConfirm = "@@ " .. version.ircPipe

local PeerState = {pending = "pending", ready = "ready", rejected = "rejected"}

class.IrcPipe(Pipe)
function IrcPipe:_init(data, driver)
	self:super()
	self.data = data
	self.driver = driver
	self.nick = data.nick
	self.room = data.room
	self.peers = {}        -- nick -> PeerState
	self.joined = false
	self.registered = false
	self.outbox = {}       -- Throttled PRIVMSG lines
	self.tokens = IRC_BURST
	self.frames = 0
end

function IrcPipe:childWake()
	self:send("NICK " .. self.nick)
	self:send("USER " .. self.nick .. "-bot 8 * :" .. self.nick .. " (snes bot)")
	self:debugPrint("Room is", self.room)
end

function IrcPipe:childTick()
	if self.joined then
		self.driver:tick()
	end

	-- Refill send tokens and drain the outbox
	self.frames = self.frames + 1
	if self.frames >= IRC_FRAMES_PER_LINE then
		self.frames = 0
		if self.tokens < IRC_BURST then self.tokens = self.tokens + 1 end
	end
	while self.tokens > 0 and #self.outbox > 0 and not self.dead do
		self.tokens = self.tokens - 1
		self:send(table.remove(self.outbox, 1))
	end
end

function IrcPipe:abort(msg)
	self:exit()
	errorMessage(msg)
end

-- Queue a message to the room
function IrcPipe:msg(s)
	table.insert(self.outbox, "PRIVMSG " .. self.room .. " :" .. s)
end

function IrcPipe:readyPeerCount()
	local n = 0
	for _, state in pairs(self.peers) do
		if state == PeerState.ready then n = n + 1 end
	end
	return n
end

function IrcPipe:isReady(nick)
	return self.peers[nick] == PeerState.ready
end

-- When newNick just became ready, decide whether WE are the one who should
-- send full state to them. Every already-ready peer runs this same
-- computation independently (same inputs, same deterministic sort), so
-- exactly one of them ends up elected without any negotiation over the wire.
function IrcPipe:isElectedResponder(newNick)
	local candidates = {self.nick}
	for nick, state in pairs(self.peers) do
		if state == PeerState.ready and nick ~= newNick then
			table.insert(candidates, nick)
		end
	end
	table.sort(candidates)
	return candidates[1] == self.nick
end

function IrcPipe:peerReady(nick)
	if self.peers[nick] == PeerState.ready then return false end
	self.peers[nick] = PeerState.ready
	statusMessage(nil)
	message(nick .. " is playing with you (" .. self:readyPeerCount() .. " in room)")
	return true
end

function IrcPipe:rejectPeer(nick, reason)
	if self.peers[nick] == PeerState.rejected then return end
	self.peers[nick] = PeerState.rejected
	message("Ignoring " .. nick .. ": " .. reason)
end

function IrcPipe:removePeer(nick, why)
	local state = self.peers[nick]
	self.peers[nick] = nil
	if state == PeerState.ready then
		message(nick .. " " .. why .. " (" .. self:readyPeerCount() .. " left in room)")
	end
end

function IrcPipe:handleVersion(nick, msg)
	local theirIrcVersion = stringx.split(msg, nil, 2)[2]
	if not versionMatches(version.ircPipe, theirIrcVersion, true) then
		print(nick .. " is using IRC pipe version " .. tostring(theirIrcVersion) .. ", you have " .. tostring(version.ircPipe))
		self:rejectPeer(nick, "incompatible emu-coop version")
		return
	end
	if self.peers[nick] == nil then
		self:debugPrint("Handshake started with", nick)
		self.peers[nick] = PeerState.pending
		self:msg(IrcConfirm) -- Let them know about us (they ignore it if they already do)
		self.driver:greet()
	end
end

function IrcPipe:handleRoomMessage(nick, msg)
	local prefix = msg:sub(1, 2)
	if prefix == "@@" then
		self:handleVersion(nick, msg)
	elseif msg:sub(1, 1) == "#" then
		local state = self.peers[nick]
		if state == PeerState.pending or state == PeerState.ready then
			self.driver:handle(msg:sub(2), nick)
		end
	elseif prefix == "!!" then
		-- Old style matchmaking hello, nothing to do
	else
		message(nick .. "> " .. msg) -- A human chatting in the room
	end
end

function IrcPipe:handle(s)
	self:debugPrint("RECV: " .. s)

	local splits = stringx.split(s, nil, 2)
	local cmd, args = splits[1], splits[2] or ""

	if cmd == "PING" then -- On "PING :msg" respond with "PONG :msg"
		self:send("PONG " .. args)
		return
	elseif cmd == "ERROR" then
		self:abort("Server closed the connection: " .. args)
		return
	elseif cmd:sub(1, 1) ~= ":" then
		return
	end

	local source = cmd:sub(2)
	local nick = stringx.split(source, "!", 2)[1]
	local splits2 = stringx.split(args, nil, 3)
	local commandType = splits2[1]
	local target = splits2[2] or ""
	local rest = splits2[3] or ""
	local trailing = rest:match("^:(.*)$") or rest -- Text after the ":" (if any)

	self:debugPrint("Nick:", nick, "CommandType:", commandType, "Target:", target, "Rest:", rest)

	if commandType == "001" then -- RPL_WELCOME: registered, now we may join
		self.registered = true
		self.nick = target -- The server tells us our actual nick
		statusMessage("Joining " .. self.room .. "...")
		self:send("JOIN " .. self.room)

	elseif commandType == "433" and not self.registered then -- ERR_NICKNAMEINUSE
		self.nick = self.nick .. "_"
		message("Nick in use, trying " .. self.nick)
		self:send("NICK " .. self.nick)

	elseif commandType == "471" or commandType == "473" or commandType == "474" or commandType == "475" then
		self:abort("Could not join " .. self.room .. ": " .. trailing)

	elseif commandType == "JOIN" then
		local channel = target:gsub("^:", "")
		if nick == self.nick then
			if not self.joined then
				self.joined = true
				statusMessage("Joined " .. channel .. ", waiting for other players...")
				self.driver:wake(self)
				self:msg(IrcConfirm)
			end
		else
			message(nick .. " joined " .. channel)
		end

	elseif commandType == "PART" then
		self:removePeer(nick, "left")

	elseif commandType == "QUIT" then
		self:removePeer(nick, "quit")

	elseif commandType == "KICK" then
		local kicked = stringx.split(rest, nil, 2)[1]
		if kicked == self.nick then
			self:abort("You were kicked from " .. self.room)
		else
			self:removePeer(kicked, "was kicked")
		end

	elseif commandType == "NICK" then
		local newNick = target:gsub("^:", "")
		if nick == self.nick then
			self.nick = newNick
		elseif self.peers[nick] then
			self.peers[newNick] = self.peers[nick]
			self.peers[nick] = nil
			message(nick .. " is now " .. newNick)
		end

	elseif commandType == "PRIVMSG" then
		if target:lower() == self.room:lower() then
			self:handleRoomMessage(nick, trailing)
		end

	elseif commandType == "TOPIC" then
		message("Topic in " .. target .. " changed to " .. trailing)

	elseif commandType == "332" then -- Topic on join: ":server 332 me #room :topic"
		local topicText = rest:match("^%S+%s+:(.*)$")
		if topicText then message("Topic is " .. stringx.strip(topicText)) end
	end
end

-- Driver base class-- knows how to convert to/from tables

-- Lines longer than this are split up (IRC lines are limited to 512 bytes including the prefix)
DRIVER_MAX_PAYLOAD = DRIVER_MAX_PAYLOAD or 380

class.Driver()
function Driver:_init() end

function Driver:wake(pipe)
	self.pipe = pipe
	self.pending = {} -- Tables waiting to be sent, packed into as few lines as possible
	self:childWake()
end

-- Queue a table for the room. Nothing is sent while nobody else is in the room.
function Driver:sendTable(t, always)
	if not always and self.pipe:readyPeerCount() == 0 then return end
	table.insert(self.pending, t)
end

-- Pack queued tables into lines: one table on its own, several as {"batch", t1, t2, ...}
function Driver:flush()
	local batch = {}
	local function emit()
		if #batch == 1 then
			self.pipe:msg("#" .. pretty.write(batch[1], ''))
		elseif #batch > 1 then
			table.insert(batch, 1, "batch")
			self.pipe:msg("#" .. pretty.write(batch, ''))
		end
		batch = {}
	end
	for _, t in ipairs(self.pending) do
		table.insert(batch, t)
		local size = #pretty.write(#batch == 1 and batch[1] or {"batch", unpack(batch)}, '')
		if size > DRIVER_MAX_PAYLOAD and #batch > 1 then
			table.remove(batch)
			emit()
			table.insert(batch, t)
		end
	end
	emit()
	self.pending = {}
end

function Driver:handle(s, from)
	local t, err = pretty.read(s)
	if driverDebug then print("Driver got table from " .. tostring(from) .. ": " .. s) end
	if type(t) ~= "table" then
		self:handleFailure(s, err)
	elseif t[1] == "batch" then
		for i = 2, #t do self:handleTable(t[i], from) end
	else
		self:handleTable(t, from)
	end
end

function Driver:tick()
	self:childTick()
	self:flush()
end

function Driver:greet() end
function Driver:childWake() end
function Driver:childTick() end
function Driver:handleTable(t, from) end
function Driver:handleFailure(s, err) end
