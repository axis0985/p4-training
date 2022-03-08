// Use V1Model as P4 Pipeline Architecture
#include <core.p4>
#include <v1model.p4>

#include "headers.p4"
#include "parsers.p4"
#include "checksum.p4"

control ingress_block(inout headers_t hdr,
                      inout local_metadata_t local_metadata,
                      inout standard_metadata_t standard_metadata) {
    // To drop the packet
    // mark_to_drop(standard_metadata);

    // To forward the packet through specified port:
    // standard_metadata.egress_spec = port;
    // port_id is 9 bits long

    // define your table here
    // forwarding should be done in ingress
	action drop() {
		mark_to_drop(standard_metadata);
	}

	action fwd(bit<9> port) {
		standard_metadata.egress_spec = port;
	}

    action decap() {
        hdr.eth.ether_type = hdr.tunnel.original_ether_type;
        hdr.tunnel.setInvalid();
    }

    action encap() {
        local_metadata.encap_flag = 1w1;
    }

    action fwd_decap(bit<9> port) {
        fwd(port);
        decap();
    }

    action fwd_encap(bit<9> port) {
        fwd(port);
        encap();
    }

	table simple_table {
		key = {
			standard_metadata.ingress_port: exact;
		}
		actions = {
			drop;
			fwd;
            fwd_decap;
            fwd_encap;
		}
		size = 256;
		const default_action = drop();
	}

    apply {
        // Don't forget to apply table
		simple_table.apply();
    }
}

control egress_block(inout headers_t hdr,
                     inout local_metadata_t local_metadata,
                     inout standard_metadata_t standard_metadata) {
    action encap_tunnel() {
        hdr.tunnel.setValid();
        hdr.tunnel.original_ether_type = hdr.eth.ether_type;
        hdr.eth.ether_type = 0x0999;
        hdr.tunnel.id = 8w23;
    }
    apply {
        if (local_metadata.encap_flag == 1w1) {
            encap_tunnel();
        }
    }
}
// V1Model: parser > checksum > ingress > PRE/TM > egress > checksum > deparser
V1Switch(ingress_parser(),
         ingress_checksum_validation(),
         ingress_block(),
         egress_block(),
         egress_checksum_recalc(),
         egress_deparser()) main;

