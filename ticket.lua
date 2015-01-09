local m = peripheral.find("monitor")
local p = peripheral.find("printer")
local mmaxx, mmaxy = m.getSize()
local tripfare = {"0.25", "0.40"}
local serverURL = "http://henrikvester.nu/centraldator/transfer.php"
local ownerUUID = "176326b7-474a-4125-bb70-52f3bd2921ff"
local stationName = "Highcastle Central"
local destinations = {"Aelham South"}
local tickets = {"Single", "Return"}

while true do
  m.setBackgroundColor(colors.black)
  m.setTextColor(colors.white)
  m.clear()
  m.setCursorPos(1, 1)
  if p.getInkLevel() == 0 or p.getPaperLevel() == 0 then
    m.setCursorPos(1, 3)
    m.write("OUT OF SERVICE")
    os.shutdown()
  else
    m.write("Select ticket:")
    if #tickets <= 3 then
      m.setCursorPos(1, 2)
      for i = 1, mmaxx do
        m.write("-")
      end
      for i = 1, #tickets do
        m.setCursorPos(1, i + 2)
        m.write(tickets[i])
        m.setCursorPos(mmaxx - #tripfare[i] - 1, i + 2)
        m.write("$" .. tripfare[i])
      end
      ticketOffset = 2
    elseif #tickets == 4 then
      for i = 1, #tickets do
        m.setCursorPos(1, i + 1)
        m.write(tickets[i])
        m.setCursorPos(mmaxx - #tripfare[i] - 1, i + 1)
        m.write("$" .. tripfare[i])
      end
      ticketOffset = 1
    else
      m.clear()
      m.setCursorPos(1, 3)
      m.write("OUT OF SERVICE")
      os.shutdown()
    end
    local x = 0
    local y = 0
    while not (y >= 2 and y <= #tickets + ticketOffset) do
      event, side, x, y = os.pullEvent("monitor_touch") 
    end
    local chosenTicketNo = y - ticketOffset
    local chosenTicket = tickets[y - ticketOffset]
    m.setTextColor(colors.black)
    m.setBackgroundColor(colors.white)
    m.setCursorPos(1, y)
    m.clearLine()
    m.write(chosenTicket)
    m.setCursorPos(mmaxx - #tripfare[y - ticketOffset] - 1, y)
    m.write("$" .. tripfare[y - ticketOffset])
    m.setTextColor(colors.white)
    m.setBackgroundColor(colors.black)
    sleep(1)
    m.clear()
    m.setCursorPos(1, 1)
    m.write("1 " .. tickets[chosenTicketNo] .. " = $" .. tripfare[chosenTicketNo])
    for i = 1, 4 do
      m.setCursorPos(1, i + 1)
      m.clearLine()
    end
    if #destinations <= 3 then
      m.setCursorPos(1, 2)
      m.clearLine()
      for i = 1, mmaxx do
        m.write("-")
      end
      for i = 1, #destinations do
        m.setCursorPos(1, i + 2)
        m.write(destinations[i])
      end
      destinationOffset = 2
    elseif #destinations == 4 then
      for i = 1, #destinations do
        m.setCursorPos(1, i + 1)
        m.write(destinations[i])
      end
      destinationOffset = 1
    else
      m.clear()
      m.setCursorPos(1, 3)
      m.write("OUT OF SERVICE")
      os.shutdown()
    end
    local y = 0
    local x = 0
    while not (y >= 2 and y <= #destinations + destinationOffset) do
      event, side, x, y = os.pullEvent("monitor_touch") 
    end
    local chosenDest = destinations[y - destinationOffset]
    m.setTextColor(colors.black)
    m.setBackgroundColor(colors.white)
    m.setCursorPos(1, y)
    m.clearLine()
    m.write(chosenDest)
    m.setTextColor(colors.white)
    m.setBackgroundColor(colors.black)
    sleep(1)
    m.clear()
    m.setCursorPos(1, 2)
    m.write("Total: $" .. tripfare[chosenTicketNo])
    m.setCursorPos(1, 3)
    m.write("Insert card")
    m.setCursorPos(1, 4)
    m.write("or press any key")
    os.pullEvent()
    if fs.exists("disk/card") and fs.exists("disk/pin") then
      file = fs.open("disk/card", "r")
      local uuid = file.readLine()
      file.close()
      file = fs.open("disk/pin", "r")
      local pin = file.readLine()
      file.close()
      timeout = os.startTimer(10)
      http.request(serverURL .. "?account1=" .. uuid .. "&account2=" .. ownerUUID .. "&amount=" .. tripfare[chosenTicketNo] .. "&pin=" .. pin)
      event, url, message = os.pullEvent()
      if event == "timer" then
        m.setCursorPos(1, 3)
        m.write("No connection")
      elseif event == "http_success" then
        message = message.readAll()
        if message == "nomoney" then
          m.clear()
          m.setCursorPos(1, 3)
          m.write("Not enough money")
        elseif message == "error" then
          m.clear()        
          m.setCursorPos(1, 3)
          m.write("An error occured")
        elseif message == "pin" then
          m.clear()
          m.setCursorPos(1, 3)
          m.write("Wrong pin")
        elseif message == "confirm" then
          m.clear()
          m.setCursorPos(1, 3)
          m.write("Remove card")
        else
          m.clear()
          m.setCursorPos(1, 3)
          m.write("HTTP Error")
        end
      elseif event == "http_failure" then
        m.clear()
        m.setCursorPos(1, 3)
        m.write("HTTP Error")
      else
        m.clear()
        m.setCursorPos(1, 3)
        m.write("An error occured")
      end
      p.newPage()
      p.setPageTitle("Ticket")
      p.setCursorPos(1, 1)
      p.write("Ticket")
      p.setCursorPos(1, 3)
      p.write("To: " .. chosenDest)
      p.setCursorPos(1, 4)
      p.write(string.upper(chosenTicket) .. " $" .. tripfare[chosenTicketNo])
      p.setCursorPos(1, 5)
      p.write("Issued: ")
      p.setCursorPos(1, 6)
      p.write("Day " .. os.day() .. " / " .. textutils.formatTime(os.time(), true))
      p.setCursorPos(1, 7)
      p.write(stationName)
      p.endPage()
      sleep(1)
      m.clear()
      m.setCursorPos(1, 3)
      m.write("Thank you!")
      sleep(1)
    else
      m.setCursorPos(1, 2)
      m.write("Expired card.")
      m.setCursorPos(1, 3)
      m.write("Try again.")
    end
  end
end