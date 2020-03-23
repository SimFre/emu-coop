-- NETWORKING

-- A Pipe class is responsible for, somehow or other, connecting to the internet
-- and funnelling data between driver objects on different machines.

class.Pipe()

function Pipe:_init()
	self.buffer = ""
end

function Pipe:debugPrint(...)
  if pipeDebug then
  	local arg = {...}
  	local res = ""
  	for i,v in ipairs(arg) do
  	  res = res .. " " .. v
  	end
		print("DEBUG: ", res)
	end
end

function Pipe:wake(server)
	Pipe:debugPrint("Connected")
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
	Pipe:debugPrint("Disconnecting")
	self.dead = true
	self.server:close()
	self:childExit()
end

function Pipe:fail(err)
	self:exit()
end

function Pipe:send(s)
	Pipe:debugPrint("SEND: " .. s)

	local res, err = self.server:send(s .. "\r\n")
	if not res then
		errorMessage("Connection died: " .. s)
		self:exit()
		return false
	end
	return true
end

function Pipe:receivePump()
	while not self.dead do -- Loop until no data left
		local result, err = self.server:receive(1) -- Pull one byte
		if not result then
			if err ~= "timeout" then
				errorMessage("Connection died: " .. err)
				self:exit()
			end
			return
		end

		-- Got useful data
		self.buffer = self.buffer .. result
		if result == "\n" then -- Only 
			self:handle(self.buffer)
			self.buffer = ""
		end
	end
end

function Pipe:tick()
	self:receivePump()
	self:childTick()
end

function Pipe:childWake() end
function Pipe:childExit() end
function Pipe:childTick() end
function Pipe:handle() end

-- IRC

-- TODO: nickserv, reconnect logic, multiline messages

local IrcState = {login = 1, searching = 2, handshake = 3, piping = 4, aborted=5}
local IrcHello = "!! Hi, I'm a matchmaking bot for SNES games. This user thinks you're running the same bot and typed in your nick. If you're a human and seeing this, they made a mistake!"
local IrcConfirm = "@@ " .. version.ircPipe
local IrcComm = "undefined" -- user or channel

class.IrcPipe(Pipe)
function IrcPipe:_init(data, driver)
	self:super()
	self.data = data
	self.driver = driver
	self.state = IrcState.login
	self.sentVersion = false
end

function IrcPipe:childWake()
	self:send("NICK " .. self.data.nick)
	self:send("USER " .. self.data.nick .."-bot 8 * : " .. self.data.nick .. " (snes bot)")
	if self.data.partner:sub(1,1) == "#" then
		IrcComm = "channel"
		self:send("JOIN " .. self.data.partner)
	else
		IrcComm = "user"
	end
	Pipe:debugPrint("Partner is", IrcComm, self.data.partner)
end

function IrcPipe:childTick()
	if self.state == IrcState.piping then
		self.driver:tick()
	end
end

function IrcPipe:abort(msg)
	self.state = IrcState.aborted -- FIXME: I guess this is maybe redundant with .dead?
	self:exit()
	errorMessage(msg)
end

function IrcPipe:handle(s)
	Pipe:debugPrint("RECV: " .. s)

	splits = stringx.split(s, nil, 2)
	local cmd, args = splits[1], splits[2]

	if cmd == "PING" then -- On "PING :msg" respond with "PONG :msg"
		Pipe:debugPrint("Handling ping")
		self:send("PONG " .. args)

	elseif cmd:sub(1,1) == ":" then -- A message from a server or user
		local source = cmd:sub(2)
		local nick = stringx.split(source, "!", 2)[1]
		local splits2 = stringx.split(args, nil, 3)
		local commandType = splits2[1]
		local recipient = splits2[2]
		local msg = ""
		if splits2[3] ~= nil then
			msg = splits2[3]:sub(2)
		end
		
		-- You joined channel
		if commandType == "JOIN" and source == self.data.me then
			local channel = recipient:sub(2)
			statusMessage("You joined " .. channel)
			self.state = IrcState.handshake
			-- self:msg(IrcHello)
			self:msg(IrcConfirm)

		-- Someone else joined channel
		elseif commandType == "JOIN" and source ~= self.data.me then
			local channel = recipient:sub(2)
			statusMessage(nick .. " has joined " .. channel)
			self:msg(IrcConfirm)

		-- Someone left a channel
		elseif commandType == "PART" then
			statusMessage(nick .. " left " .. recipient)

		-- Someone quit
		elseif commandType == "QUIT" then
			msg = splits2[3]
			statusMessage(nick .. " quit: (" .. msg .. ")")

		-- A mode is set
		elseif commandType == "MODE" then
			local msg = splits2[3]:sub(1)
			if self.data.me == nil and string.sub(source,1,#self.data.nick) == self.data.nick then
				self.data.me = source
			end

		-- Incomming message
		elseif commandType == "PRIVMSG" then
			-- Pipe:debugPrint("Handshake started")
			if recipient == self.data.partner then
				
				if self.state == IrcState.piping then       -- Message with payload
						if msg:sub(1,1) == "#" then
							self.driver:handle(msg:sub(2))
						end
				else -- handshake
					local prefix = msg:sub(1,2)
					local exclaim = prefix == "!!"
					local confirm = prefix == "@@" 
					if exclaim or confirm then
						if not self.sentVersion then
							Pipe:debugPrint("Handshake started")
							self:msg(IrcConfirm)
							self.sentVersion = true
						end

						if confirm then
							local splits3 = stringx.split(msg, nil, 2)
							local theirIrcVersion = splits3[2]
							if not versionMatches(version.ircPipe, theirIrcVersion) then
								self:abort("Your partner's emulator version is incompatible")
								print("Other user is using IRC pipe version " .. tostring(theirIrcVersion) .. ", you have " .. tostring(version.ircPipe))
							else
								Pipe:debugPrint("Handshake finished")
								statusMessage(nil)
								message("Connected to partner")

								self.state = IrcState.piping
								self.driver:wake(self)
							end
						end
					elseif msg:sub(1,1) == "#" then
						self:abort("Tried to connect, but your partner is already playing the game! Try resetting?")
					else
						statusMessage(nick.."> " .. msg)
						-- self:abort("Your partner's emulator responded in... English? You probably typed the wrong nick!")
					end
				end -- end of handshake

			end

		-- Topic changed
		elseif commandType == "TOPIC" then
			statusMessage("Topic in " .. recipient .. " changed to " .. msg)
		
		-- Channel topic join message
		elseif commandType == "332" then
			local t = stringx.split(msg, " :", 2)
			local topicUser = t[1]
			local topicText = stringx.strip(t[2])
			statusMessage("Topic is " .. topicText .. " set by " .. topicUser)
		end

		Pipe:debugPrint("Nick:", nick, "FullNick:", source, "CommandType:", commandType, "Recipient:", recipient, "Message:", msg)

		-- print(self.state .. " " .. string.sub(source,1,#self.data.nick) .. " " .. self.data.server)
		if self.state == IrcState.login then
			if string.sub(source,1,#self.data.nick) == self.data.nick then -- This is the initial mode set from the server, we are logged in
				Pipe:debugPrint("Logged in to server")
				self.state = IrcState.searching
				-- self:whoisCheck()
			end
		else

			
			if self.state == IrcState.searching and source == self.data.server then
				local splits2 = stringx.split(args, nil, 2)
				local msg = tonumber(splits2[1])
				Pipe:debugPrint("Message ID: ", msg)
				
				-- Whois response
				if msg and msg >= 311 and msg <= 317 then
					Pipe:debugPrint("Whois response")

					statusMessage("Connecting to partner...")
					self.state = IrcState.handshake
					self:msg(IrcHello)

				end
			end
		end
	end
end

function IrcPipe:whoisCheck() -- TODO: Check on timer
	self:send("WHOIS " .. self.data.partner)
	statusMessage("Searching for partner...")
end

function IrcPipe:msg(s)
	self:send("PRIVMSG " .. self.data.partner .. " :" .. s)
end

-- Driver base class-- knows how to convert to/from tables

class.Driver()
function Driver:_init() end

function Driver:wake(pipe)
	self.pipe = pipe
	self:childWake()
end

function Driver:sendTable(t)
	local s = pretty.write(t, '')
	self.pipe:msg("#" .. s)
end

function Driver:handle(s)
	local t, err = pretty.read(s)
	if driverDebug then print("Driver got table " .. tostring(t)) end
	if t then
		self:handleTable(t)
	else
		self.handleFailure(s, err)
	end
end

function Driver:tick()
	self:childTick()
end

function Driver:childWake() end
function Driver:childTick() end
function Driver:handleTable(t) end
function Driver:handleFailure(s, err) end
