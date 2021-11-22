#ifndef __PARSERS__
#define __PARSERS__
parser ingress_parser(packet_in packet,
                      out headers_t hdr,
                      inout local_metadata_t local_metadata,
                      inout standard_metadata_t standard_metadata) {
    state start {
        packet.extract(hdr.eth);
        transition select(hdr.eth.ether_type) {
            ETH_TYPE_IPV4: parse_ipv4;
            ETH_TYPE_ARP: parse_arp;
            default: accept;
        }
    }

    state parse_arp {
        packet.extract(hdr.arp);
        transition accept;
    }

    state parse_ipv4 {
        packet.extract(hdr.ipv4);
        transition select(hdr.ipv4.protocol) {
            IP_PROTO_UDP: parse_udp;
            IP_PROTO_TCP: parse_tcp;
            default: accept;
        }
    }

    state parse_udp {
        packet.extract(hdr.udp);
        transition select(hdr.udp.dst_port) {
            2152: parse_gtp_u;
            default: accept;
        }
    }

    state parse_tcp {
        packet.extract(hdr.tcp);
        transition accept;
    }

    state parse_gtp_u {
        packet.extract(hdr.gtp_u);
        transition select(hdr.gtp_u.ex_flag, hdr.gtp_u.seq_flag, hdr.gtp_u.npdu_flag) {
            (0, 0, 0): parsed_gtp_u;
            default: parse_gtp_u_options;
        }
    }

    state parse_gtp_u_options {
        packet.extract(hdr.gtp_u_options);
        transition parsed_gtp_u;
    }

    state parsed_gtp_u {
        // parse inner ip
        packet.extract(hdr.inner_ipv4);
        transition accept;
    }
    // Exmaple parsing here:
    // state parse_XXX {
    //     packet.extract(hdr.some_protocol);
    //     transition select(hdr.some_protocol.next_type) {
    //         0xABCD: parse_OOO; // parse another header
    //         0xFFFF: reject; // drop the packet
    //         default: accept; // end of parser
    // }};

}

// V1Model Deparser
control egress_deparser(packet_out packet,
                        in headers_t hdr) {
    apply {
        // deparse the packet headers here
        // packet.emit(hdr.XXX);
        packet.emit(hdr.eth);
        packet.emit(hdr.arp);
        packet.emit(hdr.ipv4);
        packet.emit(hdr.udp);
        packet.emit(hdr.tcp);
        packet.emit(hdr.gtp_u);
        packet.emit(hdr.gtp_u_options);
        packet.emit(hdr.inner_ipv4);
    }
}


#endif