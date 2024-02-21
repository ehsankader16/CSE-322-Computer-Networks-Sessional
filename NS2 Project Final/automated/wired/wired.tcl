if {$argc != 4} {
    puts "Usage: ns $argv0 <aqmrd?> <number_of_nodes> <number_of_flows> <packets_per_second>"
    exit 1
}


set ns [new Simulator]

#======================
# define options
set val(aqmrd) [lindex $argv 0] 
set val(nn) [lindex $argv 1]
set val(nf) [lindex $argv 2]
set val(pps) [lindex $argv 3]
set val(qlimit) 30
set val(sim_start) 0.5
set val(sim_end) 50
set val(aqmrd_w) 0.002 
#======================

Queue/RED set thresh_queue_ 6
Queue/RED set maxthresh_queue_ 18
Queue/RED set bytes_ false
Queue/RED set queue_in_bytes_ false
Queue/RED set gentle_ false
Queue/RED set aqmrd_ $val(aqmrd)
Queue/RED set q_aqmrd_w_ $val(aqmrd_w)


set namFile [open animation.nam w]
$ns namtrace-all $namFile
set traceFile [open trace.tr w]
$ns trace-all $traceFile

set node_(r1) [$ns node]
set node_(r2) [$ns node]

set val(nn) [expr {$val(nn) - 2}]



expr srand(67)

for {set i 0} {$i < [expr {$val(nn) / 2}]} {incr i} {
    set node_(s$i) [$ns node]
    $ns duplex-link $node_(s$i) $node_(r1) 10Mb 2ms DropTail
}

$ns duplex-link $node_(r1) $node_(r2) 1.5Mb 20ms RED 
$ns queue-limit $node_(r1) $node_(r2) $val(qlimit)
$ns queue-limit $node_(r2) $node_(r1) $val(qlimit)

for {set i 0} {$i < [expr {$val(nn) / 2}]} {incr i} {
    set node_(d$i) [$ns node]
    $ns duplex-link $node_(d$i) $node_(r2) 10Mb 2ms DropTail
}

$ns duplex-link-op $node_(r1) $node_(r2) orient right
$ns duplex-link-op $node_(r1) $node_(r2) queuePos 0
$ns duplex-link-op $node_(r2) $node_(r1) queuePos 0

for {set i 0} {$i < $val(nf)} {incr i} {
    set source [expr int(rand() * ($val(nn)/2))]
    set dest [expr int(rand() * ($val(nn)/2))]
    set tcp_($i) [new Agent/TCP]
    set sink_($i) [new Agent/TCPSink]
    $ns attach-agent $node_(s$source) $tcp_($i)
    $ns attach-agent $node_(d$dest) $sink_($i)

    $tcp_($i) set window_ [expr 10 *($val(pps) / 100)]

    $ns connect $tcp_($i) $sink_($i)
    $tcp_($i) set fid_ $i

    set ftp_($i) [new Application/FTP]
    $ftp_($i) attach-agent $tcp_($i)
}
puts "all agents attached"
for {set i 0} {$i < $val(nf)} {incr i} {
    $ns at $val(sim_start) "$ftp_($i) start"
    $ns at $val(sim_end) "$ftp_($i) stop"
}

$ns at $val(sim_end) "finish"

# Define 'finish' procedure (include post-simulation processes)
proc finish {} {
    exit 0
}

puts "Everything ok, starting simulation"

$ns run
