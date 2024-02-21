#!/bin/bash

node_default=$((40))
flow_default=$((20))
packet_default=$((200))
unmodified=$((0))
modified=$((1))

tcl_file_to_run="wired.tcl"

node_result_file="results/node.out"
flow_result_file="results/flow.out"
packet_result_file="results/packet.out"

node_result_file_mod="results/node-modified.out"
flow_result_file_mod="results/flow-modified.out"
packet_result_file_mod="results/packet-modified.out"

# $node_default $flow_default $packet_default $speed_default

# Varying nodes
>$node_result_file
>$node_result_file_mod
for i in 20 40 60 80 100
do
    echo "node $i " >> $node_result_file
    echo "node $i " >> $node_result_file_mod
    echo testing "$tcl_file_to_run" $unmodified $i $flow_default $packet_default 
    ns "$tcl_file_to_run" $unmodified $i $flow_default $packet_default 
    awk -f parse.awk trace.tr >> $node_result_file
    echo testing "$tcl_file_to_run" $modified $i $flow_default $packet_default 
    ns "$tcl_file_to_run" $modified $i $flow_default $packet_default 
    awk -f parse.awk trace.tr >> $node_result_file_mod
done

# Varying flows
>$flow_result_file
>$flow_result_file_mod
for i in 10 20 30 40 50
do
    echo "flow $i " >> $flow_result_file
    echo "flow $i " >> $flow_result_file_mod
    echo testing "$tcl_file_to_run" $unmodified $node_default $i $packet_default 
    ns "$tcl_file_to_run" $unmodified $node_default $i $packet_default 
    awk -f parse.awk trace.tr >> $flow_result_file
    echo testing "$tcl_file_to_run" $modified $node_default $i $packet_default 
    ns "$tcl_file_to_run" $modified $node_default $i $packet_default  
    awk -f parse.awk trace.tr >> $flow_result_file_mod
done

# Varying packet rate
>$packet_result_file
>$packet_result_file_mod
for i in 100 200 300 400 500
do
    echo "packet $i " >> $packet_result_file
    echo "packet $i " >> $packet_result_file_mod
    echo testing "$tcl_file_to_run" $unmodified $node_default $flow_default $i
    ns "$tcl_file_to_run" $unmodified $node_default $flow_default $i
    awk -f parse.awk trace.tr >> $packet_result_file
    echo testing "$tcl_file_to_run" $modified $node_default $flow_default $i
    ns "$tcl_file_to_run" $modified $node_default $flow_default $i 
    awk -f parse.awk trace.tr >> $packet_result_file_mod
done



python3 mergedGraphGenerator.py $node_result_file $node_result_file_mod "node"
python3 mergedGraphGenerator.py $flow_result_file $flow_result_file_mod "flow"
python3 mergedGraphGenerator.py $packet_result_file $packet_result_file_mod "packet"

