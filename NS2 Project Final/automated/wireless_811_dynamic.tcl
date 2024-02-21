if {$argc != 6} {
    puts "Usage: ns $argv0 <aqmrd?> <number_of_nodes> <number_of_flows> <packets_per_sec> <speed> <coverage area coefficient>"
    exit 1
}
set ns [new Simulator]


# ======================================================================
# Define options

set val(chan)         Channel/WirelessChannel  ;# channel type
set val(prop)         Propagation/TwoRayGround ;# radio-propagation model
set val(ant)          Antenna/OmniAntenna      ;# Antenna type
set val(ll)           LL                       ;# Link layer type
set val(ifq)          Queue/RED  ;# Interface queue type
set val(ifqlen)       50                       ;# max packet in ifq
set val(netif)        Phy/WirelessPhy ;# network interface type
set val(mac)          Mac/802_11               ;# MAC type
set val(rp)           DSDV                      ;# ad-hoc routing protocol 
set val(aqmrd)        [lindex $argv 0]
set val(dimension)    1000
set val(nn)           [lindex $argv 1]
set val(nx)           10
set val(nf)           [lindex $argv 2]
set val(pps)          [lindex $argv 3]
set speed             [lindex $argv 4]
set val(coverageConstant)     [lindex $argv 5]
set val(ny)           [expr {$val(nn)/$val(nx)}]
set val(energymodel)   EnergyModel
set val(initialenergy) 12.0                     ;
set val(qthresh)       16
set val(qmaxthresh)    48 
set val(aqmrd_w)       0.002 

# =======================================================================
set val(width)		$val(dimension)                          
set val(height)		$val(dimension)  
set currentValue  [Phy/WirelessPhy set Pt_]            
set newValue_Pt   [expr $val(coverageConstant) * $val(coverageConstant) * $currentValue]
Phy/WirelessPhy set Pt_  $newValue_Pt;   
# puts "value: $newValue_Pt"
Queue/RED set aqmrd_ $val(aqmrd)
Queue/RED set q_aqmrd_w_ $val(aqmrd_w)
Queue/RED set thresh_queue_ $val(qthresh)
Queue/RED set maxthresh_queue_ $val(qmaxthresh)
Queue/RED set bytes_ false
Queue/RED set queue_in_bytes_ false
Queue/RED set gentle_ false

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
                -movementTrace OFF \
                -energyModel $val(energymodel) \
                -initialEnergy $val(initialenergy) \
                -rxPower 1.0 \
                -txPower 1.0 \
                -idlePower 0.01 \
                -sleepPower 0.001 
                

# create nodes
expr srand(67)

for {set i 0} {$i < $val(nx)} {incr i} {
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
    set destY [expr {int(rand() * ($val(height)-1))+1}]                    ;# random destination y                             ;# random speed
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

    $tcp($i) set maxseq_ $val(pps)
    # connect agents
    $ns connect $tcp($i) $tcp_sink($i)
    $tcp($i) set fid_ $i

    # Traffic generator
    set ftp($i) [new Application/FTP]
    # attach to agent
    $ftp($i) attach-agent $tcp($i)
    
    # start traffic generation
    $ns at 1.0 "$ftp($i) start"
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