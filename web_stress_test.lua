require "socket"

threads = {}
thread_num = 10000
host = "192.168.226.145"
port = 80
request = "GET /index.html HTTP/1.0\r\n\r\n"
ok_num = 0


function thread_func(host, port, request)
	local conn = socket.connect(host, port)
	local count = 0
	
	conn:send(request)
	
	while true do
		local s, status, partial = receive(conn)

		count = count + #(s or partial)
		if status == "closed" 
		then
			break
		end
	end
	
	conn:close()
	ok_num = ok_num + 1
end

function receive(connection)
	connection:settimeout(0)
	
	local s, status, partial = connection:receive(1024)
	
	if status == "timeout" then
		coroutine.yield(connection)
	end
	return s, status, partial
end



function thread_pool(thread_num)
	for i = 1, thread_num, 1
	do
		local co = coroutine.create(function() thread_func(host, port, request) end)
		table.insert(threads, co)
	end
end

function run()
	local i =1
	local now_ok_num = 0
	local connections = {}
	
	thread_pool(thread_num)
	
	while true do
		if threads[i] == nil then
			if threads[1] == nil 
			then 
				io.write("<<100% done\n")
				break 
			end
			i =1
			connections = {}
		end
		
		local status, res = coroutine.resume(threads[i])
		
		if not res then
			--echo result
			now_ok_num = now_ok_num + 1
			
			if now_ok_num * 100 >= thread_num
			then
				io.write("#")
				io.flush()
				now_ok_num = 0
			end
			table.remove(threads, i)
		else 
			i = i+1
			connections[#connections + 1] = res
			if #connections == #threads then
				socket.select(connections)
			end
		end
	end
			
end

run()

