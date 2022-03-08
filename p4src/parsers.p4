#ifndef __PARSERS__
#define __PARSERS__
parser ingress_parser(packet_in packet,
                      out headers_t hdr,
                      inout local_metadata_t local_metadata,
                      inout standard_metadata_t standard_metadata) {
    state start {
        packet.extract(hdr.eth);
		transition select(hdr.eth.ether_type) {
			0x0800: parse_ipv4;
            0x0999: parse_tunnel;
			0x0806: parse_arp;
			default: accept;
		}
    }

    state parse_tunnel {
        packet.extract(hdr.tunnel);
        transition accept;
    }
	
	state parse_ipv4 {
		packet.extract(hdr.ipv4);
		transition accept;
	}

	state parse_arp {
		packet.extract(hdr.arp);
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
        packet.emit(hdr.eth);
        packet.emit(hdr.tunnel);
        packet.emit(hdr.arp);
        packet.emit(hdr.ipv4);
    }
}


#endif
