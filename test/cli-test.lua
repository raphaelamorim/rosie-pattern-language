---- -*- Mode: Lua; -*-                                                                           
----
---- cli-test.lua      sniff test for the CLI
----
---- © Copyright IBM Corporation 2016.
---- LICENSE: MIT License (https://opensource.org/licenses/mit-license.html)
---- AUTHOR: Jamie A. Jennings

util = require "util"
require "test-functions"
check = test.check

test.start(test.current_filename())

infilename = "/tmp/rosietestinputfile"

rosie = ROSIE_HOME .. "/run"
input = [[
#
# This file is automatically generated on OSX.
#
search nc.rr.com
nameserver 10.0.1.1
nameserver 2606:a000:1120:8152:2f7:6fff:fed4:dc1f
/usr/share/bin/foo
jjennings@us.ibm.com
]]

f, msg = io.open(infilename, "w")
if (not f) then
   error("Could not create the input file for this test: " .. tostring(msg))
end
f:write(input)
f:close()

print("Input file (" .. infilename .. ") created successfully")

function run(expression, grep_flag, expectations)
   test.heading(expression)
   test.subheading((grep_flag and "Using grep option") or "No grep option")
   local verb = (grep_flag and "Grepping for") or "Matching"
   print("\nSTART ----------------- " .. verb .. " '" .. expression .. "' against fixed input -----------------")
   local grep = (grep_flag and " -grep") or ""
   local cmd = rosie .. grep .. " '" .. expression .. "' " .. infilename
   local results, status, code = util.os_execute_capture(cmd, nil, "l")
   if not results then error("Run failed: " .. tostring(status) .. ", " .. tostring(code)); end
   local mismatch_flag = false;
   for i=1, #results do 
      print(results[i])
      if expectations then
	 if results[i]~=expectations[i] then print("Mismatch"); mismatch_flag = true; end
      end
   end -- for
   if expectations then
      if mismatch_flag then
	 print("********** SOME MISMATCHED OUTPUT WAS FOUND. **********");
      else
	 print("END ----------------- All output matched expectations. -----------------");
      end
      if (not (#results==#expectations)) then
	 print(string.format("********** Mismatched number of results (%d) versus expectations (%d) **********", #results, #expectations))
      end
      check((not mismatch_flag), "Mismatched output compared to expectations", 1)
   end -- if expectations
   return results
end

results_basic_matchall = 
   {"\27[30m#\27[0m ",
    "\27[30m#\27[0m \27[33mThis\27[0m \27[33mfile\27[0m \27[33mis\27[0m \27[33mautomatically\27[0m \27[33mgenerated\27[0m \27[33mon\27[0m \27[36mOSX\27[0m \27[30m.\27[0m ",
    "\27[30m#\27[0m ",
    "\27[33msearch\27[0m \27[31mnc.rr.com\27[0m ",
    "\27[33mnameserver\27[0m \27[31m10.0.1.1\27[0m ",
    "\27[33mnameserver\27[0m \27[4m2606\27[0m \27[30m:\27[0m \27[4ma000\27[0m \27[30m:\27[0m \27[4m1120\27[0m \27[30m:\27[0m \27[4m8152\27[0m \27[30m:\27[0m \27[4m2f7\27[0m \27[30m:\27[0m \27[4m6fff\27[0m \27[30m:\27[0m \27[4mfed4\27[0m \27[30m:\27[0m \27[4mdc1f\27[0m ",
    "\27[32m/usr/share/bin/foo\27[0m ",
    "\27[31mjjennings@us.ibm.com\27[0m "}

results_common_word =
   {"\27[33msearch\27[0m ",
    "\27[33mnameserver\27[0m ",
    "\27[33mnameserver\27[0m ",
    "\27[33mjjennings\27[0m "}

results_common_word_grep = 
   {"\27[33mThis\27[0m \27[33mfile\27[0m \27[33mis\27[0m \27[33mautomatically\27[0m \27[33mgenerated\27[0m \27[33mon\27[0m \27[33mOSX\27[0m ",
    "\27[33msearch\27[0m \27[33mnc\27[0m \27[33mrr\27[0m \27[33mcom\27[0m ",
    "\27[33mnameserver\27[0m ",
    "\27[33mnameserver\27[0m \27[33ma\27[0m \27[33mf\27[0m \27[33mfff\27[0m \27[33mfed\27[0m \27[33mdc\27[0m \27[33mf\27[0m ",
    "\27[33musr\27[0m \27[33mshare\27[0m \27[33mbin\27[0m \27[33mfoo\27[0m ",
    "\27[33mjjennings\27[0m \27[33mus\27[0m \27[33mibm\27[0m \27[33mcom\27[0m "}

results_word_network = 
   {"\27[33msearch\27[0m \27[31mnc.rr.com\27[0m ",
    "\27[33mnameserver\27[0m \27[31m10.0.1.1\27[0m "}

results_common_number =
   {"\27[4m10.0\27[0m \27[4m1.1\27[0m ",
    "\27[4m2606\27[0m \27[4ma000\27[0m \27[4m1120\27[0m \27[4m8152\27[0m \27[4m2f7\27[0m \27[4m6fff\27[0m \27[4mfed4\27[0m \27[4mdc1f\27[0m "}

run("basic.matchall", nil, results_basic_matchall)
run("common.word", nil, results_common_word)
run("common.word", true, results_common_word_grep)
run("common.word basic.network_patterns", nil, results_word_network)
run("~common.number~", true, results_common_number)

return test.finish()
