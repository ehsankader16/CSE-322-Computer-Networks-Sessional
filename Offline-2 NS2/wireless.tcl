# simulator
set ns [new Simulator]


# ======================================================================
# Define options

set val(chan)         Channel/WirelessChannel  ;# channel type
set val(prop)         Propagation/TwoRayGround ;# radio-propagation model
set val(ant)          Antenna/OmniAntenna      ;# Antenna type
set val(ll)           LL                       ;# Link layer type
set val(ifq)          CMUPriQueue  ;# Interface queue type
set val(ifqlen)       50                       ;# max packet in ifq
set val(netif)        Phy/WirelessPhy ;# network interface type
set val(mac)          Mac/802_11               ;# MAC type
set val(rp)           DSR                      ;# ad-hoc routing protocol 
set val(nn)           40                       ;# number of mobilenodes
set val(nf)           50                       ;# number of flows
# set val(energyModel)  EnergyModel
# set val(initialEnergy) 3.0                     ;
# set val(txPower)       0.9                     ; 
# set val(rxPower)       0.5                     ;
# set val(idlePower)     0.45                    ;
# set val(sleepPower)    0.05                    ;
# =======================================================================
set val(width)		500                           
set val(height)		500    
set val(nx)         8                ;# number of columns
set val(ny)         5                ;# number of rows                        
# trace file
set trace_file [open trace.tr w]
$ns trace-all $trace_file
# $ns use-newtrace

# nam file
set nam_file [open animation.nam w]
$ns namtrace-all-wireless $nam_file 1000 1000

# topology: to keep track of node movements
set topo [new Topography]
$topo load_flatgrid $val(width) $val(height) ;# width m x height m area


# general operation director for mobilenodes
create-god $val(nn)


# node configs
# ======================================================================

# $ns node-config -addressingType flat or hierarchical or expanded
#                  -adhocRouting   DSDV or DSR or TORA
#                  -llType	   LL
#                  -macType	   Mac/802_11
#                  -propType	   "Propagation/TwoRayGround"
#                  -ifqType	   "Queue/DropTail/PriQueue"
#                  -ifqLen	   50
#                  -phyType	   "Phy/WirelessPhy"
#                  -antType	   "Antenna/OmniAntenna"
#                  -channelType    "Channel/WirelessChannel"
#                  -topoInstance   $topo
#                  -energyModel    "EnergyModel"
#                  -initialEnergy  (in Joules)
#                  -rxPower        (in W)
#                  -txPower        (in W)
#                  -agentTrace     ON or OFF
#                  -routerTrace    ON or OFF
#                  -macTrace       ON or OFF
#                  -movementTrace  ON or OFF

# ======================================================================

# $ns node-config -adhocRouting $val(rp) \
#                 -llType $val(ll) \
#                 -macType $val(mac) \
#                 -ifqType $val(ifq) \
#                 -ifqLen $val(ifqlen) \
#                 -antType $val(ant) \
#                 -propType $val(prop) \
#                 -phyType $val(netif) \
#                 -topoInstance $topo \
#                 -channelType $val(chan) \
#                 -agentTrace ON \
#                 -routerTrace ON \
#                 -macTrace OFF \
#                 -movementTrace OFF \
#                 -energyModel $val(energyModel) \
#                 -initialEnergy $val(initialEnergy) \
#                 -txPower $val(txPower) \
#                 -rxPower $val(rxPower) \
#                 -idlePower $val(idlePower) \
#                 -sleepPower $val(sleepPower) \

$ns node-config -adhocRouting $val(rp) \
                -llType $val(ll) \
                -macType $val(mac) \
                -ifqType $val(ifq) \
                -ifqLen $val(ifqlen) \
                -antType $val(ant) \
                -propType $val(prop) \
                -phyType $val(netif) \
                -topoInstance $topo \
                -channelType $val(chan) \
                -agentTrace ON \
                -routerTrace ON \
                -macTrace OFF \
                -movementTrace OFF
                

# create nodes

for {set i 0} {$i < $val(nx) } {incr i} {
	for {set j 0} {$j < $val(ny) } {incr j} {
		
		set node([expr {$i*$val(ny)+$j}]) [$ns node]

		$node([expr {$i*$val(ny)+$j}]) random-motion  1   ;# disable random motion
		$node([expr {$i*$val(ny)+$j}]) set X_ [expr ($val(width) * $i) / $val(nx)]
		$node([expr {$i*$val(ny)+$j}]) set Y_ [expr ($val(height) * $j) / $val(ny)]
		$node([expr {$i*$val(ny)+$j}]) set Z_ 0

		$ns initial_node_pos $node([expr {$i*$val(ny)+$j}]) 20
	}
} 
#random motion
for {set i 0} {$i < $val(nn)} {incr i} {
    set destX [expr {int(rand() * ($val(width)-1))+1}]                     ;# random destination x
    set destY [expr {int(rand() * ($val(height)-1))+1}]                    ;# random destination y 
    set speed [expr {int((rand() * 4) + 1)}]                               ;# random speed
    $ns at 1 "$node($i) setdest $destX $destY $speed" 
}


# Traffic

for {set i 0} {$i < $val(nf) } {incr i} {
    set src [expr {int(rand() * $val(nn))}]
    set dest [expr {int(rand() * $val(nn))}]
    if {$src == $dest} {
        set i [expr {$i - 1}]
        continue
    }

    # Traffic config
    # create agent]
    set tcp($i) [new Agent/TCP]
    set tcp_sink($i) [new Agent/TCPSink]
    # attach to nodes
    $ns attach-agent $node($src) $tcp($i)
    $ns attach-agent $node($dest) $tcp_sink($i)
    # connect agents
    $ns connect $tcp($i) $tcp_sink($i)
    $tcp($i) set fid_ $i

    # Traffic generator
    set telnet($i) [new Application/Telnet]
    # attach to agent
    $telnet($i) attach-agent $tcp($i)
    
    # start traffic generation
    $ns at 1.0 "$telnet($i) start"
}



# End Simulation

# Stop nodes
for {set i 0} {$i < $val(nn)} {incr i} {
    $ns at 50.0 "$node($i) reset"
}

# call final function
proc finish {} {
    global ns trace_file nam_file
    $ns flush-trace
    close $trace_file
    close $nam_file
}

proc halt_simulation {} {
    global ns
    puts "Simulation ending"
    $ns halt
}

$ns at 50.0001 "finish"
$ns at 50.0002 "halt_simulation"

# Run simulation
puts "Simulation starting"
$ns run

