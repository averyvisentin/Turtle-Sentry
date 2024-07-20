local methods = peripheral.getMethods( "left" )
local file = fs.open( "output", "w" ) -- opens a file named 'output' in write mode
for k, v in pairs( methods ) do
  file.writeLine( v ) -- writes the method to a new line
end
file.close() -- closes the file (important!)