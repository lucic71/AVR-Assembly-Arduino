# Connect to simavr server
target remote :1234

# Print the registers and code at each step
def hook-stop
i r
disass
end

# Here you can put a breakpoint to skip some code
b ENCODE
