#!/usr/bin/env python3
import argparse
import grpc
import os
import sys
from time import sleep

# Import P4Runtime lib from parent utils dir
# Probably there's a better way of doing this.
sys.path.append(
    os.path.join(os.path.dirname(os.path.abspath(__file__)),
                 '../../utils/'))
import p4runtime_lib.bmv2
from p4runtime_lib.switch import ShutdownAllSwitchConnections
import p4runtime_lib.helper

def readTableRules(p4info_helper, sw):
    """
    Reads the table entries from all tables on the switch.

    :param p4info_helper: the P4Info helper
    :param sw: the switch connection
    """
    print('\n----- Reading tables rules for %s -----' % sw.name)
    for response in sw.ReadTableEntries():
        for entity in response.entities:
            entry = entity.table_entry
            # TODO For extra credit, you can use the p4info_helper to translate
            #      the IDs in the entry to names
            table_name = p4info_helper.get_tables_name(entry.table_id)
            print('%s: ' % table_name, end=' ')
            for m in entry.match:
                print(p4info_helper.get_match_field_name(table_name, m.field_id), end=' ')
                print('%r' % (p4info_helper.get_match_field_value(m),), end=' ')
            action = entry.action.action
            action_name = p4info_helper.get_actions_name(action.action_id)
            print('->', action_name, end=' ')
            for p in action.params:
                print(p4info_helper.get_action_param_name(action_name, p.param_id), end=' ')
                print('%r' % p.value, end=' ')
            print()

def printCounter(p4info_helper, sw, counter_name, index):
    """
    Reads the specified counter at the specified index from the switch. In our
    program, the index is the tunnel ID. If the index is 0, it will return all
    values from the counter.

    :param p4info_helper: the P4Info helper
    :param sw:  the switch connection
    :param counter_name: the name of the counter from the P4 program
    :param index: the counter index (in our case, the tunnel ID)
    """
    for response in sw.ReadCounters(p4info_helper.get_counters_id(counter_name), index):
        for entity in response.entities:
            counter = entity.counter_entry
            print("%s %s %d: %d packets (%d bytes)" % (
                sw.name, counter_name, index,
                counter.data.packet_count, counter.data.byte_count
            ))

def printGrpcError(e):
    print("gRPC Error:", e.details(), end=' ')
    status_code = e.code()
    print("(%s)" % status_code.name, end=' ')
    traceback = sys.exc_info()[2]
    print("[%s:%d]" % (traceback.tb_frame.f_code.co_filename, traceback.tb_lineno))

def main(p4info_file_path, bmv2_file_path):
    # Instantiate a P4Runtime helper from the p4info file
    p4info_helper = p4runtime_lib.helper.P4InfoHelper(p4info_file_path)

    try:
        sleep(5)
        print("Setting Pipeline Config...")
        # Create a switch connection object for s1 and s2;
        # this is backed by a P4Runtime gRPC connection.
        # Also, dump all P4Runtime messages sent to switch to given txt files.
        s1 = p4runtime_lib.bmv2.Bmv2SwitchConnection(
            name='s1',
            address='127.0.0.1:50001',
            device_id=1,
            # proto_dump_file='logs/s1-p4runtime-requests.txt'
            )
        s2 = p4runtime_lib.bmv2.Bmv2SwitchConnection(
            name='s2',
            address='127.0.0.1:50002',
            device_id=1,
            # proto_dump_file='logs/s2-p4runtime-requests.txt'
            )
        s3 = p4runtime_lib.bmv2.Bmv2SwitchConnection(
            name='s3',
            address='127.0.0.1:50003',
            device_id=1,
            # proto_dump_file='logs/s3-p4runtime-requests.txt'
            )

        # Send master arbitration update message to establish this controller as
        # master (required by P4Runtime before performing any other write operation)
        s1.MasterArbitrationUpdate()
        s2.MasterArbitrationUpdate()
        s3.MasterArbitrationUpdate()

        # Install the P4 program on the switches
        s1.SetForwardingPipelineConfig(p4info=p4info_helper.p4info,
                                       bmv2_json_file_path=bmv2_file_path)
        print("Installed P4 Program using SetForwardingPipelineConfig on s1")
        s2.SetForwardingPipelineConfig(p4info=p4info_helper.p4info,
                                       bmv2_json_file_path=bmv2_file_path)
        print("Installed P4 Program using SetForwardingPipelineConfig on s2")
        s3.SetForwardingPipelineConfig(p4info=p4info_helper.p4info,
                                       bmv2_json_file_path=bmv2_file_path)
        print("Installed P4 Program using SetForwardingPipelineConfig on s3")

        # Modify the following code to insert your own tabel entries
        # Note: if you use ternary match fields, you must specify the priority of the table entry
        # table_entry = p4info_helper.buildTableEntry(
        #     table_name="MyIngress.myTunnel_exact",
        #     match_fields={
        #         "hdr.myTunnel.dst_id": tunnel_id
        #     },
        #     action_name="MyIngress.myTunnel_egress",
        #     action_params={
        #         "dstAddr": dst_eth_addr,
        #         "port": SWITCH_TO_HOST_PORT
        # })
        # s1.WriteTableEntry(table_entry)

        table_entry = p4info_helper.buildTableEntry(
            table_name="fwd_table",
            match_fields={
                "hdr.ipv4.dst_addr": 0x0a000202
            },
            action_name = "fwd_encap",
            action_params = {
                "port": 2,
                "teid": 111
        })
        s1.WriteTableEntry(table_entry)

        table_entry = p4info_helper.buildTableEntry(
            table_name="ingress_block.fwd_table",
            match_fields={
                "hdr.ipv4.dst_addr": 0x0a000202
            },
            action_name="ingress_block.fwd",
            action_params={
                "port": 2
        })
        s2.WriteTableEntry(table_entry)

        table_entry = p4info_helper.buildTableEntry(
            table_name="ingress_block.fwd_table",
            match_fields={
                "hdr.ipv4.dst_addr": 0x0a000202
            },
            action_name="ingress_block.fwd_decap",
            action_params={
                "port": 2
        })
        s3.WriteTableEntry(table_entry)


        table_entry = p4info_helper.buildTableEntry(
            table_name="ingress_block.fwd_table",
            match_fields={
                "hdr.ipv4.dst_addr": 0x0a000101
            },
            action_name="ingress_block.fwd",
            action_params={
                "port": 1
        })
        s1.WriteTableEntry(table_entry)
        
        table_entry = p4info_helper.buildTableEntry(
            table_name="ingress_block.fwd_table",
            match_fields={
                "hdr.ipv4.dst_addr": 0x0a000101
            },
            action_name="ingress_block.fwd",
            action_params={
                "port": 1
        })
        s2.WriteTableEntry(table_entry)

        table_entry = p4info_helper.buildTableEntry(
            table_name="ingress_block.fwd_table",
            match_fields={
                "hdr.ipv4.dst_addr": 0x0a000101
            },
            action_name="ingress_block.fwd",
            action_params={
                "port": 1
        })
        s3.WriteTableEntry(table_entry)

        readTableRules(p4info_helper, s1)
        readTableRules(p4info_helper, s2)
        readTableRules(p4info_helper, s3)

        while(True):
            sleep(1)

    except KeyboardInterrupt:
        print(" Shutting down.")
    except grpc.RpcError as e:
        printGrpcError(e)

    ShutdownAllSwitchConnections()

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='P4Runtime Controller')
    parser.add_argument('--p4info', help='p4info proto in text format from p4c',
                        type=str, action="store", required=False,
                        default='./build/advanced_tunnel.p4.p4info.txt')
    parser.add_argument('--bmv2-json', help='BMv2 JSON file from p4c',
                        type=str, action="store", required=False,
                        default='./build/advanced_tunnel.json')
    args = parser.parse_args()

    if not os.path.exists(args.p4info):
        parser.print_help()
        print("\np4info file not found: %s\nHave you run 'make'?" % args.p4info)
        parser.exit(1)
    if not os.path.exists(args.bmv2_json):
        parser.print_help()
        print("\nBMv2 JSON file not found: %s\nHave you run 'make'?" % args.bmv2_json)
        parser.exit(1)
    main(args.p4info, args.bmv2_json)
