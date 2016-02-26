
--uart  disable output
--node.output(function(str) end,0)
sBuf=""
function s_output(d)
	sBuf = sBuf..d;
	tmr.stop(4)
	tmr.alarm(4,100,0,function()
		--print('Uart: '..sBuf)
		if flagConnected==true then
			local str = 'cmd=m2m_chat&device_id='..cfg.id..'&device_key='..cfg.key..'&topic='..cfg.id..'_chat&message='..sBuf..'\r\n'
			local str2="m2m_chat:("..(tmr.now()/1000).."ms) "
			conn:send(str)
			print(str2..str)
			str = nil;str2=nil;
		end
		sBuf = ""
	end);
	d=nil; 
	collectgarbage();
end
uart.on("data",0,s_output, 0)

print('doNetTask')
tmr.stop(2) --stop keycheck

--tcp client
print("Start TCP Client");
flagConnected=false;
cnt = 0;
tmr.alarm(0, 5000, 1, function()
	if flagConnected==false then
	print("Try connect Server")
	conn = nil
	conn=net.createConnection(net.TCP, false)--创建一个client
	conn:connect(cfg.port,cfg.domain);--连接至远端
	conn:on("connection",function(c)--向事件注册回调函数，事件可为"connection", "reconnection", "disconnection", "receive", "sent"
		print("TCPClient:conneted to server");
		flagConnected = true;
		c:send('cmd=subscribe&device_id='..cfg.id..'&device_key='..cfg.key..'\r\n')
		end)
	conn:on("disconnection",function(c) 
		flagConnected = false;
		conn=nil;
		collectgarbage();
    end)
	conn:on("receive", function(conn, m) 
		parseData(net.TCP,conn,m)
		collectgarbage();
		end)
	end 
	if flagConnected == true then
		cnt=cnt+1;--保持心跳
		if cnt>=5*60/5 then
		cnt = 0;
		local str = 'cmd=keep&device_id='..cfg.id..'&device_key='..cfg.key..'\r\n'
		local str2="keep:("..(tmr.now()/1000).."ms)"
		conn:send(str)
		print(str2..str)
		str = nil;str2=nil;
		collectgarbage();
		end
	end
end)
